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

import '../../presentation/theme/void_theme.dart';

/// Rarity tier of an active Sowing Mutation in Void Incursion.
enum MutationRarity { common, rare, legendary }

/// Rogue-lite combat relic / mutation modifying capacitor sowing rules,
/// lance mechanics, or orbital defense parameters during a Void Incursion run.
class SowingMutation {
  const SowingMutation({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.icon,
    required this.accentColor,
    this.rarity = MutationRarity.common,
    this.lanceDamageMultiplier = 1.0,
    this.bonusStartingCores = 0,
    this.coreSiphonBonus = 0,
    this.doubleNyumbaOutput = false,
    this.flakMineOnLap = false,
    this.gravitonBeamPull = false,
    this.quantumMirrorCharge = false,
    this.phaseCanopyShields = 0,
  });

  /// Unique machine identifier.
  final String id;

  /// High-impact visual title.
  final String title;

  /// Short tactical category.
  final String subtitle;

  /// Concise mechanical rule explanation.
  final String description;

  /// Display icon.
  final IconData icon;

  /// Neon accent color for holographic presentation.
  final Color accentColor;

  /// Relic rarity tier.
  final MutationRarity rarity;

  /// Multiplier applied to quadratic lance damage D = alpha * M^2.
  final double lanceDamageMultiplier;

  /// Extra reserve cores granted immediately upon taking this mutation.
  final int bonusStartingCores;

  /// Extra plasma cores siphoned into reactor upon enemy craft destruction.
  final int coreSiphonBonus;

  /// If true, Nyumba bays (3 & 4) double accumulated mass and fire synchronized twin beams.
  final bool doubleNyumbaOutput;

  /// If true, every complete 16-bay lap traversed drops a spatial flak mine.
  final bool flakMineOnLap;

  /// If true, active particle lances draw descending hostiles inward toward the beam axis.
  final bool gravitonBeamPull;

  /// If true, sowing into an inner bay simultaneously mirrors 50% charge to its outer frontline twin.
  final bool quantumMirrorCharge;

  /// Number of enemy plasma projectiles deflected per combat wave.
  final int phaseCanopyShields;

  /// Predefined catalog of all rogue-lite Sowing Mutations.
  static const List<SowingMutation> allCatalog = [
    SowingMutation(
      id: 'overclocked_nyumba',
      title: 'OVERCLOCK NYUMBA',
      subtitle: 'SUPER-CAPACITOR RESONANCE',
      description:
          'Nyumba bays (3 & 4) accumulate 2x plasma mass and fire synchronized twin lances.',
      icon: Icons.flash_on,
      accentColor: VoidTheme.solarGold,
      rarity: MutationRarity.legendary,
      doubleNyumbaOutput: true,
    ),
    SowingMutation(
      id: 'cascading_superconductor',
      title: 'SUPERCONDUCTOR',
      subtitle: 'MULTI-LAP RELAY MINES',
      description:
          'Traversing a full 16-bay lap plants a proximity flak mine in the crossed conduit.',
      icon: Icons.blur_circular,
      accentColor: VoidTheme.plasmaCyan,
      rarity: MutationRarity.rare,
      flakMineOnLap: true,
    ),
    SowingMutation(
      id: 'singularity_graviton',
      title: 'GRAVITON LANCE',
      subtitle: 'SPATIAL COMPRESSION',
      description:
          'Particle lances generate a gravitational well pulling adjacent invaders into the beam.',
      icon: Icons.filter_center_focus,
      accentColor: VoidTheme.crimsonFlare,
      rarity: MutationRarity.rare,
      gravitonBeamPull: true,
    ),
    SowingMutation(
      id: 'quantum_mirror',
      title: 'QUANTUM MIRROR',
      subtitle: 'DUAL-TIER ENTANGLEMENT',
      description:
          'Sowing into Inner Reservoir bays mirrors 50% charge directly into Frontline Batteries.',
      icon: Icons.alt_route,
      accentColor: VoidTheme.emeraldShield,
      rarity: MutationRarity.rare,
      quantumMirrorCharge: true,
    ),
    SowingMutation(
      id: 'phase_canopy',
      title: 'PHASE CANOPY',
      subtitle: 'KINETIC DEFLECTION',
      description:
          'Forward dreadnought thrust creates an energy canopy deflecting 3 hostile plasma bullets.',
      icon: Icons.shield,
      accentColor: VoidTheme.plasmaCyanLight,
      rarity: MutationRarity.common,
      phaseCanopyShields: 3,
    ),
    SowingMutation(
      id: 'core_siphon_overdrive',
      title: 'SIPHON OVERDRIVE',
      subtitle: 'REACTOR HARVESTING',
      description:
          'Neutralizing any enemy craft harvests +2 extra auxiliary cores directly to reserves.',
      icon: Icons.battery_charging_full,
      accentColor: VoidTheme.solarGold,
      rarity: MutationRarity.common,
      coreSiphonBonus: 2,
    ),
    SowingMutation(
      id: 'quadratic_focus',
      title: 'BEAM OVERCHARGE',
      subtitle: 'HIGH-ENERGY LASER',
      description:
          'Increases laser beam damage by +35% across all battery discharges.',
      icon: Icons.offline_bolt,
      accentColor: VoidTheme.plasmaCyan,
      rarity: MutationRarity.common,
      lanceDamageMultiplier: 1.35,
    ),
    SowingMutation(
      id: 'emergency_matrix',
      title: 'EMERGENCY MATRIX',
      subtitle: 'REACTOR SURGE',
      description:
          'Instantly replenishes +6 emergency plasma cores into the dreadnought reactor pool.',
      icon: Icons.add_circle,
      accentColor: VoidTheme.emeraldShield,
      rarity: MutationRarity.common,
      bonusStartingCores: 6,
    ),
  ];
}
