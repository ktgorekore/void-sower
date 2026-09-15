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

import '../../domain/models/user_profile.dart';
import '../theme/void_theme.dart';

/// Redesigned two-tier Tactical HUD header grouping Defense Grid and Fleet Command.
class HudHeader extends StatelessWidget {
  const HudHeader({
    super.key,
    required this.reserveCores,
    required this.score,
    required this.difficultyTier,
    required this.onSettingsTap,
    this.onCodexTap,
    this.onTutorialTap,
    this.onEmergencyFlareTap,
    this.isAutoSolving = false,
    this.onToggleAutoSolve,
    this.userProfile,
    this.onProfileTap,
    this.invadersRemaining,
    this.isPaused = false,
    this.onTogglePause,
    this.onMapTap,
  });

  final int reserveCores;
  final int score;
  final int difficultyTier;
  final VoidCallback onSettingsTap;
  final VoidCallback? onCodexTap;
  final VoidCallback? onTutorialTap;
  final VoidCallback? onEmergencyFlareTap;
  final bool isAutoSolving;
  final VoidCallback? onToggleAutoSolve;
  final UserProfile? userProfile;
  final VoidCallback? onProfileTap;
  final int? invadersRemaining;
  final bool isPaused;
  final VoidCallback? onTogglePause;
  final VoidCallback? onMapTap;

  String get tierName {
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
    final profile = userProfile ?? const UserProfile();

    return Container(
      decoration: BoxDecoration(
        color: VoidTheme.obsidianBlack.withValues(alpha: 0.95),
        border: const Border(
          bottom: BorderSide(color: VoidTheme.cardSurface, width: 1.0),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ROW 1: DEFENSE GRID & MISSION INTEL
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8.0,
                vertical: 3.5,
              ),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: VoidTheme.cardSurface.withValues(alpha: 0.45),
                    width: 0.8,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Left Group: Sector Tier & Invaders Counter
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Sector Threat Tier Pill
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6.0,
                          vertical: 2.0,
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
                          'T${difficultyTier + 1} • $tierName',
                          style: TextStyle(
                            color: difficultyTier == 2
                                ? VoidTheme.crimsonFlare
                                : VoidTheme.plasmaCyan,
                            fontSize: 9.0,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                      const SizedBox(width: 5.0),
                      // Invaders Remaining Pill
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6.0,
                          vertical: 2.0,
                        ),
                        decoration: BoxDecoration(
                          color: VoidTheme.cardSurface.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(4.0),
                          border: Border.all(
                            color:
                                (invadersRemaining != null &&
                                    invadersRemaining! <= 3)
                                ? VoidTheme.solarGold
                                : VoidTheme.textMuted.withValues(alpha: 0.4),
                            width: 0.8,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.shield_outlined,
                              size: 11.0,
                              color:
                                  (invadersRemaining != null &&
                                      invadersRemaining! <= 3)
                                  ? VoidTheme.solarGold
                                  : VoidTheme.textSecondary,
                            ),
                            const SizedBox(width: 3.0),
                            Text(
                              invadersRemaining != null
                                  ? '$invadersRemaining HOSTILES'
                                  : 'DEFENSE GRID ACTIVE',
                              style: TextStyle(
                                color:
                                    (invadersRemaining != null &&
                                        invadersRemaining! <= 3)
                                    ? VoidTheme.solarGold
                                    : VoidTheme.textSecondary,
                                fontSize: 8.5,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // Right Group: Prominent Bao Rules, Academy Tutorial, and Settings
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Prominent BAO RULES Button
                      if (onCodexTap != null)
                        GestureDetector(
                          onTap: onCodexTap,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7.0,
                              vertical: 2.5,
                            ),
                            decoration: BoxDecoration(
                              color: VoidTheme.plasmaCyan.withValues(
                                alpha: 0.15,
                              ),
                              borderRadius: BorderRadius.circular(4.0),
                              border: Border.all(
                                color: VoidTheme.plasmaCyan,
                                width: 1.0,
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.menu_book,
                                  color: VoidTheme.plasmaCyan,
                                  size: 12.0,
                                ),
                                SizedBox(width: 3.0),
                                Text(
                                  'RULES',
                                  style: TextStyle(
                                    color: VoidTheme.plasmaCyan,
                                    fontSize: 9.0,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      if (onTutorialTap != null) ...[
                        const SizedBox(width: 4.0),
                        GestureDetector(
                          onTap: onTutorialTap,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6.0,
                              vertical: 2.5,
                            ),
                            decoration: BoxDecoration(
                              color: VoidTheme.solarGold.withValues(
                                alpha: 0.12,
                              ),
                              borderRadius: BorderRadius.circular(4.0),
                              border: Border.all(
                                color: VoidTheme.solarGold.withValues(
                                  alpha: 0.7,
                                ),
                                width: 0.8,
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.school,
                                  color: VoidTheme.solarGold,
                                  size: 12.0,
                                ),
                                SizedBox(width: 2.5),
                                Text(
                                  'ACADEMY',
                                  style: TextStyle(
                                    color: VoidTheme.solarGold,
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(width: 2.0),
                      IconButton(
                        padding: const EdgeInsets.all(3.0),
                        constraints: const BoxConstraints(),
                        icon: const Icon(
                          Icons.settings,
                          color: VoidTheme.textSecondary,
                          size: 15.0,
                        ),
                        onPressed: onSettingsTap,
                        tooltip: 'Settings',
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ROW 2: TACTICAL FLEET & REACTOR ARSENAL
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8.0,
                vertical: 3.0,
              ),
              color: VoidTheme.obsidianBlack.withValues(alpha: 0.7),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Left Group: Pilot Profile, Reserve Cores & Mission Score
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Pilot Profile Pill
                      GestureDetector(
                        onTap: onProfileTap,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5.0,
                            vertical: 2.0,
                          ),
                          decoration: BoxDecoration(
                            color: VoidTheme.cardSurface,
                            borderRadius: BorderRadius.circular(4.0),
                            border: Border.all(
                              color: profile.isGoogleLinked
                                  ? VoidTheme.plasmaCyan
                                  : VoidTheme.solarGold.withValues(alpha: 0.5),
                              width: 0.8,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.account_circle,
                                color: profile.isGoogleLinked
                                    ? VoidTheme.plasmaCyan
                                    : VoidTheme.solarGold,
                                size: 12.0,
                              ),
                              const SizedBox(width: 3.0),
                              ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 80.0,
                                ),
                                child: Text(
                                  profile.callsign,
                                  style: const TextStyle(
                                    color: VoidTheme.starWhite,
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.3,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 4.0),

                      // Reactor Reserve Cores / Bombs Gauge
                      GestureDetector(
                        onTap: onEmergencyFlareTap,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5.0,
                            vertical: 2.0,
                          ),
                          decoration: BoxDecoration(
                            color: VoidTheme.cardSurface,
                            borderRadius: BorderRadius.circular(4.0),
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
                                size: 12.0,
                              ),
                              const SizedBox(width: 1.5),
                              Text(
                                '$reserveCores CORES',
                                style: TextStyle(
                                  color: reserveCores <= 5
                                      ? VoidTheme.crimsonFlare
                                      : VoidTheme.solarGold,
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 4.0),

                      // Score Pill
                      Text(
                        '$score',
                        style: const TextStyle(
                          color: VoidTheme.plasmaCyanLight,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ],
                  ),

                  // Right Group: Tactical Controls (Pause/Resume, AI Solver, Sector Map)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Tactical Pause / Time Dilation Button
                      if (onTogglePause != null)
                        GestureDetector(
                          onTap: onTogglePause,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6.0,
                              vertical: 2.5,
                            ),
                            decoration: BoxDecoration(
                              color: isPaused
                                  ? VoidTheme.solarGold
                                  : VoidTheme.cardSurface,
                              borderRadius: BorderRadius.circular(4.0),
                              border: Border.all(
                                color: isPaused
                                    ? VoidTheme.solarGold
                                    : VoidTheme.textMuted.withValues(
                                        alpha: 0.5,
                                      ),
                                width: 0.8,
                              ),
                              boxShadow: isPaused
                                  ? [
                                      BoxShadow(
                                        color: VoidTheme.solarGold.withValues(
                                          alpha: 0.4,
                                        ),
                                        blurRadius: 4.0,
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isPaused ? Icons.play_arrow : Icons.pause,
                                  color: isPaused
                                      ? VoidTheme.obsidianBlack
                                      : VoidTheme.starWhite,
                                  size: 11.0,
                                ),
                                const SizedBox(width: 2.0),
                                Text(
                                  isPaused ? 'RESUME' : 'PAUSE',
                                  style: TextStyle(
                                    color: isPaused
                                        ? VoidTheme.obsidianBlack
                                        : VoidTheme.starWhite,
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                      // AI Tactical Solver Button
                      if (onToggleAutoSolve != null) ...[
                        const SizedBox(width: 4.0),
                        GestureDetector(
                          onTap: onToggleAutoSolve,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5.0,
                              vertical: 2.5,
                            ),
                            decoration: BoxDecoration(
                              color: isAutoSolving
                                  ? VoidTheme.crimsonFlare
                                  : VoidTheme.cardSurface,
                              borderRadius: BorderRadius.circular(4.0),
                              border: Border.all(
                                color: isAutoSolving
                                    ? VoidTheme.crimsonFlare
                                    : VoidTheme.textMuted.withValues(
                                        alpha: 0.5,
                                      ),
                                width: 0.8,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.smart_toy,
                                  color: isAutoSolving
                                      ? VoidTheme.obsidianBlack
                                      : VoidTheme.plasmaCyanLight,
                                  size: 11.0,
                                ),
                                const SizedBox(width: 2.0),
                                Text(
                                  'AI',
                                  style: TextStyle(
                                    color: isAutoSolving
                                        ? VoidTheme.obsidianBlack
                                        : VoidTheme.plasmaCyanLight,
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],

                      // Sector Map Navigation Button
                      if (onMapTap != null) ...[
                        const SizedBox(width: 4.0),
                        GestureDetector(
                          onTap: onMapTap,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5.0,
                              vertical: 2.5,
                            ),
                            decoration: BoxDecoration(
                              color: VoidTheme.cardSurface,
                              borderRadius: BorderRadius.circular(4.0),
                              border: Border.all(
                                color: VoidTheme.plasmaCyan.withValues(
                                  alpha: 0.5,
                                ),
                                width: 0.8,
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.map_outlined,
                                  color: VoidTheme.plasmaCyan,
                                  size: 11.0,
                                ),
                                SizedBox(width: 2.0),
                                Text(
                                  'MAP',
                                  style: TextStyle(
                                    color: VoidTheme.plasmaCyan,
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
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
