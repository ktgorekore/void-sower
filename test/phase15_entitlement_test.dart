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
import 'package:void_sower/domain/services/entitlement_service.dart';
import 'package:void_sower/domain/services/persistence_service.dart';
import 'package:void_sower/presentation/widgets/fleet_hangar_dialog.dart';
import 'package:void_sower/presentation/widgets/pro_upgrade_modal.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await PersistenceService.instance.resetForTesting();
    EntitlementService.instance.resetForTesting();
  });

  group('Phase 15: EntitlementService & ProFeature Tests', () {
    test('ProFeature enum has 10 distinct capabilities', () {
      expect(ProFeature.values.length, 10);
      for (final feature in ProFeature.values) {
        final meta = ProFeatureMeta.registry[feature];
        expect(meta, isNotNull);
        expect(meta!.title.isNotEmpty, isTrue);
        expect(meta.shortDescription.isNotEmpty, isTrue);
      }
    });

    test('Features are locked by default on free tier', () {
      expect(EntitlementService.instance.isProUnlocked, isFalse);
      for (final feature in ProFeature.values) {
        expect(
          EntitlementService.instance.isFeatureAccessible(feature),
          isFalse,
        );
      }
    });

    test('grantTemporaryPass unlocks specific feature and tracks moves', () {
      expect(
        EntitlementService.instance.isFeatureAccessible(
          ProFeature.aiTacticalSolver,
        ),
        isFalse,
      );

      EntitlementService.instance.grantTemporaryPass(
        ProFeature.aiTacticalSolver,
        moves: 3,
      );

      expect(
        EntitlementService.instance.isFeatureAccessible(
          ProFeature.aiTacticalSolver,
        ),
        isTrue,
      );
      expect(EntitlementService.instance.aiSolverRemainingMoves, 3);

      EntitlementService.instance.consumeAiSolverMove();
      expect(EntitlementService.instance.aiSolverRemainingMoves, 2);
      expect(
        EntitlementService.instance.isFeatureAccessible(
          ProFeature.aiTacticalSolver,
        ),
        isTrue,
      );

      EntitlementService.instance.consumeAiSolverMove();
      EntitlementService.instance.consumeAiSolverMove();
      expect(EntitlementService.instance.aiSolverRemainingMoves, 0);
    });

    test('Permanent Pro unlock grants all features indefinitely', () async {
      await PersistenceService.instance.setProUnlocked(true);
      expect(EntitlementService.instance.isProUnlocked, isTrue);

      for (final feature in ProFeature.values) {
        expect(
          EntitlementService.instance.isFeatureAccessible(feature),
          isTrue,
        );
      }
    });
  });

  group('Phase 15: UI Presentation & Gating Widget Tests', () {
    testWidgets('ProUpgradeModal displays \$1.29 and Pro Commander features', (
      tester,
    ) async {
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

      expect(find.text('PRO COMMANDER FLEET'), findsOneWidget);
      expect(find.text('Lifetime License • \$1.29 One-Time'), findsOneWidget);
      expect(find.text('UNLOCK PRO COMMANDER — \$1.29'), findsOneWidget);
      expect(find.text('WATCH TRANSMISSION (FREE PASS)'), findsOneWidget);
      expect(find.text('RESTORE PREVIOUS PURCHASES'), findsOneWidget);
    });

    testWidgets(
      'FleetHangarDialog shows lock button for MK-III on free tier and allows equip on Pro',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        String selected = 'mk1_bastion';

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: FleetHangarDialog(
                selectedChassisId: selected,
                onChassisSelected: (id) => selected = id,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // MK-I is equipped
        expect(find.text('EQUIPPED'), findsOneWidget);

        // MK-II is free to equip
        expect(find.text('EQUIP SHIP'), findsOneWidget);

        // Scroll down to reveal MK-III
        await tester.drag(find.byType(ListView), const Offset(0, -250));
        await tester.pumpAndSettle();

        // MK-III should be locked
        expect(find.text('LOCKED • UNLOCK PRO / AD PASS'), findsWidgets);

        // Unlock Pro
        await PersistenceService.instance.setProUnlocked(true);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: FleetHangarDialog(
                selectedChassisId: selected,
                onChassisSelected: (id) => selected = id,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.drag(find.byType(ListView), const Offset(0, -250));
        await tester.pumpAndSettle();

        // Now MK-III should have EQUIP SHIP
        expect(find.text('EQUIP SHIP'), findsWidgets);
      },
    );
  });
}
