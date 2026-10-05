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

/// Exhaustive state machine modeling player entitlement & Pro feature access in Void Sower.
///
/// Replaces fragmented boolean flags with a unified state machine supporting:
/// * [StandardFreeEntitlement]: Baseline free tier.
/// * [TimedBoostEntitlement]: Stackable 5-minute Pro Boost unlocked via rewarded ad (stackable up to 60m).
/// * [LifetimeProEntitlement]: Permanent Pro tier purchased via in-app billing.
sealed class EntitlementState {
  /// Creates an [EntitlementState] instance.
  const EntitlementState();

  /// Whether the player has permanent Pro lifetime entitlement.
  bool get isLifetimePro => false;

  /// Whether an ad-boosted Pro pass is currently active.
  bool get isBoostActive => false;

  /// Whether Pro features (Incursion mode, Daily Sorties, MCTS solver, Hangar skins) are accessible.
  bool get hasProAccess => isLifetimePro || isBoostActive;

  /// Time remaining on current boost, or [Duration.zero] if none.
  Duration get remainingBoostTime => Duration.zero;

  /// Formatted countdown display (e.g. '04:59') if boost is active, or empty string.
  String get formattedRemainingTime => '';
}

/// Baseline free-tier entitlement.
final class StandardFreeEntitlement extends EntitlementState {
  /// Creates a [StandardFreeEntitlement] instance.
  const StandardFreeEntitlement();
}

/// Temporary app-wide Pro Boost granting full Pro access for a stackable duration.
final class TimedBoostEntitlement extends EntitlementState {
  /// Expiration timestamp of the active boost.
  final DateTime expiresAt;

  /// Creates a [TimedBoostEntitlement] expiring at [expiresAt].
  const TimedBoostEntitlement({required this.expiresAt});

  @override
  bool get isBoostActive => DateTime.now().isBefore(expiresAt);

  @override
  Duration get remainingBoostTime {
    final diff = expiresAt.difference(DateTime.now());
    return diff.isNegative ? Duration.zero : diff;
  }

  @override
  String get formattedRemainingTime {
    final remaining = remainingBoostTime;
    if (remaining <= Duration.zero) return '00:00';
    final minutes = remaining.inMinutes
        .remainder(60)
        .toString()
        .padLeft(2, '0');
    final seconds = remaining.inSeconds
        .remainder(60)
        .toString()
        .padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

/// Permanent Pro lifetime tier with unlimited access and zero ads.
final class LifetimeProEntitlement extends EntitlementState {
  /// Creates a [LifetimeProEntitlement] instance.
  const LifetimeProEntitlement();

  @override
  bool get isLifetimePro => true;
}

/// State machine governing player entitlement, reward ad boosts, and Pro status.
class EntitlementStateMachine {
  /// Default duration awarded per rewarded ad watch (5 minutes).
  static const Duration boostDurationPerAd = Duration(minutes: 5);

  /// Maximum allowed stacked boost duration (60 minutes).
  static const Duration maxBoostDuration = Duration(minutes: 60);

  EntitlementState _currentState;

  /// Creates an [EntitlementStateMachine] with an initial [state].
  EntitlementStateMachine({
    EntitlementState initialState = const StandardFreeEntitlement(),
  }) : _currentState = initialState;

  /// Current entitlement state.
  EntitlementState get currentState {
    // If current state is a boost that has expired, transition back to standard free.
    if (_currentState is TimedBoostEntitlement) {
      final boost = _currentState as TimedBoostEntitlement;
      if (!boost.isBoostActive) {
        _currentState = const StandardFreeEntitlement();
      }
    }
    return _currentState;
  }

  /// Extends or initiates a stackable timed Pro Boost by [duration] (default 5 minutes).
  ///
  /// Stacks additively up to [maxBoostDuration] (60 minutes) from the current time.
  /// If player already holds [LifetimeProEntitlement], this operation is a no-op.
  void grantBoost({Duration duration = boostDurationPerAd}) {
    if (_currentState.isLifetimePro) return;

    final now = DateTime.now();
    final maxAllowedExpiry = now.add(maxBoostDuration);

    DateTime newExpiry;
    if (_currentState is TimedBoostEntitlement &&
        (_currentState as TimedBoostEntitlement).isBoostActive) {
      final currentExpiry = (_currentState as TimedBoostEntitlement).expiresAt;
      newExpiry = currentExpiry.add(duration);
    } else {
      newExpiry = now.add(duration);
    }

    if (newExpiry.isAfter(maxAllowedExpiry)) {
      newExpiry = maxAllowedExpiry;
    }

    _currentState = TimedBoostEntitlement(expiresAt: newExpiry);
  }

  /// Upgrades player to lifetime Pro entitlement permanently.
  void unlockLifetimePro() {
    _currentState = const LifetimeProEntitlement();
  }

  /// Restores entitlement state to baseline free tier.
  void resetToFree() {
    _currentState = const StandardFreeEntitlement();
  }
}
