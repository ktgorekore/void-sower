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
import 'tactile_button.dart';

/// Modal overlay presented upon neutralizing all assault craft in a sector wave.
class VictoryDialog extends StatelessWidget {
  const VictoryDialog({
    super.key,
    required this.score,
    required this.coresRemaining,
    required this.onNextSector,
  });

  final int score;
  final int coresRemaining;
  final VoidCallback onNextSector;

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
          border: Border.all(color: VoidTheme.solarGold, width: 2.0),
          boxShadow: [
            BoxShadow(
              color: VoidTheme.solarGold.withValues(alpha: 0.3),
              blurRadius: 24.0,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.military_tech,
              color: VoidTheme.solarGold,
              size: 56.0,
            ),
            const SizedBox(height: 12.0),
            const Text(
              'SECTOR LIBERATED',
              style: TextStyle(
                color: VoidTheme.solarGold,
                fontSize: 22.0,
                fontWeight: FontWeight.bold,
                letterSpacing: 2.0,
              ),
            ),
            const SizedBox(height: 8.0),
            const Text(
              'Assault wave neutralized. Orbital corridor secure.',
              textAlign: TextAlign.center,
              style: TextStyle(color: VoidTheme.textSecondary, fontSize: 13.0),
            ),
            const SizedBox(height: 16.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (i) {
                final earned =
                    i <
                    (coresRemaining >= 16 ? 3 : (coresRemaining >= 8 ? 2 : 1));
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: Icon(
                    earned ? Icons.star : Icons.star_border,
                    color: VoidTheme.solarGold,
                    size: 32.0,
                  ),
                );
              }),
            ),
            const SizedBox(height: 16.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatColumn('SCORE', '$score', VoidTheme.textPrimary),
                _buildStatColumn(
                  'CORES SAVED',
                  '$coresRemaining',
                  VoidTheme.plasmaCyan,
                ),
              ],
            ),
            const SizedBox(height: 24.0),
            TactileButton(
              label: 'ADVANCE SECTOR',
              icon: Icons.navigate_next,
              onPressed: onNextSector,
              accentColor: VoidTheme.solarGold,
              minWidth: double.infinity,
              height: 48.0,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, Color valueColor) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: VoidTheme.textMuted,
            fontSize: 10.0,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 4.0),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: 18.0,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
