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

import '../../domain/models/bay_role.dart';
import '../../domain/models/bay_state.dart';
import '../controllers/tactical_solver_controller.dart';
import '../services/haptic_service.dart';
import '../theme/void_theme.dart';

/// Compact 56px Martial Flight & Totem Command Bar replacing the legacy 142px
/// 16-box spreadsheet dock.
///
/// Uses visual seed pips and ultra-short plain-English nuggets so players
/// immediately understand turret growth, seed spreading, and the 3-in-a-row
/// Laser Fence without mathematical jargon.
class MancalaBatteryDockWidget extends StatelessWidget {
  const MancalaBatteryDockWidget({
    super.key,
    required this.bays,
    required this.selectedBay,
    this.activeSowBay,
    required this.sowDirection,
    required this.activeCorridor,
    required this.onBaySelected,
    required this.onSowAction,
    required this.onInjectCore,
    required this.onQuickFire,
    this.onDirectDischargeBay,
    this.millTriadBays = const <int>{},
    this.onSlidePosition,
    this.onDirectionChanged,
    this.tacticalAdvice,
  });

  final List<BayState> bays;
  final int selectedBay;
  final int? activeSowBay;
  final int sowDirection;
  final int activeCorridor;
  final ValueChanged<int> onBaySelected;
  final void Function(int bayIndex, int direction) onSowAction;
  final void Function(int bayIndex, int direction) onInjectCore;
  final VoidCallback onQuickFire;
  final ValueChanged<int>? onDirectDischargeBay;
  final Set<int> millTriadBays;
  final ValueChanged<double>? onSlidePosition;
  final ValueChanged<int>? onDirectionChanged;
  final TacticalAdvice? tacticalAdvice;

  @override
  Widget build(BuildContext context) {
    final alignedBayIndex = 8 + activeCorridor.clamp(0, 7);
    final alignedMass = alignedBayIndex < bays.length
        ? bays[alignedBayIndex].chargeUnits
        : 0;
    final hasMill = millTriadBays.isNotEmpty;

    final String tierLabel;
    final Color tierColor;
    final IconData tierIcon;
    if (alignedMass >= 4) {
      tierLabel = 'MEGA GUN';
      tierColor = VoidTheme.solarGold;
      tierIcon = Icons.auto_awesome;
    } else if (alignedMass >= 2) {
      tierLabel = 'AUTO-GUN';
      tierColor = VoidTheme.plasmaCyan;
      tierIcon = Icons.bolt;
    } else if (alignedMass == 1) {
      tierLabel = 'SHIELD';
      tierColor = VoidTheme.emeraldShield;
      tierIcon = Icons.shield;
    } else {
      tierLabel = 'EMPTY';
      tierColor = VoidTheme.crimsonFlare;
      tierIcon = Icons.radio_button_unchecked;
    }

    final String subActionText;
    if (alignedMass >= 2) {
      subActionText = '⚡ TAP FOR ${alignedMass * alignedMass}x SUPER BEAM';
    } else if (alignedMass == 1) {
      subActionText = '🛡️ BLOCKS BOMBS • SHOOT TO GROW';
    } else {
      subActionText = '🎯 SHOOT ENEMIES TO GROW';
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragEnd: (details) {
            final vx = details.primaryVelocity ?? 0.0;
            if (vx.abs() > 80.0) {
              final dir = vx > 0 ? 1 : -1;
              final resolved = BayRole.resolveSowDirection(
                alignedBayIndex,
                dir,
              );
              HapticService.instance.sowTick();
              onDirectionChanged?.call(resolved);
              onSowAction(alignedBayIndex, resolved);
            }
          },
          child: Container(
            height: 56.0,
            margin: const EdgeInsets.symmetric(horizontal: 10.0),
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 5.0),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xE60E1726), Color(0xF2070B14)],
              ),
              borderRadius: BorderRadius.circular(14.0),
              border: Border.all(
                color: hasMill
                    ? VoidTheme.solarGold.withValues(alpha: 0.80)
                    : const Color(0xFF1E293B),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.55),
                  blurRadius: 12.0,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                // 1. Left Pill: SOW / SPREAD SEEDS ‹ ›
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildSowButton(
                      label: '‹ SOW',
                      onTap: () {
                        final resolved = BayRole.resolveSowDirection(
                          alignedBayIndex,
                          -1,
                        );
                        HapticService.instance.sowTick();
                        onDirectionChanged?.call(resolved);
                        onSowAction(alignedBayIndex, resolved);
                      },
                    ),
                    const SizedBox(width: 4.0),
                    _buildSowButton(
                      label: 'SOW ›',
                      onTap: () {
                        final resolved = BayRole.resolveSowDirection(
                          alignedBayIndex,
                          1,
                        );
                        HapticService.instance.sowTick();
                        onDirectionChanged?.call(resolved);
                        onSowAction(alignedBayIndex, resolved);
                      },
                    ),
                  ],
                ),
                const SizedBox(width: 6.0),

                // 2. Center Visual Turret Meter & One-Tap Super Beam Pill
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      HapticService.instance.injectionClick();
                      if (onDirectDischargeBay != null && alignedMass >= 2) {
                        onDirectDischargeBay!(alignedBayIndex);
                      } else {
                        onQuickFire();
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8.0,
                        vertical: 4.0,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(10.0),
                        border: Border.all(
                          color: tierColor.withValues(alpha: 0.75),
                          width: 1.1,
                        ),
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(tierIcon, size: 11.0, color: tierColor),
                                const SizedBox(width: 4.0),
                                Text(
                                  'TOTEM #${activeCorridor + 1} • $tierLabel',
                                  style: TextStyle(
                                    color: tierColor,
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(width: 6.0),
                                // 4 visual glowing seed pips instead of "M=..."
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: List.generate(4, (pipIdx) {
                                    final filled = pipIdx < alignedMass;
                                    return Container(
                                      width: 6.5,
                                      height: 6.5,
                                      margin: const EdgeInsets.symmetric(
                                        horizontal: 1.2,
                                      ),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: filled
                                            ? tierColor
                                            : Colors.transparent,
                                        border: Border.all(
                                          color: filled
                                              ? tierColor
                                              : Colors.white30,
                                          width: 1.0,
                                        ),
                                      ),
                                    );
                                  }),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2.5),
                            Text(
                              subActionText,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 7.4,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6.0),

                // 3. Right Pill: FENCE BLAST or BLASTER FIRE
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    HapticService.instance.injectionClick();
                    if (hasMill && onDirectDischargeBay != null) {
                      onDirectDischargeBay!(millTriadBays.first);
                    } else {
                      onQuickFire();
                    }
                  },
                  child: Container(
                    constraints: const BoxConstraints(
                      minWidth: 68.0,
                      minHeight: 42.0,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9.0,
                      vertical: 5.0,
                    ),
                    decoration: BoxDecoration(
                      color: hasMill
                          ? VoidTheme.solarGold.withValues(alpha: 0.20)
                          : VoidTheme.plasmaCyan.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(10.0),
                      border: Border.all(
                        color: hasMill
                            ? VoidTheme.solarGold
                            : VoidTheme.plasmaCyan,
                        width: 1.2,
                      ),
                    ),
                    child: Center(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          hasMill ? 'FENCE\nBLAST' : 'BLASTER\nFIRE',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: hasMill
                                ? VoidTheme.solarGold
                                : VoidTheme.plasmaCyan,
                            fontSize: 8.0,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 3.0),
        _buildSubtleAdvisoryBar(),
      ],
    );
  }

  Widget _buildSowButton({required String label, required VoidCallback onTap}) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minWidth: 48.0, minHeight: 42.0),
        padding: const EdgeInsets.symmetric(horizontal: 7.0, vertical: 5.0),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(9.0),
          border: Border.all(
            color: VoidTheme.plasmaCyan.withValues(alpha: 0.55),
            width: 1.0,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              color: VoidTheme.plasmaCyan,
              fontSize: 8.0,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.4,
            ),
          ),
        ),
      ),
    );
  }

  /// Builds a crisp, visual-first, human-readable directive nugget row.
  Widget _buildSubtleAdvisoryBar() {
    final advice = tacticalAdvice;
    if (advice != null) {
      final dirStr = advice.recommendedDirection > 0 ? 'SOW ›' : '‹ SOW';
      return SizedBox(
        height: 15.0,
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.lightbulb,
                  size: 10.0,
                  color: VoidTheme.solarGold,
                ),
                const SizedBox(width: 4.0),
                Text(
                  'TIP: TAP $dirStr TO POWER UP TOTEM #${(advice.recommendedBay & 7) + 1}',
                  style: const TextStyle(
                    color: Color(0xFF38BDF8),
                    fontSize: 8.0,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return const SizedBox(
      height: 15.0,
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.gps_fixed, size: 9.5, color: VoidTheme.plasmaCyan),
              SizedBox(width: 3.0),
              Text(
                'SHOOT = +SEEDS',
                style: TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 7.8,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.4,
                ),
              ),
              SizedBox(width: 8.0),
              Icon(Icons.bolt, size: 10.0, color: VoidTheme.plasmaCyan),
              SizedBox(width: 2.0),
              Text(
                '2+ SEEDS = AUTO-GUN',
                style: TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 7.8,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.4,
                ),
              ),
              SizedBox(width: 8.0),
              Icon(Icons.shield, size: 9.5, color: VoidTheme.solarGold),
              SizedBox(width: 3.0),
              Text(
                '3 IN A ROW = LASER FENCE',
                style: TextStyle(
                  color: VoidTheme.solarGold,
                  fontSize: 7.8,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
