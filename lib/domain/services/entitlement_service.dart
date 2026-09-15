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
import 'package:flutter/foundation.dart';

import '../models/pro_feature.dart';
import 'ad_service.dart';
import 'iap_service.dart';
import 'persistence_service.dart';

export 'iap_service.dart' show PurchaseOutcome, PurchaseOutcomeStatus;

/// Central authority managing permanent Pro entitlements and temporary Rewarded Ad passes.
class EntitlementService extends ChangeNotifier {
  EntitlementService._();
  static final EntitlementService instance = EntitlementService._();

  final Map<ProFeature, DateTime> _temporaryPasses = {};
  int _aiSolverRemainingMoves = 0;

  /// Whether the player holds a lifetime Pro license.
  bool get isProUnlocked => PersistenceService.instance.isProUnlocked;

  /// Number of rewarded AI solver moves currently remaining in session.
  int get aiSolverRemainingMoves => _aiSolverRemainingMoves;

  /// Checks whether a given [ProFeature] is currently accessible.
  bool isFeatureAccessible(ProFeature feature) {
    if (isProUnlocked) return true;

    if (feature == ProFeature.aiTacticalSolver) {
      if (_aiSolverRemainingMoves > 0) return true;
    }

    final expiry = _temporaryPasses[feature];
    if (expiry != null) {
      if (DateTime.now().isBefore(expiry)) {
        return true;
      } else {
        _temporaryPasses.remove(feature);
      }
    }

    return false;
  }

  /// Consumes one rewarded AI solver move if operating under a temporary pass.
  void consumeAiSolverMove() {
    if (isProUnlocked) return;
    if (_aiSolverRemainingMoves > 0) {
      _aiSolverRemainingMoves--;
      notifyListeners();
    }
  }

  /// Grants a temporary pass for a specific [ProFeature] (e.g. from a rewarded ad).
  void grantTemporaryPass(
    ProFeature feature, {
    Duration duration = const Duration(minutes: 15),
    int moves = 3,
  }) {
    if (feature == ProFeature.aiTacticalSolver) {
      _aiSolverRemainingMoves += moves;
    }
    _temporaryPasses[feature] = DateTime.now().add(duration);
    notifyListeners();
  }

  /// Initiates rewarded transmission flow to unlock a temporary pass.
  Future<bool> unlockWithRewardedAd(ProFeature feature) async {
    final success = await AdService.instance.showRewardedAd();
    if (success) {
      grantTemporaryPass(feature);
      return true;
    }
    return false;
  }

  /// Purchases the lifetime Pro license via Google Play Billing.
  Future<PurchaseOutcome> purchaseProLifetime() async {
    final outcome = await IapService.instance.purchaseProLifetime();
    if (outcome.isSuccess) {
      notifyListeners();
    }
    return outcome;
  }

  /// Restores existing Google Play purchases.
  Future<void> restorePurchases() async {
    await IapService.instance.restorePurchases();
    notifyListeners();
  }

  /// Explicitly notifies listeners when entitlement changes from external stream events.
  void notifyEntitlementChanged() {
    notifyListeners();
  }

  /// Clears temporary passes (for testing).
  @visibleForTesting
  void resetForTesting() {
    _temporaryPasses.clear();
    _aiSolverRemainingMoves = 0;
    notifyListeners();
  }
}
