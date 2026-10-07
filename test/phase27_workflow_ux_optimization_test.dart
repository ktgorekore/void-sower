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
import 'package:void_sower/domain/models/bay_state.dart';
import 'package:void_sower/domain/services/entitlement_service.dart';
import 'package:void_sower/domain/services/persistence_service.dart';
import 'package:void_sower/engine/mock_void_sower_engine.dart';
import 'package:void_sower/presentation/controllers/tactical_solver_controller.dart';
import 'package:void_sower/presentation/screens/combat_screen.dart';
import 'package:void_sower/presentation/widgets/combat_settings_sheet.dart';
import 'package:void_sower/presentation/widgets/command_arc_widget.dart';
import 'package:void_sower/presentation/widgets/game_over_dialog.dart';
import 'package:void_sower/presentation/widgets/pause_menu_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await PersistenceService.instance.initialize();
    await PersistenceService.instance.setCompletedTutorial(true);
    await PersistenceService.instance.setProUnlocked(false);
    EntitlementService.instance.syncStateFromPersistence();
  });

  group('Phase 27: Normal Sector Defeat Workflow Optimization', () {
    testWidgets(
      'Normal sector Game Over suppresses auxiliary core CTAs for Pro Commander',
      (tester) async {
        await PersistenceService.instance.setProUnlocked(true);
        EntitlementService.instance.syncStateFromPersistence();

        final engine = MockVoidSowerEngine();
        await tester.pumpWidget(
          MaterialApp(
            home: CombatScreen(
              engine: engine,
              sectorId: 1,
              isIncursionRun: false,
              isDailySortie: false,
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 50));

        final combatState = tester.state(find.byType(CombatScreen));
        final dialogCoordinator = (combatState as dynamic).dialogCoordinator;

        // Trigger defeat in normal sector
        dialogCoordinator.showDefeat(
          context: tester.element(find.byType(CombatScreen)),
          builder: (dialogContext) => GameOverDialog(
            score: 1500,
            highScore: 3000,
            isAmmoDepleted: true,
            armDuration: Duration.zero,
            isPro: true,
            onRetry: () {},
            onReturnToMap: () {},
            onWatchAdForCores:
                null, // Normal sector: game is over, no core refill
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(GameOverDialog), findsOneWidget);
        expect(find.text('CORES EXHAUSTED'), findsOneWidget);
        expect(find.text('FINAL SCORE: 1500'), findsOneWidget);

        // Core refill and ad CTAs must NEVER appear
        expect(find.textContaining('SUMMON AUXILIARY CORES'), findsNothing);
        expect(find.textContaining('WATCH AD'), findsNothing);

        // Clear decisive tactical options
        expect(find.text('STAR MAP'), findsOneWidget);
        expect(find.text('RETRY'), findsOneWidget);
      },
    );

    testWidgets(
      'Normal sector Game Over suppresses watch-ad CTA for Free Pilot',
      (tester) async {
        await PersistenceService.instance.setProUnlocked(false);
        EntitlementService.instance.syncStateFromPersistence();

        final engine = MockVoidSowerEngine();
        await tester.pumpWidget(
          MaterialApp(
            home: CombatScreen(
              engine: engine,
              sectorId: 1,
              isIncursionRun: false,
              isDailySortie: false,
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 50));

        final combatState = tester.state(find.byType(CombatScreen));
        final dialogCoordinator = (combatState as dynamic).dialogCoordinator;

        dialogCoordinator.showDefeat(
          context: tester.element(find.byType(CombatScreen)),
          builder: (dialogContext) => GameOverDialog(
            score: 950,
            highScore: 2000,
            isAmmoDepleted: true,
            armDuration: Duration.zero,
            isPro: false,
            onRetry: () {},
            onReturnToMap: () {},
            onWatchAdForCores: null, // Normal sector
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(GameOverDialog), findsOneWidget);
        expect(find.textContaining('WATCH AD'), findsNothing);
        expect(find.textContaining('SUMMON AUXILIARY CORES'), findsNothing);
        expect(find.text('STAR MAP'), findsOneWidget);
        expect(find.text('RETRY'), findsOneWidget);
      },
    );

    testWidgets(
      'Void Incursion mode permits continue / emergency core refill',
      (tester) async {
        await PersistenceService.instance.setProUnlocked(false);
        EntitlementService.instance.syncStateFromPersistence();

        final engine = MockVoidSowerEngine();
        await tester.pumpWidget(
          MaterialApp(
            home: CombatScreen(
              engine: engine,
              sectorId: 1,
              isIncursionRun: true,
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 50));

        final combatState = tester.state(find.byType(CombatScreen));
        final dialogCoordinator = (combatState as dynamic).dialogCoordinator;

        bool adTriggered = false;
        dialogCoordinator.showDefeat(
          context: tester.element(find.byType(CombatScreen)),
          builder: (dialogContext) => GameOverDialog(
            score: 4200,
            highScore: 5000,
            isAmmoDepleted: true,
            armDuration: Duration.zero,
            isPro: false,
            watchAdLabel: 'WATCH AD (UNLOCK 5m PRO & UNLIMITED CORES)',
            onWatchAdForCores: () => adTriggered = true,
            onRetry: () {},
            onReturnToMap: () {},
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(GameOverDialog), findsOneWidget);
        expect(
          find.text('WATCH AD (UNLOCK 5m PRO & UNLIMITED CORES)'),
          findsOneWidget,
        );

        await tester.tap(
          find.text('WATCH AD (UNLOCK 5m PRO & UNLIMITED CORES)'),
        );
        await tester.pump();
        expect(adTriggered, isTrue);
      },
    );
  });

  group('Phase 27: Pause -> Settings -> Return Navigation Workflow', () {
    testWidgets(
      'Opening settings from pause and swiping back resumes combat cleanly without freezing',
      (tester) async {
        final engine = MockVoidSowerEngine();
        await tester.pumpWidget(
          MaterialApp(home: CombatScreen(engine: engine)),
        );
        await tester.pump(const Duration(milliseconds: 50));

        // Open pause menu
        await tester.tap(find.byIcon(Icons.pause));
        await tester.pump(const Duration(milliseconds: 200));
        expect(find.byType(PauseMenuDialog), findsOneWidget);

        // Tap Settings icon in pause menu
        await tester.tap(find.byIcon(Icons.settings));
        await tester.pumpAndSettle();

        // Settings modal is open
        expect(find.byType(CombatSettingsSheet), findsOneWidget);
        expect(find.text('FLEET SYSTEM CONFIG'), findsOneWidget);

        // Dismiss settings (simulating user close or swipe back)
        await tester.tap(find.byIcon(Icons.close));
        await tester.pumpAndSettle();

        // Settings is closed
        expect(find.byType(CombatSettingsSheet), findsNothing);
        // Pause menu is also closed (no secondary modal roadblock)
        expect(find.byType(PauseMenuDialog), findsNothing);

        // Combat screen is active and unpaused (not frozen)
        final combatState = tester.state(find.byType(CombatScreen));
        final coordinator = (combatState as dynamic).dialogCoordinator;
        expect(coordinator, isNotNull);

        // Pause button shows pause icon (active combat), not stuck
        expect(find.byIcon(Icons.pause), findsOneWidget);
      },
    );
  });

  group('Phase 27: CommandArcWidget Stable Layout & Zero Bay Jump', () {
    late List<BayState> testBays;

    setUp(() {
      testBays = List<BayState>.generate(
        16,
        (i) => BayState(
          bayIndex: i,
          tier: i < 8 ? 0 : 1,
          gridColumn: i < 8 ? i : 15 - i,
          radialPositionRad: i * 0.392,
          chargeUnits: 3,
          isNyumba: i == 3 || i == 4,
          isKichwa: i == 8 || i == 15,
          isKimbi: i == 9 || i == 14,
          isFrontline: i >= 8,
        ),
      );
    });

    testWidgets(
      'CommandArcWidget maintains 100% identical height and bay position when advice toggles',
      (tester) async {
        // Unlock Pro so the tactical advice feature is active
        await PersistenceService.instance.setProUnlocked(true);
        EntitlementService.instance.syncStateFromPersistence();

        // 1. Build with NO active advice (standby state)
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Align(
                alignment: Alignment.bottomCenter,
                child: CommandArcWidget(
                  bays: testBays,
                  selectedBay: 8,
                  sowDirection: 1,
                  tacticalAdvice: null,
                  onBaySelected: (_) {},
                  onSowAction: (_, _) {},
                  onInjectCore: (_, _) {},
                  onSlidePosition: (_) {},
                ),
              ),
            ),
          ),
        );
        await tester.pump();

        // Check standby bar exists
        expect(find.text('TACTICAL AI SCANNING CORRIDORS...'), findsOneWidget);
        expect(find.text('STANDBY'), findsOneWidget);

        final initialArcSize = tester.getSize(find.byType(CommandArcWidget));
        final initialBay8Pos = tester.getTopLeft(
          find.bySemanticsLabel(RegExp('Bay 8')),
        );

        // 2. Re-pump with ACTIVE tactical advice recommendation
        const activeAdvice = TacticalAdvice(
          recommendedBay: 10,
          recommendedDirection: 1,
          targetCorridor: 2,
          predictedDamage: 45.0,
          explanation: 'FLANK SOW BAY 10 CW (+4 COMBO)',
          isEmergencyBreach: false,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Align(
                alignment: Alignment.bottomCenter,
                child: CommandArcWidget(
                  bays: testBays,
                  selectedBay: 8,
                  sowDirection: 1,
                  tacticalAdvice: activeAdvice,
                  onBaySelected: (_) {},
                  onSowAction: (_, _) {},
                  onInjectCore: (_, _) {},
                  onSlidePosition: (_) {},
                ),
              ),
            ),
          ),
        );
        await tester.pump();

        // Active advice banner rendered
        expect(find.text('FLANK SOW BAY 10 CW (+4 COMBO)'), findsOneWidget);
        expect(find.text('PRO ADVISOR'), findsOneWidget);

        final activeArcSize = tester.getSize(find.byType(CommandArcWidget));
        final activeBay8Pos = tester.getTopLeft(
          find.bySemanticsLabel(RegExp('Bay 8')),
        );

        // Verify total height of CommandArcWidget is identical
        expect(
          activeArcSize.height,
          equals(initialArcSize.height),
          reason:
              'CommandArcWidget height must remain strictly identical to prevent layout jump',
        );

        // Verify frontline bay Y position is identical (0.0 offset difference)
        expect(
          activeBay8Pos.dy,
          equals(initialBay8Pos.dy),
          reason:
              'Bay 8 Y position must NOT jump when tactical advice appears or clears',
        );

        // 3. Clear advice back to null
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Align(
                alignment: Alignment.bottomCenter,
                child: CommandArcWidget(
                  bays: testBays,
                  selectedBay: 8,
                  sowDirection: 1,
                  tacticalAdvice: null,
                  onBaySelected: (_) {},
                  onSowAction: (_, _) {},
                  onInjectCore: (_, _) {},
                  onSlidePosition: (_) {},
                ),
              ),
            ),
          ),
        );
        await tester.pump();

        final clearedArcSize = tester.getSize(find.byType(CommandArcWidget));
        final clearedBay8Pos = tester.getTopLeft(
          find.bySemanticsLabel(RegExp('Bay 8')),
        );

        expect(clearedArcSize.height, equals(initialArcSize.height));
        expect(clearedBay8Pos.dy, equals(initialBay8Pos.dy));
      },
    );

    testWidgets(
      'CommandArcWidget renders subtle advisory bar universally for non-Pro/free users with zero jumping',
      (tester) async {
        // Explicitly set Pro to false (Free Commander)
        await PersistenceService.instance.setProUnlocked(false);
        EntitlementService.instance.syncStateFromPersistence();

        // 1. Build with NO active advice (free user standby state)
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Align(
                alignment: Alignment.bottomCenter,
                child: CommandArcWidget(
                  bays: testBays,
                  selectedBay: 8,
                  sowDirection: 1,
                  tacticalAdvice: null,
                  onBaySelected: (_) {},
                  onSowAction: (_, _) {},
                  onInjectCore: (_, _) {},
                  onSlidePosition: (_) {},
                ),
              ),
            ),
          ),
        );
        await tester.pump();

        // Check standby bar exists for free user too
        expect(find.text('TACTICAL AI SCANNING CORRIDORS...'), findsOneWidget);
        expect(find.text('STANDBY'), findsOneWidget);

        final freeStandbySize = tester.getSize(find.byType(CommandArcWidget));
        final freeBay8Pos = tester.getTopLeft(
          find.bySemanticsLabel(RegExp('Bay 8')),
        );

        // 2. Active advice arrives for free user
        const freeAdvice = TacticalAdvice(
          recommendedBay: 12,
          recommendedDirection: -1,
          targetCorridor: 4,
          predictedDamage: 30.0,
          explanation: 'INTERCEPT SOW BAY 12 CCW',
          isEmergencyBreach: false,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Align(
                alignment: Alignment.bottomCenter,
                child: CommandArcWidget(
                  bays: testBays,
                  selectedBay: 8,
                  sowDirection: 1,
                  tacticalAdvice: freeAdvice,
                  onBaySelected: (_) {},
                  onSowAction: (_, _) {},
                  onInjectCore: (_, _) {},
                  onSlidePosition: (_) {},
                ),
              ),
            ),
          ),
        );
        await tester.pump();

        expect(find.text('INTERCEPT SOW BAY 12 CCW'), findsOneWidget);
        final freeActiveSize = tester.getSize(find.byType(CommandArcWidget));
        final freeActiveBay8Pos = tester.getTopLeft(
          find.bySemanticsLabel(RegExp('Bay 8')),
        );

        expect(freeActiveSize.height, equals(freeStandbySize.height));
        expect(freeActiveBay8Pos.dy, equals(freeBay8Pos.dy));
      },
    );
  });
}
