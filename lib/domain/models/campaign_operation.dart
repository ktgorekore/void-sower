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

import 'campaign_sector.dart';
import 'sector_combat_doctrine.dart';

/// Represents a planetary or orbital campaign operation consisting of multiple sectors.
class CampaignOperation {
  const CampaignOperation({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.tacticalBriefing,
    required this.isProRequired,
    required this.defaultDoctrine,
    required this.baseSectorId,
    required this.sectors,
  });

  /// Unique machine identifier (e.g. 'kilwa_basin', 'phantom_drift', 'void_swarm').
  final String id;

  /// High-tech military title of the theater.
  final String title;

  /// Operational subtitle.
  final String subtitle;

  /// Tactical intelligence overview for the command deck.
  final String tacticalBriefing;

  /// Whether accessing this campaign requires permanent Pro or a temporary pass.
  final bool isProRequired;

  /// Combat rules doctrine governing this theater.
  final SectorCombatDoctrine defaultDoctrine;

  /// First 1-based sector ID in this operation.
  final int baseSectorId;

  /// Ordered list of mission sectors within this operation.
  final List<CampaignSector> sectors;

  /// Total number of sectors liberated in this operation.
  int get liberatedCount => sectors.where((s) => s.isLiberated).length;

  /// Total stars earned across this operation.
  int get totalStars => sectors.fold(0, (acc, s) => acc + s.starsEarned);

  /// Maximum possible stars in this operation.
  int get maxStars => sectors.length * 3;
}
