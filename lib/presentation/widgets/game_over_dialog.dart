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

/// Modal overlay presented when enemy vessels breach the orbital boundary.
class GameOverDialog extends StatelessWidget {
  const GameOverDialog({
    super.key,
    required this.score,
    this.highScore = 0,
    required this.onRetry,
    required this.onReturnToMap,
    this.isAmmoDepleted = false,
  });

  final int score;
  final int highScore;
  final VoidCallback onRetry;
  final VoidCallback onReturnToMap;
  final bool isAmmoDepleted;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Container(
        padding: const EdgeInsets.all(24.0),
        decoration: BoxDecoration(
          color: VoidTheme.obsidianBlack,
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(
            color: isAmmoDepleted
                ? VoidTheme.solarGold
                : VoidTheme.crimsonFlare,
            width: 2.0,
          ),
          boxShadow: [
            BoxShadow(
              color:
                  (isAmmoDepleted
                          ? VoidTheme.solarGold
                          : VoidTheme.crimsonFlare)
                      .withValues(alpha: 0.3),
              blurRadius: 24.0,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isAmmoDepleted ? Icons.bolt : Icons.warning_amber_rounded,
              color: isAmmoDepleted
                  ? VoidTheme.solarGold
                  : VoidTheme.crimsonFlare,
              size: 56.0,
            ),
            const SizedBox(height: 12.0),
            Text(
              isAmmoDepleted ? 'CORES EXHAUSTED' : 'ORBITAL BREACH',
              style: TextStyle(
                color: isAmmoDepleted
                    ? VoidTheme.solarGold
                    : VoidTheme.crimsonFlare,
                fontSize: 22.0,
                fontWeight: FontWeight.bold,
                letterSpacing: 2.0,
              ),
            ),
            const SizedBox(height: 8.0),
            Text(
              isAmmoDepleted
                  ? 'Reserve plasma cores depleted with zero ordnance remaining to engage the enemy fleet.'
                  : 'The atmospheric boundary was compromised by enemy assault craft.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: VoidTheme.textSecondary,
                fontSize: 13.0,
              ),
            ),
            const SizedBox(height: 14.0),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'FINAL SCORE: $score',
                  style: const TextStyle(
                    color: VoidTheme.solarGold,
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 4.0),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.emoji_events,
                      size: 13.0,
                      color: (score >= highScore && score > 0)
                          ? VoidTheme.solarGold
                          : VoidTheme.textMuted,
                    ),
                    const SizedBox(width: 4.0),
                    Text(
                      (score >= highScore && score > 0)
                          ? '🏆 NEW ALL-TIME HIGH SCORE!'
                          : 'ALL-TIME HIGH SCORE: ${math.max(score, highScore)}',
                      style: TextStyle(
                        color: (score >= highScore && score > 0)
                            ? VoidTheme.solarGold
                            : VoidTheme.textSecondary,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16.0),
            Container(
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: VoidTheme.cardSurface.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(
                  color: VoidTheme.plasmaCyan.withValues(alpha: 0.3),
                  width: 1.0,
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.lightbulb_outline,
                    color: VoidTheme.solarGold,
                    size: 18.0,
                  ),
                  const SizedBox(width: 8.0),
                  Expanded(
                    child: Text(
                      isAmmoDepleted
                          ? 'TACTICAL TIP: Avoid single-core quick shots. Build high mass along the backline to unleash devastating quadratic cascades!'
                          : 'TACTICAL TIP: Sowing into Nyumba (Bays 3 & 4) retains charges for a massive quadratic overload.',
                      style: const TextStyle(
                        color: VoidTheme.textSecondary,
                        fontSize: 11.0,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22.0),
            Row(
              children: [
                Expanded(
                  child: TactileButton(
                    label: 'SECTOR MAP',
                    onPressed: onReturnToMap,
                    accentColor: VoidTheme.textSecondary,
                    isPrimary: false,
                    height: 44.0,
                  ),
                ),
                const SizedBox(width: 12.0),
                Expanded(
                  child: TactileButton(
                    label: 'TRY AGAIN',
                    icon: Icons.refresh,
                    onPressed: onRetry,
                    accentColor: VoidTheme.crimsonFlare,
                    height: 44.0,
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
