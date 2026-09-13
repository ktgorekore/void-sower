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

import 'package:shared_preferences/shared_preferences.dart';

/// Persistence service managing local guest progress and player settings.
class PersistenceService {
  PersistenceService._();
  static final PersistenceService instance = PersistenceService._();

  SharedPreferences? _prefs;

  Future<void> initialize() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  static const String _kHighScore = 'void_sower_high_score';
  static const String _kLiberatedSectors = 'void_sower_liberated_sectors';
  static const String _kProUnlocked = 'void_sower_pro_unlocked';
  static const String _kSoundEnabled = 'void_sower_sound_enabled';
  static const String _kHapticsEnabled = 'void_sower_haptics_enabled';

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

  bool get isSoundEnabled => _prefs?.getBool(_kSoundEnabled) ?? true;
  Future<void> setSoundEnabled(bool enabled) async {
    await _prefs?.setBool(_kSoundEnabled, enabled);
  }

  bool get isHapticsEnabled => _prefs?.getBool(_kHapticsEnabled) ?? true;
  Future<void> setHapticsEnabled(bool enabled) async {
    await _prefs?.setBool(_kHapticsEnabled, enabled);
  }

  /// GDPR / CCPA right-to-be-forgotten wipe.
  Future<void> wipeAllData() async {
    await _prefs?.clear();
  }
}
