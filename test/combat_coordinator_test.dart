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
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:void_sower/domain/services/persistence_service.dart';
import 'package:void_sower/domain/state/combat_match_state.dart';
import 'package:void_sower/engine/mock_void_sower_engine.dart';
import 'package:void_sower/presentation/controllers/combat_coordinator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CombatCoordinator Architecture Tests', () {
    late MockVoidSowerEngine engine;
    late CombatCoordinator coordinator;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await PersistenceService.instance.initialize();
      engine = MockVoidSowerEngine();
      coordinator = CombatCoordinator(engine: engine, difficultyTier: 1);
      coordinator.initialize(startingCores: 28, boundaryY: 0.15);
    });

    tearDown(() {
      coordinator.dispose();
    });

    test('Initializes state machine to activeCombat for tier 1', () {
      expect(coordinator.state.status, equals(CombatMatchStatus.activeCombat));
      expect(coordinator.dreadnought.reserveCores, equals(28));
      expect(coordinator.bays.length, equals(16));
      expect(coordinator.enemies.isNotEmpty, isTrue);
    });

    test('selectBay updates selectedBay and computes prediction', () {
      coordinator.selectBay(8);
      expect(coordinator.state.selectedBay, equals(8));
      expect(coordinator.prediction, isNotNull);
      expect(coordinator.prediction!.terminalBay, isNotNull);
    });

    test(
      'slidePosition moves dreadnought and auto-locks active corridor bay',
      () {
        coordinator.slidePosition(
          0.5,
        ); // Corridor 4 (center) -> Frontline bay 12
        expect(coordinator.state.selectedBay, equals(12));
      },
    );

    test('toggleAutoSolve toggles solver state', () {
      expect(coordinator.state.isAutoSolving, isFalse);
      coordinator.toggleAutoSolve();
      expect(coordinator.state.isAutoSolving, isTrue);
      coordinator.toggleAutoSolve();
      expect(coordinator.state.isAutoSolving, isFalse);
    });

    test('update steps engine simulation and updates physics', () {
      coordinator.update(0.016, const Size(800, 1000));
      expect(coordinator.dreadnought, isNotNull);
    });

    test(
      'Tutorial briefing pauses simulation until player dismisses/launches',
      () async {
        final tier0Coordinator = CombatCoordinator(
          engine: engine,
          difficultyTier: 0,
        );
        tier0Coordinator.initialize(startingCores: 28, boundaryY: 0.15);

        // Before tutorial is completed, tier 0 starts in briefing mode
        expect(
          tier0Coordinator.state.status,
          equals(CombatMatchStatus.briefing),
        );

        final initialEnemyY = tier0Coordinator.enemies.first.worldPosY;

        // Calling update multiple times while in briefing must NOT move enemies
        for (var i = 0; i < 20; i++) {
          tier0Coordinator.update(0.016, const Size(800, 1000));
        }
        expect(tier0Coordinator.enemies.first.worldPosY, equals(initialEnemyY));

        // Dismissing tutorial starts active combat and records completion
        tier0Coordinator.dismissTutorial();
        expect(
          tier0Coordinator.state.status,
          equals(CombatMatchStatus.activeCombat),
        );
        expect(PersistenceService.instance.hasCompletedTutorial, isTrue);

        // Now active combat steps simulation and advances enemies
        tier0Coordinator.update(0.016, const Size(800, 1000));
        expect(
          tier0Coordinator.enemies.first.worldPosY,
          lessThan(initialEnemyY),
        );

        // Subsequent sector 0 launch starts directly in active combat
        final replayCoordinator = CombatCoordinator(
          engine: engine,
          difficultyTier: 0,
        );
        replayCoordinator.initialize(startingCores: 28, boundaryY: 0.15);
        expect(
          replayCoordinator.state.status,
          equals(CombatMatchStatus.activeCombat),
        );

        // Manual showTutorial pauses active combat
        replayCoordinator.showTutorial();
        expect(
          replayCoordinator.state.status,
          equals(CombatMatchStatus.briefing),
        );

        tier0Coordinator.dispose();
        replayCoordinator.dispose();
      },
    );

    test('quickFireActiveCorridor injects core axially inward', () {
      // Position at Corridor 2 (X = 0.31) -> Active bay is 10, inward direction +1
      coordinator.slidePosition(0.31);
      expect(coordinator.state.selectedBay, equals(10));

      final initialCores = coordinator.dreadnought.reserveCores;
      coordinator.quickFireActiveCorridor();

      // Injected core into bay 10 with inward direction (+1)
      expect(coordinator.dreadnought.reserveCores, equals(initialCores - 1));
      expect(
        coordinator.damageNumbers.any((d) => d.text.contains('AXIAL LANCE')),
        isTrue,
      );

      // Position on right half: Corridor 6 (X = 0.81) -> Active bay is 14, inward direction -1
      coordinator.slidePosition(0.81);
      expect(coordinator.state.selectedBay, equals(14));
      coordinator.quickFireActiveCorridor();
      expect(coordinator.dreadnought.reserveCores, equals(initialCores - 2));
    });

    test('Triggers immediate defeat when reserve cores are exhausted', () {
      coordinator.initialize(startingCores: 0, boundaryY: 0.15);
      expect(coordinator.dreadnought.reserveCores, equals(0));
      expect(coordinator.enemies.isNotEmpty, isTrue);

      coordinator.update(0.016, const Size(800, 1000));
      expect(coordinator.state.status, equals(CombatMatchStatus.defeat));
      expect(coordinator.bulletManager.bullets, isEmpty);
    });

    test(
      'When orbital boundary is breached, simulation halts and invader bullets stop shooting',
      () {
        // Step time enough to trigger enemy fire cooldown (35 steps of 0.04s = 1.4s > 1.0s cooldown)
        for (var i = 0; i < 35; i++) {
          coordinator.update(0.04, const Size(800, 1000));
        }
        expect(coordinator.bulletManager.bullets, isNotEmpty);

        // Fast forward / trigger defeat (startingCores: 0)
        coordinator.initialize(startingCores: 0, boundaryY: 0.15);
        coordinator.update(0.04, const Size(800, 1000));

        // Game over / defeat triggered: match status is defeat, active bullets are cleared
        expect(coordinator.state.status, equals(CombatMatchStatus.defeat));
        expect(coordinator.bulletManager.bullets, isEmpty);

        // Subsequent update steps must freeze: no new bullets fired, simulation frozen
        for (var i = 0; i < 50; i++) {
          coordinator.update(0.04, const Size(800, 1000));
        }
        expect(coordinator.bulletManager.bullets, isEmpty);
        expect(coordinator.state.status, equals(CombatMatchStatus.defeat));
      },
    );

    test(
      'Pausing combat during active sowing sequence finalizes injection and preserves paused state',
      () async {
        coordinator.selectBay(11);
        coordinator.sow(11, 1);
        expect(
          coordinator.state.status,
          equals(CombatMatchStatus.sowingSequence),
        );

        // Pause combat immediately while sowing traversal is in flight
        coordinator.pauseCombat();
        expect(coordinator.state.status, equals(CombatMatchStatus.paused));
        expect(coordinator.state.activeSowBay, isNull);

        // Await enough wall-clock time for delayed animation timers to fire
        await Future<void>.delayed(const Duration(milliseconds: 150));

        // Status MUST strictly remain paused and NOT revert to activeCombat
        expect(coordinator.state.status, equals(CombatMatchStatus.paused));

        // Repeated update steps must NOT advance simulation
        final initialEnemyY = coordinator.enemies.first.worldPosY;
        for (var i = 0; i < 30; i++) {
          coordinator.update(0.016, const Size(800, 1000));
        }
        expect(coordinator.enemies.first.worldPosY, equals(initialEnemyY));
        expect(coordinator.state.status, equals(CombatMatchStatus.paused));

        // Resuming combat transitions cleanly to activeCombat
        coordinator.resumeCombat();
        expect(
          coordinator.state.status,
          equals(CombatMatchStatus.activeCombat),
        );
      },
    );

    test(
      'AI tactical solver does not execute moves when combat is paused',
      () async {
        coordinator.toggleAutoSolve();
        expect(coordinator.state.isAutoSolving, isTrue);

        coordinator.pauseCombat();
        expect(coordinator.state.status, equals(CombatMatchStatus.paused));

        // Simulate multiple seconds while paused
        for (var i = 0; i < 60; i++) {
          coordinator.update(0.05, const Size(800, 1000));
        }

        // Wait to catch any rogue asynchronous timer callbacks
        await Future<void>.delayed(const Duration(milliseconds: 150));

        expect(coordinator.state.status, equals(CombatMatchStatus.paused));
        expect(coordinator.state.activeSowBay, isNull);
      },
    );

    test(
      'AI tactical solver marks hasUsedAiSolver and prevents player stats/points accumulation',
      () {
        expect(coordinator.hasUsedAiSolver, isFalse);
        expect(coordinator.sessionSeedsSown, equals(0));

        // Player manual sow accumulates stats
        coordinator.sow(11, 1);
        expect(coordinator.sessionSeedsSown, greaterThan(0));
        final initialSeeds = coordinator.sessionSeedsSown;

        // Toggling auto solve sets hasUsedAiSolver flag
        coordinator.toggleAutoSolve();
        expect(coordinator.hasUsedAiSolver, isTrue);
        expect(coordinator.state.isAutoSolving, isTrue);

        // Subsequent sowing while auto-solving or after AI used does NOT accumulate player stats
        coordinator.sow(12, 1);
        expect(coordinator.sessionSeedsSown, equals(initialSeeds));

        // Competitive score returns 0 once AI solver has been engaged
        expect(coordinator.competitiveScore, equals(0));
      },
    );

    test('selectBay on Bay 15 with direction 1 resolves inward to -1', () {
      coordinator.selectBay(15, 1);
      expect(coordinator.state.selectedBay, equals(15));
      expect(coordinator.sowDirection, equals(-1));
      expect(coordinator.prediction, isNotNull);
      // Bay 15 has 2 charges + 1 injected = 3 units. Sowing -1: 14 -> 13 -> 12.
      expect(coordinator.prediction!.terminalBay, equals(12));
    });

    test('selectBay on Bay 8 with direction -1 resolves inward to 1', () {
      coordinator.selectBay(8, -1);
      expect(coordinator.state.selectedBay, equals(8));
      expect(coordinator.sowDirection, equals(1));
      expect(coordinator.prediction, isNotNull);
      // Bay 8 has 2 charges + 1 injected = 3 units. Sowing +1: 9 -> 10 -> 11.
      expect(coordinator.prediction!.terminalBay, equals(11));
    });

    test(
      'quickFireActiveCorridor from Bay 15 resolves direction to -1 and fires lance',
      () {
        // Slide to Corridor 7 (aligned with Bay 15: (7 + 0.5) / 8.0 = 0.9375)
        coordinator.slidePosition(0.9375);
        expect(coordinator.state.selectedBay, equals(15));
        expect(coordinator.sowDirection, equals(-1));

        final initialLances = coordinator.lances.length;
        coordinator.quickFireActiveCorridor();

        expect(coordinator.sowDirection, equals(-1));
        expect(coordinator.lances.length, greaterThan(initialLances));
      },
    );

    test('slidePosition to corridor 7 (bay 15) forces direction to -1', () {
      coordinator.slidePosition(0.95);
      expect(coordinator.state.selectedBay, equals(15));
      expect(coordinator.sowDirection, equals(-1));
    });

    test(
      'slidePosition to corridor 0 (bay 8) preserves or forces inward direction 1',
      () {
        coordinator.selectBay(8, -1);
        expect(coordinator.sowDirection, equals(1));
        coordinator.slidePosition(0.05);
        expect(coordinator.state.selectedBay, equals(8));
        expect(coordinator.sowDirection, equals(1));
      },
    );
  });
}
