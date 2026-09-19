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

import '../models/campaign_operation.dart';
import '../models/campaign_sector.dart';
import '../models/pro_feature.dart';
import '../models/sector_combat_doctrine.dart';
import '../models/sector_progression_status.dart';
import 'entitlement_service.dart';
import 'persistence_service.dart';

/// Service managing progressive star sectors across all orbital operations.
class CampaignService {
  CampaignService._();
  static final CampaignService instance = CampaignService._();

  /// Retrieves a specific sector by its 1-based sector ID across all theaters (1..27).
  CampaignSector getSector(int sectorId) {
    final allSectors = getAllSectors();
    return allSectors.firstWhere(
      (s) => s.sectorId == sectorId,
      orElse: () => allSectors.first,
    );
  }

  /// Returns sectors for the currently active campaign operation.
  List<CampaignSector> getSectors([String? campaignId]) {
    final targetId = campaignId ?? PersistenceService.instance.activeCampaignId;
    return getSectorsForCampaign(targetId);
  }

  /// Returns all 27 sectors across all 3 campaign theaters.
  List<CampaignSector> getAllSectors() {
    return [
      ...getSectorsForCampaign('kilwa_basin'),
      ...getSectorsForCampaign('phantom_drift'),
      ...getSectorsForCampaign('void_swarm'),
    ];
  }

  /// Returns all available campaign operations.
  List<CampaignOperation> getOperations() {
    return [
      getOperation('kilwa_basin'),
      getOperation('phantom_drift'),
      getOperation('void_swarm'),
    ];
  }

  /// Retrieves a specific campaign operation by its identifier.
  CampaignOperation getOperation(String operationId) {
    switch (operationId) {
      case 'phantom_drift':
        return CampaignOperation(
          id: 'phantom_drift',
          title: 'PHANTOM DRIFT',
          subtitle: 'Lateral Evasive Corridors',
          tacticalBriefing:
              'Hostile carrier wings employ lateral thrusters and phase-displacement fields. '
              'Invaders dynamically oscillate between firing corridors to evade axial quadratic lances.',
          isProRequired: true,
          defaultDoctrine: SectorCombatDoctrine.phantomDrift,
          baseSectorId: 10,
          sectors: getSectorsForCampaign('phantom_drift'),
        );
      case 'void_swarm':
        return CampaignOperation(
          id: 'void_swarm',
          title: 'VOID SWARM',
          subtitle: 'Horde Crucible & Core Siphon',
          tacticalBriefing:
              'Dense multi-wave reinforcement hordes drop continuously from high orbit. '
              'Neutralizing hostiles activates Tactical Core Siphon (+1 to +3 cores) directly to the dreadnought reactor.',
          isProRequired: true,
          defaultDoctrine: SectorCombatDoctrine.voidSwarm,
          baseSectorId: 19,
          sectors: getSectorsForCampaign('void_swarm'),
        );
      case 'kilwa_basin':
      default:
        return CampaignOperation(
          id: 'kilwa_basin',
          title: 'KILWA NEBULA BASIN',
          subtitle: 'Outer Bastions & Singularity Core',
          tacticalBriefing:
              'Standard imperial attack corridors. Master the ancient count-and-capture plasma dispersal '
              'to break the blockade around Kilwa Kisiwani and neutralize the Singularity Core.',
          isProRequired: false,
          defaultDoctrine: SectorCombatDoctrine.standardOrbital,
          baseSectorId: 1,
          sectors: getSectorsForCampaign('kilwa_basin'),
        );
    }
  }

  /// Returns the 9 sectors of a specific campaign operation with dynamic unlock and liberation state.
  List<CampaignSector> getSectorsForCampaign(String campaignId) {
    final persistence = PersistenceService.instance;
    final isPro = EntitlementService.instance.isProUnlocked;
    final hasPass = EntitlementService.instance.isFeatureAccessible(
      ProFeature.proCampaignTheaters,
    );
    final isOperationUnlocked = campaignId == 'kilwa_basin' || isPro || hasPass;
    final liberatedInCampaign = persistence.getLiberatedSectorsForCampaign(
      campaignId,
    );

    if (campaignId == 'phantom_drift') {
      return _buildPhantomDriftSectors(
        isOperationUnlocked: isOperationUnlocked,
        isPro: isPro,
        liberated: liberatedInCampaign,
        persistence: persistence,
      );
    } else if (campaignId == 'void_swarm') {
      return _buildVoidSwarmSectors(
        isOperationUnlocked: isOperationUnlocked,
        isPro: isPro,
        liberated: liberatedInCampaign,
        persistence: persistence,
      );
    }

    return _buildKilwaBasinSectors(
      isPro: isPro,
      liberated: persistence.liberatedSectors,
      persistence: persistence,
    );
  }

  SectorProgressionStatus _evaluateStatus({
    required bool isOperationUnlocked,
    required bool isPro,
    required bool isFirstInOperation,
    required bool isLiberated,
    required bool isPrerequisiteMet,
  }) {
    if (!isOperationUnlocked) return SectorProgressionStatus.locked;
    if (isLiberated) return SectorProgressionStatus.liberated;
    // With Pro, all sectors start unlocked!
    if (isPro) return SectorProgressionStatus.accessible;
    if (isFirstInOperation || isPrerequisiteMet) {
      return SectorProgressionStatus.accessible;
    }
    return SectorProgressionStatus.locked;
  }

  List<CampaignSector> _buildKilwaBasinSectors({
    required bool isPro,
    required int liberated,
    required PersistenceService persistence,
  }) {
    final sectorsData = [
      (1, 'Zanzibar Reef Gate', 'Outer Bastions', 0, 1200, null, null),
      (
        2,
        'Pemba Channel Relay',
        'Outer Bastions',
        0,
        1650,
        1,
        'Zanzibar Reef Gate',
      ),
      (
        3,
        'Mafia Trench Fortress',
        'Outer Bastions',
        0,
        2100,
        2,
        'Pemba Channel Relay',
      ),
      (
        4,
        'Kaskazi Ion Stream',
        'Monsoon Straits',
        1,
        3400,
        3,
        'Mafia Trench Fortress',
      ),
      (
        5,
        'Kusi Vortex Outpost',
        'Monsoon Straits',
        1,
        4100,
        4,
        'Kaskazi Ion Stream',
      ),
      (
        6,
        'Lindi Ridge Bastion',
        'Monsoon Straits',
        1,
        5300,
        5,
        'Kusi Vortex Outpost',
      ),
      (
        7,
        'Kilwa Kisiwani Citadel',
        'Core Siphon',
        2,
        7800,
        6,
        'Lindi Ridge Bastion',
      ),
      (
        8,
        'Songo Mnara Flagship Berth',
        'Core Siphon',
        2,
        9200,
        7,
        'Kilwa Kisiwani Citadel',
      ),
      (
        9,
        'Great Siphon Singularity',
        'Core Siphon',
        2,
        12500,
        8,
        'Songo Mnara Flagship Berth',
      ),
    ];

    return sectorsData.map((data) {
      final id = data.$1;
      final name = data.$2;
      final region = data.$3;
      final tier = data.$4;
      final defaultScore = data.$5;
      final reqId = data.$6;
      final reqName = data.$7;

      final stars = persistence.getSectorStars(id);
      final score = persistence.getSectorScore(id);
      final isLib = liberated > id || stars > 0;
      final isPrereq = liberated >= id;

      final status = _evaluateStatus(
        isOperationUnlocked: true,
        isPro: isPro,
        isFirstInOperation: id == 1,
        isLiberated: isLib,
        isPrerequisiteMet: isPrereq,
      );

      return CampaignSector(
        sectorId: id,
        name: name,
        region: region,
        difficultyTier: tier,
        starsEarned: stars,
        status: status,
        bestScore: score > 0 ? score : defaultScore,
        requiredSectorId: reqId,
        requiredSectorName: reqName,
        campaignId: 'kilwa_basin',
        doctrine: SectorCombatDoctrine.standardOrbital,
      );
    }).toList();
  }

  List<CampaignSector> _buildPhantomDriftSectors({
    required bool isOperationUnlocked,
    required bool isPro,
    required int liberated,
    required PersistenceService persistence,
  }) {
    final sectorsData = [
      (10, 'Aldabra Shimmer Rift', 'Drift Perimeter', 0, 1800, null, null),
      (
        11,
        'Cosmoledo Mirage Shoals',
        'Drift Perimeter',
        0,
        2400,
        10,
        'Aldabra Shimmer Rift',
      ),
      (
        12,
        'Astove Phase Bastion',
        'Drift Perimeter',
        0,
        3100,
        11,
        'Cosmoledo Mirage Shoals',
      ),
      (
        13,
        'Assumption Vector Vortex',
        'Phase Straits',
        1,
        4500,
        12,
        'Astove Phase Bastion',
      ),
      (
        14,
        'Farquhar Quantum Surge',
        'Phase Straits',
        1,
        5800,
        13,
        'Assumption Vector Vortex',
      ),
      (
        15,
        'St. Pierre Phantom Spire',
        'Phase Straits',
        1,
        7200,
        14,
        'Farquhar Quantum Surge',
      ),
      (
        16,
        'Providence Rift Citadel',
        'Singularity Drift',
        2,
        9600,
        15,
        'St. Pierre Phantom Spire',
      ),
      (
        17,
        'Coëtivy Warp Bastion',
        'Singularity Drift',
        2,
        11800,
        16,
        'Providence Rift Citadel',
      ),
      (
        18,
        'Agalega Singularity Zenith',
        'Singularity Drift',
        2,
        15200,
        17,
        'Coëtivy Warp Bastion',
      ),
    ];

    return sectorsData.map((data) {
      final id = data.$1;
      final name = data.$2;
      final region = data.$3;
      final tier = data.$4;
      final defaultScore = data.$5;
      final reqId = data.$6;
      final reqName = data.$7;
      final relIndex = id - 9; // 1..9

      final stars = persistence.getSectorStars(id);
      final score = persistence.getSectorScore(id);
      final isLib = liberated > relIndex || stars > 0;
      final isPrereq = liberated >= relIndex;

      final status = _evaluateStatus(
        isOperationUnlocked: isOperationUnlocked,
        isPro: isPro,
        isFirstInOperation: relIndex == 1,
        isLiberated: isLib,
        isPrerequisiteMet: isPrereq,
      );

      return CampaignSector(
        sectorId: id,
        name: name,
        region: region,
        difficultyTier: tier,
        starsEarned: stars,
        status: status,
        bestScore: score > 0 ? score : defaultScore,
        requiredSectorId: reqId,
        requiredSectorName: reqName,
        campaignId: 'phantom_drift',
        doctrine: SectorCombatDoctrine.phantomDrift,
      );
    }).toList();
  }

  List<CampaignSector> _buildVoidSwarmSectors({
    required bool isOperationUnlocked,
    required bool isPro,
    required int liberated,
    required PersistenceService persistence,
  }) {
    final sectorsData = [
      (19, 'Comoros Hive Gate', 'Swarm Ingress', 0, 2200, 8, null, null),
      (
        20,
        'Mohéli Brood Bastion',
        'Swarm Ingress',
        0,
        2900,
        9,
        19,
        'Comoros Hive Gate',
      ),
      (
        21,
        'Anjouan Larval Conduit',
        'Swarm Ingress',
        0,
        3800,
        10,
        20,
        'Mohéli Brood Bastion',
      ),
      (
        22,
        'Mayotte Swarm Corridor',
        'Horde Nexus',
        1,
        5200,
        12,
        21,
        'Anjouan Larval Conduit',
      ),
      (
        23,
        'Glorioso Nest Spire',
        'Horde Nexus',
        1,
        6600,
        13,
        22,
        'Mayotte Swarm Corridor',
      ),
      (
        24,
        'Geyser Hive Fortress',
        'Horde Nexus',
        1,
        8400,
        14,
        23,
        'Glorioso Nest Spire',
      ),
      (
        25,
        'Bassas da India Apex',
        'Apex Crucible',
        2,
        11000,
        16,
        24,
        'Geyser Hive Fortress',
      ),
      (
        26,
        'Europa Swarm Sovereign',
        'Apex Crucible',
        2,
        13500,
        18,
        25,
        'Bassas da India Apex',
      ),
      (
        27,
        'Mozambique Singularity Hive',
        'Apex Crucible',
        2,
        18000,
        20,
        26,
        'Europa Swarm Sovereign',
      ),
    ];

    return sectorsData.map((data) {
      final id = data.$1;
      final name = data.$2;
      final region = data.$3;
      final tier = data.$4;
      final defaultScore = data.$5;
      final quota = data.$6;
      final reqId = data.$7;
      final reqName = data.$8;
      final relIndex = id - 18; // 1..9

      final stars = persistence.getSectorStars(id);
      final score = persistence.getSectorScore(id);
      final isLib = liberated > relIndex || stars > 0;
      final isPrereq = liberated >= relIndex;

      final status = _evaluateStatus(
        isOperationUnlocked: isOperationUnlocked,
        isPro: isPro,
        isFirstInOperation: relIndex == 1,
        isLiberated: isLib,
        isPrerequisiteMet: isPrereq,
      );

      return CampaignSector(
        sectorId: id,
        name: name,
        region: region,
        difficultyTier: tier,
        starsEarned: stars,
        status: status,
        bestScore: score > 0 ? score : defaultScore,
        requiredSectorId: reqId,
        requiredSectorName: reqName,
        campaignId: 'void_swarm',
        doctrine: SectorCombatDoctrine.voidSwarm,
        reinforcementQuota: quota,
        coreSiphonPerKill: 1,
      );
    }).toList();
  }
}
