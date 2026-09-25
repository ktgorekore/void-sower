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
import 'package:void_sower/domain/services/ad_service.dart';
import 'package:void_sower/domain/services/persistence_service.dart';
import 'package:void_sower/domain/state/combat_match_state.dart';
import 'package:void_sower/engine/mock_void_sower_engine.dart';
import 'package:void_sower/presentation/controllers/combat_coordinator.dart';
import 'package:void_sower/presentation/screens/campaign_map_screen.dart';
import 'package:void_sower/presentation/screens/combat_screen.dart';
import 'package:void_sower/presentation/widgets/hud_header.dart';
import 'package:void_sower/presentation/widgets/pro_upgrade_modal.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await PersistenceService.instance.resetForTesting();
    await PersistenceService.instance.setCompletedTutorial(true);
    AdService.instance.resetCooldownForTesting();
    AdService.instance.setSimulateMobileForTesting(false);
  });

  group('Phase 20 Fix 1: AdService Reward Verification & Bypass Elimination', () {
    test(
      'Non-Pro pilot returns false when ad cannot be loaded or shown',
      () async {
        final adService = AdService.instance;
        adService.setSimulateMobileForTesting(true);
        adService.setRewardedAdForTesting(null);

        // On mobile environment with no cached ad and mock platform failing to load,
        // showRewardedAd must return false rather than granting a free pass.
        final rewarded = await adService.showRewardedAd();
        expect(rewarded, isFalse);
      },
    );

    test(
      'Pro Commander receives instant bypass without requiring ads',
      () async {
        await PersistenceService.instance.setProUnlocked(true);
        final adService = AdService.instance;
        adService.setSimulateMobileForTesting(true);

        final rewarded = await adService.showRewardedAd();
        expect(rewarded, isTrue);
      },
    );

    test('Configuration suppression grants instant bypass', () async {
      await PersistenceService.instance.setAdsDisabled(true);
      final adService = AdService.instance;
      adService.setSimulateMobileForTesting(true);

      final rewarded = await adService.showRewardedAd();
      expect(rewarded, isTrue);
    });

    test('Emergency flare enforces cooldown between requests', () async {
      final adService = AdService.instance;
      expect(adService.canRequestEmergencyFlare, isTrue);

      // Trigger flare bypass on desktop
      final rewarded = await adService.showRewardedAd(isEmergencyFlare: true);
      expect(rewarded, isTrue);

      // Immediately after, flare is on cooldown
      expect(adService.canRequestEmergencyFlare, isFalse);

      final secondAttempt = await adService.showRewardedAd(
        isEmergencyFlare: true,
      );
      expect(secondAttempt, isFalse);
    });
  });

  group('Phase 20 Fix 2: In-Engine Pro Discovery & Compact Status Badge', () {
    testWidgets(
      'HudHeader displays compact Pro discovery badge for non-Pro pilot',
      (tester) async {
        bool proTapped = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: HudHeader(
                reserveCores: 20,
                score: 1200,
                highScore: 4000,
                isPro: false,
                difficultyTier: 1,
                sectorId: 1,
                onProTap: () => proTapped = true,
              ),
            ),
          ),
        );

        // Verifies compact PRO badge exists in the HUD
        expect(find.text('PRO'), findsOneWidget);
        expect(find.byIcon(Icons.workspace_premium_outlined), findsOneWidget);

        // Tapping badge triggers onProTap
        await tester.tap(find.text('PRO'));
        await tester.pump();
        expect(proTapped, isTrue);
      },
    );

    testWidgets('HudHeader displays radiant gold badge for Pro Commander', (
      tester,
    ) async {
      bool proTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HudHeader(
              reserveCores: 20,
              score: 2500,
              highScore: 5000,
              isPro: true,
              difficultyTier: 1,
              sectorId: 1,
              onProTap: () => proTapped = true,
            ),
          ),
        ),
      );

      // Pro commander displays filled gold icon
      expect(find.text('PRO'), findsOneWidget);
      expect(find.byIcon(Icons.workspace_premium), findsOneWidget);

      await tester.tap(find.text('PRO'));
      await tester.pump();
      expect(proTapped, isTrue);
    });

    testWidgets('Tapping Pro badge in CombatScreen opens ProUpgradeModal', (
      tester,
    ) async {
      final mockEngine = MockVoidSowerEngine();

      await tester.pumpWidget(
        MaterialApp(home: CombatScreen(engine: mockEngine)),
      );
      await tester.pump(const Duration(milliseconds: 50));

      // Tap PRO badge in top-left wing
      expect(find.text('PRO'), findsOneWidget);
      await tester.tap(find.text('PRO'));
      await tester.pump(const Duration(milliseconds: 200));

      // ProUpgradeModal is presented
      expect(find.byType(ProUpgradeModal), findsOneWidget);
    });
  });

  group(
    'Phase 20 Fix 3: CombatScreen Ticker Resumption & App Lifecycle Unfreeze',
    () {
      testWidgets(
        'CombatScreen handles lifecycle changes and modal dismissals cleanly',
        (tester) async {
          final mockEngine = MockVoidSowerEngine();

          await tester.pumpWidget(
            MaterialApp(home: CombatScreen(engine: mockEngine)),
          );
          await tester.pump(const Duration(milliseconds: 50));

          // Open Pro modal
          await tester.tap(find.text('PRO'));
          await tester.pump(const Duration(milliseconds: 200));
          expect(find.byType(ProUpgradeModal), findsOneWidget);

          // Close modal
          final closeButton = find.byIcon(Icons.close);
          if (closeButton.evaluate().isNotEmpty) {
            await tester.tap(closeButton.first);
          } else {
            await tester.tapAt(const Offset(10, 10));
          }
          await tester.pump(const Duration(milliseconds: 200));
          expect(find.byType(ProUpgradeModal), findsNothing);

          // Simulate app backgrounding and foregrounding as during AdMob AdActivity
          tester.binding.handleAppLifecycleStateChanged(
            AppLifecycleState.paused,
          );
          await tester.pump(const Duration(milliseconds: 50));

          tester.binding.handleAppLifecycleStateChanged(
            AppLifecycleState.resumed,
          );
          await tester.pump(const Duration(milliseconds: 50));

          // Simulation continues rendering without crashing or freezing
          expect(find.byType(CombatScreen), findsOneWidget);
        },
      );
    },
  );

  group('Phase 20 Fix 4: Tactical Lance Continuity & Sector Clearance', () {
    test(
      'CombatCoordinator preserves active lances during victory state for visual decay',
      () {
        final engine = MockVoidSowerEngine();
        final coordinator = CombatCoordinator(
          engine: engine,
          difficultyTier: 1,
        );
        coordinator.initialize(startingCores: 28, boundaryY: 0.15);

        // Create an active lance
        coordinator.quickFireActiveCorridor();
        expect(coordinator.lances.isNotEmpty, isTrue);

        // Force state transition to victory (as when last invader is eliminated)
        coordinator.setMatchStatusForTesting(CombatMatchStatus.victory);

        // Step coordinator by 0.016s
        coordinator.update(0.016, const Size(400, 800));

        // Lance should NOT be wiped to empty instantly; it must remain visible and decay
        expect(coordinator.lances.isNotEmpty, isTrue);
        expect(coordinator.lances.first.remainingDuration, lessThan(0.50));
        expect(coordinator.lances.first.remainingDuration, greaterThan(0.0));

        coordinator.dispose();
      },
    );
  });

  group('Phase 20 Fix 5: Campaign Routing to Starter Campaign on Victory', () {
    test(
      'PersistenceService enforces kilwa_basin for non-Pro users even if pro campaign saved',
      () async {
        final persistence = PersistenceService.instance;
        expect(persistence.isProUnlocked, isFalse);

        // Attempt to set a pro campaign in preferences directly
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('active_campaign_id', 'phantom_drift');

        // activeCampaignId property must fall back to 'kilwa_basin' for non-pro users
        expect(persistence.activeCampaignId, equals('kilwa_basin'));
      },
    );

    testWidgets('CampaignMapScreen defaults to starter campaign kilwa_basin', (
      tester,
    ) async {
      final mockEngine = MockVoidSowerEngine();

      await tester.pumpWidget(
        MaterialApp(
          home: CampaignMapScreen(
            engine: mockEngine,
            initialCampaignId: 'kilwa_basin',
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Starter campaign tabs are rendered and active
      expect(find.text('KILWA BASIN'), findsOneWidget);
      expect(find.text('Zanzibar Reef Gate'), findsOneWidget);
    });
  });
}
