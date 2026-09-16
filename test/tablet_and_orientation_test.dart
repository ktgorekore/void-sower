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
import 'package:void_sower/domain/models/dreadnought_state.dart';
import 'package:void_sower/engine/mock_void_sower_engine.dart';
import 'package:void_sower/presentation/screens/campaign_map_screen.dart';
import 'package:void_sower/presentation/screens/combat_screen.dart';
import 'package:void_sower/presentation/theme/void_theme.dart';
import 'package:void_sower/presentation/widgets/combat_painter.dart';
import 'package:void_sower/presentation/widgets/landscape_orientation_shield.dart';

void main() {
  group('Tablet Responsiveness & Landscape Orientation Guard Tests', () {
    late MockVoidSowerEngine mockEngine;

    setUp(() {
      mockEngine = MockVoidSowerEngine();
    });

    testWidgets('Renders full width on standard phone portrait screen', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400); // ~432 x 960 dp
      tester.view.devicePixelRatio = 2.5;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: VoidTheme.darkTheme,
          home: CombatScreen(engine: mockEngine),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));

      expect(find.byType(CombatScreen), findsOneWidget);
      expect(find.byType(LandscapeOrientationShield), findsNothing);
    });

    testWidgets('Centers viewport within 580 dp on tablet portrait screen', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1600, 2560); // 800 x 1280 dp tablet
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: VoidTheme.darkTheme,
          home: CombatScreen(engine: mockEngine),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));

      expect(find.byType(CombatScreen), findsOneWidget);
      expect(find.byType(LandscapeOrientationShield), findsNothing);

      // Verify centered container constraints
      final constrainedContainers = tester.widgetList<Container>(
        find.descendant(
          of: find.byType(CombatScreen),
          matching: find.byType(Container),
        ),
      );

      final has580Constraint = constrainedContainers.any(
        (c) => c.constraints?.maxWidth == 580.0,
      );
      expect(
        has580Constraint,
        isTrue,
        reason: 'CombatScreen should center within maxWidth: 580.0 on tablets',
      );
    });

    testWidgets(
      'Centers viewport and remains fully playable on tablet landscape screen',
      (tester) async {
        tester.view.physicalSize = const Size(
          2560,
          1600,
        ); // 1280 x 800 dp tablet landscape
        tester.view.devicePixelRatio = 2.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          MaterialApp(
            theme: VoidTheme.darkTheme,
            home: CombatScreen(engine: mockEngine),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 16));

        expect(find.byType(CombatScreen), findsOneWidget);
        // Height is 800 dp >= 520 dp, so it should NOT show the shield
        expect(find.byType(LandscapeOrientationShield), findsNothing);

        final constrainedContainers = tester.widgetList<Container>(
          find.descendant(
            of: find.byType(CombatScreen),
            matching: find.byType(Container),
          ),
        );

        final has580Constraint = constrainedContainers.any(
          (c) => c.constraints?.maxWidth == 580.0,
        );
        expect(has580Constraint, isTrue);
      },
    );

    testWidgets(
      'Displays LandscapeOrientationShield on compact landscape viewport (height < 520 dp)',
      (tester) async {
        tester.view.physicalSize = const Size(
          1920,
          800,
        ); // ~960 x 400 dp (phone landscape)
        tester.view.devicePixelRatio = 2.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          MaterialApp(
            theme: VoidTheme.darkTheme,
            home: CombatScreen(engine: mockEngine),
          ),
        );
        await tester.pump();

        expect(find.byType(LandscapeOrientationShield), findsOneWidget);
        expect(find.text('ORIENTATION LOCK ACTIVE'), findsOneWidget);
        expect(find.text('ROTATE DEVICE TO PORTRAIT'), findsOneWidget);
        expect(find.text('AWAITING SENSOR REALIGNMENT...'), findsOneWidget);
      },
    );

    testWidgets(
      'CampaignMapScreen centers on tablet and shows shield in compact landscape',
      (tester) async {
        // Test compact landscape
        tester.view.physicalSize = const Size(1920, 800); // 960 x 400 dp
        tester.view.devicePixelRatio = 2.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          MaterialApp(
            theme: VoidTheme.darkTheme,
            home: CampaignMapScreen(engine: mockEngine),
          ),
        );
        await tester.pump();

        expect(find.byType(LandscapeOrientationShield), findsOneWidget);
      },
    );

    testWidgets(
      'CombatPainter paints enlarged defender with prow beacon cleanly',
      (tester) async {
        const dread = DreadnoughtState(
          orbitalPositionX: 0.5,
          targetPositionX: 0.5,
          reserveCores: 16,
          boundaryLineY: 0.15,
          isCascading: false,
          totalScore: 1000,
          currentSimState: 0,
          coresUsed: 4,
        );

        final painter = CombatPainter(
          dreadnought: dread,
          enemies: const [],
          lances: const [],
          flaks: const [],
          particles: const [],
          damageNumbers: const [],
          enemyBullets: const [],
          animationTime: 1.5,
        );

        await tester.pumpWidget(
          RepaintBoundary(
            child: CustomPaint(
              size: const Size(400.0, 700.0),
              painter: painter,
            ),
          ),
        );

        expect(find.byType(CustomPaint), findsOneWidget);
      },
    );
  });
}
