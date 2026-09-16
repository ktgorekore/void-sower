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
import 'package:void_sower/domain/services/persistence_service.dart';
import 'package:void_sower/engine/mock_void_sower_engine.dart';
import 'package:void_sower/main.dart';

import 'package:void_sower/presentation/screens/combat_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await PersistenceService.instance.initialize();
  });

  testWidgets('VoidSowerApp launches directly into combat arena by default', (
    WidgetTester tester,
  ) async {
    await PersistenceService.instance.setCompletedTutorial(true);
    final mockEngine = MockVoidSowerEngine();
    await tester.pumpWidget(VoidSowerApp(engine: mockEngine));
    await tester.pump();

    expect(find.byType(CombatScreen), findsOneWidget);
    expect(find.text('PAUSE'), findsOneWidget);

    // Opening pause menu reveals meta actions (RULES, MAP, etc.)
    await tester.tap(find.text('PAUSE'));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('RULES'), findsOneWidget);
    expect(find.text('MAP'), findsOneWidget);
  });

  testWidgets(
    'VoidSowerApp launches campaign map screen with command deck UI',
    (WidgetTester tester) async {
      final mockEngine = MockVoidSowerEngine();
      await tester.pumpWidget(
        VoidSowerApp(engine: mockEngine, startCombat: false),
      );
      await tester.pumpAndSettle();

      // Verify command deck and branding
      expect(find.text('VOID SOWER'), findsOneWidget);
      expect(find.text('KILWA NEBULA BASIN'), findsOneWidget);
      expect(find.text('ORBITAL COMMAND DECK'), findsOneWidget);

      // Verify prominent greeting command cards
      expect(find.text('USER PROFILE'), findsOneWidget);
      expect(find.text('ACTIVE FLEET'), findsOneWidget);
      expect(find.text('Vanguard-01'), findsOneWidget);
      expect(find.text('MK-I Bastion'), findsOneWidget);

      // Verify sectors & engage buttons
      expect(find.text('Zanzibar Reef Gate'), findsOneWidget);
      expect(find.text('ENGAGE'), findsWidgets);

      // Tap USER PROFILE card -> Opens Profile Dossier Modal
      await tester.tap(find.text('USER PROFILE'));
      await tester.pumpAndSettle();
      expect(find.text('PILOT FLIGHT DOSSIER'), findsOneWidget);

      // Dismiss Profile Modal
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();
      expect(find.text('PILOT FLIGHT DOSSIER'), findsNothing);

      // Tap ACTIVE FLEET card -> Opens Fleet Hangar Modal
      await tester.tap(find.text('ACTIVE FLEET'));
      await tester.pumpAndSettle();
      expect(find.text('ORBITAL FLEET HANGAR'), findsOneWidget);

      // Dismiss Fleet Hangar Modal
      await tester.tap(find.text('CLOSE HANGAR'));
      await tester.pumpAndSettle();
      expect(find.text('ORBITAL FLEET HANGAR'), findsNothing);
    },
  );
}
