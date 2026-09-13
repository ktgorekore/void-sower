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

/// Sector node on the Kilwa Nebula campaign star map.
class CampaignSector {
  const CampaignSector({
    required this.sectorId,
    required this.name,
    required this.region,
    required this.difficultyTier,
    required this.starsEarned,
    required this.isUnlocked,
    required this.bestScore,
  });

  final int sectorId;
  final String name;
  final String region; // 'Outer Bastions', 'Monsoon Straits', 'Core Siphon'
  final int difficultyTier; // 0, 1, 2
  final int starsEarned; // 0 to 3
  final bool isUnlocked;
  final int bestScore;
}
