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
import 'package:void_sower/domain/models/pro_feature.dart';
import 'package:void_sower/domain/models/sector_combat_doctrine.dart';
import 'package:void_sower/domain/models/sector_progression_status.dart';
import 'package:void_sower/domain/services/campaign_service.dart';
import 'package:void_sower/domain/services/entitlement_service.dart';
import 'package:void_sower/domain/services/persistence_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await PersistenceService.instance.initialize();
    await PersistenceService.instance.resetForTesting();
    EntitlementService.instance.resetForTesting();
  });

  group('Campaign Operations & Multi-Theater Tests', () {
    test(
      'CampaignService returns 3 distinct operations with 9 sectors each',
      () {
        final operations = CampaignService.instance.getOperations();
        expect(operations.length, 3);

        final kilwa = operations[0];
        expect(kilwa.id, 'kilwa_basin');
        expect(kilwa.isProRequired, false);
        expect(kilwa.sectors.length, 9);
        expect(kilwa.defaultDoctrine, SectorCombatDoctrine.standardOrbital);

        final drift = operations[1];
        expect(drift.id, 'phantom_drift');
        expect(drift.isProRequired, true);
        expect(drift.sectors.length, 9);
        expect(drift.defaultDoctrine, SectorCombatDoctrine.phantomDrift);

        final swarm = operations[2];
        expect(swarm.id, 'void_swarm');
        expect(swarm.isProRequired, true);
        expect(swarm.sectors.length, 9);
        expect(swarm.defaultDoctrine, SectorCombatDoctrine.voidSwarm);
      },
    );

    test(
      'Non-Pro user progression: Kilwa Basin unlocked sequentially, Pro campaigns locked',
      () {
        final kilwaSectors = CampaignService.instance.getSectorsForCampaign(
          'kilwa_basin',
        );
        expect(kilwaSectors[0].isUnlocked, true);
        expect(kilwaSectors[0].status, SectorProgressionStatus.accessible);
        expect(kilwaSectors[1].isUnlocked, false);
        expect(kilwaSectors[1].status, SectorProgressionStatus.locked);

        final driftSectors = CampaignService.instance.getSectorsForCampaign(
          'phantom_drift',
        );
        for (final s in driftSectors) {
          expect(s.isUnlocked, false);
          expect(s.status, SectorProgressionStatus.locked);
        }

        final swarmSectors = CampaignService.instance.getSectorsForCampaign(
          'void_swarm',
        );
        for (final s in swarmSectors) {
          expect(s.isUnlocked, false);
          expect(s.status, SectorProgressionStatus.locked);
        }
      },
    );

    test(
      'PRO USERS: ALL 27 SECTORS START UNLOCKED ACROSS ALL THEATERS',
      () async {
        await PersistenceService.instance.setProUnlocked(true);
        expect(EntitlementService.instance.isProUnlocked, true);

        final allSectors = CampaignService.instance.getAllSectors();
        expect(allSectors.length, 27);

        for (final sector in allSectors) {
          expect(
            sector.isUnlocked,
            true,
            reason:
                'Sector ${sector.sectorId} (${sector.name}) should start unlocked for Pro',
          );
          expect(
            sector.status != SectorProgressionStatus.locked,
            true,
            reason: 'Sector ${sector.sectorId} should not be locked for Pro',
          );
        }
      },
    );

    test('Temporary Pass grants access to Pro campaign theaters', () {
      EntitlementService.instance.grantTemporaryPass(
        ProFeature.proCampaignTheaters,
        duration: const Duration(minutes: 30),
      );

      final driftSectors = CampaignService.instance.getSectorsForCampaign(
        'phantom_drift',
      );
      expect(driftSectors[0].isUnlocked, true);

      final swarmSectors = CampaignService.instance.getSectorsForCampaign(
        'void_swarm',
      );
      expect(swarmSectors[0].isUnlocked, true);
    });

    test(
      'Multi-campaign persistence tracks liberated sectors independently',
      () async {
        await PersistenceService.instance.recordSectorVictory(
          sectorId: 1,
          score: 2500,
          coresRemaining: 18,
        );
        expect(PersistenceService.instance.liberatedSectors, 2);

        await PersistenceService.instance.recordSectorVictory(
          sectorId: 10,
          score: 3200,
          coresRemaining: 20,
        );
        expect(
          PersistenceService.instance.getLiberatedSectorsForCampaign(
            'phantom_drift',
          ),
          2,
        );
        expect(
          PersistenceService.instance.liberatedSectors,
          2,
        ); // Kilwa remains 2
      },
    );
  });
}
