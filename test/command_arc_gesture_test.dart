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
import 'package:void_sower/domain/models/bay_state.dart';
import 'package:void_sower/presentation/widgets/command_arc_widget.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CommandArcWidget Bidirectional Sowing & Gesture Tests', () {
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
      'Swiping left on frontline bay triggers onSowAction with direction -1',
      (tester) async {
        int? lastSowBay;
        int? lastSowDir;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CommandArcWidget(
                bays: testBays,
                selectedBay: 8,
                sowDirection: 1,
                onBaySelected: (_) {},
                onSowAction: (bay, dir) {
                  lastSowBay = bay;
                  lastSowDir = dir;
                },
                onInjectCore: (_, _) {},
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Drag left on Bay 10
        final bay10Finder = find.text('10');
        expect(bay10Finder, findsOneWidget);

        await tester.drag(bay10Finder, const Offset(-40.0, 0.0));
        await tester.pumpAndSettle();

        expect(lastSowBay, equals(10));
        expect(lastSowDir, equals(-1));
      },
    );

    testWidgets(
      'Swiping right on frontline bay triggers onSowAction with direction 1',
      (tester) async {
        int? lastSowBay;
        int? lastSowDir;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CommandArcWidget(
                bays: testBays,
                selectedBay: 8,
                sowDirection: -1,
                onBaySelected: (_) {},
                onSowAction: (bay, dir) {
                  lastSowBay = bay;
                  lastSowDir = dir;
                },
                onInjectCore: (_, _) {},
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Drag right on Bay 10
        final bay10Finder = find.text('10');
        expect(bay10Finder, findsOneWidget);

        await tester.drag(bay10Finder, const Offset(40.0, 0.0));
        await tester.pumpAndSettle();

        expect(lastSowBay, equals(10));
        expect(lastSowDir, equals(1));
      },
    );

    testWidgets('Flicking upward on frontline bay triggers onInjectCore', (
      tester,
    ) async {
      int? injectedBay;
      int? injectedDir;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CommandArcWidget(
              bays: testBays,
              selectedBay: 8,
              sowDirection: -1,
              onBaySelected: (_) {},
              onSowAction: (_, _) {},
              onInjectCore: (bay, dir) {
                injectedBay = bay;
                injectedDir = dir;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Flick upward on Bay 11
      final bay11Finder = find.text('11');
      expect(bay11Finder, findsOneWidget);

      await tester.drag(bay11Finder, const Offset(0.0, -50.0));
      await tester.pumpAndSettle();

      expect(injectedBay, equals(11));
      expect(injectedDir, equals(-1));
    });

    testWidgets(
      'Dedicated SOW LEFT and SOW RIGHT buttons trigger respective directions',
      (tester) async {
        int? lastSowBay;
        int? lastSowDir;
        int? lastChangedDir;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CommandArcWidget(
                bays: testBays,
                selectedBay: 12,
                sowDirection: 1,
                onBaySelected: (_) {},
                onSowAction: (bay, dir) {
                  lastSowBay = bay;
                  lastSowDir = dir;
                },
                onInjectCore: (_, _) {},
                onDirectionChanged: (dir) {
                  lastChangedDir = dir;
                },
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Tap SOW LEFT
        await tester.tap(find.text('SOW LEFT'));
        await tester.pumpAndSettle();

        expect(lastSowBay, equals(12));
        expect(lastSowDir, equals(-1));
        expect(lastChangedDir, equals(-1));

        // Tap SOW RIGHT
        await tester.tap(find.text('SOW RIGHT'));
        await tester.pumpAndSettle();

        expect(lastSowBay, equals(12));
        expect(lastSowDir, equals(1));
        expect(lastChangedDir, equals(1));
      },
    );

    testWidgets('AXIAL DISCHARGE button honors sowDirection', (tester) async {
      int? injectedBay;
      int? injectedDir;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CommandArcWidget(
              bays: testBays,
              selectedBay: 9,
              sowDirection: -1,
              onBaySelected: (_) {},
              onSowAction: (_, _) {},
              onInjectCore: (bay, dir) {
                injectedBay = bay;
                injectedDir = dir;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.textContaining('AXIAL DISCHARGE'));
      await tester.pumpAndSettle();

      expect(injectedBay, equals(9));
      expect(injectedDir, equals(-1));
    });

    testWidgets(
      'Swiping left and right on Return Orbit bays triggers onSowAction',
      (tester) async {
        int? lastSowBay;
        int? lastSowDir;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CommandArcWidget(
                bays: testBays,
                selectedBay: 8,
                sowDirection: 1,
                onBaySelected: (_) {},
                onSowAction: (bay, dir) {
                  lastSowBay = bay;
                  lastSowDir = dir;
                },
                onInjectCore: (_, _) {},
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Bay 2 is on the backline
        final bay2Finder = find.text('2');
        expect(bay2Finder, findsOneWidget);

        // Drag left on Bay 2
        await tester.drag(bay2Finder, const Offset(-30.0, 0.0));
        await tester.pumpAndSettle();
        expect(lastSowBay, equals(2));
        expect(lastSowDir, equals(-1));

        // Drag right on Bay 2
        await tester.drag(bay2Finder, const Offset(30.0, 0.0));
        await tester.pumpAndSettle();
        expect(lastSowBay, equals(2));
        expect(lastSowDir, equals(1));
      },
    );

    testWidgets(
      'AXIAL DISCHARGE button on Bay 15 (Kichwa) enforces inward direction -1 even if sowDirection is 1',
      (tester) async {
        int? injectedBay;
        int? injectedDir;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CommandArcWidget(
                bays: testBays,
                selectedBay: 15,
                sowDirection: 1,
                onBaySelected: (_) {},
                onSowAction: (_, _) {},
                onInjectCore: (bay, dir) {
                  injectedBay = bay;
                  injectedDir = dir;
                },
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.textContaining('AXIAL DISCHARGE'));
        await tester.pumpAndSettle();

        expect(injectedBay, equals(15));
        expect(injectedDir, equals(-1));
      },
    );

    testWidgets(
      'AXIAL DISCHARGE button on Bay 8 (Kichwa) enforces inward direction 1 even if sowDirection is -1',
      (tester) async {
        int? injectedBay;
        int? injectedDir;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CommandArcWidget(
                bays: testBays,
                selectedBay: 8,
                sowDirection: -1,
                onBaySelected: (_) {},
                onSowAction: (_, _) {},
                onInjectCore: (bay, dir) {
                  injectedBay = bay;
                  injectedDir = dir;
                },
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.textContaining('AXIAL DISCHARGE'));
        await tester.pumpAndSettle();

        expect(injectedBay, equals(8));
        expect(injectedDir, equals(1));
      },
    );

    testWidgets(
      'Flicking upward on Bay 15 enforces inward direction -1 even if sowDirection is 1',
      (tester) async {
        int? injectedBay;
        int? injectedDir;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CommandArcWidget(
                bays: testBays,
                selectedBay: 8,
                sowDirection: 1,
                onBaySelected: (_) {},
                onSowAction: (_, _) {},
                onInjectCore: (bay, dir) {
                  injectedBay = bay;
                  injectedDir = dir;
                },
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final bay15Finder = find.text('15');
        expect(bay15Finder, findsOneWidget);

        await tester.drag(bay15Finder, const Offset(0.0, -50.0));
        await tester.pumpAndSettle();

        expect(injectedBay, equals(15));
        expect(injectedDir, equals(-1));
      },
    );

    testWidgets(
      'Swiping right on Bay 15 (Kichwa) is overridden to inward direction -1',
      (tester) async {
        int? lastSowBay;
        int? lastSowDir;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CommandArcWidget(
                bays: testBays,
                selectedBay: 8,
                sowDirection: 1,
                onBaySelected: (_) {},
                onSowAction: (bay, dir) {
                  lastSowBay = bay;
                  lastSowDir = dir;
                },
                onInjectCore: (_, _) {},
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final bay15Finder = find.text('15');
        expect(bay15Finder, findsOneWidget);

        await tester.drag(bay15Finder, const Offset(40.0, 0.0));
        await tester.pumpAndSettle();

        expect(lastSowBay, equals(15));
        expect(lastSowDir, equals(-1));
      },
    );

    testWidgets(
      'Tapping already-selected Bay 15 triggers onInjectCore with inward direction -1',
      (tester) async {
        int? injectedBay;
        int? injectedDir;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CommandArcWidget(
                bays: testBays,
                selectedBay: 15,
                sowDirection: 1,
                onBaySelected: (_) {},
                onSowAction: (_, _) {},
                onInjectCore: (bay, dir) {
                  injectedBay = bay;
                  injectedDir = dir;
                },
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Selected bay with 3 charge units shows '3 ⚡'
        final bay15SelectedFinder = find.text('3 ⚡');
        expect(bay15SelectedFinder, findsOneWidget);

        await tester.tap(bay15SelectedFinder);
        await tester.pumpAndSettle();

        expect(injectedBay, equals(15));
        expect(injectedDir, equals(-1));
      },
    );
  });
}
