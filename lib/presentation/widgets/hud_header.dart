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
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../domain/models/user_profile.dart';
import '../../domain/services/persistence_service.dart';
import '../theme/void_theme.dart';

/// Streamlined "Split-Wing" Tactical HUD Header.
///
/// Anchors mission identity & score to the Top-Left Wing, survival telemetry &
/// single-point simulation controls to the Top-Right Wing, leaving the critical
/// center combat corridor 100% unobstructed for incoming hostile craft.
class HudHeader extends StatelessWidget {
  const HudHeader({
    super.key,
    required this.reserveCores,
    required this.score,
    this.highScore = 0,
    this.isPro = false,
    required this.difficultyTier,
    this.sectorId = 1,
    this.sectorName = 'Zanzibar Reef Gate',
    this.userProfile,
    this.onProfileTap,
    this.invadersRemaining,
    this.totalInvaders,
    this.isPaused = false,
    this.onTogglePause,
    this.isAutoSolving = false,
    this.onToggleAutoSolve,
    this.isSecured = false,
    this.onNextSectorTap,
    this.onSettingsTap,
    this.onMapTap,
    this.onRestartTap,
    this.onStopTap,
    this.onCodexTap,
    this.onTutorialTap,
    this.onEmergencyFlareTap,
  });

  final int reserveCores;
  final int score;
  final int highScore;
  final bool isPro;
  final int difficultyTier;
  final int sectorId;
  final String sectorName;
  final UserProfile? userProfile;
  final VoidCallback? onProfileTap;
  final int? invadersRemaining;
  final int? totalInvaders;
  final bool isPaused;
  final VoidCallback? onTogglePause;
  final bool isAutoSolving;
  final VoidCallback? onToggleAutoSolve;
  final bool isSecured;
  final VoidCallback? onNextSectorTap;

  // Additional/legacy meta action delegates (can be triggered via Pause Menu)
  final VoidCallback? onSettingsTap;
  final VoidCallback? onMapTap;
  final VoidCallback? onRestartTap;
  final VoidCallback? onStopTap;
  final VoidCallback? onCodexTap;
  final VoidCallback? onTutorialTap;
  final VoidCallback? onEmergencyFlareTap;

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

  /// Formats raw score into prominent 6-digit grouped typography (e.g. 004,820).
  static String formatScore(int score) {
    final clamped = score.clamp(0, 999999);
    final str = clamped.toString().padLeft(6, '0');
    return '${str.substring(0, 3)},${str.substring(3)}';
  }

  @override
  Widget build(BuildContext context) {
    final profile = userProfile ?? const UserProfile();
    final bool secured =
        isSecured || (invadersRemaining != null && invadersRemaining == 0);

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // 1. TOP LEFT WING: Mission Micro-Badge, Prominent Score & Pilot Callsign
            _buildLeftWing(profile, secured),

            // 2. OPEN CENTER CHANNEL: 100% unobstructed spawn sightline for incoming hostiles
            const Spacer(),

            // 3. TOP RIGHT WING: Cores Micro-Gauge, Hostiles & One-Button Pause/AI Controls
            _buildRightWing(secured),
          ],
        ),
      ),
    );
  }

  /// Builds the glassmorphic Top-Left Wing anchoring mission identity, current score & all-time high score.
  Widget _buildLeftWing(UserProfile profile, bool secured) {
    final effectiveIsPro = isPro || PersistenceService.instance.isProUnlocked;
    final callsignText = profile.callsign.isNotEmpty
        ? profile.callsign.toUpperCase()
        : 'VANGUARD-01';
    final effectiveHighScore = math.max(score, highScore);
    final isNewRecord = score >= highScore && score > 0;

    return ClipRRect(
      borderRadius: BorderRadius.circular(10.0),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 7.5, vertical: 5.0),
          decoration: BoxDecoration(
            color: VoidTheme.obsidianBlack.withValues(alpha: 0.65),
            borderRadius: BorderRadius.circular(10.0),
            border: Border.all(
              color: secured
                  ? VoidTheme.emeraldShield.withValues(alpha: 0.4)
                  : VoidTheme.plasmaCyan.withValues(alpha: 0.25),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color:
                    (secured ? VoidTheme.emeraldShield : VoidTheme.plasmaCyan)
                        .withValues(alpha: 0.12),
                blurRadius: 10.0,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Mission Micro-Badge & Pilot Callsign with Person Icon & PRO Badge
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 5.0,
                    height: 5.0,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: secured
                          ? VoidTheme.emeraldShield
                          : VoidTheme.plasmaCyan,
                      boxShadow: [
                        BoxShadow(
                          color:
                              (secured
                                      ? VoidTheme.emeraldShield
                                      : VoidTheme.plasmaCyan)
                                  .withValues(alpha: 0.8),
                          blurRadius: 4.0,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4.0),
                  Text(
                    'S$sectorId • $tierName',
                    style: TextStyle(
                      color: secured
                          ? VoidTheme.emeraldShield
                          : VoidTheme.plasmaCyan,
                      fontSize: 8.0,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(width: 3.0),
                  Text(
                    '•',
                    style: TextStyle(
                      color: VoidTheme.textMuted.withValues(alpha: 0.4),
                      fontSize: 7.0,
                    ),
                  ),
                  const SizedBox(width: 3.0),
                  GestureDetector(
                    onTap: onProfileTap,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.person,
                          size: 8.5,
                          color: effectiveIsPro
                              ? VoidTheme.solarGold
                              : VoidTheme.plasmaCyan.withValues(alpha: 0.8),
                        ),
                        const SizedBox(width: 2.0),
                        ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: effectiveIsPro ? 44.0 : 54.0,
                          ),
                          child: Text(
                            callsignText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: effectiveIsPro
                                  ? VoidTheme.starWhite
                                  : VoidTheme.textMuted.withValues(alpha: 0.85),
                              fontSize: 7.0,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                        if (effectiveIsPro) ...[
                          const SizedBox(width: 3.0),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 3.0,
                              vertical: 0.5,
                            ),
                            decoration: BoxDecoration(
                              color: VoidTheme.solarGold.withValues(
                                alpha: 0.22,
                              ),
                              borderRadius: BorderRadius.circular(3.0),
                              border: Border.all(
                                color: VoidTheme.solarGold.withValues(
                                  alpha: 0.85,
                                ),
                                width: 0.6,
                              ),
                            ),
                            child: const Text(
                              'PRO',
                              style: TextStyle(
                                color: VoidTheme.solarGold,
                                fontSize: 6.5,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2.0),

              // Primary Current Score Row: "SCORE" micro-label + 6-digit score
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  const Text(
                    'SCORE',
                    style: TextStyle(
                      color: VoidTheme.plasmaCyanLight,
                      fontSize: 7.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(width: 4.0),
                  Text(
                    formatScore(score),
                    style: const TextStyle(
                      color: VoidTheme.starWhite,
                      fontSize: 15.0,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.6,
                      shadows: [
                        Shadow(
                          color: VoidTheme.plasmaCyanLight,
                          blurRadius: 6.0,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 1.0),

              // All-Time High Score Sub-Row: Trophy + "HI-SCORE" + 6-digit high score
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.emoji_events,
                    size: 8.5,
                    color: isNewRecord
                        ? VoidTheme.solarGold
                        : VoidTheme.solarGold.withValues(alpha: 0.75),
                  ),
                  const SizedBox(width: 2.5),
                  Text(
                    isNewRecord ? 'HI-SCORE ★' : 'HI-SCORE',
                    style: TextStyle(
                      color: isNewRecord
                          ? VoidTheme.solarGold
                          : VoidTheme.solarGold.withValues(alpha: 0.85),
                      fontSize: 7.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(width: 3.5),
                  Text(
                    formatScore(effectiveHighScore),
                    style: TextStyle(
                      color: isNewRecord
                          ? VoidTheme.solarGold
                          : VoidTheme.solarGold.withValues(alpha: 0.9),
                      fontSize: 10.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                      shadows: isNewRecord
                          ? const [
                              Shadow(
                                color: VoidTheme.solarGold,
                                blurRadius: 6.0,
                              ),
                            ]
                          : null,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the glassmorphic Top-Right Wing anchoring survival telemetry and controls.
  Widget _buildRightWing(bool secured) {
    final remaining = invadersRemaining ?? 0;
    final total = totalInvaders ?? 0;
    final eliminated = total > remaining ? total - remaining : 0;
    final coreFill = (reserveCores / 50.0).clamp(0.0, 1.0);
    final coreColor = reserveCores <= 5
        ? VoidTheme.crimsonFlare
        : VoidTheme.solarGold;

    return ClipRRect(
      borderRadius: BorderRadius.circular(10.0),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8.5, vertical: 5.5),
          decoration: BoxDecoration(
            color: VoidTheme.obsidianBlack.withValues(alpha: 0.65),
            borderRadius: BorderRadius.circular(10.0),
            border: Border.all(
              color: secured
                  ? VoidTheme.emeraldShield.withValues(alpha: 0.4)
                  : VoidTheme.solarGold.withValues(alpha: 0.25),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: (secured ? VoidTheme.emeraldShield : VoidTheme.solarGold)
                    .withValues(alpha: 0.12),
                blurRadius: 10.0,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Energy Cores Micro-Gauge with 4px Progress Bar
              GestureDetector(
                onTap: onEmergencyFlareTap,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.bolt, size: 13.0, color: coreColor),
                        const SizedBox(width: 1.0),
                        Text(
                          '$reserveCores/50',
                          style: TextStyle(
                            color: coreColor,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2.0),
                    // 4px-high progress bar
                    Container(
                      width: 86.0,
                      height: 3.5,
                      decoration: BoxDecoration(
                        color: VoidTheme.cardSurface,
                        borderRadius: BorderRadius.circular(2.0),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: coreFill,
                        child: Container(
                          decoration: BoxDecoration(
                            color: coreColor,
                            borderRadius: BorderRadius.circular(2.0),
                            boxShadow: [
                              BoxShadow(
                                color: coreColor.withValues(alpha: 0.5),
                                blurRadius: 4.0,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 1.0),
                    Text(
                      'ENERGY CORES',
                      style: TextStyle(
                        color: VoidTheme.textMuted.withValues(alpha: 0.8),
                        fontSize: 7.0,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 5.0),

              // Bottom Row: Hostiles & Controls (AI + Pause)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Hostiles Micro-Indicator / Clean SECURED Status
                  GestureDetector(
                    onTap: secured ? onNextSectorTap : null,
                    child: Container(
                      padding: secured
                          ? const EdgeInsets.symmetric(
                              horizontal: 6.0,
                              vertical: 2.0,
                            )
                          : EdgeInsets.zero,
                      decoration: secured
                          ? BoxDecoration(
                              color: VoidTheme.emeraldShield.withValues(
                                alpha: 0.18,
                              ),
                              borderRadius: BorderRadius.circular(4.0),
                              border: Border.all(
                                color: VoidTheme.emeraldShield.withValues(
                                  alpha: 0.6,
                                ),
                                width: 0.8,
                              ),
                            )
                          : null,
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
                                : (remaining <= 2
                                      ? VoidTheme.solarGold
                                      : VoidTheme.crimsonFlare),
                          ),
                          const SizedBox(width: 3.0),
                          Text(
                            secured
                                ? 'SECURED'
                                : (total > 0
                                      ? '$eliminated/$total'
                                      : '$remaining'),
                            style: TextStyle(
                              color: secured
                                  ? VoidTheme.emeraldShield
                                  : (remaining <= 2
                                        ? VoidTheme.solarGold
                                        : VoidTheme.starWhite),
                              fontSize: 10.0,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // AI Tactical Auto-Solver Toggle Switch (active combat only)
                  if (!secured && onToggleAutoSolve != null) ...[
                    const SizedBox(width: 8.0),
                    GestureDetector(
                      onTap: onToggleAutoSolve,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5.5,
                          vertical: 2.5,
                        ),
                        decoration: BoxDecoration(
                          color: isAutoSolving
                              ? VoidTheme.crimsonFlare
                              : VoidTheme.cardSurface.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(4.0),
                          border: Border.all(
                            color: isAutoSolving
                                ? VoidTheme.crimsonFlare
                                : VoidTheme.plasmaCyan.withValues(alpha: 0.4),
                            width: 1.0,
                          ),
                          boxShadow: isAutoSolving
                              ? [
                                  BoxShadow(
                                    color: VoidTheme.crimsonFlare.withValues(
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
                              Icons.smart_toy,
                              size: 11.0,
                              color: isAutoSolving
                                  ? VoidTheme.obsidianBlack
                                  : VoidTheme.plasmaCyanLight,
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

                  // Single Pause Button [ ⏸ ] (active combat only)
                  if (!secured && onTogglePause != null) ...[
                    const SizedBox(width: 6.0),
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
                              : VoidTheme.cardSurface.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(4.0),
                          border: Border.all(
                            color: isPaused
                                ? VoidTheme.solarGold
                                : VoidTheme.textSecondary.withValues(
                                    alpha: 0.5,
                                  ),
                            width: 1.0,
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
                              size: 12.0,
                              color: isPaused
                                  ? VoidTheme.obsidianBlack
                                  : VoidTheme.starWhite,
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
                                letterSpacing: 0.3,
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
      ),
    );
  }
}
