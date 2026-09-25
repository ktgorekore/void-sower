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
    this.isAiAssisted = false,
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
  final bool isAiAssisted;
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

  String get sectorBadgeText {
    if (sectorId >= 19) return 'SWARM • S$sectorId';
    if (sectorId >= 10) return 'DRIFT • S$sectorId';
    return 'S$sectorId • $tierName';
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
      child: LayoutBuilder(
        builder: (context, constraints) {
          final row = IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // 1. TOP LEFT WING: Pilot Callsign, Mission Micro-Badge, Score & Hi-Score
                _buildLeftWing(profile, secured),

                // 2. OPEN CENTER CHANNEL: 100% unobstructed spawn sightline for incoming hostiles
                const Spacer(),

                // 3. TOP RIGHT WING: Cores Micro-Gauge, Hostiles & Simulation Controls
                _buildRightWing(secured),
              ],
            ),
          );

          if (constraints.maxWidth < 490.0) {
            return Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 4.0,
                vertical: 2.0,
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.topCenter,
                child: SizedBox(width: 490.0, child: row),
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: row,
          );
        },
      ),
    );
  }

  /// Builds the glassmorphic Top-Left Minimal Orbit Wing anchoring current score & sector.
  Widget _buildLeftWing(UserProfile profile, bool secured) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 5.0),
      decoration: BoxDecoration(
        color: VoidTheme.obsidianBlack.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(
          color: secured
              ? VoidTheme.emeraldShield.withValues(alpha: 0.45)
              : VoidTheme.plasmaCyan.withValues(alpha: 0.35),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: (secured ? VoidTheme.emeraldShield : VoidTheme.plasmaCyan)
                .withValues(alpha: 0.15),
            blurRadius: 10.0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Primary Current Score: "SCORE" micro-label + 6-digit score (or AI SIM / UNRANKED)
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                isAiAssisted ? 'AI SIM' : 'SCORE',
                style: TextStyle(
                  color: isAiAssisted
                      ? VoidTheme.solarGold
                      : VoidTheme.plasmaCyanLight,
                  fontSize: 8.0,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(width: 5.0),
              Text(
                isAiAssisted ? 'UNRANKED' : formatScore(score),
                style: TextStyle(
                  color: isAiAssisted
                      ? VoidTheme.solarGold
                      : VoidTheme.starWhite,
                  fontSize: isAiAssisted ? 13.0 : 15.0,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.6,
                  shadows: [
                    Shadow(
                      color: isAiAssisted
                          ? VoidTheme.solarGold
                          : VoidTheme.plasmaCyanLight,
                      blurRadius: 6.0,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 2.0),

          // Sector Badge & Sector Name
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
                sectorBadgeText,
                style: TextStyle(
                  color: secured
                      ? VoidTheme.emeraldShield
                      : VoidTheme.plasmaCyan,
                  fontSize: 8.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.3,
                ),
              ),
              if (sectorName.isNotEmpty && sectorName != tierName) ...[
                const SizedBox(width: 4.0),
                Text(
                  '•',
                  style: TextStyle(
                    color: VoidTheme.textMuted.withValues(alpha: 0.5),
                    fontSize: 7.5,
                  ),
                ),
                const SizedBox(width: 4.0),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 90.0),
                  child: Text(
                    sectorName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: VoidTheme.textSecondary,
                      fontSize: 8.5,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  /// Builds the glassmorphic Top-Right Minimal Orbit Wing anchoring fuel cores, hostiles & pause control.
  Widget _buildRightWing(bool secured) {
    final remaining = invadersRemaining ?? 0;
    final total = totalInvaders ?? 0;
    final eliminated = total > remaining ? total - remaining : 0;
    final coreColor = reserveCores <= 5
        ? VoidTheme.crimsonFlare
        : VoidTheme.solarGold;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
      decoration: BoxDecoration(
        color: VoidTheme.obsidianBlack.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(
          color: secured
              ? VoidTheme.emeraldShield.withValues(alpha: 0.45)
              : VoidTheme.solarGold.withValues(alpha: 0.35),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: (secured ? VoidTheme.emeraldShield : VoidTheme.solarGold)
                .withValues(alpha: 0.15),
            blurRadius: 10.0,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 1. Elimination tracker or SECURED badge
          if (secured)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onNextSectorTap,
              child: Container(
                height: 28.0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10.0,
                  vertical: 4.0,
                ),
                decoration: BoxDecoration(
                  color: VoidTheme.emeraldShield.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(14.0),
                  border: Border.all(
                    color: VoidTheme.emeraldShield.withValues(alpha: 0.8),
                    width: 1.0,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(
                      Icons.check_circle,
                      size: 13.0,
                      color: VoidTheme.emeraldShield,
                    ),
                    SizedBox(width: 4.0),
                    Text(
                      'SECURED',
                      style: TextStyle(
                        color: VoidTheme.emeraldShield,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else if (total > 0 || invadersRemaining != null)
            Container(
              height: 28.0,
              padding: const EdgeInsets.symmetric(
                horizontal: 8.0,
                vertical: 4.0,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(14.0),
                border: Border.all(
                  color:
                      (remaining <= 2
                              ? VoidTheme.solarGold
                              : const Color(0xFF00E5FF))
                          .withValues(alpha: 0.4),
                  width: 1.0,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.shield_outlined,
                    size: 13.0,
                    color: remaining <= 2
                        ? VoidTheme.solarGold
                        : const Color(0xFF38BDF8),
                  ),
                  const SizedBox(width: 4.0),
                  Text(
                    total > 0 ? '$eliminated/$total' : '$remaining',
                    style: const TextStyle(
                      color: VoidTheme.starWhite,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(width: 6.0),

          // 2. Integrated Core Fuel Gauge: ⚡ 28 CORES Pill
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onEmergencyFlareTap,
            child: Container(
              height: 28.0,
              padding: const EdgeInsets.symmetric(
                horizontal: 10.0,
                vertical: 4.0,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(14.0),
                border: Border.all(color: const Color(0xFF0284C7), width: 1.2),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7.0,
                    height: 7.0,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: coreColor,
                      boxShadow: [
                        BoxShadow(
                          color: coreColor.withValues(alpha: 0.8),
                          blurRadius: 4.0,
                          spreadRadius: 0.5,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 5.0),
                  Text(
                    '$reserveCores',
                    style: TextStyle(
                      color: coreColor,
                      fontSize: 13.0,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(width: 4.0),
                  Text(
                    'CORES',
                    style: TextStyle(
                      color: coreColor.withValues(alpha: 0.75),
                      fontSize: 8.0,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 3. Single Streamlined Circular Pause Button [ ⏸ ]
          if (onTogglePause != null) ...[
            const SizedBox(width: 6.0),
            Tooltip(
              message: isPaused ? 'Resume Sortie' : 'Pause Sortie',
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onTogglePause,
                child: Container(
                  width: 28.0,
                  height: 28.0,
                  decoration: BoxDecoration(
                    color: isPaused
                        ? VoidTheme.emeraldShield.withValues(alpha: 0.25)
                        : const Color(0xFF1E293B).withValues(alpha: 0.7),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isPaused
                          ? VoidTheme.emeraldShield
                          : VoidTheme.solarGold.withValues(alpha: 0.5),
                      width: 1.0,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      isPaused ? Icons.play_arrow : Icons.pause,
                      size: 15.0,
                      color: isPaused
                          ? VoidTheme.emeraldShield
                          : VoidTheme.solarGold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
