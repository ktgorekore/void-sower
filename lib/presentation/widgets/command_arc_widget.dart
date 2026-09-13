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

/// Lower 30% Primary Thumb Command Arc managing the 16 capacitor bays and dreadnought slider.
class CommandArcWidget extends StatefulWidget {
  const CommandArcWidget({
    super.key,
    required this.bays,
    required this.selectedBay,
    required this.onBaySelected,
    required this.onSowAction,
    required this.onInjectCore,
    required this.onSlidePosition,
  });

  final List<BayState> bays;
  final int? selectedBay;
  final ValueChanged<int> onBaySelected;
  final void Function(int bayIndex, int direction) onSowAction;
  final void Function(int bayIndex, int direction) onInjectCore;
  final ValueChanged<double> onSlidePosition;

  @override
  State<CommandArcWidget> createState() => _CommandArcWidgetState();
}

class _CommandArcWidgetState extends State<CommandArcWidget> {
  double _sliderOffset = 0.0;

  void _handlePanUpdate(DragUpdateDetails details, double maxWidth) {
    setState(() {
      _sliderOffset = (_sliderOffset + details.delta.dx).clamp(
        -maxWidth / 3,
        maxWidth / 3,
      );
    });
    final normalizedX = (0.5 + (_sliderOffset / maxWidth)).clamp(0.0, 1.0);
    widget.onSlidePosition(normalizedX);
  }

  @override
  Widget build(BuildContext context) {
    final frontlineBays = widget.bays.where((b) => b.isFrontline).toList();
    final backlineBays = widget.bays.where((b) => !b.isFrontline).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
          decoration: BoxDecoration(
            color: VoidTheme.obsidianBlack,
            border: const Border(
              top: BorderSide(color: VoidTheme.cardSurface, width: 1.5),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Gesture Guide Bar
              Padding(
                padding: const EdgeInsets.only(bottom: 6.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.touch_app,
                      size: 12.0,
                      color: VoidTheme.plasmaCyan,
                    ),
                    const SizedBox(width: 4.0),
                    Text(
                      'TAP: SELECT  •  SWIPE: SOW  •  FLICK ▲: INJECT',
                      style: TextStyle(
                        color: VoidTheme.textSecondary.withValues(alpha: 0.8),
                        fontSize: 9.5,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),

              // Frontline Tier (Bays 0 to 7)
              _buildBayRow(frontlineBays, isFrontline: true),
              const SizedBox(height: 6.0),

              // Backline Tier (Bays 8 to 15)
              _buildBayRow(backlineBays, isFrontline: false),
              const SizedBox(height: 10.0),

              // Horizontal Lateral Orbital Platform Slider
              GestureDetector(
                onPanUpdate: (d) => _handlePanUpdate(d, constraints.maxWidth),
                child: Container(
                  height: 38.0,
                  decoration: BoxDecoration(
                    color: VoidTheme.cardSurface,
                    borderRadius: BorderRadius.circular(19.0),
                    border: Border.all(
                      color: VoidTheme.textMuted.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Corridor Grid Notches
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: List.generate(8, (i) {
                          return Text(
                            'C${i + 1}',
                            style: TextStyle(
                              color: VoidTheme.textMuted.withValues(alpha: 0.6),
                              fontSize: 9.0,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        }),
                      ),
                      Transform.translate(
                        offset: Offset(_sliderOffset, 0),
                        child: Container(
                          width: 58.0,
                          height: 30.0,
                          decoration: BoxDecoration(
                            color: VoidTheme.solarGold,
                            borderRadius: BorderRadius.circular(15.0),
                            boxShadow: [
                              BoxShadow(
                                color: VoidTheme.solarGold.withValues(
                                  alpha: 0.45,
                                ),
                                blurRadius: 10.0,
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.chevron_left,
                                color: VoidTheme.obsidianBlack,
                                size: 14.0,
                              ),
                              Icon(
                                Icons.rocket,
                                color: VoidTheme.obsidianBlack,
                                size: 16.0,
                              ),
                              Icon(
                                Icons.chevron_right,
                                color: VoidTheme.obsidianBlack,
                                size: 14.0,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBayRow(List<BayState> rowBays, {required bool isFrontline}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: rowBays.map((bay) => _buildBayCell(bay, isFrontline)).toList(),
    );
  }

  Widget _buildBayCell(BayState bay, bool isFrontline) {
    final isSelected = widget.selectedBay == bay.bayIndex;

    Color borderColor = VoidTheme.textMuted.withValues(alpha: 0.4);
    Color bayGlow = Colors.transparent;
    if (isSelected) {
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
          widget.onBaySelected(bay.bayIndex);
        },
        onDoubleTap: () {
          HapticService.instance.injectionClick();
          widget.onInjectCore(bay.bayIndex, 1);
        },
        onPanEnd: (details) {
          final vx = details.velocity.pixelsPerSecond.dx;
          final vy = details.velocity.pixelsPerSecond.dy;
          if (vy < -120 && vy.abs() > vx.abs()) {
            // Upward flick = Core Injection (namua)
            HapticService.instance.injectionClick();
            widget.onInjectCore(bay.bayIndex, 1);
          } else if (vx > 100) {
            // Swipe right = Clockwise (+1)
            HapticService.instance.sowTick();
            widget.onSowAction(bay.bayIndex, 1);
          } else if (vx < -100) {
            // Swipe left = Counter-Clockwise (-1)
            HapticService.instance.sowTick();
            widget.onSowAction(bay.bayIndex, -1);
          }
        },
        child: Container(
          height: 56.0,
          margin: const EdgeInsets.symmetric(horizontal: 1.5),
          decoration: BoxDecoration(
            color: isSelected
                ? VoidTheme.plasmaCyan.withValues(alpha: 0.22)
                : (bayGlow != Colors.transparent
                      ? bayGlow
                      : VoidTheme.cardSurface),
            borderRadius: BorderRadius.circular(6.0),
            border: Border.all(
              color: borderColor,
              width: isSelected || bay.isNyumba ? 2.0 : 1.0,
            ),
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
                          ? VoidTheme.plasmaCyan
                          : VoidTheme.textSecondary,
                      fontSize: 10.0,
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
              const SizedBox(height: 1.0),

              // Accumulated Plasma Units (M)
              Text(
                '${bay.chargeUnits}',
                style: TextStyle(
                  color: bay.chargeUnits >= 4
                      ? (isFrontline
                            ? VoidTheme.plasmaCyan
                            : VoidTheme.solarGold)
                      : VoidTheme.textPrimary,
                  fontSize: 14.0,
                  fontWeight: FontWeight.bold,
                ),
              ),

              // Concentric Charge Pips (Up to 4 pips)
              if (bay.chargeUnits > 0)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    bay.chargeUnits.clamp(1, 4),
                    (i) => Container(
                      width: 3.5,
                      height: 3.5,
                      margin: const EdgeInsets.symmetric(horizontal: 0.6),
                      decoration: BoxDecoration(
                        color: bay.chargeUnits >= 4
                            ? VoidTheme.plasmaCyan
                            : VoidTheme.solarGold,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
