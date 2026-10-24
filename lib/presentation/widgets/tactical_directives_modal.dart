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

import '../services/haptic_service.dart';
import '../theme/void_theme.dart';
import 'kinetic_rule_diorama.dart';
import 'tactile_button.dart';

/// Visual-first, plain-English Tactical Combat Directives modal.
///
/// Uses animated 60 FPS dioramas, visual seed badges, and ultra-short 1-line
/// captions so any player understands the 3D Turret & Laser Fence mechanics
/// in seconds.
class TacticalDirectivesModal extends StatelessWidget {
  const TacticalDirectivesModal({
    super.key,
    this.onLaunchAcademy,
    this.onLaunchSimulationLab,
  });

  /// Optional callback to trigger hands-on Flight Academy interactive simulation.
  final VoidCallback? onLaunchAcademy;

  /// Optional callback to trigger Orbital Simulation Lab and MCTS arena.
  final VoidCallback? onLaunchSimulationLab;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(
        horizontal: 16.0,
        vertical: 24.0,
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 440.0, maxHeight: 720.0),
        decoration: BoxDecoration(
          color: VoidTheme.obsidianBlack.withValues(alpha: 0.98),
          borderRadius: BorderRadius.circular(18.0),
          border: Border.all(
            color: VoidTheme.plasmaCyan.withValues(alpha: 0.8),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: VoidTheme.plasmaCyan.withValues(alpha: 0.25),
              blurRadius: 24.0,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Header
            Padding(
              padding: const EdgeInsets.fromLTRB(18.0, 16.0, 12.0, 10.0),
              child: Row(
                children: [
                  Container(
                    width: 38.0,
                    height: 38.0,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: VoidTheme.plasmaCyan.withValues(alpha: 0.15),
                      border: Border.all(
                        color: VoidTheme.plasmaCyan,
                        width: 1.5,
                      ),
                    ),
                    child: const Icon(
                      Icons.military_tech,
                      color: VoidTheme.plasmaCyan,
                      size: 22.0,
                    ),
                  ),
                  const SizedBox(width: 12.0),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'TACTICAL DIRECTIVES',
                          style: TextStyle(
                            color: VoidTheme.starWhite,
                            fontSize: 15.0,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                          ),
                        ),
                        SizedBox(height: 2.0),
                        Text(
                          'QUICK GUIDE',
                          style: TextStyle(
                            color: VoidTheme.plasmaCyanLight,
                            fontSize: 9.5,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: VoidTheme.textSecondary,
                      size: 20.0,
                    ),
                    tooltip: 'Close Directives',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(color: VoidTheme.cardSurface, height: 1.0),

            // Scrollable 4-Card Visual Guide
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 12.0,
                ),
                children: [
                  _buildRuleCard(
                    stepNumber: '1',
                    title: 'SHOOT & SPREAD SEEDS',
                    subtitle: '‹ SOW / SOW ›',
                    description:
                        'Shoot enemies to get seeds. Swipe ‹ SOW or SOW › to spread them across turrets.',
                    chips: const ['🎯 SHOOT = +SEEDS', '‹ SOW / SOW ›'],
                    icon: Icons.sync_alt_rounded,
                    accentColor: VoidTheme.plasmaCyan,
                    dioramaType: DioramaType.sowingAndNamua,
                  ),
                  const SizedBox(height: 10.0),

                  _buildRuleCard(
                    stepNumber: '2',
                    title: 'GROW 3D TURRETS',
                    subtitle: '1 TO 4 SEEDS',
                    description:
                        '1 seed = Shield. 2+ = Auto-Gun. 4+ = 16x Super Beam!',
                    chips: const [
                      '●○○○ SHIELD',
                      '●●○○ AUTO-GUN',
                      '●●●● 16x BEAM',
                    ],
                    icon: Icons.bolt,
                    accentColor: VoidTheme.crimsonFlare,
                    dioramaType: DioramaType.quadraticDamage,
                  ),
                  const SizedBox(height: 10.0),

                  _buildRuleCard(
                    stepNumber: '3',
                    title: '3 IN A ROW = LASER FENCE',
                    subtitle: 'ZAPS BOMBS',
                    description:
                        'Line up 3 Auto-Guns side-by-side to zap enemy bombs in mid-air!',
                    chips: const ['🗼—🗼—🗼 3 IN A ROW', '⚡ ZAPS BOMBS'],
                    icon: Icons.shield,
                    accentColor: VoidTheme.solarGold,
                    dioramaType: DioramaType.relayAndCascade,
                  ),
                  const SizedBox(height: 10.0),

                  _buildRuleCard(
                    stepNumber: '4',
                    title: 'AIM & FLY FORWARD',
                    subtitle: '+60% POWER',
                    description:
                        'Drag left/right to aim. Slide up into the green zone for +60% power!',
                    chips: const ['◄ ► AIM LANE', '▲ +60% POWER'],
                    icon: Icons.filter_center_focus,
                    accentColor: VoidTheme.emeraldShield,
                    dioramaType: DioramaType.vanguardAltitude,
                  ),
                ],
              ),
            ),

            const Divider(color: VoidTheme.cardSurface, height: 1.0),

            // Footer Action Deck
            Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 10.0, 16.0, 14.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (onLaunchAcademy != null) ...[
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        onLaunchAcademy?.call();
                      },
                      icon: const Icon(
                        Icons.school,
                        color: VoidTheme.plasmaCyan,
                        size: 16.0,
                      ),
                      label: const FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'FLIGHT ACADEMY',
                          style: TextStyle(
                            color: VoidTheme.plasmaCyan,
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: VoidTheme.plasmaCyan.withValues(alpha: 0.6),
                          width: 1.2,
                        ),
                        backgroundColor: VoidTheme.plasmaCyan.withValues(
                          alpha: 0.08,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12.0,
                          vertical: 10.0,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10.0),
                  ],

                  if (onLaunchSimulationLab != null) ...[
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        onLaunchSimulationLab?.call();
                      },
                      icon: const Icon(
                        Icons.psychology,
                        color: VoidTheme.solarGold,
                        size: 16.0,
                      ),
                      label: const FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'SIM LAB • PRO',
                          style: TextStyle(
                            color: VoidTheme.solarGold,
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: VoidTheme.solarGold.withValues(alpha: 0.6),
                          width: 1.2,
                        ),
                        backgroundColor: VoidTheme.solarGold.withValues(
                          alpha: 0.08,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12.0,
                          vertical: 10.0,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10.0),
                  ],

                  TactileButton(
                    label: 'ENGAGE',
                    icon: Icons.rocket_launch,
                    accentColor: VoidTheme.plasmaCyan,
                    isPrimary: true,
                    height: 44.0,
                    onPressed: () {
                      HapticService.instance.sowTick();
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRuleCard({
    required String stepNumber,
    required String title,
    required String subtitle,
    required String description,
    required List<String> chips,
    required IconData icon,
    required Color accentColor,
    DioramaType? dioramaType,
  }) {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: VoidTheme.cardSurface.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.4),
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 34.0,
                height: 34.0,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(
                    color: accentColor.withValues(alpha: 0.6),
                    width: 1.0,
                  ),
                ),
                child: Icon(icon, color: accentColor, size: 18.0),
              ),
              const SizedBox(width: 10.0),
              Expanded(
                child: Text(
                  '$stepNumber. $title',
                  style: TextStyle(
                    color: accentColor,
                    fontSize: 12.0,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.7,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6.0,
                  vertical: 2.0,
                ),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4.0),
                ),
                child: Text(
                  subtitle,
                  style: TextStyle(
                    color: accentColor,
                    fontSize: 8.0,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ],
          ),
          if (dioramaType != null) ...[
            const SizedBox(height: 8.0),
            KineticRuleDiorama(
              type: dioramaType,
              height: 84.0,
              accentColor: accentColor,
            ),
          ],
          const SizedBox(height: 8.0),
          Wrap(
            spacing: 6.0,
            runSpacing: 4.0,
            children: chips
                .map(
                  (c) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6.0,
                      vertical: 2.0,
                    ),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(4.0),
                      border: Border.all(
                        color: accentColor.withValues(alpha: 0.4),
                        width: 0.8,
                      ),
                    ),
                    child: Text(
                      c,
                      style: TextStyle(
                        color: accentColor,
                        fontSize: 8.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 5.0),
          Text(
            description,
            style: const TextStyle(
              color: VoidTheme.starWhite,
              fontSize: 10.8,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}
