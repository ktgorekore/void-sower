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

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../services/haptic_service.dart';
import '../theme/void_theme.dart';
import 'tactile_button.dart';

/// Modal overlay presented upon neutralizing all assault craft in a sector wave.
/// Modernized with a sleek, uncluttered profile and high-contrast visuals.
class VictoryDialog extends StatefulWidget {
  const VictoryDialog({
    super.key,
    this.sectorId = 1,
    this.sectorName = 'Zanzibar Reef Gate',
    required this.score,
    this.highScore = 0,
    required this.coresRemaining,
    this.starsEarned = 3,
    this.isNewUnlock = false,
    this.unlockedSectorName,
    this.campaignProgressText,
    this.armDuration = Duration.zero,
    required this.onNextSector,
    this.onReturnToMap,
    this.onDismiss,
    this.canAdvance,
    this.onUpgradePro,
    this.isAiAssisted = false,
  });

  /// 1-based index of the liberated sector.
  final int sectorId;

  /// Human-readable identity of the sector.
  final String sectorName;

  /// Final score accumulated during the mission.
  final int score;

  /// All-time high score recorded in persistent storage.
  final int highScore;

  /// Surplus energy cores retained at wave conclusion.
  final int coresRemaining;

  /// Calculated star performance rating (1 to 3).
  final int starsEarned;

  /// True if completing this wave unlocked a new sector.
  final bool isNewUnlock;

  /// Name of the newly unlocked sector, if applicable.
  final String? unlockedSectorName;

  /// Campaign summary text, e.g. "3 / 9 LIBERATED".
  final String? campaignProgressText;

  /// Safety debounce duration before action buttons accept taps.
  final Duration armDuration;

  /// Callback to advance to the next sector or replay.
  final VoidCallback onNextSector;

  /// Callback to navigate to the Campaign Star Map.
  final VoidCallback? onReturnToMap;

  /// Optional callback when modal is closed to view the battlefield.
  final VoidCallback? onDismiss;

  /// Whether advancing to the next sector is possible (unlocked or Pro).
  final bool? canAdvance;

  /// Optional callback to trigger Pro Commander upgrade flow.
  final VoidCallback? onUpgradePro;

  /// Whether the AI solver was active or used during this sortie.
  final bool isAiAssisted;

  @override
  State<VictoryDialog> createState() => _VictoryDialogState();
}

class _VictoryDialogState extends State<VictoryDialog> {
  bool _isArmed = false;
  Timer? _armTimer;

  @override
  void initState() {
    super.initState();
    if (widget.armDuration == Duration.zero) {
      _isArmed = true;
    } else {
      _armTimer = Timer(widget.armDuration, () {
        if (mounted) {
          setState(() => _isArmed = true);
        }
      });
    }
  }

  @override
  void dispose() {
    _armTimer?.cancel();
    super.dispose();
  }

  String get _starRatingLabel {
    if (widget.isAiAssisted) {
      return 'AI SOLVER • UNRANKED';
    }
    switch (widget.starsEarned) {
      case 3:
        return '★★★ FLAWLESS DEFENSE';
      case 2:
        return '★★☆ HEROIC SORTIE';
      case 1:
      default:
        return '★☆☆ CORRIDOR SURVIVOR';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      alignment: const Alignment(0.0, -0.28),
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            constraints: const BoxConstraints(maxWidth: 340.0),
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 14.0,
            ),
            decoration: BoxDecoration(
              color: VoidTheme.obsidianBlack.withValues(alpha: 0.96),
              borderRadius: BorderRadius.circular(16.0),
              border: Border.all(color: VoidTheme.solarGold, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: VoidTheme.solarGold.withValues(alpha: 0.3),
                  blurRadius: 20.0,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Victory Crest & Title
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 32.0,
                      height: 32.0,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: VoidTheme.solarGold.withValues(alpha: 0.15),
                        border: Border.all(
                          color: VoidTheme.solarGold,
                          width: 1.2,
                        ),
                      ),
                      child: const Icon(
                        Icons.military_tech,
                        color: VoidTheme.solarGold,
                        size: 18.0,
                      ),
                    ),
                    const SizedBox(width: 8.0),
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'SECTOR ${widget.sectorId} LIBERATED!',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: VoidTheme.solarGold,
                              fontSize: 14.0,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.0,
                            ),
                          ),
                          Text(
                            widget.sectorName.toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: VoidTheme.plasmaCyan,
                              fontSize: 10.0,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10.0),

                // Stars Rating Badge
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10.0,
                      vertical: 3.5,
                    ),
                    decoration: BoxDecoration(
                      color: VoidTheme.cardSurface,
                      borderRadius: BorderRadius.circular(12.0),
                      border: Border.all(
                        color: widget.isAiAssisted
                            ? VoidTheme.plasmaCyan.withValues(alpha: 0.5)
                            : VoidTheme.solarGold.withValues(alpha: 0.4),
                        width: 1.0,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!widget.isAiAssisted)
                          Row(
                            children: List.generate(3, (i) {
                              final earned = i < widget.starsEarned;
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 1.0,
                                ),
                                child: Icon(
                                  earned ? Icons.star : Icons.star_border,
                                  color: VoidTheme.solarGold,
                                  size: 13.0,
                                ),
                              );
                            }),
                          )
                        else
                          const Padding(
                            padding: EdgeInsets.only(right: 3.0),
                            child: Icon(
                              Icons.smart_toy,
                              color: VoidTheme.plasmaCyan,
                              size: 12.0,
                            ),
                          ),
                        const SizedBox(width: 4.0),
                        Flexible(
                          child: Text(
                            _starRatingLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: widget.isAiAssisted
                                  ? VoidTheme.plasmaCyan
                                  : VoidTheme.solarGoldLight,
                              fontSize: 9.0,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10.0),

                // Unlock Announcement (Compact Chip)
                if (widget.isNewUnlock &&
                    widget.unlockedSectorName != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8.0,
                      vertical: 5.0,
                    ),
                    decoration: BoxDecoration(
                      color: VoidTheme.emeraldShield.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6.0),
                      border: Border.all(
                        color: VoidTheme.emeraldShield,
                        width: 1.0,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.lock_open,
                          color: VoidTheme.emeraldShield,
                          size: 14.0,
                        ),
                        const SizedBox(width: 5.0),
                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'NEW SECTOR UNLOCKED!',
                                style: TextStyle(
                                  color: VoidTheme.emeraldShield,
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              Text(
                                'Sector ${widget.sectorId + 1}: ${widget.unlockedSectorName!.toUpperCase()}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: VoidTheme.starWhite,
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10.0),
                ],

                // Score & Cores Stats Row (Unified 3-Column Stats Capsule)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8.0,
                    vertical: 6.0,
                  ),
                  decoration: BoxDecoration(
                    color: VoidTheme.cardSurface.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(8.0),
                    border: Border.all(
                      color: VoidTheme.cardSurface,
                      width: 1.0,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: _buildStatColumn(
                          'MISSION SCORE',
                          widget.isAiAssisted ? 'UNRANKED' : '${widget.score}',
                          widget.isAiAssisted
                              ? VoidTheme.textMuted
                              : VoidTheme.textPrimary,
                        ),
                      ),
                      Container(
                        width: 1.0,
                        height: 22.0,
                        color: VoidTheme.cardSurface,
                      ),
                      Expanded(
                        child: _buildStatColumn(
                          (!widget.isAiAssisted &&
                                  widget.score >= widget.highScore &&
                                  widget.score > 0)
                              ? '★ NEW RECORD'
                              : 'HIGH SCORE',
                          widget.isAiAssisted
                              ? '${widget.highScore}'
                              : '${math.max(widget.score, widget.highScore)}',
                          VoidTheme.solarGold,
                        ),
                      ),
                      Container(
                        width: 1.0,
                        height: 22.0,
                        color: VoidTheme.cardSurface,
                      ),
                      Expanded(
                        child: _buildStatColumn(
                          'CORES SAVED',
                          '${widget.coresRemaining}',
                          VoidTheme.plasmaCyan,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12.0),

                // Action Buttons
                Builder(
                  builder: (context) {
                    final canAdvance =
                        widget.canAdvance ?? (widget.sectorId < 9);
                    return TactileButton(
                      label: canAdvance
                          ? 'ADVANCE TO NEXT SECTOR'
                          : 'REPLAY SECTOR',
                      icon: canAdvance ? Icons.navigate_next : Icons.replay,
                      onPressed: _isArmed ? widget.onNextSector : null,
                      accentColor: _isArmed
                          ? VoidTheme.solarGold
                          : VoidTheme.solarGold.withValues(alpha: 0.4),
                      minWidth: double.infinity,
                      height: 40.0,
                    );
                  },
                ),
                if (widget.onReturnToMap != null) ...[
                  const SizedBox(height: 6.0),
                  TactileButton(
                    label: 'RETURN TO STAR MAP',
                    icon: Icons.map_outlined,
                    onPressed: _isArmed ? widget.onReturnToMap! : null,
                    accentColor: _isArmed
                        ? VoidTheme.plasmaCyan
                        : VoidTheme.plasmaCyan.withValues(alpha: 0.4),
                    isPrimary: false,
                    minWidth: double.infinity,
                    height: 36.0,
                  ),
                ],
                if (widget.onUpgradePro != null) ...[
                  const SizedBox(height: 6.0),
                  TactileButton(
                    label: 'UNLOCK ALL SECTORS • PRO',
                    icon: Icons.workspace_premium,
                    onPressed: _isArmed ? widget.onUpgradePro! : null,
                    accentColor: _isArmed
                        ? VoidTheme.solarGold
                        : VoidTheme.solarGold.withValues(alpha: 0.4),
                    minWidth: double.infinity,
                    height: 36.0,
                  ),
                ],
              ],
            ),
          ),
          Positioned(
            top: 2.0,
            right: 2.0,
            child: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(5.0),
                decoration: BoxDecoration(
                  color: VoidTheme.cardSurface,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: VoidTheme.textMuted.withValues(alpha: 0.5),
                    width: 1.0,
                  ),
                ),
                child: const Icon(
                  Icons.close,
                  color: VoidTheme.textSecondary,
                  size: 14.0,
                ),
              ),
              constraints: const BoxConstraints(
                minWidth: 40.0,
                minHeight: 40.0,
              ),
              tooltip: 'Dismiss',
              onPressed: () {
                HapticService.instance.sowTick();
                if (widget.onDismiss != null) {
                  widget.onDismiss!();
                } else {
                  Navigator.of(context).pop();
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, Color valueColor) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: VoidTheme.textMuted,
            fontSize: 7.5,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 1.0),
        Text(
          value,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: valueColor,
            fontSize: 14.0,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}
