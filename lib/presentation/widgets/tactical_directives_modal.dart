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
import 'tactile_button.dart';

/// Consolidated, ultra-fast (<20 seconds) Tactical Combat Directives modal.
///
/// Merges the Bao Orbital Codex and Flight Academy into 4 illustrated visual flashcards,
/// completely eliminating instructional wall-of-text fatigue while giving commanders
/// immediate one-tap access to the hands-on academy simulator.
class TacticalDirectivesModal extends StatelessWidget {
  const TacticalDirectivesModal({super.key, this.onLaunchAcademy});

  /// Optional callback to trigger hands-on Flight Academy interactive simulation.
  final VoidCallback? onLaunchAcademy;

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
            // Top Header: Insignia + Title + Subtitle + Close Button
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
                      boxShadow: [
                        BoxShadow(
                          color: VoidTheme.plasmaCyan.withValues(alpha: 0.4),
                          blurRadius: 10.0,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.military_tech,
                      color: VoidTheme.plasmaCyan,
                      size: 22.0,
                    ),
                  ),
                  const SizedBox(width: 12.0),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
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
                          'CORE COMBAT RULES IN 20 SECONDS',
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

            // Scrollable 4-Card Visual Micro-Briefing
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 12.0,
                ),
                children: [
                  // Card 1: Swipe to Sow
                  _buildRuleCard(
                    stepNumber: '1',
                    title: 'SWIPE TO SOW',
                    subtitle: 'TRAVERSAL',
                    description:
                        'Swipe left or right to distribute cores. Land in charged bays for free cascade laps.',
                    icon: Icons.sync_alt_rounded,
                    accentColor: VoidTheme.plasmaCyan,
                  ),
                  const SizedBox(height: 10.0),

                  // Card 2: Corridors C1–C8
                  _buildRuleCard(
                    stepNumber: '2',
                    title: 'CORRIDORS C1–C8',
                    subtitle: 'TARGETING',
                    description:
                        'Bays C1–C8 target the 8 enemy lanes. Align your dreadnought to aim.',
                    icon: Icons.filter_center_focus,
                    accentColor: VoidTheme.plasmaCyanLight,
                  ),
                  const SizedBox(height: 10.0),

                  // Card 3: Quadratic Lance
                  _buildRuleCard(
                    stepNumber: '3',
                    title: 'QUADRATIC LANCE',
                    subtitle: 'LANCE (D = M²)',
                    description:
                        'Frontline bays fire Particle Lances. Damage scales quadratically (4 cores = 16x).',
                    icon: Icons.bolt,
                    accentColor: VoidTheme.emeraldShield,
                  ),
                  const SizedBox(height: 10.0),

                  // Card 4: Shield Deflection
                  _buildRuleCard(
                    stepNumber: '4',
                    title: 'SHIELD CANOPY',
                    subtitle: 'DEFLECTION',
                    description:
                        'Charged frontline bays automatically deflect enemy bombs safely (+50 PTS).',
                    icon: Icons.shield,
                    accentColor: VoidTheme.solarGold,
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
                  // Secondary Action: Interactive Flight Academy Simulator (if available)
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
                          'LAUNCH FLIGHT ACADEMY',
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

                  // Primary Engage Combat Button
                  TactileButton(
                    label: 'ENGAGE COMBAT',
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
    required IconData icon,
    required Color accentColor,
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Glyph Box
          Container(
            width: 40.0,
            height: 40.0,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8.0),
              border: Border.all(
                color: accentColor.withValues(alpha: 0.6),
                width: 1.0,
              ),
            ),
            child: Icon(icon, color: accentColor, size: 20.0),
          ),
          const SizedBox(width: 12.0),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        '$stepNumber. $title',
                        style: TextStyle(
                          color: accentColor,
                          fontSize: 12.0,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6.0),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5.0,
                        vertical: 1.5,
                      ),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(3.0),
                      ),
                      child: Text(
                        subtitle,
                        style: TextStyle(
                          color: accentColor,
                          fontSize: 7.5,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5.0),
                Text(
                  description,
                  style: const TextStyle(
                    color: VoidTheme.starWhite,
                    fontSize: 11.0,
                    height: 1.35,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
