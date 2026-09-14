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

import 'dart:io';

/// Production and test advertisement configuration constants for Google AdMob.
class AdConfig {
  AdConfig._();

  /// Official Google AdMob test rewarded video ad unit ID for Android.
  static const String androidRewardedTestId =
      'ca-app-pub-3940256099942544/5224354917';

  /// Official Google AdMob test rewarded video ad unit ID for iOS.
  static const String iosRewardedTestId =
      'ca-app-pub-3940256099942544/1712485313';

  /// Minimum duration between consecutive rewarded ad impressions.
  static const Duration rewardedCooldown = Duration(minutes: 3);

  /// Number of plasma cores replenished upon rewarded ad completion.
  static const int emergencyCoresReward = 8;

  /// Returns appropriate rewarded ad unit ID for the host operating system.
  static String get rewardedAdUnitId {
    if (Platform.isAndroid) {
      return androidRewardedTestId;
    } else if (Platform.isIOS) {
      return iosRewardedTestId;
    }
    return androidRewardedTestId;
  }
}
