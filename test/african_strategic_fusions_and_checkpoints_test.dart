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
import 'package:void_sower/domain/models/space_anomaly.dart';
import 'package:void_sower/domain/services/persistence_service.dart';
import 'package:void_sower/engine/mock_void_sower_engine.dart';
import 'package:void_sower/presentation/controllers/combat_coordinator.dart';
import 'package:void_sower/presentation/screens/combat_screen.dart';
import 'package:void_sower/presentation/widgets/combat_camera_3d.dart';

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

        // Sowing harvests +2 bonus seeds into adjacent bays without auto-firing.
        final afterCharges = engine.getBays().fold<int>(
          0,
          (sum, b) => sum + b.chargeUnits,
        );
        expect(engine.getLances(), isEmpty);
        expect(afterCharges, greaterThanOrEqualTo(beforeCharges + 2));

        // Explicit discharge fires the accumulated frontline bay charge.
        expect(engine.dischargeBay(9), equals(1));
        expect(engine.getLances(), isNotEmpty);
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

    test(
      'CombatCamera3D projects 3D trench depth, vertical altitude, and unprojects floor coordinates',
      () {
        const size = Size(400.0, 800.0);
        const chaseCam = CombatCamera3D();
        final nearProj = chaseCam.project(
          size,
          normX: 0.25,
          normZ: 0.0,
          elevationY: 0.0,
        );
        final farProj = chaseCam.project(
          size,
          normX: 0.25,
          normZ: 1.0,
          elevationY: 0.20,
        );

        // Far horizon must converge toward center X and higher on screen (smaller Y)
        expect(farProj.screenOffset.dy, lessThan(nearProj.screenOffset.dy));
        expect(farProj.perspectiveScale, lessThan(nearProj.perspectiveScale));
        // 3D vertical altitude must lift screenOffset above groundOffset
        expect(farProj.screenOffset.dy, lessThan(farProj.groundOffset.dy));

        // Unprojecting a floor point returns valid normalized coordinates
        final unproj = chaseCam.unprojectToTrenchFloor(
          size,
          nearProj.groundOffset,
        );
        expect(unproj.dx, closeTo(0.25, 0.05));
        expect(unproj.dy, closeTo(0.0, 0.05));

        // Cycling camera modes steps through CHASE 3D -> BRIDGE 3D -> ORBIT 3D -> TOP-DOWN
        final bridgeCam = chaseCam.nextMode();
        expect(bridgeCam.mode, CombatCameraMode.bridge3D);
        expect(bridgeCam.yawDeg, closeTo(-22.0, 0.01));

        // Verify exact algebraic unprojection under oblique 3D yaw & chase parallax
        final orbitCam = bridgeCam.copyWith(followX: 0.68, followZ: 0.14);
        final obliqueProj = orbitCam.project(
          size,
          normX: 0.72,
          normZ: 0.38,
          elevationY: 0.0,
        );
        final obliqueUnproj = orbitCam.unprojectToTrenchFloor(
          size,
          obliqueProj.groundOffset,
        );
        expect(obliqueUnproj.dx, closeTo(0.72, 0.01));
        expect(obliqueUnproj.dy, closeTo(0.38, 0.01));
      },
    );

    test(
      'Decoupled sowing redistributes cores without auto-firing until explicitly discharged',
      () {
        coordinator.initialize(sector: testSector1);
        expect(coordinator.lances, isEmpty);

        // Sowing from Bay 8 redistributes cores without spawning a lance
        coordinator.sow(8, 1);
        expect(coordinator.lances, isEmpty);

        // Explicit frontline bay discharge fires the accumulated charge
        final dmg = coordinator.dischargeFrontlineBay(9);
        expect(dmg, greaterThan(0.0));
        expect(coordinator.lances, isNotEmpty);
      },
    );

    test(
      '3D Space Anomalies drift toward Defender and grant rewards on interception or lance hit',
      () {
        coordinator.initialize(sector: testSector1);
        final initialCores = coordinator.dreadnought.reserveCores;

        // Spawn a coreCache anomaly right ahead of the Defender in Corridor 3
        final slot = coordinator.spawnSpaceAnomaly(
          corridor: 3,
          type: SpaceAnomalyType.coreCache,
          normZ: 0.08,
        );
        expect(slot, isNotNull);
        expect(slot!.active, isTrue);

        // Step simulation so the Defender intercepts the drifting anomaly in 3D space
        coordinator.slidePosition2D(0.4375, 0.18);
        coordinator.update(0.05, const Size(400, 800));

        expect(coordinator.anomaliesDiscovered, equals(1));
        expect(coordinator.dreadnought.reserveCores, equals(initialCores + 4));

        // Spawn an ionNebulaSurge anomaly in Corridor 5 and intercept via lance fire
        final surgeSlot = coordinator.spawnSpaceAnomaly(
          corridor: 5,
          type: SpaceAnomalyType.ionNebulaSurge,
          normZ: 0.65,
        );
        expect(surgeSlot, isNotNull);
        final cullBefore = coordinator.surgicalCullCharges;

        coordinator.dischargeFrontlineBay(13); // Bay 13 = Corridor 5
        expect(coordinator.anomaliesDiscovered, equals(2));
        expect(coordinator.surgicalCullCharges, equals(cullBefore + 1));
      },
    );

    testWidgets(
      'CombatScreen renders unified single-bar top HUD without secondary comms/story overlays, removes manual camera gimbal buttons, and banks 3D camera automatically',
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

        // Verify unified single top HUD bar, Gmail-style profile avatar, Star Map button, and Special Ops shortcut render
        expect(find.byKey(const Key('unified_top_hud_bar')), findsOneWidget);
        expect(find.byKey(const Key('hud_profile_avatar')), findsOneWidget);
        expect(find.byKey(const Key('hud_map_button')), findsOneWidget);
        expect(find.byKey(const Key('hud_special_ops_button')), findsOneWidget);

        // Verify secondary top HUD overlays (comms banner, story act pill, relic bar) are omitted
        expect(find.byKey(const Key('narrative_comms_banner')), findsNothing);
        expect(find.byKey(const Key('story_act_status_pill')), findsNothing);
        expect(find.text('RELIC:'), findsNothing);

        // Verify manual 2D/3D camera gimbal buttons are removed
        expect(find.byKey(const Key('camera_mode_button')), findsNothing);
        expect(find.byKey(const Key('camera_yaw_stbd_button')), findsNothing);

        // Verify automatic 3D camera banks and pitches dynamically when Dreadnought moves
        mockEngine.setDreadnoughtTarget(0.85, 0.45);
        await tester.pump(const Duration(milliseconds: 50));
        final dynamic screenState = tester.state(find.byType(CombatScreen));
        expect(screenState.camera3D.pitchDeg, greaterThan(25.0));

        // Verify visual-first Bottom Command Dock renders short 1-word labels without multi-line text or advisory strip
        expect(
          find.byKey(const Key('dock_center_turret_pill')),
          findsOneWidget,
        );
        expect(find.byKey(const Key('dock_fire_button')), findsOneWidget);
        expect(find.text('‹ SOW'), findsOneWidget);
        expect(find.text('SOW ›'), findsOneWidget);
        expect(find.text('BLAST'), findsOneWidget);
        expect(find.textContaining('TOTEM #'), findsNothing);
        expect(find.textContaining('SHOOT = +SEEDS'), findsNothing);
      },
    );

    test(
      'Frontline bays never auto-fire without player command, Shoot-to-Harvest sows seeds on kill, and enemies evade charged lanes',
      () {
        engine.initialize(startingCores: 20, boundaryY: 0.15);
        engine.spawnEnemy(
          corridor: 2,
          worldPosY: 0.75,
          velocityY: 0.0,
          shields: 0.0,
          hull: 500.0,
          vesselType: 1,
        );
        engine.spawnEnemy(
          corridor: 5,
          worldPosY: 0.85,
          velocityY: 0.0,
          shields: 0.0,
          hull: 500.0,
          vesselType: 1,
        );
        final charges = List<int>.filled(16, 0);
        charges[10] = 3; // Charged frontline Bay 10 (Corridor 2)
        engine.restoreSnapshot(
          bayCharges: charges,
          reserveCores: 20,
          totalScore: 0,
        );

        // Step 2.0s without player firing: bay must NOT auto-fire passively
        for (var i = 0; i < 40; i++) {
          engine.stepSimulation(0.05);
        }

        expect(engine.getBays()[10].chargeUnits, equals(3));
        final c2Enemy = engine.getEnemies().firstWhere(
          (e) => e.assignedCorridor == 2,
        );
        expect(c2Enemy.currentHull, equals(500.0));

        // Enable lateral drift: enemy in charged Corridor 2 actively evades toward uncharged Corridor 1
        engine.setLateralDrift(true);
        for (var i = 0; i < 20; i++) {
          engine.stepSimulation(0.05);
        }
        final driftedEnemy = engine.getEnemies().first;
        expect(driftedEnemy.worldPosX, lessThan(2.5 / 8.0));

        // Finish a fresh invader via player-triggered dischargeBay and verify Shoot-to-Harvest sows +1 seed into Bay 11
        engine.setLateralDrift(false);
        engine.spawnEnemy(
          corridor: 2,
          worldPosY: 0.65,
          velocityY: 0.0,
          shields: 0.0,
          hull: 80.0,
          vesselType: 0,
        );
        charges[10] = 1;
        engine.restoreSnapshot(
          bayCharges: charges,
          reserveCores: 20,
          totalScore: 0,
        );
        expect(engine.dischargeBay(10), equals(1));
        engine.stepSimulation(0.05);
        expect(engine.getBays()[11].chargeUnits, equals(1));
      },
    );
  });
}
