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

import '../theme/void_theme.dart';
import 'kinetic_rule_diorama.dart';
import 'tactile_button.dart';

/// Visual-first Bao Orbital Codex explaining the 3D Turret & Laser Fence rules
/// in plain, everyday language with animated dioramas.
class BaoCodexDialog extends StatelessWidget {
  const BaoCodexDialog({super.key, this.onLaunchAcademy});

  /// Optional callback to launch or transition into the interactive Flight Academy.
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
        constraints: const BoxConstraints(maxWidth: 480.0, maxHeight: 620.0),
        padding: const EdgeInsets.all(20.0),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(20.0),
          border: Border.all(
            color: const Color(0xFFF59E0B).withValues(alpha: 0.8),
            width: 1.5,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x66000000),
              blurRadius: 24.0,
              offset: Offset(0, 8),
            ),
            BoxShadow(
              color: Color(0x2BF59E0B),
              blurRadius: 16.0,
              spreadRadius: -2,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: 38.0,
                  height: 38.0,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0x22F59E0B),
                    border: Border.all(
                      color: const Color(0xFFF59E0B),
                      width: 1.5,
                    ),
                  ),
                  child: const Icon(
                    Icons.menu_book,
                    color: Color(0xFFF59E0B),
                    size: 20.0,
                  ),
                ),
                const SizedBox(width: 12.0),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'VISUAL COMBAT GUIDE',
                        style: TextStyle(
                          color: Color(0xFFF59E0B),
                          fontSize: 9.0,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                        ),
                      ),
                      SizedBox(height: 2.0),
                      Text(
                        'BAO ORBITAL CODEX',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15.0,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.close,
                    color: Color(0xFF94A3B8),
                    size: 20.0,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 12.0),
            Container(
              height: 3.0,
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B),
                borderRadius: BorderRadius.circular(1.5),
                boxShadow: const [
                  BoxShadow(color: Color(0x80F59E0B), blurRadius: 6.0),
                ],
              ),
            ),
            const SizedBox(height: 14.0),

            // Scrollable Visual Guide Cards
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildSectionCard(
                      title: 'AFRICAN STRATEGY MEETS 3D SHOOTER',
                      body:
                          'Every shot drops seeds into 8 3D Turrets inspired by Bao & Morabaraba.',
                      chips: const [
                        '🎯 SHOOT = +SEEDS',
                        '🗼 8 3D TURRETS',
                        '⚡ LASER FENCE',
                      ],
                      icon: Icons.history_edu,
                      color: VoidTheme.solarGold,
                    ),
                    const SizedBox(height: 12.0),
                    _buildSectionCard(
                      title: '1. SHOOT & SPREAD SEEDS',
                      body:
                          'Shoot enemies to harvest seeds, or tap ‹ SOW / SOW › to spread seeds to neighbor turrets.',
                      chips: const [
                        '🎯 AUTO-HARVEST',
                        '‹ SOW / SOW ›',
                        'GROW TURRETS',
                      ],
                      icon: Icons.bolt,
                      color: VoidTheme.plasmaCyan,
                      dioramaType: DioramaType.sowingAndNamua,
                    ),
                    const SizedBox(height: 12.0),
                    _buildSectionCard(
                      title: '2. TURRET LEVELS & SUPER BEAMS',
                      body:
                          '1 seed = Shield Dome. 2–3 seeds = Auto-Gun. 4+ seeds = 16x Super Beam!',
                      chips: const [
                        '●○○○ SHIELD',
                        '●●○○ AUTO-GUN',
                        '●●●● 16x SUPER BEAM',
                      ],
                      icon: Icons.flash_on,
                      color: VoidTheme.crimsonFlare,
                      dioramaType: DioramaType.quadraticDamage,
                    ),
                    const SizedBox(height: 12.0),
                    _buildSectionCard(
                      title: '3. 3 IN A ROW = LASER FENCE',
                      body:
                          '3 adjacent Auto-Guns link a golden Laser Fence that zaps falling bombs mid-air!',
                      chips: const [
                        '🗼—🗼—🗼 3 IN A ROW',
                        '🛡️ ZAPS BOMBS',
                        '⚡ 1.5x BARRAGE',
                      ],
                      icon: Icons.shield,
                      color: VoidTheme.solarGold,
                      dioramaType: DioramaType.relayAndCascade,
                    ),
                    const SizedBox(height: 12.0),
                    _buildSectionCard(
                      title: '4. FLY FORWARD FOR +60% POWER',
                      body:
                          'Slide your ship up into the green Boost Zone for +60% laser damage.',
                      chips: const [
                        '◄ ► SLIDE TO AIM',
                        '▲ FLY UP = +60% POWER',
                      ],
                      icon: Icons.compare_arrows,
                      color: VoidTheme.emeraldShield,
                      dioramaType: DioramaType.vanguardAltitude,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16.0),

            if (onLaunchAcademy != null) ...[
              TactileButton(
                label: 'ACADEMY',
                icon: Icons.school,
                onPressed: () {
                  Navigator.of(context).pop();
                  onLaunchAcademy?.call();
                },
                accentColor: VoidTheme.solarGold,
                isPrimary: true,
                height: 44.0,
              ),
              const SizedBox(height: 8.0),
            ],

            TactileButton(
              label: 'DISMISS',
              onPressed: () => Navigator.of(context).pop(),
              accentColor: VoidTheme.plasmaCyan,
              isPrimary: onLaunchAcademy == null,
              height: 40.0,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required String body,
    required IconData icon,
    required Color color,
    List<String>? chips,
    DioramaType? dioramaType,
  }) {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: VoidTheme.cardSurface.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18.0),
              const SizedBox(width: 8.0),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontSize: 12.0,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
            ],
          ),
          if (dioramaType != null) ...[
            const SizedBox(height: 8.0),
            KineticRuleDiorama(
              type: dioramaType,
              height: 90.0,
              accentColor: color,
            ),
          ],
          if (chips != null && chips.isNotEmpty) ...[
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
                        color: color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4.0),
                        border: Border.all(
                          color: color.withValues(alpha: 0.4),
                          width: 0.8,
                        ),
                      ),
                      child: Text(
                        c,
                        style: TextStyle(
                          color: color,
                          fontSize: 9.0,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
          const SizedBox(height: 6.0),
          Text(
            body,
            style: const TextStyle(
              color: VoidTheme.textSecondary,
              fontSize: 11.0,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}
