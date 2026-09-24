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
import 'diamond_shield_badge.dart';

/// Primary thumb command arc managing the 16 physical capacitor battery cells
/// and axial particle lance discharge.
///
/// Implements the high-tech physical battery deck from the 3.0 specification:
/// - Projection shelf with active corridor alignment and relay multiplier
/// - Frontline battery cells (C1–C8) featuring physical terminal caps and segmented LED charge gauges
/// - Distinct Diamond Shield emblems for special tactical bays (Kichwa 8/15, Kimbi 9/14, Nyumba 3/4)
/// - Sub-deck reservoir tier (R1–R8) with golden Nyumba vault reactors
/// - Ergonomic one-thumb rounded pill trigger button (54 dp)
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

    final selected = selectedBay;
    final activeCorridor = (selected != null && selected >= 8 && selected <= 15)
        ? selected - 8
        : (selected != null && selected < 8 ? selected : 0);
    final activeBay = selected ?? (activeCorridor + 8);

    return Container(
      padding: const EdgeInsets.fromLTRB(6.0, 3.0, 6.0, 5.0),
      decoration: BoxDecoration(
        color: const Color(0xFF0B1320),
        border: Border(
          top: BorderSide(
            color: VoidTheme.plasmaCyan.withValues(alpha: 0.35),
            width: 1.5,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.8),
            blurRadius: 16.0,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // -------------------------------------------------------------------
          // 1. Projection Shelf Bar (Lance Alignment + Relay Status)
          // -------------------------------------------------------------------
          Container(
            margin: const EdgeInsets.only(bottom: 4.0),
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3.0),
            decoration: BoxDecoration(
              color: VoidTheme.cardSurface.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(6.0),
              border: Border.all(
                color: VoidTheme.plasmaCyan.withValues(alpha: 0.25),
                width: 0.8,
              ),
            ),
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
                        Container(
                          width: 6.0,
                          height: 6.0,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: VoidTheme.plasmaCyan,
                            boxShadow: [
                              BoxShadow(
                                color: VoidTheme.plasmaCyan,
                                blurRadius: 5.0,
                                spreadRadius: 1.0,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 5.0),
                        Text(
                          'LANCE ALIGNED: CORRIDOR ${activeCorridor + 1}',
                          style: const TextStyle(
                            color: VoidTheme.starWhite,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 6.0),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6.0,
                    vertical: 2.0,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF080C14),
                    borderRadius: BorderRadius.circular(8.0),
                    border: Border.all(color: VoidTheme.plasmaCyan, width: 0.9),
                  ),
                  child: const Text(
                    'RELAY x2',
                    style: TextStyle(
                      color: VoidTheme.plasmaCyan,
                      fontSize: 8.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // -------------------------------------------------------------------
          // 2. Frontline Tier Header (▲ BAYS 8-15)
          // -------------------------------------------------------------------
          Padding(
            padding: const EdgeInsets.only(bottom: 2.0, left: 2.0, right: 2.0),
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
                            fontSize: 7.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.6,
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
                    fontSize: 7.0,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),

          // -------------------------------------------------------------------
          // 3. Corridor Aiming Badges C1–C8
          // -------------------------------------------------------------------
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
                        height: 22.0,
                        margin: const EdgeInsets.symmetric(horizontal: 1.0),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? VoidTheme.plasmaCyan.withValues(alpha: 0.35)
                              : const Color(0xFF101C2E),
                          borderRadius: BorderRadius.circular(4.0),
                          border: Border.all(
                            color: isSelected
                                ? VoidTheme.plasmaCyan
                                : VoidTheme.cardSurface,
                            width: isSelected ? 1.4 : 0.8,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: VoidTheme.plasmaCyan.withValues(
                                      alpha: 0.45,
                                    ),
                                    blurRadius: 5.0,
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
                              fontSize: 8.5,
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

          // -------------------------------------------------------------------
          // 4. Physical Frontline Batteries (Real Battery Casings & LED Bars)
          // -------------------------------------------------------------------
          _buildFrontlineBatteryRow(frontlineBays),
          const SizedBox(height: 4.0),

          // -------------------------------------------------------------------
          // 5. Backline Sub-Deck Header (▼ BAYS 0-7 RESERVOIR)
          // -------------------------------------------------------------------
          Padding(
            padding: const EdgeInsets.only(bottom: 2.0, left: 2.0, right: 2.0),
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
                            fontSize: 7.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.6,
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
                    fontSize: 7.0,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),

          // -------------------------------------------------------------------
          // 6. Sub-Deck Reservoir Cells R1–R8 (Nyumba Vault R4 & R5 in Gold)
          // -------------------------------------------------------------------
          _buildReservoirRow(backlineBays),
          const SizedBox(height: 5.0),

          // -------------------------------------------------------------------
          // 7. Tactical Pill Trigger Button (⚡ INJECT & DISCHARGE C[X])
          // -------------------------------------------------------------------
          Semantics(
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
                height: 50.0,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00E5FF), Color(0xFF5DF2FF)],
                  ),
                  borderRadius: BorderRadius.circular(25.0),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.8),
                    width: 1.4,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x6600E5FF),
                      blurRadius: 12.0,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.bolt, color: Colors.black, size: 16.0),
                        const SizedBox(width: 4.0),
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              'AXIAL DISCHARGE C${activeCorridor + 1}',
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 12.0,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.7,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 1.0),
                    const Text(
                      'SWIPE BATTERY TO SOW • QUADRATIC BURST',
                      style: TextStyle(
                        color: Colors.black,
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
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Frontline Physical Battery Row (C1 to C8)
  // ---------------------------------------------------------------------------
  Widget _buildFrontlineBatteryRow(List<BayState> rowBays) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: rowBays.map((bay) => _buildPhysicalBatteryCell(bay)).toList(),
    );
  }

  /// Builds a realistic physical capacitor battery cell:
  /// - Raised positive terminal cap on top
  /// - Rounded cylindrical metallic casing
  /// - Stack of horizontal segmented LED charge bars
  /// - Diamond Shield badge for special tactical bastions (Kichwa 8/15, Kimbi 9/14)
  Widget _buildPhysicalBatteryCell(BayState bay) {
    final isSelected = selectedBay == bay.bayIndex;
    final isSowHop = activeSowBay == bay.bayIndex;

    Color borderColor = VoidTheme.cardSurface;
    Color glowColor = Colors.transparent;

    if (isSowHop) {
      borderColor = VoidTheme.solarGold;
      glowColor = VoidTheme.solarGold.withValues(alpha: 0.6);
    } else if (isSelected) {
      borderColor = VoidTheme.plasmaCyan;
      glowColor = VoidTheme.plasmaCyan.withValues(alpha: 0.45);
    } else if (bay.isKichwa) {
      borderColor = VoidTheme.nebulaAmethyst;
      glowColor = VoidTheme.nebulaAmethyst.withValues(alpha: 0.25);
    } else if (bay.isKimbi) {
      borderColor = VoidTheme.emeraldShield;
      glowColor = VoidTheme.emeraldShield.withValues(alpha: 0.25);
    }

    return Expanded(
      child: Semantics(
        label: 'Frontline Battery ${bay.bayIndex}, ${bay.chargeUnits} charges',
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
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 1.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Battery Terminal Cap with Bay Index printed
                  Container(
                    width: 14.0,
                    height: 4.0,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? VoidTheme.plasmaCyan
                          : const Color(0xFF334E68),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(2.0),
                      ),
                    ),
                  ),

                  // Battery Cylinder Body (48 dp height for ergonomic touch target)
                  Container(
                    height: 48.0,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF132A40)
                          : const Color(0xFF101C2E),
                      borderRadius: BorderRadius.circular(6.0),
                      border: Border.all(
                        color: borderColor,
                        width: isSelected ? 1.6 : 1.0,
                      ),
                      boxShadow: isSelected || glowColor != Colors.transparent
                          ? [
                              BoxShadow(
                                color: glowColor,
                                blurRadius: isSelected ? 8.0 : 4.0,
                              ),
                            ]
                          : null,
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Stack of Horizontal Segmented LED Charge Bars
                        Positioned.fill(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 3.5,
                              vertical: 4.5,
                            ),
                            child: _buildBatterySegmentBars(
                              bay.chargeUnits,
                              isSelected,
                            ),
                          ),
                        ),

                        // Special Tactical Bay Badge: Diamond Shield
                        if (bay.isKichwa)
                          Positioned(
                            top: 2.0,
                            child: DiamondShieldBadge(
                              size: 13.0,
                              accentColor: VoidTheme.nebulaAmethyst,
                              tooltip: 'Kichwa Tactical Head',
                            ),
                          )
                        else if (bay.isKimbi)
                          Positioned(
                            top: 2.0,
                            child: DiamondShieldBadge(
                              size: 13.0,
                              accentColor: VoidTheme.emeraldShield,
                              tooltip: 'Kimbi Tactical Bastion',
                            ),
                          ),

                        // Bay Index & Charge Counter Overlay at Bottom
                        Positioned(
                          bottom: 2.0,
                          child: Text(
                            '${bay.bayIndex}',
                            style: TextStyle(
                              color: bay.chargeUnits > 0
                                  ? (isSelected
                                        ? VoidTheme.plasmaCyan
                                        : VoidTheme.starWhite)
                                  : VoidTheme.textMuted,
                              fontSize: 8.5,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
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

  /// Builds 6 horizontal stacked LED indicator bars simulating a real battery gauge.
  Widget _buildBatterySegmentBars(int chargeUnits, bool isSelected) {
    const totalBars = 6;
    // Calculate how many bars should be lit
    int litBars = 0;
    if (chargeUnits == 1) {
      litBars = 2;
    } else if (chargeUnits == 2) {
      litBars = 3;
    } else if (chargeUnits == 3) {
      litBars = 4;
    } else if (chargeUnits >= 4) {
      litBars = totalBars;
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(totalBars, (index) {
        // Bars are filled from bottom to top
        final barIndexFromBottom = totalBars - 1 - index;
        final isLit = barIndexFromBottom < litBars;

        final barColor = isLit
            ? (chargeUnits >= 4
                  ? VoidTheme.plasmaCyan
                  : VoidTheme.plasmaCyanLight)
            : const Color(0xFF1B2A3D);

        return Container(
          height: 3.5,
          margin: const EdgeInsets.symmetric(horizontal: 1.5),
          decoration: BoxDecoration(
            color: barColor,
            borderRadius: BorderRadius.circular(1.5),
            boxShadow: isLit
                ? [
                    BoxShadow(
                      color: barColor.withValues(alpha: 0.6),
                      blurRadius: 3.0,
                      spreadRadius: 0.5,
                    ),
                  ]
                : null,
          ),
        );
      }),
    );
  }

  // ---------------------------------------------------------------------------
  // Backline Reservoir Row (R1 to R8)
  // ---------------------------------------------------------------------------
  Widget _buildReservoirRow(List<BayState> rowBays) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: rowBays.map((bay) => _buildReservoirCell(bay)).toList(),
    );
  }

  /// Builds a sub-deck reservoir cell:
  /// - Labeled R1 to R8 (and bay index)
  /// - Central Bays 3 & 4 (R4 & R5) styled in warm solar gold with Diamond Vault Shield
  Widget _buildReservoirCell(BayState bay) {
    final isSelected = selectedBay == bay.bayIndex;
    final isSowHop = activeSowBay == bay.bayIndex;
    final rIndex = bay.bayIndex + 1; // R1 to R8

    Color borderColor = VoidTheme.cardSurface;
    Color cellBg = const Color(0xFF0D1B2A);
    Color glowColor = Colors.transparent;

    if (isSowHop) {
      borderColor = VoidTheme.solarGold;
      glowColor = VoidTheme.solarGold.withValues(alpha: 0.5);
    } else if (isSelected) {
      borderColor = VoidTheme.plasmaCyan;
      glowColor = VoidTheme.plasmaCyan.withValues(alpha: 0.4);
    } else if (bay.isNyumba) {
      borderColor = VoidTheme.solarGold;
      cellBg = const Color(0xFF1E1C12);
      glowColor = VoidTheme.solarGold.withValues(alpha: 0.25);
    }

    return Expanded(
      child: Semantics(
        label:
            'Reservoir Bay ${bay.bayIndex}${bay.isNyumba ? " Nyumba Vault" : ""}, ${bay.chargeUnits} charges',
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
              height: 38.0,
              margin: const EdgeInsets.symmetric(horizontal: 1.0),
              decoration: BoxDecoration(
                color: cellBg,
                borderRadius: BorderRadius.circular(5.0),
                border: Border.all(
                  color: borderColor,
                  width: bay.isNyumba || isSelected ? 1.5 : 0.8,
                ),
                boxShadow: isSelected || glowColor != Colors.transparent
                    ? [BoxShadow(color: glowColor, blurRadius: 5.0)]
                    : null,
              ),
              child: bay.isNyumba
                  ? _buildNyumbaVaultContent(bay, rIndex)
                  : _buildStandardReservoirContent(bay, rIndex, isSelected),
            ),
          ),
        ),
      ),
    );
  }

  /// Builds the specialized Nyumba Vault cell (R4 / R5) in warm solar gold.
  Widget _buildNyumbaVaultContent(BayState bay, int rIndex) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${bay.bayIndex}',
              style: const TextStyle(
                color: VoidTheme.solarGold,
                fontSize: 8.0,
                fontWeight: FontWeight.w900,
                height: 1.0,
              ),
            ),
            const SizedBox(width: 1.5),
            const DiamondShieldBadge(
              size: 9.5,
              accentColor: VoidTheme.solarGold,
              hasGlow: false,
            ),
          ],
        ),
        const SizedBox(height: 1.0),
        const Text(
          'NYUMBA',
          style: TextStyle(
            color: VoidTheme.solarGold,
            fontSize: 5.8,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.3,
            height: 1.0,
          ),
        ),
        const SizedBox(height: 1.0),
        Text(
          '🛡️ ${bay.chargeUnits}',
          style: const TextStyle(
            color: VoidTheme.solarGold,
            fontSize: 8.5,
            fontWeight: FontWeight.w900,
            height: 1.0,
          ),
        ),
      ],
    );
  }

  /// Builds a standard reservoir storage cell (R1, R2, R3, R6, R7, R8).
  Widget _buildStandardReservoirContent(
    BayState bay,
    int rIndex,
    bool isSelected,
  ) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '${bay.bayIndex}',
          style: TextStyle(
            color: isSelected ? VoidTheme.plasmaCyan : VoidTheme.textMuted,
            fontSize: 7.5,
            fontWeight: FontWeight.bold,
            height: 1.0,
          ),
        ),
        const SizedBox(height: 1.0),
        Text(
          bay.chargeUnits > 0 ? '${bay.chargeUnits}' : '-',
          style: TextStyle(
            color: bay.chargeUnits > 0
                ? VoidTheme.starWhite
                : VoidTheme.textMuted,
            fontSize: 9.5,
            fontWeight: FontWeight.w900,
            height: 1.0,
          ),
        ),
      ],
    );
  }
}
