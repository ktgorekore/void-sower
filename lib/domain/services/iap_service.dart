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
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import 'entitlement_service.dart';
import 'persistence_service.dart';

/// Status of an In-App Purchase flow attempt.
enum PurchaseOutcomeStatus {
  /// Purchase successfully completed and validated.
  success,

  /// Purchase was explicitly cancelled by the user.
  canceled,

  /// Purchase is pending external confirmation.
  pending,

  /// Purchase encountered an unrecoverable error.
  error,
}

/// Detailed result of an In-App Purchase attempt.
class PurchaseOutcome {
  /// Creates a successful purchase outcome.
  const PurchaseOutcome.success()
    : status = PurchaseOutcomeStatus.success,
      errorMessage = null;

  /// Creates a cancelled purchase outcome.
  const PurchaseOutcome.canceled()
    : status = PurchaseOutcomeStatus.canceled,
      errorMessage = null;

  /// Creates a pending purchase outcome.
  const PurchaseOutcome.pending()
    : status = PurchaseOutcomeStatus.pending,
      errorMessage = null;

  /// Creates a failed purchase outcome with an [errorMessage].
  const PurchaseOutcome.error(this.errorMessage)
    : status = PurchaseOutcomeStatus.error;

  /// The resulting status of the purchase operation.
  final PurchaseOutcomeStatus status;

  /// Optional error description if the status is [PurchaseOutcomeStatus.error].
  final String? errorMessage;

  /// Whether the purchase was successfully completed.
  bool get isSuccess => status == PurchaseOutcomeStatus.success;

  /// Whether the purchase was cancelled by the user.
  bool get isCanceled => status == PurchaseOutcomeStatus.canceled;

  /// Whether the purchase is currently pending.
  bool get isPending => status == PurchaseOutcomeStatus.pending;

  /// Whether the purchase encountered an error.
  bool get isError => status == PurchaseOutcomeStatus.error;
}

/// Service managing In-App Purchases (Google Play Billing v7).
class IapService {
  IapService._();
  static final IapService instance = IapService._();

  /// SKU for permanent Pro Commander access.
  static const String kProLifetimeSku = 'void_sower_pro_lifetime';

  InAppPurchase? _iapOverride;
  InAppPurchase get _iap => _iapOverride ??= InAppPurchase.instance;

  /// Injects an [InAppPurchase] instance for unit testing.
  @visibleForTesting
  void setIapForTesting(InAppPurchase? iap) {
    _iapOverride = iap;
  }

  StreamSubscription<List<PurchaseDetails>>? _subscription;
  bool _isAvailable = false;
  ProductDetails? _proProductDetails;
  Completer<PurchaseOutcome>? _pendingPurchaseCompleter;

  /// Whether store billing service is connected and ready.
  bool get isAvailable => _isAvailable;

  /// Cached product details for the Pro Lifetime SKU.
  ProductDetails? get proProductDetails => _proProductDetails;

  /// Initializes purchase stream listener and queries product catalog with timeout protection.
  Future<void> initialize({
    Duration timeoutDuration = const Duration(seconds: 3),
  }) async {
    if (!Platform.isAndroid && !Platform.isIOS && _iapOverride == null) {
      _isAvailable = false;
      return;
    }

    try {
      _isAvailable = await _iap.isAvailable().timeout(
        timeoutDuration,
        onTimeout: () {
          debugPrint(
            '[IapService] Store billing availability check timed out.',
          );
          return false;
        },
      );
      if (!_isAvailable) return;

      await _subscription?.cancel();
      _subscription = _iap.purchaseStream.listen(
        _onPurchaseUpdates,
        onDone: () => _subscription?.cancel(),
        onError: (error) {
          debugPrint('[IapService] Purchase stream error: $error');
        },
      );

      await queryProducts(timeoutDuration: timeoutDuration);
    } catch (e) {
      debugPrint('[IapService] Init error: $e');
    }
  }

  /// Queries the Play Store catalog for the Pro Lifetime SKU with timeout protection.
  Future<void> queryProducts({
    Duration timeoutDuration = const Duration(seconds: 3),
  }) async {
    if (!_isAvailable) return;
    try {
      final response = await _iap
          .queryProductDetails({kProLifetimeSku})
          .timeout(
            timeoutDuration,
            onTimeout: () {
              debugPrint('[IapService] Product details query timed out.');
              return ProductDetailsResponse(
                productDetails: [],
                notFoundIDs: [kProLifetimeSku],
              );
            },
          );
      if (response.productDetails.isNotEmpty) {
        _proProductDetails = response.productDetails.first;
      } else {
        _proProductDetails = null;
      }
    } catch (e) {
      debugPrint('[IapService] queryProducts error: $e');
    }
  }

  Future<void> _onPurchaseUpdates(
    List<PurchaseDetails> purchaseDetailsList,
  ) async {
    for (final purchase in purchaseDetailsList) {
      if (purchase.productID == kProLifetimeSku) {
        switch (purchase.status) {
          case PurchaseStatus.purchased:
          case PurchaseStatus.restored:
            await PersistenceService.instance.setProUnlocked(true);
            EntitlementService.instance.notifyEntitlementChanged();
            if (_pendingPurchaseCompleter != null &&
                !_pendingPurchaseCompleter!.isCompleted) {
              _pendingPurchaseCompleter!.complete(
                const PurchaseOutcome.success(),
              );
            }
            if (purchase.pendingCompletePurchase) {
              await _iap.completePurchase(purchase);
            }
            break;

          case PurchaseStatus.canceled:
            if (purchase.pendingCompletePurchase) {
              await _iap.completePurchase(purchase);
            }
            if (_pendingPurchaseCompleter != null &&
                !_pendingPurchaseCompleter!.isCompleted) {
              _pendingPurchaseCompleter!.complete(
                const PurchaseOutcome.canceled(),
              );
            }
            break;

          case PurchaseStatus.error:
            if (purchase.pendingCompletePurchase) {
              await _iap.completePurchase(purchase);
            }
            final errorMsg =
                purchase.error?.message ?? 'Purchase transaction failed.';
            if (_pendingPurchaseCompleter != null &&
                !_pendingPurchaseCompleter!.isCompleted) {
              _pendingPurchaseCompleter!.complete(
                PurchaseOutcome.error(errorMsg),
              );
            }
            break;

          case PurchaseStatus.pending:
            debugPrint('[IapService] Purchase pending for $kProLifetimeSku');
            break;
        }
      } else {
        if (purchase.pendingCompletePurchase) {
          await _iap.completePurchase(purchase);
        }
      }
    }
  }

  /// Initiates buy flow for the Pro Lifetime license and awaits the user's transaction outcome.
  Future<PurchaseOutcome> purchaseProLifetime() async {
    if (!Platform.isAndroid && !Platform.isIOS && _iapOverride == null) {
      debugPrint(
        '[IapService] In-app purchases not supported on this platform.',
      );
      return const PurchaseOutcome.error(
        'In-app purchases are not supported on this platform.',
      );
    }

    if (!_isAvailable) {
      await initialize(timeoutDuration: const Duration(seconds: 4));
    }

    if (!_isAvailable) {
      debugPrint('[IapService] Store billing service unavailable.');
      return const PurchaseOutcome.error(
        'Google Play Store billing is currently unavailable on this device or emulator. Please verify Google Play Store is installed and signed into an active Google account.',
      );
    }

    if (_proProductDetails == null) {
      await queryProducts();
      if (_proProductDetails == null) {
        debugPrint('[IapService] SKU $kProLifetimeSku details not found.');
        return const PurchaseOutcome.error(
          'Pro product details could not be loaded from Google Play Store.',
        );
      }
    }

    if (_pendingPurchaseCompleter != null &&
        !_pendingPurchaseCompleter!.isCompleted) {
      _pendingPurchaseCompleter!.complete(const PurchaseOutcome.canceled());
    }
    final completer = Completer<PurchaseOutcome>();
    _pendingPurchaseCompleter = completer;

    try {
      final purchaseParam = PurchaseParam(productDetails: _proProductDetails!);
      final launched = await _iap.buyNonConsumable(
        purchaseParam: purchaseParam,
      );
      if (!launched) {
        if (!completer.isCompleted) {
          completer.complete(
            const PurchaseOutcome.error(
              'Failed to launch Google Play billing flow.',
            ),
          );
        }
        return await completer.future;
      }
      return await completer.future;
    } catch (e) {
      debugPrint('[IapService] purchase error: $e');
      if (!completer.isCompleted) {
        completer.complete(PurchaseOutcome.error(e.toString()));
      }
      return await completer.future;
    }
  }

  /// Restores previous purchases across devices.
  Future<void> restorePurchases() async {
    if (!Platform.isAndroid && !Platform.isIOS && _iapOverride == null) {
      return;
    }
    if (!_isAvailable) {
      await initialize(timeoutDuration: const Duration(seconds: 4));
    }
    if (!_isAvailable) {
      debugPrint('[IapService] Store unavailable, cannot restore purchases.');
      return;
    }
    try {
      await _iap.restorePurchases();
    } catch (e) {
      debugPrint('[IapService] restorePurchases error: $e');
    }
  }

  /// Disposes stream listener and cancels any pending purchase completers.
  void dispose() {
    _subscription?.cancel();
    _subscription = null;
    if (_pendingPurchaseCompleter != null &&
        !_pendingPurchaseCompleter!.isCompleted) {
      _pendingPurchaseCompleter!.complete(const PurchaseOutcome.canceled());
    }
    _pendingPurchaseCompleter = null;
  }

  /// Resets internal state for unit testing.
  @visibleForTesting
  Future<void> resetForTesting() async {
    await _subscription?.cancel();
    _subscription = null;
    _isAvailable = false;
    _proProductDetails = null;
    _iapOverride = null;
    if (_pendingPurchaseCompleter != null &&
        !_pendingPurchaseCompleter!.isCompleted) {
      _pendingPurchaseCompleter!.complete(const PurchaseOutcome.canceled());
    }
    _pendingPurchaseCompleter = null;
  }
}
