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
/// Implements Sower Deck 2.0 based on the redesigned visual specification:
/// - Unified glassmorphic deck backplate (#0A101F with #1E293B border)
/// - 8 Frontline Bay Capsules (aligned directly with Corridors 1 to 8)
/// - Tactile Glowing Plasma Seed clusters (Bao mancala dot layouts)
/// - Sleek Sub-Deck Reservoir Tray with golden Nyumba Vault Shield sanctum
/// - Contextual Gesture Action Prompt (Swipe to Sow • Tap to Axial Discharge)
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

    // Sum stored charges in reservoir
    final storedReservoirCharges = backlineBays.fold<int>(
      0,
      (sum, b) => sum + b.chargeUnits,
    );

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
      padding: const EdgeInsets.fromLTRB(10.0, 8.0, 10.0, 8.0),
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
          const SizedBox(height: 8.0),

          // -------------------------------------------------------------------
          // 2. Sowing Loop / Sub-Deck Reservoir Tray (Bays 0 to 7 Reimagined)
          // -------------------------------------------------------------------
          _buildReservoirTray(backlineBays, storedReservoirCharges),
          const SizedBox(height: 6.0),

          // -------------------------------------------------------------------
          // 3. Contextual Gesture Action Prompt (Swipe to Sow • Tap to Discharge)
          // -------------------------------------------------------------------
          _buildTouchGesturePrompt(activeCorridor, activeBay),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 1. Frontline Deck: 8 Vertical Bay Capsules
  // ---------------------------------------------------------------------------
  Widget _buildFrontlineDeck(
    List<BayState> frontlineBays,
    int activeCorridor,
    int activeBay,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(8, (i) {
        final corridor = i;
        final bay = frontlineBays.firstWhere(
          (b) => b.bayIndex == (8 + corridor) || b.gridColumn == corridor,
          orElse: () => BayState(
            bayIndex: 8 + corridor,
            tier: 1,
            gridColumn: corridor,
            radialPositionRad: corridor * 0.392,
            chargeUnits: 0,
            isFrontline: true,
            isNyumba: false,
            isKichwa: corridor == 0 || corridor == 7,
            isKimbi: corridor == 1 || corridor == 6,
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
              child: AnimatedScale(
                scale: isSowHop ? 1.08 : 1.0,
                duration: const Duration(milliseconds: 140),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Corridor notch tag (C1–C8) with dedicated tap target
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

                    // Ergonomic Bay Capsule (48 dp height required by test)
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
                      onDoubleTap: () {
                        HapticService.instance.injectionClick();
                        final dir = (activeCorridor >= 4) ? -1 : 1;
                        onInjectCore(bay.bayIndex, dir);
                      },
                      onPanEnd: (details) {
                        final vx = details.velocity.pixelsPerSecond.dx;
                        final vy = details.velocity.pixelsPerSecond.dy;
                        if (vy < -100 && vy.abs() > vx.abs()) {
                          HapticService.instance.injectionClick();
                          final dir = (activeCorridor >= 4) ? -1 : 1;
                          onInjectCore(bay.bayIndex, dir);
                        } else if (vx > 80) {
                          HapticService.instance.sowTick();
                          onSowAction(bay.bayIndex, 1);
                        } else if (vx < -80) {
                          HapticService.instance.sowTick();
                          onSowAction(bay.bayIndex, -1);
                        }
                      },
                      child: Container(
                        height: 48.0,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF082F49)
                              : const Color(0xFF0F172A),
                          borderRadius: BorderRadius.circular(8.0),
                          border: Border.all(
                            color: isSelected
                                ? VoidTheme.plasmaCyan
                                : (isSowHop
                                      ? VoidTheme.solarGold
                                      : const Color(0xFF1E293B)),
                            width: isSelected ? 1.8 : 1.0,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: VoidTheme.plasmaCyan.withValues(
                                      alpha: 0.45,
                                    ),
                                    blurRadius: 8.0,
                                    spreadRadius: 1.0,
                                  ),
                                ]
                              : null,
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
                                  size: 7.5,
                                  accentColor: VoidTheme.nebulaAmethyst,
                                  hasGlow: false,
                                ),
                              )
                            else if (bay.isKimbi)
                              const Positioned(
                                top: 2.0,
                                child: DiamondShieldBadge(
                                  size: 7.5,
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
          ),
        );
      }),
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
        gradient: RadialGradient(
          colors: [Colors.white, VoidTheme.plasmaCyan, const Color(0xFF0284C7)],
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

  Widget _buildAmberSeed(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(
          colors: [Color(0xFFFFFBEB), Color(0xFFF59E0B), Color(0xFFB45309)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF59E0B).withValues(alpha: 0.7),
            blurRadius: 3.5,
            spreadRadius: 0.5,
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 2. Sub-Deck Reservoir Tray: Nyumba Vault Shield + Stored Reserve
  // ---------------------------------------------------------------------------
  Widget _buildReservoirTray(List<BayState> backlineBays, int storedCharges) {
    // Find Nyumba bays (3 & 4)
    final bay3 = backlineBays.firstWhere(
      (b) => b.bayIndex == 3,
      orElse: () => const BayState(
        bayIndex: 3,
        tier: 0,
        gridColumn: 3,
        radialPositionRad: 0,
        chargeUnits: 0,
        isFrontline: false,
        isNyumba: true,
        isKichwa: false,
        isKimbi: false,
      ),
    );
    final bay4 = backlineBays.firstWhere(
      (b) => b.bayIndex == 4,
      orElse: () => const BayState(
        bayIndex: 4,
        tier: 0,
        gridColumn: 4,
        radialPositionRad: 0,
        chargeUnits: 0,
        isFrontline: false,
        isNyumba: true,
        isKichwa: false,
        isKimbi: false,
      ),
    );

    final nyumbaTotal = bay3.chargeUnits + bay4.chargeUnits;

    return Container(
      height: 44.0,
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: const Color(0xFF060C18),
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(color: const Color(0xFF1E293B), width: 1.0),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Left: RESERVOIR label
            const Text(
              'RESERVOIR',
              style: TextStyle(
                color: Color(0xFF475569),
                fontSize: 8.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(width: 12.0),

            // Center: Nyumba Vault Shield (Bays 3 & 4)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                HapticService.instance.sowTick();
                onBaySelected(3);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10.0,
                  vertical: 3.0,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF451A03),
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(
                    color: const Color(0xFFF59E0B),
                    width: 1.2,
                  ),
                  boxShadow: const [
                    BoxShadow(color: Color(0x33F59E0B), blurRadius: 4.0),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.shield,
                      size: 11.0,
                      color: Color(0xFFF59E0B),
                    ),
                    const SizedBox(width: 4.0),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'NYUMBA',
                          style: TextStyle(
                            color: Color(0xFFFBBF24),
                            fontSize: 8.0,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.6,
                          ),
                        ),
                        Text(
                          'VAULT SHIELD $nyumbaTotal',
                          style: const TextStyle(
                            color: Color(0xFFD97706),
                            fontSize: 6.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12.0),

            // Right: Stored reserve cores
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildAmberSeed(5.0),
                const SizedBox(width: 3.0),
                _buildAmberSeed(5.0),
                const SizedBox(width: 5.0),
                Text(
                  '+$storedCharges STORED',
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 8.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 3. Contextual Gesture Action Prompt (Swipe to Sow • Tap to Discharge)
  // ---------------------------------------------------------------------------
  Widget _buildTouchGesturePrompt(int activeCorridor, int activeBay) {
    return Semantics(
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
          padding: const EdgeInsets.symmetric(horizontal: 10.0),
          decoration: BoxDecoration(
            color: const Color(0xFF070D18),
            borderRadius: BorderRadius.circular(10.0),
            border: Border.all(
              color: VoidTheme.plasmaCyan.withValues(alpha: 0.3),
              width: 1.0,
            ),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Swipe hint
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.swap_horiz,
                      size: 13.0,
                      color: VoidTheme.plasmaCyan,
                    ),
                    const SizedBox(width: 3.0),
                    RichText(
                      text: const TextSpan(
                        children: [
                          TextSpan(
                            text: 'SWIPE ',
                            style: TextStyle(
                              color: VoidTheme.plasmaCyan,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          TextSpan(
                            text: 'TO SOW',
                            style: TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 9.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Center divider dot
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0),
                  child: Container(
                    width: 3.5,
                    height: 3.5,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF334155),
                    ),
                  ),
                ),

                // Tap to Discharge hint (contains 'AXIAL DISCHARGE' for test expectation)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.bolt,
                      size: 13.0,
                      color: Color(0xFFF59E0B),
                    ),
                    const SizedBox(width: 3.0),
                    Text(
                      'TAP TO AXIAL DISCHARGE C${activeCorridor + 1}',
                      style: const TextStyle(
                        color: Color(0xFFF59E0B),
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
