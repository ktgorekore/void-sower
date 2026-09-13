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
import '../../domain/models/prediction_result.dart';
import '../theme/void_theme.dart';

/// Middle 10% Dynamic Projection Shelf displaying reticle targeting telemetry.
class ProjectionShelf extends StatelessWidget {
  const ProjectionShelf({
    super.key,
    required this.prediction,
    required this.selectedBay,
  });

  final PredictionResult? prediction;
  final int? selectedBay;

  @override
  Widget build(BuildContext context) {
    if (prediction == null || selectedBay == null) {
      return Container(
        height: 48.0,
        alignment: Alignment.center,
        color: VoidTheme.obsidianBlack.withValues(alpha: 0.6),
        child: const Text(
          'TAP & SWIPE TO SOW • FLICK UP TO INJECT (NAMUA)',
          style: TextStyle(
            color: VoidTheme.textMuted,
            fontSize: 11.0,
            letterSpacing: 1.0,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }

    final p = prediction!;
    final isLance = p.triggersLance;
    final isRelay = p.triggersRelay;

    return Container(
      height: 48.0,
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      decoration: BoxDecoration(
        color: VoidTheme.cardSurface.withValues(alpha: 0.9),
        border: Border.symmetric(
          horizontal: BorderSide(
            color: isLance ? VoidTheme.plasmaCyan : VoidTheme.solarGold,
            width: 1.0,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Trajectory Preview
          Row(
            children: [
              const Icon(Icons.radar, color: VoidTheme.plasmaCyan, size: 16.0),
              const SizedBox(width: 8.0),
              Text(
                'BAY $selectedBay → BAY ${p.terminalBay}',
                style: const TextStyle(
                  color: VoidTheme.textPrimary,
                  fontSize: 12.0,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              if (p.terminalCorridor >= 0) ...[
                const SizedBox(width: 6.0),
                Text(
                  '(CORRIDOR ${p.terminalCorridor})',
                  style: const TextStyle(
                    color: VoidTheme.plasmaCyanLight,
                    fontSize: 11.0,
                  ),
                ),
              ],
            ],
          ),

          // Damage / Effect Readout
          Row(
            children: [
              if (isLance) ...[
                const Icon(
                  Icons.flash_on,
                  color: VoidTheme.plasmaCyan,
                  size: 16.0,
                ),
                const SizedBox(width: 4.0),
                Text(
                  'LANCE: ${p.predictedDamage.toInt()} DMG (M=${p.finalMass})',
                  style: const TextStyle(
                    color: VoidTheme.plasmaCyan,
                    fontSize: 12.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ] else if (isRelay) ...[
                const Icon(
                  Icons.alt_route,
                  color: VoidTheme.solarGold,
                  size: 16.0,
                ),
                const SizedBox(width: 4.0),
                const Text(
                  'RELAY OVERLOAD (FLAK VENT)',
                  style: TextStyle(
                    color: VoidTheme.solarGold,
                    fontSize: 11.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ] else ...[
                Text(
                  'ACCUMULATE: M=${p.finalMass} (MIN 4 FOR LANCE)',
                  style: const TextStyle(
                    color: VoidTheme.textSecondary,
                    fontSize: 11.0,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
