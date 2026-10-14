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
import 'package:void_sower/domain/models/narrative_transmission.dart';
import 'package:void_sower/domain/services/persistence_service.dart';
import 'package:void_sower/engine/mock_void_sower_engine.dart';
import 'package:void_sower/presentation/controllers/combat_coordinator.dart';
import 'package:void_sower/presentation/screens/combat_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const testSector1 = CampaignSector(
    sectorId: 1,
    name: 'Kilwa Gate',
    region: 'Outer Bastions',
    difficultyTier: 0,
    starsEarned: 0,
    bestScore: 0,
    campaignId: 'kilwa_basin',
    reinforcementQuota: 6,
  );

  const testSector2 = CampaignSector(
    sectorId: 2,
    name: 'Zanzibar Anchorage',
    region: 'Outer Bastions',
    difficultyTier: 1,
    starsEarned: 0,
    bestScore: 0,
    campaignId: 'kilwa_basin',
    reinforcementQuota: 6,
  );

  group('African Strategic Fusions & 3-Phase Checkpoints', () {
    late MockVoidSowerEngine engine;
    late CombatCoordinator coordinator;

    setUp(() async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      await PersistenceService.instance.resetForTesting();
      await PersistenceService.instance.setCompletedTutorial(true);
      engine = MockVoidSowerEngine()..initialize(startingCores: 32);
      coordinator = CombatCoordinator(engine: engine);
    });

    tearDown(() {
      coordinator.dispose();
    });

    test(
      'Bao Mtaji capture harvests +2 bonus seeds on enemy-aligned frontline hit',
      () {
        engine.generateWave(difficulty: 1, randomSeed: 42);
        engine.restoreSnapshot(
          bayCharges: <int>[1, 1, 1, 2, 2, 1, 1, 1, 0, 2, 2, 2, 2, 2, 2, 2],
          reserveCores: 20,
          totalScore: 0,
        );
        engine.spawnEnemy(
          corridor: 1,
          worldPosY: 0.55,
          velocityY: 12.0,
          shields: 50.0,
          hull: 100.0,
          vesselType: 0,
        );

        final beforeCharges = engine.getBays().fold<int>(
          0,
          (sum, b) => sum + b.chargeUnits,
        );
        final steps = engine.injectCore(8, 1);
        expect(steps, greaterThan(0));

        final afterCharges = engine.getBays().fold<int>(
          0,
          (sum, b) => sum + b.chargeUnits,
        );
        expect(engine.getLances(), isNotEmpty);
        expect(afterCharges, greaterThanOrEqualTo(beforeCharges - 2));
      },
    );

    test(
      'Direct Bay Discharge vents single frontline bay without sowing rotation',
      () {
        engine.generateWave(difficulty: 1, randomSeed: 42);
        engine.restoreSnapshot(
          bayCharges: List<int>.filled(16, 3),
          reserveCores: 20,
          totalScore: 0,
        );
        expect(engine.getBays()[10].chargeUnits, 3);
        expect(engine.getBays()[11].chargeUnits, 3);

        final discharged = engine.dischargeBay(10);
        expect(discharged, 1);
        expect(
          engine.getLances().last.totalDamage,
          greaterThanOrEqualTo(900.0),
        );

        final baysAfter = engine.getBays();
        expect(baysAfter[10].chargeUnits, anyOf(equals(0), equals(2)));
        expect(baysAfter[11].chargeUnits, 3);
      },
    );

    test(
      'Morabaraba 3-Bay Mill Triad triggers synchronized 1.5x 3-corridor barrage',
      () {
        coordinator.initialize(sector: testSector1);
        engine.restoreSnapshot(
          bayCharges: List<int>.filled(16, 3),
          reserveCores: 24,
          totalScore: 0,
        );
        coordinator.update(0.016, const Size(400, 800));

        expect(coordinator.hasActiveMillTriad, isTrue);
        expect(coordinator.activeMillTriadBays, containsAll(<int>[8, 9, 10]));

        final baysDischarged = coordinator.dischargeFrontlineBay(9);
        expect(baysDischarged, 3.0);
        expect(coordinator.lances.length, greaterThanOrEqualTo(3));
        expect(
          coordinator.damageNumbers.any(
            (d) => d.text.contains('MORABARABA MILL BARRAGE'),
          ),
          isTrue,
        );

        expect(coordinator.bays[8].chargeUnits, lessThan(3));
        expect(coordinator.bays[9].chargeUnits, lessThan(3));
        expect(coordinator.bays[10].chargeUnits, lessThan(3));
      },
    );

    test(
      'Malagasy Fanorona Approach & Withdrawal vector strikes damage aligned enemies',
      () {
        coordinator.initialize(sector: testSector2);
        engine.spawnEnemy(
          corridor: 3,
          worldPosY: 0.45,
          velocityY: 12.0,
          shields: 40.0,
          hull: 180.0,
          vesselType: 1,
        );
        coordinator.update(0.016, const Size(400, 800));

        coordinator.slidePosition2D(0.4375, 0.20);
        for (var i = 0; i < 35; i++) {
          coordinator.update(0.05, const Size(400, 800));
        }

        final approachDamage = coordinator.triggerFanoronaVectorStrike(
          isApproach: true,
        );
        expect(approachDamage, greaterThan(0.0));
        expect(coordinator.lastFanoronaVectorLabel, 'APPROACH');

        for (var i = 0; i < 35; i++) {
          coordinator.update(0.05, const Size(400, 800));
        }

        final withdrawalDamage = coordinator.triggerFanoronaVectorStrike(
          isApproach: false,
        );
        expect(withdrawalDamage, greaterThanOrEqualTo(0.0));
      },
    );

    test(
      'West African Yote Surgical Cull executes 800 DMG orbital strike on apex target',
      () {
        coordinator.initialize(sector: testSector2);
        engine.spawnEnemy(
          corridor: 4,
          worldPosY: 0.65,
          velocityY: 10.0,
          shields: 100.0,
          hull: 900.0,
          vesselType: 2,
        );
        coordinator.update(0.016, const Size(400, 800));

        final target = coordinator.enemies.firstWhere((e) => !e.isDestroyed);
        final initialIntegrity = target.currentShields + target.currentHull;

        final culled = engine.cullEnemy(target.entityId);
        expect(culled, 1);

        final updated = engine.getEnemies().firstWhere(
          (e) => e.entityId == target.entityId,
        );
        final afterIntegrity = updated.currentShields + updated.currentHull;
        expect(afterIntegrity, lessThan(initialIntegrity));
      },
    );

    test(
      '3-Phase Ascending Checkpoints transition from Vanguard -> Siege (Relic Draft) -> Apex Boss',
      () {
        coordinator.initialize(sector: testSector2);
        expect(
          coordinator.checkpointPhase,
          SectorCheckpointPhase.vanguardRecon,
        );
        expect(coordinator.activeTransmission, isNotNull);
        expect(
          coordinator.activeTransmission!.speaker,
          contains('ADMIRAL ZAWADI'),
        );

        for (var i = 0; i < 8; i++) {
          final living = coordinator.enemies
              .where((e) => !e.isDestroyed)
              .toList();
          if (living.isEmpty) break;
          engine.cullEnemy(living.first.entityId);
          engine.cullEnemy(living.first.entityId);
          coordinator.update(0.016, const Size(400, 800));
          if (coordinator.checkpointPhase ==
              SectorCheckpointPhase.tacticalSiege) {
            break;
          }
        }

        expect(
          coordinator.checkpointPhase,
          anyOf(
            SectorCheckpointPhase.tacticalSiege,
            SectorCheckpointPhase.apexBoss,
          ),
        );
        if (coordinator.checkpointPhase ==
            SectorCheckpointPhase.tacticalSiege) {
          expect(coordinator.checkpointMutationChoices.length, 3);
          final chosen = coordinator.checkpointMutationChoices.first;
          coordinator.selectCheckpointMutation(chosen);
          expect(coordinator.checkpointMutationChoices, isEmpty);
          expect(coordinator.activeMutations, contains(chosen));
        }

        for (var i = 0; i < 12; i++) {
          final living = coordinator.enemies
              .where((e) => !e.isDestroyed)
              .toList();
          if (living.length <= 1) break;
          engine.cullEnemy(living.first.entityId);
          engine.cullEnemy(living.first.entityId);
          coordinator.update(0.016, const Size(400, 800));
          if (coordinator.checkpointPhase == SectorCheckpointPhase.apexBoss) {
            break;
          }
        }

        expect(coordinator.checkpointPhase, SectorCheckpointPhase.apexBoss);
        expect(coordinator.surgicalCullCharges, greaterThanOrEqualTo(1));

        final chargesBefore = coordinator.surgicalCullCharges;
        final executed = coordinator.executeSurgicalCull();
        expect(executed, isTrue);
        expect(coordinator.surgicalCullCharges, chargesBefore - 1);
      },
    );

    testWidgets(
      'CombatScreen renders 3-Phase Checkpoint HUD, Comms Strip, and Mill Barrage chip',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(1080, 2400));
        addTearDown(() => tester.binding.setSurfaceSize(null));

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

        // Verify 3-Phase Checkpoint chip is visible.
        expect(find.textContaining('P1: RECON'), findsOneWidget);
        // Verify Afrofuturist Narrative Comms speaker is visible.
        expect(find.textContaining('ADMIRAL ZAWADI'), findsOneWidget);
      },
    );
  });
}
