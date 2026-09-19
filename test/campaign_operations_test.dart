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
import 'package:void_sower/domain/models/pro_feature.dart';
import 'package:void_sower/domain/models/sector_combat_doctrine.dart';
import 'package:void_sower/domain/models/sector_progression_status.dart';
import 'package:void_sower/domain/services/campaign_service.dart';
import 'package:void_sower/domain/services/entitlement_service.dart';
import 'package:void_sower/domain/services/persistence_service.dart';
import 'package:void_sower/engine/mock_void_sower_engine.dart';
import 'package:void_sower/presentation/screens/campaign_map_screen.dart';
import 'package:void_sower/presentation/screens/combat_screen.dart';
import 'package:void_sower/presentation/widgets/pro_upgrade_modal.dart';

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
      'Non-Pro user progression: Introductory teaser sector unlocked for all campaigns, further Pro sectors locked',
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
        // Sector 10 (teaser) is unlocked for all users!
        expect(driftSectors[0].sectorId, 10);
        expect(driftSectors[0].isUnlocked, true);
        expect(driftSectors[0].status, SectorProgressionStatus.accessible);
        expect(driftSectors[0].isProRequired, false);

        // Sectors 11-18 require Pro Commander clearance
        for (int i = 1; i < driftSectors.length; i++) {
          final s = driftSectors[i];
          expect(s.isUnlocked, false);
          expect(s.status, SectorProgressionStatus.locked);
          expect(s.isProRequired, true);
          expect(
            s.unlockRequirement,
            'Unlock Pro Commander clearance to deploy to Phantom Drift sectors.',
          );
        }

        final swarmSectors = CampaignService.instance.getSectorsForCampaign(
          'void_swarm',
        );
        // Sector 19 (teaser) is unlocked for all users!
        expect(swarmSectors[0].sectorId, 19);
        expect(swarmSectors[0].isUnlocked, true);
        expect(swarmSectors[0].status, SectorProgressionStatus.accessible);
        expect(swarmSectors[0].isProRequired, false);

        // Sectors 20-27 require Pro Commander clearance
        for (int i = 1; i < swarmSectors.length; i++) {
          final s = swarmSectors[i];
          expect(s.isUnlocked, false);
          expect(s.status, SectorProgressionStatus.locked);
          expect(s.isProRequired, true);
          expect(
            s.unlockRequirement,
            'Unlock Pro Commander clearance to deploy to Void Swarm sectors.',
          );
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

    testWidgets(
      'CampaignMapScreen displays theater switcher tabs and PRO locked badges',
      (tester) async {
        final mockEngine = MockVoidSowerEngine();
        await tester.pumpWidget(
          MaterialApp(home: CampaignMapScreen(engine: mockEngine)),
        );
        await tester.pumpAndSettle();

        // Check theater switcher tabs
        expect(find.text('KILWA BASIN'), findsOneWidget);
        expect(find.text('PHANTOM DRIFT'), findsOneWidget);
        expect(find.text('VOID SWARM'), findsOneWidget);

        // For non-pro, PRO badges are visible
        expect(find.text('PRO'), findsWidgets);
      },
    );

    testWidgets(
      'Free users can switch to Pro theaters, view teaser sector, and tap locked sector to open ProUpgradeModal',
      (tester) async {
        final mockEngine = MockVoidSowerEngine();
        await tester.pumpWidget(
          MaterialApp(home: CampaignMapScreen(engine: mockEngine)),
        );
        await tester.pumpAndSettle();

        // Tap on PHANTOM DRIFT tab
        await tester.tap(find.text('PHANTOM DRIFT'));
        await tester.pumpAndSettle();

        // Theater switches and displays Sector 10 unlocked
        expect(find.text('Aldabra Shimmer Rift'), findsOneWidget);
        expect(find.text('PHANTOM DRIFT • LATERAL EVASION'), findsOneWidget);
        expect(find.text('ENGAGE'), findsOneWidget);

        // Sector 11 is locked
        expect(find.text('Cosmoledo Mirage Shoals'), findsOneWidget);
        await tester.tap(find.text('Cosmoledo Mirage Shoals'));
        await tester.pumpAndSettle();

        // Locked dialog opens with Pro upgrade option
        expect(find.text('IMPERIAL ORBITAL BLOCKADE DETECTED'), findsOneWidget);
        expect(
          find.text(
            'Unlock Pro Commander clearance to deploy to Phantom Drift sectors.',
          ),
          findsOneWidget,
        );
        expect(find.text('INSTANTLY UNLOCK ALL SECTORS • PRO'), findsOneWidget);

        // Tap Pro upgrade button
        await tester.tap(find.text('INSTANTLY UNLOCK ALL SECTORS • PRO'));
        await tester.pumpAndSettle();

        // Modal should open
        expect(find.byType(ProUpgradeModal), findsOneWidget);
        expect(find.text('PRO COMMANDER FLEET'), findsOneWidget);
      },
    );

    testWidgets(
      'With Pro unlocked, switching campaign theater updates sectors and doctrine banner',
      (tester) async {
        await PersistenceService.instance.setProUnlocked(true);
        final mockEngine = MockVoidSowerEngine();

        await tester.pumpWidget(
          MaterialApp(home: CampaignMapScreen(engine: mockEngine)),
        );
        await tester.pumpAndSettle();

        // Initially in Kilwa Basin
        expect(find.text('Zanzibar Reef Gate'), findsOneWidget);

        // Tap on PHANTOM DRIFT tab
        await tester.tap(find.text('PHANTOM DRIFT'));
        await tester.pumpAndSettle();

        // Doctrine banner and Phantom Drift sector should now be displayed
        expect(find.text('Aldabra Shimmer Rift'), findsOneWidget);
        expect(find.text('PHANTOM DRIFT • LATERAL EVASION'), findsOneWidget);

        // Tap on VOID SWARM tab
        await tester.tap(find.text('VOID SWARM'));
        await tester.pumpAndSettle();

        // Void Swarm sector and doctrine banner should be displayed
        expect(find.text('Comoros Hive Gate'), findsOneWidget);
        expect(
          find.text('VOID SWARM • HORDE CRUCIBLE & CORE SIPHON'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'Launching sector from Pro campaign displays doctrine badge on HUD',
      (tester) async {
        await PersistenceService.instance.setProUnlocked(true);
        final mockEngine = MockVoidSowerEngine();

        await tester.pumpWidget(
          MaterialApp(home: CampaignMapScreen(engine: mockEngine)),
        );
        await tester.pumpAndSettle();

        // Switch to PHANTOM DRIFT
        await tester.tap(find.text('PHANTOM DRIFT'));
        await tester.pumpAndSettle();

        // Engage Sector 10
        await tester.tap(find.text('ENGAGE').first);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Should be in CombatScreen
        expect(find.byType(CombatScreen), findsOneWidget);
        // Doctrine badge should show DRIFT • S10
        expect(find.text('DRIFT • S10'), findsOneWidget);
      },
    );

    testWidgets(
      'Free users can directly launch Sector 10 and Sector 19 teaser sectors',
      (tester) async {
        final mockEngine = MockVoidSowerEngine();
        await tester.pumpWidget(
          MaterialApp(home: CampaignMapScreen(engine: mockEngine)),
        );
        await tester.pumpAndSettle();

        // 1. Switch to PHANTOM DRIFT as a free user
        await tester.tap(find.text('PHANTOM DRIFT'));
        await tester.pumpAndSettle();

        // Engage Sector 10
        await tester.tap(find.text('ENGAGE').first);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Enters CombatScreen with Phantom Drift doctrine badge
        expect(find.byType(CombatScreen), findsOneWidget);
        expect(find.text('DRIFT • S10'), findsOneWidget);

        // Return to map
        Navigator.of(tester.element(find.byType(CombatScreen))).pop();
        await tester.pumpAndSettle();

        // 2. Switch to VOID SWARM as a free user
        await tester.tap(find.text('VOID SWARM'));
        await tester.pumpAndSettle();

        // Engage Sector 19
        await tester.tap(find.text('ENGAGE').first);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Enters CombatScreen with Void Swarm doctrine badge
        expect(find.byType(CombatScreen), findsOneWidget);
        expect(find.text('SWARM • S19'), findsOneWidget);
      },
    );
  });
}
