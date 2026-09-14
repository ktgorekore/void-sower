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

import '../../domain/models/bay_state.dart';
import '../../domain/models/dreadnought_state.dart';
import '../../domain/models/enemy_craft.dart';
import '../../domain/services/game_engine_interface.dart';

/// Callback when the autonomous solver selects a strategic action.
typedef OnSolverMoveSelected =
    void Function(int bayIndex, int direction, double targetSlideX);

/// Encapsulates autonomous tactical decision evaluation and action pacing.
class TacticalSolverController {
  TacticalSolverController({
    required this.engine,
    required this.onMoveSelected,
  });

  final IVoidSowerEngine engine;
  final OnSolverMoveSelected onMoveSelected;

  double _cooldown = 0.0;

  /// Resets cooldown timer.
  void reset() {
    _cooldown = 0.0;
  }

  /// Advances solver countdown and triggers evaluation when primed.
  void update({
    required double dt,
    required DreadnoughtState dreadnought,
    required List<BayState> bays,
    required List<EnemyCraft> enemies,
  }) {
    if (dreadnought.reserveCores == 0 ||
        dreadnought.isCascading ||
        !dreadnought.isIdle) {
      return;
    }

    _cooldown -= dt;
    if (_cooldown > 0.0) return;

    final activeEnemies = enemies
        .where((e) => !e.isDestroyed && e.worldPosY > 0.15)
        .toList();
    if (activeEnemies.isEmpty) return;

    final activeCorridors = activeEnemies
        .map((e) => e.assignedCorridor)
        .toSet();

    int bestBay = 0;
    int bestDir = 1;
    double bestScore = -1.0;

    for (int bay = 0; bay < 16; bay++) {
      for (final dir in [1, -1]) {
        final pred = engine.predictSow(bay, dir);
        double score = 0.0;

        if (pred.triggersLance &&
            activeCorridors.contains(pred.terminalCorridor)) {
          score += 1000.0 + (pred.predictedDamage * 10.0);
        }
        if (pred.triggersRelay) {
          score += 600.0 + (pred.totalCascadeLaps * 150.0);
        }
        if (pred.terminalBay >= 8) {
          score += 80.0;
        }
        if (bay < bays.length) {
          score += bays[bay].chargeUnits * 25.0;
        }

        if (score > bestScore) {
          bestScore = score;
          bestBay = bay;
          bestDir = dir;
        }
      }
    }

    final pred = engine.predictSow(bestBay, bestDir);
    final int targetCorridor;
    if (pred.terminalCorridor >= 0) {
      targetCorridor = pred.terminalCorridor;
    } else if (bestBay >= 8) {
      targetCorridor = bestBay - 8;
    } else {
      targetCorridor = bestBay % 8;
    }
    final targetX = ((targetCorridor + 0.5) / 8.0).clamp(0.0, 1.0);

    onMoveSelected(bestBay, bestDir, targetX);
    _cooldown = 1.0;
  }
}
