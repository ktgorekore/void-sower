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

import 'sector_combat_doctrine.dart';
import 'sector_progression_status.dart';

/// Sector node on the orbital campaign star map.
class CampaignSector {
  const CampaignSector({
    required this.sectorId,
    required this.name,
    required this.region,
    required this.difficultyTier,
    required this.starsEarned,
    this.status = SectorProgressionStatus.accessible,
    bool? isUnlocked,
    bool isLiberated = false,
    required this.bestScore,
    this.requiredSectorId,
    this.requiredSectorName,
    this.campaignId = 'kilwa_basin',
    this.doctrine = SectorCombatDoctrine.standardOrbital,
    this.reinforcementQuota = 0,
    this.coreSiphonPerKill = 1,
    this.isProRequired = false,
  }) : _explicitUnlocked = isUnlocked,
       _explicitLiberated = isLiberated;

  /// 1-based index of the sector across all campaign theaters (1..27).
  final int sectorId;

  /// Lore designation of the orbital sector.
  final String name;

  /// Campaign region ('Outer Bastions', 'Monsoon Straits', 'Core Siphon', etc.).
  final String region;

  /// Threat tier (0 = Patrol, 1 = Monsoon, 2 = Singularity).
  final int difficultyTier;

  /// Stars earned in this sector (0 to 3).
  final int starsEarned;

  /// Progression and security status of this sector.
  final SectorProgressionStatus status;

  final bool? _explicitUnlocked;
  final bool _explicitLiberated;

  /// Whether this sector is unlocked and accessible to the commander.
  bool get isUnlocked {
    if (_explicitUnlocked != null) return _explicitUnlocked;
    return status != SectorProgressionStatus.locked;
  }

  /// Whether this sector has been liberated (hostiles defeated at least once).
  bool get isLiberated {
    if (_explicitLiberated) return true;
    return status == SectorProgressionStatus.liberated || starsEarned > 0;
  }

  /// High score achieved in this sector.
  final int bestScore;

  /// 1-based sector ID required to unlock this sector (if locked).
  final int? requiredSectorId;

  /// Designation of the required sector (if locked).
  final String? requiredSectorName;

  /// Machine identifier of the campaign operation containing this sector.
  final String campaignId;

  /// Combat rules doctrine governing this sector.
  final SectorCombatDoctrine doctrine;

  /// For Void Swarm: total replacement invaders queued to drop during combat.
  final int reinforcementQuota;

  /// For Void Swarm: baseline cores siphoned back on enemy destruction.
  final int coreSiphonPerKill;

  /// Whether this sector strictly requires Pro Commander clearance to deploy.
  final bool isProRequired;

  /// Human-readable unlock requirement text.
  String get unlockRequirement {
    if (isUnlocked) return 'Sector secured for orbital transit.';
    if (isProRequired) {
      final theater = campaignId == 'phantom_drift'
          ? 'Phantom Drift'
          : campaignId == 'void_swarm'
          ? 'Void Swarm'
          : 'advanced';
      return 'Unlock Pro Commander clearance to deploy to $theater sectors.';
    }
    if (requiredSectorName != null && requiredSectorId != null) {
      return 'Liberate Sector $requiredSectorId: $requiredSectorName to break imperial blockade.';
    }
    return 'Liberate the preceding sector or unlock Pro Commander clearance.';
  }
}
