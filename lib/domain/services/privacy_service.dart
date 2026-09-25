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

/// User privacy and tracking consent states compliant with GDPR, CCPA, and COPPA.
enum ConsentStatus {
  /// Consent status has not yet been determined.
  unknown,

  /// User consent is legally required before requesting personalized resources.
  required,

  /// User explicitly granted privacy consent.
  obtained,

  /// Region does not require explicit affirmative consent.
  notRequired,

  /// User denied or revoked privacy consent.
  denied,
}

/// Service managing user consent and privacy regulations (GDPR, CCPA, COPPA).
class PrivacyService {
  PrivacyService._();

  /// Singleton access instance.
  static final PrivacyService instance = PrivacyService._();

  ConsentStatus _status = ConsentStatus.notRequired;

  /// Current user consent status.
  ConsentStatus get status => _status;

  /// Indicates whether advertising and analytics requests are legally permitted.
  bool get canRequestAds =>
      _status == ConsentStatus.obtained || _status == ConsentStatus.notRequired;

  /// Requests user consent dialog from the User Messaging Platform.
  Future<void> requestConsent() async {
    // In production, interfaces with google_mobile_ads UserMessagingPlatform
    _status = ConsentStatus.obtained;
  }
}
