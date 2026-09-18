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
import 'package:void_sower/domain/models/dreadnought_state.dart';
import 'package:void_sower/domain/services/persistence_service.dart';
import 'package:void_sower/engine/mock_void_sower_engine.dart';
import 'package:void_sower/presentation/screens/combat_screen.dart';
import 'package:void_sower/presentation/widgets/combat_painter.dart';
import 'package:void_sower/presentation/widgets/command_arc_widget.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('UX Refinements Tests', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await PersistenceService.instance.initialize();
      await PersistenceService.instance.setCompletedTutorial(true);
    });

    testWidgets(
      'CommandArcWidget removes sow left/right buttons and platform slider, displays enlarged 48dp bays and C1-C8 notches',
      (tester) async {
        final bays = List<BayState>.generate(
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

        int? selectedBay;
        int? injectedBay;
        int? injectedDir;
        double? slidePos;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CommandArcWidget(
                bays: bays,
                selectedBay: selectedBay,
                onBaySelected: (b) => selectedBay = b,
                onSowAction: (_, _) {},
                onInjectCore: (b, d) {
                  injectedBay = b;
                  injectedDir = d;
                },
                onSlidePosition: (p) => slidePos = p,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // 1. Physical sow buttons MUST NOT exist
        expect(find.text('◄ SOW'), findsNothing);
        expect(find.text('SOW ►'), findsNothing);

        // 2. Lateral slider chevron handle MUST NOT exist
        expect(find.byIcon(Icons.rocket), findsNothing);

        // 3. Corridor alignment badges C1 to C8 MUST exist
        for (var i = 1; i <= 8; i++) {
          expect(find.text('C$i'), findsOneWidget);
        }

        // 4. Prominent AXIAL DISCHARGE button MUST exist
        expect(find.textContaining('AXIAL DISCHARGE'), findsOneWidget);

        // 5. Tapping corridor badge C3 selects frontline bay 10 (8 + 2) and aligns slide
        await tester.tap(find.text('C3'));
        await tester.pumpAndSettle();
        expect(selectedBay, equals(10));
        expect(slidePos, equals((2 + 0.5) / 8.0));

        // 6. Tapping AXIAL DISCHARGE triggers core injection
        await tester.tap(find.textContaining('AXIAL DISCHARGE'));
        await tester.pumpAndSettle();
        expect(injectedBay, isNotNull);
        expect(injectedDir, isNotNull);

        // 7. Verify sower bay cell container height is 48 dp
        final bayCellFinder = find.ancestor(
          of: find.text('10'),
          matching: find.byType(Container),
        );
        expect(bayCellFinder, findsWidgets);
        final bayRenderBox =
            tester.renderObject(bayCellFinder.first) as RenderBox;
        expect(bayRenderBox.size.height, equals(48.0));
      },
    );

    testWidgets(
      'Sector Secured Dock renders without overflow on narrow 320dp screen',
      (tester) async {
        tester.view.physicalSize = const Size(320 * 2.0, 568 * 2.0);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final mockEngine = MockVoidSowerEngine();
        mockEngine.initialize(startingCores: 28, boundaryY: 0.15);

        await tester.pumpWidget(
          MaterialApp(
            home: CombatScreen(
              engine: mockEngine,
              difficultyTier: 1,
              sectorId: 1,
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 100));

        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'CombatPainter renders enlarged dreadnought flagship without error',
      (tester) async {
        const dread = DreadnoughtState(
          orbitalPositionX: 0.5,
          targetPositionX: 0.5,
          reserveCores: 28,
          boundaryLineY: 0.15,
          isCascading: false,
          totalScore: 1200,
          currentSimState: 0,
          coresUsed: 4,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CustomPaint(
                size: const Size(400, 800),
                painter: CombatPainter(
                  dreadnought: dread,
                  enemies: const [],
                  lances: const [],
                  flaks: const [],
                  particles: const [],
                  enemyBullets: const [],
                  animationTime: 1.0,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(CustomPaint), findsWidgets);
        expect(tester.takeException(), isNull);
      },
    );
  });
}
