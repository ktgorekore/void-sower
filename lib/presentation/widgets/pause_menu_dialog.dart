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

import '../services/haptic_service.dart';
import '../theme/void_theme.dart';

/// Modal overlay presented when the player pauses the combat simulation.
/// Uses sleek, high-contrast, self-explanatory icon controls with minimal text.
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
    this.canRewind = false,
    this.rewindsRemaining = 0,
    this.onRewind,
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
  final bool canRewind;
  final int rewindsRemaining;
  final VoidCallback? onRewind;

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
            constraints: const BoxConstraints(maxWidth: 340.0),
            padding: const EdgeInsets.symmetric(
              horizontal: 20.0,
              vertical: 18.0,
            ),
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
                      width: 40.0,
                      height: 40.0,
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
                        size: 24.0,
                      ),
                    ),
                    const SizedBox(width: 12.0),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'TACTICAL PAUSE',
                            style: TextStyle(
                              color: VoidTheme.starWhite,
                              fontSize: 15.0,
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
                const SizedBox(height: 14.0),

                // Score bar: Compact Score + Best
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12.0,
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
                                fontSize: 15.0,
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
                                fontSize: 15.0,
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
                const SizedBox(height: 12.0),

                // Chrono-Anchor Rewind Option (if enabled)
                if (onRewind != null) ...[
                  GestureDetector(
                    onTap: canRewind
                        ? () {
                            HapticService.instance.injectionClick();
                            onRewind!();
                          }
                        : null,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12.0,
                        vertical: 9.0,
                      ),
                      decoration: BoxDecoration(
                        color: canRewind
                            ? VoidTheme.nebulaAmethyst.withValues(alpha: 0.22)
                            : VoidTheme.cardSurface.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(8.0),
                        border: Border.all(
                          color: canRewind
                              ? VoidTheme.nebulaAmethyst
                              : const Color(0xFF334155),
                          width: 1.2,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.history,
                            color: canRewind
                                ? VoidTheme.nebulaAmethyst
                                : VoidTheme.textMuted,
                            size: 16.0,
                          ),
                          Flexible(
                            child: Text(
                              canRewind
                                  ? 'CHRONO-REWIND ($rewindsRemaining REMAINING)'
                                  : 'CHRONO-REWIND (DEPLETED / LOCKED)',
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              style: TextStyle(
                                color: canRewind
                                    ? VoidTheme.starWhite
                                    : VoidTheme.textMuted,
                                fontSize: 10.0,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10.0),
                ] else ...[
                  const SizedBox(height: 4.0),
                ],

                // Primary Simulation Controls (Icon-Focused, Self-Explanatory)
                Row(
                  children: [
                    // Restart Button (Cyan 🔄)
                    Expanded(
                      flex: 3,
                      child: _buildActionIconButton(
                        icon: Icons.replay,
                        color: VoidTheme.plasmaCyan,
                        tooltip: 'Restart Sector',
                        onPressed: onRestart,
                        height: 48.0,
                      ),
                    ),
                    const SizedBox(width: 8.0),
                    // Large Emerald Resume Hero Button (▶)
                    Expanded(
                      flex: 4,
                      child: _buildActionIconButton(
                        icon: Icons.play_arrow,
                        color: VoidTheme.emeraldShield,
                        tooltip: 'Resume Sortie',
                        onPressed: onResume,
                        isPrimary: true,
                        iconSize: 28.0,
                        height: 48.0,
                      ),
                    ),
                    const SizedBox(width: 8.0),
                    // Abort Button (Crimson ⏹)
                    Expanded(
                      flex: 3,
                      child: _buildActionIconButton(
                        icon: Icons.stop_circle_outlined,
                        color: VoidTheme.crimsonFlare,
                        tooltip: 'Abort Mission',
                        onPressed: onAbort,
                        height: 48.0,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12.0),

                // Secondary Utility Icon Strip: Map, Directives, Academy, Settings, PRO AI Solver
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    if (onMap != null)
                      _buildUtilityIconButton(
                        icon: Icons.map_outlined,
                        color: VoidTheme.plasmaCyanLight,
                        tooltip: 'Star Map',
                        onPressed: onMap!,
                      ),
                    if (onCodex != null)
                      _buildUtilityIconButton(
                        icon: Icons.menu_book,
                        color: VoidTheme.solarGold,
                        tooltip: 'Directives',
                        onPressed: onCodex!,
                      ),
                    if (onAcademy != null)
                      _buildUtilityIconButton(
                        icon: Icons.school,
                        color: VoidTheme.plasmaCyanLight,
                        tooltip: 'Flight Academy',
                        onPressed: onAcademy!,
                      ),
                    if (onSettings != null)
                      _buildUtilityIconButton(
                        icon: Icons.settings,
                        color: VoidTheme.textSecondary,
                        tooltip: 'Settings',
                        onPressed: onSettings!,
                      ),
                    if (onToggleAutoSolve != null)
                      _buildProButton(
                        isAutoSolving: isAutoSolving,
                        onPressed: onToggleAutoSolve!,
                      ),
                  ],
                ),
              ],
            ),
          ),

          // Close button (X)
          Positioned(
            top: 6.0,
            right: 6.0,
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

  Widget _buildActionIconButton({
    required IconData icon,
    required Color color,
    required String tooltip,
    required VoidCallback onPressed,
    bool isPrimary = false,
    double iconSize = 22.0,
    double height = 44.0,
  }) {
    return Semantics(
      label: tooltip,
      button: true,
      child: Tooltip(
        message: tooltip,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            HapticService.instance.injectionClick();
            onPressed();
          },
          child: Container(
            height: height,
            decoration: BoxDecoration(
              color: isPrimary
                  ? color.withValues(alpha: 0.2)
                  : VoidTheme.cardSurface.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(10.0),
              border: Border.all(color: color, width: isPrimary ? 1.5 : 1.0),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: isPrimary ? 0.35 : 0.15),
                  blurRadius: isPrimary ? 8.0 : 4.0,
                ),
              ],
            ),
            child: Center(
              child: Icon(icon, color: color, size: iconSize),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUtilityIconButton({
    required IconData icon,
    required Color color,
    required String tooltip,
    required VoidCallback onPressed,
    bool isActive = false,
  }) {
    return Semantics(
      label: tooltip,
      button: true,
      child: Tooltip(
        message: tooltip,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            HapticService.instance.sowTick();
            onPressed();
          },
          child: Container(
            width: 44.0,
            height: 44.0,
            decoration: BoxDecoration(
              color: isActive
                  ? color.withValues(alpha: 0.2)
                  : VoidTheme.cardSurface.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(10.0),
              border: Border.all(
                color: isActive ? color : VoidTheme.cardSurface,
                width: 1.0,
              ),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: 0.4),
                        blurRadius: 6.0,
                      ),
                    ]
                  : null,
            ),
            child: Center(child: Icon(icon, color: color, size: 20.0)),
          ),
        ),
      ),
    );
  }

  Widget _buildProButton({
    required VoidCallback onPressed,
    required bool isAutoSolving,
  }) {
    final activeColor = isAutoSolving
        ? VoidTheme.crimsonFlare
        : VoidTheme.solarGold;
    return Semantics(
      label: isAutoSolving ? 'AI Solver Active (PRO)' : 'AI Solver (PRO)',
      button: true,
      child: Tooltip(
        message: isAutoSolving
            ? 'AI Solver: ACTIVE'
            : 'AI Tactical Solver (PRO)',
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            HapticService.instance.sowTick();
            onPressed();
          },
          child: Container(
            height: 44.0,
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            decoration: BoxDecoration(
              color: isAutoSolving
                  ? VoidTheme.crimsonFlare.withValues(alpha: 0.2)
                  : VoidTheme.cardSurface.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(10.0),
              border: Border.all(color: activeColor, width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: activeColor.withValues(
                    alpha: isAutoSolving ? 0.35 : 0.2,
                  ),
                  blurRadius: 6.0,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.smart_toy, color: activeColor, size: 18.0),
                const SizedBox(width: 4.0),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4.0,
                    vertical: 1.5,
                  ),
                  decoration: BoxDecoration(
                    color: isAutoSolving
                        ? VoidTheme.crimsonFlare.withValues(alpha: 0.3)
                        : VoidTheme.solarGold.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4.0),
                    border: Border.all(
                      color: activeColor.withValues(alpha: 0.8),
                      width: 0.8,
                    ),
                  ),
                  child: Text(
                    isAutoSolving ? 'ACTIVE' : 'PRO',
                    style: TextStyle(
                      color: activeColor,
                      fontSize: 8.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
