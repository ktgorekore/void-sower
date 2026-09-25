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
/// Implements Sower Deck 2.0 based on the refined visual and operational specifications:
/// - Unified glassmorphic deck backplate (#0A101F with #1E293B border)
/// - 8 Frontline Bay Capsules (Bays 8–15, aligned directly under Corridors 1–8 with uniform width)
/// - 8 Return Orbit Bays (Bays 0–7, transparent return circuit with Nyumba Vault Shield Bays 3 & 4)
/// - Bidirectional Sowing Controls ([SOW LEFT], [AXIAL DISCHARGE], [SOW RIGHT]) + swipe support
/// - Zero dynamic per-frame allocation and zero candlestick distortion
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
    // Separate frontline and backline
    final frontlineBays = bays.where((b) => b.isFrontline).toList();
    final backlineBays = bays.where((b) => !b.isFrontline).toList();

    // Map selection to active corridor
    final selected = selectedBay;
    final activeCorridor = (selected != null && selected >= 8 && selected <= 15)
        ? selected - 8
        : (selected != null && selected < 8 ? selected : 0);
    final activeBay = selected ?? (activeCorridor + 8);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
      padding: const EdgeInsets.fromLTRB(8.0, 8.0, 8.0, 8.0),
      decoration: BoxDecoration(
        color: const Color(0xFF0A101F).withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: const Color(0xFF1E293B), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.75),
            blurRadius: 18.0,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // -------------------------------------------------------------------
          // 1. 8 Frontline Bay Capsules (Directly Aligned Under Corridors 1 to 8)
          // -------------------------------------------------------------------
          _buildFrontlineDeck(frontlineBays, activeCorridor, activeBay),
          const SizedBox(height: 6.0),

          // -------------------------------------------------------------------
          // 2. Return Orbit / Backline Capacitors (Bays 0 to 7)
          // -------------------------------------------------------------------
          _buildReturnOrbitDeck(backlineBays),
          const SizedBox(height: 8.0),

          // -------------------------------------------------------------------
          // 3. Bidirectional Sowing & Axial Discharge Controls
          // -------------------------------------------------------------------
          _buildTouchGesturePrompt(activeCorridor, activeBay),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 1. Frontline Deck: 8 Vertical Bay Capsules with Strict Uniform Width
  // ---------------------------------------------------------------------------
  Widget _buildFrontlineDeck(
    List<BayState> frontlineBays,
    int activeCorridor,
    int activeBay,
  ) {
    return Row(
      children: List.generate(8, (i) {
        final corridor = i;
        final targetIndex = 8 + corridor;
        final bay = frontlineBays.firstWhere(
          (b) => b.bayIndex == targetIndex,
          orElse: () => bays.firstWhere(
            (b) => b.bayIndex == targetIndex,
            orElse: () => BayState(
              bayIndex: targetIndex,
              tier: 1,
              gridColumn: corridor,
              radialPositionRad: corridor * 0.392,
              chargeUnits: 0,
              isFrontline: true,
              isNyumba: false,
              isKichwa: corridor == 0 || corridor == 7,
              isKimbi: corridor == 1 || corridor == 6,
            ),
          ),
        );

        final isSelected = selectedBay == bay.bayIndex;
        final isSowHop = activeSowBay == bay.bayIndex;

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2.0),
            child: Semantics(
              label:
                  'Corridor ${corridor + 1}, Bay ${bay.bayIndex}, ${bay.chargeUnits} charges',
              button: true,
              selected: isSelected,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Corridor notch tag (C1–C8)
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      HapticService.instance.sowTick();
                      onBaySelected(bay.bayIndex);
                      final normX = (corridor + 0.5) / 8.0;
                      onSlidePosition?.call(normX);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 2.0),
                      alignment: Alignment.center,
                      child: Text(
                        'C${corridor + 1}',
                        style: TextStyle(
                          color: isSelected
                              ? VoidTheme.plasmaCyan
                              : const Color(0xFF475569),
                          fontSize: 8.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 2.0),

                  // Frontline Bay Capsule (Height 48.0dp strictly enforced for test & feel)
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      HapticService.instance.sowTick();
                      if (isSelected) {
                        HapticService.instance.injectionClick();
                        final dir = (activeCorridor >= 4) ? -1 : 1;
                        onInjectCore(bay.bayIndex, dir);
                      } else {
                        onBaySelected(bay.bayIndex);
                        final normX = (corridor + 0.5) / 8.0;
                        onSlidePosition?.call(normX);
                      }
                    },
                    onHorizontalDragEnd: (details) {
                      final vx = details.primaryVelocity ?? 0.0;
                      if (vx > 50) {
                        HapticService.instance.sowTick();
                        onSowAction(bay.bayIndex, 1);
                      } else if (vx < -50) {
                        HapticService.instance.sowTick();
                        onSowAction(bay.bayIndex, -1);
                      }
                    },
                    onPanEnd: (details) {
                      final vx = details.velocity.pixelsPerSecond.dx;
                      final vy = details.velocity.pixelsPerSecond.dy;
                      if (vy < -80 && vy.abs() > vx.abs()) {
                        HapticService.instance.injectionClick();
                        final dir = (activeCorridor >= 4) ? -1 : 1;
                        onInjectCore(bay.bayIndex, dir);
                      } else if (vx > 50) {
                        HapticService.instance.sowTick();
                        onSowAction(bay.bayIndex, 1);
                      } else if (vx < -50) {
                        HapticService.instance.sowTick();
                        onSowAction(bay.bayIndex, -1);
                      }
                    },
                    child: Container(
                      height: 48.0,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF082F49)
                            : (isSowHop
                                  ? const Color(0xFF1E293B)
                                  : const Color(0xFF0F172A)),
                        borderRadius: BorderRadius.circular(8.0),
                        border: Border.all(
                          color: isSelected
                              ? VoidTheme.plasmaCyan
                              : (isSowHop
                                    ? VoidTheme.solarGold
                                    : const Color(0xFF1E293B)),
                          width: isSelected ? 1.4 : 1.0,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: VoidTheme.plasmaCyan.withValues(
                                    alpha: 0.35,
                                  ),
                                  blurRadius: 6.0,
                                ),
                              ]
                            : (isSowHop
                                  ? [
                                      BoxShadow(
                                        color: VoidTheme.solarGold.withValues(
                                          alpha: 0.45,
                                        ),
                                        blurRadius: 6.0,
                                      ),
                                    ]
                                  : null),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Seed Dot Clusters (Bao count-and-capture visualization)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 2.0,
                              vertical: 3.0,
                            ),
                            child: _buildPlasmaSeedCluster(
                              bay.chargeUnits,
                              isSelected,
                            ),
                          ),

                          // Special Bastion Badge for Kichwa / Kimbi
                          if (bay.isKichwa)
                            const Positioned(
                              top: 2.0,
                              child: DiamondShieldBadge(
                                size: 7.0,
                                accentColor: VoidTheme.nebulaAmethyst,
                                hasGlow: false,
                              ),
                            )
                          else if (bay.isKimbi)
                            const Positioned(
                              top: 2.0,
                              child: DiamondShieldBadge(
                                size: 7.0,
                                accentColor: VoidTheme.emeraldShield,
                                hasGlow: false,
                              ),
                            ),

                          // Bay index / charge label inside the 48dp capsule
                          Positioned(
                            bottom: 2.0,
                            child: Text(
                              isSelected && bay.chargeUnits > 0
                                  ? '${bay.chargeUnits} ⚡'
                                  : '${bay.bayIndex}',
                              style: TextStyle(
                                color: isSelected
                                    ? VoidTheme.plasmaCyan
                                    : const Color(0xFF64748B),
                                fontSize: 8.0,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  // ---------------------------------------------------------------------------
  // 2. Return Orbit Sub-Deck: Bays 0 to 7 (Inner Capacitor Ring & Nyumba Shield)
  // ---------------------------------------------------------------------------
  Widget _buildReturnOrbitDeck(List<BayState> backlineBays) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 2.0, vertical: 1.0),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'RETURN ORBIT (BAYS 0–7)',
                  style: TextStyle(
                    color: Color(0xFF475569),
                    fontSize: 7.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
                SizedBox(width: 8.0),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.shield, size: 8.5, color: VoidTheme.solarGold),
                    SizedBox(width: 3.0),
                    Text(
                      'NYUMBA CANOPY VAULT (B3 & B4)',
                      style: TextStyle(
                        color: VoidTheme.solarGold,
                        fontSize: 7.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 2.0),
        Row(
          children: List.generate(8, (i) {
            final bayIndex = i;
            final bay = backlineBays.firstWhere(
              (b) => b.bayIndex == bayIndex,
              orElse: () => bays.firstWhere(
                (b) => b.bayIndex == bayIndex,
                orElse: () => BayState(
                  bayIndex: bayIndex,
                  tier: 0,
                  gridColumn: bayIndex,
                  radialPositionRad: 0,
                  chargeUnits: 0,
                  isFrontline: false,
                  isNyumba: bayIndex == 3 || bayIndex == 4,
                  isKichwa: false,
                  isKimbi: false,
                ),
              ),
            );

            final isSelected = selectedBay == bay.bayIndex;
            final isSowHop = activeSowBay == bay.bayIndex;
            final isNyumba = bay.isNyumba;

            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2.0),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    HapticService.instance.sowTick();
                    onBaySelected(bay.bayIndex);
                  },
                  child: Container(
                    height: 28.0,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? (isNyumba
                                ? const Color(0xFF451A03)
                                : const Color(0xFF082F49))
                          : (isNyumba
                                ? const Color(0xFF271202)
                                : const Color(0xFF070D18)),
                      borderRadius: BorderRadius.circular(6.0),
                      border: Border.all(
                        color: isSelected
                            ? (isNyumba
                                  ? VoidTheme.solarGold
                                  : VoidTheme.plasmaCyan)
                            : (isSowHop
                                  ? VoidTheme.solarGold
                                  : (isNyumba
                                        ? const Color(0xFF78350F)
                                        : const Color(0xFF1E293B))),
                        width: isSelected || isNyumba ? 1.2 : 0.8,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color:
                                    (isNyumba
                                            ? VoidTheme.solarGold
                                            : VoidTheme.plasmaCyan)
                                        .withValues(alpha: 0.35),
                                blurRadius: 4.0,
                              ),
                            ]
                          : null,
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        if (bay.chargeUnits > 0)
                          Positioned(
                            top: 3.0,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: List.generate(
                                bay.chargeUnits.clamp(1, 3),
                                (ci) => Container(
                                  width: 3.5,
                                  height: 3.5,
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 0.5,
                                  ),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isNyumba
                                        ? VoidTheme.solarGold
                                        : VoidTheme.plasmaCyan,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        Positioned(
                          bottom: 2.0,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isNyumba)
                                const Padding(
                                  padding: EdgeInsets.only(right: 1.0),
                                  child: Icon(
                                    Icons.shield,
                                    size: 7.0,
                                    color: VoidTheme.solarGold,
                                  ),
                                ),
                              Text(
                                '${bay.bayIndex}',
                                style: TextStyle(
                                  color: isNyumba
                                      ? VoidTheme.solarGold
                                      : (isSelected
                                            ? VoidTheme.plasmaCyan
                                            : const Color(0xFF64748B)),
                                  fontSize: 7.5,
                                  fontWeight: FontWeight.w800,
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
            );
          }),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 3. Bidirectional Sowing & Axial Discharge Controls
  // ---------------------------------------------------------------------------
  Widget _buildTouchGesturePrompt(int activeCorridor, int activeBay) {
    return Row(
      children: [
        // SOW LEFT Button
        Expanded(
          flex: 4,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              HapticService.instance.sowTick();
              onSowAction(activeBay, -1);
            },
            child: Container(
              height: 38.0,
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              decoration: BoxDecoration(
                color: const Color(0xFF070D18),
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(
                  color: VoidTheme.plasmaCyan.withValues(alpha: 0.4),
                  width: 1.0,
                ),
              ),
              child: const FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.arrow_left,
                      size: 16.0,
                      color: VoidTheme.plasmaCyan,
                    ),
                    Text(
                      'SOW LEFT',
                      style: TextStyle(
                        color: VoidTheme.plasmaCyan,
                        fontSize: 9.5,
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
        const SizedBox(width: 4.0),

        // AXIAL DISCHARGE (Fire / Inject)
        Expanded(
          flex: 6,
          child: Semantics(
            label:
                'Axial Discharge Corridor ${activeCorridor + 1}, Tap to Fire Lance',
            button: true,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                HapticService.instance.injectionClick();
                final dir = (activeCorridor >= 4) ? -1 : 1;
                onInjectCore(activeBay, dir);
              },
              child: Container(
                height: 38.0,
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                decoration: BoxDecoration(
                  color: const Color(0xFF082F49),
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(color: VoidTheme.plasmaCyan, width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: VoidTheme.plasmaCyan.withValues(alpha: 0.25),
                      blurRadius: 6.0,
                    ),
                  ],
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.bolt,
                        size: 14.0,
                        color: Color(0xFFF59E0B),
                      ),
                      const SizedBox(width: 3.0),
                      Text(
                        'AXIAL DISCHARGE C${activeCorridor + 1}',
                        style: const TextStyle(
                          color: Color(0xFFF59E0B),
                          fontSize: 9.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 4.0),

        // SOW RIGHT Button
        Expanded(
          flex: 4,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              HapticService.instance.sowTick();
              onSowAction(activeBay, 1);
            },
            child: Container(
              height: 38.0,
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              decoration: BoxDecoration(
                color: const Color(0xFF070D18),
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(
                  color: VoidTheme.plasmaCyan.withValues(alpha: 0.4),
                  width: 1.0,
                ),
              ),
              child: const FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'SOW RIGHT',
                      style: TextStyle(
                        color: VoidTheme.plasmaCyan,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.4,
                      ),
                    ),
                    Icon(
                      Icons.arrow_right,
                      size: 16.0,
                      color: VoidTheme.plasmaCyan,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Plasma Seed Cluster Renderer (Dot layout)
  // ---------------------------------------------------------------------------
  Widget _buildPlasmaSeedCluster(int charges, bool isSelected) {
    if (charges <= 0) {
      return const SizedBox.shrink();
    }

    if (charges == 1) {
      return Center(child: _buildSingleSeed(6.0, isSelected));
    }

    if (charges == 2) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildSingleSeed(5.0, isSelected),
          const SizedBox(height: 3.0),
          _buildSingleSeed(5.0, isSelected),
        ],
      );
    }

    if (charges == 3) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildSingleSeed(4.5, isSelected),
              const SizedBox(width: 3.0),
              _buildSingleSeed(4.5, isSelected),
            ],
          ),
          const SizedBox(height: 3.0),
          _buildSingleSeed(4.5, isSelected),
        ],
      );
    }

    // 4 or more seeds (2x2 quad cluster)
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildSingleSeed(4.5, isSelected),
            const SizedBox(width: 3.0),
            _buildSingleSeed(4.5, isSelected),
          ],
        ),
        const SizedBox(height: 3.0),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildSingleSeed(4.5, isSelected),
            const SizedBox(width: 3.0),
            _buildSingleSeed(4.5, isSelected),
          ],
        ),
      ],
    );
  }

  Widget _buildSingleSeed(double size, bool isSelected) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(
          colors: [Colors.white, VoidTheme.plasmaCyan, Color(0xFF0284C7)],
        ),
        boxShadow: [
          BoxShadow(
            color: VoidTheme.plasmaCyan.withValues(
              alpha: isSelected ? 0.9 : 0.6,
            ),
            blurRadius: 4.0,
            spreadRadius: 0.5,
          ),
        ],
      ),
    );
  }
}
