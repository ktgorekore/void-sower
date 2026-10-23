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

/// Compact 52px Martial Flight & Totem Command Bar.
///
/// Uses visual seed pips, turret tier icons, and concise single-word action
/// buttons (`‹ SOW`, `SOW ›`, `FIRE` / `BLAST`) without multi-line text
/// descriptions or bottom advisory text strips.
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

    final Color tierColor;
    final IconData tierIcon;
    if (alignedMass >= 4) {
      tierColor = VoidTheme.solarGold;
      tierIcon = Icons.auto_awesome;
    } else if (alignedMass >= 2) {
      tierColor = VoidTheme.plasmaCyan;
      tierIcon = Icons.bolt;
    } else if (alignedMass == 1) {
      tierColor = VoidTheme.emeraldShield;
      tierIcon = Icons.shield;
    } else {
      tierColor = VoidTheme.crimsonFlare;
      tierIcon = Icons.radio_button_unchecked;
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onHorizontalDragEnd: (details) {
        final vx = details.primaryVelocity ?? 0.0;
        if (vx.abs() > 80.0) {
          final dir = vx > 0 ? 1 : -1;
          final resolved = BayRole.resolveSowDirection(alignedBayIndex, dir);
          HapticService.instance.sowTick();
          onDirectionChanged?.call(resolved);
          onSowAction(alignedBayIndex, resolved);
        }
      },
      child: Container(
        height: 52.0,
        margin: const EdgeInsets.fromLTRB(10.0, 0.0, 10.0, 4.0),
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
            // 1. Left Controls: ‹ SOW and SOW ›
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

            // 2. Center Visual Turret Charge Meter (Icon + 4 Glowing Pips)
            Expanded(
              child: GestureDetector(
                key: const Key('dock_center_turret_pill'),
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
                  height: 40.0,
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(10.0),
                    border: Border.all(
                      color: tierColor.withValues(alpha: 0.75),
                      width: 1.1,
                    ),
                  ),
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(tierIcon, size: 14.0, color: tierColor),
                          const SizedBox(width: 4.0),
                          Text(
                            '#${activeCorridor + 1}',
                            style: TextStyle(
                              color: tierColor,
                              fontSize: 10.0,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(width: 8.0),
                          // 4 visual glowing seed pips
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: List.generate(4, (pipIdx) {
                              final filled = pipIdx < alignedMass;
                              return Container(
                                width: 8.0,
                                height: 8.0,
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 1.8,
                                ),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: filled
                                      ? tierColor
                                      : Colors.transparent,
                                  border: Border.all(
                                    color: filled ? tierColor : Colors.white30,
                                    width: 1.2,
                                  ),
                                  boxShadow: filled
                                      ? [
                                          BoxShadow(
                                            color: tierColor.withValues(
                                              alpha: 0.65,
                                            ),
                                            blurRadius: 4.0,
                                          ),
                                        ]
                                      : null,
                                ),
                              );
                            }),
                          ),
                          if (alignedMass >= 2) ...[
                            const SizedBox(width: 6.0),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4.0,
                                vertical: 1.5,
                              ),
                              decoration: BoxDecoration(
                                color: tierColor.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(4.0),
                              ),
                              child: Text(
                                '${alignedMass * alignedMass}x',
                                style: TextStyle(
                                  color: tierColor,
                                  fontSize: 9.0,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6.0),

            // 3. Right Action Button: Single-word FIRE or BLAST
            GestureDetector(
              key: const Key('dock_fire_button'),
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
                  minWidth: 64.0,
                  minHeight: 40.0,
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
                    color: hasMill ? VoidTheme.solarGold : VoidTheme.plasmaCyan,
                    width: 1.2,
                  ),
                ),
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          hasMill ? Icons.auto_awesome_motion : Icons.flash_on,
                          size: 13.0,
                          color: hasMill
                              ? VoidTheme.solarGold
                              : VoidTheme.plasmaCyan,
                        ),
                        const SizedBox(width: 3.0),
                        Text(
                          hasMill ? 'BLAST' : 'FIRE',
                          style: TextStyle(
                            color: hasMill
                                ? VoidTheme.solarGold
                                : VoidTheme.plasmaCyan,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSowButton({required String label, required VoidCallback onTap}) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minWidth: 48.0, minHeight: 40.0),
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
              fontSize: 8.5,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.4,
            ),
          ),
        ),
      ),
    );
  }
}
