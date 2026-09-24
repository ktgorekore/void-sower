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

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/void_theme.dart';
import 'tactile_button.dart';

/// Modal overlay presented when the player pauses the combat simulation.
/// Stacks core simulation controls, campaign navigation, tactical codex, and settings.
class PauseMenuDialog extends StatelessWidget {
  const PauseMenuDialog({
    super.key,
    required this.sectorId,
    required this.sectorName,
    required this.difficultyTier,
    required this.score,
    this.highScore = 0,
    required this.onResume,
    required this.onRestart,
    required this.onAbort,
    this.onMap,
    this.onCodex,
    this.onAcademy,
    this.onSettings,
    this.isAutoSolving = false,
    this.onToggleAutoSolve,
  });

  final int sectorId;
  final String sectorName;
  final int difficultyTier;
  final int score;
  final int highScore;
  final VoidCallback onResume;
  final VoidCallback onRestart;
  final VoidCallback onAbort;
  final VoidCallback? onMap;
  final VoidCallback? onCodex;
  final VoidCallback? onAcademy;
  final VoidCallback? onSettings;
  final bool isAutoSolving;
  final VoidCallback? onToggleAutoSolve;

  String get _tierName {
    switch (difficultyTier) {
      case 0:
        return 'PATROL';
      case 1:
        return 'SIEGE';
      case 2:
        return 'BASTION';
      default:
        return 'ORBITAL';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            constraints: const BoxConstraints(maxWidth: 400.0),
            padding: const EdgeInsets.all(22.0),
            decoration: BoxDecoration(
              color: VoidTheme.obsidianBlack.withValues(alpha: 0.96),
              borderRadius: BorderRadius.circular(16.0),
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
                // Header: Title & Sector Details
                Row(
                  children: [
                    Container(
                      width: 44.0,
                      height: 44.0,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: VoidTheme.solarGold.withValues(alpha: 0.15),
                        border: Border.all(
                          color: VoidTheme.solarGold,
                          width: 1.5,
                        ),
                      ),
                      child: const Icon(
                        Icons.pause_circle_filled,
                        color: VoidTheme.solarGold,
                        size: 26.0,
                      ),
                    ),
                    const SizedBox(width: 14.0),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'TACTICAL PAUSE',
                            style: TextStyle(
                              color: VoidTheme.starWhite,
                              fontSize: 16.0,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 2.0),
                          Text(
                            'SECTOR $sectorId • $sectorName • $_tierName',
                            style: const TextStyle(
                              color: VoidTheme.textSecondary,
                              fontSize: 10.0,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.4,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16.0),

                // Score banner: Current Sortie Score + All-Time High Score
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10.0,
                    vertical: 8.0,
                  ),
                  decoration: BoxDecoration(
                    color: VoidTheme.cardSurface.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(8.0),
                    border: Border.all(
                      color: VoidTheme.cardSurface,
                      width: 1.0,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'CURRENT SORTIE SCORE',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: VoidTheme.textMuted,
                                fontSize: 8.5,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.4,
                              ),
                            ),
                            const SizedBox(height: 2.0),
                            Text(
                              '$score',
                              style: const TextStyle(
                                color: VoidTheme.plasmaCyanLight,
                                fontSize: 14.0,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 8.0),
                        width: 1.0,
                        height: 24.0,
                        color: VoidTheme.cardSurface,
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(
                                  Icons.emoji_events,
                                  size: 10.0,
                                  color: VoidTheme.solarGold,
                                ),
                                SizedBox(width: 3.0),
                                Flexible(
                                  child: Text(
                                    'ALL-TIME HIGH SCORE',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: VoidTheme.solarGold,
                                      fontSize: 8.5,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2.0),
                            Text(
                              '${math.max(score, highScore)}',
                              style: const TextStyle(
                                color: VoidTheme.solarGold,
                                fontSize: 14.0,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18.0),

                // Primary Simulation Controls: Resume (Play), Restart, Stop (Abort) - Icon-Only
                Row(
                  children: [
                    // Resume Sortie (Play)
                    Expanded(
                      child: Tooltip(
                        message: 'RESUME SORTIE',
                        child: TactileButton(
                          label: '',
                          icon: Icons.play_arrow,
                          accentColor: VoidTheme.emeraldShield,
                          onPressed: onResume,
                          minWidth: 0.0,
                          height: 46.0,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10.0),
                    // Restart Sortie
                    Expanded(
                      child: Tooltip(
                        message: 'RESTART SORTIE',
                        child: TactileButton(
                          label: '',
                          icon: Icons.replay,
                          accentColor: VoidTheme.plasmaCyan,
                          isPrimary: false,
                          onPressed: onRestart,
                          minWidth: 0.0,
                          height: 46.0,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10.0),
                    // Abort Sortie (Stop)
                    Expanded(
                      child: Tooltip(
                        message: 'ABORT SORTIE',
                        child: TactileButton(
                          label: '',
                          icon: Icons.stop_circle_outlined,
                          accentColor: VoidTheme.crimsonFlare,
                          isPrimary: false,
                          onPressed: onAbort,
                          minWidth: 0.0,
                          height: 46.0,
                        ),
                      ),
                    ),
                  ],
                ),
                if (onToggleAutoSolve != null) ...[
                  const SizedBox(height: 10.0),
                  TactileButton(
                    label: isAutoSolving
                        ? 'AI AUTO-SOLVER: ENGAGED'
                        : 'AI AUTO-SOLVER: STANDBY',
                    icon: Icons.smart_toy,
                    accentColor: isAutoSolving
                        ? VoidTheme.crimsonFlare
                        : VoidTheme.plasmaCyan,
                    isPrimary: isAutoSolving,
                    onPressed: onToggleAutoSolve,
                    minWidth: double.infinity,
                    height: 40.0,
                  ),
                ],
                const SizedBox(height: 10.0),

                // Tertiary Row: Map / Codex / Academy
                Row(
                  children: [
                    if (onMap != null)
                      Expanded(
                        child: TactileButton(
                          label: 'MAP',
                          icon: Icons.map_outlined,
                          accentColor: VoidTheme.plasmaCyanLight,
                          isPrimary: false,
                          onPressed: onMap,
                          minWidth: 0.0,
                          height: 40.0,
                          fontSize: 11.0,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4.0,
                            vertical: 4.0,
                          ),
                        ),
                      ),
                    if (onMap != null && (onCodex != null || onAcademy != null))
                      const SizedBox(width: 8.0),
                    if (onCodex != null)
                      Expanded(
                        child: TactileButton(
                          label: 'RULES',
                          icon: Icons.menu_book,
                          accentColor: VoidTheme.plasmaCyanLight,
                          isPrimary: false,
                          onPressed: onCodex,
                          minWidth: 0.0,
                          height: 40.0,
                          fontSize: 11.0,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4.0,
                            vertical: 4.0,
                          ),
                        ),
                      ),
                    if (onCodex != null && onAcademy != null)
                      const SizedBox(width: 8.0),
                    if (onAcademy != null)
                      Expanded(
                        child: TactileButton(
                          label: 'ACADEMY',
                          icon: Icons.school,
                          accentColor: VoidTheme.solarGold,
                          isPrimary: false,
                          onPressed: onAcademy,
                          minWidth: 0.0,
                          height: 40.0,
                          fontSize: 11.0,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4.0,
                            vertical: 4.0,
                          ),
                        ),
                      ),
                  ],
                ),

                // System Settings
                if (onSettings != null) ...[
                  const SizedBox(height: 10.0),
                  TactileButton(
                    label: 'SYSTEM & AUDIO SETTINGS',
                    icon: Icons.settings,
                    accentColor: VoidTheme.textSecondary,
                    isPrimary: false,
                    onPressed: onSettings,
                    minWidth: double.infinity,
                    height: 40.0,
                  ),
                ],
              ],
            ),
          ),

          // Close button (X)
          Positioned(
            top: 10.0,
            right: 10.0,
            child: GestureDetector(
              onTap: onResume,
              child: Container(
                padding: const EdgeInsets.all(6.0),
                decoration: BoxDecoration(
                  color: VoidTheme.cardSurface,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: VoidTheme.textMuted.withValues(alpha: 0.6),
                    width: 1.0,
                  ),
                ),
                child: const Icon(
                  Icons.close,
                  color: VoidTheme.textSecondary,
                  size: 16.0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
