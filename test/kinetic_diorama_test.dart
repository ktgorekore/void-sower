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
import 'package:void_sower/presentation/theme/void_theme.dart';
import 'package:void_sower/presentation/widgets/bao_codex_dialog.dart';
import 'package:void_sower/presentation/widgets/kinetic_rule_diorama.dart';
import 'package:void_sower/presentation/widgets/tactical_directives_modal.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('KineticRuleDiorama Micro-Canvas Visual Tests', () {
    testWidgets('Renders all four diorama types without throwing', (
      tester,
    ) async {
      for (final type in DioramaType.values) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 320.0,
                  child: KineticRuleDiorama(type: type, height: 120.0),
                ),
              ),
            ),
          ),
        );

        expect(find.byType(KineticRuleDiorama), findsOneWidget);
        expect(find.byType(CustomPaint), findsWidgets);

        // Advance animation ticker
        await tester.pump(const Duration(milliseconds: 500));
        await tester.pump(const Duration(milliseconds: 1000));
      }
    });

    testWidgets('Custom accent color overrides default palette', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: KineticRuleDiorama(
              type: DioramaType.sowingAndNamua,
              accentColor: VoidTheme.crimsonFlare,
              height: 140.0,
            ),
          ),
        ),
      );

      expect(find.byType(KineticRuleDiorama), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 200));
    });

    testWidgets('BaoCodexDialog mounts kinetic dioramas inside section cards', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: BaoCodexDialog())),
      );

      // Verify Codex dialog contains the kinetic micro-diorama canvases
      expect(find.byType(BaoCodexDialog), findsOneWidget);
      expect(find.byType(KineticRuleDiorama), findsWidgets);

      // Verify key titles remain available
      expect(find.text('BAO ORBITAL CODEX'), findsOneWidget);
      expect(find.text('1. NAMUA (CORE INJECTION)'), findsOneWidget);
      expect(find.text('2. CHARGED LASERS (STACKING POWER)'), findsOneWidget);
      expect(
        find.text('3. NYUMBA (SUPER-CAPACITOR BAYS 3 & 4)'),
        findsOneWidget,
      );

      await tester.pump(const Duration(milliseconds: 300));
    });

    testWidgets(
      'TacticalDirectivesModal displays animated visual rule vignettes',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(home: Scaffold(body: TacticalDirectivesModal())),
        );

        expect(find.byType(TacticalDirectivesModal), findsOneWidget);
        expect(find.byType(KineticRuleDiorama), findsWidgets);
        expect(find.text('1. SWIPE TO SOW'), findsOneWidget);
        expect(find.text('2. CORRIDORS C1–C8'), findsOneWidget);

        await tester.scrollUntilVisible(
          find.text('4. SHIELD CANOPY'),
          150.0,
          scrollable: find.byType(Scrollable).first,
        );
        expect(find.text('4. SHIELD CANOPY'), findsOneWidget);

        await tester.pump(const Duration(milliseconds: 300));
      },
    );
  });
}
