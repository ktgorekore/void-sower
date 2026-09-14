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

import 'package:flutter/material.dart';

/// Afrofuturist squadron insignia motifs.
enum PilotInsignia {
  kilwaCrest(
    'Kilwa Crest',
    'Ancient maritime empire beacon of the Indian Ocean.',
  ),
  shonaStar(
    'Shona Star',
    'Geometric stellar sentinel inspired by Great Zimbabwe architecture.',
  ),
  zuluAegis(
    'Zulu Aegis',
    'Resilient elliptical defense crest forged in solar fires.',
  ),
  oyoComet(
    'Oyo Comet',
    'Blazing cavalry trajectory traversing deep orbital rifts.',
  ),
  songhaiCrown(
    'Songhai Crown',
    'Sovereign golden standard from the legendary Sahel academies.',
  ),
  swahiliNavigator(
    'Swahili Navigator',
    'Astrolabe vector guiding dreadnoughts through cosmic storms.',
  );

  const PilotInsignia(this.displayName, this.description);

  /// Human-readable label of the insignia.
  final String displayName;

  /// Lore description of the insignia motif.
  final String description;

  /// Iconic Material representation of the insignia motif.
  IconData get iconData {
    switch (this) {
      case PilotInsignia.kilwaCrest:
        return Icons.waves;
      case PilotInsignia.shonaStar:
        return Icons.auto_awesome;
      case PilotInsignia.zuluAegis:
        return Icons.shield;
      case PilotInsignia.oyoComet:
        return Icons.bolt;
      case PilotInsignia.songhaiCrown:
        return Icons.military_tech;
      case PilotInsignia.swahiliNavigator:
        return Icons.explore;
    }
  }
}

/// Military rank tiers earned through combat score.
enum PilotRank {
  cadet('Cadet', 0, 999),
  ensign('Ensign', 1000, 4999),
  lieutenant('Lieutenant', 5000, 14999),
  commander('Commander', 15000, 29999),
  admiral('Admiral', 30000, 49999),
  voidAscendant('Void Ascendant', 50000, 10000000);

  const PilotRank(this.title, this.minScore, this.maxScore);

  /// Rank designation title.
  final String title;

  /// Minimum threshold score required.
  final int minScore;

  /// Maximum threshold score for this tier.
  final int maxScore;

  /// Calculates rank corresponding to a given score.
  static PilotRank fromScore(int score) {
    if (score >= voidAscendant.minScore) return voidAscendant;
    if (score >= admiral.minScore) return admiral;
    if (score >= commander.minScore) return commander;
    if (score >= lieutenant.minScore) return lieutenant;
    if (score >= ensign.minScore) return ensign;
    return cadet;
  }
}

/// Player identity and lifetime progression telemetry.
class UserProfile {
  const UserProfile({
    this.id = 'pilot_default',
    this.callsign = 'Vanguard-01',
    this.insignia = PilotInsignia.kilwaCrest,
    this.lifetimeScore = 0,
    this.enemiesDestroyed = 0,
    this.lancesFired = 0,
    this.maxCascadeLaps = 0,
    this.unlockedAchievements = const <String>[],
    this.isGoogleLinked = false,
    this.googleEmail,
    this.googleDisplayName,
    this.googlePhotoUrl,
  });

  /// Unique identifier for this pilot profile.
  final String id;

  /// Pilot callsign handle (alphanumeric and hyphens, max 16 chars).
  final String callsign;

  /// Selected squadron cultural motif insignia.
  final PilotInsignia insignia;

  /// Cumulative lifetime combat score across all sectors.
  final int lifetimeScore;

  /// Total enemy assault craft neutralized.
  final int enemiesDestroyed;

  /// Total particle lance discharges activated.
  final int lancesFired;

  /// Maximum consecutive Bao cascade laps achieved in a single turn.
  final int maxCascadeLaps;

  /// List of achievement IDs unlocked by the pilot.
  final List<String> unlockedAchievements;

  /// Whether this profile is linked to a Google Play account.
  final bool isGoogleLinked;

  /// Associated Google email address if linked.
  final String? googleEmail;

  /// Associated Google display name if linked.
  final String? googleDisplayName;

  /// Associated Google avatar photo URL if available.
  final String? googlePhotoUrl;

  /// Pilot military rank calculated from lifetime combat score.
  PilotRank get rank => PilotRank.fromScore(lifetimeScore);

  /// Progress fraction (0.0 to 1.0) towards the next rank tier.
  double get rankProgress {
    final current = rank;
    if (current == PilotRank.voidAscendant) return 1.0;
    final range = current.maxScore - current.minScore + 1;
    final progress = lifetimeScore - current.minScore;
    return (progress / range).clamp(0.0, 1.0);
  }

  /// Creates a copy of this profile with updated attributes.
  UserProfile copyWith({
    String? id,
    String? callsign,
    PilotInsignia? insignia,
    int? lifetimeScore,
    int? enemiesDestroyed,
    int? lancesFired,
    int? maxCascadeLaps,
    List<String>? unlockedAchievements,
    bool? isGoogleLinked,
    String? googleEmail,
    String? googleDisplayName,
    String? googlePhotoUrl,
  }) {
    return UserProfile(
      id: id ?? this.id,
      callsign: callsign ?? this.callsign,
      insignia: insignia ?? this.insignia,
      lifetimeScore: lifetimeScore ?? this.lifetimeScore,
      enemiesDestroyed: enemiesDestroyed ?? this.enemiesDestroyed,
      lancesFired: lancesFired ?? this.lancesFired,
      maxCascadeLaps: maxCascadeLaps ?? this.maxCascadeLaps,
      unlockedAchievements: unlockedAchievements ?? this.unlockedAchievements,
      isGoogleLinked: isGoogleLinked ?? this.isGoogleLinked,
      googleEmail: googleEmail ?? this.googleEmail,
      googleDisplayName: googleDisplayName ?? this.googleDisplayName,
      googlePhotoUrl: googlePhotoUrl ?? this.googlePhotoUrl,
    );
  }

  /// Serializes profile to JSON map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'callsign': callsign,
      'insignia': insignia.name,
      'lifetimeScore': lifetimeScore,
      'enemiesDestroyed': enemiesDestroyed,
      'lancesFired': lancesFired,
      'maxCascadeLaps': maxCascadeLaps,
      'unlockedAchievements': unlockedAchievements,
      'isGoogleLinked': isGoogleLinked,
      'googleEmail': googleEmail,
      'googleDisplayName': googleDisplayName,
      'googlePhotoUrl': googlePhotoUrl,
    };
  }

  /// Deserializes profile from JSON map.
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    PilotInsignia parsedInsignia;
    try {
      parsedInsignia = PilotInsignia.values.byName(
        json['insignia'] as String? ?? 'kilwaCrest',
      );
    } catch (_) {
      parsedInsignia = PilotInsignia.kilwaCrest;
    }

    final parsedCallsign = json['callsign'] as String? ?? 'Vanguard-01';
    final parsedId =
        json['id'] as String? ??
        'pilot_${parsedCallsign.toLowerCase().replaceAll(' ', '_')}';

    return UserProfile(
      id: parsedId,
      callsign: parsedCallsign,
      insignia: parsedInsignia,
      lifetimeScore: (json['lifetimeScore'] as num?)?.toInt() ?? 0,
      enemiesDestroyed: (json['enemiesDestroyed'] as num?)?.toInt() ?? 0,
      lancesFired: (json['lancesFired'] as num?)?.toInt() ?? 0,
      maxCascadeLaps: (json['maxCascadeLaps'] as num?)?.toInt() ?? 0,
      unlockedAchievements:
          (json['unlockedAchievements'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const <String>[],
      isGoogleLinked: json['isGoogleLinked'] as bool? ?? false,
      googleEmail: json['googleEmail'] as String?,
      googleDisplayName: json['googleDisplayName'] as String?,
      googlePhotoUrl: json['googlePhotoUrl'] as String?,
    );
  }
}
