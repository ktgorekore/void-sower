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

/// Arcade floating damage number drifting upward on impacts.
/// Pre-computes its TextPainter layout upon instantiation to guarantee
/// zero allocation and zero layout passes on 60 FPS rendering hot paths.
class FloatingDamageNumber {
  FloatingDamageNumber({
    required this.text,
    required this.x,
    required this.y,
    required this.color,
    this.lifetime = 0.75,
    this.isCritical = false,
  }) : remainingLifetime = lifetime,
       textPainter = TextPainter(
         text: TextSpan(
           text: text,
           style: TextStyle(
             color: color,
             fontSize: isCritical ? 15.0 : 12.0,
             fontWeight: FontWeight.bold,
             shadows: const [Shadow(color: Colors.black, blurRadius: 4.0)],
           ),
         ),
         textDirection: TextDirection.ltr,
       )..layout();

  final String text;
  final double x;
  double y;
  final Color color;
  final double lifetime;
  double remainingLifetime;
  final bool isCritical;

  /// Pre-computed text layout for zero-allocation rendering.
  final TextPainter textPainter;

  /// Updates lifetime and upward drift position. Returns true while still alive.
  bool update(double dt) {
    remainingLifetime -= dt;
    y -= 50.0 * dt;
    return remainingLifetime > 0.0;
  }
}
