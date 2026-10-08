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
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../config/ad_config.dart';
import 'persistence_service.dart';
import 'privacy_service.dart';

/// Discrete lifecycle states for rewarded advertisement management.
enum AdLifecycleState {
  /// AdMob SDK has not yet been initialized.
  uninitialized,

  /// SDK is initialized; no ad is currently cached or loading.
  idle,

  /// Rewarded ad request is in flight across the network.
  loading,

  /// Rewarded ad is pre-cached and ready for immediate display.
  ready,

  /// Ad is actively displaying full-screen video over the app viewport.
  showing,

  /// Ad load or playback encountered an unrecoverable error.
  error,
}

/// Service managing optional rewarded advertisements with smart frequency capping.
class AdService {
  AdService._();
  static final AdService instance = AdService._();

  DateTime? _lastEmergencyFlareTime;
  RewardedAd? _rewardedAd;
  AdLifecycleState _lifecycleState = AdLifecycleState.uninitialized;
  bool _simulateMobileForTesting = false;
  Completer<RewardedAd?>? _loadingCompleter;

  /// Current ad lifecycle state.
  AdLifecycleState get lifecycleState => _lifecycleState;

  /// Resets the rewarded ad cooldown timer for unit tests.
  @visibleForTesting
  void resetCooldownForTesting() {
    _lastEmergencyFlareTime = null;
    _lifecycleState = AdLifecycleState.idle;
  }

  /// Sets whether the service simulates a mobile platform environment for unit testing.
  @visibleForTesting
  void setSimulateMobileForTesting(bool simulate) {
    _simulateMobileForTesting = simulate;
  }

  /// Sets a cached rewarded ad for unit tests.
  @visibleForTesting
  void setRewardedAdForTesting(RewardedAd? ad) {
    _rewardedAd = ad;
    _lifecycleState = ad != null
        ? AdLifecycleState.ready
        : AdLifecycleState.idle;
  }

  /// Sets lifecycle state explicitly for unit tests.
  @visibleForTesting
  void setLifecycleStateForTesting(AdLifecycleState state) {
    _lifecycleState = state;
  }

  /// Initializes AdMob SDK and pre-loads the initial rewarded ad with timeout protection.
  Future<void> initialize({
    Duration timeoutDuration = const Duration(seconds: 3),
  }) async {
    if (_lifecycleState != AdLifecycleState.uninitialized) return;

    if (PersistenceService.instance.areAdsDisabled) {
      debugPrint('[AdService] Ads suppressed via configuration.');
      _lifecycleState = AdLifecycleState.idle;
      return;
    }

    if (Platform.isAndroid || Platform.isIOS) {
      try {
        await MobileAds.instance.initialize().timeout(
          timeoutDuration,
          onTimeout: () {
            debugPrint('[AdService] MobileAds initialization timed out.');
            return InitializationStatus({});
          },
        );
        _lifecycleState = AdLifecycleState.idle;
        unawaited(loadRewardedAd());
      } catch (e) {
        debugPrint('[AdService] MobileAds init error: $e');
        _lifecycleState = AdLifecycleState.error;
      }
    } else {
      _lifecycleState = AdLifecycleState.idle;
    }
  }

  /// Whether the emergency flare cooldown has expired and is ready for use.
  bool get canRequestEmergencyFlare {
    if (_lastEmergencyFlareTime == null) return true;
    return DateTime.now().difference(_lastEmergencyFlareTime!) >=
        AdConfig.rewardedCooldown;
  }

  /// Backward-compatible check for ad display capability.
  bool get shouldShowAd {
    if (!PrivacyService.instance.canRequestAds &&
        !PersistenceService.instance.isProUnlocked) {
      return false;
    }
    return canRequestEmergencyFlare;
  }

  /// Asynchronously loads and caches a rewarded advertisement.
  /// Guarantees single-flight loading across concurrent callers.
  Future<RewardedAd?> loadRewardedAd() {
    if (PersistenceService.instance.areAdsDisabled) {
      return Future.value(null);
    }
    if (_lifecycleState == AdLifecycleState.showing) {
      debugPrint('[AdService] Cannot load ad while another ad is showing.');
      return Future.value(null);
    }
    if (_rewardedAd != null) {
      _lifecycleState = AdLifecycleState.ready;
      return Future.value(_rewardedAd);
    }
    if (_lifecycleState == AdLifecycleState.loading &&
        _loadingCompleter != null) {
      return _loadingCompleter!.future;
    }
    if (!Platform.isAndroid && !Platform.isIOS) {
      return Future.value(null);
    }

    _lifecycleState = AdLifecycleState.loading;
    _loadingCompleter = Completer<RewardedAd?>();

    RewardedAd.load(
      adUnitId: AdConfig.rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          debugPrint('[AdService] RewardedAd loaded successfully.');
          _rewardedAd = ad;
          _lifecycleState = AdLifecycleState.ready;
          if (_loadingCompleter != null && !_loadingCompleter!.isCompleted) {
            _loadingCompleter!.complete(ad);
          }
        },
        onAdFailedToLoad: (error) {
          debugPrint('[AdService] RewardedAd failed to load: $error');
          _rewardedAd = null;
          _lifecycleState = AdLifecycleState.error;
          if (_loadingCompleter != null && !_loadingCompleter!.isCompleted) {
            _loadingCompleter!.complete(null);
          }
        },
      ),
    );

    return _loadingCompleter!.future;
  }

  /// Displays the rewarded ad or grants an immediate pass if Pro Commander is unlocked
  /// or if ads are disabled (for testing, store screenshots, and promotional recordings).
  /// If [isEmergencyFlare] is true, enforces the 3-minute emergency cooldown.
  /// User-initiated feature unlock passes never suffer from emergency flare cooldowns.
  /// Returns `true` if the reward was earned, `false` otherwise.
  /// Note: This method decouples reward presentation from Pro Boost grants;
  /// calling features are responsible for awarding specific perks.
  Future<bool> showRewardedAd({bool isEmergencyFlare = false}) async {
    // Single-flight guard: prevent concurrent ad presentations
    if (_lifecycleState == AdLifecycleState.showing) {
      debugPrint('[AdService] RewardedAd presentation already in-flight.');
      return false;
    }

    // Pro commander privilege or explicit suppression: instant pass without ads
    if (PersistenceService.instance.isProUnlocked ||
        PersistenceService.instance.areAdsDisabled) {
      if (isEmergencyFlare) {
        _lastEmergencyFlareTime = DateTime.now();
      }
      return true;
    }

    if (isEmergencyFlare && !canRequestEmergencyFlare) {
      debugPrint('[AdService] Emergency flare is on active cooldown.');
      return false;
    }

    // Graceful fallback for non-mobile development & testing environments
    if (!_simulateMobileForTesting && !Platform.isAndroid && !Platform.isIOS) {
      if (isEmergencyFlare) {
        _lastEmergencyFlareTime = DateTime.now();
      }
      return true;
    }

    // If ad is not pre-cached, wait for in-flight or on-demand load with timeout
    RewardedAd? adToShow = _rewardedAd;
    if (adToShow == null) {
      try {
        adToShow = await loadRewardedAd().timeout(
          const Duration(seconds: 4),
          onTimeout: () {
            debugPrint('[AdService] Ad loading timed out waiting for display.');
            return null;
          },
        );
      } catch (e) {
        debugPrint('[AdService] Ad loading error: $e');
        adToShow = null;
      }
    }

    if (adToShow == null) {
      debugPrint(
        '[AdService] No ad available; cannot grant reward without viewing.',
      );
      _lifecycleState = AdLifecycleState.error;
      unawaited(loadRewardedAd());
      return false;
    }

    _lifecycleState = AdLifecycleState.showing;
    final completer = Completer<bool>();
    var rewardEarned = false;

    adToShow.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        debugPrint('[AdService] RewardedAd displayed full screen.');
      },
      onAdDismissedFullScreenContent: (ad) {
        debugPrint(
          '[AdService] RewardedAd dismissed. Reward earned: $rewardEarned',
        );
        ad.dispose();
        _rewardedAd = null;
        _lifecycleState = AdLifecycleState.idle;
        unawaited(loadRewardedAd());
        if (!completer.isCompleted) {
          completer.complete(rewardEarned);
        }
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('[AdService] RewardedAd playback error: $error');
        ad.dispose();
        _rewardedAd = null;
        _lifecycleState = AdLifecycleState.error;
        unawaited(loadRewardedAd());
        if (!completer.isCompleted) {
          completer.complete(false);
        }
      },
    );

    _rewardedAd = null;

    adToShow.show(
      onUserEarnedReward: (adWithoutView, reward) {
        debugPrint(
          '[AdService] User earned reward: ${reward.type} ${reward.amount}',
        );
        rewardEarned = true;
      },
    );

    if (isEmergencyFlare) {
      _lastEmergencyFlareTime = DateTime.now();
    }

    return completer.future;
  }
}
