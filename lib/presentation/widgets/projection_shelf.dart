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
import '../../domain/models/pro_feature.dart';
import '../../domain/services/entitlement_service.dart';
import '../theme/void_theme.dart';

/// Middle 10% Dynamic Projection Shelf displaying reticle targeting telemetry.
class ProjectionShelf extends StatelessWidget {
  const ProjectionShelf({
    super.key,
    required this.prediction,
    required this.selectedBay,
    this.isDeepTelemetry,
    this.threatCorridorBreachProbability,
  });

  final PredictionResult? prediction;
  final int? selectedBay;
  final bool? isDeepTelemetry;
  final double? threatCorridorBreachProbability;

  @override
  Widget build(BuildContext context) {
    if (prediction == null || selectedBay == null) {
      return Container(
        width: double.infinity,
        height: 22.0,
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: VoidTheme.obsidianBlack.withValues(alpha: 0.75),
          border: const Border.symmetric(
            horizontal: BorderSide(color: VoidTheme.cardSurface, width: 0.8),
          ),
        ),
        child: const FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.radar, size: 11.0, color: VoidTheme.plasmaCyan),
              SizedBox(width: 5.0),
              Text(
                'SELECT BAY TO PREVIEW LANCE & SOWING TRAJECTORY',
                style: TextStyle(
                  color: VoidTheme.textSecondary,
                  fontSize: 8.5,
                  letterSpacing: 0.6,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final p = prediction!;
    final isLance = p.triggersLance;
    final isRelay = p.triggersRelay;
    final deepActive =
        isDeepTelemetry ??
        EntitlementService.instance.isFeatureAccessible(
          ProFeature.deepSensorTelemetry,
        );

    return Container(
      width: double.infinity,
      height: 22.0,
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      decoration: BoxDecoration(
        color: VoidTheme.cardSurface.withValues(alpha: 0.9),
        border: Border.symmetric(
          horizontal: BorderSide(
            color: isLance ? VoidTheme.plasmaCyan : VoidTheme.solarGold,
            width: 0.8,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Trajectory Preview (Anchored to Left)
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.radar,
                    color: VoidTheme.plasmaCyan,
                    size: 13.0,
                  ),
                  const SizedBox(width: 6.0),
                  Text(
                    'BAY $selectedBay → BAY ${p.terminalBay}',
                    style: const TextStyle(
                      color: VoidTheme.textPrimary,
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  if (p.terminalCorridor >= 0) ...[
                    const SizedBox(width: 5.0),
                    Text(
                      '(CORRIDOR ${p.terminalCorridor})',
                      style: const TextStyle(
                        color: VoidTheme.plasmaCyanLight,
                        fontSize: 9.5,
                      ),
                    ),
                  ],
                  if (deepActive && p.totalCascadeLaps > 0) ...[
                    const SizedBox(width: 4.0),
                    Text(
                      '• ${p.totalCascadeLaps} LAPS',
                      style: const TextStyle(
                        color: VoidTheme.solarGold,
                        fontSize: 8.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(width: 8.0),

          // Damage / Effect Readout (Anchored to Right)
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isLance) ...[
                    const Icon(
                      Icons.flash_on,
                      color: VoidTheme.plasmaCyan,
                      size: 13.0,
                    ),
                    const SizedBox(width: 3.0),
                    Text(
                      deepActive
                          ? 'LANCE: ${p.predictedDamage.toInt()} DMG (α × ${p.finalMass}²)'
                          : 'LANCE: ${p.predictedDamage.toInt()} DMG (M=${p.finalMass})',
                      style: const TextStyle(
                        color: VoidTheme.plasmaCyan,
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (deepActive &&
                        threatCorridorBreachProbability != null &&
                        threatCorridorBreachProbability! > 0) ...[
                      const SizedBox(width: 4.0),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 3.0,
                          vertical: 1.0,
                        ),
                        decoration: BoxDecoration(
                          color: VoidTheme.crimsonFlare.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(2.0),
                          border: Border.all(
                            color: VoidTheme.crimsonFlare,
                            width: 0.6,
                          ),
                        ),
                        child: Text(
                          '${(threatCorridorBreachProbability! * 100).toInt()}% RISK',
                          style: const TextStyle(
                            color: VoidTheme.crimsonFlare,
                            fontSize: 7.5,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ] else if (isRelay) ...[
                    const Icon(
                      Icons.alt_route,
                      color: VoidTheme.solarGold,
                      size: 13.0,
                    ),
                    const SizedBox(width: 3.0),
                    const Text(
                      'RELAY OVERLOAD (FLAK VENT)',
                      style: TextStyle(
                        color: VoidTheme.solarGold,
                        fontSize: 9.5,
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
            ),
          ),
        ],
      ),
    );
  }
}
