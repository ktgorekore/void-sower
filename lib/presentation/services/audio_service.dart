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

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import '../../domain/services/persistence_service.dart';

/// Low-latency audio player service with dedicated BGM and SFX pooling.
class AudioService {
  AudioService._();
  static final AudioService instance = AudioService._();

  double sfxVolume = 0.8;
  double bgmVolume = 0.6;
  bool isSfxMuted = false;
  bool isBgmMuted = false;

  /// Backward-compatible alias for SFX mute status.
  bool get isMuted => isSfxMuted;
  set isMuted(bool value) => isSfxMuted = value;

  /// Backward-compatible alias for SFX volume.
  double get volume => sfxVolume;
  set volume(double value) => sfxVolume = value;

  AudioPlayer? _bgmPlayer;
  final List<AudioPlayer> _sfxPool = <AudioPlayer>[];
  static const int _kPoolSize = 6;
  int _poolIndex = 0;
  bool _initialized = false;

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

  /// Initializes BGM player and pre-allocates SFX player pool.
  Future<void> initialize() async {
    if (_initialized) return;
    try {
      final p = PersistenceService.instance;
      sfxVolume = p.sfxVolume;
      bgmVolume = p.bgmVolume;
      isSfxMuted = p.isSfxMuted;
      isBgmMuted = p.isBgmMuted;

      // Configure exclusive audio focus globally and across all player instances
      // to ensure background media (e.g. YouTube, Spotify) pauses immediately.
      try {
        await AudioPlayer.global.setAudioContext(gameAudioContext);
      } catch (e) {
        debugPrint('[AudioService] Global audio context setup fallback: $e');
      }

      _bgmPlayer = AudioPlayer();
      try {
        await _bgmPlayer!.setAudioContext(gameAudioContext);
      } catch (e) {
        debugPrint('[AudioService] BGM audio context setup fallback: $e');
      }
      await _bgmPlayer!.setReleaseMode(ReleaseMode.loop);
      await _bgmPlayer!.setVolume(isBgmMuted ? 0.0 : bgmVolume);

      for (var i = 0; i < _kPoolSize; i++) {
        final player = AudioPlayer();
        try {
          await player.setAudioContext(gameAudioContext);
        } catch (e) {
          debugPrint(
            '[AudioService] SFX player audio context setup fallback: $e',
          );
        }
        await player.setVolume(isSfxMuted ? 0.0 : sfxVolume);
        _sfxPool.add(player);
      }
      _initialized = true;
    } catch (e) {
      debugPrint('[AudioService] Initialization error: $e');
    }
  }

  /// Explicitly requests exclusive audio focus across both Android and iOS,
  /// causing background media apps (YouTube, Spotify, etc.) to pause immediately.
  Future<void> requestExclusiveAudioFocus() async {
    try {
      await AudioPlayer.global.setAudioContext(gameAudioContext);
      if (_bgmPlayer != null) {
        await _bgmPlayer!.setAudioContext(gameAudioContext);
      }
      for (final player in _sfxPool) {
        await player.setAudioContext(gameAudioContext);
      }
    } catch (e) {
      debugPrint('[AudioService] requestExclusiveAudioFocus fallback: $e');
    }
  }

  /// Sets SFX channel volume and updates pool.
  Future<void> setSfxVolume(double volume) async {
    sfxVolume = volume.clamp(0.0, 1.0);
    await PersistenceService.instance.setSfxVolume(sfxVolume);
    for (final player in _sfxPool) {
      await player.setVolume(isSfxMuted ? 0.0 : sfxVolume);
    }
  }

  /// Sets BGM channel volume and updates background player.
  Future<void> setBgmVolume(double volume) async {
    bgmVolume = volume.clamp(0.0, 1.0);
    await PersistenceService.instance.setBgmVolume(bgmVolume);
    if (_bgmPlayer != null && !isBgmMuted) {
      await _bgmPlayer!.setVolume(bgmVolume);
    }
  }

  /// Toggles SFX mute status.
  Future<void> setSfxMuted(bool muted) async {
    isSfxMuted = muted;
    await PersistenceService.instance.setSfxMuted(muted);
    for (final player in _sfxPool) {
      await player.setVolume(isSfxMuted ? 0.0 : sfxVolume);
    }
  }

  /// Toggles BGM mute status.
  Future<void> setBgmMuted(bool muted) async {
    isBgmMuted = muted;
    await PersistenceService.instance.setBgmMuted(muted);
    if (_bgmPlayer != null) {
      await _bgmPlayer!.setVolume(isBgmMuted ? 0.0 : bgmVolume);
    }
  }

  /// Starts or restarts looping background music.
  Future<void> startBgm({String assetPath = 'audio/kilwa_ambient.mp3'}) async {
    if (_bgmPlayer == null) return;
    try {
      await _bgmPlayer!.setSource(AssetSource(assetPath));
      await _bgmPlayer!.setVolume(isBgmMuted ? 0.0 : bgmVolume);
      await _bgmPlayer!.resume();
    } catch (e) {
      debugPrint('[AudioService] startBgm fallback: $e');
    }
  }

  /// Pauses looping background music.
  Future<void> pauseBgm() async {
    await _bgmPlayer?.pause();
  }

  /// Resumes background music if not muted.
  Future<void> resumeBgm() async {
    if (!isBgmMuted) {
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
    if (isSfxMuted || !_initialized) return;
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
    if (isSfxMuted || !_initialized) return;
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
    if (isSfxMuted || !_initialized) return;
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
    if (isSfxMuted || !_initialized) return;
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
    if (isSfxMuted || !_initialized) return;
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
    if (isSfxMuted || !_initialized) return;
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
    if (isSfxMuted || !_initialized) return;
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
    if (isSfxMuted || !_initialized) return;
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
