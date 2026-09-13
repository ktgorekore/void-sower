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

  List<CampaignSector> getSectors() {
    final liberated = PersistenceService.instance.liberatedSectors;

    return [
      // Region 1: Outer Bastions (Tier 1)
      CampaignSector(
        sectorId: 1,
        name: 'Zanzibar Reef Gate',
        region: 'Outer Bastions',
        difficultyTier: 0,
        starsEarned: liberated > 1 ? 3 : 0,
        isUnlocked: true,
        bestScore: 1200,
      ),
      CampaignSector(
        sectorId: 2,
        name: 'Pemba Channel Relay',
        region: 'Outer Bastions',
        difficultyTier: 0,
        starsEarned: liberated > 2 ? 3 : 0,
        isUnlocked: liberated >= 2,
        bestScore: 1650,
      ),
      CampaignSector(
        sectorId: 3,
        name: 'Mafia Trench Fortress',
        region: 'Outer Bastions',
        difficultyTier: 0,
        starsEarned: liberated > 3 ? 2 : 0,
        isUnlocked: liberated >= 3,
        bestScore: 2100,
      ),

      // Region 2: Monsoon Straits (Tier 2)
      CampaignSector(
        sectorId: 4,
        name: 'Kaskazi Ion Stream',
        region: 'Monsoon Straits',
        difficultyTier: 1,
        starsEarned: liberated > 4 ? 3 : 0,
        isUnlocked: liberated >= 4,
        bestScore: 3400,
      ),
      CampaignSector(
        sectorId: 5,
        name: 'Kusi Vortex Outpost',
        region: 'Monsoon Straits',
        difficultyTier: 1,
        starsEarned: liberated > 5 ? 2 : 0,
        isUnlocked: liberated >= 5,
        bestScore: 4100,
      ),
      CampaignSector(
        sectorId: 6,
        name: 'Lindi Ridge Bastion',
        region: 'Monsoon Straits',
        difficultyTier: 1,
        starsEarned: liberated > 6 ? 3 : 0,
        isUnlocked: liberated >= 6,
        bestScore: 5300,
      ),

      // Region 3: Core Siphon (Tier 3)
      CampaignSector(
        sectorId: 7,
        name: 'Kilwa Kisiwani Citadel',
        region: 'Core Siphon',
        difficultyTier: 2,
        starsEarned: liberated > 7 ? 2 : 0,
        isUnlocked: liberated >= 7,
        bestScore: 7800,
      ),
      CampaignSector(
        sectorId: 8,
        name: 'Songo Mnara Flagship Berth',
        region: 'Core Siphon',
        difficultyTier: 2,
        starsEarned: liberated > 8 ? 3 : 0,
        isUnlocked: liberated >= 8,
        bestScore: 9200,
      ),
      CampaignSector(
        sectorId: 9,
        name: 'Great Siphon Singularity',
        region: 'Core Siphon',
        difficultyTier: 2,
        starsEarned: liberated > 9 ? 3 : 0,
        isUnlocked: liberated >= 9,
        bestScore: 12500,
      ),
    ];
  }
}
