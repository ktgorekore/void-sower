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

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_platform_interface/in_app_purchase_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:void_sower/domain/models/pro_feature.dart';
import 'package:void_sower/domain/services/entitlement_service.dart';
import 'package:void_sower/domain/services/iap_service.dart';
import 'package:void_sower/domain/services/persistence_service.dart';
import 'package:void_sower/presentation/widgets/pro_upgrade_modal.dart';

class _MockInAppPurchase implements InAppPurchase {
  final StreamController<List<PurchaseDetails>> controller =
      StreamController<List<PurchaseDetails>>.broadcast();

  bool available = true;
  bool buySuccess = true;
  bool returnProductDetails = true;
  final List<PurchaseDetails> completedPurchases = [];
  Completer<bool>? hangIsAvailableCompleter;
  Completer<ProductDetailsResponse>? hangQueryProductDetailsCompleter;

  @override
  Stream<List<PurchaseDetails>> get purchaseStream => controller.stream;

  @override
  Future<bool> isAvailable() async {
    if (hangIsAvailableCompleter != null) {
      return hangIsAvailableCompleter!.future;
    }
    return available;
  }

  @override
  Future<ProductDetailsResponse> queryProductDetails(
    Set<String> identifiers,
  ) async {
    if (hangQueryProductDetailsCompleter != null) {
      return hangQueryProductDetailsCompleter!.future;
    }
    if (!returnProductDetails) {
      return ProductDetailsResponse(
        productDetails: const [],
        notFoundIDs: identifiers.toList(),
      );
    }
    return ProductDetailsResponse(
      productDetails: [
        ProductDetails(
          id: IapService.kProLifetimeSku,
          title: 'Pro Lifetime',
          description: 'Unlock all Pro features permanently',
          price: r'$1.29',
          rawPrice: 1.29,
          currencyCode: 'USD',
        ),
      ],
      notFoundIDs: const [],
    );
  }

  @override
  Future<bool> buyNonConsumable({required PurchaseParam purchaseParam}) async {
    return buySuccess;
  }

  @override
  Future<bool> buyConsumable({
    required PurchaseParam purchaseParam,
    bool autoConsume = true,
  }) async => false;

  @override
  Future<void> completePurchase(PurchaseDetails purchase) async {
    completedPurchases.add(purchase);
  }

  @override
  Future<void> restorePurchases({String? applicationUserName}) async {}

  @override
  Future<String> countryCode() async => 'US';

  @override
  T getPlatformAddition<T extends InAppPurchasePlatformAddition?>() {
    throw UnimplementedError();
  }

  void emitPurchase(PurchaseDetails purchase) {
    controller.add([purchase]);
  }

  void dispose() {
    controller.close();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _MockInAppPurchase mockIap;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await PersistenceService.instance.resetForTesting();
    EntitlementService.instance.resetForTesting();

    mockIap = _MockInAppPurchase();
    IapService.instance.setIapForTesting(mockIap);
    await IapService.instance.initialize();
  });

  tearDown(() async {
    mockIap.dispose();
    await IapService.instance.resetForTesting();
  });

  group('Phase 16: In-App Purchase Bug Regression & Security Tests', () {
    test(
      'Cancelling the Google Play billing popup does NOT unlock Pro features',
      () async {
        final p = PersistenceService.instance;
        await p.setProUnlocked(false);
        expect(p.isProUnlocked, isFalse);
        expect(
          EntitlementService.instance.isFeatureAccessible(
            ProFeature.mk3SingularityChassis,
          ),
          isFalse,
        );

        // Initiate purchase flow
        final purchaseFuture = EntitlementService.instance
            .purchaseProLifetime();

        // Simulate user clicking Cancel on the Google Play Test card modal
        mockIap.emitPurchase(
          PurchaseDetails(
            purchaseID: 'cancel_tx_99',
            productID: IapService.kProLifetimeSku,
            verificationData: PurchaseVerificationData(
              localVerificationData: 'test_local',
              serverVerificationData: 'test_server',
              source: 'google_play',
            ),
            transactionDate: '2026-09-14',
            status: PurchaseStatus.canceled,
          ),
        );

        final outcome = await purchaseFuture;

        // Verify outcome is canceled and Pro is strictly locked
        expect(outcome.isCanceled, isTrue);
        expect(outcome.isSuccess, isFalse);
        expect(p.isProUnlocked, isFalse);
        expect(EntitlementService.instance.isProUnlocked, isFalse);
        expect(
          EntitlementService.instance.isFeatureAccessible(
            ProFeature.mk3SingularityChassis,
          ),
          isFalse,
        );
      },
    );

    test('Completing purchase successfully unlocks Pro features', () async {
      final p = PersistenceService.instance;
      await p.setProUnlocked(false);
      expect(p.isProUnlocked, isFalse);

      final purchaseFuture = EntitlementService.instance.purchaseProLifetime();

      // Simulate user successfully completing payment
      mockIap.emitPurchase(
        PurchaseDetails(
          purchaseID: 'success_tx_101',
          productID: IapService.kProLifetimeSku,
          verificationData: PurchaseVerificationData(
            localVerificationData: 'test_local',
            serverVerificationData: 'test_server',
            source: 'google_play',
          ),
          transactionDate: '2026-09-14',
          status: PurchaseStatus.purchased,
        )..pendingCompletePurchase = true,
      );

      final outcome = await purchaseFuture;

      expect(outcome.isSuccess, isTrue);
      expect(outcome.isCanceled, isFalse);
      expect(p.isProUnlocked, isTrue);
      expect(EntitlementService.instance.isProUnlocked, isTrue);
      expect(
        EntitlementService.instance.isFeatureAccessible(
          ProFeature.mk3SingularityChassis,
        ),
        isTrue,
      );
      expect(mockIap.completedPurchases, isNotEmpty);
    });

    test(
      'Store billing unavailable fails safely without unlocking Pro',
      () async {
        mockIap.available = false;
        await IapService.instance.initialize();

        final p = PersistenceService.instance;
        await p.setProUnlocked(false);

        final outcome = await EntitlementService.instance.purchaseProLifetime();

        expect(outcome.isError, isTrue);
        expect(
          outcome.errorMessage,
          contains('Google Play Store billing is currently unavailable'),
        );
        expect(p.isProUnlocked, isFalse);
        expect(EntitlementService.instance.isProUnlocked, isFalse);
      },
    );

    test(
      'Missing catalog product details fails safely without unlocking Pro',
      () async {
        mockIap.returnProductDetails = false;
        await IapService.instance.queryProducts();

        final p = PersistenceService.instance;
        await p.setProUnlocked(false);

        final outcome = await EntitlementService.instance.purchaseProLifetime();

        expect(outcome.isError, isTrue);
        expect(
          outcome.errorMessage,
          contains('Pro product details could not be loaded'),
        );
        expect(p.isProUnlocked, isFalse);
        expect(EntitlementService.instance.isProUnlocked, isFalse);
      },
    );

    test(
      'Billing flow launch failure fails safely without unlocking Pro',
      () async {
        mockIap.buySuccess = false;

        final p = PersistenceService.instance;
        await p.setProUnlocked(false);

        final outcome = await EntitlementService.instance.purchaseProLifetime();

        expect(outcome.isError, isTrue);
        expect(
          outcome.errorMessage,
          contains('Failed to launch Google Play billing flow'),
        );
        expect(p.isProUnlocked, isFalse);
        expect(EntitlementService.instance.isProUnlocked, isFalse);
      },
    );

    test(
      'Store transaction error fails safely without unlocking Pro',
      () async {
        final p = PersistenceService.instance;
        await p.setProUnlocked(false);

        final purchaseFuture = EntitlementService.instance
            .purchaseProLifetime();

        mockIap.emitPurchase(
          PurchaseDetails(
              purchaseID: 'err_tx_00',
              productID: IapService.kProLifetimeSku,
              verificationData: PurchaseVerificationData(
                localVerificationData: 'test_local',
                serverVerificationData: 'test_server',
                source: 'google_play',
              ),
              transactionDate: '2026-09-14',
              status: PurchaseStatus.error,
            )
            ..error = IAPError(
              source: 'google_play',
              code: 'ITEM_ALREADY_OWNED',
              message: 'Item is already owned by another account',
            ),
        );

        final outcome = await purchaseFuture;

        expect(outcome.isError, isTrue);
        expect(outcome.errorMessage, contains('already owned'));
        expect(p.isProUnlocked, isFalse);
        expect(EntitlementService.instance.isProUnlocked, isFalse);
      },
    );

    test(
      'Restoring purchases with no prior purchases does not unlock Pro',
      () async {
        final p = PersistenceService.instance;
        await p.setProUnlocked(false);

        await EntitlementService.instance.restorePurchases();
        await Future<void>.delayed(Duration.zero);

        expect(p.isProUnlocked, isFalse);
        expect(EntitlementService.instance.isProUnlocked, isFalse);
      },
    );
  });

  group('Phase 16: ProUpgradeModal UI Cancellation & Unlock Gating Tests', () {
    testWidgets(
      'Cancelling Google Play dialog keeps ProUpgradeModal open and does not invoke onUnlocked',
      (tester) async {
        bool onUnlockedCalled = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => showDialog<void>(
                    context: context,
                    builder: (ctx) => ProUpgradeModal(
                      highlightedFeature: ProFeature.mk3SingularityChassis,
                      onUnlocked: () => onUnlockedCalled = true,
                    ),
                  ),
                  child: const Text('OPEN MODAL'),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('OPEN MODAL'));
        await tester.pumpAndSettle();

        // Tap the primary unlock button
        await tester.tap(find.text('UNLOCK PRO COMMANDER — \$1.29'));
        await tester.pump(); // Enter processing state

        // Simulate user dismissing the Google Play bottom sheet
        mockIap.emitPurchase(
          PurchaseDetails(
            purchaseID: 'cancel_tx_modal',
            productID: IapService.kProLifetimeSku,
            verificationData: PurchaseVerificationData(
              localVerificationData: 'test',
              serverVerificationData: 'test',
              source: 'google_play',
            ),
            transactionDate: '2026-09-14',
            status: PurchaseStatus.canceled,
          ),
        );

        await tester.pumpAndSettle();

        // Modal should still be present
        expect(find.byType(ProUpgradeModal), findsOneWidget);
        expect(onUnlockedCalled, isFalse);
        expect(PersistenceService.instance.isProUnlocked, isFalse);
        expect(
          find.text('TRANSMISSION CANCELLED: Purchase was not completed.'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'Completing purchase in Google Play closes ProUpgradeModal and invokes onUnlocked',
      (tester) async {
        bool onUnlockedCalled = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => showDialog<void>(
                    context: context,
                    builder: (ctx) => ProUpgradeModal(
                      highlightedFeature: ProFeature.mk3SingularityChassis,
                      onUnlocked: () => onUnlockedCalled = true,
                    ),
                  ),
                  child: const Text('OPEN MODAL'),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('OPEN MODAL'));
        await tester.pumpAndSettle();

        // Tap the primary unlock button
        await tester.tap(find.text('UNLOCK PRO COMMANDER — \$1.29'));
        await tester.pump(); // Enter processing state

        // Simulate user completing payment
        mockIap.emitPurchase(
          PurchaseDetails(
            purchaseID: 'success_tx_modal',
            productID: IapService.kProLifetimeSku,
            verificationData: PurchaseVerificationData(
              localVerificationData: 'test',
              serverVerificationData: 'test',
              source: 'google_play',
            ),
            transactionDate: '2026-09-14',
            status: PurchaseStatus.purchased,
          ),
        );

        await tester.runAsync(() async {
          await Future<void>.delayed(const Duration(milliseconds: 50));
        });
        await tester.pumpAndSettle();

        expect(onUnlockedCalled, isTrue);
        expect(PersistenceService.instance.isProUnlocked, isTrue);
        expect(find.byType(ProUpgradeModal), findsNothing);
        expect(
          find.text(
            'PRO COMMANDER UNLOCKED: All features, flagships & ad-free access granted!',
          ),
          findsOneWidget,
        );
      },
    );

    test(
      'IapService initialize completes gracefully when isAvailable hangs (times out)',
      () async {
        mockIap.hangIsAvailableCompleter = Completer<bool>();
        await IapService.instance.initialize(
          timeoutDuration: const Duration(milliseconds: 50),
        );
        expect(IapService.instance.isAvailable, isFalse);
      },
    );

    test(
      'IapService queryProducts completes gracefully when queryProductDetails hangs (times out)',
      () async {
        mockIap.available = true;
        mockIap.hangIsAvailableCompleter = null;
        mockIap.hangQueryProductDetailsCompleter =
            Completer<ProductDetailsResponse>();
        await IapService.instance.initialize(
          timeoutDuration: const Duration(milliseconds: 50),
        );
        expect(IapService.instance.isAvailable, isTrue);
        expect(IapService.instance.proProductDetails, isNull);
      },
    );
  });
}
