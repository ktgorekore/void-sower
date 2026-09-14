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

/// Supported cloud identity authentication providers.
enum AuthProviderType { guest, google }

/// Data model representing a player's authenticated identity and cloud credentials.
class AuthAccount {
  const AuthAccount({
    required this.uid,
    this.email,
    this.displayName,
    this.photoUrl,
    required this.providerType,
    required this.isAnonymous,
    required this.linkedAt,
  });

  /// Unique provider user ID or local synthetic guest identifier.
  final String uid;

  /// Player email address (if linked via Google Sign-In).
  final String? email;

  /// Player display name from identity provider.
  final String? displayName;

  /// Profile avatar photo URL.
  final String? photoUrl;

  /// Identity authentication provider type.
  final AuthProviderType providerType;

  /// Whether player is operating under an anonymous local guest profile.
  final bool isAnonymous;

  /// Timestamp when this account identity was created or linked.
  final DateTime linkedAt;

  /// Factory creating an anonymous local guest account.
  factory AuthAccount.guest({String? guestId}) {
    final id = guestId ?? 'usr_guest_${DateTime.now().microsecondsSinceEpoch}';
    return AuthAccount(
      uid: id,
      displayName: 'Guest Pilot',
      providerType: AuthProviderType.guest,
      isAnonymous: true,
      linkedAt: DateTime.now(),
    );
  }

  /// Serializes account identity to JSON map.
  Map<String, dynamic> toJson() => {
    'uid': uid,
    'email': email,
    'displayName': displayName,
    'photoUrl': photoUrl,
    'providerType': providerType.index,
    'isAnonymous': isAnonymous,
    'linkedAt': linkedAt.toIso8601String(),
  };

  /// Deserializes account identity from JSON map.
  factory AuthAccount.fromJson(Map<String, dynamic> json) {
    return AuthAccount(
      uid: json['uid'] as String,
      email: json['email'] as String?,
      displayName: json['displayName'] as String?,
      photoUrl: json['photoUrl'] as String?,
      providerType: AuthProviderType.values[json['providerType'] as int? ?? 0],
      isAnonymous: json['isAnonymous'] as bool? ?? true,
      linkedAt: json['linkedAt'] != null
          ? DateTime.parse(json['linkedAt'] as String)
          : DateTime.now(),
    );
  }
}
