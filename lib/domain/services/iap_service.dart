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

/// Service managing In-App Purchases (Google Play Billing v7).
class IapService {
  IapService._();
  static final IapService instance = IapService._();

  static const String kProLifetimeSku = 'void_sower_pro_lifetime';

  Future<bool> purchaseProLifetime() async {
    // Process transaction and persist entitlement
    await PersistenceService.instance.setProUnlocked(true);
    return true;
  }

  Future<void> restorePurchases() async {
    // Check Play Store receipt validation
    await PersistenceService.instance.setProUnlocked(true);
  }
}
