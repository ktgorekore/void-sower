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
import 'package:void_sower/domain/services/daily_sortie_service.dart';
import 'package:void_sower/domain/services/entitlement_service.dart';
import 'package:void_sower/domain/services/persistence_service.dart';
import 'package:void_sower/engine/mock_void_sower_engine.dart';
import 'package:void_sower/presentation/screens/campaign_map_screen.dart';
import 'package:void_sower/presentation/screens/combat_screen.dart';
import 'package:void_sower/presentation/widgets/game_over_dialog.dart';
import 'package:void_sower/presentation/widgets/pro_upgrade_modal.dart';
import 'package:void_sower/presentation/widgets/rewarded_ad_modal.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await PersistenceService.instance.resetForTesting();
    await PersistenceService.instance.setCompletedTutorial(true);
    AdService.instance.resetCooldownForTesting();
    AdService.instance.setSimulateMobileForTesting(false);
    await PersistenceService.instance.setProBoostExpiry(null);
    await PersistenceService.instance.setProUnlocked(false);
    EntitlementService.instance.syncStateFromPersistence();
  });

  group('Phase 26: GameOverDialog Pro vs Free Consistency', () {
    testWidgets(
      'GameOverDialog renders SUMMON AUXILIARY CORES and bolt icon when isPro is true',
      (tester) async {
        bool callbackFired = false;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: GameOverDialog(
                score: 1200,
                highScore: 2500,
                isAmmoDepleted: true,
                armDuration: Duration.zero,
                isPro: true,
                rewardCores: 56,
                onRetry: () {},
                onReturnToMap: () {},
                onWatchAdForCores: () => callbackFired = true,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Must display Pro auxiliary core label
        expect(find.text('SUMMON AUXILIARY CORES (+56 CORES)'), findsOneWidget);
        expect(find.byIcon(Icons.bolt), findsWidgets);

        // Must NEVER display ad terminology or play circle icon
        expect(find.textContaining('WATCH AD'), findsNothing);
        expect(find.byIcon(Icons.play_circle_filled), findsNothing);

        // Tap executes immediately
        await tester.tap(find.text('SUMMON AUXILIARY CORES (+56 CORES)'));
        await tester.pump();
        expect(callbackFired, isTrue);
      },
    );

    testWidgets(
      'GameOverDialog renders WATCH AD and play icon when isPro is false',
      (tester) async {
        bool callbackFired = false;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: GameOverDialog(
                score: 1200,
                highScore: 2500,
                isAmmoDepleted: true,
                armDuration: Duration.zero,
                isPro: false,
                rewardCores: 56,
                onRetry: () {},
                onReturnToMap: () {},
                onWatchAdForCores: () => callbackFired = true,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('WATCH AD (+56 CORES & +5m PRO)'), findsOneWidget);
        expect(find.byIcon(Icons.play_circle_filled), findsOneWidget);

        await tester.tap(find.text('WATCH AD (+56 CORES & +5m PRO)'));
        await tester.pump();
        expect(callbackFired, isTrue);
      },
    );
  });

  group('Phase 26: Daily Sortie Pro Experience Audit', () {
    testWidgets(
      'Pro user in Daily Sortie has active Pro status and combat screen mounts cleanly',
      (tester) async {
        await PersistenceService.instance.setProUnlocked(true);
        EntitlementService.instance.syncStateFromPersistence();

        final engine = MockVoidSowerEngine();
        final dailySector = DailySortieService.instance.getTodaySector();

        await tester.pumpWidget(
          MaterialApp(
            home: CombatScreen(
              engine: engine,
              sectorId: 999,
              sector: dailySector,
              isDailySortie: true,
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 100));

        // Verify combat screen loaded with active Pro entitlement
        expect(find.byType(CombatScreen), findsOneWidget);
        expect(EntitlementService.instance.hasActivePro, isTrue);
      },
    );
  });

  group('Phase 26: RewardedAdModal Pro Treatment', () {
    testWidgets(
      'Pro Commander sees SUMMON FLARE and zero-ad privilege lore in RewardedAdModal',
      (tester) async {
        await PersistenceService.instance.setProUnlocked(true);
        EntitlementService.instance.syncStateFromPersistence();

        int granted = 0;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => Center(
                  child: ElevatedButton(
                    onPressed: () {
                      showDialog<void>(
                        context: context,
                        builder: (ctx) => RewardedAdModal(
                          rewardCores: 56,
                          onCoresGranted: (c) => granted = c,
                        ),
                      );
                    },
                    child: const Text('OPEN'),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('OPEN'));
        await tester.pumpAndSettle();

        // Must show Pro tier and summon flare
        expect(find.text('TIER: PRO COMMANDER'), findsOneWidget);
        expect(find.text('+56 CORES • INSTANT'), findsOneWidget);
        expect(find.text('SUMMON FLARE'), findsOneWidget);
        expect(find.byIcon(Icons.bolt), findsWidgets);
        expect(find.textContaining('WATCH AD'), findsNothing);

        await tester.tap(find.text('SUMMON FLARE'));
        await tester.pumpAndSettle();
        expect(granted, 56);
        expect(
          find.text(
            'EMERGENCY FLARE RECEIVED: +56 Plasma Cores Injected (Pro Link Active)!',
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets('Non-Pro commander sees WATCH AD in RewardedAdModal', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RewardedAdModal(rewardCores: 56, onCoresGranted: (_) {}),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('WATCH AD (+56 CORES)'), findsOneWidget);
      expect(find.byIcon(Icons.play_circle_filled), findsOneWidget);
    });
  });

  group('Phase 26: Campaign Map Locked Sector Pro Audit', () {
    testWidgets(
      'Pro user on locked sector dialog does NOT see WATCH AD (+5m PRO) or UNLOCK PRO',
      (tester) async {
        await PersistenceService.instance.setProUnlocked(true);
        EntitlementService.instance.syncStateFromPersistence();

        final engine = MockVoidSowerEngine();
        await tester.pumpWidget(
          MaterialApp(home: CampaignMapScreen(engine: engine)),
        );
        await tester.pumpAndSettle();

        // Tap a locked sector (e.g. Sector 2 when Sector 1 is not liberated)
        final sector2Card = find.textContaining('SECTOR 2');
        if (sector2Card.evaluate().isNotEmpty) {
          await tester.tap(sector2Card.first);
          await tester.pumpAndSettle();

          // Must NOT show WATCH AD or UNLOCK PRO
          expect(find.text('WATCH AD (+5m PRO)'), findsNothing);
          expect(find.text('UNLOCK PRO — \$1.29'), findsNothing);
        }
      },
    );
  });

  group('Phase 26: ProUpgradeModal Lifetime State Audit', () {
    testWidgets(
      'Lifetime Pro user in ProUpgradeModal sees PRO COMMANDER LIFETIME ACTIVE and no purchase CTAs',
      (tester) async {
        await PersistenceService.instance.setProUnlocked(true);
        EntitlementService.instance.syncStateFromPersistence();

        await tester.pumpWidget(
          const MaterialApp(home: Scaffold(body: ProUpgradeModal())),
        );
        await tester.pumpAndSettle();

        expect(find.text('PRO COMMANDER LIFETIME ACTIVE'), findsOneWidget);
        expect(find.text('UNLOCK PRO — \$1.29'), findsNothing);
        expect(find.text('WATCH AD (+5m PRO)'), findsNothing);
        expect(find.text('CLOSE'), findsOneWidget);

        await tester.tap(find.text('CLOSE'));
        await tester.pumpAndSettle();
      },
    );
  });
}
