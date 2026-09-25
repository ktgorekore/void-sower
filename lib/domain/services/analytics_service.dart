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

import 'package:flutter/foundation.dart';

/// Telemetry logging service for combat milestones and session events.
class AnalyticsService {
  AnalyticsService._();

  /// Singleton access instance.
  static final AnalyticsService instance = AnalyticsService._();

  /// Logs a custom analytical telemetry event with optional key-value [parameters].
  void logEvent(String name, [Map<String, dynamic>? parameters]) {
    debugPrint('[Analytics] $name: $parameters');
  }

  /// Records combat sortie initiation for [sectorId] at the specified difficulty [tier].
  void logCombatStart(int sectorId, int tier) {
    logEvent('combat_start', {'sector_id': sectorId, 'tier': tier});
  }

  /// Records mission victory for [sectorId] with final [score] and [remainingCores].
  void logCombatVictory(int sectorId, int score, int remainingCores) {
    logEvent('combat_victory', {
      'sector_id': sectorId,
      'score': score,
      'remaining_cores': remainingCores,
    });
  }

  /// Records mission defeat for [sectorId] with achieved [score].
  void logCombatDefeat(int sectorId, int score) {
    logEvent('combat_defeat', {'sector_id': sectorId, 'score': score});
  }
}
