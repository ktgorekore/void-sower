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
    this.isAutoSolving = false,
    this.onToggleAutoSolve,
  });

  final int reserveCores;
  final int score;
  final int difficultyTier;
  final VoidCallback onSettingsTap;
  final VoidCallback? onTutorialTap;
  final bool isAutoSolving;
  final VoidCallback? onToggleAutoSolve;

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
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
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
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lens, color: VoidTheme.solarGold, size: 13.0),
                const SizedBox(width: 4.0),
                Text(
                  'CORES: $reserveCores',
                  style: const TextStyle(
                    color: VoidTheme.solarGold,
                    fontSize: 12.0,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),

            // Tier Classification Badge
            Flexible(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 6.0),
                padding: const EdgeInsets.symmetric(
                  horizontal: 6.0,
                  vertical: 3.0,
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
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: difficultyTier == 2
                        ? VoidTheme.crimsonFlare
                        : VoidTheme.plasmaCyan,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ),

            // Score & Actions
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'SCORE: $score',
                  style: const TextStyle(
                    color: VoidTheme.textPrimary,
                    fontSize: 12.0,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(width: 4.0),
                if (onToggleAutoSolve != null)
                  IconButton(
                    padding: const EdgeInsets.all(4.0),
                    constraints: const BoxConstraints(),
                    icon: Icon(
                      isAutoSolving
                          ? Icons.smart_toy
                          : Icons.smart_toy_outlined,
                      color: isAutoSolving
                          ? VoidTheme.crimsonFlare
                          : VoidTheme.plasmaCyanLight,
                      size: 18.0,
                    ),
                    onPressed: onToggleAutoSolve,
                    tooltip: isAutoSolving
                        ? 'Stop AI Tactical Solver'
                        : 'Launch AI Tactical Solver',
                  ),
                const SizedBox(width: 2.0),
                if (onTutorialTap != null)
                  IconButton(
                    padding: const EdgeInsets.all(4.0),
                    constraints: const BoxConstraints(),
                    icon: const Icon(
                      Icons.help_outline,
                      color: VoidTheme.solarGold,
                      size: 18.0,
                    ),
                    onPressed: onTutorialTap,
                    tooltip: 'Flight Academy',
                  ),
                const SizedBox(width: 2.0),
                IconButton(
                  padding: const EdgeInsets.all(4.0),
                  constraints: const BoxConstraints(),
                  icon: const Icon(
                    Icons.menu_book,
                    color: VoidTheme.plasmaCyan,
                    size: 18.0,
                  ),
                  onPressed: onSettingsTap,
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
