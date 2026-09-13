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

enum ConsentStatus { unknown, required, obtained, notRequired, denied }

/// Service managing user consent and privacy regulations (GDPR, CCPA, COPPA).
class PrivacyService {
  PrivacyService._();
  static final PrivacyService instance = PrivacyService._();

  ConsentStatus _status = ConsentStatus.notRequired;
  ConsentStatus get status => _status;

  bool get canRequestAds =>
      _status == ConsentStatus.obtained || _status == ConsentStatus.notRequired;

  Future<void> requestConsent() async {
    // In production, interfaces with google_mobile_ads UserMessagingPlatform
    _status = ConsentStatus.obtained;
  }
}
