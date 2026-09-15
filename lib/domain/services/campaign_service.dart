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

import '../models/campaign_sector.dart';
import 'persistence_service.dart';

/// Service managing progressive star sectors across the Kilwa Nebula Basin.
class CampaignService {
  CampaignService._();
  static final CampaignService instance = CampaignService._();

  /// Retrieves a specific sector by its 1-based sector ID.
  CampaignSector getSector(int sectorId) {
    final sectors = getSectors();
    return sectors.firstWhere(
      (s) => s.sectorId == sectorId,
      orElse: () => sectors.first,
    );
  }

  /// Returns the complete list of 9 campaign sectors with dynamic unlock and liberation state.
  List<CampaignSector> getSectors() {
    final persistence = PersistenceService.instance;
    final liberated = persistence.liberatedSectors;

    return [
      // Region 1: Outer Bastions (Tier 1)
      CampaignSector(
        sectorId: 1,
        name: 'Zanzibar Reef Gate',
        region: 'Outer Bastions',
        difficultyTier: 0,
        starsEarned: persistence.getSectorStars(1),
        isUnlocked: true,
        isLiberated: liberated > 1 || persistence.getSectorStars(1) > 0,
        bestScore: persistence.getSectorScore(1) > 0
            ? persistence.getSectorScore(1)
            : 1200,
        requiredSectorId: null,
        requiredSectorName: null,
      ),
      CampaignSector(
        sectorId: 2,
        name: 'Pemba Channel Relay',
        region: 'Outer Bastions',
        difficultyTier: 0,
        starsEarned: persistence.getSectorStars(2),
        isUnlocked: liberated >= 2,
        isLiberated: liberated > 2 || persistence.getSectorStars(2) > 0,
        bestScore: persistence.getSectorScore(2) > 0
            ? persistence.getSectorScore(2)
            : 1650,
        requiredSectorId: 1,
        requiredSectorName: 'Zanzibar Reef Gate',
      ),
      CampaignSector(
        sectorId: 3,
        name: 'Mafia Trench Fortress',
        region: 'Outer Bastions',
        difficultyTier: 0,
        starsEarned: persistence.getSectorStars(3),
        isUnlocked: liberated >= 3,
        isLiberated: liberated > 3 || persistence.getSectorStars(3) > 0,
        bestScore: persistence.getSectorScore(3) > 0
            ? persistence.getSectorScore(3)
            : 2100,
        requiredSectorId: 2,
        requiredSectorName: 'Pemba Channel Relay',
      ),

      // Region 2: Monsoon Straits (Tier 2)
      CampaignSector(
        sectorId: 4,
        name: 'Kaskazi Ion Stream',
        region: 'Monsoon Straits',
        difficultyTier: 1,
        starsEarned: persistence.getSectorStars(4),
        isUnlocked: liberated >= 4,
        isLiberated: liberated > 4 || persistence.getSectorStars(4) > 0,
        bestScore: persistence.getSectorScore(4) > 0
            ? persistence.getSectorScore(4)
            : 3400,
        requiredSectorId: 3,
        requiredSectorName: 'Mafia Trench Fortress',
      ),
      CampaignSector(
        sectorId: 5,
        name: 'Kusi Vortex Outpost',
        region: 'Monsoon Straits',
        difficultyTier: 1,
        starsEarned: persistence.getSectorStars(5),
        isUnlocked: liberated >= 5,
        isLiberated: liberated > 5 || persistence.getSectorStars(5) > 0,
        bestScore: persistence.getSectorScore(5) > 0
            ? persistence.getSectorScore(5)
            : 4100,
        requiredSectorId: 4,
        requiredSectorName: 'Kaskazi Ion Stream',
      ),
      CampaignSector(
        sectorId: 6,
        name: 'Lindi Ridge Bastion',
        region: 'Monsoon Straits',
        difficultyTier: 1,
        starsEarned: persistence.getSectorStars(6),
        isUnlocked: liberated >= 6,
        isLiberated: liberated > 6 || persistence.getSectorStars(6) > 0,
        bestScore: persistence.getSectorScore(6) > 0
            ? persistence.getSectorScore(6)
            : 5300,
        requiredSectorId: 5,
        requiredSectorName: 'Kusi Vortex Outpost',
      ),

      // Region 3: Core Siphon (Tier 3)
      CampaignSector(
        sectorId: 7,
        name: 'Kilwa Kisiwani Citadel',
        region: 'Core Siphon',
        difficultyTier: 2,
        starsEarned: persistence.getSectorStars(7),
        isUnlocked: liberated >= 7,
        isLiberated: liberated > 7 || persistence.getSectorStars(7) > 0,
        bestScore: persistence.getSectorScore(7) > 0
            ? persistence.getSectorScore(7)
            : 7800,
        requiredSectorId: 6,
        requiredSectorName: 'Lindi Ridge Bastion',
      ),
      CampaignSector(
        sectorId: 8,
        name: 'Songo Mnara Flagship Berth',
        region: 'Core Siphon',
        difficultyTier: 2,
        starsEarned: persistence.getSectorStars(8),
        isUnlocked: liberated >= 8,
        isLiberated: liberated > 8 || persistence.getSectorStars(8) > 0,
        bestScore: persistence.getSectorScore(8) > 0
            ? persistence.getSectorScore(8)
            : 9200,
        requiredSectorId: 7,
        requiredSectorName: 'Kilwa Kisiwani Citadel',
      ),
      CampaignSector(
        sectorId: 9,
        name: 'Great Siphon Singularity',
        region: 'Core Siphon',
        difficultyTier: 2,
        starsEarned: persistence.getSectorStars(9),
        isUnlocked: liberated >= 9,
        isLiberated: liberated > 9 || persistence.getSectorStars(9) > 0,
        bestScore: persistence.getSectorScore(9) > 0
            ? persistence.getSectorScore(9)
            : 12500,
        requiredSectorId: 8,
        requiredSectorName: 'Songo Mnara Flagship Berth',
      ),
    ];
  }
}
