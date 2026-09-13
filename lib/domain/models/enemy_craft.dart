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

/// State representation of an enemy assault craft.
class EnemyCraft {
  const EnemyCraft({
    required this.entityId,
    required this.assignedCorridor,
    required this.worldPosX,
    required this.worldPosY,
    required this.velocityY,
    required this.currentShields,
    required this.maxShields,
    required this.currentHull,
    required this.maxHull,
    required this.vesselType,
    required this.isDestroyed,
  });

  final int entityId;
  final int assignedCorridor;
  final double worldPosX;
  final double worldPosY;
  final double velocityY;
  final double currentShields;
  final double maxShields;
  final double currentHull;
  final double maxHull;
  final int vesselType; // 0: Drone, 1: Cruiser, 2: Flagship
  final bool isDestroyed;
}
