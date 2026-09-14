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

import 'package:flutter/material.dart';

/// Discrete operational states of the Combat Match Flow Finite State Machine.
enum CombatMatchStatus {
  /// Engine initializing or setting up initial entities.
  initializing,

  /// Interactive tactical tutorial briefing overlay is active.
  briefing,

  /// Active real-time combat loop (player can slide platform, select bays, sow).
  activeCombat,

  /// Visual sowing sequence is animating pit-to-pit along the ring.
  sowingSequence,

  /// Game paused (e.g., menu, codex, or dialog open).
  paused,

  /// Planetary defense successful, all enemy assault craft neutralized.
  victory,

  /// Dreadnought destroyed, reserves depleted, or atmospheric boundary breached.
  defeat,

  /// Screen or session terminated.
  disposed,
}

/// Immutable state snapshot for the Combat Match Flow State Machine.
class CombatMatchState {
  const CombatMatchState({
    required this.status,
    this.selectedBay,
    this.activeSowBay,
    this.isAutoSolving = false,
    this.screenShake = Offset.zero,
  });

  /// Initial factory state.
  factory CombatMatchState.initial({bool startWithTutorial = false}) {
    return CombatMatchState(
      status: startWithTutorial
          ? CombatMatchStatus.briefing
          : CombatMatchStatus.activeCombat,
    );
  }

  /// Current lifecycle status in the combat state machine.
  final CombatMatchStatus status;

  /// Currently selected capacitor bay index (0..15), if any.
  final int? selectedBay;

  /// Bay currently highlighted during an active sowing hop traversal.
  final int? activeSowBay;

  /// Whether the MCTS tactical auto-solver is autonomously commanding the ship.
  final bool isAutoSolving;

  /// Dynamic screen shake offset decaying toward zero.
  final Offset screenShake;

  /// Whether player touch input is currently permitted.
  bool get canReceiveInput =>
      status == CombatMatchStatus.activeCombat && !isAutoSolving;

  /// Whether the match has concluded in a terminal outcome.
  bool get isTerminal =>
      status == CombatMatchStatus.victory || status == CombatMatchStatus.defeat;

  /// Returns a copy with updated attributes.
  CombatMatchState copyWith({
    CombatMatchStatus? status,
    int? selectedBay,
    bool clearSelectedBay = false,
    int? activeSowBay,
    bool clearActiveSowBay = false,
    bool? isAutoSolving,
    Offset? screenShake,
  }) {
    return CombatMatchState(
      status: status ?? this.status,
      selectedBay: clearSelectedBay ? null : (selectedBay ?? this.selectedBay),
      activeSowBay: clearActiveSowBay
          ? null
          : (activeSowBay ?? this.activeSowBay),
      isAutoSolving: isAutoSolving ?? this.isAutoSolving,
      screenShake: screenShake ?? this.screenShake,
    );
  }
}
