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

/// Tactical orientation shield displayed when the device is held in an unsupported
/// compact landscape aspect ratio (height < 520 dp).
///
/// Prompts the commander to rotate their device back to portrait orientation
/// to ensure precision vertical capacitor alignment and lance targeting.
class LandscapeOrientationShield extends StatefulWidget {
  /// Creates a [LandscapeOrientationShield].
  const LandscapeOrientationShield({super.key});

  @override
  State<LandscapeOrientationShield> createState() =>
      _LandscapeOrientationShieldState();
}

class _LandscapeOrientationShieldState extends State<LandscapeOrientationShield>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: VoidTheme.obsidianBlack,
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          final pulse = _pulseController.value;
          final rotationAngle = math.sin(pulse * math.pi) * 0.15;

          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 16.0,
              ),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 480.0),
                padding: const EdgeInsets.symmetric(
                  horizontal: 28.0,
                  vertical: 22.0,
                ),
                decoration: BoxDecoration(
                  color: VoidTheme.cardSurface.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(16.0),
                  border: Border.all(
                    color: VoidTheme.solarGold.withValues(
                      alpha: 0.7 + 0.3 * pulse,
                    ),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: VoidTheme.solarGold.withValues(
                        alpha: 0.2 + 0.15 * pulse,
                      ),
                      blurRadius: 20.0,
                      spreadRadius: 1.0,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Animated Rotation Radar Icon
                    Transform.rotate(
                      angle: rotationAngle,
                      child: Container(
                        width: 60.0,
                        height: 60.0,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: VoidTheme.obsidianBlack,
                          border: Border.all(
                            color: VoidTheme.plasmaCyan.withValues(
                              alpha: 0.8 + 0.2 * pulse,
                            ),
                            width: 2.0,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: VoidTheme.plasmaCyan.withValues(
                                alpha: 0.35 * pulse,
                              ),
                              blurRadius: 12.0,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.screen_rotation_rounded,
                          color: VoidTheme.plasmaCyan,
                          size: 32.0,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14.0),

                    // Primary Title
                    const Text(
                      'ORIENTATION LOCK ACTIVE',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: VoidTheme.solarGold,
                        fontSize: 14.0,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2.0,
                      ),
                    ),
                    const SizedBox(height: 6.0),

                    // Subtitle
                    const Text(
                      'ROTATE DEVICE TO PORTRAIT',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: VoidTheme.starWhite,
                        fontSize: 12.0,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 10.0),

                    // Description text
                    Text(
                      'Bao orbital batteries require vertical capacitor alignment for precision lance trajectory and thumb command arc telemetry.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: VoidTheme.textSecondary.withValues(alpha: 0.9),
                        fontSize: 11.0,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16.0),

                    // Sensor Realignment Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12.0,
                        vertical: 5.0,
                      ),
                      decoration: BoxDecoration(
                        color: VoidTheme.obsidianBlack,
                        borderRadius: BorderRadius.circular(6.0),
                        border: Border.all(
                          color: VoidTheme.emeraldShield.withValues(
                            alpha: 0.5 + 0.4 * pulse,
                          ),
                          width: 1.0,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6.0,
                            height: 6.0,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: VoidTheme.emeraldShield,
                              boxShadow: [
                                BoxShadow(
                                  color: VoidTheme.emeraldShield.withValues(
                                    alpha: 0.8 * pulse,
                                  ),
                                  blurRadius: 4.0,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8.0),
                          const Text(
                            'AWAITING SENSOR REALIGNMENT...',
                            style: TextStyle(
                              color: VoidTheme.emeraldShield,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
