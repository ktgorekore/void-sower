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

/// Distinct premium feature capabilities in Void Sower.
enum ProFeature {
  /// Autonomous Monte Carlo Tree Search solver & autopilot.
  aiTacticalSolver,

  /// Holographic real-time next-move suggestion on active bays.
  aiMoveAdvisor,

  /// Heavy MK-III Singularity Sovereign flagship chassis (+30% lance alpha).
  mk3SingularityChassis,

  /// Exclusive solar-gilded MK-IV Golden Sovereign hull and engine trails.
  goldenSovereignSkin,

  /// Full multi-lap cascade spline trajectories and quadratic damage previews.
  deepSensorTelemetry,

  /// In-combat time-dilation rewinds restoring prior turn state.
  chronoAnchorRewind,

  /// Custom wave sandbox generator and infinite horde survival skirmish.
  orbitalSimulationLab,

  /// 100% ad-free experience with instant emergency reactor core injection.
  adFreeEmergencyFlare,

  /// Tactical time dilation & combat pause to inspect invader lanes and plan axial strikes.
  tacticalPause,

  /// Unlocks all 27 sectors across Kilwa Basin, Phantom Drift, and Void Swarm theaters.
  proCampaignTheaters,
}

/// Metadata and descriptive copy for a [ProFeature].
class ProFeatureMeta {
  const ProFeatureMeta({
    required this.feature,
    required this.title,
    required this.shortDescription,
    required this.icon,
  });

  final ProFeature feature;
  final String title;
  final String shortDescription;
  final IconData icon;

  static const Map<ProFeature, ProFeatureMeta> registry = {
    ProFeature.proCampaignTheaters: ProFeatureMeta(
      feature: ProFeature.proCampaignTheaters,
      title: 'EXPANDED PRO CAMPAIGN THEATERS',
      shortDescription:
          'All 27 campaign sectors start unlocked. Unlocks Phantom Drift (evasive invaders) and Void Swarm (respawning horde & core siphon).',
      icon: Icons.public,
    ),
    ProFeature.aiTacticalSolver: ProFeatureMeta(
      feature: ProFeature.aiTacticalSolver,
      title: 'AUTONOMOUS AI TACTICAL SOLVER',
      shortDescription:
          'Native C++ MCTS autopilot clears complex orbital waves with optimal cascades.',
      icon: Icons.smart_toy,
    ),
    ProFeature.aiMoveAdvisor: ProFeatureMeta(
      feature: ProFeature.aiMoveAdvisor,
      title: 'HOLOGRAPHIC TACTICAL ADVISOR',
      shortDescription:
          'Subtle glowing vector markers guide your next high-impact sowing decision.',
      icon: Icons.lightbulb_outline,
    ),
    ProFeature.mk3SingularityChassis: ProFeatureMeta(
      feature: ProFeature.mk3SingularityChassis,
      title: 'MK-III SINGULARITY SOVEREIGN',
      shortDescription:
          'Heavy 40-core dreadnought with +30% lance alpha and expanded flak blast radius.',
      icon: Icons.rocket_launch,
    ),
    ProFeature.goldenSovereignSkin: ProFeatureMeta(
      feature: ProFeature.goldenSovereignSkin,
      title: 'MK-IV GOLDEN SOVEREIGN HULL',
      shortDescription:
          'Gilded solar circuit lattice armor with radiant antimatter exhaust trails.',
      icon: Icons.shield,
    ),
    ProFeature.deepSensorTelemetry: ProFeatureMeta(
      feature: ProFeature.deepSensorTelemetry,
      title: 'DEEP SENSOR TELEMETRY',
      shortDescription:
          'Dynamic holographic splines preview multi-lap cascade routes and damage output.',
      icon: Icons.radar,
    ),
    ProFeature.chronoAnchorRewind: ProFeatureMeta(
      feature: ProFeature.chronoAnchorRewind,
      title: 'CHRONO-ANCHOR REWIND',
      shortDescription:
          'Undo accidental sowing miscalculations prior to catastrophic orbital breach.',
      icon: Icons.history,
    ),
    ProFeature.orbitalSimulationLab: ProFeatureMeta(
      feature: ProFeature.orbitalSimulationLab,
      title: 'SIMULATION LAB & SKIRMISH',
      shortDescription:
          'Custom wave generator, MCTS benchmark arena, and Endless Horde Survival mode.',
      icon: Icons.biotech,
    ),
    ProFeature.adFreeEmergencyFlare: ProFeatureMeta(
      feature: ProFeature.adFreeEmergencyFlare,
      title: '100% AD-FREE & INSTANT FLARES',
      shortDescription:
          'Zero commercials forever. Instant +8 core emergency refills with zero cooldown.',
      icon: Icons.bolt,
    ),
    ProFeature.tacticalPause: ProFeatureMeta(
      feature: ProFeature.tacticalPause,
      title: 'TACTICAL TIME DILATION',
      shortDescription:
          'Freeze invader advancement to analyze trajectory lanes and calibrate axial lance strikes.',
      icon: Icons.pause_circle_outline,
    ),
  };
}
