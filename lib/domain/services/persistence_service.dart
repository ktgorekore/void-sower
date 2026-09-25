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
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_profile.dart';

/// Persistence service managing local guest progress, player settings, and save export/import.
class PersistenceService {
  PersistenceService._();
  static final PersistenceService instance = PersistenceService._();

  SharedPreferences? _prefs;

  /// Initializes SharedPreferences instance with resilience against storage locks.
  Future<void> initialize({
    Duration timeoutDuration = const Duration(seconds: 2),
  }) async {
    try {
      _prefs ??= await SharedPreferences.getInstance().timeout(
        timeoutDuration,
        onTimeout: () {
          debugPrint('[PersistenceService] SharedPreferences init timed out');
          throw TimeoutException('SharedPreferences init timed out');
        },
      );
    } catch (e) {
      debugPrint('[PersistenceService] SharedPreferences init error: $e');
    }
  }

  /// Resets and clears preferences for unit tests.
  @visibleForTesting
  Future<void> resetForTesting() async {
    _prefs = await SharedPreferences.getInstance();
    await _prefs?.clear();
  }

  static const String _kHighScore = 'void_sower_high_score';
  static const String _kLiberatedSectors = 'void_sower_liberated_sectors';
  static const String _kProUnlocked = 'void_sower_pro_unlocked';
  static const String _kAdsDisabled = 'void_sower_ads_disabled';
  static const String _kSoundEnabled = 'void_sower_sound_enabled';
  static const String _kMusicEnabled = 'void_sower_music_enabled';
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

  static const String _kCompletedTutorial = 'void_sower_completed_tutorial';
  static const String _kUserProfile = 'void_sower_user_profile';

  // --- Campaign & Scores ---
  bool get hasCompletedTutorial =>
      _prefs?.getBool(_kCompletedTutorial) ?? false;
  Future<void> setCompletedTutorial(bool completed) async {
    await _prefs?.setBool(_kCompletedTutorial, completed);
  }

  int get highScore {
    try {
      final val = _prefs?.get(_kHighScore);
      if (val is int) return val;
      if (val is String) return int.tryParse(val) ?? 0;
    } catch (_) {}
    return 0;
  }

  Future<void> setHighScore(int score) async {
    if (score > highScore) {
      await _prefs?.setInt(_kHighScore, score);
    }
  }

  int get liberatedSectors {
    try {
      final val = _prefs?.get(_kLiberatedSectors);
      if (val is int) return val;
      if (val is String) return int.tryParse(val) ?? 1;
    } catch (_) {}
    return 1;
  }

  Future<void> setLiberatedSectors(int count) async {
    if (count > liberatedSectors) {
      await _prefs?.setInt(_kLiberatedSectors, count);
    }
  }

  static const String _kActiveCampaignId = 'void_sower_active_campaign_id';
  static const String _kCampaignLiberatedPrefix =
      'void_sower_campaign_liberated_';

  /// Currently selected campaign operation ('kilwa_basin', 'phantom_drift', 'void_swarm').
  String get activeCampaignId {
    final saved = _prefs?.getString(_kActiveCampaignId);
    if (saved != null && saved.isNotEmpty) {
      if (!isProUnlocked && saved != 'kilwa_basin') {
        return 'kilwa_basin';
      }
      return saved;
    }
    return 'kilwa_basin';
  }

  Future<void> setActiveCampaignId(String campaignId) async {
    await _prefs?.setString(_kActiveCampaignId, campaignId);
  }

  /// Retrieves number of liberated sectors for a specific campaign operation.
  int getLiberatedSectorsForCampaign(String campaignId) {
    if (campaignId == 'kilwa_basin') return liberatedSectors;
    try {
      final val = _prefs?.get('$_kCampaignLiberatedPrefix$campaignId');
      if (val is int) return val;
      if (val is String) return int.tryParse(val) ?? 1;
    } catch (_) {}
    return 1;
  }

  /// Sets number of liberated sectors for a specific campaign operation.
  Future<void> setLiberatedSectorsForCampaign(
    String campaignId,
    int count,
  ) async {
    if (campaignId == 'kilwa_basin') {
      await setLiberatedSectors(count);
      return;
    }
    final current = getLiberatedSectorsForCampaign(campaignId);
    if (count > current) {
      await _prefs?.setInt('$_kCampaignLiberatedPrefix$campaignId', count);
    }
  }

  static const String _kSectorStarsPrefix = 'void_sower_sector_stars_';
  static const String _kSectorScorePrefix = 'void_sower_sector_score_';

  /// Retrieves stars earned (0 to 3) for a specific campaign sector.
  int getSectorStars(int sectorId) {
    try {
      final val = _prefs?.get('$_kSectorStarsPrefix$sectorId');
      if (val is int) return val;
      if (val is String) {
        return int.tryParse(val) ?? (liberatedSectors > sectorId ? 3 : 0);
      }
    } catch (_) {}
    return (liberatedSectors > sectorId ? 3 : 0);
  }

  /// Retrieves personal high score achieved in a specific campaign sector.
  int getSectorScore(int sectorId) {
    try {
      final val = _prefs?.get('$_kSectorScorePrefix$sectorId');
      if (val is int) return val;
      if (val is String) return int.tryParse(val) ?? 0;
    } catch (_) {}
    return 0;
  }

  static const String _kSelectedChassisId = 'void_sower_selected_chassis_id';

  /// Currently equipped dreadnought chassis ID ('mk1_bastion', 'mk2_monsoon', 'mk3_singularity', 'mk4_golden_sovereign').
  String get selectedChassisId =>
      _prefs?.getString(_kSelectedChassisId) ?? 'mk1_bastion';

  /// Updates equipped dreadnought chassis ID.
  Future<void> setSelectedChassisId(String id) async {
    await _prefs?.setString(_kSelectedChassisId, id);
  }

  static String _formatTodayDate([DateTime? now]) {
    final dt = now ?? DateTime.now();
    return '${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  static bool _isYesterday(String lastDateStr, String todayStr) {
    try {
      final lastParts = lastDateStr.split('-').map(int.parse).toList();
      final todayParts = todayStr.split('-').map(int.parse).toList();
      final lastDt = DateTime(lastParts[0], lastParts[1], lastParts[2]);
      final todayDt = DateTime(todayParts[0], todayParts[1], todayParts[2]);
      return todayDt.difference(lastDt).inDays == 1;
    } catch (_) {
      return false;
    }
  }

  static int _calculateUpdatedStreak(
    String? lastPlayedDate,
    int currentStreak,
    String today,
  ) {
    if (lastPlayedDate == null) return 1;
    if (lastPlayedDate == today) {
      return currentStreak == 0 ? 1 : currentStreak;
    }
    if (_isYesterday(lastPlayedDate, today)) {
      return (currentStreak <= 0 ? 1 : currentStreak) + 1;
    }
    return 1;
  }

  /// Records a successful sector defense, awards stars and score, unlocks the next sector,
  /// and updates pilot profile statistics and combat telemetry.
  Future<void> recordSectorVictory({
    required int sectorId,
    required int score,
    required int coresRemaining,
    int enemiesNeutralized = 4,
    int lancesFired = 0,
    int flakBursts = 0,
    int seedsSown = 0,
    int maxCascadeLaps = 0,
    int flightTimeSeconds = 0,
    String chassisId = 'mk1_bastion',
    String campaignId = 'kilwa_basin',
  }) async {
    final earnedStars = coresRemaining >= 16
        ? 3
        : (coresRemaining >= 8 ? 2 : 1);
    final previousStars = getSectorStars(sectorId);
    if (earnedStars > previousStars) {
      await _prefs?.setInt('$_kSectorStarsPrefix$sectorId', earnedStars);
    }

    final previousScore = getSectorScore(sectorId);
    if (score > previousScore) {
      await _prefs?.setInt('$_kSectorScorePrefix$sectorId', score);
    }

    // Advance campaign frontier if this was the current vanguard sector
    if (sectorId <= 9) {
      if (sectorId >= liberatedSectors && sectorId < 9) {
        await setLiberatedSectors(sectorId + 1);
      } else if (sectorId == 9) {
        await setLiberatedSectors(10);
      }
    } else if (sectorId <= 18) {
      final rel = sectorId - 9; // 1..9
      final cur = getLiberatedSectorsForCampaign('phantom_drift');
      if (rel >= cur && rel < 9) {
        await setLiberatedSectorsForCampaign('phantom_drift', rel + 1);
      } else if (rel == 9) {
        await setLiberatedSectorsForCampaign('phantom_drift', 10);
      }
    } else if (sectorId <= 27) {
      final rel = sectorId - 18; // 1..9
      final cur = getLiberatedSectorsForCampaign('void_swarm');
      if (rel >= cur && rel < 9) {
        await setLiberatedSectorsForCampaign('void_swarm', rel + 1);
      } else if (rel == 9) {
        await setLiberatedSectorsForCampaign('void_swarm', 10);
      }
    }

    // Update global high score
    await setHighScore(score);

    // Update active pilot profile statistics
    final active = userProfile;
    final isFlawless = coresRemaining >= 16;
    final today = _formatTodayDate();
    final newStreak = _calculateUpdatedStreak(
      active.lastPlayedDate,
      active.currentStreak,
      today,
    );
    final longestStreak = math.max(active.longestStreak, newStreak);

    final updatedChassisSorties = Map<String, int>.from(active.chassisSorties);
    updatedChassisSorties[chassisId] =
        (updatedChassisSorties[chassisId] ?? 0) + 1;

    final updatedCampaignSorties = Map<String, int>.from(
      active.campaignSorties,
    );
    updatedCampaignSorties[campaignId] =
        (updatedCampaignSorties[campaignId] ?? 0) + 1;

    final updatedProfile = active.copyWith(
      lifetimeScore: active.lifetimeScore + score,
      enemiesDestroyed: active.enemiesDestroyed + enemiesNeutralized,
      missionsPlayed: active.missionsPlayed + 1,
      victories: active.victories + 1,
      flawlessVictories: isFlawless
          ? (active.flawlessVictories + 1)
          : active.flawlessVictories,
      totalCoresSaved: active.totalCoresSaved + coresRemaining,
      lancesFired: active.lancesFired + lancesFired,
      flakBurstsTriggered: active.flakBurstsTriggered + flakBursts,
      totalSeedsSown: active.totalSeedsSown + seedsSown,
      maxCascadeLaps: math.max(active.maxCascadeLaps, maxCascadeLaps),
      totalFlightTimeSeconds: active.totalFlightTimeSeconds + flightTimeSeconds,
      currentStreak: newStreak,
      longestStreak: longestStreak,
      lastPlayedDate: today,
      chassisSorties: updatedChassisSorties,
      campaignSorties: updatedCampaignSorties,
    );
    await saveUserProfile(updatedProfile);
  }

  /// Records a mission defeat (reactor breach or cores depleted), updates streaks,
  /// flight time, and sorties telemetry in the pilot profile.
  Future<void> recordSectorDefeat({
    required int sectorId,
    required int score,
    int lancesFired = 0,
    int flakBursts = 0,
    int seedsSown = 0,
    int maxCascadeLaps = 0,
    int flightTimeSeconds = 0,
    String chassisId = 'mk1_bastion',
    String campaignId = 'kilwa_basin',
  }) async {
    final previousScore = getSectorScore(sectorId);
    if (score > previousScore) {
      await _prefs?.setInt('$_kSectorScorePrefix$sectorId', score);
    }

    // Update global high score
    await setHighScore(score);

    // Update active pilot profile statistics
    final active = userProfile;
    final today = _formatTodayDate();
    final newStreak = _calculateUpdatedStreak(
      active.lastPlayedDate,
      active.currentStreak,
      today,
    );
    final longestStreak = math.max(active.longestStreak, newStreak);

    final updatedChassisSorties = Map<String, int>.from(active.chassisSorties);
    updatedChassisSorties[chassisId] =
        (updatedChassisSorties[chassisId] ?? 0) + 1;

    final updatedCampaignSorties = Map<String, int>.from(
      active.campaignSorties,
    );
    updatedCampaignSorties[campaignId] =
        (updatedCampaignSorties[campaignId] ?? 0) + 1;

    final updatedProfile = active.copyWith(
      lifetimeScore: active.lifetimeScore + score,
      missionsPlayed: active.missionsPlayed + 1,
      defeats: active.defeats + 1,
      lancesFired: active.lancesFired + lancesFired,
      flakBurstsTriggered: active.flakBurstsTriggered + flakBursts,
      totalSeedsSown: active.totalSeedsSown + seedsSown,
      maxCascadeLaps: math.max(active.maxCascadeLaps, maxCascadeLaps),
      totalFlightTimeSeconds: active.totalFlightTimeSeconds + flightTimeSeconds,
      currentStreak: newStreak,
      longestStreak: longestStreak,
      lastPlayedDate: today,
      chassisSorties: updatedChassisSorties,
      campaignSorties: updatedCampaignSorties,
    );
    await saveUserProfile(updatedProfile);
  }

  bool get isProUnlocked => _prefs?.getBool(_kProUnlocked) ?? false;
  Future<void> setProUnlocked(bool unlocked) async {
    await _prefs?.setBool(_kProUnlocked, unlocked);
  }

  bool get areAdsDisabled => _prefs?.getBool(_kAdsDisabled) ?? false;
  Future<void> setAdsDisabled(bool disabled) async {
    await _prefs?.setBool(_kAdsDisabled, disabled);
  }

  // --- Audio Preferences ---
  bool get isSoundEnabled => _prefs?.getBool(_kSoundEnabled) ?? true;
  Future<void> setSoundEnabled(bool enabled) async {
    await _prefs?.setBool(_kSoundEnabled, enabled);
  }

  bool get isMusicEnabled => _prefs?.getBool(_kMusicEnabled) ?? true;
  Future<void> setMusicEnabled(bool enabled) async {
    await _prefs?.setBool(_kMusicEnabled, enabled);
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

  static const String _kActiveProfileId = 'void_sower_active_profile_id';
  static const String _kProfilesList = 'void_sower_profiles_list';

  // --- User Profiles & Pilot Identity ---

  /// List of all registered local pilot profiles.
  List<UserProfile> get profiles {
    final rawList = _prefs?.getStringList(_kProfilesList);
    if (rawList != null && rawList.isNotEmpty) {
      final list = <UserProfile>[];
      for (final raw in rawList) {
        try {
          final map = jsonDecode(raw) as Map<String, dynamic>;
          list.add(UserProfile.fromJson(map));
        } catch (_) {}
      }
      if (list.isNotEmpty) return list;
    }

    // Fallback to legacy single profile key
    final legacyRaw = _prefs?.getString(_kUserProfile);
    if (legacyRaw != null && legacyRaw.isNotEmpty) {
      try {
        final map = jsonDecode(legacyRaw) as Map<String, dynamic>;
        final profile = UserProfile.fromJson(map);
        return [profile];
      } catch (_) {}
    }

    return const [UserProfile(id: 'pilot_default', callsign: 'Vanguard-01')];
  }

  /// ID of the currently active pilot profile.
  String get activeProfileId {
    final activeId = _prefs?.getString(_kActiveProfileId);
    if (activeId != null && activeId.isNotEmpty) {
      return activeId;
    }
    return profiles.first.id;
  }

  /// Active pilot user profile.
  UserProfile get userProfile {
    final currentList = profiles;
    final activeId = activeProfileId;
    for (final p in currentList) {
      if (p.id == activeId) return p;
    }
    return currentList.first;
  }

  /// Saves or updates a pilot profile and marks it active.
  Future<void> saveUserProfile(UserProfile profile) async {
    final currentList = List<UserProfile>.from(profiles);
    final index = currentList.indexWhere((p) => p.id == profile.id);
    if (index >= 0) {
      currentList[index] = profile;
    } else {
      currentList.add(profile);
    }

    final rawList = currentList.map((p) => jsonEncode(p.toJson())).toList();
    await _prefs?.setStringList(_kProfilesList, rawList);
    await _prefs?.setString(_kActiveProfileId, profile.id);
    await _prefs?.setString(_kUserProfile, jsonEncode(profile.toJson()));
  }

  /// Creates a new pilot profile with a unique callsign.
  Future<bool> createProfile(
    String callsign, {
    PilotInsignia insignia = PilotInsignia.kilwaCrest,
  }) async {
    final clean = callsign.trim();
    if (clean.isEmpty) return false;

    final currentList = profiles;
    if (currentList.any(
      (p) => p.callsign.toLowerCase() == clean.toLowerCase(),
    )) {
      return false;
    }

    final newProfile = UserProfile(
      id: 'pilot_${DateTime.now().millisecondsSinceEpoch}',
      callsign: clean,
      insignia: insignia,
    );

    await saveUserProfile(newProfile);
    return true;
  }

  /// Switches active user identity to the given profile ID.
  Future<void> switchProfile(String profileId) async {
    final currentList = profiles;
    final match = currentList.firstWhere(
      (p) => p.id == profileId,
      orElse: () => currentList.first,
    );
    await _prefs?.setString(_kActiveProfileId, match.id);
    await _prefs?.setString(_kUserProfile, jsonEncode(match.toJson()));
  }

  /// Deletes a pilot profile if more than one profile exists.
  Future<bool> deleteProfile(String profileId) async {
    final currentList = List<UserProfile>.from(profiles);
    if (currentList.length <= 1) return false;

    currentList.removeWhere((p) => p.id == profileId);
    final rawList = currentList.map((p) => jsonEncode(p.toJson())).toList();
    await _prefs?.setStringList(_kProfilesList, rawList);

    if (activeProfileId == profileId) {
      await switchProfile(currentList.first.id);
    }
    return true;
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
      'isSoundEnabled': isSoundEnabled,
      'isMusicEnabled': isMusicEnabled,
      'sfxVolume': sfxVolume,
      'bgmVolume': bgmVolume,
      'isSfxMuted': isSfxMuted,
      'isBgmMuted': isBgmMuted,
      'isHapticsEnabled': isHapticsEnabled,
      'highShadersEnabled': highShadersEnabled,
      'targetFps': targetFps,
      'selectedChassisId': selectedChassisId,
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
      if (payload['isSoundEnabled'] is bool) {
        await _prefs?.setBool(
          _kSoundEnabled,
          payload['isSoundEnabled'] as bool,
        );
      }
      if (payload['isMusicEnabled'] is bool) {
        await _prefs?.setBool(
          _kMusicEnabled,
          payload['isMusicEnabled'] as bool,
        );
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
      if (payload['selectedChassisId'] is String) {
        await setSelectedChassisId(payload['selectedChassisId'] as String);
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
