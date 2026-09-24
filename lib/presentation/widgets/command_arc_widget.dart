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
                          '▲ BAYS 8–15 (FRONTLINE TURRETS)',
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

          // Corridor Alignment Badges C1–C8 (Direct Aiming Channels)
          Padding(
            padding: const EdgeInsets.only(bottom: 3.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(8, (i) {
                final corridor = i;
                final frontlineBay = 8 + corridor;
                final isSelected = selectedBay == frontlineBay;

                return Expanded(
                  child: Semantics(
                    label: 'Corridor ${i + 1}',
                    button: true,
                    selected: isSelected,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        HapticService.instance.sowTick();
                        onBaySelected(frontlineBay);
                        final normX = (corridor + 0.5) / 8.0;
                        onSlidePosition?.call(normX);
                      },
                      child: Container(
                        height: 28.0,
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
                  ),
                );
              }),
            ),
          ),

          // Frontline Tier (Bays 8 to 15) - Primary 48 dp height
          _buildBayRow(frontlineBays, isFrontline: true),
          const SizedBox(height: 4.0),

          // Backline Tier Header (Sub-Deck Reactor Core)
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
                          '▼ BAYS 0–7 (SUB-DECK REACTOR)',
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

          // Backline Sub-Deck Reservoir (Bays 0 to 7) - Streamlined 38 dp height
          _buildBayRow(backlineBays, isFrontline: false),
          const SizedBox(height: 4.0),

          // Tactical Flagship Axial Discharge Action Deck (TAP TO FIRE LANCE)
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
                child: Semantics(
                  label:
                      'Axial Discharge Corridor ${activeCorridor + 1}, Tap to Fire Lance',
                  button: true,
                  child: GestureDetector(
                    onTap: () {
                      HapticService.instance.injectionClick();
                      final dir = (activeCorridor >= 4) ? -1 : 1;
                      onInjectCore(activeBay, dir);
                    },
                    child: Container(
                      height: 52.0,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            VoidTheme.plasmaCyan,
                            VoidTheme.plasmaCyanLight,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(26.0),
                        border: Border.all(
                          color: VoidTheme.starWhite.withValues(alpha: 0.6),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: VoidTheme.plasmaCyan.withValues(alpha: 0.5),
                            blurRadius: 12.0,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
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
                                    'AXIAL DISCHARGE C${activeCorridor + 1} • TAP TO FIRE LANCE',
                                    style: const TextStyle(
                                      color: VoidTheme.obsidianBlack,
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.6,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 1.0),
                          const Text(
                            'SWIPE BATTERY TO SOW • TAP TO FIRE',
                            style: TextStyle(
                              color: VoidTheme.obsidianBlack,
                              fontSize: 7.0,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
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
      child: Semantics(
        label:
            '${isFrontline ? "Frontline" : "Sub-deck"} Bay ${bay.bayIndex}, ${bay.chargeUnits} charges',
        button: true,
        selected: isSelected,
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
              HapticService.instance.injectionClick();
              onInjectCore(bay.bayIndex, 1);
            } else if (vx > 100) {
              HapticService.instance.sowTick();
              onSowAction(bay.bayIndex, 1);
            } else if (vx < -100) {
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
                  // Bay Index label & Special badges (Nyumba = 🛡️ Vault)
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
                        const Padding(
                          padding: EdgeInsets.only(left: 1.5),
                          child: Icon(
                            Icons.shield,
                            color: VoidTheme.solarGold,
                            size: 8.5,
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

                  // Accumulated Plasma Units (M) or Vault Reserve
                  Text(
                    bay.isNyumba
                        ? '🛡️ ${bay.chargeUnits}'
                        : '${bay.chargeUnits}',
                    style: TextStyle(
                      color: bay.isNyumba
                          ? VoidTheme.solarGold
                          : (bay.chargeUnits >= 4
                                ? (isFrontline
                                      ? VoidTheme.plasmaCyan
                                      : VoidTheme.solarGold)
                                : (isFrontline
                                      ? VoidTheme.textPrimary
                                      : VoidTheme.textSecondary)),
                      fontSize: bay.isNyumba
                          ? (isFrontline ? 10.5 : 9.5)
                          : (isFrontline ? 13.0 : 11.0),
                      fontWeight: FontWeight.w900,
                      height: 1.05,
                    ),
                  ),

                  // Segmented Glowing Battery Pill Dashes (Physical Energy Cells)
                  if (bay.chargeUnits > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 2.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          bay.chargeUnits.clamp(1, 4),
                          (i) => Container(
                            width: isFrontline ? 5.5 : 4.2,
                            height: isFrontline ? 2.8 : 2.2,
                            margin: const EdgeInsets.symmetric(horizontal: 0.6),
                            decoration: BoxDecoration(
                              color: bay.isNyumba
                                  ? VoidTheme.solarGold
                                  : (bay.chargeUnits >= 4
                                        ? (isFrontline
                                              ? VoidTheme.plasmaCyan
                                              : VoidTheme.solarGold)
                                        : (isFrontline
                                              ? VoidTheme.plasmaCyanLight
                                              : VoidTheme.solarGoldLight)),
                              borderRadius: BorderRadius.circular(1.2),
                              boxShadow: bay.chargeUnits >= 2
                                  ? [
                                      BoxShadow(
                                        color:
                                            (bay.isNyumba
                                                    ? VoidTheme.solarGold
                                                    : VoidTheme.plasmaCyan)
                                                .withValues(alpha: 0.45),
                                        blurRadius: 2.0,
                                      ),
                                    ]
                                  : null,
                            ),
                          ),
                        ),
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.only(top: 2.0),
                      child: Text(
                        '-',
                        style: TextStyle(
                          color: VoidTheme.textMuted.withValues(alpha: 0.6),
                          fontSize: 8.0,
                          height: 1.0,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
