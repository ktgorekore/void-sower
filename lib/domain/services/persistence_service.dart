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

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_profile.dart';

/// Persistence service managing local guest progress, player settings, and save export/import.
class PersistenceService {
  PersistenceService._();
  static final PersistenceService instance = PersistenceService._();

  SharedPreferences? _prefs;

  /// Initializes SharedPreferences instance.
  Future<void> initialize() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  static const String _kHighScore = 'void_sower_high_score';
  static const String _kLiberatedSectors = 'void_sower_liberated_sectors';
  static const String _kProUnlocked = 'void_sower_pro_unlocked';
  static const String _kSoundEnabled = 'void_sower_sound_enabled';
  static const String _kHapticsEnabled = 'void_sower_haptics_enabled';

  static const String _kSfxVolume = 'void_sower_sfx_volume';
  static const String _kBgmVolume = 'void_sower_bgm_volume';
  static const String _kIsSfxMuted = 'void_sower_is_sfx_muted';
  static const String _kIsBgmMuted = 'void_sower_is_bgm_muted';

  static const String _kHighShadersEnabled = 'void_sower_high_shaders_enabled';
  static const String _kTargetFps = 'void_sower_target_fps';
  static const String _kLowBatteryMode = 'void_sower_low_battery_mode';

  static const String _kVlogLevel = 'void_sower_vlog_level';
  static const String _kShowFpsCounter = 'void_sower_show_fps_counter';
  static const String _kCrashReportingConsent =
      'void_sower_crash_reporting_consent';
  static const String _kPersonalizedAdsConsent =
      'void_sower_personalized_ads_consent';

  static const String _kUserProfile = 'void_sower_user_profile';

  // --- Campaign & Scores ---
  int get highScore => _prefs?.getInt(_kHighScore) ?? 0;
  Future<void> setHighScore(int score) async {
    if (score > highScore) {
      await _prefs?.setInt(_kHighScore, score);
    }
  }

  int get liberatedSectors => _prefs?.getInt(_kLiberatedSectors) ?? 1;
  Future<void> setLiberatedSectors(int count) async {
    if (count > liberatedSectors) {
      await _prefs?.setInt(_kLiberatedSectors, count);
    }
  }

  bool get isProUnlocked => _prefs?.getBool(_kProUnlocked) ?? false;
  Future<void> setProUnlocked(bool unlocked) async {
    await _prefs?.setBool(_kProUnlocked, unlocked);
  }

  // --- Audio Preferences ---
  bool get isSoundEnabled => _prefs?.getBool(_kSoundEnabled) ?? true;
  Future<void> setSoundEnabled(bool enabled) async {
    await _prefs?.setBool(_kSoundEnabled, enabled);
  }

  double get sfxVolume => _prefs?.getDouble(_kSfxVolume) ?? 0.8;
  Future<void> setSfxVolume(double volume) async {
    await _prefs?.setDouble(_kSfxVolume, volume.clamp(0.0, 1.0));
  }

  double get bgmVolume => _prefs?.getDouble(_kBgmVolume) ?? 0.6;
  Future<void> setBgmVolume(double volume) async {
    await _prefs?.setDouble(_kBgmVolume, volume.clamp(0.0, 1.0));
  }

  bool get isSfxMuted => _prefs?.getBool(_kIsSfxMuted) ?? false;
  Future<void> setSfxMuted(bool muted) async {
    await _prefs?.setBool(_kIsSfxMuted, muted);
  }

  bool get isBgmMuted => _prefs?.getBool(_kIsBgmMuted) ?? false;
  Future<void> setBgmMuted(bool muted) async {
    await _prefs?.setBool(_kIsBgmMuted, muted);
  }

  bool get isHapticsEnabled => _prefs?.getBool(_kHapticsEnabled) ?? true;
  Future<void> setHapticsEnabled(bool enabled) async {
    await _prefs?.setBool(_kHapticsEnabled, enabled);
  }

  // --- Graphics Preferences ---
  bool get highShadersEnabled => _prefs?.getBool(_kHighShadersEnabled) ?? true;
  Future<void> setHighShadersEnabled(bool enabled) async {
    await _prefs?.setBool(_kHighShadersEnabled, enabled);
  }

  int get targetFps => _prefs?.getInt(_kTargetFps) ?? 60;
  Future<void> setTargetFps(int fps) async {
    await _prefs?.setInt(_kTargetFps, fps);
  }

  bool get lowBatteryMode => _prefs?.getBool(_kLowBatteryMode) ?? false;
  Future<void> setLowBatteryMode(bool enabled) async {
    await _prefs?.setBool(_kLowBatteryMode, enabled);
  }

  // --- Diagnostics & Privacy Preferences ---
  int get vlogLevel => _prefs?.getInt(_kVlogLevel) ?? 0;
  Future<void> setVlogLevel(int level) async {
    await _prefs?.setInt(_kVlogLevel, level);
  }

  bool get showFpsCounter => _prefs?.getBool(_kShowFpsCounter) ?? false;
  Future<void> setShowFpsCounter(bool show) async {
    await _prefs?.setBool(_kShowFpsCounter, show);
  }

  bool get crashReportingConsent =>
      _prefs?.getBool(_kCrashReportingConsent) ?? true;
  Future<void> setCrashReportingConsent(bool consent) async {
    await _prefs?.setBool(_kCrashReportingConsent, consent);
  }

  bool get personalizedAdsConsent =>
      _prefs?.getBool(_kPersonalizedAdsConsent) ?? false;
  Future<void> setPersonalizedAdsConsent(bool consent) async {
    await _prefs?.setBool(_kPersonalizedAdsConsent, consent);
  }

  // --- User Profile ---
  UserProfile get userProfile {
    final raw = _prefs?.getString(_kUserProfile);
    if (raw == null || raw.isEmpty) {
      return const UserProfile();
    }
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return UserProfile.fromJson(map);
    } catch (_) {
      return const UserProfile();
    }
  }

  Future<void> saveUserProfile(UserProfile profile) async {
    final raw = jsonEncode(profile.toJson());
    await _prefs?.setString(_kUserProfile, raw);
  }

  // --- Checksum & Save Data Mobility ---

  static int _computeChecksum(String data) {
    var hash = 5381;
    for (final codeUnit in data.codeUnits) {
      hash = ((hash << 5) + hash) + codeUnit;
      hash &= 0xFFFFFFFF;
    }
    return hash;
  }

  /// Exports current save data and user preferences as a base64 string with checksum.
  String exportSaveJson() {
    final payload = <String, dynamic>{
      'version': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'highScore': highScore,
      'liberatedSectors': liberatedSectors,
      'isProUnlocked': isProUnlocked,
      'sfxVolume': sfxVolume,
      'bgmVolume': bgmVolume,
      'isSfxMuted': isSfxMuted,
      'isBgmMuted': isBgmMuted,
      'isHapticsEnabled': isHapticsEnabled,
      'highShadersEnabled': highShadersEnabled,
      'targetFps': targetFps,
      'userProfile': userProfile.toJson(),
    };

    final jsonString = jsonEncode(payload);
    final checksum = _computeChecksum(jsonString);

    final container = <String, dynamic>{
      'schema': 'void_sower_save_v1',
      'checksum': checksum,
      'data': jsonString,
    };

    return base64Encode(utf8.encode(jsonEncode(container)));
  }

  /// Validates and imports save data from a base64 encoded string.
  /// Returns true on successful restore, false on invalid or corrupted payload.
  Future<bool> importSaveJson(String rawBase64) async {
    try {
      final decodedJson = utf8.decode(base64Decode(rawBase64.trim()));
      final container = jsonDecode(decodedJson) as Map<String, dynamic>;

      if (container['schema'] != 'void_sower_save_v1') return false;

      final dataString = container['data'] as String;
      final expectedChecksum = container['checksum'] as int;
      final actualChecksum = _computeChecksum(dataString);

      if (actualChecksum != expectedChecksum) return false;

      final payload = jsonDecode(dataString) as Map<String, dynamic>;

      if (payload['highScore'] is int) {
        await _prefs?.setInt(_kHighScore, payload['highScore'] as int);
      }
      if (payload['liberatedSectors'] is int) {
        await _prefs?.setInt(
          _kLiberatedSectors,
          payload['liberatedSectors'] as int,
        );
      }
      if (payload['isProUnlocked'] is bool) {
        await _prefs?.setBool(_kProUnlocked, payload['isProUnlocked'] as bool);
      }
      if (payload['sfxVolume'] is num) {
        await _prefs?.setDouble(
          _kSfxVolume,
          (payload['sfxVolume'] as num).toDouble(),
        );
      }
      if (payload['bgmVolume'] is num) {
        await _prefs?.setDouble(
          _kBgmVolume,
          (payload['bgmVolume'] as num).toDouble(),
        );
      }
      if (payload['isSfxMuted'] is bool) {
        await _prefs?.setBool(_kIsSfxMuted, payload['isSfxMuted'] as bool);
      }
      if (payload['isBgmMuted'] is bool) {
        await _prefs?.setBool(_kIsBgmMuted, payload['isBgmMuted'] as bool);
      }
      if (payload['isHapticsEnabled'] is bool) {
        await _prefs?.setBool(
          _kHapticsEnabled,
          payload['isHapticsEnabled'] as bool,
        );
      }
      if (payload['highShadersEnabled'] is bool) {
        await _prefs?.setBool(
          _kHighShadersEnabled,
          payload['highShadersEnabled'] as bool,
        );
      }
      if (payload['targetFps'] is int) {
        await _prefs?.setInt(_kTargetFps, payload['targetFps'] as int);
      }
      if (payload['userProfile'] is Map<String, dynamic>) {
        final profile = UserProfile.fromJson(
          payload['userProfile'] as Map<String, dynamic>,
        );
        await saveUserProfile(profile);
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  /// GDPR / CCPA right-to-be-forgotten wipe.
  Future<void> wipeAllData() async {
    await _prefs?.clear();
  }
}
