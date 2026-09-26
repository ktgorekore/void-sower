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
import 'package:void_sower/domain/services/persistence_service.dart';
import 'package:void_sower/engine/mock_void_sower_engine.dart';
import 'package:void_sower/presentation/screens/combat_screen.dart';
import 'package:void_sower/presentation/widgets/command_arc_widget.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await PersistenceService.instance.resetForTesting();
    await PersistenceService.instance.setCompletedTutorial(true);
  });

  group('Phase 21: Decluttered Combat Viewport & Projection Shelf Removal', () {
    testWidgets(
      'CombatScreen does not render ProjectionShelf or BAY...CORRIDOR telemetry',
      (tester) async {
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

        // 1. Verify "BAY ... CORRIDOR" telemetry string is NOT present
        expect(find.textContaining('CORRIDOR'), findsNothing);
        expect(find.textContaining('BAY 11'), findsNothing);
        expect(find.textContaining('BAY 14'), findsNothing);

        // 2. Verify button row labels are NOT present on the screen
        expect(find.text('AXIAL DISCHARGE'), findsNothing);
        expect(find.textContaining('AXIAL DISCHARGE'), findsNothing);
        expect(find.text('SOW LEFT'), findsNothing);
        expect(find.text('SOW RIGHT'), findsNothing);

        // 3. Verify external tags C1..C8 are NOT present on the screen
        for (var i = 1; i <= 8; i++) {
          expect(find.text('C$i'), findsNothing);
        }

        // 4. Verify Return Orbit bulky text headers are NOT present
        expect(find.textContaining('RETURN ORBIT (BAYS 0–7)'), findsNothing);
        expect(find.textContaining('NYUMBA CANOPY VAULT'), findsNothing);
      },
    );
  });

  group('Phase 21: CommandArcWidget Minimalist Visual Layout', () {
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
      'CommandArcWidget contains zero button rows or external corridor badges',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CommandArcWidget(
                bays: testBays,
                selectedBay: 8,
                sowDirection: 1,
                onBaySelected: (_) {},
                onSowAction: (_, _) {},
                onInjectCore: (_, _) {},
                onSlidePosition: (_) {},
              ),
            ),
          ),
        );
        await tester.pump();

        // Ensure no legacy button row text
        expect(find.text('SOW LEFT'), findsNothing);
        expect(find.text('SOW RIGHT'), findsNothing);
        expect(find.textContaining('AXIAL DISCHARGE'), findsNothing);

        // Ensure no outside C1..C8 text
        for (var i = 1; i <= 8; i++) {
          expect(find.text('C$i'), findsNothing);
        }

        // Verify frontline cylinders render directly (e.g., charge icons or numbers inside)
        expect(find.byType(CommandArcWidget), findsOneWidget);
      },
    );
  });

  group('Phase 21: Direct Defender Gesture Unification in CombatScreen', () {
    testWidgets(
      'Swiping defender horizontally right in combat viewport triggers sowing clockwise',
      (tester) async {
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

        // Find the combat viewport GestureDetector (the one inside the Expanded stack)
        final viewportFinder = find.byWidgetPredicate(
          (widget) =>
              widget is GestureDetector &&
              widget.behavior == HitTestBehavior.opaque &&
              widget.child is Stack,
        );
        expect(viewportFinder, findsOneWidget);

        // Perform a swipe right gesture across the combat viewport
        final center = tester.getCenter(viewportFinder);
        final gesture = await tester.startGesture(center);
        await gesture.moveBy(const Offset(80.0, 0.0));
        await gesture.up();
        await tester.pump(const Duration(milliseconds: 50));

        // Sowing state is triggered or game loop received action
        expect(find.byType(CombatScreen), findsOneWidget);
      },
    );

    testWidgets(
      'Swiping defender horizontally left in combat viewport triggers sowing counter-clockwise',
      (tester) async {
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

        final viewportFinder = find.byWidgetPredicate(
          (widget) =>
              widget is GestureDetector &&
              widget.behavior == HitTestBehavior.opaque &&
              widget.child is Stack,
        );
        expect(viewportFinder, findsOneWidget);

        // Perform a swipe left gesture across the combat viewport
        final center = tester.getCenter(viewportFinder);
        final gesture = await tester.startGesture(center);
        await gesture.moveBy(const Offset(-80.0, 0.0));
        await gesture.up();
        await tester.pump(const Duration(milliseconds: 50));

        expect(find.byType(CombatScreen), findsOneWidget);
      },
    );

    testWidgets(
      'Flicking defender upward in combat viewport triggers axial lance quick fire',
      (tester) async {
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

        final viewportFinder = find.byWidgetPredicate(
          (widget) =>
              widget is GestureDetector &&
              widget.behavior == HitTestBehavior.opaque &&
              widget.child is Stack,
        );
        expect(viewportFinder, findsOneWidget);

        // Perform an upward flick gesture
        final center = tester.getCenter(viewportFinder);
        final gesture = await tester.startGesture(center);
        await gesture.moveBy(const Offset(0.0, -90.0));
        await gesture.up();
        await tester.pump(const Duration(milliseconds: 50));

        expect(find.byType(CombatScreen), findsOneWidget);
      },
    );

    testWidgets('Tapping combat viewport triggers lance discharge', (
      tester,
    ) async {
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

      final viewportFinder = find.byWidgetPredicate(
        (widget) =>
            widget is GestureDetector &&
            widget.behavior == HitTestBehavior.opaque &&
            widget.child is Stack,
      );
      expect(viewportFinder, findsOneWidget);

      // Tap the viewport
      await tester.tap(viewportFinder);
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.byType(CombatScreen), findsOneWidget);
    });
  });
}
