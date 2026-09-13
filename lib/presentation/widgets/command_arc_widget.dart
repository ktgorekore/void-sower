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
    widget.onSlidePosition(_sliderOffset);
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
              // Frontline Tier (Bays 0 to 7)
              _buildBayRow(frontlineBays, isFrontline: true),
              const SizedBox(height: 8.0),

              // Backline Tier (Bays 8 to 15)
              _buildBayRow(backlineBays, isFrontline: false),
              const SizedBox(height: 12.0),

              // Horizontal Lateral Orbital Platform Slider
              GestureDetector(
                onPanUpdate: (d) => _handlePanUpdate(d, constraints.maxWidth),
                child: Container(
                  height: 36.0,
                  decoration: BoxDecoration(
                    color: VoidTheme.cardSurface,
                    borderRadius: BorderRadius.circular(18.0),
                    border: Border.all(
                      color: VoidTheme.textMuted.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      const Text(
                        '◀ SLIDE TO PAN DREADNOUGHT ▶',
                        style: TextStyle(
                          color: VoidTheme.textSecondary,
                          fontSize: 10.0,
                          letterSpacing: 1.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Transform.translate(
                        offset: Offset(_sliderOffset, 0),
                        child: Container(
                          width: 54.0,
                          height: 28.0,
                          decoration: BoxDecoration(
                            color: VoidTheme.solarGold,
                            borderRadius: BorderRadius.circular(14.0),
                            boxShadow: [
                              BoxShadow(
                                color: VoidTheme.solarGold.withValues(
                                  alpha: 0.4,
                                ),
                                blurRadius: 8.0,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.drag_handle,
                            color: VoidTheme.obsidianBlack,
                            size: 18.0,
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
    if (isSelected) {
      borderColor = VoidTheme.plasmaCyan;
    } else if (bay.isNyumba) {
      borderColor = VoidTheme.solarGold;
    } else if (bay.isKichwa) {
      borderColor = VoidTheme.nebulaAmethyst;
    } else if (bay.isKimbi) {
      borderColor = Colors.tealAccent;
    }

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          HapticService.instance.sowTick();
          widget.onBaySelected(bay.bayIndex);
        },
        onHorizontalDragEnd: (details) {
          final velocity = details.primaryVelocity ?? 0;
          if (velocity > 150) {
            // Swipe right = Clockwise (+1)
            HapticService.instance.sowTick();
            widget.onSowAction(bay.bayIndex, 1);
          } else if (velocity < -150) {
            // Swipe left = Counter-Clockwise (-1)
            HapticService.instance.sowTick();
            widget.onSowAction(bay.bayIndex, -1);
          }
        },
        onVerticalDragEnd: (details) {
          final velocity = details.primaryVelocity ?? 0;
          if (velocity < -150) {
            // Upward flick = Core Injection (namua)
            HapticService.instance.injectionClick();
            widget.onInjectCore(bay.bayIndex, 1);
          }
        },
        child: Container(
          height: 52.0,
          margin: const EdgeInsets.symmetric(horizontal: 2.0),
          decoration: BoxDecoration(
            color: isSelected
                ? VoidTheme.plasmaCyan.withValues(alpha: 0.2)
                : VoidTheme.cardSurface,
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
                ],
              ),
              const SizedBox(height: 2.0),

              // Accumulated Plasma Units (M)
              Text(
                '${bay.chargeUnits}',
                style: TextStyle(
                  color: bay.chargeUnits >= 4
                      ? (isFrontline
                            ? VoidTheme.plasmaCyan
                            : VoidTheme.solarGold)
                      : VoidTheme.textPrimary,
                  fontSize: 15.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
