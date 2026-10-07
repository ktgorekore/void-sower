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

import '../models/entitlement_state.dart';
import '../models/pro_feature.dart';
import 'ad_service.dart';
import 'iap_service.dart';
import 'persistence_service.dart';

export 'iap_service.dart' show PurchaseOutcome, PurchaseOutcomeStatus;

/// Central authority managing permanent Pro entitlements and temporary Rewarded Ad passes.
class EntitlementService extends ChangeNotifier {
  EntitlementService._() {
    syncStateFromPersistence();
  }
  static final EntitlementService instance = EntitlementService._();

  late EntitlementStateMachine _stateMachine;
  final Map<ProFeature, DateTime> _temporaryPasses = {};
  int _aiSolverRemainingMoves = 0;

  /// Synchronizes state machine with local persistence on startup or account switch.
  void syncStateFromPersistence() {
    if (PersistenceService.instance.isProUnlocked) {
      _stateMachine = EntitlementStateMachine(
        initialState: const LifetimeProEntitlement(),
      );
    } else {
      final savedExpiry = PersistenceService.instance.proBoostExpiry;
      if (savedExpiry != null && DateTime.now().isBefore(savedExpiry)) {
        _stateMachine = EntitlementStateMachine(
          initialState: TimedBoostEntitlement(expiresAt: savedExpiry),
        );
      } else {
        _stateMachine = EntitlementStateMachine(
          initialState: const StandardFreeEntitlement(),
        );
      }
    }
  }

  /// Current exhaustive entitlement state (StandardFree, TimedBoost, LifetimePro).
  EntitlementState get entitlementState {
    if (PersistenceService.instance.isProUnlocked) {
      return const LifetimeProEntitlement();
    }
    if (_stateMachine.currentState is LifetimeProEntitlement) {
      _stateMachine.resetToFree();
    }
    return _stateMachine.currentState;
  }

  /// Whether the player holds a lifetime Pro license.
  bool get isProUnlocked => PersistenceService.instance.isProUnlocked;

  /// Whether the player holds active Pro privileges (lifetime Pro or active timed boost).
  bool get hasActivePro => isProUnlocked || entitlementState.hasProAccess;

  /// Whether an ad-boosted Pro pass is currently active.
  bool get isBoostActive => entitlementState.isBoostActive;

  /// Remaining duration of the active Pro boost, or [Duration.zero].
  Duration get remainingBoostTime => entitlementState.remainingBoostTime;

  /// Formatted countdown display (e.g. '04:59') if boost is active, or empty string.
  String get formattedRemainingBoostTime =>
      entitlementState.formattedRemainingTime;

  /// Number of rewarded AI solver moves currently remaining in session.
  int get aiSolverRemainingMoves => _aiSolverRemainingMoves;

  /// Checks whether a given [ProFeature] is currently accessible.
  bool isFeatureAccessible(ProFeature feature) {
    if (isProUnlocked || entitlementState.hasProAccess) return true;

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

  /// Grants a stackable timed Pro Boost (default 5 minutes, stackable up to 60m).
  void grantStackableBoost({
    Duration duration = EntitlementStateMachine.boostDurationPerAd,
  }) {
    _stateMachine.grantBoost(duration: duration);
    final state = _stateMachine.currentState;
    if (state is TimedBoostEntitlement) {
      unawaited(PersistenceService.instance.setProBoostExpiry(state.expiresAt));
    }
    notifyListeners();
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

  /// Total remaining minutes of active Pro boost rounded up, or 0.
  int get boostMinutesRemaining => (remainingBoostTime.inSeconds + 59) ~/ 60;

  /// Maximum allowed Pro boost minutes (60 minutes).
  int get maxBoostMinutes => 60;

  /// Fraction of max boost active (0.0 to 1.0).
  double get boostFraction =>
      (remainingBoostTime.inSeconds / 3600.0).clamp(0.0, 1.0);

  /// Number of 5-minute segments lit (0 to 12) out of 12.
  int get boostSegmentsLit =>
      (remainingBoostTime.inSeconds / 300.0).ceil().clamp(0, 12);

  /// Whether player has reached or is near the maximum stacked boost limit.
  bool get isMaxBoostReached =>
      remainingBoostTime >= const Duration(minutes: 58);

  /// Initiates rewarded ad flow to unlock a stackable 5-minute Pro Boost app-wide.
  ///
  /// Always awards 5 minutes of full Pro access across ALL features, stackable
  /// up to 60 minutes.
  Future<bool> unlockWithRewardedAd([ProFeature? feature]) async {
    final success = await AdService.instance.showRewardedAd(
      isEmergencyFlare: false,
    );
    if (success) {
      if (feature != null) {
        grantTemporaryPass(feature);
      }
      return true;
    }
    return false;
  }

  /// Purchases the lifetime Pro license via Google Play Billing.
  Future<PurchaseOutcome> purchaseProLifetime() async {
    final outcome = await IapService.instance.purchaseProLifetime();
    if (outcome.isSuccess) {
      _stateMachine.unlockLifetimePro();
      await PersistenceService.instance.setProBoostExpiry(null);
      notifyListeners();
    }
    return outcome;
  }

  /// Restores existing Google Play purchases.
  Future<void> restorePurchases() async {
    await IapService.instance.restorePurchases();
    if (PersistenceService.instance.isProUnlocked) {
      _stateMachine.unlockLifetimePro();
    }
    notifyListeners();
  }

  /// Explicitly notifies listeners when entitlement changes from external stream events.
  void notifyEntitlementChanged() {
    notifyListeners();
  }

  /// Clears temporary passes and resets state machine (for testing).
  @visibleForTesting
  void resetForTesting() {
    _temporaryPasses.clear();
    _aiSolverRemainingMoves = 0;
    _stateMachine.resetToFree();
    notifyListeners();
  }
}
