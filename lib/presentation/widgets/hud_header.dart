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

/// 3-Tier Tactical HUD Header organizing Campaign Navigation, Combat Telemetry,
/// and Universal Simulation Controls.
class HudHeader extends StatelessWidget {
  const HudHeader({
    super.key,
    required this.reserveCores,
    required this.score,
    required this.difficultyTier,
    this.sectorId = 1,
    this.sectorName = 'Zanzibar Reef Gate',
    required this.onSettingsTap,
    this.onCodexTap,
    this.onTutorialTap,
    this.onEmergencyFlareTap,
    this.isAutoSolving = false,
    this.onToggleAutoSolve,
    this.userProfile,
    this.onProfileTap,
    this.invadersRemaining,
    this.totalInvaders,
    this.isPaused = false,
    this.onTogglePause,
    this.onMapTap,
    this.onRestartTap,
    this.onStopTap,
    this.onNextSectorTap,
    this.isSecured = false,
  });

  final int reserveCores;
  final int score;
  final int difficultyTier;
  final int sectorId;
  final String sectorName;
  final VoidCallback onSettingsTap;
  final VoidCallback? onCodexTap;
  final VoidCallback? onTutorialTap;
  final VoidCallback? onEmergencyFlareTap;
  final bool isAutoSolving;
  final VoidCallback? onToggleAutoSolve;
  final UserProfile? userProfile;
  final VoidCallback? onProfileTap;
  final int? invadersRemaining;
  final int? totalInvaders;
  final bool isPaused;
  final VoidCallback? onTogglePause;
  final VoidCallback? onMapTap;
  final VoidCallback? onRestartTap;
  final VoidCallback? onStopTap;
  final VoidCallback? onNextSectorTap;
  final bool isSecured;

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
    final bool secured =
        isSecured || (invadersRemaining != null && invadersRemaining == 0);

    return Container(
      decoration: BoxDecoration(
        color: VoidTheme.obsidianBlack.withValues(alpha: 0.96),
        border: const Border(
          bottom: BorderSide(color: VoidTheme.cardSurface, width: 1.0),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // BAR 1: SYSTEM NAVIGATION & PROTOCOLS
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
                  // Left: Map Navigation & Sector Threat Tier
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (onMapTap != null) ...[
                        GestureDetector(
                          onTap: onMapTap,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7.0,
                              vertical: 3.0,
                            ),
                            decoration: BoxDecoration(
                              color: VoidTheme.cardSurface,
                              borderRadius: BorderRadius.circular(4.0),
                              border: Border.all(
                                color: VoidTheme.plasmaCyan.withValues(
                                  alpha: 0.7,
                                ),
                                width: 1.0,
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.map_outlined,
                                  color: VoidTheme.plasmaCyan,
                                  size: 13.0,
                                ),
                                SizedBox(width: 3.0),
                                Text(
                                  'MAP',
                                  style: TextStyle(
                                    color: VoidTheme.plasmaCyan,
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 5.0),
                      ],
                      // Sector Threat Tier Pill
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7.0,
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
                          'S$sectorId • $tierName',
                          style: TextStyle(
                            color: difficultyTier == 2
                                ? VoidTheme.crimsonFlare
                                : VoidTheme.plasmaCyan,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Right: Rules, Academy & Aligned Settings
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (onCodexTap != null)
                        GestureDetector(
                          onTap: onCodexTap,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7.0,
                              vertical: 3.0,
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
                                  size: 13.0,
                                ),
                                SizedBox(width: 3.0),
                                Text(
                                  'RULES',
                                  style: TextStyle(
                                    color: VoidTheme.plasmaCyan,
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      if (onTutorialTap != null) ...[
                        const SizedBox(width: 5.0),
                        GestureDetector(
                          onTap: onTutorialTap,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7.0,
                              vertical: 3.0,
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
                                width: 1.0,
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.school,
                                  color: VoidTheme.solarGold,
                                  size: 13.0,
                                ),
                                SizedBox(width: 2.5),
                                Text(
                                  'ACADEMY',
                                  style: TextStyle(
                                    color: VoidTheme.solarGold,
                                    fontSize: 9.0,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(width: 5.0),
                      // Pixel-perfect Aligned Settings Button
                      GestureDetector(
                        onTap: onSettingsTap,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6.0,
                            vertical: 3.0,
                          ),
                          decoration: BoxDecoration(
                            color: VoidTheme.cardSurface,
                            borderRadius: BorderRadius.circular(4.0),
                            border: Border.all(
                              color: VoidTheme.textSecondary.withValues(
                                alpha: 0.5,
                              ),
                              width: 1.0,
                            ),
                          ),
                          child: const Icon(
                            Icons.settings,
                            color: VoidTheme.starWhite,
                            size: 18.0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // BAR 2: LIVE COMBAT TELEMETRY & REACTOR ARSENAL
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8.0,
                vertical: 3.5,
              ),
              decoration: BoxDecoration(
                color: VoidTheme.obsidianBlack.withValues(alpha: 0.8),
                border: Border(
                  bottom: BorderSide(
                    color: VoidTheme.cardSurface.withValues(alpha: 0.4),
                    width: 0.8,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Left: Pilot Callsign & Score
                  Flexible(
                    flex: 5,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GestureDetector(
                            onTap: onProfileTap,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6.0,
                                vertical: 2.5,
                              ),
                              decoration: BoxDecoration(
                                color: VoidTheme.cardSurface,
                                borderRadius: BorderRadius.circular(4.0),
                                border: Border.all(
                                  color: profile.isGoogleLinked
                                      ? VoidTheme.plasmaCyan
                                      : VoidTheme.solarGold.withValues(
                                          alpha: 0.5,
                                        ),
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
                                    size: 13.0,
                                  ),
                                  const SizedBox(width: 3.0),
                                  ConstrainedBox(
                                    constraints: const BoxConstraints(
                                      maxWidth: 85.0,
                                    ),
                                    child: Text(
                                      profile.callsign,
                                      style: const TextStyle(
                                        color: VoidTheme.starWhite,
                                        fontSize: 10.0,
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
                          const SizedBox(width: 6.0),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'SCORE: ',
                                style: TextStyle(
                                  color: VoidTheme.textMuted,
                                  fontSize: 9.0,
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
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Right: Cores Gauge & Hostiles Tracker
                  Flexible(
                    flex: 5,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GestureDetector(
                            onTap: onEmergencyFlareTap,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6.0,
                                vertical: 2.5,
                              ),
                              decoration: BoxDecoration(
                                color: VoidTheme.cardSurface,
                                borderRadius: BorderRadius.circular(4.0),
                                border: Border.all(
                                  color: reserveCores <= 5
                                      ? VoidTheme.crimsonFlare
                                      : VoidTheme.solarGold.withValues(
                                          alpha: 0.7,
                                        ),
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
                                      fontSize: 10.0,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 5.0),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6.0,
                              vertical: 2.5,
                            ),
                            decoration: BoxDecoration(
                              color: VoidTheme.cardSurface.withValues(
                                alpha: 0.8,
                              ),
                              borderRadius: BorderRadius.circular(4.0),
                              border: Border.all(
                                color: secured
                                    ? VoidTheme.emeraldShield
                                    : ((invadersRemaining != null &&
                                              invadersRemaining! <= 2)
                                          ? VoidTheme.solarGold
                                          : VoidTheme.textMuted.withValues(
                                              alpha: 0.4,
                                            )),
                                width: 1.0,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  secured
                                      ? Icons.check_circle
                                      : Icons.shield_outlined,
                                  size: 12.0,
                                  color: secured
                                      ? VoidTheme.emeraldShield
                                      : ((invadersRemaining != null &&
                                                invadersRemaining! <= 2)
                                            ? VoidTheme.solarGold
                                            : VoidTheme.textSecondary),
                                ),
                                const SizedBox(width: 3.0),
                                Text(
                                  secured
                                      ? 'SECURED'
                                      : (invadersRemaining != null
                                            ? (totalInvaders != null
                                                  ? '${totalInvaders! - invadersRemaining!}/$totalInvaders HOSTILES'
                                                  : '$invadersRemaining HOSTILES')
                                            : 'DEFENSE GRID'),
                                  style: TextStyle(
                                    color: secured
                                        ? VoidTheme.emeraldShield
                                        : ((invadersRemaining != null &&
                                                  invadersRemaining! <= 2)
                                              ? VoidTheme.solarGold
                                              : VoidTheme.textSecondary),
                                    fontSize: 9.0,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // BAR 3: TACTICAL SIMULATION CONTROLS (UNIVERSAL ACCESS)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8.0,
                vertical: 3.5,
              ),
              color: VoidTheme.obsidianBlack.withValues(alpha: 0.95),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Left: Mission Status Indicator
                  Flexible(
                    flex: 3,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (secured)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7.0,
                                vertical: 2.5,
                              ),
                              decoration: BoxDecoration(
                                color: VoidTheme.emeraldShield.withValues(
                                  alpha: 0.15,
                                ),
                                borderRadius: BorderRadius.circular(4.0),
                                border: Border.all(
                                  color: VoidTheme.emeraldShield,
                                  width: 1.0,
                                ),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.verified,
                                    color: VoidTheme.emeraldShield,
                                    size: 12.0,
                                  ),
                                  SizedBox(width: 3.0),
                                  Text(
                                    'SECTOR SECURED',
                                    style: TextStyle(
                                      color: VoidTheme.emeraldShield,
                                      fontSize: 9.0,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else if (isPaused)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7.0,
                                vertical: 2.5,
                              ),
                              decoration: BoxDecoration(
                                color: VoidTheme.solarGold.withValues(
                                  alpha: 0.15,
                                ),
                                borderRadius: BorderRadius.circular(4.0),
                                border: Border.all(
                                  color: VoidTheme.solarGold,
                                  width: 1.0,
                                ),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.pause_circle_filled,
                                    color: VoidTheme.solarGold,
                                    size: 12.0,
                                  ),
                                  SizedBox(width: 3.0),
                                  Text(
                                    'TIME DILATED',
                                    style: TextStyle(
                                      color: VoidTheme.solarGold,
                                      fontSize: 9.0,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.4,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7.0,
                                vertical: 2.5,
                              ),
                              decoration: BoxDecoration(
                                color: VoidTheme.cardSurface,
                                borderRadius: BorderRadius.circular(4.0),
                                border: Border.all(
                                  color: VoidTheme.plasmaCyan.withValues(
                                    alpha: 0.4,
                                  ),
                                  width: 0.8,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 6.0,
                                    height: 6.0,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: VoidTheme.plasmaCyan,
                                    ),
                                  ),
                                  const SizedBox(width: 4.0),
                                  const Text(
                                    'SORTIE ACTIVE',
                                    style: TextStyle(
                                      color: VoidTheme.plasmaCyan,
                                      fontSize: 9.0,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  // Right: Dynamic Action Controls
                  Flexible(
                    flex: 7,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: secured
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (onNextSectorTap != null)
                                  GestureDetector(
                                    onTap: onNextSectorTap,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 9.0,
                                        vertical: 3.0,
                                      ),
                                      decoration: BoxDecoration(
                                        color: VoidTheme.emeraldShield,
                                        borderRadius: BorderRadius.circular(
                                          4.0,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: VoidTheme.emeraldShield
                                                .withValues(alpha: 0.4),
                                            blurRadius: 6.0,
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            sectorId < 9
                                                ? 'NEXT SECTOR'
                                                : 'REPLAY SECTOR',
                                            style: const TextStyle(
                                              color: VoidTheme.obsidianBlack,
                                              fontSize: 9.5,
                                              fontWeight: FontWeight.w900,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                          const SizedBox(width: 3.0),
                                          const Icon(
                                            Icons.arrow_forward,
                                            color: VoidTheme.obsidianBlack,
                                            size: 13.0,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                if (onRestartTap != null) ...[
                                  const SizedBox(width: 5.0),
                                  GestureDetector(
                                    onTap: onRestartTap,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 7.0,
                                        vertical: 3.0,
                                      ),
                                      decoration: BoxDecoration(
                                        color: VoidTheme.cardSurface,
                                        borderRadius: BorderRadius.circular(
                                          4.0,
                                        ),
                                        border: Border.all(
                                          color: VoidTheme.plasmaCyan,
                                          width: 1.0,
                                        ),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.replay,
                                            color: VoidTheme.plasmaCyan,
                                            size: 12.0,
                                          ),
                                          SizedBox(width: 2.5),
                                          Text(
                                            'REPLAY',
                                            style: TextStyle(
                                              color: VoidTheme.plasmaCyan,
                                              fontSize: 9.0,
                                              fontWeight: FontWeight.w900,
                                              letterSpacing: 0.4,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            )
                          : Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Universal Pause / Resume (Available to Everyone)
                                if (onTogglePause != null)
                                  GestureDetector(
                                    onTap: onTogglePause,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 7.0,
                                        vertical: 3.0,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isPaused
                                            ? VoidTheme.solarGold
                                            : VoidTheme.cardSurface,
                                        borderRadius: BorderRadius.circular(
                                          4.0,
                                        ),
                                        border: Border.all(
                                          color: isPaused
                                              ? VoidTheme.solarGold
                                              : VoidTheme.textMuted.withValues(
                                                  alpha: 0.6,
                                                ),
                                          width: 1.0,
                                        ),
                                        boxShadow: isPaused
                                            ? [
                                                BoxShadow(
                                                  color: VoidTheme.solarGold
                                                      .withValues(alpha: 0.4),
                                                  blurRadius: 4.0,
                                                ),
                                              ]
                                            : null,
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            isPaused
                                                ? Icons.play_arrow
                                                : Icons.pause,
                                            color: isPaused
                                                ? VoidTheme.obsidianBlack
                                                : VoidTheme.starWhite,
                                            size: 12.0,
                                          ),
                                          const SizedBox(width: 2.5),
                                          Text(
                                            isPaused ? 'RESUME' : 'PAUSE',
                                            style: TextStyle(
                                              color: isPaused
                                                  ? VoidTheme.obsidianBlack
                                                  : VoidTheme.starWhite,
                                              fontSize: 9.0,
                                              fontWeight: FontWeight.w900,
                                              letterSpacing: 0.4,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),

                                // Universal Restart Sortie
                                if (onRestartTap != null) ...[
                                  const SizedBox(width: 4.0),
                                  GestureDetector(
                                    onTap: onRestartTap,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6.0,
                                        vertical: 3.0,
                                      ),
                                      decoration: BoxDecoration(
                                        color: VoidTheme.cardSurface,
                                        borderRadius: BorderRadius.circular(
                                          4.0,
                                        ),
                                        border: Border.all(
                                          color: VoidTheme.textMuted.withValues(
                                            alpha: 0.6,
                                          ),
                                          width: 1.0,
                                        ),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.replay,
                                            color: VoidTheme.starWhite,
                                            size: 12.0,
                                          ),
                                          SizedBox(width: 2.0),
                                          Text(
                                            'RESTART',
                                            style: TextStyle(
                                              color: VoidTheme.starWhite,
                                              fontSize: 9.0,
                                              fontWeight: FontWeight.w900,
                                              letterSpacing: 0.3,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],

                                // Universal Stop / Abort Sortie
                                if (onStopTap != null) ...[
                                  const SizedBox(width: 4.0),
                                  GestureDetector(
                                    onTap: onStopTap,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6.0,
                                        vertical: 3.0,
                                      ),
                                      decoration: BoxDecoration(
                                        color: VoidTheme.cardSurface,
                                        borderRadius: BorderRadius.circular(
                                          4.0,
                                        ),
                                        border: Border.all(
                                          color: VoidTheme.crimsonFlare
                                              .withValues(alpha: 0.6),
                                          width: 1.0,
                                        ),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.stop_circle_outlined,
                                            color: VoidTheme.crimsonFlare,
                                            size: 12.0,
                                          ),
                                          SizedBox(width: 2.0),
                                          Text(
                                            'ABORT',
                                            style: TextStyle(
                                              color: VoidTheme.crimsonFlare,
                                              fontSize: 9.0,
                                              fontWeight: FontWeight.w900,
                                              letterSpacing: 0.3,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],

                                // Tactical AI Solver
                                if (onToggleAutoSolve != null) ...[
                                  const SizedBox(width: 4.0),
                                  GestureDetector(
                                    onTap: onToggleAutoSolve,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6.0,
                                        vertical: 3.0,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isAutoSolving
                                            ? VoidTheme.crimsonFlare
                                            : VoidTheme.cardSurface,
                                        borderRadius: BorderRadius.circular(
                                          4.0,
                                        ),
                                        border: Border.all(
                                          color: isAutoSolving
                                              ? VoidTheme.crimsonFlare
                                              : VoidTheme.plasmaCyan.withValues(
                                                  alpha: 0.5,
                                                ),
                                          width: 1.0,
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
                                            size: 12.0,
                                          ),
                                          const SizedBox(width: 2.0),
                                          Text(
                                            'AI',
                                            style: TextStyle(
                                              color: isAutoSolving
                                                  ? VoidTheme.obsidianBlack
                                                  : VoidTheme.plasmaCyanLight,
                                              fontSize: 9.0,
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
                    ),
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
