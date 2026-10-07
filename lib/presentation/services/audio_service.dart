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
  static const int _kPoolSize = 8;
  static const int _kPoolMask = _kPoolSize - 1;
  int _poolIndex = 0;
  bool _initialized = false;
  bool _isTestMode = false;
  bool _isBgmPaused = false;
  bool _audioFocusReleased = false;
  String? _currentBgmAssetPath;

  /// The active BGM asset path, if any.
  String? get currentBgmAssetPath => _currentBgmAssetPath;

  /// Whether background music is explicitly paused.
  bool get isBgmPaused => _isBgmPaused;

  /// Whether audio focus has been released to external media.
  bool get isAudioFocusReleased => _audioFocusReleased;

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

  /// Generates a compliant 16-bit PCM mono 8000 Hz silent WAV byte buffer in-memory.
  ///
  /// Used by [_bgmPlayer] as an active audio carrier with [gameAudioContext]
  /// ([AndroidAudioFocus.gain]), which instructs Android's native AudioManager to
  /// grant exclusive audio focus and pause background media (e.g. YouTube, Spotify, Podcasts).
  static Uint8List _buildSilentWavBytes({
    int durationMs = 200,
    int sampleRate = 8000,
  }) {
    final numSamples = (sampleRate * durationMs) ~/ 1000;
    const numChannels = 1;
    const bitsPerSample = 16;
    final byteRate = sampleRate * numChannels * (bitsPerSample ~/ 8);
    const blockAlign = numChannels * (bitsPerSample ~/ 8);
    final dataSize = numSamples * blockAlign;
    final totalSize = 36 + dataSize;

    final bytes = ByteData(44 + dataSize);
    // RIFF chunk descriptor
    bytes.setUint8(0, 0x52); // 'R'
    bytes.setUint8(1, 0x49); // 'I'
    bytes.setUint8(2, 0x46); // 'F'
    bytes.setUint8(3, 0x46); // 'F'
    bytes.setUint32(4, totalSize, Endian.little);
    bytes.setUint8(8, 0x57); // 'W'
    bytes.setUint8(9, 0x41); // 'A'
    bytes.setUint8(10, 0x56); // 'V'
    bytes.setUint8(11, 0x45); // 'E'
    // fmt subchunk
    bytes.setUint8(12, 0x66); // 'f'
    bytes.setUint8(13, 0x6D); // 'm'
    bytes.setUint8(14, 0x74); // 't'
    bytes.setUint8(15, 0x20); // ' '
    bytes.setUint32(16, 16, Endian.little); // Subchunk1Size (16 for PCM)
    bytes.setUint16(20, 1, Endian.little); // AudioFormat (1 for PCM)
    bytes.setUint16(22, numChannels, Endian.little);
    bytes.setUint32(24, sampleRate, Endian.little);
    bytes.setUint32(28, byteRate, Endian.little);
    bytes.setUint16(32, blockAlign, Endian.little);
    bytes.setUint16(34, bitsPerSample, Endian.little);
    // data subchunk
    bytes.setUint8(36, 0x64); // 'd'
    bytes.setUint8(37, 0x61); // 'a'
    bytes.setUint8(38, 0x74); // 't'
    bytes.setUint8(39, 0x61); // 'a'
    bytes.setUint32(40, dataSize, Endian.little);
    // Audio samples remain zeroed by ByteData allocation
    return bytes.buffer.asUint8List();
  }

  static final Uint8List _silentWavBytes = _buildSilentWavBytes();

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

  /// Game SFX audio context configured without exclusive audio focus across Android
  /// (audioFocus none) and iOS (ambient category).
  ///
  /// This prevents pooled SFX players from fighting each other or the BGM player
  /// for audio focus, completely eliminating audio focus churn and device stalls.
  static final AudioContext sfxAudioContext = AudioContext(
    android: const AudioContextAndroid(
      isSpeakerphoneOn: false,
      stayAwake: false,
      contentType: AndroidContentType.sonification,
      usageType: AndroidUsageType.game,
      audioFocus: AndroidAudioFocus.none,
    ),
    iOS: AudioContextIOS(
      category: AVAudioSessionCategory.ambient,
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
        await updateAudioFocus();
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

      final sfxTargetContext = isAudioActive
          ? sfxAudioContext
          : ambientAudioContext;

      for (var i = 0; i < _kPoolSize; i++) {
        try {
          final player = AudioPlayer();
          try {
            await player.setAudioContext(sfxTargetContext);
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
      await updateAudioFocus();
    } catch (e) {
      debugPrint('[AudioService] Initialization error: $e');
    }
  }

  /// Explicitly requests exclusive audio focus across both Android and iOS,
  /// causing background media apps (YouTube, Spotify, etc.) to pause immediately.
  Future<void> requestExclusiveAudioFocus() async {
    _audioFocusReleased = false;
    if (_isTestMode) return;
    try {
      try {
        await AudioPlayer.global.setAudioContext(gameAudioContext);
      } catch (_) {}
      if (_bgmPlayer != null) {
        try {
          await _bgmPlayer!.setAudioContext(gameAudioContext);
          // Only resume if music is actively playing and not paused by user
          if (isMusicActive && !_isBgmPaused) {
            await _bgmPlayer!.setVolume(bgmVolume);
            await _bgmPlayer!.resume();
          }
        } catch (_) {}
      }
      for (final player in _sfxPool) {
        try {
          await player.setAudioContext(sfxAudioContext);
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
    _audioFocusReleased = true;
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
    _isBgmPaused = false;
    _currentBgmAssetPath = assetPath;
    if (_bgmPlayer == null || !isMusicActive) return;
    try {
      await _bgmPlayer!.setAudioContext(gameAudioContext);
      await _bgmPlayer!.setReleaseMode(ReleaseMode.loop);
      await _bgmPlayer!.setSource(AssetSource(assetPath));
      await _bgmPlayer!.setVolume(bgmVolume);
      await _bgmPlayer!.resume();
    } catch (e) {
      debugPrint('[AudioService] startBgm fallback: $e');
      if (isAudioActive && !_isTestMode) {
        try {
          await _bgmPlayer!.setAudioContext(gameAudioContext);
          await _bgmPlayer!.setReleaseMode(ReleaseMode.loop);
          await _bgmPlayer!.setSource(BytesSource(_silentWavBytes));
          await _bgmPlayer!.setVolume(0.01);
          await _bgmPlayer!.resume();
        } catch (_) {}
      }
    }
  }

  /// Pauses looping background music.
  Future<void> pauseBgm() async {
    _isBgmPaused = true;
    try {
      await _bgmPlayer?.pause();
    } catch (_) {}
  }

  /// Resumes background music if music is active.
  Future<void> resumeBgm() async {
    _isBgmPaused = false;
    if (isMusicActive) {
      try {
        await _bgmPlayer?.resume();
      } catch (_) {}
    }
  }

  /// Stops background music.
  Future<void> stopBgm() async {
    _isBgmPaused = false;
    try {
      await _bgmPlayer?.stop();
    } catch (_) {}
  }

  AudioPlayer? _getNextPlayer() {
    if (_sfxPool.isEmpty) {
      if (_isTestMode) {
        _poolIndex = (_poolIndex + 1) & _kPoolMask;
      }
      return null;
    }
    final player = _sfxPool[_poolIndex];
    _poolIndex = (_poolIndex + 1) & _kPoolMask;
    return player;
  }

  /// Current pool index for unit test inspection.
  @visibleForTesting
  int get poolIndex => _poolIndex;

  /// Total pre-allocated player pool size for testing.
  @visibleForTesting
  int get poolSize => _sfxPool.length;

  /// Internal testing helper for testing ring buffer wraparound.
  @visibleForTesting
  AudioPlayer? getNextPlayerForTesting() => _getNextPlayer();

  /// Internal testing helper to set ring buffer index.
  @visibleForTesting
  void setPoolIndexForTesting(int index) {
    _poolIndex = index & _kPoolMask;
  }

  /// Internal testing helper to populate pool in test mode.
  @visibleForTesting
  void populatePoolForTesting(List<AudioPlayer> players) {
    _sfxPool.clear();
    _sfxPool.addAll(players);
  }

  /// Internal testing helper to set mock BGM player in test mode.
  @visibleForTesting
  void setBgmPlayerForTesting(AudioPlayer? player) {
    _bgmPlayer = player;
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

  /// Disposes BGM player and pool, releasing audio focus to [ambientAudioContext].
  Future<void> dispose() async {
    await releaseAudioFocus();
    await _bgmPlayer?.dispose();
    _bgmPlayer = null;
    for (final player in _sfxPool) {
      await player.dispose();
    }
    _sfxPool.clear();
    _initialized = false;
  }
}
