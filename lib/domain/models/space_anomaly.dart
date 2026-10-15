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

/// Classification of discoverable 3D deep-space anomalies encountered during flight.
enum SpaceAnomalyType {
  /// Crystalline plasma core cache (+4 reserve cores on interception or lance hit).
  coreCache,

  /// Ancient Bao relic pod (unlocks/activates a sowing relic buff or draft).
  ancientRelic,

  /// Ionized nebula surge (grants +1 Yoté tactical cull charge and weapon surge).
  ionNebulaSurge,
}

/// Pre-allocated mutable 3D space anomaly slot for zero-allocation 60/120 Hz traversal.
class SpaceAnomaly {
  /// Creates a pre-allocated [SpaceAnomaly] slot.
  SpaceAnomaly({
    this.id = 0,
    this.type = SpaceAnomalyType.coreCache,
    this.corridor = 0,
    this.normX = 0.5,
    this.normZ = 1.0,
    this.elevationY = 0.18,
    this.velocityZ = 0.08,
    this.rotationRad = 0.0,
    this.active = false,
  });

  /// Unique monotonic identifier for this anomaly spawn.
  int id;

  /// Type of reward granted upon discovery/interception.
  SpaceAnomalyType type;

  /// Orbital corridor index (`0..7`).
  int corridor;

  /// Normalized lateral X position (`0.0` to `1.0`).
  double normX;

  /// Normalized 3D trench depth (`1.0` = far deep space, `0.0` = defense perimeter).
  double normZ;

  /// Normalized 3D vertical altitude (`0.0` to `1.0`).
  double elevationY;

  /// Forward drift speed toward the Defender along the Z axis.
  double velocityZ;

  /// Continuous 3D polyhedral rotation angle in radians.
  double rotationRad;

  /// Whether this pool slot is currently active in 3D space.
  bool active;
}
