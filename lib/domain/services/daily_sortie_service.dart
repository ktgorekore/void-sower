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

import '../models/campaign_sector.dart';
import '../models/sector_combat_doctrine.dart';
import 'persistence_service.dart';

/// Service managing deterministic Daily Galactic Sorties.
///
/// Uses UTC dates to generate an identical 24-hour global combat challenge
/// with procedural mutators, global scoring benchmarks, and daily progression.
class DailySortieService {
  DailySortieService._();
  static final DailySortieService instance = DailySortieService._();

  /// Current UTC timestamp.
  DateTime get currentUtcDate => DateTime.now().toUtc();

  /// Date key in YYYY-MM-DD format.
  String get todayDateKey {
    final d = currentUtcDate;
    final month = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '${d.year}-$month-$day';
  }

  /// 32-bit deterministic integer seed for today's sortie.
  int get todaySeed {
    final d = currentUtcDate;
    return (d.year * 10000) + (d.month * 100) + d.day;
  }

  /// Active tactical doctrine for today's sortie.
  SectorCombatDoctrine get todayDoctrine {
    final doctrines = SectorCombatDoctrine.values;
    return doctrines[todaySeed % doctrines.length];
  }

  /// Threat tier for today's sortie (0: Patrol, 1: Monsoon, 2: Singularity).
  int get todayDifficultyTier => todaySeed % 3;

  /// High score recorded for today's sortie.
  int get todayBestScore =>
      PersistenceService.instance.getDailyHighScore(todayDateKey);

  /// Human-readable descriptor of today's special atmospheric condition.
  String get todayModifierTitle {
    switch (todayDoctrine) {
      case SectorCombatDoctrine.phantomDrift:
        return 'LATERAL PHASE DISTORTION';
      case SectorCombatDoctrine.voidSwarm:
        return 'HORDE CRUCIBLE & CORE SIPHON';
      case SectorCombatDoctrine.standardOrbital:
      default:
        return 'SINGULARITY ION STREAM';
    }
  }

  /// Tactical gameplay briefing for today's modifiers.
  String get todayModifierDescription {
    switch (todayDoctrine) {
      case SectorCombatDoctrine.phantomDrift:
        return 'Hostiles execute continuous lateral thruster maneuvers. Axial lances must be timed during directional transitions.';
      case SectorCombatDoctrine.voidSwarm:
        return 'Continuous reinforcement hordes drop from deep space. Neutralizing invaders harvests +2 auxiliary cores directly into the reactor.';
      case SectorCombatDoctrine.standardOrbital:
      default:
        return 'Standard attack corridors. High-energy quadratic particle lances inflict maximum devastation.';
    }
  }

  /// Generates the official [CampaignSector] for today's daily sortie.
  CampaignSector getTodaySector() {
    final seed = todaySeed;
    final quota = 24 + (seed % 20);
    final siphon = 1 + (seed % 3);

    return CampaignSector(
      sectorId: 8888,
      name: 'DAILY SORTIE: $todayDateKey',
      region: 'Galactic Horizon • ${todayModifierTitle.toUpperCase()}',
      difficultyTier: todayDifficultyTier,
      starsEarned: 0,
      bestScore: todayBestScore,
      isUnlocked: true,
      campaignId: 'daily_sortie',
      doctrine: todayDoctrine,
      reinforcementQuota: quota,
      coreSiphonPerKill: siphon,
    );
  }

  /// Records player's score for today's sortie.
  Future<void> recordTodayScore(int score) async {
    await PersistenceService.instance.setDailyHighScore(todayDateKey, score);
  }
}
