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
import 'package:void_sower/domain/models/campaign_sector.dart';
import 'package:void_sower/domain/models/sector_combat_doctrine.dart';
import 'package:void_sower/domain/services/persistence_service.dart';
import 'package:void_sower/domain/state/combat_match_state.dart';
import 'package:void_sower/engine/mock_void_sower_engine.dart';
import 'package:void_sower/presentation/controllers/combat_coordinator.dart';
import 'package:void_sower/presentation/screens/combat_screen.dart';
import 'package:void_sower/presentation/screens/simulation_lab_screen.dart';
import 'package:void_sower/presentation/widgets/pause_menu_dialog.dart';
import 'package:void_sower/presentation/widgets/tactical_directives_modal.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await PersistenceService.instance.resetForTesting();
    await PersistenceService.instance.setCompletedTutorial(true);
    await PersistenceService.instance.setProUnlocked(true);
  });

  group('Phase 22: Simulation Lab UI & Custom Sortie Streamlining', () {
    testWidgets(
      'SimulationLabScreen displays clean labels, doctrine selector, and LAUNCH SIMULATION button',
      (tester) async {
        final mockEngine = MockVoidSowerEngine();

        await tester.pumpWidget(
          MaterialApp(home: SimulationLabScreen(engine: mockEngine)),
        );
        await tester.pumpAndSettle();

        // 1. Verify concise parameter labels
        expect(find.text('HOSTILE QUOTA'), findsOneWidget);
        expect(find.text('DESCENT SPEED'), findsOneWidget);
        expect(find.text('STARTING CORES'), findsOneWidget);
        expect(find.text('COMBAT DOCTRINE'), findsOneWidget);

        // 2. Verify doctrine options are present
        expect(find.text('STANDARD'), findsOneWidget);
        expect(find.text('DRIFT'), findsOneWidget);
        expect(find.text('SWARM'), findsOneWidget);

        // 3. Verify streamlined launch button
        expect(find.text('LAUNCH SIMULATION'), findsOneWidget);
        expect(find.text('INITIALIZE CUSTOM SIMULATION SORTIE'), findsNothing);
      },
    );

    testWidgets('Tapping doctrine selector toggles active doctrine', (
      tester,
    ) async {
      final mockEngine = MockVoidSowerEngine();

      await tester.pumpWidget(
        MaterialApp(home: SimulationLabScreen(engine: mockEngine)),
      );
      await tester.pumpAndSettle();

      // Tap SWARM doctrine
      await tester.tap(find.text('SWARM'));
      await tester.pumpAndSettle();

      // Tap DRIFT doctrine
      await tester.tap(find.text('DRIFT'));
      await tester.pumpAndSettle();

      // Tap STANDARD doctrine
      await tester.tap(find.text('STANDARD'));
      await tester.pumpAndSettle();
    });

    testWidgets(
      'Tapping LAUNCH SIMULATION navigates to CombatScreen with custom parameters',
      (tester) async {
        final mockEngine = MockVoidSowerEngine();

        await tester.pumpWidget(
          MaterialApp(home: SimulationLabScreen(engine: mockEngine)),
        );
        await tester.pumpAndSettle();

        // Tap LAUNCH SIMULATION
        await tester.tap(find.text('LAUNCH SIMULATION'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Verify CombatScreen is pushed
        expect(find.byType(CombatScreen), findsOneWidget);
      },
    );
  });

  group('Phase 22: Reinforcement Spawning & Victory Completion in Sim Lab', () {
    test(
      'CombatCoordinator spawns reinforcements regardless of doctrine until quota reached',
      () {
        final mockEngine = MockVoidSowerEngine();
        final coordinator = CombatCoordinator(engine: mockEngine);

        const customSector = CampaignSector(
          sectorId: 901,
          name: 'SIM LAB TEST',
          region: 'Orbital Holodeck',
          difficultyTier: 1,
          starsEarned: 0,
          bestScore: 0,
          isUnlocked: true,
          doctrine: SectorCombatDoctrine.standardOrbital,
          reinforcementQuota: 2,
          coreSiphonPerKill: 2,
        );

        coordinator.initialize(
          sector: customSector,
          startingCores: 28,
          initialVelocity: 0.025,
        );

        // Initial state
        expect(coordinator.dreadnought.reserveCores, equals(28));
        expect(coordinator.enemies.length, greaterThanOrEqualTo(1));

        final initialSpawnCount = mockEngine.getEnemies().length;

        // Simulate destroying an enemy during update
        final victim = coordinator.enemies.first;
        mockEngine.setEnemyDestroyedForTesting(victim.entityId, true);

        // Call update to trigger _handleEnemyNeutralized
        coordinator.update(0.016, const Size(400, 800));

        // Reinforcement should have been spawned into mockEngine
        expect(mockEngine.getEnemies().length, greaterThan(initialSpawnCount));
        coordinator.dispose();
      },
    );

    test(
      'CombatCoordinator transitions to victory when all reinforcements destroyed',
      () {
        final mockEngine = MockVoidSowerEngine();
        final coordinator = CombatCoordinator(engine: mockEngine);

        const customSector = CampaignSector(
          sectorId: 901,
          name: 'SIM LAB TEST',
          region: 'Orbital Holodeck',
          difficultyTier: 1,
          starsEarned: 0,
          bestScore: 0,
          isUnlocked: true,
          doctrine: SectorCombatDoctrine.standardOrbital,
          reinforcementQuota: 0, // No reinforcements remaining
          coreSiphonPerKill: 2,
        );

        coordinator.initialize(sector: customSector, startingCores: 28);

        // Destroy all existing enemies
        for (final e in mockEngine.getEnemies()) {
          mockEngine.setEnemyDestroyedForTesting(e.entityId, true);
        }
        // Set sim state to Victory (7)
        mockEngine.setSimStateForTesting(7);

        coordinator.update(0.016, const Size(400, 800));

        expect(coordinator.state.status, equals(CombatMatchStatus.victory));
        coordinator.dispose();
      },
    );
  });

  group('Phase 22: Rapid Shooting & Input Unlocking', () {
    test(
      'quickFireActiveCorridor finalizes pending sow and shoots without lock',
      () {
        final mockEngine = MockVoidSowerEngine();
        final coordinator = CombatCoordinator(engine: mockEngine);

        coordinator.initialize(startingCores: 20);
        expect(
          coordinator.state.status,
          equals(CombatMatchStatus.activeCombat),
        );

        // Initiate a sow (which transitions status to sowingSequence)
        coordinator.sow(8, 1);
        expect(
          coordinator.state.status,
          equals(CombatMatchStatus.sowingSequence),
        );

        // Rapidly fire axial lance: should immediately finalize pending sow and fire!
        coordinator.quickFireActiveCorridor();
        expect(
          coordinator.state.status,
          equals(CombatMatchStatus.activeCombat),
        );
        expect(coordinator.state.canReceiveInput, isTrue);

        // Subsequent quick fires succeed immediately
        coordinator.quickFireActiveCorridor();
        expect(
          coordinator.state.status,
          equals(CombatMatchStatus.activeCombat),
        );

        coordinator.dispose();
      },
    );

    test(
      'resumeCombat restores activeCombat even if previously in sowingSequence',
      () {
        final mockEngine = MockVoidSowerEngine();
        final coordinator = CombatCoordinator(engine: mockEngine);

        coordinator.initialize(startingCores: 20);
        coordinator.sow(8, 1);
        expect(
          coordinator.state.status,
          equals(CombatMatchStatus.sowingSequence),
        );

        coordinator.resumeCombat();
        expect(
          coordinator.state.status,
          equals(CombatMatchStatus.activeCombat),
        );
        expect(coordinator.state.canReceiveInput, isTrue);

        coordinator.dispose();
      },
    );
  });

  group('Phase 22: Dialog Navigation & Chained Pause/Resume Workflows', () {
    testWidgets(
      'Opening Pause Menu and navigating to Codex then dismissing resumes combat cleanly',
      (tester) async {
        final mockEngine = MockVoidSowerEngine();

        await tester.pumpWidget(
          MaterialApp(
            home: CombatScreen(
              engine: mockEngine,
              difficultyTier: 1,
              sectorId: 1,
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 50));

        // Open Pause Menu
        await tester.tap(find.byIcon(Icons.pause));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        expect(find.byType(PauseMenuDialog), findsOneWidget);

        // Tap Directives icon (Icons.menu_book) inside PauseMenuDialog
        await tester.tap(find.byIcon(Icons.menu_book));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));

        // Verify Codex modal is now open and PauseMenuDialog is closed
        expect(find.byType(PauseMenuDialog), findsNothing);
        expect(find.byType(TacticalDirectivesModal), findsOneWidget);

        // Dismiss Codex modal
        await tester.tap(find.byIcon(Icons.close));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));

        // Verify Codex is closed and combat screen is back to active combat
        expect(find.byType(TacticalDirectivesModal), findsNothing);
        expect(find.byType(CombatScreen), findsOneWidget);
      },
    );
  });
}
