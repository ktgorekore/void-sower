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

import '../services/audio_service.dart';

/// Event-driven audio orchestrator for combat simulation.
/// Replaces per-frame polling with discrete event dispatches.
class CombatAudioOrchestrator {
  CombatAudioOrchestrator({AudioService? audioService})
    : _audio = audioService ?? AudioService.instance;

  final AudioService _audio;

  /// Triggers upward particle lance beam firing SFX.
  void onLanceFired() {
    _audio.playLanceFire();
  }

  /// Triggers secondary radial flak explosion SFX.
  void onFlakDetonated() {
    _audio.playFlakBurst();
  }

  /// Triggers conduit breach / shield impact SFX.
  void onShieldHit() {
    _audio.playShieldHit();
  }

  /// Triggers magnetic core reload into bay SFX.
  void onCoreInjected() {
    _audio.playInjectCore();
  }

  /// Triggers resonant kalimba sowing step with harmonic pitch ramp.
  void onSowStep({int cascadeDepth = 0}) {
    _audio.playSowStep(cascadeDepth: cascadeDepth);
  }

  /// Triggers ascending fanfare on victory.
  void onVictory() {
    _audio.playVictory();
  }

  /// Triggers power-down reactor whine on defeat.
  void onDefeat() {
    _audio.playGameOver();
  }

  /// Triggers laser deflection / bomb interception ping SFX.
  void onBulletDeflected() {
    _audio.playBulletDeflect();
  }
}
