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
import 'package:void_sower/presentation/widgets/pause_menu_dialog.dart';
import 'package:void_sower/presentation/widgets/pro_boost_modal.dart';

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

  group('Phase 25: Pro Boost Stacking & 60m Clamp', () {
    test('Non-pro user stacks boost in 5m increments up to 60m ceiling', () {
      final ent = EntitlementService.instance;
      expect(ent.isProUnlocked, isFalse);
      expect(ent.isBoostActive, isFalse);
      expect(ent.boostMinutesRemaining, 0);
      expect(ent.boostSegmentsLit, 0);

      // 1st ad watched -> +5 mins (1 segment)
      ent.grantStackableBoost(duration: const Duration(minutes: 5));
      expect(ent.isBoostActive, isTrue);
      expect(ent.boostMinutesRemaining, 5);
      expect(ent.boostSegmentsLit, 1);
      expect(ent.isMaxBoostReached, isFalse);

      // 2nd ad watched -> +5 mins (total 10 mins, 2 segments)
      ent.grantStackableBoost(duration: const Duration(minutes: 5));
      expect(ent.boostMinutesRemaining, 10);
      expect(ent.boostSegmentsLit, 2);

      // Stack up to 12 segments (60 mins)
      for (int i = 0; i < 10; i++) {
        ent.grantStackableBoost(duration: const Duration(minutes: 5));
      }
      expect(ent.boostMinutesRemaining, 60);
      expect(ent.boostSegmentsLit, 12);
      expect(ent.isMaxBoostReached, isTrue);

      // Stacking beyond 60m is clamped at 60m
      ent.grantStackableBoost(duration: const Duration(minutes: 5));
      expect(ent.boostMinutesRemaining, 60);
      expect(ent.boostSegmentsLit, 12);
    });

    test(
      'Permanent Pro user bypasses boost and has permanent access',
      () async {
        await PersistenceService.instance.setProUnlocked(true);
        EntitlementService.instance.syncStateFromPersistence();

        final ent = EntitlementService.instance;
        expect(ent.isProUnlocked, isTrue);
        expect(ent.isFeatureAccessible(ProFeature.aiTacticalSolver), isTrue);
      },
    );
  });

  group('Phase 25: Void Incursion Mode Unlimited Cores', () {
    test('Non-incursion run enforces standard core limits even for Pro', () {
      final coordinator = CombatCoordinator(engine: MockVoidSowerEngine());
      coordinator.initialize(
        startingCores: 28,
        boundaryY: 0.15,
        isIncursionRun: false,
      );

      expect(coordinator.isUnlimitedCores, isFalse);
      expect(coordinator.dreadnought.reserveCores, 28);
      coordinator.dispose();
    });

    test(
      'Incursion run for Pro user grants unlimited cores and 9999 initial cores',
      () async {
        await PersistenceService.instance.setProUnlocked(true);
        EntitlementService.instance.syncStateFromPersistence();

        final coordinator = CombatCoordinator(engine: MockVoidSowerEngine());
        coordinator.initialize(
          startingCores: 28,
          boundaryY: 0.15,
          isIncursionRun: true,
        );

        expect(coordinator.isUnlimitedCores, isTrue);
        expect(coordinator.dreadnought.reserveCores, 9999);
        coordinator.dispose();
      },
    );

    test('Incursion run for Pro Boost active user grants unlimited cores', () {
      EntitlementService.instance.grantStackableBoost(
        duration: const Duration(minutes: 5),
      );

      final coordinator = CombatCoordinator(engine: MockVoidSowerEngine());
      coordinator.initialize(
        startingCores: 28,
        boundaryY: 0.15,
        isIncursionRun: true,
      );

      expect(coordinator.isUnlimitedCores, isTrue);
      expect(coordinator.dreadnought.reserveCores, 9999);
      coordinator.dispose();
    });

    test(
      'Dynamic Pro Boost activation mid-incursion replenishes cores immediately',
      () {
        final coordinator = CombatCoordinator(engine: MockVoidSowerEngine());
        coordinator.initialize(
          startingCores: 14,
          boundaryY: 0.15,
          isIncursionRun: true,
        );

        expect(coordinator.isUnlimitedCores, isFalse);
        expect(coordinator.dreadnought.reserveCores, 14);

        // Deplete cores
        coordinator.dreadnought = coordinator.dreadnought.copyWith(
          reserveCores: 0,
        );
        coordinator.setMatchStatusForTesting(CombatMatchStatus.defeat);
        expect(coordinator.state.canReceiveInput, isFalse);

        // User watches ad / activates Pro Boost mid-game
        EntitlementService.instance.grantStackableBoost(
          duration: const Duration(minutes: 5),
        );

        expect(coordinator.isUnlimitedCores, isTrue);
        expect(
          coordinator.dreadnought.reserveCores,
          greaterThanOrEqualTo(5000),
        );
        expect(coordinator.state.status, CombatMatchStatus.activeCombat);
        expect(coordinator.state.canReceiveInput, isTrue);
        coordinator.dispose();
      },
    );
  });

  group('Phase 25: GameOverDialog Incursion Suppression & Rewarded UX', () {
    testWidgets(
      'Permanent Pro in Incursion mode has ad button suppressed on game over',
      (tester) async {
        await PersistenceService.instance.setProUnlocked(true);
        EntitlementService.instance.syncStateFromPersistence();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: GameOverDialog(
                score: 2500,
                highScore: 5000,
                isAmmoDepleted: true,
                armDuration: Duration.zero,
                onRetry: () {},
                onReturnToMap: () {},
                onWatchAdForCores: null, // Suppressed for Pro in incursion
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('CORES EXHAUSTED'), findsOneWidget);
        expect(find.byIcon(Icons.play_circle_filled), findsNothing);
      },
    );

    testWidgets(
      'Non-pro in Incursion mode gets UNLOCK 5m PRO & UNLIMITED CORES label',
      (tester) async {
        bool adWatched = false;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: GameOverDialog(
                score: 1000,
                highScore: 2000,
                isAmmoDepleted: true,
                armDuration: Duration.zero,
                watchAdLabel: 'WATCH AD (UNLOCK 5m PRO & UNLIMITED CORES)',
                onRetry: () {},
                onReturnToMap: () {},
                onWatchAdForCores: () => adWatched = true,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.text('WATCH AD (UNLOCK 5m PRO & UNLIMITED CORES)'),
          findsOneWidget,
        );

        await tester.tap(
          find.text('WATCH AD (UNLOCK 5m PRO & UNLIMITED CORES)'),
        );
        await tester.pump();
        expect(adWatched, isTrue);
      },
    );
  });

  group('Phase 25: Combat Pause / Resume UX', () {
    testWidgets(
      'Resuming from PauseMenuDialog restores active combat cleanly',
      (tester) async {
        final engine = MockVoidSowerEngine();
        await tester.pumpWidget(
          MaterialApp(home: CombatScreen(engine: engine)),
        );
        await tester.pump(const Duration(milliseconds: 50));

        // Open Pause Menu
        await tester.tap(find.byIcon(Icons.pause));
        await tester.pump(const Duration(milliseconds: 200));

        expect(find.byType(PauseMenuDialog), findsOneWidget);

        // Resume from dialog via primary play button
        await tester.tap(
          find.descendant(
            of: find.byType(PauseMenuDialog),
            matching: find.byTooltip('Resume Sortie'),
          ),
        );
        await tester.pump(const Duration(milliseconds: 200));

        expect(find.byType(PauseMenuDialog), findsNothing);
      },
    );

    testWidgets('Pause menu Pro Boost strip and return workflow', (
      tester,
    ) async {
      final engine = MockVoidSowerEngine();
      await tester.pumpWidget(MaterialApp(home: CombatScreen(engine: engine)));
      await tester.pump(const Duration(milliseconds: 50));

      // Tap pause button in HUD
      await tester.tap(find.byIcon(Icons.pause));
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.byType(PauseMenuDialog), findsOneWidget);

      // Tap Pro Boost strip in pause menu
      expect(
        find.text('UNLOCK PRO BOOST • TAP TO STACK (+5m)'),
        findsOneWidget,
      );
      await tester.tap(find.text('UNLOCK PRO BOOST • TAP TO STACK (+5m)'));
      await tester.pump(const Duration(milliseconds: 200));

      // ProBoostModal is open
      expect(find.byType(ProBoostModal), findsOneWidget);

      // Dismiss ProBoostModal via close icon
      await tester.tap(find.byIcon(Icons.close));
      await tester.pump(const Duration(milliseconds: 200));

      // Returns to PauseMenuDialog
      expect(find.byType(PauseMenuDialog), findsOneWidget);

      // Resume combat cleanly
      await tester.tap(
        find.descendant(
          of: find.byType(PauseMenuDialog),
          matching: find.byTooltip('Resume Sortie'),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.byType(PauseMenuDialog), findsNothing);
    });
  });

  group('Phase 25: ProBoostModal Stacking Battery Widget', () {
    testWidgets(
      'ProBoostModal renders 12 segments and stacks +5m upon ad watch',
      (tester) async {
        bool boostUpdated = false;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ProBoostModal(onBoostUpdated: () => boostUpdated = true),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('PRO TEMPORAL OVERCHARGE'), findsOneWidget);
        expect(find.text('WATCH AD (+5m BOOST)'), findsOneWidget);
        expect(find.text('0 / 60 MIN'), findsOneWidget);

        // Tap Watch Ad
        await tester.tap(find.text('WATCH AD (+5m BOOST)'));
        await tester.pumpAndSettle();

        expect(boostUpdated, isTrue);
        expect(EntitlementService.instance.isBoostActive, isTrue);
        expect(EntitlementService.instance.boostMinutesRemaining, 5);
        expect(find.text('5 / 60 MIN'), findsOneWidget);
      },
    );
  });
}
