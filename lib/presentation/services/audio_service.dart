// Copyright 2026 Void Sower Authors.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../domain/services/persistence_service.dart';

/// Low-latency audio player service with dedicated BGM and SFX pooling.
///
/// Supports dynamic audio focus orchestration: when sound/music is enabled and active,
/// requests exclusive audio focus. When sound or music is disabled or volume is zero,
/// releases and abandons device audio focus ([AndroidAudioFocus.none] and iOS ambient + mixWithOthers)
/// so external media (e.g. YouTube, Spotify, Podcasts) can play freely without interruption.
class AudioService {
  AudioService._();
  static final AudioService instance = AudioService._();

  bool isSoundEnabled = true;
  bool isMusicEnabled = true;
  double sfxVolume = 0.8;
  double bgmVolume = 0.6;
  bool isSfxMuted = false;
  bool isBgmMuted = false;

  /// Backward-compatible alias for master sound FX enable status.
  bool get isAudioEnabled => isSoundEnabled;
  set isAudioEnabled(bool value) => isSoundEnabled = value;

  /// Backward-compatible alias for SFX mute status.
  bool get isMuted => isSfxMuted;
  set isMuted(bool value) => isSfxMuted = value;

  /// Backward-compatible alias for SFX volume.
  double get volume => sfxVolume;
  set volume(double value) => sfxVolume = value;

  /// Whether sound effects should actively be played.
  /// If sound is disabled, muted, or volume is reduced to 0, sound is inactive.
  bool get isSoundActive => isSoundEnabled && !isSfxMuted && sfxVolume > 0.001;

  /// Whether background music should actively be played.
  /// If music is disabled, muted, or volume is reduced to 0, music is inactive.
  bool get isMusicActive => isMusicEnabled && !isBgmMuted && bgmVolume > 0.001;

  /// Whether any game audio (SFX or BGM) is actively outputting sound.
  bool get isAudioActive => isSoundActive || isMusicActive;

  AudioPlayer? _bgmPlayer;
  final List<AudioPlayer> _sfxPool = <AudioPlayer>[];
  static const int _kPoolSize = 6;
  int _poolIndex = 0;
  bool _initialized = false;
  bool _isTestMode = false;

  static bool _detectTestEnvironment() {
    try {
      if (kIsWeb) return false;
      if (Platform.environment.containsKey('FLUTTER_TEST')) return true;
      final type = ServicesBinding.instance.runtimeType.toString();
      return type.startsWith('AutomatedTest') || type.startsWith('TestWidgets');
    } catch (_) {
      return false;
    }
  }

  /// Game audio context configured to request exclusive audio focus across
  /// Android (gain focus, usage game, music content) and iOS (soloAmbient session).
  ///
  /// This guarantees background media players (Spotify, YouTube, Podcasts) pause
  /// immediately upon game audio initialization and playback, eliminating audio contention.
  static final AudioContext gameAudioContext = AudioContext(
    android: const AudioContextAndroid(
      isSpeakerphoneOn: false,
      stayAwake: false,
      contentType: AndroidContentType.music,
      usageType: AndroidUsageType.game,
      audioFocus: AndroidAudioFocus.gain,
    ),
    iOS: AudioContextIOS(
      category: AVAudioSessionCategory.soloAmbient,
      options: const {},
    ),
  );

  /// Ambient audio context configured to request NO audio focus across Android
  /// (audioFocus none) and iOS (ambient category with mixWithOthers).
  ///
  /// Used when game audio is disabled, muted, or volume is zero, completely
  /// freeing the device's audio focus so external media (YouTube, Spotify, Podcasts)
  /// can play without being paused or interrupted by the game.
  static final AudioContext ambientAudioContext = AudioContext(
    android: const AudioContextAndroid(
      isSpeakerphoneOn: false,
      stayAwake: false,
      contentType: AndroidContentType.music,
      usageType: AndroidUsageType.game,
      audioFocus: AndroidAudioFocus.none,
    ),
    iOS: AudioContextIOS(
      category: AVAudioSessionCategory.ambient,
      options: const {},
    ),
  );

  /// Initializes BGM player and pre-allocates SFX player pool.
  Future<void> initialize() async {
    if (_initialized) return;
    _isTestMode = _detectTestEnvironment();
    try {
      final p = PersistenceService.instance;
      isSoundEnabled = p.isSoundEnabled;
      isMusicEnabled = p.isMusicEnabled;
      sfxVolume = p.sfxVolume;
      bgmVolume = p.bgmVolume;
      isSfxMuted = p.isSfxMuted;
      isBgmMuted = p.isBgmMuted;

      if (_isTestMode) {
        _initialized = true;
        return;
      }

      // Select audio context based on whether game audio is currently active.
      // If disabled or volume is 0, use ambientAudioContext (no focus) to avoid
      // preempting external media like YouTube or Spotify.
      final targetContext = isAudioActive
          ? gameAudioContext
          : ambientAudioContext;

      try {
        await AudioPlayer.global.setAudioContext(targetContext);
      } catch (e) {
        debugPrint('[AudioService] Global audio context setup fallback: $e');
      }

      _bgmPlayer = AudioPlayer();
      try {
        await _bgmPlayer!.setAudioContext(targetContext);
        await _bgmPlayer!.setReleaseMode(ReleaseMode.loop);
        await _bgmPlayer!.setVolume(isMusicActive ? bgmVolume : 0.0);
      } catch (e) {
        debugPrint('[AudioService] BGM audio context setup fallback: $e');
      }

      for (var i = 0; i < _kPoolSize; i++) {
        try {
          final player = AudioPlayer();
          try {
            await player.setAudioContext(targetContext);
          } catch (_) {}
          try {
            await player.setVolume(isSoundActive ? sfxVolume : 0.0);
          } catch (_) {}
          _sfxPool.add(player);
        } catch (e) {
          debugPrint(
            '[AudioService] SFX player audio context setup fallback: $e',
          );
        }
      }
      _initialized = true;
    } catch (e) {
      debugPrint('[AudioService] Initialization error: $e');
    }
  }

  /// Explicitly requests exclusive audio focus across both Android and iOS,
  /// causing background media apps (YouTube, Spotify, etc.) to pause immediately.
  Future<void> requestExclusiveAudioFocus() async {
    if (_isTestMode) return;
    try {
      try {
        await AudioPlayer.global.setAudioContext(gameAudioContext);
      } catch (_) {}
      if (_bgmPlayer != null) {
        try {
          await _bgmPlayer!.setAudioContext(gameAudioContext);
        } catch (_) {}
      }
      for (final player in _sfxPool) {
        try {
          await player.setAudioContext(gameAudioContext);
        } catch (_) {}
      }
    } catch (e) {
      debugPrint('[AudioService] requestExclusiveAudioFocus fallback: $e');
    }
  }

  /// Releases audio focus across Android and iOS by stopping active players
  /// and applying [ambientAudioContext] (AndroidAudioFocus.none and iOS ambient + mixWithOthers).
  ///
  /// This immediately abandons audio focus, allowing external apps like YouTube
  /// and Spotify to resume playback without interference.
  Future<void> releaseAudioFocus() async {
    if (_isTestMode) return;
    try {
      if (_bgmPlayer != null) {
        try {
          await _bgmPlayer!.stop();
          await _bgmPlayer!.setAudioContext(ambientAudioContext);
        } catch (_) {}
      }
      for (final player in _sfxPool) {
        try {
          await player.stop();
          await player.setAudioContext(ambientAudioContext);
        } catch (_) {}
      }
      try {
        await AudioPlayer.global.setAudioContext(ambientAudioContext);
      } catch (_) {}
    } catch (e) {
      debugPrint('[AudioService] releaseAudioFocus fallback: $e');
    }
  }

  /// Updates audio focus state dynamically based on [isAudioActive].
  ///
  /// If no audio channels are active (e.g. sound disabled or volume zero),
  /// releases audio focus. Otherwise, applies [gameAudioContext] to ensure
  /// crisp game sound playback.
  Future<void> updateAudioFocus() async {
    if (!_initialized) return;
    if (isAudioActive) {
      await requestExclusiveAudioFocus();
    } else {
      await releaseAudioFocus();
    }
  }

  /// Sets master sound FX enable toggle and updates focus.
  Future<void> setSoundEnabled(bool enabled) async {
    isSoundEnabled = enabled;
    await PersistenceService.instance.setSoundEnabled(enabled);
    if (!isSoundActive) {
      for (final player in _sfxPool) {
        try {
          await player.stop();
          await player.setVolume(0.0);
        } catch (_) {}
      }
    } else {
      for (final player in _sfxPool) {
        try {
          await player.setVolume(sfxVolume);
        } catch (_) {}
      }
    }
    await updateAudioFocus();
  }

  /// Sets master background music enable toggle and updates focus.
  Future<void> setMusicEnabled(bool enabled) async {
    isMusicEnabled = enabled;
    await PersistenceService.instance.setMusicEnabled(enabled);
    if (!isMusicActive) {
      await stopBgm();
    } else {
      if (_bgmPlayer != null) {
        await _bgmPlayer!.setVolume(bgmVolume);
        await _bgmPlayer!.resume();
      }
    }
    await updateAudioFocus();
  }

  /// Sets SFX channel volume and updates pool.
  Future<void> setSfxVolume(double volume) async {
    sfxVolume = volume.clamp(0.0, 1.0);
    await PersistenceService.instance.setSfxVolume(sfxVolume);
    for (final player in _sfxPool) {
      await player.setVolume(isSoundActive ? sfxVolume : 0.0);
    }
    await updateAudioFocus();
  }

  /// Sets BGM channel volume and updates background player.
  Future<void> setBgmVolume(double volume) async {
    bgmVolume = volume.clamp(0.0, 1.0);
    await PersistenceService.instance.setBgmVolume(bgmVolume);
    if (_bgmPlayer != null) {
      if (!isMusicActive) {
        await _bgmPlayer!.setVolume(0.0);
        await _bgmPlayer!.stop();
      } else {
        await _bgmPlayer!.setVolume(bgmVolume);
      }
    }
    await updateAudioFocus();
  }

  /// Toggles SFX mute status.
  Future<void> setSfxMuted(bool muted) async {
    isSfxMuted = muted;
    await PersistenceService.instance.setSfxMuted(muted);
    for (final player in _sfxPool) {
      await player.setVolume(isSoundActive ? sfxVolume : 0.0);
    }
    await updateAudioFocus();
  }

  /// Toggles BGM mute status.
  Future<void> setBgmMuted(bool muted) async {
    isBgmMuted = muted;
    await PersistenceService.instance.setBgmMuted(muted);
    if (_bgmPlayer != null) {
      if (!isMusicActive) {
        await _bgmPlayer!.setVolume(0.0);
        await _bgmPlayer!.stop();
      } else {
        await _bgmPlayer!.setVolume(bgmVolume);
      }
    }
    await updateAudioFocus();
  }

  /// Starts or restarts looping background music if music is active.
  Future<void> startBgm({String assetPath = 'audio/kilwa_ambient.mp3'}) async {
    if (_bgmPlayer == null || !isMusicActive) return;
    try {
      await _bgmPlayer!.setSource(AssetSource(assetPath));
      await _bgmPlayer!.setVolume(bgmVolume);
      await _bgmPlayer!.resume();
    } catch (e) {
      debugPrint('[AudioService] startBgm fallback: $e');
    }
  }

  /// Pauses looping background music.
  Future<void> pauseBgm() async {
    await _bgmPlayer?.pause();
  }

  /// Resumes background music if music is active.
  Future<void> resumeBgm() async {
    if (isMusicActive) {
      await _bgmPlayer?.resume();
    }
  }

  /// Stops background music.
  Future<void> stopBgm() async {
    await _bgmPlayer?.stop();
  }

  AudioPlayer? _getNextPlayer() {
    if (_sfxPool.isEmpty) return null;
    final player = _sfxPool[_poolIndex];
    _poolIndex = (_poolIndex + 1) % _sfxPool.length;
    return player;
  }

  /// Plays harmonic sow step SFX with cascade pitch ramping.
  Future<void> playSowStep({int cascadeDepth = 0}) async {
    if (!isSoundActive || !_initialized) return;
    try {
      final player = _getNextPlayer();
      if (player != null) {
        final pitch = (1.0 + (cascadeDepth * 0.08)).clamp(0.5, 2.0);
        await player.setPlaybackRate(pitch);
        await player.setSource(AssetSource('audio/sow_step.wav'));
        await player.resume();
      }
    } catch (_) {}
  }

  /// Plays particle lance emission SFX.
  Future<void> playLanceFire() async {
    if (!isSoundActive || !_initialized) return;
    try {
      final player = _getNextPlayer();
      if (player != null) {
        await player.setPlaybackRate(1.0);
        await player.setSource(AssetSource('audio/lance_fire.wav'));
        await player.resume();
      }
    } catch (_) {}
  }

  /// Plays flak burst radial detonation SFX.
  Future<void> playFlakBurst() async {
    if (!isSoundActive || !_initialized) return;
    try {
      final player = _getNextPlayer();
      if (player != null) {
        await player.setPlaybackRate(1.0);
        await player.setSource(AssetSource('audio/flak_burst.wav'));
        await player.resume();
      }
    } catch (_) {}
  }

  /// Plays kinetic barrier absorption SFX.
  Future<void> playShieldHit() async {
    if (!isSoundActive || !_initialized) return;
    try {
      final player = _getNextPlayer();
      if (player != null) {
        await player.setPlaybackRate(1.0);
        await player.setSource(AssetSource('audio/shield_hit.wav'));
        await player.resume();
      }
    } catch (_) {}
  }

  /// Plays core injection SFX.
  Future<void> playInjectCore() async {
    if (!isSoundActive || !_initialized) return;
    try {
      final player = _getNextPlayer();
      if (player != null) {
        await player.setPlaybackRate(1.0);
        await player.setSource(AssetSource('audio/inject_core.wav'));
        await player.resume();
      }
    } catch (_) {}
  }

  /// Plays sector liberation victory fanfare SFX.
  Future<void> playVictory() async {
    if (!isSoundActive || !_initialized) return;
    try {
      final player = _getNextPlayer();
      if (player != null) {
        await player.setPlaybackRate(1.0);
        await player.setSource(AssetSource('audio/victory.wav'));
        await player.resume();
      }
    } catch (_) {}
  }

  /// Plays dreadnought destruction defeat SFX.
  Future<void> playGameOver() async {
    if (!isSoundActive || !_initialized) return;
    try {
      final player = _getNextPlayer();
      if (player != null) {
        await player.setPlaybackRate(1.0);
        await player.setSource(AssetSource('audio/defeat.wav'));
        await player.resume();
      }
    } catch (_) {}
  }

  /// Plays projectile deflection SFX.
  Future<void> playBulletDeflect() async {
    if (!isSoundActive || !_initialized) return;
    try {
      final player = _getNextPlayer();
      if (player != null) {
        await player.setPlaybackRate(1.0);
        await player.setSource(AssetSource('audio/bullet_deflect.wav'));
        await player.resume();
      }
    } catch (_) {}
  }

  /// Disposes BGM player and pool.
  void dispose() {
    _bgmPlayer?.dispose();
    _bgmPlayer = null;
    for (final player in _sfxPool) {
      player.dispose();
    }
    _sfxPool.clear();
    _initialized = false;
  }
}
