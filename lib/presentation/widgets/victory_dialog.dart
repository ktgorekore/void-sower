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
  });

  final int sectorId;
  final String sectorName;
  final int score;
  final int highScore;
  final int coresRemaining;
  final int starsEarned;
  final bool isNewUnlock;
  final String? unlockedSectorName;
  final String? campaignProgressText;

  /// Safety debounce duration before action buttons accept taps.
  final Duration armDuration;

  final VoidCallback onNextSector;
  final VoidCallback? onReturnToMap;
  final VoidCallback? onDismiss;

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
      // 500ms safety arming delay to prevent accidental button clicks from shooting taps
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
      alignment: const Alignment(0.0, -0.32),
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            constraints: const BoxConstraints(maxWidth: 420.0),
            padding: const EdgeInsets.all(22.0),
            decoration: BoxDecoration(
              color: VoidTheme.obsidianBlack,
              borderRadius: BorderRadius.circular(16.0),
              border: Border.all(color: VoidTheme.solarGold, width: 2.0),
              boxShadow: [
                BoxShadow(
                  color: VoidTheme.solarGold.withValues(alpha: 0.35),
                  blurRadius: 24.0,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Victory Crest & Title
                Center(
                  child: Container(
                    width: 64.0,
                    height: 64.0,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: VoidTheme.solarGold.withValues(alpha: 0.15),
                      border: Border.all(
                        color: VoidTheme.solarGold,
                        width: 2.0,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: VoidTheme.solarGold.withValues(alpha: 0.4),
                          blurRadius: 16.0,
                          spreadRadius: 2.0,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.military_tech,
                      color: VoidTheme.solarGold,
                      size: 40.0,
                    ),
                  ),
                ),
                const SizedBox(height: 12.0),
                Text(
                  'SECTOR ${widget.sectorId} LIBERATED!',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: VoidTheme.solarGold,
                    fontSize: 20.0,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 2.0),
                Text(
                  widget.sectorName.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: VoidTheme.plasmaCyan,
                    fontSize: 12.0,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 12.0),

                // Stars Rating Badge
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14.0,
                      vertical: 6.0,
                    ),
                    decoration: BoxDecoration(
                      color: VoidTheme.cardSurface,
                      borderRadius: BorderRadius.circular(20.0),
                      border: Border.all(
                        color: VoidTheme.solarGold.withValues(alpha: 0.5),
                        width: 1.0,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: List.generate(3, (i) {
                            final earned = i < widget.starsEarned;
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 2.0,
                              ),
                              child: Icon(
                                earned ? Icons.star : Icons.star_border,
                                color: VoidTheme.solarGold,
                                size: 18.0,
                              ),
                            );
                          }),
                        ),
                        const SizedBox(width: 8.0),
                        Text(
                          _starRatingLabel,
                          style: const TextStyle(
                            color: VoidTheme.solarGoldLight,
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14.0),

                // Progress Banner: New Unlock or Campaign Summary
                if (widget.isNewUnlock &&
                    widget.unlockedSectorName != null) ...[
                  Container(
                    padding: const EdgeInsets.all(10.0),
                    decoration: BoxDecoration(
                      color: VoidTheme.emeraldShield.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10.0),
                      border: Border.all(
                        color: VoidTheme.emeraldShield,
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: VoidTheme.emeraldShield.withValues(
                            alpha: 0.25,
                          ),
                          blurRadius: 10.0,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.lock_open,
                          color: VoidTheme.emeraldShield,
                          size: 20.0,
                        ),
                        const SizedBox(width: 8.0),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'NEW SECTOR UNLOCKED!',
                                style: TextStyle(
                                  color: VoidTheme.emeraldShield,
                                  fontSize: 10.0,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.8,
                                ),
                              ),
                              Text(
                                'Sector ${widget.sectorId + 1}: ${widget.unlockedSectorName!.toUpperCase()}',
                                style: const TextStyle(
                                  color: VoidTheme.starWhite,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12.0),
                ] else if (widget.campaignProgressText != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10.0,
                      vertical: 6.0,
                    ),
                    decoration: BoxDecoration(
                      color: VoidTheme.cardSurface.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(8.0),
                      border: Border.all(
                        color: VoidTheme.textMuted.withValues(alpha: 0.4),
                        width: 0.8,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        'CAMPAIGN PROGRESS: ${widget.campaignProgressText}',
                        style: const TextStyle(
                          color: VoidTheme.textSecondary,
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12.0),
                ],

                // Score & Cores Stats Row: Mission Score + High Score + Cores Saved
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: _buildStatColumn(
                        'MISSION SCORE',
                        '${widget.score}',
                        VoidTheme.textPrimary,
                      ),
                    ),
                    Container(
                      width: 1.0,
                      height: 32.0,
                      color: VoidTheme.cardSurface,
                    ),
                    Expanded(
                      child: _buildStatColumn(
                        (widget.score >= widget.highScore && widget.score > 0)
                            ? '★ NEW RECORD'
                            : 'HIGH SCORE',
                        '${math.max(widget.score, widget.highScore)}',
                        VoidTheme.solarGold,
                      ),
                    ),
                    Container(
                      width: 1.0,
                      height: 32.0,
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
                const SizedBox(height: 20.0),

                // Action Buttons
                TactileButton(
                  label: widget.sectorId < 9
                      ? 'ADVANCE TO NEXT SECTOR'
                      : 'REPLAY SECTOR',
                  icon: Icons.navigate_next,
                  onPressed: _isArmed ? widget.onNextSector : null,
                  accentColor: _isArmed
                      ? VoidTheme.solarGold
                      : VoidTheme.solarGold.withValues(alpha: 0.45),
                  minWidth: double.infinity,
                  height: 46.0,
                ),
                if (widget.onReturnToMap != null) ...[
                  const SizedBox(height: 8.0),
                  TactileButton(
                    label: 'RETURN TO STAR MAP',
                    icon: Icons.map_outlined,
                    onPressed: _isArmed ? widget.onReturnToMap! : null,
                    accentColor: _isArmed
                        ? VoidTheme.plasmaCyan
                        : VoidTheme.plasmaCyan.withValues(alpha: 0.45),
                    isPrimary: false,
                    minWidth: double.infinity,
                    height: 42.0,
                  ),
                ],
              ],
            ),
          ),
          Positioned(
            top: 4.0,
            right: 4.0,
            child: IconButton(
              icon: Container(
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
              constraints: const BoxConstraints(
                minWidth: 48.0,
                minHeight: 48.0,
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
            fontSize: 9.0,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 2.0),
        Text(
          value,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: valueColor,
            fontSize: 18.0,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}
