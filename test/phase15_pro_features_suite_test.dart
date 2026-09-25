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
import 'package:void_sower/domain/models/dreadnought_state.dart';
import 'package:void_sower/domain/models/enemy_craft.dart';
import 'package:void_sower/domain/models/prediction_result.dart';
import 'package:void_sower/domain/services/entitlement_service.dart';
import 'package:void_sower/domain/services/fleet_service.dart';
import 'package:void_sower/domain/services/persistence_service.dart';
import 'package:void_sower/engine/mock_void_sower_engine.dart';
import 'package:void_sower/presentation/controllers/combat_coordinator.dart';
import 'package:void_sower/presentation/controllers/tactical_solver_controller.dart';
import 'package:void_sower/presentation/screens/simulation_lab_screen.dart';
import 'package:void_sower/presentation/widgets/projection_shelf.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await PersistenceService.instance.resetForTesting();
    await PersistenceService.instance.setCompletedTutorial(true);
    EntitlementService.instance.resetForTesting();
  });

  group('Phase 15: Chassis Combat Multipliers & Fleet System', () {
    test('FleetService defines 4 distinct combat chassis with multipliers', () {
      final chassisList = FleetService.instance.getChassisList();
      expect(chassisList.length, 4);

      final bastion = FleetService.instance.getChassis('mk1_bastion');
      expect(bastion.lanceAlphaBonus, 1.0);
      expect(bastion.coreCapacity, 32);

      final monsoon = FleetService.instance.getChassis('mk2_monsoon');
      expect(monsoon.lanceAlphaBonus, 1.15);
      expect(monsoon.coreCapacity, 36);

      final singularity = FleetService.instance.getChassis('mk3_singularity');
      expect(singularity.lanceAlphaBonus, 1.30);
      expect(singularity.coreCapacity, 40);

      final golden = FleetService.instance.getChassis('mk4_golden_sovereign');
      expect(golden.lanceAlphaBonus, 1.40);
      expect(golden.coreCapacity, 44);
    });

    test(
      'CombatCoordinator initializes engine with chassis-specific lance multiplier and cores',
      () {
        final engine = MockVoidSowerEngine();
        final coordinator = CombatCoordinator(engine: engine);

        coordinator.initialize(chassisId: 'mk3_singularity');
        expect(engine.lanceAlphaMultiplier, 1.30);
        expect(coordinator.dreadnought.reserveCores, 40);

        coordinator.initialize(chassisId: 'mk2_monsoon');
        expect(engine.lanceAlphaMultiplier, 1.15);
        expect(coordinator.dreadnought.reserveCores, 36);

        // Explicit startingCores override takes precedence
        coordinator.initialize(chassisId: 'mk2_monsoon', startingCores: 16);
        expect(coordinator.dreadnought.reserveCores, 16);
      },
    );
  });

  group('Phase 15: Chrono-Anchor Turn Rewind', () {
    test(
      'Captures snapshots and enables rewind via Pro entitlement or emergency pass',
      () async {
        final engine = MockVoidSowerEngine();
        final coordinator = CombatCoordinator(engine: engine);

        coordinator.initialize(startingCores: 28);
        expect(coordinator.canChronoRewind, isFalse);

        final scoreBeforeTurn = coordinator.dreadnought.totalScore;

        // Perform a core injection to generate history
        coordinator.injectCore(0, 1);
        expect(
          coordinator.dreadnought.totalScore,
          greaterThanOrEqualTo(scoreBeforeTurn),
        );
        expect(
          coordinator.canChronoRewind,
          isFalse,
        ); // Locked because not Pro and no emergency rewinds

        // Grant emergency rewinds
        coordinator.grantEmergencyRewinds(2);
        expect(coordinator.canChronoRewind, isTrue);

        final success = coordinator.triggerChronoRewind();
        expect(success, isTrue);
        expect(coordinator.dreadnought.totalScore, scoreBeforeTurn);

        // Once snapshots are exhausted
        expect(coordinator.canChronoRewind, isFalse);
      },
    );

    test(
      'Permanent Pro unlock enables Chrono-Anchor rewinds indefinitely',
      () async {
        await PersistenceService.instance.setProUnlocked(true);
        final engine = MockVoidSowerEngine();
        final coordinator = CombatCoordinator(engine: engine);

        coordinator.initialize(startingCores: 28);
        coordinator.injectCore(2, -1);

        expect(coordinator.canChronoRewind, isTrue);
        expect(coordinator.triggerChronoRewind(), isTrue);
      },
    );
  });

  group('Phase 15: Native MCTS Solver & Holographic Advisor', () {
    test(
      'MockVoidSowerEngine solveTacticalStep evaluates best tactical choice',
      () {
        final engine = MockVoidSowerEngine();
        engine.initialize(startingCores: 28, boundaryY: 0.15);

        final result = engine.solveTacticalStep();
        expect(result, isNotNull);
        expect(result!.bayIndex, inInclusiveRange(0, 15));
        expect(result.direction == 1 || result.direction == -1, isTrue);
        expect(result.confidence, greaterThan(0.0));
      },
    );

    test(
      'TacticalSolverController in advisor mode updates advice without executing move',
      () {
        final engine = MockVoidSowerEngine();
        engine.initialize(startingCores: 28, boundaryY: 0.15);

        bool moveExecuted = false;
        final controller = TacticalSolverController(
          engine: engine,
          mode: TacticalSolverMode.advisor,
          onMoveSelected: (bay, dir, x) {
            moveExecuted = true;
          },
        );

        final dread = DreadnoughtState(
          orbitalPositionX: 0.5,
          targetPositionX: 0.5,
          reserveCores: 28,
          boundaryLineY: 0.15,
          isCascading: false,
          totalScore: 0,
          currentSimState: 0,
          coresUsed: 0,
        );

        final enemy = EnemyCraft(
          entityId: 1,
          assignedCorridor: 3,
          worldPosX: 0.4375,
          worldPosY: 0.5,
          velocityY: 0.05,
          currentShields: 0,
          maxShields: 0,
          currentHull: 100,
          maxHull: 100,
          vesselType: 0,
          isDestroyed: false,
        );

        controller.update(
          dt: 0.016,
          dreadnought: dread,
          bays: engine.getBays(),
          enemies: [enemy],
        );

        // In advisor mode, currentAdvice is calculated, but move is not fired
        expect(controller.currentAdvice, isNotNull);
        expect(
          controller.currentAdvice!.recommendedBay,
          inInclusiveRange(0, 15),
        );
        expect(moveExecuted, isFalse);
      },
    );
  });

  group('Phase 15: Deep Sensor Telemetry in ProjectionShelf', () {
    testWidgets(
      'Renders quadratic formula and breach risk tag when Pro telemetry is active',
      (tester) async {
        await PersistenceService.instance.setProUnlocked(true);

        const prediction = PredictionResult(
          terminalBay: 12,
          terminalCorridor: 4,
          finalMass: 6,
          predictedDamage: 54.0,
          totalCascadeLaps: 1,
          triggersLance: true,
          triggersRelay: false,
        );

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: ProjectionShelf(
                prediction: prediction,
                selectedBay: 0,
                isDeepTelemetry: true,
                threatCorridorBreachProbability: 0.42,
              ),
            ),
          ),
        );

        // Verifies quadratic formula breakdown
        expect(find.textContaining('α × 6²'), findsOneWidget);
        // Verifies breach risk indicator
        expect(find.text('42% RISK'), findsOneWidget);
        // Verifies multi-lap tag
        expect(find.textContaining('1 LAPS'), findsOneWidget);
      },
    );

    testWidgets('Renders standard telemetry when Pro telemetry is inactive', (
      tester,
    ) async {
      const prediction = PredictionResult(
        terminalBay: 12,
        terminalCorridor: 4,
        finalMass: 6,
        predictedDamage: 36.0,
        totalCascadeLaps: 0,
        triggersLance: true,
        triggersRelay: false,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ProjectionShelf(
              prediction: prediction,
              selectedBay: 0,
              isDeepTelemetry: false,
            ),
          ),
        ),
      );

      expect(find.textContaining('M=6'), findsOneWidget);
      expect(find.textContaining('α × 6²'), findsNothing);
      expect(find.textContaining('RISK'), findsNothing);
    });
  });

  group('Phase 15: Orbital Simulation Lab & MCTS Benchmark Arena', () {
    testWidgets(
      'Displays Pro locked shield when user does not have clearance',
      (tester) async {
        final engine = MockVoidSowerEngine();

        await tester.pumpWidget(
          MaterialApp(home: SimulationLabScreen(engine: engine)),
        );

        expect(find.text('ORBITAL SIMULATION LAB'), findsOneWidget);
        expect(find.text('PRO COMMANDER CLEARANCE REQUIRED'), findsOneWidget);
        expect(find.text('UNLOCK PRO CLEARANCE'), findsOneWidget);
      },
    );

    testWidgets(
      'Unlocks tabs and runs 100-iteration MCTS benchmark when Pro unlocked',
      (tester) async {
        await PersistenceService.instance.setProUnlocked(true);
        final engine = MockVoidSowerEngine();

        await tester.pumpWidget(
          MaterialApp(home: SimulationLabScreen(engine: engine)),
        );

        expect(find.text('CUSTOM SORTIE'), findsOneWidget);
        expect(find.text('MCTS ARENA'), findsOneWidget);
        expect(find.text('ENDLESS HORDE'), findsOneWidget);

        // Switch to MCTS Benchmark Arena tab
        await tester.tap(find.text('MCTS ARENA'));
        await tester.pumpAndSettle();

        expect(find.text('NATIVE C++ MCTS SOLVER STRESS-TEST'), findsOneWidget);
        expect(
          find.text('EXECUTE 100-ITERATION MCTS BENCHMARK'),
          findsOneWidget,
        );

        // Trigger Benchmark execution
        await tester.tap(find.text('EXECUTE 100-ITERATION MCTS BENCHMARK'));
        await tester.pump(); // Starts timer

        // Allow 50ms Timer and 100 iterations to run
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pumpAndSettle();

        expect(
          find.text('BENCHMARK TELEMETRY RESULTS (100 ITERATIONS)'),
          findsOneWidget,
        );
        expect(
          find.text('FRAME TIME COMPLIANCE (16.6ms BUDGET)'),
          findsOneWidget,
        );
      },
    );
  });
}
