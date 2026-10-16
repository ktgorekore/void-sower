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

/// Compact 60px Martial Flight & Totem Command Bar replacing the legacy 142px
/// 16-box spreadsheet dock.
///
/// The 8 Ancestral Totem Turrets (`bays[8..15]`) and 3D Morabaraba Laser Fences
/// render directly on the 3D battlefield floor inside [CombatPainter], keeping
/// 100% of the player's visual focus on the 3D combat arena.
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
    if (alignedMass >= 4) {
      tierLabel = 'T3 SUPER-PRISM';
      tierColor = VoidTheme.solarGold;
    } else if (alignedMass >= 2) {
      tierLabel = 'T2 AUTO-TURRET';
      tierColor = VoidTheme.plasmaCyan;
    } else if (alignedMass == 1) {
      tierLabel = 'T1 SHIELD DOME';
      tierColor = VoidTheme.emeraldShield;
    } else {
      tierLabel = 'T0 DORMANT';
      tierColor = VoidTheme.crimsonFlare;
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
                // 1. Left Pill: SOW TOTEMS ‹ ›
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

                // 2. Center Status & Totem Overdrive Pill
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
                            Text(
                              'TOTEM #${activeCorridor + 1} • $tierLabel (M=$alignedMass)',
                              style: TextStyle(
                                color: tierColor,
                                fontSize: 8.5,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 2.0),
                            Text(
                              alignedMass >= 2
                                  ? 'TAP FOR M²=${alignedMass * alignedMass}x OVERDRIVE'
                                  : 'SHOOT INVADERS TO HARVEST TOTEM SEEDS',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 7.2,
                                fontWeight: FontWeight.w700,
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

                // 3. Right Pill: MORABARABA FENCE 1.5x or HARVEST BLASTER
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
                          hasMill ? 'FENCE\n1.5x' : 'BLASTER\nFIRE',
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

  /// Builds a subtle, single-line fixed-height advisory indicator that prevents layout jumps.
  Widget _buildSubtleAdvisoryBar() {
    final advice = tacticalAdvice;
    if (advice != null) {
      final dirStr = advice.recommendedDirection > 0 ? '› RIGHT' : '‹ LEFT';
      return SizedBox(
        height: 14.0,
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.auto_awesome,
                  size: 9.0,
                  color: Color(0xFF38BDF8),
                ),
                const SizedBox(width: 4.0),
                Text(
                  'TACTICAL ADVISORY: SOW TOTEM #${(advice.recommendedBay & 7) + 1} $dirStr • EST. ${advice.predictedDamage.toInt()} DMG',
                  style: const TextStyle(
                    color: Color(0xFF38BDF8),
                    fontSize: 7.5,
                    fontWeight: FontWeight.w800,
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
      height: 14.0,
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            'SHOOT TO HARVEST SEEDS • EVOLVE 3D TOTEM TURRETS • 3 ADJACENT = LASER FENCE',
            style: TextStyle(
              color: Color(0xFF64748B),
              fontSize: 7.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
