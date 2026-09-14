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

/// Top Tactical HUD header displaying pilot profile, reserve cores, score, wave tier, and controls.
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
    final profile = userProfile ?? const UserProfile();

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
            // STRIP 1: Pilot Profile, Reactor Economy, Sector Tier & Mission Score
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8.0,
                vertical: 4.0,
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
                  // 1. Pilot Profile Pill (Avatar/Insignia, Callsign, Google indicator)
                  GestureDetector(
                    onTap: onProfileTap,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6.0,
                        vertical: 2.5,
                      ),
                      decoration: BoxDecoration(
                        color: VoidTheme.cardSurface,
                        borderRadius: BorderRadius.circular(5.0),
                        border: Border.all(
                          color: profile.isGoogleLinked
                              ? VoidTheme.plasmaCyan
                              : VoidTheme.solarGold.withValues(alpha: 0.5),
                          width: 1.0,
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
                            size: 14.0,
                          ),
                          const SizedBox(width: 4.0),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 125.0),
                            child: Text(
                              profile.callsign,
                              style: const TextStyle(
                                color: VoidTheme.starWhite,
                                fontSize: 11.0,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.4,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (profile.isGoogleLinked) ...[
                            const SizedBox(width: 2.0),
                            const Icon(
                              Icons.g_mobiledata,
                              color: VoidTheme.plasmaCyan,
                              size: 14.0,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  // 2. Reactor Reserve Core Gauge (Namua Fuel Pool)
                  GestureDetector(
                    onTap: onEmergencyFlareTap,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6.0,
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
                          const SizedBox(width: 2.0),
                          Text(
                            '$reserveCores CORES',
                            style: TextStyle(
                              color: reserveCores <= 5
                                  ? VoidTheme.crimsonFlare
                                  : VoidTheme.solarGold,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 3. Sector Threat Tier Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5.0,
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
                      'TIER ${difficultyTier + 1}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: difficultyTier == 2
                            ? VoidTheme.crimsonFlare
                            : VoidTheme.plasmaCyan,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),

                  // 4. Mission Combat Score
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'SCORE: ',
                        style: TextStyle(
                          color: VoidTheme.textSecondary,
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.4,
                        ),
                      ),
                      Text(
                        '$score',
                        style: const TextStyle(
                          color: VoidTheme.plasmaCyanLight,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.6,
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
                horizontal: 8.0,
                vertical: 2.0,
              ),
              color: VoidTheme.obsidianBlack.withValues(alpha: 0.6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Tactical Status Guidance Pill
                  Expanded(
                    child: Row(
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
                        Expanded(
                          child: Text(
                            isAutoSolving
                                ? 'AI TACTICAL SOLVER ACTIVE'
                                : '8 CONDUITS ARMED • SOW TO DISCHARGE',
                            style: TextStyle(
                              color: isAutoSolving
                                  ? VoidTheme.crimsonFlare
                                  : VoidTheme.textSecondary,
                              fontSize: 8.5,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.4,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4.0),

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
                      if (onProfileTap != null) ...[
                        const SizedBox(width: 4.0),
                        IconButton(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4.0,
                            vertical: 2.0,
                          ),
                          constraints: const BoxConstraints(),
                          icon: const Icon(
                            Icons.account_circle_outlined,
                            color: VoidTheme.plasmaCyanLight,
                            size: 16.0,
                          ),
                          onPressed: onProfileTap,
                          tooltip: 'User Profile & Dossier',
                        ),
                      ],
                      if (onTutorialTap != null) ...[
                        const SizedBox(width: 4.0),
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
                      ],
                      if (onCodexTap != null) ...[
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
                          onPressed: onCodexTap,
                          tooltip: 'Bao Codex',
                        ),
                      ],
                      const SizedBox(width: 4.0),
                      IconButton(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4.0,
                          vertical: 2.0,
                        ),
                        constraints: const BoxConstraints(),
                        icon: const Icon(
                          Icons.settings,
                          color: VoidTheme.solarGold,
                          size: 16.0,
                        ),
                        onPressed: onSettingsTap,
                        tooltip: 'Fleet Settings',
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
