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
import 'package:void_sower/domain/services/campaign_service.dart';
import 'package:void_sower/domain/services/persistence_service.dart';
import 'package:void_sower/engine/mock_void_sower_engine.dart';
import 'package:void_sower/presentation/screens/campaign_map_screen.dart';
import 'package:void_sower/presentation/widgets/hud_header.dart';
import 'package:void_sower/presentation/widgets/victory_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await PersistenceService.instance.resetForTesting();
  });

  group('Campaign & Sector Progression Tests', () {
    test('CampaignSector model generates correct unlock requirements', () {
      const s1 = CampaignSector(
        sectorId: 1,
        name: 'Zanzibar Reef Gate',
        region: 'Outer Bastions',
        difficultyTier: 0,
        starsEarned: 0,
        isUnlocked: true,
        bestScore: 0,
      );
      expect(s1.unlockRequirement, 'Sector secured for orbital transit.');

      const s2 = CampaignSector(
        sectorId: 2,
        name: 'Pemba Channel Relay',
        region: 'Outer Bastions',
        difficultyTier: 0,
        starsEarned: 0,
        isUnlocked: false,
        bestScore: 0,
        requiredSectorId: 1,
        requiredSectorName: 'Zanzibar Reef Gate',
      );
      expect(
        s2.unlockRequirement,
        'Liberate Sector 1: Zanzibar Reef Gate to break imperial blockade.',
      );
    });

    test('CampaignService loads 9 sectors with proper prerequisites', () {
      final sectors = CampaignService.instance.getSectors();
      expect(sectors.length, 9);
      expect(sectors[0].sectorId, 1);
      expect(sectors[0].isUnlocked, isTrue);
      expect(sectors[0].isLiberated, isFalse);

      // Sector 2 is locked until Sector 1 is liberated
      expect(sectors[1].sectorId, 2);
      expect(sectors[1].isUnlocked, isFalse);
      expect(sectors[1].requiredSectorId, 1);
      expect(sectors[1].requiredSectorName, 'Zanzibar Reef Gate');
    });

    test(
      'PersistenceService records sector victory and advances frontier',
      () async {
        final p = PersistenceService.instance;
        expect(p.liberatedSectors, 1);
        expect(p.getSectorStars(1), 0);

        // Record victory on Sector 1 with 16 cores saved (flawless 3 stars)
        await p.recordSectorVictory(
          sectorId: 1,
          score: 3500,
          coresRemaining: 16,
          enemiesNeutralized: 4,
        );

        expect(p.liberatedSectors, 2);
        expect(p.getSectorStars(1), 3);
        expect(p.getSectorScore(1), 3500);
        expect(p.highScore, 3500);
        expect(p.userProfile.enemiesDestroyed, 4);
        expect(p.userProfile.lifetimeScore, 3500);

        // Check that CampaignService now shows Sector 1 liberated and Sector 2 unlocked
        final updatedSectors = CampaignService.instance.getSectors();
        expect(updatedSectors[0].isLiberated, isTrue);
        expect(updatedSectors[0].starsEarned, 3);
        expect(updatedSectors[1].isUnlocked, isTrue);
        expect(updatedSectors[1].isLiberated, isFalse);
      },
    );
  });

  group('VictoryDialog Widget Tests', () {
    testWidgets(
      'Displays sector name, stars label, and new unlock announcement',
      (tester) async {
        bool advanced = false;
        bool returnedToMap = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: VictoryDialog(
                sectorId: 1,
                sectorName: 'Zanzibar Reef Gate',
                score: 4200,
                coresRemaining: 18,
                isNewUnlock: true,
                unlockedSectorName: 'Pemba Channel Relay',
                campaignProgressText: '1 / 9 LIBERATED',
                onNextSector: () => advanced = true,
                onReturnToMap: () => returnedToMap = true,
              ),
            ),
          ),
        );

        expect(find.text('SECTOR 1 LIBERATED!'), findsOneWidget);
        expect(find.text('ZANZIBAR REEF GATE'), findsOneWidget);
        expect(find.text('★★★ FLAWLESS DEFENSE'), findsOneWidget);
        expect(find.text('NEW SECTOR UNLOCKED!'), findsOneWidget);
        expect(find.text('Sector 2: PEMBA CHANNEL RELAY'), findsOneWidget);
        expect(find.text('4200'), findsNWidgets(2));
        expect(find.text('18'), findsOneWidget);

        await tester.tap(find.text('ADVANCE TO NEXT SECTOR'));
        await tester.pumpAndSettle();
        expect(advanced, isTrue);

        await tester.tap(find.text('RETURN TO STAR MAP'));
        await tester.pumpAndSettle();
        expect(returnedToMap, isTrue);
      },
    );

    testWidgets(
      'VictoryDialog debounces premature taps until armDuration elapses',
      (tester) async {
        bool advanced = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: VictoryDialog(
                sectorId: 2,
                sectorName: 'Pemba Channel Relay',
                score: 5500,
                coresRemaining: 20,
                armDuration: const Duration(milliseconds: 500),
                onNextSector: () => advanced = true,
              ),
            ),
          ),
        );

        // Immediate tap during shooting cooldown should be ignored
        await tester.tap(find.text('ADVANCE TO NEXT SECTOR'));
        await tester.pump();
        expect(advanced, isFalse);

        // After 500ms safety cooldown, button arms and tap succeeds
        await tester.pump(const Duration(milliseconds: 500));
        await tester.tap(find.text('ADVANCE TO NEXT SECTOR'));
        await tester.pumpAndSettle();
        expect(advanced, isTrue);
      },
    );
  });

  group('HudHeader Progress Tracking Tests', () {
    testWidgets('Displays threat tier and live hostile elimination progress', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HudHeader(
              reserveCores: 20,
              score: 1500,
              difficultyTier: 0,
              sectorId: 1,
              sectorName: 'Zanzibar Reef Gate',
              totalInvaders: 4,
              invadersRemaining: 2,
              onSettingsTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('S1 • PATROL'), findsOneWidget);
      expect(find.text('2/4'), findsOneWidget);
    });

    testWidgets('Displays SECURED in emerald when 0 invaders remain', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HudHeader(
              reserveCores: 18,
              score: 3000,
              difficultyTier: 1,
              sectorId: 4,
              sectorName: 'Kaskazi Ion Stream',
              totalInvaders: 4,
              invadersRemaining: 0,
              onSettingsTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('S4 • SIEGE'), findsOneWidget);
      expect(find.text('SECURED'), findsOneWidget);
    });
  });

  group('CampaignMapScreen Locked Sector & Requirements Tests', () {
    testWidgets('Renders locked sectors with clear unlock requirements', (
      tester,
    ) async {
      final engine = MockVoidSowerEngine();

      await tester.pumpWidget(
        MaterialApp(home: CampaignMapScreen(engine: engine)),
      );
      await tester.pumpAndSettle();

      // Check header liberation counter
      expect(find.text('ORBITAL COMMAND DECK'), findsOneWidget);
      expect(find.text('LIBERATED: 0 / 9 (0%)'), findsOneWidget);

      // Check that Sector 1 has OBJECTIVE badge
      expect(find.text('OBJECTIVE'), findsOneWidget);
      expect(find.text('Zanzibar Reef Gate'), findsOneWidget);

      // Check that locked Sector 2 explicitly mentions how to unlock it
      expect(find.text('Pemba Channel Relay'), findsOneWidget);
      expect(
        find.text(
          'UNLOCK: Liberate Sector 1: Zanzibar Reef Gate to break imperial blockade.',
        ),
        findsOneWidget,
      );

      // Tapping on locked sector opens locked intel sheet
      await tester.tap(find.text('Pemba Channel Relay'));
      await tester.pumpAndSettle();

      expect(find.text('IMPERIAL ORBITAL BLOCKADE DETECTED'), findsOneWidget);
      expect(find.text('CLEARANCE REQUIREMENT'), findsOneWidget);
      expect(find.text('DEPLOY TO SECTOR 1'), findsOneWidget);

      // Dismiss locked intel sheet
      await tester.tap(find.text('DISMISS INTEL'));
      await tester.pumpAndSettle();
      expect(find.text('IMPERIAL ORBITAL BLOCKADE DETECTED'), findsNothing);
    });

    testWidgets(
      'CampaignMapScreen provides direct Flight Academy action in app bar and launches tutorial',
      (tester) async {
        final engine = MockVoidSowerEngine();

        await tester.pumpWidget(
          MaterialApp(home: CampaignMapScreen(engine: engine)),
        );
        await tester.pumpAndSettle();

        // Verify Flight Academy / Directives tab exists
        final academyIcon = find.byTooltip('Flight Academy');
        expect(academyIcon, findsOneWidget);
        expect(find.byIcon(Icons.school), findsOneWidget);

        // Tap Directives tab to open Tactical Directives modal
        await tester.tap(academyIcon);
        await tester.pumpAndSettle();

        // Tap HANDS-ON SIM to launch Flight Academy tutorial
        final simButton = find.text('HANDS-ON SIM');
        expect(simButton, findsOneWidget);
        await tester.tap(simButton);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));

        // Verify that the Flight Academy tutorial overlay is active over Sector 1
        expect(find.text('FLIGHT ACADEMY'), findsOneWidget);
        expect(find.text('Zanzibar Reef Gate'), findsAtLeastNWidgets(1));
      },
    );
  });
}
