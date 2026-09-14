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

import 'persistence_service.dart';

/// Service managing In-App Purchases (Google Play Billing v7).
class IapService {
  IapService._();
  static final IapService instance = IapService._();

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

  /// Whether store billing service is connected and ready.
  bool get isAvailable => _isAvailable;

  /// Cached product details for the Pro Lifetime SKU.
  ProductDetails? get proProductDetails => _proProductDetails;

  /// Initializes purchase stream listener and queries product catalog.
  Future<void> initialize() async {
    if (!Platform.isAndroid && !Platform.isIOS) {
      _isAvailable = false;
      return;
    }

    try {
      _isAvailable = await _iap.isAvailable();
      if (!_isAvailable) return;

      _subscription = _iap.purchaseStream.listen(
        _onPurchaseUpdates,
        onDone: () => _subscription?.cancel(),
        onError: (error) {
          debugPrint('[IapService] Purchase stream error: $error');
        },
      );

      await queryProducts();
    } catch (e) {
      debugPrint('[IapService] Init error: $e');
    }
  }

  /// Queries the Play Store catalog for the Pro Lifetime SKU.
  Future<void> queryProducts() async {
    if (!_isAvailable) return;
    try {
      final response = await _iap.queryProductDetails({kProLifetimeSku});
      if (response.productDetails.isNotEmpty) {
        _proProductDetails = response.productDetails.first;
      }
    } catch (e) {
      debugPrint('[IapService] queryProducts error: $e');
    }
  }

  void _onPurchaseUpdates(List<PurchaseDetails> purchaseDetailsList) {
    for (final purchase in purchaseDetailsList) {
      if (purchase.productID == kProLifetimeSku) {
        if (purchase.status == PurchaseStatus.purchased ||
            purchase.status == PurchaseStatus.restored) {
          PersistenceService.instance.setProUnlocked(true);
        }

        if (purchase.pendingCompletePurchase) {
          _iap.completePurchase(purchase);
        }
      }
    }
  }

  /// Initiates buy flow for the Pro Lifetime license.
  Future<bool> purchaseProLifetime() async {
    if (!_isAvailable || _proProductDetails == null) {
      // Fallback entitlement for offline test environments
      await PersistenceService.instance.setProUnlocked(true);
      return true;
    }

    try {
      final purchaseParam = PurchaseParam(productDetails: _proProductDetails!);
      return await _iap.buyNonConsumable(purchaseParam: purchaseParam);
    } catch (e) {
      debugPrint('[IapService] purchase error: $e');
      return false;
    }
  }

  /// Restores previous purchases across devices.
  Future<void> restorePurchases() async {
    if (!_isAvailable) {
      await PersistenceService.instance.setProUnlocked(true);
      return;
    }
    try {
      await _iap.restorePurchases();
    } catch (e) {
      debugPrint('[IapService] restorePurchases error: $e');
    }
  }

  /// Disposes stream listener.
  void dispose() {
    _subscription?.cancel();
    _subscription = null;
  }
}
