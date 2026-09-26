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
import 'diamond_shield_badge.dart';

/// Primary thumb command arc managing the 16 physical capacitor battery cells
/// and axial particle lance discharge.
///
/// Implements Sower Deck 3.0 based on the minimalist gesture-driven specifications:
/// - Unified glassmorphic deck backplate (#0A101F with #1E293B border)
/// - 8 Frontline Bay Capsules (Bays 8–15, aligned directly under Corridors 1–8 with uniform width)
/// - 8 Return Orbit Bays (Bays 0–7, compact return circuit with Nyumba Vault Shield Bays 3 & 4)
/// - Fluid gesture-driven sowing and core injection without button clutter
/// - Zero dynamic per-frame allocation and zero candlestick distortion
class CommandArcWidget extends StatelessWidget {
  const CommandArcWidget({
    super.key,
    required this.bays,
    required this.selectedBay,
    this.activeSowBay,
    this.sowDirection = 1,
    required this.onBaySelected,
    required this.onSowAction,
    required this.onInjectCore,
    this.onSlidePosition,
    this.onDirectionChanged,
    this.tacticalAdvice,
  });

  final List<BayState> bays;
  final int? selectedBay;
  final int? activeSowBay;
  final int sowDirection;
  final ValueChanged<int> onBaySelected;
  final void Function(int bayIndex, int direction) onSowAction;
  final void Function(int bayIndex, int direction) onInjectCore;
  final ValueChanged<double>? onSlidePosition;
  final ValueChanged<int>? onDirectionChanged;
  final TacticalAdvice? tacticalAdvice;

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
      padding: const EdgeInsets.all(6.0),
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
          const SizedBox(height: 4.0),

          // -------------------------------------------------------------------
          // 2. Return Orbit / Backline Capacitors (Bays 0 to 7)
          // -------------------------------------------------------------------
          _buildReturnOrbitDeck(backlineBays),

          // -------------------------------------------------------------------
          // 2b. Holographic Tactical Advisor Banner (if primed)
          // -------------------------------------------------------------------
          if (tacticalAdvice != null) ...[
            const SizedBox(height: 4.0),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8.0,
                vertical: 3.0,
              ),
              decoration: BoxDecoration(
                color:
                    (tacticalAdvice!.isEmergencyBreach
                            ? VoidTheme.crimsonFlare
                            : VoidTheme.solarGold)
                        .withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6.0),
                border: Border.all(
                  color: tacticalAdvice!.isEmergencyBreach
                      ? VoidTheme.crimsonFlare
                      : VoidTheme.solarGold,
                  width: 1.0,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    tacticalAdvice!.isEmergencyBreach
                        ? Icons.warning_amber_rounded
                        : Icons.psychology,
                    size: 13.0,
                    color: tacticalAdvice!.isEmergencyBreach
                        ? VoidTheme.crimsonFlare
                        : VoidTheme.solarGold,
                  ),
                  const SizedBox(width: 4.0),
                  Expanded(
                    child: Text(
                      tacticalAdvice!.explanation,
                      style: TextStyle(
                        color: tacticalAdvice!.isEmergencyBreach
                            ? VoidTheme.crimsonFlare
                            : VoidTheme.solarGold,
                        fontSize: 9.0,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 4.0),
                  Text(
                    'PRO ADVISOR',
                    style: TextStyle(
                      color:
                          (tacticalAdvice!.isEmergencyBreach
                                  ? VoidTheme.crimsonFlare
                                  : VoidTheme.solarGold)
                              .withValues(alpha: 0.8),
                      fontSize: 7.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
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
        final isAdvisorBay = tacticalAdvice?.recommendedBay == bay.bayIndex;

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
                  // Raised Positive Terminal Cap
                  Container(
                    width: 14.0,
                    height: 3.5,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? VoidTheme.plasmaCyan
                          : (isAdvisorBay
                                ? (tacticalAdvice!.isEmergencyBreach
                                      ? VoidTheme.crimsonFlare
                                      : VoidTheme.solarGold)
                                : const Color(0xFF334E68)),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(2.0),
                      ),
                    ),
                  ),

                  // Frontline Battery Cylinder Body (Height 48.0dp strictly enforced for test & feel)
                  _FrontlineBayCylinder(
                    bay: bay,
                    corridor: corridor,
                    isSelected: isSelected,
                    isSowHop: isSowHop,
                    isAdvisorBay: isAdvisorBay,
                    activeDirection: sowDirection,
                    tacticalAdvice: tacticalAdvice,
                    onTap: () {
                      HapticService.instance.sowTick();
                      final resolvedDir = BayRole.resolveSowDirection(
                        bay.bayIndex,
                        sowDirection,
                      );
                      if (isSelected) {
                        HapticService.instance.injectionClick();
                        onDirectionChanged?.call(resolvedDir);
                        onInjectCore(bay.bayIndex, resolvedDir);
                      } else {
                        onBaySelected(bay.bayIndex);
                        onDirectionChanged?.call(resolvedDir);
                        final normX = (corridor + 0.5) / 8.0;
                        onSlidePosition?.call(normX);
                      }
                    },
                    onSowAction: (bayIndex, direction) {
                      onDirectionChanged?.call(direction);
                      onSowAction(bayIndex, direction);
                    },
                    onInjectCore: onInjectCore,
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
    return Row(
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
        final isAdvisorBay = tacticalAdvice?.recommendedBay == bay.bayIndex;
        final isNyumba = bay.isNyumba;

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2.0),
            child: _ReturnOrbitBayCell(
              bay: bay,
              isSelected: isSelected,
              isSowHop: isSowHop,
              isAdvisorBay: isAdvisorBay,
              isNyumba: isNyumba,
              activeDirection: sowDirection,
              tacticalAdvice: tacticalAdvice,
              onTap: () {
                HapticService.instance.sowTick();
                onBaySelected(bay.bayIndex);
              },
              onSowAction: (bayIndex, direction) {
                onDirectionChanged?.call(direction);
                onSowAction(bayIndex, direction);
              },
            ),
          ),
        );
      }),
    );
  }
}

// -----------------------------------------------------------------------------
// Frontline Bay Capsule with Precise Gesture Disambiguation & Displacement Tracking
// -----------------------------------------------------------------------------
class _FrontlineBayCylinder extends StatefulWidget {
  const _FrontlineBayCylinder({
    required this.bay,
    required this.corridor,
    required this.isSelected,
    required this.isSowHop,
    required this.isAdvisorBay,
    required this.activeDirection,
    this.tacticalAdvice,
    required this.onTap,
    required this.onSowAction,
    required this.onInjectCore,
  });

  final BayState bay;
  final int corridor;
  final bool isSelected;
  final bool isSowHop;
  final bool isAdvisorBay;
  final int activeDirection;
  final TacticalAdvice? tacticalAdvice;
  final VoidCallback onTap;
  final void Function(int bayIndex, int direction) onSowAction;
  final void Function(int bayIndex, int direction) onInjectCore;

  @override
  State<_FrontlineBayCylinder> createState() => _FrontlineBayCylinderState();
}

class _FrontlineBayCylinderState extends State<_FrontlineBayCylinder> {
  double _dragDx = 0.0;
  double _dragDy = 0.0;

  @override
  Widget build(BuildContext context) {
    final bay = widget.bay;
    final isSelected = widget.isSelected;
    final isSowHop = widget.isSowHop;
    final isAdvisorBay = widget.isAdvisorBay;
    final tacticalAdvice = widget.tacticalAdvice;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      onPanStart: (_) {
        _dragDx = 0.0;
        _dragDy = 0.0;
      },
      onPanUpdate: (details) {
        _dragDx += details.delta.dx;
        _dragDy += details.delta.dy;
      },
      onPanEnd: (details) {
        final vx = details.velocity.pixelsPerSecond.dx;
        final vy = details.velocity.pixelsPerSecond.dy;

        // 1. Upward flick -> Inject Core (Namua)
        if ((_dragDy < -16.0 || vy < -60.0) && _dragDy.abs() > _dragDx.abs()) {
          HapticService.instance.injectionClick();
          final resolvedDir = BayRole.resolveSowDirection(
            bay.bayIndex,
            widget.activeDirection,
          );
          widget.onInjectCore(bay.bayIndex, resolvedDir);
        }
        // 2. Swiped RIGHT (Clockwise)
        else if (_dragDx > 6.0 || vx > 20.0) {
          HapticService.instance.sowTick();
          final resolvedDir = BayRole.resolveSowDirection(bay.bayIndex, 1);
          widget.onSowAction(bay.bayIndex, resolvedDir);
        }
        // 3. Swiped LEFT (Counter-Clockwise)
        else if (_dragDx < -6.0 || vx < -20.0) {
          HapticService.instance.sowTick();
          final resolvedDir = BayRole.resolveSowDirection(bay.bayIndex, -1);
          widget.onSowAction(bay.bayIndex, resolvedDir);
        }
      },
      child: Container(
        height: 48.0,
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF132A40)
              : (isSowHop ? const Color(0xFF1E293B) : const Color(0xFF101C2E)),
          borderRadius: BorderRadius.circular(6.0),
          border: Border.all(
            color: isSelected
                ? VoidTheme.plasmaCyan
                : (isAdvisorBay
                      ? (tacticalAdvice?.isEmergencyBreach == true
                            ? VoidTheme.crimsonFlare
                            : VoidTheme.solarGold)
                      : (isSowHop
                            ? VoidTheme.solarGold
                            : (bay.isKichwa
                                  ? VoidTheme.nebulaAmethyst
                                  : (bay.isKimbi
                                        ? VoidTheme.emeraldShield
                                        : const Color(0xFF1E293B))))),
            width: isSelected || isAdvisorBay ? 1.4 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: VoidTheme.plasmaCyan.withValues(alpha: 0.35),
                    blurRadius: 6.0,
                  ),
                ]
              : (isAdvisorBay
                    ? [
                        BoxShadow(
                          color:
                              (tacticalAdvice?.isEmergencyBreach == true
                                      ? VoidTheme.crimsonFlare
                                      : VoidTheme.solarGold)
                                  .withValues(alpha: 0.45),
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
                          : null)),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Holographic Tactical Advisor Direction Reticle
            if (isAdvisorBay && tacticalAdvice != null)
              Positioned(
                top: 2.0,
                right: 2.0,
                child: Icon(
                  tacticalAdvice.recommendedDirection > 0
                      ? Icons.arrow_forward
                      : Icons.arrow_back,
                  size: 8.5,
                  color: tacticalAdvice.isEmergencyBreach
                      ? VoidTheme.crimsonFlare
                      : VoidTheme.solarGold,
                ),
              ),
            // 6 Horizontal Stacked LED Indicator Bars (Battery Gauge)
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 3.0,
                  vertical: 4.0,
                ),
                child: _buildBatterySegmentBars(bay.chargeUnits, isSelected),
              ),
            ),

            // Special Bastion Badge for Kichwa / Kimbi
            if (bay.isKichwa)
              const Positioned(
                top: 2.0,
                child: DiamondShieldBadge(
                  size: 8.0,
                  accentColor: VoidTheme.nebulaAmethyst,
                  hasGlow: false,
                ),
              )
            else if (bay.isKimbi)
              const Positioned(
                top: 2.0,
                child: DiamondShieldBadge(
                  size: 8.0,
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
                      : (bay.chargeUnits > 0
                            ? VoidTheme.starWhite
                            : const Color(0xFF64748B)),
                  fontSize: 8.0,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Return Orbit Bay Cell with Swipe Support
// -----------------------------------------------------------------------------
class _ReturnOrbitBayCell extends StatefulWidget {
  const _ReturnOrbitBayCell({
    required this.bay,
    required this.isSelected,
    required this.isSowHop,
    required this.isAdvisorBay,
    required this.isNyumba,
    required this.activeDirection,
    this.tacticalAdvice,
    required this.onTap,
    required this.onSowAction,
  });

  final BayState bay;
  final bool isSelected;
  final bool isSowHop;
  final bool isAdvisorBay;
  final bool isNyumba;
  final int activeDirection;
  final TacticalAdvice? tacticalAdvice;
  final VoidCallback onTap;
  final void Function(int bayIndex, int direction) onSowAction;

  @override
  State<_ReturnOrbitBayCell> createState() => _ReturnOrbitBayCellState();
}

class _ReturnOrbitBayCellState extends State<_ReturnOrbitBayCell> {
  double _dragDx = 0.0;

  @override
  Widget build(BuildContext context) {
    final bay = widget.bay;
    final isSelected = widget.isSelected;
    final isSowHop = widget.isSowHop;
    final isAdvisorBay = widget.isAdvisorBay;
    final isNyumba = widget.isNyumba;
    final tacticalAdvice = widget.tacticalAdvice;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      onPanStart: (_) => _dragDx = 0.0,
      onPanUpdate: (details) => _dragDx += details.delta.dx,
      onPanEnd: (details) {
        final vx = details.velocity.pixelsPerSecond.dx;
        if (_dragDx > 6.0 || vx > 20.0) {
          HapticService.instance.sowTick();
          final resolvedDir = BayRole.resolveSowDirection(bay.bayIndex, 1);
          widget.onSowAction(bay.bayIndex, resolvedDir);
        } else if (_dragDx < -6.0 || vx < -20.0) {
          HapticService.instance.sowTick();
          final resolvedDir = BayRole.resolveSowDirection(bay.bayIndex, -1);
          widget.onSowAction(bay.bayIndex, resolvedDir);
        }
      },
      child: Container(
        height: 28.0,
        decoration: BoxDecoration(
          color: isSelected
              ? (isNyumba ? const Color(0xFF451A03) : const Color(0xFF082F49))
              : (isNyumba ? const Color(0xFF271202) : const Color(0xFF070D18)),
          borderRadius: BorderRadius.circular(6.0),
          border: Border.all(
            color: isSelected
                ? (isNyumba ? VoidTheme.solarGold : VoidTheme.plasmaCyan)
                : (isAdvisorBay
                      ? (tacticalAdvice?.isEmergencyBreach == true
                            ? VoidTheme.crimsonFlare
                            : VoidTheme.solarGold)
                      : (isSowHop
                            ? VoidTheme.solarGold
                            : (isNyumba
                                  ? const Color(0xFF78350F)
                                  : const Color(0xFF1E293B)))),
            width: isSelected || isNyumba || isAdvisorBay ? 1.2 : 0.8,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color:
                        (isNyumba ? VoidTheme.solarGold : VoidTheme.plasmaCyan)
                            .withValues(alpha: 0.35),
                    blurRadius: 4.0,
                  ),
                ]
              : (isAdvisorBay
                    ? [
                        BoxShadow(
                          color:
                              (tacticalAdvice?.isEmergencyBreach == true
                                      ? VoidTheme.crimsonFlare
                                      : VoidTheme.solarGold)
                                  .withValues(alpha: 0.35),
                          blurRadius: 4.0,
                        ),
                      ]
                    : null),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (isAdvisorBay && tacticalAdvice != null)
              Positioned(
                top: 1.0,
                right: 2.0,
                child: Icon(
                  tacticalAdvice.recommendedDirection > 0
                      ? Icons.arrow_forward
                      : Icons.arrow_back,
                  size: 7.0,
                  color: tacticalAdvice.isEmergencyBreach
                      ? VoidTheme.crimsonFlare
                      : VoidTheme.solarGold,
                ),
              ),
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
                      margin: const EdgeInsets.symmetric(horizontal: 0.5),
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
    );
  }
}

// -----------------------------------------------------------------------------
// Physical Battery Segment Bars (6-Stage Horizontal LED Charge Gauge)
// -----------------------------------------------------------------------------
Widget _buildBatterySegmentBars(int chargeUnits, bool isSelected) {
  const totalBars = 6;
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
      final barIndexFromBottom = totalBars - 1 - index;
      final isLit = barIndexFromBottom < litBars;

      final barColor = isLit
          ? (chargeUnits >= 4
                ? VoidTheme.plasmaCyan
                : VoidTheme.plasmaCyanLight)
          : const Color(0xFF1B2A3D);

      return Container(
        height: 3.2,
        margin: const EdgeInsets.symmetric(horizontal: 1.0),
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
