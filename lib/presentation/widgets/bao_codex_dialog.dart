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

/// In-game Bao Codex and Tactical Rules Guide detailing orbital battery principles.
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
        constraints: const BoxConstraints(maxWidth: 480.0, maxHeight: 600.0),
        padding: const EdgeInsets.all(20.0),
        decoration: VoidTheme.glassmorphic(
          borderColor: VoidTheme.solarGold,
          borderWidth: 1.5,
          borderRadius: 16.0,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              children: [
                const Icon(
                  Icons.menu_book,
                  color: VoidTheme.solarGold,
                  size: 24.0,
                ),
                const SizedBox(width: 10.0),
                const Expanded(
                  child: Text(
                    'BAO ORBITAL CODEX',
                    style: TextStyle(
                      color: VoidTheme.solarGold,
                      fontSize: 16.0,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: VoidTheme.textSecondary),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const Divider(color: VoidTheme.cardSurface, height: 16.0),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildSectionCard(
                      title: 'ANCIENT MATHEMATICAL ROOTS',
                      body:
                          '16-bay orbital dreadnought defense system adapted from Bao count-and-capture rules.',
                      chips: const [
                        '16 CAPACITOR BAYS',
                        'COUNT & CAPTURE',
                        'CHARGED LASERS',
                      ],
                      icon: Icons.history_edu,
                      color: VoidTheme.solarGold,
                    ),
                    const SizedBox(height: 12.0),
                    _buildSectionCard(
                      title: '1. NAMUA (CORE INJECTION)',
                      body:
                          'Spend 1 core from 28 reactor reserves to prime capacitor bays.',
                      chips: const [
                        '⚡ 28 RESERVE CORES',
                        'PRIME BAY',
                        'SOWING TRAVERSAL',
                      ],
                      icon: Icons.bolt,
                      color: VoidTheme.plasmaCyan,
                      dioramaType: DioramaType.sowingAndNamua,
                    ),
                    const SizedBox(height: 12.0),
                    _buildSectionCard(
                      title: '2. CHARGED LASERS (STACKING POWER)',
                      body:
                          'Frontline bays fire laser beams. Stacking cores multiplies damage: 4 cores = 16x power!',
                      chips: const [
                        '⚡ 100x BASE',
                        '4 CORES = 16x POWER',
                        'LASER BEAM',
                      ],
                      icon: Icons.flash_on,
                      color: VoidTheme.crimsonFlare,
                      dioramaType: DioramaType.quadraticDamage,
                    ),
                    const SizedBox(height: 12.0),
                    _buildSectionCard(
                      title: '3. NYUMBA (SUPER-CAPACITOR BAYS 3 & 4)',
                      body:
                          'Nyumba bays retain sanctuary energy and amplify subsequent cascades.',
                      chips: const [
                        '🛡️ SANCTUARY BAYS',
                        '+15% CASCADE BOOST',
                        'REVERSE VECTORS',
                      ],
                      icon: Icons.shield,
                      color: VoidTheme.solarGold,
                      dioramaType: DioramaType.relayAndCascade,
                    ),
                    const SizedBox(height: 12.0),
                    _buildSectionCard(
                      title: '4. KICHWA (HEAD VECTORS 8 & 15)',
                      body:
                          'Advance along the altitude rail for a +60% Vanguard proximity devastation bonus.',
                      chips: const [
                        '▲ DEEP SPACE ASCENT',
                        '+60% PROXIMITY BONUS',
                        'CORRIDOR AIM',
                      ],
                      icon: Icons.compare_arrows,
                      color: VoidTheme.nebulaAmethyst,
                      dioramaType: DioramaType.vanguardAltitude,
                    ),
                    const SizedBox(height: 12.0),
                    _buildSectionCard(
                      title: '5. KIMBI (FLANK DEFLECTION BAYS 9 & 14)',
                      body:
                          'Charged flank chambers focus secondary flak shockwaves outward.',
                      chips: const [
                        '🛡️ DEFLECTION BAYS',
                        'FLAK SHOCKWAVE',
                        '+50 PTS',
                      ],
                      icon: Icons.call_split,
                      color: VoidTheme.emeraldShield,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16.0),

            // Interactive Flight Academy Onboarding Launch Button
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

            // Close Button
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
              fontSize: 11.5,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}
