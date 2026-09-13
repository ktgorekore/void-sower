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

import 'persistence_service.dart';
import 'privacy_service.dart';

/// Service managing optional rewarded advertisements with smart frequency capping.
class AdService {
  AdService._();
  static final AdService instance = AdService._();

  DateTime? _lastAdShownTime;
  static const Duration _kAdCooldown = Duration(minutes: 3);

  bool get shouldShowAd {
    if (PersistenceService.instance.isProUnlocked) return false;
    if (!PrivacyService.instance.canRequestAds) return false;

    if (_lastAdShownTime == null) return true;
    return DateTime.now().difference(_lastAdShownTime!) >= _kAdCooldown;
  }

  Future<bool> showRewardedAd() async {
    if (!shouldShowAd) return false;
    _lastAdShownTime = DateTime.now();
    // Simulate rewarded ad completion
    return true;
  }
}
