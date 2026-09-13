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

/// Top Tactical HUD header displaying reserve cores, score, wave tier, and controls.
class HudHeader extends StatelessWidget {
  const HudHeader({
    super.key,
    required this.reserveCores,
    required this.score,
    required this.difficultyTier,
    required this.onSettingsTap,
    this.onTutorialTap,
  });

  final int reserveCores;
  final int score;
  final int difficultyTier;
  final VoidCallback onSettingsTap;
  final VoidCallback? onTutorialTap;

  String get tierName {
    switch (difficultyTier) {
      case 0:
        return 'SECTOR PATROL';
      case 1:
        return 'PLANETARY SIEGE';
      case 2:
        return 'FLAGSHIP BASTION';
      default:
        return 'ORBITAL ENGAGEMENT';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: VoidTheme.obsidianBlack.withValues(alpha: 0.85),
        border: const Border(
          bottom: BorderSide(color: VoidTheme.cardSurface, width: 1.0),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Reserve Cores Indicator
            Row(
              children: [
                const Icon(Icons.lens, color: VoidTheme.solarGold, size: 16.0),
                const SizedBox(width: 6.0),
                Text(
                  'CORES: $reserveCores',
                  style: const TextStyle(
                    color: VoidTheme.solarGold,
                    fontSize: 14.0,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),

            // Tier Classification Badge
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8.0,
                vertical: 4.0,
              ),
              decoration: BoxDecoration(
                color: VoidTheme.cardSurface,
                borderRadius: BorderRadius.circular(4.0),
                border: Border.all(
                  color: difficultyTier == 2
                      ? VoidTheme.crimsonFlare
                      : VoidTheme.plasmaCyan,
                  width: 1.0,
                ),
              ),
              child: Text(
                tierName,
                style: TextStyle(
                  color: difficultyTier == 2
                      ? VoidTheme.crimsonFlare
                      : VoidTheme.plasmaCyan,
                  fontSize: 11.0,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ),

            // Score & Actions
            Row(
              children: [
                Text(
                  'SCORE: $score',
                  style: const TextStyle(
                    color: VoidTheme.textPrimary,
                    fontSize: 14.0,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(width: 8.0),
                if (onTutorialTap != null)
                  IconButton(
                    icon: const Icon(
                      Icons.help_outline,
                      color: VoidTheme.solarGold,
                      size: 20.0,
                    ),
                    onPressed: onTutorialTap,
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Flight Academy',
                  ),
                IconButton(
                  icon: const Icon(
                    Icons.menu_book,
                    color: VoidTheme.plasmaCyan,
                    size: 20.0,
                  ),
                  onPressed: onSettingsTap,
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Bao Codex',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
