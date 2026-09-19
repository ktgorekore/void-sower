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

import '../theme/void_theme.dart';
import 'tactile_button.dart';

/// Modal overlay presented when enemy vessels breach the orbital boundary or
/// plasma ammunition is exhausted.
///
/// Anchored to the upper-middle viewport (`Alignment(0.0, -0.32)`) with a 500ms
/// safety debounce delay to prevent in-flight shooting taps from triggering
/// accidental retries or navigation.
class GameOverDialog extends StatefulWidget {
  const GameOverDialog({
    super.key,
    required this.score,
    this.highScore = 0,
    required this.onRetry,
    required this.onReturnToMap,
    this.isAmmoDepleted = false,
    this.isAiAssisted = false,
    this.armDuration = const Duration(milliseconds: 500),
  });

  /// Mission score attained prior to defeat.
  final int score;

  /// All-time high score recorded in persistent storage.
  final int highScore;

  /// Callback to retry the current sector wave.
  final VoidCallback onRetry;

  /// Callback to navigate back to the Campaign Star Map.
  final VoidCallback onReturnToMap;

  /// Whether defeat was triggered by ammunition exhaustion rather than breach.
  final bool isAmmoDepleted;

  /// Whether the AI solver was active or used during this sortie.
  final bool isAiAssisted;

  /// Safety debounce duration before action buttons accept taps.
  final Duration armDuration;

  @override
  State<GameOverDialog> createState() => _GameOverDialogState();
}

class _GameOverDialogState extends State<GameOverDialog> {
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

  @override
  Widget build(BuildContext context) {
    final isNewRecord =
        !widget.isAiAssisted &&
        widget.score >= widget.highScore &&
        widget.score > 0;
    final effectiveHighScore = widget.isAiAssisted
        ? widget.highScore
        : math.max(widget.score, widget.highScore);
    final accentColor = widget.isAmmoDepleted
        ? VoidTheme.solarGold
        : VoidTheme.crimsonFlare;

    return Dialog(
      alignment: const Alignment(0.0, -0.32),
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 340.0),
        padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 16.0),
        decoration: BoxDecoration(
          color: VoidTheme.obsidianBlack,
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(color: accentColor, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: accentColor.withValues(alpha: 0.3),
              blurRadius: 20.0,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              widget.isAmmoDepleted ? Icons.bolt : Icons.warning_amber_rounded,
              color: accentColor,
              size: 38.0,
            ),
            const SizedBox(height: 8.0),
            Text(
              widget.isAmmoDepleted ? 'CORES EXHAUSTED' : 'ORBITAL BREACH',
              style: TextStyle(
                color: accentColor,
                fontSize: 17.0,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 4.0),
            Text(
              widget.isAmmoDepleted
                  ? 'Reserve plasma cores depleted with zero ordnance remaining.'
                  : 'Atmospheric boundary compromised by enemy assault craft.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: VoidTheme.textSecondary,
                fontSize: 11.5,
              ),
            ),
            const SizedBox(height: 12.0),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12.0,
                vertical: 8.0,
              ),
              decoration: BoxDecoration(
                color: VoidTheme.cardSurface.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(color: VoidTheme.cardSurface, width: 1.0),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.isAiAssisted
                        ? 'AI SIMULATION • UNRANKED'
                        : 'FINAL SCORE: ${widget.score}',
                    style: const TextStyle(
                      color: VoidTheme.solarGold,
                      fontSize: 16.0,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 2.0),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.emoji_events,
                        size: 12.0,
                        color: isNewRecord
                            ? VoidTheme.solarGold
                            : VoidTheme.textMuted,
                      ),
                      const SizedBox(width: 4.0),
                      Flexible(
                        child: Text(
                          isNewRecord
                              ? '🏆 NEW ALL-TIME HIGH SCORE!'
                              : (widget.isAiAssisted
                                    ? 'ALL-TIME HIGH SCORE: ${widget.highScore}'
                                    : 'ALL-TIME HIGH SCORE: $effectiveHighScore'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: isNewRecord
                                ? VoidTheme.solarGold
                                : VoidTheme.textSecondary,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10.0),
            Text(
              widget.isAmmoDepleted
                  ? 'TIP: Build mass along backline for quadratic cascades.'
                  : 'TIP: Sowing into Nyumba (Bays 3 & 4) stores massive charges.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: VoidTheme.textMuted,
                fontSize: 10.0,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 16.0),
            Row(
              children: [
                Expanded(
                  child: TactileButton(
                    label: 'SECTOR MAP',
                    onPressed: _isArmed ? widget.onReturnToMap : null,
                    accentColor: _isArmed
                        ? VoidTheme.textSecondary
                        : VoidTheme.textSecondary.withValues(alpha: 0.35),
                    isPrimary: false,
                    height: 40.0,
                  ),
                ),
                const SizedBox(width: 10.0),
                Expanded(
                  child: TactileButton(
                    label: 'TRY AGAIN',
                    icon: Icons.refresh,
                    onPressed: _isArmed ? widget.onRetry : null,
                    accentColor: _isArmed
                        ? VoidTheme.crimsonFlare
                        : VoidTheme.crimsonFlare.withValues(alpha: 0.35),
                    height: 40.0,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
