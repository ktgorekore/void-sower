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
import '../../domain/models/prediction_result.dart';
import '../../domain/services/game_engine_interface.dart';

/// Callback when the autonomous solver selects a strategic action.
typedef OnSolverMoveSelected =
    void Function(int bayIndex, int direction, double targetSlideX);

/// Encapsulates autonomous tactical decision evaluation, zero-allocation
/// threat scanning, and adaptive action pacing to prevent orbital breaches.
class TacticalSolverController {
  TacticalSolverController({
    required this.engine,
    required this.onMoveSelected,
  });

  final IVoidSowerEngine engine;
  final OnSolverMoveSelected onMoveSelected;

  double _cooldown = 0.0;

  /// Current remaining cooldown in seconds.
  double get cooldown => _cooldown;

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

    // Zero-allocation active enemy scan & threat proximity evaluation.
    int activeCorridorsMask = 0;
    int criticalCorridorsMask = 0;
    int activeEnemyCount = 0;
    double minDistanceToBoundary = 1.0;

    for (var i = 0; i < enemies.length; i++) {
      final enemy = enemies[i];
      if (enemy.isDestroyed || enemy.worldPosY <= 0.15) {
        continue;
      }
      activeEnemyCount++;
      final corridor = enemy.assignedCorridor;
      if (corridor >= 0 && corridor < 8) {
        activeCorridorsMask |= (1 << corridor);
        final dist = enemy.worldPosY - 0.15;
        if (dist < minDistanceToBoundary) {
          minDistanceToBoundary = dist;
        }
        // If enemy is below Y = 0.40, corridor is under imminent breach threat!
        if (enemy.worldPosY < 0.40) {
          criticalCorridorsMask |= (1 << corridor);
        }
      }
    }

    if (activeEnemyCount == 0) return;

    int bestBay = 0;
    int bestDir = 1;
    double bestScore = -1.0;
    PredictionResult? bestPred;

    for (int bay = 0; bay < 16; bay++) {
      for (final dir in [1, -1]) {
        final pred = engine.predictSow(bay, dir);
        double score = 0.0;

        final corridor = pred.terminalCorridor;
        final bool corridorHasEnemy =
            corridor >= 0 &&
            corridor < 8 &&
            (activeCorridorsMask & (1 << corridor)) != 0;
        final bool isCriticalCorridor =
            corridor >= 0 &&
            corridor < 8 &&
            (criticalCorridorsMask & (1 << corridor)) != 0;

        if (pred.triggersLance && corridorHasEnemy) {
          score += 1200.0 + (pred.predictedDamage * 15.0);
          // Massively prioritize destroying enemies on the verge of breach!
          if (isCriticalCorridor) {
            score += 3000.0;
          }
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
          bestPred = pred;
        }
      }
    }

    final pred = bestPred ?? engine.predictSow(bestBay, bestDir);
    final int targetCorridor;
    if (pred.terminalCorridor >= 0) {
      targetCorridor = pred.terminalCorridor;
    } else if (bestBay >= 8) {
      targetCorridor = bestBay - 8;
    } else {
      targetCorridor = bestBay & 0x07;
    }
    final targetX = ((targetCorridor + 0.5) / 8.0).clamp(0.0, 1.0);

    onMoveSelected(bestBay, bestDir, targetX);

    // Adaptive reactive pacing:
    // If invaders are near atmospheric horizon, counter immediately.
    if (minDistanceToBoundary < 0.25) {
      _cooldown = 0.16; // Imminent breach emergency
    } else if (minDistanceToBoundary < 0.50) {
      _cooldown = 0.32; // Mid-range encounter
    } else {
      _cooldown = 0.55; // Long-range setup
    }
  }
}
