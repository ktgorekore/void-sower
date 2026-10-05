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

/// State representation of an enemy assault craft with 3D spatial flight telemetry.
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
    this.worldPosZ = 0.0,
    this.bankAngleRad = 0.0,
    this.pitchAngleRad = 0.0,
    this.behaviorMode = 0,
    this.warpInProgress = 1.0,
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

  /// Spatial altitude depth in 3D theater (0.0: deep space, 1.0: defense perimeter).
  final double worldPosZ;

  /// 3D banking roll angle in radians (-0.6 to +0.6).
  final double bankAngleRad;

  /// 3D dive pitch angle in radians (-0.4 to +0.4).
  final double pitchAngleRad;

  /// Behavioral AI mode (0: Standard, 1: Swooper, 2: Weaver, 3: Kamikaze, 4: Splitter).
  final int behaviorMode;

  /// Holographic warp-in distortion progress (0.0 to 1.0).
  final double warpInProgress;

  EnemyCraft copyWith({
    int? entityId,
    int? assignedCorridor,
    double? worldPosX,
    double? worldPosY,
    double? velocityY,
    double? currentShields,
    double? maxShields,
    double? currentHull,
    double? maxHull,
    int? vesselType,
    bool? isDestroyed,
    double? worldPosZ,
    double? bankAngleRad,
    double? pitchAngleRad,
    int? behaviorMode,
    double? warpInProgress,
  }) {
    return EnemyCraft(
      entityId: entityId ?? this.entityId,
      assignedCorridor: assignedCorridor ?? this.assignedCorridor,
      worldPosX: worldPosX ?? this.worldPosX,
      worldPosY: worldPosY ?? this.worldPosY,
      velocityY: velocityY ?? this.velocityY,
      currentShields: currentShields ?? this.currentShields,
      maxShields: maxShields ?? this.maxShields,
      currentHull: currentHull ?? this.currentHull,
      maxHull: maxHull ?? this.maxHull,
      vesselType: vesselType ?? this.vesselType,
      isDestroyed: isDestroyed ?? this.isDestroyed,
      worldPosZ: worldPosZ ?? this.worldPosZ,
      bankAngleRad: bankAngleRad ?? this.bankAngleRad,
      pitchAngleRad: pitchAngleRad ?? this.pitchAngleRad,
      behaviorMode: behaviorMode ?? this.behaviorMode,
      warpInProgress: warpInProgress ?? this.warpInProgress,
    );
  }
}
