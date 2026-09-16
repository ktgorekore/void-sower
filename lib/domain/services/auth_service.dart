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
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../models/auth_account.dart';
import 'persistence_service.dart';

/// Strategy interface for cloud identity and social login providers.
abstract class IAuthClient {
  Future<AuthAccount> signInAnonymously();
  Future<AuthAccount> signInWithGoogle();
  Future<void> signOut();
  AuthAccount? get currentAccount;
}

/// Production Google Sign-In client interfacing with Google Play Services.
class GoogleAuthClient implements IAuthClient {
  GoogleAuthClient({GoogleSignIn? googleSignIn})
    : _googleSignIn =
          googleSignIn ??
          GoogleSignIn(
            scopes: ['email', 'profile'],
            serverClientId:
                '368139306134-keehurh5eivlpr4t641q68drrg0qjktg.apps.googleusercontent.com',
          );

  final GoogleSignIn _googleSignIn;
  AuthAccount? _currentAccount;

  @override
  AuthAccount? get currentAccount => _currentAccount;

  @override
  Future<AuthAccount> signInAnonymously() async {
    _currentAccount = AuthAccount.guest();
    return _currentAccount!;
  }

  @override
  Future<AuthAccount> signInWithGoogle() async {
    try {
      try {
        if (await _googleSignIn.isSignedIn()) {
          await _googleSignIn.signOut();
        }
      } catch (_) {}

      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw PlatformException(
          code: 'SIGN_IN_CANCELLED',
          message: 'Google Sign-In prompt cancelled by user',
        );
      }

      _currentAccount = AuthAccount(
        uid: googleUser.id,
        email: googleUser.email,
        displayName:
            googleUser.displayName ?? googleUser.email.split('@').first,
        photoUrl: googleUser.photoUrl,
        providerType: AuthProviderType.google,
        isAnonymous: false,
        linkedAt: DateTime.now(),
      );
      return _currentAccount!;
    } catch (e) {
      debugPrint('[GoogleAuthClient] signInWithGoogle notice: $e');
      rethrow;
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[GoogleAuthClient] signOut notice: $e');
      }
    }
    _currentAccount = AuthAccount.guest();
  }
}

/// In-memory mock authentication client for unit tests and local emulator operation.
class MockAuthClient implements IAuthClient {
  MockAuthClient({AuthAccount? initialAccount})
    : _currentAccount = initialAccount ?? AuthAccount.guest();

  AuthAccount? _currentAccount;

  @override
  AuthAccount? get currentAccount => _currentAccount;

  @override
  Future<AuthAccount> signInAnonymously() async {
    _currentAccount = AuthAccount.guest();
    return _currentAccount!;
  }

  @override
  Future<AuthAccount> signInWithGoogle() async {
    _currentAccount = AuthAccount(
      uid: 'google_pilot_998234',
      email: 'pilot.vanguard@gmail.com',
      displayName: 'Commander Vanguard',
      photoUrl: null,
      providerType: AuthProviderType.google,
      isAnonymous: false,
      linkedAt: DateTime.now(),
    );
    return _currentAccount!;
  }

  @override
  Future<void> signOut() async {
    _currentAccount = AuthAccount.guest();
  }
}

/// Service orchestrating player authentication, guest fallback, and Google Sign-In linking.
class AuthService extends ChangeNotifier {
  AuthService._internal({IAuthClient? client})
    : _client =
          client ??
          (_detectTestEnvironment() ? MockAuthClient() : GoogleAuthClient()),
      _currentAccount = (client?.currentAccount ?? AuthAccount.guest());

  static final AuthService instance = AuthService._internal();

  /// Creates an instance with an explicit client (useful for unit tests).
  factory AuthService.withClient(IAuthClient client) {
    return AuthService._internal(client: client);
  }

  final IAuthClient _client;
  AuthAccount _currentAccount;

  static bool _detectTestEnvironment() {
    try {
      if (kIsWeb) return false;
      if (Platform.environment.containsKey('FLUTTER_TEST')) return true;
      final type = ServicesBinding.instance.runtimeType.toString();
      return type.startsWith('AutomatedTest') || type.startsWith('TestWidgets');
    } catch (_) {
      return false;
    }
  }

  /// Active authentication account identity.
  AuthAccount get currentAccount => _currentAccount;

  /// Whether active user is playing under an anonymous guest profile.
  bool get isAnonymous => _currentAccount.isAnonymous;

  /// Whether active user is linked with Google Play / Google Sign-In.
  bool get isGoogleLinked =>
      _currentAccount.providerType == AuthProviderType.google;

  String? _lastError;

  /// Most recent authentication error message, or `null` if none.
  String? get lastError => _lastError;

  /// Initializes the service and restores or provisions player identity.
  Future<void> initialize() async {
    if (_client.currentAccount != null) {
      _currentAccount = _client.currentAccount!;
    } else {
      _currentAccount = await _client.signInAnonymously();
    }
    notifyListeners();
  }

  /// Links the current guest account with Google Sign-In.
  Future<bool> linkWithGoogle() async {
    _lastError = null;
    try {
      final account = await _client.signInWithGoogle();
      _currentAccount = account;
      _migrateLocalProfileToCloud(account);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('[AuthService] Google link error: $e');
      if (e is PlatformException) {
        if (e.code == 'SIGN_IN_CANCELLED') {
          _lastError =
              'Google Sign-In was cancelled or no Google Account is registered on this device.';
        } else if (e.code == 'sign_in_failed' ||
            e.message?.contains('10') == true) {
          _lastError =
              'Google Sign-In configuration notice (ApiException: 10). Ensure Play App Signing SHA-1, project support email, and Google provider are configured in Firebase Console.';
        } else {
          _lastError = e.message ?? e.code;
        }
      } else {
        _lastError = e.toString();
      }
      return false;
    }
  }

  /// Links with a simulated Google account for emulator testing or offline previews.
  Future<bool> linkWithSimulatedGoogleAccount({
    String uid = 'google_pilot_vanguard',
    String email = 'pilot.vanguard@gmail.com',
    String displayName = 'Commander Vanguard',
  }) async {
    _lastError = null;
    final account = AuthAccount(
      uid: uid,
      email: email,
      displayName: displayName,
      photoUrl: null,
      providerType: AuthProviderType.google,
      isAnonymous: false,
      linkedAt: DateTime.now(),
    );
    _currentAccount = account;
    _migrateLocalProfileToCloud(account);
    notifyListeners();
    return true;
  }

  /// Signs out of cloud provider and reverts to a local guest account.
  Future<void> signOut() async {
    try {
      await _client.signOut();
      _currentAccount = await _client.signInAnonymously();
      final active = PersistenceService.instance.userProfile;
      final updated = active.copyWith(
        isGoogleLinked: false,
        googleEmail: null,
        googleDisplayName: null,
        googlePhotoUrl: null,
      );
      await PersistenceService.instance.saveUserProfile(updated);
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[AuthService] Sign out error: $e');
      }
    }
  }

  /// Synchronizes the local guest profile with cloud identity credentials.
  void _migrateLocalProfileToCloud(AuthAccount account) {
    final active = PersistenceService.instance.userProfile;
    final updated = active.copyWith(
      isGoogleLinked: true,
      googleEmail: account.email,
      googleDisplayName: account.displayName,
      googlePhotoUrl: account.photoUrl,
      callsign: account.displayName ?? active.callsign,
    );
    PersistenceService.instance.saveUserProfile(updated);
  }
}
