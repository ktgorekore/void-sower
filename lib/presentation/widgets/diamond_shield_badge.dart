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

import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../theme/void_theme.dart';

/// Distinct Afrofuturistic Diamond Shield emblem used for tactical special bays
/// (Kichwa head bays 8 & 15, Kimbi flank bastions 9 & 14, and Nyumba vault bays 3 & 4).
class DiamondShieldBadge extends StatelessWidget {
  const DiamondShieldBadge({
    super.key,
    this.size = 18.0,
    required this.accentColor,
    this.label,
    this.tooltip,
    this.hasGlow = true,
  });

  final double size;
  final Color accentColor;
  final String? label;
  final String? tooltip;
  final bool hasGlow;

  @override
  Widget build(BuildContext context) {
    final widgetContent = SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Rotated Diamond Plaque with Glowing Border
          Transform.rotate(
            angle: math.pi / 4,
            child: Container(
              width: size * 0.72,
              height: size * 0.72,
              decoration: BoxDecoration(
                color: VoidTheme.obsidianBlack.withValues(alpha: 0.9),
                border: Border.all(color: accentColor, width: 1.2),
                borderRadius: BorderRadius.circular(2.0),
                boxShadow: hasGlow
                    ? [
                        BoxShadow(
                          color: accentColor.withValues(alpha: 0.5),
                          blurRadius: 6.0,
                          spreadRadius: 0.5,
                        ),
                      ]
                    : null,
              ),
            ),
          ),

          // Central Shield Icon
          Icon(Icons.shield, size: size * 0.55, color: accentColor),

          // Optional Sub-badge overlay (e.g. bay or charge number)
          if (label != null)
            Positioned(
              bottom: 0,
              child: Text(
                label!,
                style: TextStyle(
                  color: accentColor,
                  fontSize: 7.0,
                  fontWeight: FontWeight.w900,
                  height: 1.0,
                ),
              ),
            ),
        ],
      ),
    );

    if (tooltip != null) {
      return Tooltip(message: tooltip!, child: widgetContent);
    }
    return widgetContent;
  }
}
