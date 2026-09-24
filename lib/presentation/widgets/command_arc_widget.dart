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
import '../../domain/models/bay_state.dart';
import '../services/haptic_service.dart';
import '../theme/void_theme.dart';

/// Primary thumb command arc managing the 16 capacitor bays and axial discharge.
///
/// Features enlarged touch-friendly bays (48 dp) adhering to ergonomic mobile standards,
/// C1–C8 corridor alignment badges, and direct gesture sowing (tap/double-tap/flick/swipe).
class CommandArcWidget extends StatelessWidget {
  const CommandArcWidget({
    super.key,
    required this.bays,
    required this.selectedBay,
    this.activeSowBay,
    required this.onBaySelected,
    required this.onSowAction,
    required this.onInjectCore,
    this.onSlidePosition,
  });

  final List<BayState> bays;
  final int? selectedBay;
  final int? activeSowBay;
  final ValueChanged<int> onBaySelected;
  final void Function(int bayIndex, int direction) onSowAction;
  final void Function(int bayIndex, int direction) onInjectCore;
  final ValueChanged<double>? onSlidePosition;

  @override
  Widget build(BuildContext context) {
    final frontlineBays = bays.where((b) => b.isFrontline).toList();
    final backlineBays = bays.where((b) => !b.isFrontline).toList();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 3.0),
      decoration: const BoxDecoration(
        color: VoidTheme.obsidianBlack,
        border: Border(
          top: BorderSide(color: VoidTheme.cardSurface, width: 1.0),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Frontline Tier Header (Dominant Weapon Deck)
          Padding(
            padding: const EdgeInsets.only(bottom: 2.0, left: 3.0, right: 3.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.shield,
                          size: 9.0,
                          color: VoidTheme.plasmaCyan,
                        ),
                        const SizedBox(width: 3.0),
                        Text(
                          '▲ BAYS 8–15 (FRONTLINE)',
                          style: TextStyle(
                            color: VoidTheme.plasmaCyan.withValues(alpha: 0.95),
                            fontSize: 7.2,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Text(
                  'C1–C8 ──► LANCE',
                  style: TextStyle(
                    color: VoidTheme.plasmaCyanLight.withValues(alpha: 0.8),
                    fontSize: 6.8,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),

          // Corridor Alignment Badges C1–C8
          Padding(
            padding: const EdgeInsets.only(bottom: 3.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(8, (i) {
                final corridor = i;
                final frontlineBay = 8 + corridor;
                final isSelected = selectedBay == frontlineBay;

                return Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      HapticService.instance.sowTick();
                      onBaySelected(frontlineBay);
                      final normX = (corridor + 0.5) / 8.0;
                      onSlidePosition?.call(normX);
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 1.0),
                      padding: const EdgeInsets.symmetric(vertical: 2.5),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? VoidTheme.plasmaCyan.withValues(alpha: 0.3)
                            : VoidTheme.cardSurface.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(4.0),
                        border: Border.all(
                          color: isSelected
                              ? VoidTheme.plasmaCyan
                              : VoidTheme.cardSurface,
                          width: isSelected ? 1.2 : 0.8,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: VoidTheme.plasmaCyan.withValues(
                                    alpha: 0.4,
                                  ),
                                  blurRadius: 4.0,
                                ),
                              ]
                            : null,
                      ),
                      child: Center(
                        child: Text(
                          'C${i + 1}',
                          style: TextStyle(
                            color: isSelected
                                ? VoidTheme.plasmaCyan
                                : VoidTheme.textSecondary,
                            fontSize: 9.0,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),

          // Frontline Tier (Bays 8 to 15) - Primary 48 dp height
          _buildBayRow(frontlineBays, isFrontline: true),
          const SizedBox(height: 4.0),

          // Backline Tier Header (Sub-Deck Reservoir)
          Padding(
            padding: const EdgeInsets.only(bottom: 2.0, left: 3.0, right: 3.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.cyclone,
                          size: 9.0,
                          color: VoidTheme.solarGold,
                        ),
                        const SizedBox(width: 3.0),
                        Text(
                          '▼ BAYS 0–7 (RESERVOIR)',
                          style: TextStyle(
                            color: VoidTheme.solarGold.withValues(alpha: 0.95),
                            fontSize: 7.0,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Text(
                  'STORAGE ──► RELAY',
                  style: TextStyle(
                    color: VoidTheme.solarGoldLight.withValues(alpha: 0.75),
                    fontSize: 6.8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Backline Tier (Bays 0 to 7) - Streamlined 38 dp height
          _buildBayRow(backlineBays, isFrontline: false),
          const SizedBox(height: 4.0),

          // Tactical Flagship Axial Discharge Action Deck
          Builder(
            builder: (context) {
              final selected = selectedBay;
              final activeCorridor =
                  (selected != null && selected >= 8 && selected <= 15)
                  ? selected - 8
                  : (selected != null && selected < 8 ? selected : 0);
              final activeBay = selected ?? (activeCorridor + 8);

              return Padding(
                padding: const EdgeInsets.only(bottom: 2.0),
                child: GestureDetector(
                  onTap: () {
                    HapticService.instance.injectionClick();
                    final dir = (activeCorridor >= 4) ? -1 : 1;
                    onInjectCore(activeBay, dir);
                  },
                  child: Container(
                    height: 38.0,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          VoidTheme.plasmaCyan,
                          VoidTheme.plasmaCyanLight,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(8.0),
                      boxShadow: [
                        BoxShadow(
                          color: VoidTheme.plasmaCyan.withValues(alpha: 0.4),
                          blurRadius: 8.0,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.bolt,
                          color: VoidTheme.obsidianBlack,
                          size: 16.0,
                        ),
                        const SizedBox(width: 4.0),
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              'AXIAL DISCHARGE C${activeCorridor + 1} (INJECT CORE • BAY $activeBay)',
                              style: const TextStyle(
                                color: VoidTheme.obsidianBlack,
                                fontSize: 11.0,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBayRow(List<BayState> rowBays, {required bool isFrontline}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: rowBays.map((bay) => _buildBayCell(bay, isFrontline)).toList(),
    );
  }

  Widget _buildBayCell(BayState bay, bool isFrontline) {
    final isSelected = selectedBay == bay.bayIndex;
    final isSowHop = activeSowBay == bay.bayIndex;

    Color borderColor = VoidTheme.textMuted.withValues(alpha: 0.4);
    Color bayGlow = Colors.transparent;
    if (isSowHop) {
      borderColor = VoidTheme.solarGold;
      bayGlow = VoidTheme.solarGold.withValues(alpha: 0.55);
    } else if (isSelected) {
      borderColor = VoidTheme.plasmaCyan;
      bayGlow = VoidTheme.plasmaCyan.withValues(alpha: 0.3);
    } else if (bay.isNyumba) {
      borderColor = VoidTheme.solarGold;
      bayGlow = VoidTheme.solarGold.withValues(alpha: 0.15);
    } else if (bay.isKichwa) {
      borderColor = VoidTheme.nebulaAmethyst;
      bayGlow = VoidTheme.nebulaAmethyst.withValues(alpha: 0.15);
    } else if (bay.isKimbi) {
      borderColor = VoidTheme.emeraldShield;
      bayGlow = VoidTheme.emeraldShield.withValues(alpha: 0.15);
    }

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          HapticService.instance.sowTick();
          if (selectedBay == bay.bayIndex) {
            HapticService.instance.injectionClick();
            onInjectCore(bay.bayIndex, 1);
          } else {
            onBaySelected(bay.bayIndex);
            if (bay.bayIndex >= 8) {
              final corridor = bay.bayIndex - 8;
              final normX = (corridor + 0.5) / 8.0;
              onSlidePosition?.call(normX);
            }
          }
        },
        onDoubleTap: () {
          HapticService.instance.injectionClick();
          onInjectCore(bay.bayIndex, 1);
        },
        onPanEnd: (details) {
          final vx = details.velocity.pixelsPerSecond.dx;
          final vy = details.velocity.pixelsPerSecond.dy;
          if (vy < -120 && vy.abs() > vx.abs()) {
            // Upward flick = Core Injection (namua)
            HapticService.instance.injectionClick();
            onInjectCore(bay.bayIndex, 1);
          } else if (vx > 100) {
            // Swipe right = Clockwise (+1)
            HapticService.instance.sowTick();
            onSowAction(bay.bayIndex, 1);
          } else if (vx < -100) {
            // Swipe left = Counter-Clockwise (-1)
            HapticService.instance.sowTick();
            onSowAction(bay.bayIndex, -1);
          }
        },
        child: AnimatedScale(
          scale: isSowHop ? 1.12 : 1.0,
          duration: const Duration(milliseconds: 140),
          child: Container(
            height: isFrontline ? 48.0 : 38.0,
            margin: const EdgeInsets.symmetric(horizontal: 1.0),
            decoration: BoxDecoration(
              color: isSelected
                  ? (isFrontline
                        ? VoidTheme.plasmaCyan.withValues(alpha: 0.25)
                        : VoidTheme.solarGold.withValues(alpha: 0.22))
                  : (bayGlow != Colors.transparent
                        ? bayGlow
                        : (isFrontline
                              ? VoidTheme.cardSurface
                              : VoidTheme.obsidianBlack.withValues(
                                  alpha: 0.6,
                                ))),
              borderRadius: BorderRadius.circular(6.0),
              border: Border.all(
                color: borderColor,
                width: isSelected || bay.isNyumba ? 1.5 : 0.9,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color:
                            (isFrontline
                                    ? VoidTheme.plasmaCyan
                                    : VoidTheme.solarGold)
                                .withValues(alpha: 0.35),
                        blurRadius: 6.0,
                      ),
                    ]
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Bay Index label & Special badges
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${bay.bayIndex}',
                      style: TextStyle(
                        color: isSelected
                            ? (isFrontline
                                  ? VoidTheme.plasmaCyan
                                  : VoidTheme.solarGold)
                            : (isFrontline
                                  ? VoidTheme.textSecondary
                                  : VoidTheme.textMuted),
                        fontSize: isFrontline ? 9.5 : 8.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (bay.isNyumba)
                      const Text(
                        '★',
                        style: TextStyle(
                          color: VoidTheme.solarGold,
                          fontSize: 8.0,
                        ),
                      ),
                    if (bay.isKichwa)
                      const Text(
                        '♦',
                        style: TextStyle(
                          color: VoidTheme.nebulaAmethyst,
                          fontSize: 8.0,
                        ),
                      ),
                    if (bay.isKimbi)
                      const Text(
                        '▲',
                        style: TextStyle(
                          color: VoidTheme.emeraldShield,
                          fontSize: 8.0,
                        ),
                      ),
                  ],
                ),

                // Accumulated Plasma Units (M)
                Text(
                  '${bay.chargeUnits}',
                  style: TextStyle(
                    color: bay.chargeUnits >= 4
                        ? (isFrontline
                              ? VoidTheme.plasmaCyan
                              : VoidTheme.solarGold)
                        : (isFrontline
                              ? VoidTheme.textPrimary
                              : VoidTheme.textSecondary),
                    fontSize: isFrontline ? 13.5 : 11.5,
                    fontWeight: FontWeight.bold,
                    height: 1.05,
                  ),
                ),

                // Concentric Charge Pips (Up to 4 pips)
                if (bay.chargeUnits > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 1.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        bay.chargeUnits.clamp(1, 4),
                        (i) => Container(
                          width: isFrontline ? 3.2 : 2.6,
                          height: isFrontline ? 3.2 : 2.6,
                          margin: const EdgeInsets.symmetric(horizontal: 0.5),
                          decoration: BoxDecoration(
                            color: bay.chargeUnits >= 4
                                ? (isFrontline
                                      ? VoidTheme.plasmaCyan
                                      : VoidTheme.solarGold)
                                : (isFrontline
                                      ? VoidTheme.plasmaCyanLight
                                      : VoidTheme.solarGoldLight),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
