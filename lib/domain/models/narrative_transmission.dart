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

/// Represents the 3 ascending tactical checkpoint phases within each sector.
enum SectorCheckpointPhase {
  /// Phase 1: Opening vanguard formation and reconnaissance.
  vanguardRecon(
    phaseNumber: 1,
    label: 'PHASE I · VANGUARD RECON',
    shortLabel: 'P1: RECON',
  ),

  /// Phase 2: Mid-sector tactical objective siege after Checkpoint 1 relic draft.
  tacticalSiege(
    phaseNumber: 2,
    label: 'PHASE II · TACTICAL SIEGE',
    shortLabel: 'P2: SIEGE',
  ),

  /// Phase 3: Multi-corridor Apex Command Dreadnought encounter.
  apexBoss(
    phaseNumber: 3,
    label: 'PHASE III · APEX COMMAND',
    shortLabel: 'P3: APEX BOSS',
  );

  const SectorCheckpointPhase({
    required this.phaseNumber,
    required this.label,
    required this.shortLabel,
  });

  /// 1-based phase number (1, 2, or 3).
  final int phaseNumber;

  /// Full tactical HUD banner label.
  final String label;

  /// Compact badge label for mobile HUD headers.
  final String shortLabel;
}

/// Immutable Afrofuturist radio transmission displayed at sector phase transitions.
class NarrativeTransmission {
  /// Creates a [NarrativeTransmission].
  const NarrativeTransmission({
    required this.speaker,
    required this.roleTitle,
    required this.culturalHeritage,
    required this.message,
    required this.tacticalDirective,
    required this.phase,
  });

  /// Commander or AI navigator name.
  final String speaker;

  /// Rank or role title.
  final String roleTitle;

  /// Cultural & strategic lineage tag (e.g. 'SWAHILI COAST · BAO MTAJI').
  final String culturalHeritage;

  /// Storyline comms dialogue.
  final String message;

  /// Actionable tactical hint fusing African strategy with space combat.
  final String tacticalDirective;

  /// Associated sector checkpoint phase.
  final SectorCheckpointPhase phase;
}

/// Lookup registry mapping campaign operations and phases to Afrofuturist
/// narrative transmissions and native tactical quest codes.
class SectorNarrativeRegistry {
  SectorNarrativeRegistry._();

  /// Sector-specific story lore anchors across the 27 sectors.
  static const Map<int, String> _sectorLoreTarget = <int, String>{
    1: 'Zanzibar Reef Gate beacon',
    2: 'Pemba Channel quantum relay',
    3: 'Mafia Trench orbital bastion',
    4: 'Kaskazi ion stream conduits',
    5: 'Kusi monsoon vortex array',
    6: 'Lindi Ridge defense spire',
    7: 'Kilwa Kisiwani royal foundry',
    8: 'Songo Mnara flagship drydock',
    9: 'Great Siphon Singularity core',
    10: 'Aldabra shimmer rift threshold',
    11: 'Cosmoledo phase-mirage shoals',
    12: 'Astove phase bastion',
    13: 'Assumption vector vortex',
    14: 'Farquhar quantum surge gate',
    15: 'St. Pierre phantom spire',
    16: 'Providence rift citadel',
    17: 'Coëtivy warp bastion',
    18: 'Agalega singularity zenith',
    19: 'Comoros hive ingress gate',
    20: 'Mohéli brood bastion',
    21: 'Anjouan larval conduit',
    22: 'Mayotte swarm corridor',
    23: 'Glorioso nest spire',
    24: 'Geyser hive fortress',
    25: 'Bassas da India apex crucible',
    26: 'Europa swarm sovereign',
    27: 'Mozambique singularity hive',
  };

  /// Resolves the narrative transmission for a given [operationId], [sectorNumber],
  /// and [phase].
  static NarrativeTransmission resolve({
    required int operationId,
    required int sectorNumber,
    required SectorCheckpointPhase phase,
  }) {
    final loreTarget =
        _sectorLoreTarget[sectorNumber] ?? 'Sector $sectorNumber beacon';
    final questTitle = questTitleForType(questTypeForSector(sectorNumber));

    if (operationId <= 1) {
      switch (phase) {
        case SectorCheckpointPhase.vanguardRecon:
          return NarrativeTransmission(
            speaker: 'ADMIRAL ZAWADI',
            roleTitle: 'KILWA ORBITAL FLOTILLA',
            culturalHeritage: 'SWAHILI COAST · BAO LA KISWAHILI',
            message:
                'Act I: Hegemony scouts are converging on the $loreTarget. '
                'Bays only fire on your command—weave the capacitor ring and '
                'pilot the Dreadnought to intercept!',
            tacticalDirective:
                'MTAJI RELAY: Land a multi-seed sow on an enemy lane to fire '
                'AND harvest +2 plasma seeds into your hand.',
            phase: phase,
          );
        case SectorCheckpointPhase.tacticalSiege:
          return NarrativeTransmission(
            speaker: 'SANKOFA-9',
            roleTitle: 'ASTROMETRIC AI CORE',
            culturalHeritage: 'KILWA BASIN · NYUMBA SANCTUARY',
            message:
                'Act II ($questTitle): Vanguard broken! Hostile strike wings '
                'are now evading charged corridors around the $loreTarget. '
                'Draft an Ancestral Relic and hold the siege line.',
            tacticalDirective:
                'DIRECT FIRE vs SOW: Tap FIRE to unleash stored M² mass '
                'immediately, or swipe CW/CCW to sow a chain cascade.',
            phase: phase,
          );
        case SectorCheckpointPhase.apexBoss:
          return NarrativeTransmission(
            speaker: 'ADMIRAL ZAWADI',
            roleTitle: 'KILWA ORBITAL FLOTILLA',
            culturalHeritage: 'MORABARABA · THREE-BAY MILL',
            message:
                'Act III: Hegemony Command Dreadnought dropping out of slipstream '
                'over the $loreTarget! Single-core shots will not breach its '
                'tri-lane barrier.',
            tacticalDirective:
                'MORABARABA MILL: Charge 3 adjacent frontline bays (M ≥ 2) '
                'to link a 1.5x 3-Corridor Super-Beam Barrage!',
            phase: phase,
          );
      }
    } else if (operationId == 2) {
      switch (phase) {
        case SectorCheckpointPhase.vanguardRecon:
          return NarrativeTransmission(
            speaker: 'STRATEGIST ANDRIANA',
            roleTitle: 'IMERINA VANGUARD COMMAND',
            culturalHeritage: 'MALAGASY HIGHLANDS · FANORONA VECTORS',
            message:
                'Act I: Entering $loreTarget. Phase-drift interceptors '
                'actively read your bay charges and flank unshielded lanes—'
                'static defense will fail.',
            tacticalDirective:
                'FANORONA VECTOR: Thrust forward into an enemy lane for an '
                'Approach Piercing Strike, or pull back for a Withdrawal Pulse!',
            phase: phase,
          );
        case SectorCheckpointPhase.tacticalSiege:
          return NarrativeTransmission(
            speaker: 'STRATEGIST ANDRIANA',
            roleTitle: 'IMERINA VANGUARD COMMAND',
            culturalHeritage: 'WEST AFRICAN · YOTÉ SURGICAL CULL',
            message:
                'Act II ($questTitle): Armored Cruisers are screening the '
                '$loreTarget siege line—shatter a Cruiser to unlock an '
                'orbital Yoté Cull!',
            tacticalDirective:
                'YOTÉ CULL: Destroying an Armored Cruiser grants a free '
                '800 DMG orbital kinetic strike—tap any enemy or CULL button!',
            phase: phase,
          );
        case SectorCheckpointPhase.apexBoss:
          return NarrativeTransmission(
            speaker: 'SANKOFA-9',
            roleTitle: 'ASTROMETRIC AI CORE',
            culturalHeritage: 'IMERINA CITADEL · APEX INTERCEPT',
            message:
                'Act III: Phantom Apex Carrier locking onto the $loreTarget! '
                'Combine Fanorona forward surges with Morabaraba 3-Bay Mills '
                'to shatter its multi-corridor plating.',
            tacticalDirective:
                'APEX PROTOCOL: Use Yoté Culls and 3-Bay Mill barrages to '
                'collapse all three boss shield corridors.',
            phase: phase,
          );
      }
    } else {
      switch (phase) {
        case SectorCheckpointPhase.vanguardRecon:
          return NarrativeTransmission(
            speaker: 'ELDER NOMMO-7',
            roleTitle: 'SIGI TOLO SANCTUARY KEEPER',
            culturalHeritage: 'DOGON SIRIUS LORE · PO TOLO CORE',
            message:
                'Act I: You fly beneath the twin suns at the $loreTarget. '
                'The white dwarf gravity well amplifies every quadratic '
                'resonance you sow.',
            tacticalDirective:
                'GRANDMASTERY: Chain Bao Mtaji captures into 3-Bay Mills '
                'while weaving Fanorona depth thrusts.',
            phase: phase,
          );
        case SectorCheckpointPhase.tacticalSiege:
          return NarrativeTransmission(
            speaker: 'ELDER NOMMO-7',
            roleTitle: 'SIGI TOLO SANCTUARY KEEPER',
            culturalHeritage: 'GREAT ZIMBABWE · MONOLITH BASTION',
            message:
                'Act II ($questTitle): Collapse the Hegemony warp rift at '
                'the $loreTarget before their adaptive fleet overwhelms the '
                'sanctuary perimeter!',
            tacticalDirective:
                'TACTICAL SIEGE: Complete the active corridor quest while '
                'harvesting Yoté Cull charges from Cruisers.',
            phase: phase,
          );
        case SectorCheckpointPhase.apexBoss:
          return NarrativeTransmission(
            speaker: 'ADMIRAL ZAWADI & NOMMO-7',
            roleTitle: 'SOVEREIGN COALITION COMMAND',
            culturalHeritage: 'PAN-AFRICAN TACTICAL SYNTHESIS',
            message:
                'Act III: The Sovereign Executioner Flagship commands the '
                '$loreTarget! Unleash every ancestral doctrine—Bao, Fanorona, '
                'Morabaraba, and Yoté!',
            tacticalDirective:
                'FINAL ASCENSION: Link 3-Bay Mills (1.5x) and trigger Yoté '
                'Surgical Culls to annihilate the Apex Flagship!',
            phase: phase,
          );
      }
    }
  }

  /// Resolves the native C++ `QuestType` integer (1..5) for Phase 2 of a sector.
  static int questTypeForSector(int sectorNumber) {
    // 1: OutpostReclamation, 2: ConvoyEscort, 4: WarpRiftCollapse, 5: AsteroidProspecting
    const questCycle = <int>[1, 4, 2, 5];
    return questCycle[(sectorNumber - 1).abs() & 3];
  }

  /// Human-readable objective title for Phase 2 tactical quests.
  static String questTitleForType(int questType) {
    switch (questType) {
      case 1:
        return 'OUTPOST RECLAMATION';
      case 2:
        return 'CONVOY ESCORT';
      case 3:
        return 'CAPITAL MOTHERSHIP SIEGE';
      case 4:
        return 'WARP RIFT COLLAPSE';
      case 5:
        return 'ASTEROID PROSPECTING';
      default:
        return 'SECTOR SUPREMACY';
    }
  }
}
