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
import '../theme/void_theme.dart';

/// Modal overlay presented when enemy vessels breach the orbital boundary.
class GameOverDialog extends StatelessWidget {
  const GameOverDialog({
    super.key,
    required this.score,
    required this.onRetry,
    required this.onReturnToMap,
  });

  final int score;
  final VoidCallback onRetry;
  final VoidCallback onReturnToMap;

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
          border: Border.all(color: VoidTheme.crimsonFlare, width: 2.0),
          boxShadow: [
            BoxShadow(
              color: VoidTheme.crimsonFlare.withValues(alpha: 0.3),
              blurRadius: 24.0,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              color: VoidTheme.crimsonFlare,
              size: 56.0,
            ),
            const SizedBox(height: 12.0),
            const Text(
              'ORBITAL BREACH',
              style: TextStyle(
                color: VoidTheme.crimsonFlare,
                fontSize: 22.0,
                fontWeight: FontWeight.bold,
                letterSpacing: 2.0,
              ),
            ),
            const SizedBox(height: 8.0),
            const Text(
              'The atmospheric boundary was compromised by enemy assault craft.',
              textAlign: TextAlign.center,
              style: TextStyle(color: VoidTheme.textSecondary, fontSize: 13.0),
            ),
            const SizedBox(height: 16.0),
            Text(
              'FINAL SCORE: $score',
              style: const TextStyle(
                color: VoidTheme.solarGold,
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 24.0),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: VoidTheme.textSecondary,
                      side: const BorderSide(color: VoidTheme.textMuted),
                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                    ),
                    onPressed: onReturnToMap,
                    child: const Text('SECTOR MAP'),
                  ),
                ),
                const SizedBox(width: 12.0),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: VoidTheme.crimsonFlare,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                    ),
                    onPressed: onRetry,
                    child: const Text('RE-ENGAGE'),
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
