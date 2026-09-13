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

/// Low-latency audio player service with player pooling and pitch ramping.
class AudioService {
  AudioService._();
  static final AudioService instance = AudioService._();

  bool isMuted = false;
  double volume = 0.8;

  final List<AudioPlayer> _playerPool = <AudioPlayer>[];
  static const int _kPoolSize = 6;
  int _poolIndex = 0;

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    try {
      for (var i = 0; i < _kPoolSize; i++) {
        final player = AudioPlayer();
        await player.setVolume(volume);
        _playerPool.add(player);
      }
      _initialized = true;
    } catch (e) {
      debugPrint('[AudioService] Initialization error: $e');
    }
  }

  AudioPlayer? _getNextPlayer() {
    if (_playerPool.isEmpty) return null;
    final player = _playerPool[_poolIndex];
    _poolIndex = (_poolIndex + 1) % _playerPool.length;
    return player;
  }

  Future<void> playSowStep({int cascadeDepth = 0}) async {
    if (isMuted || !_initialized) return;
    try {
      final player = _getNextPlayer();
      if (player != null) {
        // Harmonic pitch ramp based on cascade depth
        final pitch = (1.0 + (cascadeDepth * 0.08)).clamp(0.5, 2.0);
        await player.setPlaybackRate(pitch);
        await player.setSource(AssetSource('audio/sow_step.wav'));
        await player.resume();
      }
    } catch (_) {
      // Graceful fallback if asset unprimed
    }
  }

  Future<void> playLanceFire() async {
    if (isMuted || !_initialized) return;
    try {
      final player = _getNextPlayer();
      if (player != null) {
        await player.setPlaybackRate(1.0);
        await player.setSource(AssetSource('audio/lance_fire.wav'));
        await player.resume();
      }
    } catch (_) {}
  }

  Future<void> playFlakBurst() async {
    if (isMuted || !_initialized) return;
    try {
      final player = _getNextPlayer();
      if (player != null) {
        await player.setPlaybackRate(1.0);
        await player.setSource(AssetSource('audio/flak_burst.wav'));
        await player.resume();
      }
    } catch (_) {}
  }

  Future<void> playVictory() async {
    if (isMuted || !_initialized) return;
    try {
      final player = _getNextPlayer();
      if (player != null) {
        await player.setPlaybackRate(1.0);
        await player.setSource(AssetSource('audio/victory.wav'));
        await player.resume();
      }
    } catch (_) {}
  }

  Future<void> playGameOver() async {
    if (isMuted || !_initialized) return;
    try {
      final player = _getNextPlayer();
      if (player != null) {
        await player.setPlaybackRate(1.0);
        await player.setSource(AssetSource('audio/defeat.wav'));
        await player.resume();
      }
    } catch (_) {}
  }

  void dispose() {
    for (final player in _playerPool) {
      player.dispose();
    }
    _playerPool.clear();
    _initialized = false;
  }
}
