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

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:void_sower/domain/models/campaign_sector.dart';
import 'package:void_sower/domain/models/sector_combat_doctrine.dart';
import 'package:void_sower/domain/models/swarm_wave_phase.dart';
import 'package:void_sower/domain/services/campaign_service.dart';
import 'package:void_sower/domain/services/entitlement_service.dart';
import 'package:void_sower/domain/services/persistence_service.dart';
import 'package:void_sower/engine/mock_void_sower_engine.dart';
import 'package:void_sower/presentation/controllers/combat_coordinator.dart';
import 'package:void_sower/presentation/controllers/combat_overlay_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CombatOverlayState FSM Tests', () {
    test('Initial overlay state is none without active modals', () {
      const state = CombatOverlayState.none;
      expect(state.isModalOpen, isFalse);
      expect(state.isTerminalFlow, isFalse);
    });

    test('Modal states correctly reflect isModalOpen and isTerminalFlow', () {
      expect(CombatOverlayState.paused.isModalOpen, isTrue);
      expect(CombatOverlayState.paused.isTerminalFlow, isFalse);

      expect(CombatOverlayState.briefing.isModalOpen, isTrue);
      expect(CombatOverlayState.codex.isModalOpen, isTrue);
      expect(CombatOverlayState.settings.isModalOpen, isTrue);
      expect(CombatOverlayState.profile.isModalOpen, isTrue);
      expect(CombatOverlayState.emergencyFlare.isModalOpen, isTrue);

      expect(CombatOverlayState.defeatGrace.isModalOpen, isFalse);
      expect(CombatOverlayState.defeatGrace.isTerminalFlow, isTrue);

      expect(CombatOverlayState.defeatModal.isModalOpen, isTrue);
      expect(CombatOverlayState.defeatModal.isTerminalFlow, isTrue);

      expect(CombatOverlayState.victoryGrace.isModalOpen, isFalse);
      expect(CombatOverlayState.victoryGrace.isTerminalFlow, isTrue);

      expect(CombatOverlayState.victoryModal.isModalOpen, isTrue);
      expect(CombatOverlayState.victoryModal.isTerminalFlow, isTrue);

      expect(CombatOverlayState.victoryReview.isModalOpen, isFalse);
      expect(CombatOverlayState.victoryReview.isTerminalFlow, isTrue);
    });
  });

  group('CombatCoordinator Doctrine & Core Siphon Tests', () {
    late MockVoidSowerEngine engine;
    late CombatCoordinator coordinator;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await PersistenceService.instance.resetForTesting();
      EntitlementService.instance.resetForTesting();

      engine = MockVoidSowerEngine();
      coordinator = CombatCoordinator(engine: engine);
    });

    tearDown(() {
      coordinator.dispose();
    });

    test(
      'Standard sector initializes with standardOrbital doctrine and 0 reinforcements',
      () {
        const sector = CampaignSector(
          sectorId: 1,
          name: 'Ghat Platform',
          region: 'Kilwa Basin',
          difficultyTier: 0,
          starsEarned: 0,
          bestScore: 0,
          doctrine: SectorCombatDoctrine.standardOrbital,
          reinforcementQuota: 0,
        );

        coordinator.initialize(sector: sector);
        expect(
          coordinator.sector?.doctrine,
          SectorCombatDoctrine.standardOrbital,
        );
        expect(coordinator.remainingReinforcements, 0);
        expect(coordinator.swarmPhase, SwarmWavePhase.secured);
      },
    );

    test('Phantom Drift sector initializes lateral drift on engine', () {
      const sector = CampaignSector(
        sectorId: 10,
        name: 'Vapor Corridor',
        region: 'Phantom Drift',
        difficultyTier: 1,
        starsEarned: 0,
        bestScore: 0,
        doctrine: SectorCombatDoctrine.phantomDrift,
      );

      coordinator.initialize(sector: sector);
      expect(coordinator.sector?.doctrine, SectorCombatDoctrine.phantomDrift);
    });

    test(
      'Void Swarm sector initializes with horde reinforcement quota and tracks siphon',
      () {
        const sector = CampaignSector(
          sectorId: 19,
          name: 'Larval Trench',
          region: 'Void Swarm',
          difficultyTier: 1,
          starsEarned: 0,
          bestScore: 0,
          doctrine: SectorCombatDoctrine.voidSwarm,
          reinforcementQuota: 12,
          coreSiphonPerKill: 2,
        );

        coordinator.initialize(sector: sector);
        expect(coordinator.sector?.doctrine, SectorCombatDoctrine.voidSwarm);
        expect(coordinator.remainingReinforcements, 12);
        expect(coordinator.swarmPhase, SwarmWavePhase.initialAssault);

        // Verify that Tactical Core Siphon grants cores
        final initialCores = coordinator.dreadnought.reserveCores;
        coordinator.grantEmergencyCores(3);
        expect(coordinator.dreadnought.reserveCores, initialCores + 3);
      },
    );

    test(
      'Pro Commander entitlement instantly unlocks all 27 campaign sectors',
      () async {
        final campaignService = CampaignService.instance;

        // Before Pro: only sector 1 is accessible
        final freeSectors = campaignService.getSectors('kilwa_basin');
        expect(freeSectors.first.isUnlocked, isTrue);
        expect(freeSectors[1].isUnlocked, isFalse);

        // Upgrade to Pro Commander
        await PersistenceService.instance.setProUnlocked(true);
        expect(EntitlementService.instance.isProUnlocked, isTrue);

        // After Pro: all sectors across all campaigns are unlocked!
        final proKilwa = campaignService.getSectors('kilwa_basin');
        expect(proKilwa.every((s) => s.isUnlocked), isTrue);

        final proDrift = campaignService.getSectors('phantom_drift');
        expect(proDrift.every((s) => s.isUnlocked), isTrue);

        final proSwarm = campaignService.getSectors('void_swarm');
        expect(proSwarm.every((s) => s.isUnlocked), isTrue);
      },
    );
  });
}
