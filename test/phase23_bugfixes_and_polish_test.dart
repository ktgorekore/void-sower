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
import 'package:void_sower/domain/services/ad_service.dart';
import 'package:void_sower/domain/services/entitlement_service.dart';
import 'package:void_sower/domain/services/persistence_service.dart';
import 'package:void_sower/domain/state/combat_match_state.dart';
import 'package:void_sower/engine/mock_void_sower_engine.dart';
import 'package:void_sower/presentation/controllers/combat_coordinator.dart';
import 'package:void_sower/presentation/screens/combat_screen.dart';
import 'package:void_sower/presentation/widgets/game_over_dialog.dart';
import 'package:void_sower/presentation/widgets/hud_header.dart';
import 'package:void_sower/presentation/widgets/pause_menu_dialog.dart';
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
    EntitlementService.instance.syncStateFromPersistence();
  });

  group('Bug 1: Core Replenishment & Lance Firing Recovery', () {
    test(
      'grantEmergencyCores revives match status and permits lance firing',
      () {
        final coordinator = CombatCoordinator(engine: MockVoidSowerEngine());
        coordinator.initialize(startingCores: 0, boundaryY: 0.15);

        // Simulate defeat from core exhaustion
        coordinator.setMatchStatusForTesting(CombatMatchStatus.defeat);
        expect(coordinator.state.canReceiveInput, isFalse);

        // Siphon or emergency core injection revives state
        coordinator.grantEmergencyCores(3);
        expect(coordinator.state.status, CombatMatchStatus.activeCombat);
        expect(coordinator.state.canReceiveInput, isTrue);
        expect(coordinator.dreadnought.reserveCores, 3);

        // Now firing quick fire corridor succeeds and fires lance
        coordinator.quickFireActiveCorridor();
        expect(coordinator.dreadnought.reserveCores, 2);
        expect(coordinator.sessionSeedsSown, 1);
      },
    );
  });

  group('Bug 2 & 5: GameOverDialog Rewarded Ad CTA & Standardized Button', () {
    testWidgets(
      'GameOverDialog presents WATCH AD (+8 CORES) and executes callback',
      (tester) async {
        bool adWatched = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: GameOverDialog(
                score: 1500,
                highScore: 3000,
                isAmmoDepleted: true,
                armDuration: Duration.zero,
                onRetry: () {},
                onReturnToMap: () {},
                onWatchAdForCores: () => adWatched = true,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Standardized button verification
        expect(find.text('WATCH AD (+8 CORES)'), findsOneWidget);
        expect(find.byIcon(Icons.play_circle_filled), findsOneWidget);

        await tester.tap(find.text('WATCH AD (+8 CORES)'));
        await tester.pump();
        expect(adWatched, isTrue);
      },
    );
  });

  group('Bug 3: Pro Boost Active Countdown Timer in HUD', () {
    testWidgets('HudHeader displays formatted timer when boost is active', (
      tester,
    ) async {
      EntitlementService.instance.grantStackableBoost(
        duration: const Duration(minutes: 5),
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HudHeader(
              reserveCores: 15,
              score: 800,
              isPro: false,
              difficultyTier: 1,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byIcon(Icons.timer), findsOneWidget);
      expect(
        find.text(EntitlementService.instance.formattedRemainingBoostTime),
        findsOneWidget,
      );
    });
  });

  group('Bug 4: Curiosity-Triggering Red Lock Badge for Non-Pro', () {
    testWidgets(
      'HudHeader displays prominent red lock badge for non-Pro users',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: HudHeader(
                reserveCores: 15,
                score: 800,
                isPro: false,
                difficultyTier: 1,
              ),
            ),
          ),
        );
        await tester.pump();

        expect(find.byIcon(Icons.lock_outline), findsOneWidget);
        expect(find.text('PRO'), findsOneWidget);
      },
    );
  });

  group('Bug 5 & 6: Standardized Watch Ad Buttons & Shortened Labels', () {
    testWidgets(
      'ProUpgradeModal renders standardized ad button and shortened purchase label',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: ProUpgradeModal(
                highlightedFeature: ProFeature.aiTacticalSolver,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('WATCH AD (+5m PRO)'), findsOneWidget);
        expect(find.byIcon(Icons.play_circle_filled), findsOneWidget);
        expect(find.text('UNLOCK PRO — \$1.29'), findsOneWidget);
      },
    );

    testWidgets('RewardedAdModal renders standardized WATCH AD (+8 CORES)', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: RewardedAdModal(onCoresGranted: (_) {})),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('WATCH AD (+8 CORES)'), findsOneWidget);
      expect(find.byIcon(Icons.play_circle_filled), findsOneWidget);
    });
  });

  group('Bug 7: Pause Menu Pro Icon Interactivity', () {
    testWidgets(
      'Tapping Pro AI Solver in pause menu opens ProUpgradeModal for non-pro user',
      (tester) async {
        final engine = MockVoidSowerEngine();
        await tester.pumpWidget(
          MaterialApp(home: CombatScreen(engine: engine)),
        );
        await tester.pump(const Duration(milliseconds: 50));

        // Tap Pause button in HUD
        await tester.tap(find.byIcon(Icons.pause));
        await tester.pump(const Duration(milliseconds: 200));

        expect(find.byType(PauseMenuDialog), findsOneWidget);

        // Tap Pro AI Solver icon in PauseMenuDialog
        expect(find.byIcon(Icons.smart_toy), findsOneWidget);
        await tester.tap(find.byIcon(Icons.smart_toy));
        await tester.pump(const Duration(milliseconds: 200));

        // ProUpgradeModal is presented
        expect(find.byType(ProUpgradeModal), findsOneWidget);
      },
    );
  });
}
