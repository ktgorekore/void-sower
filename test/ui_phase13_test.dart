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
import 'package:void_sower/domain/models/prediction_result.dart';
import 'package:void_sower/presentation/widgets/bao_codex_dialog.dart';
import 'package:void_sower/presentation/widgets/command_arc_widget.dart';
import 'package:void_sower/presentation/widgets/fleet_hangar_dialog.dart';
import 'package:void_sower/presentation/widgets/projection_shelf.dart';
import 'package:void_sower/presentation/widgets/tactile_button.dart';
import 'package:void_sower/presentation/widgets/tutorial_overlay.dart';

void main() {
  group('Phase 13 UI Polish Tests', () {
    testWidgets('TactileButton renders and triggers callback', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TactileButton(
              label: 'ENGAGE TEST',
              onPressed: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.text('ENGAGE TEST'), findsOneWidget);
      await tester.tap(find.text('ENGAGE TEST'));
      await tester.pumpAndSettle();
      expect(tapped, isTrue);
    });

    testWidgets('TutorialOverlay steps through flight academy', (tester) async {
      bool dismissed = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TutorialOverlay(onDismiss: () => dismissed = true),
          ),
        ),
      );

      expect(find.text('FLIGHT ACADEMY'), findsOneWidget);
      expect(find.text('1. CORE INJECTION (NAMUA)'), findsOneWidget);

      // Step to next
      await tester.tap(find.text('NEXT'));
      await tester.pumpAndSettle();
      expect(find.text('2. SOWING TRAVERSAL'), findsOneWidget);

      // Step to next
      await tester.tap(find.text('NEXT'));
      await tester.pumpAndSettle();
      expect(find.text('3. QUADRATIC LANCE DISCHARGE'), findsOneWidget);

      // Step to next
      await tester.tap(find.text('NEXT'));
      await tester.pumpAndSettle();
      expect(find.text('4. ORBITAL PLATFORM ALIGNMENT'), findsOneWidget);

      // Final step -> launch
      await tester.tap(find.text('LAUNCH!'));
      await tester.pumpAndSettle();
      expect(dismissed, isTrue);
    });

    testWidgets('BaoCodexDialog displays rules and lore', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: BaoCodexDialog())),
      );

      expect(find.text('BAO ORBITAL CODEX'), findsOneWidget);
      expect(find.text('ANCIENT MATHEMATICAL ROOTS'), findsOneWidget);
      expect(find.text('1. NAMUA (CORE INJECTION)'), findsOneWidget);
      expect(find.text('2. QUADRATIC LANCES (D = α · M²)'), findsOneWidget);
      expect(
        find.text('3. NYUMBA (SUPER-CAPACITOR BAYS 3 & 4)'),
        findsOneWidget,
      );
      expect(find.text('DISMISS CODEX'), findsOneWidget);
    });

    testWidgets('FleetHangarDialog displays chassis variants and stats', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      String equipped = 'mk1_bastion';
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FleetHangarDialog(
              selectedChassisId: equipped,
              onChassisSelected: (id) => equipped = id,
            ),
          ),
        ),
      );

      expect(find.text('ORBITAL FLEET HANGAR'), findsOneWidget);
      expect(find.text('MK-I Bastion Standard'), findsOneWidget);
      expect(find.text('MK-II Monsoon Vanguard'), findsOneWidget);

      // Scroll down to reveal MK-III Singularity
      await tester.drag(find.byType(ListView), const Offset(0, -300));
      await tester.pumpAndSettle();
      expect(find.text('MK-III Singularity Sovereign'), findsOneWidget);

      // Scroll back up and equip MK-II
      await tester.drag(find.byType(ListView), const Offset(0, 300));
      await tester.pumpAndSettle();
      final equipButtons = find.text('EQUIP SHIP');
      expect(equipButtons, findsWidgets);
      await tester.tap(equipButtons.first);
      await tester.pumpAndSettle();
      expect(equipped, equals('mk2_monsoon'));
    });

    testWidgets(
      'CommandArcWidget displays 16 bays, pips, and corridor notches',
      (tester) async {
        final bays = List<BayState>.generate(
          16,
          (i) => BayState(
            bayIndex: i,
            tier: i < 8 ? 0 : 1,
            gridColumn: i < 8 ? i : 15 - i,
            radialPositionRad: i * 0.392,
            chargeUnits: i == 3 ? 4 : 2,
            isNyumba: i == 3 || i == 4,
            isKichwa: i == 8 || i == 15,
            isKimbi: i == 9 || i == 14,
            isFrontline: i < 8,
          ),
        );

        int? selected;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CommandArcWidget(
                bays: bays,
                selectedBay: selected,
                onBaySelected: (b) => selected = b,
                onSowAction: (_, _) {},
                onInjectCore: (_, _) {},
                onSlidePosition: (_) {},
              ),
            ),
          ),
        );

        expect(find.text('C1'), findsOneWidget);
        expect(find.text('C8'), findsOneWidget);
        expect(find.byType(CommandArcWidget), findsOneWidget);

        // Tap bay 3
        await tester.tap(find.text('3'));
        await tester.pump(const Duration(milliseconds: 400));
        await tester.pumpAndSettle();
        expect(selected, equals(3));
      },
    );

    testWidgets(
      'ProjectionShelf displays trajectory telemetry and lance damage',
      (tester) async {
        const pred = PredictionResult(
          terminalBay: 3,
          terminalCorridor: 3,
          finalMass: 4,
          predictedDamage: 16.0,
          totalCascadeLaps: 0,
          triggersLance: true,
          triggersRelay: false,
        );

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: ProjectionShelf(prediction: pred, selectedBay: 0),
            ),
          ),
        );

        expect(find.text('BAY 0 → BAY 3'), findsOneWidget);
        expect(find.text('LANCE: 16 DMG (M=4)'), findsOneWidget);
      },
    );
  });
}
