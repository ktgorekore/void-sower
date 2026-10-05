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

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:void_sower/domain/models/entitlement_state.dart';
import 'package:void_sower/domain/models/pro_feature.dart';
import 'package:void_sower/domain/services/entitlement_service.dart';
import 'package:void_sower/domain/services/persistence_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Stackable Entitlement State Machine Tests', () {
    test(
      'Initial state defaults to StandardFreeEntitlement with no Pro access',
      () {
        final sm = EntitlementStateMachine();
        expect(sm.currentState, isA<StandardFreeEntitlement>());
        expect(sm.currentState.hasProAccess, isFalse);
        expect(sm.currentState.isBoostActive, isFalse);
        expect(sm.currentState.isLifetimePro, isFalse);
        expect(sm.currentState.remainingBoostTime, equals(Duration.zero));
        expect(sm.currentState.formattedRemainingTime, isEmpty);
      },
    );

    test(
      'grantBoost transitions to TimedBoostEntitlement and stacks up to 60m',
      () {
        final sm = EntitlementStateMachine();
        sm.grantBoost(duration: const Duration(minutes: 5));

        expect(sm.currentState, isA<TimedBoostEntitlement>());
        expect(sm.currentState.hasProAccess, isTrue);
        expect(sm.currentState.isBoostActive, isTrue);
        expect(
          sm.currentState.remainingBoostTime.inMinutes,
          inInclusiveRange(4, 5),
        );

        // Stack an additional 5 minutes
        sm.grantBoost(duration: const Duration(minutes: 5));
        expect(
          sm.currentState.remainingBoostTime.inMinutes,
          inInclusiveRange(9, 10),
        );

        // Stack exceeding 60 minutes clamps to 60 minutes
        sm.grantBoost(duration: const Duration(minutes: 90));
        expect(
          sm.currentState.remainingBoostTime.inMinutes,
          inInclusiveRange(59, 60),
        );
      },
    );

    test(
      'LifetimeProEntitlement overrides boost and gives permanent access',
      () {
        final sm = EntitlementStateMachine();
        sm.grantBoost(duration: const Duration(minutes: 5));
        sm.unlockLifetimePro();

        expect(sm.currentState, isA<LifetimeProEntitlement>());
        expect(sm.currentState.isLifetimePro, isTrue);
        expect(sm.currentState.hasProAccess, isTrue);

        // grantBoost is no-op when lifetime Pro is active
        sm.grantBoost(duration: const Duration(minutes: 10));
        expect(sm.currentState, isA<LifetimeProEntitlement>());
      },
    );

    test('Expired TimedBoost transitions back to StandardFreeEntitlement', () {
      final expiredTime = DateTime.now().subtract(const Duration(seconds: 1));
      final sm = EntitlementStateMachine(
        initialState: TimedBoostEntitlement(expiresAt: expiredTime),
      );

      expect(sm.currentState, isA<StandardFreeEntitlement>());
      expect(sm.currentState.hasProAccess, isFalse);
    });
  });

  group('EntitlementService Integration Tests', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await PersistenceService.instance.resetForTesting();
      EntitlementService.instance.resetForTesting();
    });

    test('grantStackableBoost unlocks ProFeatures and broadcasts updates', () {
      final service = EntitlementService.instance;
      expect(service.isFeatureAccessible(ProFeature.aiTacticalSolver), isFalse);

      service.grantStackableBoost(duration: const Duration(minutes: 5));

      expect(service.isBoostActive, isTrue);
      expect(service.isFeatureAccessible(ProFeature.aiTacticalSolver), isTrue);
      expect(
        service.isFeatureAccessible(ProFeature.orbitalSimulationLab),
        isTrue,
      );
      expect(service.formattedRemainingBoostTime, isNotEmpty);
    });

    test(
      'persistence saves and restores active pro boost on restart',
      () async {
        final service = EntitlementService.instance;
        service.grantStackableBoost(duration: const Duration(minutes: 20));

        final savedExpiry = PersistenceService.instance.proBoostExpiry;
        expect(savedExpiry, isNotNull);
        expect(savedExpiry!.isAfter(DateTime.now()), isTrue);

        // Simulate app restart
        service.syncStateFromPersistence();
        expect(service.isBoostActive, isTrue);
        expect(
          service.isFeatureAccessible(ProFeature.proCampaignTheaters),
          isTrue,
        );
      },
    );
  });
}
