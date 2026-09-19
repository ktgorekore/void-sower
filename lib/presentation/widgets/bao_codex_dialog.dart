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
import 'tactile_button.dart';
import 'tutorial_video_dialog.dart';

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
                          'Void Sower transforms the Swahili count-and-capture game '
                          'Bao la Kiswahili into a 16-bay orbital dreadnought defense system. '
                          'Energy distributed along circular trajectories powers axial laser lances.',
                      icon: Icons.history_edu,
                      color: VoidTheme.solarGold,
                    ),
                    const SizedBox(height: 12.0),
                    _buildSectionCard(
                      title: '1. NAMUA (CORE INJECTION)',
                      body:
                          'Your reactor pool holds 28 Reserve Cores per sector. '
                          'Injecting a core into any bay (even with 0 charge) spends 1 reserve core '
                          '(Bao "Namua" rule) to prime and initiate orbital sowing. Energy is never created from nothing.',
                      icon: Icons.bolt,
                      color: VoidTheme.plasmaCyan,
                    ),
                    const SizedBox(height: 12.0),
                    _buildSectionCard(
                      title: '2. QUADRATIC LANCES (D = α · M²)',
                      body:
                          'When a sowing sequence finishes on a frontline bay (Bays 8–15 facing an active corridor), '
                          'its accumulated mass M discharges as an axial Particle Lance (D = 100 · M²). '
                          'Single shots deal only 100 DMG, while accumulated mass reaches 3,600 to 14,400 DMG!',
                      icon: Icons.flash_on,
                      color: VoidTheme.crimsonFlare,
                    ),
                    const SizedBox(height: 12.0),
                    _buildSectionCard(
                      title: '3. NYUMBA (SUPER-CAPACITOR BAYS 3 & 4)',
                      body:
                          'Nyumba (House) bays act as retention sanctuaries. '
                          'Units deposited into a Nyumba are stored and amplify subsequent discharges '
                          'with a +15% quadratic cascade bonus.',
                      icon: Icons.shield,
                      color: VoidTheme.solarGold,
                    ),
                    const SizedBox(height: 12.0),
                    _buildSectionCard(
                      title: '4. KICHWA (HEAD VECTORS 8 & 15)',
                      body:
                          'Kichwa conduits allow reversing the angular momentum of a sowing wave. '
                          'Entering a Kichwa reverses directional drift, trapping enemy formations.',
                      icon: Icons.compare_arrows,
                      color: VoidTheme.nebulaAmethyst,
                    ),
                    const SizedBox(height: 12.0),
                    _buildSectionCard(
                      title: '5. KIMBI (FLANK DEFLECTION BAYS 9 & 14)',
                      body:
                          'Kimbi chambers focus secondary flak shockwaves. '
                          'Terminating near a Kimbi redirects explosive flak bursts toward the outer corridors.',
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
                label: 'ENTER FLIGHT ACADEMY',
                icon: Icons.school,
                onPressed: () {
                  Navigator.of(context).pop();
                  onLaunchAcademy?.call();
                },
                accentColor: VoidTheme.solarGold,
                isPrimary: true,
                height: 42.0,
              ),
              const SizedBox(height: 8.0),
            ],

            // Video Briefing Button
            TactileButton(
              label: 'WATCH VIDEO TUTORIAL (60s)',
              icon: Icons.play_circle_filled,
              onPressed: () {
                showDialog<void>(
                  context: context,
                  builder: (context) => const TutorialVideoDialog(),
                );
              },
              accentColor: VoidTheme.solarGold,
              isPrimary: onLaunchAcademy == null,
              height: 42.0,
            ),
            const SizedBox(height: 8.0),

            // Close Button
            TactileButton(
              label: 'DISMISS CODEX',
              onPressed: () => Navigator.of(context).pop(),
              accentColor: VoidTheme.plasmaCyan,
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
          const SizedBox(height: 6.0),
          Text(
            body,
            style: const TextStyle(
              color: VoidTheme.textSecondary,
              fontSize: 12.0,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
