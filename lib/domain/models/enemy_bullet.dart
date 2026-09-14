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

/// Descending enemy plasma projectile fired from assault craft down corridors.
class EnemyBullet {
  EnemyBullet({
    required this.id,
    required this.assignedCorridor,
    required this.x,
    required this.y,
    this.velocityY = 190.0,
    this.radius = 4.5,
    this.damage = 10,
    required this.color,
  });

  final int id;
  final int assignedCorridor;
  double x;
  double y;
  final double velocityY;
  final double radius;
  final int damage;
  final Color color;

  /// Updates projectile descent along Y axis.
  bool update(double dt) {
    y += velocityY * dt;
    return true;
  }
}
