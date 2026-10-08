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

/// Ultra-compact 142px Mancala Battery Dock matching UX 3.0 specification.
///
/// Features:
/// 1. Top row of 8 frontline battery cells (C1–C8) directly aligned with attack corridors.
///    - Active primed corridor has an upward alignment arrow, glowing cyan pulse frame,
///      and a direct-tap white `FIRE` trigger.
/// 2. Bottom row of mini return capacitors (B0–B2, B5–B7) and a central gold
///    dual-chamber Nyumba Vault (B3 & B4).
/// 3. Zero cognitive clutter, tactile gestures (swipe to sow, flick up to inject, tap to fire).
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
  final ValueChanged<double>? onSlidePosition;
  final ValueChanged<int>? onDirectionChanged;
  final TacticalAdvice? tacticalAdvice;

  @override
  Widget build(BuildContext context) {
    final frontlineBays = bays.where((b) => b.isFrontline).toList()
      ..sort((a, b) => a.bayIndex.compareTo(b.bayIndex));
    final backlineBays = bays.where((b) => !b.isFrontline).toList()
      ..sort((a, b) => a.bayIndex.compareTo(b.bayIndex));

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Master Shielded Dock Frame (142px Height)
        Container(
          height: 142.0,
          margin: const EdgeInsets.symmetric(horizontal: 10.0),
          padding: const EdgeInsets.fromLTRB(10.0, 8.0, 10.0, 8.0),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xE60E1726), Color(0xF2070B14)],
            ),
            borderRadius: BorderRadius.circular(18.0),
            border: Border.all(color: const Color(0xFF1E293B), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.65),
                blurRadius: 18.0,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Dock Header Bar
              _buildDockHeader(),
              const SizedBox(height: 6.0),

              // 2. Row 1: 8 Frontline Battery Cells (C1–C8)
              Expanded(flex: 55, child: _buildFrontlineRow(frontlineBays)),

              const SizedBox(height: 5.0),

              // 3. Row 2: Mini Return Orbit Cells & Gold Nyumba Vault (B0–B7)
              Expanded(flex: 40, child: _buildBacklineRow(backlineBays)),
            ],
          ),
        ),

        const SizedBox(height: 3.0),

        // Fixed-Height Subtle Advisory Bar (Available to everyone, zero vertical jitter)
        _buildSubtleAdvisoryBar(),
      ],
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
                  'TACTICAL ADVISORY: SOW BAY ${advice.recommendedBay} $dirStr • EST. ${advice.predictedDamage.toInt()} DMG',
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
            'SLIDE DEFENDER IN 3D SPACE • SWIPE TO SOW • TAP CONDUIT TO FIRE',
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

  /// Builds the top header of the dock with clean labels.
  Widget _buildDockHeader() {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: const [
          Text(
            'ORBITAL BATTERY CONDUITS (C1–C8)',
            style: TextStyle(
              color: Color(0xFF64748B),
              fontSize: 7.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.0,
            ),
          ),
          SizedBox(width: 12.0),
          Text(
            '‹ SWIPE PIT TO SOW • TAP TO FIRE ›',
            style: TextStyle(
              color: Color(0xFF0284C7),
              fontSize: 7.0,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  /// Builds Row 1: 8 frontline battery cells with alignment indicator and FIRE trigger.
  Widget _buildFrontlineRow(List<BayState> frontlineBays) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
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

        final isAligned = corridor == activeCorridor;
        final isSelected = selectedBay == bay.bayIndex;
        final isSowHop = activeSowBay == bay.bayIndex;

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2.0),
            child: _Ux3FrontlineCell(
              bay: bay,
              corridor: corridor,
              isAligned: isAligned,
              isSelected: isSelected,
              isSowHop: isSowHop,
              activeDirection: sowDirection,
              onTap: () {
                HapticService.instance.sowTick();
                if (isAligned) {
                  onQuickFire();
                } else {
                  onBaySelected(bay.bayIndex);
                  final normX = (corridor + 0.5) / 8.0;
                  onSlidePosition?.call(normX);
                }
              },
              onFire: onQuickFire,
              onSowAction: onSowAction,
              onInjectCore: onInjectCore,
            ),
          ),
        );
      }),
    );
  }

  /// Builds Row 2: Sub-deck return capacitors B0–B2, B5–B7 and central Gold Nyumba Vault.
  Widget _buildBacklineRow(List<BayState> backlineBays) {
    BayState getBay(int index) {
      return backlineBays.firstWhere(
        (b) => b.bayIndex == index,
        orElse: () => bays.firstWhere(
          (b) => b.bayIndex == index,
          orElse: () => BayState(
            bayIndex: index,
            tier: 0,
            gridColumn: index,
            radialPositionRad: 0,
            chargeUnits: 0,
            isFrontline: false,
            isNyumba: index == 3 || index == 4,
            isKichwa: false,
            isKimbi: false,
          ),
        ),
      );
    }

    final b0 = getBay(0);
    final b1 = getBay(1);
    final b2 = getBay(2);
    final b3 = getBay(3);
    final b4 = getBay(4);
    final b5 = getBay(5);
    final b6 = getBay(6);
    final b7 = getBay(7);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Left mini return cells B0, B1, B2
        Expanded(child: _buildMiniReturnCell(b0, 'B0')),
        const SizedBox(width: 4.0),
        Expanded(child: _buildMiniReturnCell(b1, 'B1')),
        const SizedBox(width: 4.0),
        Expanded(child: _buildMiniReturnCell(b2, 'B2')),
        const SizedBox(width: 4.0),

        // Central Gold Nyumba Vault (Dual-Chamber B3 & B4)
        Expanded(flex: 2, child: _buildNyumbaDualVault(b3, b4)),

        const SizedBox(width: 4.0),
        // Right mini return cells B5, B6, B7
        Expanded(child: _buildMiniReturnCell(b5, 'B5')),
        const SizedBox(width: 4.0),
        Expanded(child: _buildMiniReturnCell(b6, 'B6')),
        const SizedBox(width: 4.0),
        Expanded(child: _buildMiniReturnCell(b7, 'B7')),
      ],
    );
  }

  /// Builds a mini return orbit cell (B0, B1, B2, B5, B6, B7).
  Widget _buildMiniReturnCell(BayState bay, String label) {
    final count = bay.chargeUnits;
    final isSelected = selectedBay == bay.bayIndex;
    final isSowHop = activeSowBay == bay.bayIndex;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        HapticService.instance.sowTick();
        onBaySelected(bay.bayIndex);
      },
      onHorizontalDragEnd: (details) {
        final vx = details.velocity.pixelsPerSecond.dx;
        if (vx.abs() > 20.0) {
          final dir = vx > 0 ? 1 : -1;
          HapticService.instance.sowTick();
          onSowAction(bay.bayIndex, dir);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF132A40)
              : (isSowHop ? const Color(0xFF1E293B) : const Color(0xFF080D1A)),
          borderRadius: BorderRadius.circular(4.0),
          border: Border.all(
            color: isSelected
                ? VoidTheme.plasmaCyan
                : (isSowHop ? VoidTheme.solarGold : const Color(0xFF1E293B)),
            width: isSelected || isSowHop ? 1.2 : 0.8,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$count',
              style: TextStyle(
                color: count > 0
                    ? const Color(0xFF94A3B8)
                    : const Color(0xFF334155),
                fontSize: 8.5,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: count > 0
                    ? const Color(0xFF64748B)
                    : const Color(0xFF334155),
                fontSize: 6.0,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the central Gold Nyumba Vault (Dual chamber B3 & B4).
  Widget _buildNyumbaDualVault(BayState b3, BayState b4) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF291503),
        borderRadius: BorderRadius.circular(6.0),
        border: Border.all(color: const Color(0xFFF59E0B), width: 1.3),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF59E0B).withValues(alpha: 0.25),
            blurRadius: 6.0,
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              // Chamber B3
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    HapticService.instance.sowTick();
                    onBaySelected(b3.bayIndex);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 2.0),
                    decoration: BoxDecoration(
                      color: const Color(0xFF78350F),
                      borderRadius: BorderRadius.circular(2.5),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${b3.chargeUnits}',
                      style: const TextStyle(
                        color: Color(0xFFFEF3C7),
                        fontSize: 9.0,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 3.0),
              // Chamber B4
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    HapticService.instance.sowTick();
                    onBaySelected(b4.bayIndex);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 2.0),
                    decoration: BoxDecoration(
                      color: const Color(0xFF78350F),
                      borderRadius: BorderRadius.circular(2.5),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${b4.chargeUnits}',
                      style: const TextStyle(
                        color: Color(0xFFFEF3C7),
                        fontSize: 9.0,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2.0),
          const Text(
            'NYUMBA',
            style: TextStyle(
              color: Color(0xFFFBBF24),
              fontSize: 6.5,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }
}

/// Frontline battery cell capsule with gesture handling and primed FIRE button.
class _Ux3FrontlineCell extends StatefulWidget {
  const _Ux3FrontlineCell({
    required this.bay,
    required this.corridor,
    required this.isAligned,
    required this.isSelected,
    required this.isSowHop,
    required this.activeDirection,
    required this.onTap,
    required this.onFire,
    required this.onSowAction,
    required this.onInjectCore,
  });

  final BayState bay;
  final int corridor;
  final bool isAligned;
  final bool isSelected;
  final bool isSowHop;
  final int activeDirection;
  final VoidCallback onTap;
  final VoidCallback onFire;
  final void Function(int bayIndex, int direction) onSowAction;
  final void Function(int bayIndex, int direction) onInjectCore;

  @override
  State<_Ux3FrontlineCell> createState() => _Ux3FrontlineCellState();
}

class _Ux3FrontlineCellState extends State<_Ux3FrontlineCell> {
  double _dragDx = 0.0;
  double _dragDy = 0.0;

  @override
  Widget build(BuildContext context) {
    final bay = widget.bay;
    final isAligned = widget.isAligned;
    final isSelected = widget.isSelected;
    final isSowHop = widget.isSowHop;
    final count = bay.chargeUnits;
    final label = 'C${widget.corridor + 1}';

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

        // Upward flick -> Inject Core (Namua)
        if ((_dragDy < -16.0 || vy < -60.0) && _dragDy.abs() > _dragDx.abs()) {
          HapticService.instance.injectionClick();
          final dir = BayRole.resolveSowDirection(
            bay.bayIndex,
            widget.activeDirection,
          );
          widget.onInjectCore(bay.bayIndex, dir);
        }
        // Swipe Right
        else if (_dragDx > 6.0 || vx > 20.0) {
          HapticService.instance.sowTick();
          final dir = BayRole.resolveSowDirection(bay.bayIndex, 1);
          widget.onSowAction(bay.bayIndex, dir);
        }
        // Swipe Left
        else if (_dragDx < -6.0 || vx < -20.0) {
          HapticService.instance.sowTick();
          final dir = BayRole.resolveSowDirection(bay.bayIndex, -1);
          widget.onSowAction(bay.bayIndex, dir);
        }
      },
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          // Alignment Indicator Arrow
          if (isAligned)
            Positioned(
              top: -6.0,
              child: CustomPaint(
                size: const Size(8.0, 5.0),
                painter: _UpwardArrowPainter(color: const Color(0xFF00F0FF)),
              ),
            ),

          // Main Cell Container
          Container(
            decoration: BoxDecoration(
              color: isAligned
                  ? const Color(0xFF022A4A)
                  : (isSelected
                        ? const Color(0xFF0C243B)
                        : (count > 0
                              ? const Color(0xFF081324)
                              : const Color(0xFF060913))),
              borderRadius: BorderRadius.circular(6.0),
              border: Border.all(
                color: isAligned
                    ? Colors.white
                    : (isSelected
                          ? VoidTheme.plasmaCyan
                          : (isSowHop
                                ? VoidTheme.solarGold
                                : const Color(0xFF1E293B))),
                width: isAligned ? 1.8 : (isSelected ? 1.4 : 1.0),
              ),
              boxShadow: isAligned
                  ? [
                      BoxShadow(
                        color: const Color(0xFF00F0FF).withValues(alpha: 0.5),
                        blurRadius: 8.0,
                      ),
                    ]
                  : (isSelected
                        ? [
                            BoxShadow(
                              color: VoidTheme.plasmaCyan.withValues(
                                alpha: 0.3,
                              ),
                              blurRadius: 5.0,
                            ),
                          ]
                        : null),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Core count on top
                Padding(
                  padding: const EdgeInsets.only(top: 2.0),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      color: isAligned
                          ? Colors.white
                          : (count > 0
                                ? const Color(0xFFE2E8F0)
                                : const Color(0xFF334155)),
                      fontSize: isAligned ? 12.0 : 10.0,
                      fontWeight: FontWeight.w900,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

                // 2. Battery segment bars
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4.0,
                      vertical: 2.0,
                    ),
                    child: isAligned
                        ? Container(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [Color(0xFF38BDF8), Color(0xFF0284C7)],
                              ),
                              borderRadius: BorderRadius.circular(2.0),
                            ),
                          )
                        : _buildBatteryBars(count),
                  ),
                ),

                // 3. Bottom Trigger or Corridor Tag
                if (isAligned)
                  GestureDetector(
                    onTap: widget.onFire,
                    child: Container(
                      margin: const EdgeInsets.fromLTRB(2.0, 0, 2.0, 2.0),
                      padding: const EdgeInsets.symmetric(vertical: 2.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(3.0),
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        'FIRE',
                        style: TextStyle(
                          color: Color(0xFF0369A1),
                          fontSize: 6.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2.0),
                    child: Text(
                      label,
                      style: TextStyle(
                        color: count > 0
                            ? const Color(0xFF64748B)
                            : const Color(0xFF334155),
                        fontSize: 6.5,
                        fontWeight: FontWeight.w800,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Builds stacked horizontal LED bars for charge volume.
  Widget _buildBatteryBars(int charges) {
    const maxBars = 4;
    final filledBars = (charges / 2).ceil().clamp(0, maxBars);

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: List.generate(maxBars, (idx) {
        final barIndexFromBottom = maxBars - 1 - idx;
        final isFilled = barIndexFromBottom < filledBars;
        return Container(
          height: 2.5,
          margin: const EdgeInsets.symmetric(vertical: 0.8),
          decoration: BoxDecoration(
            color: isFilled
                ? const Color(0xFF0284C7)
                : const Color(0xFF1E293B).withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(1.0),
          ),
        );
      }),
    );
  }
}

class _UpwardArrowPainter extends CustomPainter {
  const _UpwardArrowPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(size.width / 2, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _UpwardArrowPainter oldDelegate) =>
      color != oldDelegate.color;
}
