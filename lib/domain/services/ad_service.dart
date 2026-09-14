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

/// Service managing optional rewarded advertisements with smart frequency capping.
class AdService {
  AdService._();
  static final AdService instance = AdService._();

  DateTime? _lastAdShownTime;
  RewardedAd? _rewardedAd;
  bool _isAdLoading = false;
  bool _initialized = false;

  /// Resets the rewarded ad cooldown timer for unit tests.
  @visibleForTesting
  void resetCooldownForTesting() {
    _lastAdShownTime = null;
  }

  /// Initializes AdMob SDK and pre-loads the initial rewarded ad.
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    if (Platform.isAndroid || Platform.isIOS) {
      try {
        await MobileAds.instance.initialize();
        loadRewardedAd();
      } catch (e) {
        debugPrint('[AdService] MobileAds init error: $e');
      }
    }
  }

  /// Whether the emergency flare cooldown has expired and is ready for use.
  bool get canRequestEmergencyFlare {
    if (_lastAdShownTime == null) return true;
    return DateTime.now().difference(_lastAdShownTime!) >=
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
  void loadRewardedAd() {
    if (_isAdLoading || _rewardedAd != null) return;
    if (!Platform.isAndroid && !Platform.isIOS) return;

    _isAdLoading = true;
    RewardedAd.load(
      adUnitId: AdConfig.rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isAdLoading = false;
        },
        onAdFailedToLoad: (error) {
          debugPrint('[AdService] RewardedAd failed to load: $error');
          _rewardedAd = null;
          _isAdLoading = false;
        },
      ),
    );
  }

  /// Displays the rewarded ad or grants an immediate pass if Pro Commander is unlocked.
  /// Returns `true` if the emergency core charge was earned, `false` otherwise.
  Future<bool> showRewardedAd() async {
    // Pro commander privilege: instant emergency flare without ads
    if (PersistenceService.instance.isProUnlocked) {
      _lastAdShownTime = DateTime.now();
      return true;
    }

    if (!canRequestEmergencyFlare) return false;

    // Graceful fallback for non-mobile development & testing environments
    if (!Platform.isAndroid && !Platform.isIOS) {
      _lastAdShownTime = DateTime.now();
      return true;
    }

    if (_rewardedAd == null) {
      loadRewardedAd();
      // Fallback emergency allowance if ad network is offline
      _lastAdShownTime = DateTime.now();
      return true;
    }

    final completer = Completer<bool>();
    var rewardEarned = false;

    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _rewardedAd = null;
        loadRewardedAd();
        if (!completer.isCompleted) {
          completer.complete(rewardEarned);
        }
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('[AdService] RewardedAd playback error: $error');
        ad.dispose();
        _rewardedAd = null;
        loadRewardedAd();
        if (!completer.isCompleted) {
          // Graceful fallback on playback error
          completer.complete(true);
        }
      },
    );

    _rewardedAd!.show(
      onUserEarnedReward: (adWithoutView, reward) {
        rewardEarned = true;
      },
    );

    _lastAdShownTime = DateTime.now();
    return completer.future;
  }
}
