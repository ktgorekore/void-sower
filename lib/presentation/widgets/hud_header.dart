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
      decoration: BoxDecoration(
        color: VoidTheme.obsidianBlack.withValues(alpha: 0.92),
        border: const Border(
          bottom: BorderSide(color: VoidTheme.cardSurface, width: 1.0),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // STRIP 1: Primary Mission Telemetry & Reactor Economy
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10.0,
                vertical: 4.5,
              ),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: VoidTheme.cardSurface.withValues(alpha: 0.5),
                    width: 0.8,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Reactor Reserve Core Gauge (Namua Fuel Pool)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7.0,
                      vertical: 2.5,
                    ),
                    decoration: BoxDecoration(
                      color: VoidTheme.cardSurface,
                      borderRadius: BorderRadius.circular(5.0),
                      border: Border.all(
                        color: reserveCores <= 5
                            ? VoidTheme.crimsonFlare
                            : VoidTheme.solarGold.withValues(alpha: 0.7),
                        width: 1.0,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.bolt,
                          color: reserveCores <= 5
                              ? VoidTheme.crimsonFlare
                              : VoidTheme.solarGold,
                          size: 13.0,
                        ),
                        const SizedBox(width: 3.0),
                        Text(
                          'REACTOR: $reserveCores',
                          style: TextStyle(
                            color: reserveCores <= 5
                                ? VoidTheme.crimsonFlare
                                : VoidTheme.solarGold,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Sector Threat Tier Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8.0,
                      vertical: 2.5,
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
                      '$tierName • TIER ${difficultyTier + 1}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: difficultyTier == 2
                            ? VoidTheme.crimsonFlare
                            : VoidTheme.plasmaCyan,
                        fontSize: 9.0,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),

                  // Mission Combat Score
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'SCORE: ',
                        style: TextStyle(
                          color: VoidTheme.textSecondary,
                          fontSize: 10.0,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        '$score',
                        style: const TextStyle(
                          color: VoidTheme.plasmaCyanLight,
                          fontSize: 12.0,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // STRIP 2: Tactical Command & Auxiliary Controls
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10.0,
                vertical: 2.0,
              ),
              color: VoidTheme.obsidianBlack.withValues(alpha: 0.6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Tactical Status Guidance Pill
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6.0,
                        height: 6.0,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isAutoSolving
                              ? VoidTheme.crimsonFlare
                              : VoidTheme.emeraldShield,
                          boxShadow: [
                            BoxShadow(
                              color:
                                  (isAutoSolving
                                          ? VoidTheme.crimsonFlare
                                          : VoidTheme.emeraldShield)
                                      .withValues(alpha: 0.6),
                              blurRadius: 4.0,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 5.0),
                      Text(
                        isAutoSolving
                            ? 'AI TACTICAL SOLVER ACTIVE'
                            : '▲ 8 CONDUITS ARMED • SOW TO DISCHARGE',
                        style: TextStyle(
                          color: isAutoSolving
                              ? VoidTheme.crimsonFlare
                              : VoidTheme.textSecondary,
                          fontSize: 8.5,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ],
                  ),

                  // Auxiliary Action Buttons
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (onToggleAutoSolve != null)
                        IconButton(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4.0,
                            vertical: 2.0,
                          ),
                          constraints: const BoxConstraints(),
                          icon: Icon(
                            isAutoSolving
                                ? Icons.smart_toy
                                : Icons.smart_toy_outlined,
                            color: isAutoSolving
                                ? VoidTheme.crimsonFlare
                                : VoidTheme.plasmaCyanLight,
                            size: 16.0,
                          ),
                          onPressed: onToggleAutoSolve,
                          tooltip: isAutoSolving
                              ? 'Stop AI Tactical Solver'
                              : 'Launch AI Tactical Solver',
                        ),
                      const SizedBox(width: 4.0),
                      if (onTutorialTap != null)
                        IconButton(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4.0,
                            vertical: 2.0,
                          ),
                          constraints: const BoxConstraints(),
                          icon: const Icon(
                            Icons.school_outlined,
                            color: VoidTheme.solarGold,
                            size: 16.0,
                          ),
                          onPressed: onTutorialTap,
                          tooltip: 'Flight Academy',
                        ),
                      const SizedBox(width: 4.0),
                      IconButton(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4.0,
                          vertical: 2.0,
                        ),
                        constraints: const BoxConstraints(),
                        icon: const Icon(
                          Icons.menu_book_outlined,
                          color: VoidTheme.plasmaCyan,
                          size: 16.0,
                        ),
                        onPressed: onSettingsTap,
                        tooltip: 'Bao Codex',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
