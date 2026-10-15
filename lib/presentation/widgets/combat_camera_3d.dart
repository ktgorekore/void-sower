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

/// Camera perspective modes for the 3D orbital trench battlefield.
enum CombatCameraMode {
  /// Low-slung over-the-shoulder 3D chase camera behind the Dreadnought.
  chase3D('CHASE 3D', 26.0, 0.0),

  /// Angled 3D isometric command bridge view showing side profiles & altitude.
  bridge3D('BRIDGE 3D', 38.0, -22.0),

  /// User-adjustable 3D free-orbit perspective camera.
  orbit3D('ORBIT 3D', 32.0, 18.0),

  /// High-altitude tactical overview camera.
  topDown('TOP-DOWN', 76.0, 0.0);

  const CombatCameraMode(this.label, this.defaultPitchDeg, this.defaultYawDeg);

  /// Display label for the HUD camera selector.
  final String label;

  /// Default camera pitch angle in degrees (15° = horizon-hugging, 80° = top-down).
  final double defaultPitchDeg;

  /// Default camera yaw angle in degrees (-45° = starboard orbit, +45° = port orbit).
  final double defaultYawDeg;
}

/// Projected 2D screen coordinate and perspective scale factor for a 3D world point.
class ProjectedPoint3D {
  /// Creates an immutable [ProjectedPoint3D].
  const ProjectedPoint3D({
    required this.screenOffset,
    required this.groundOffset,
    required this.perspectiveScale,
    required this.normZ,
  });

  /// Projected 2D screen coordinate including 3D vertical altitude elevation.
  final Offset screenOffset;

  /// Projected 2D screen coordinate of the point's vertical shadow on the trench floor (Y = 0).
  final Offset groundOffset;

  /// Perspective foreshortening scale factor (1.0 at Z = 0 threshold, smaller at far Z).
  final double perspectiveScale;

  /// Normalized depth along the trench (0.0 = near threshold, 1.0 = far apogee horizon).
  final double normZ;
}

/// Zero-allocation 3D perspective camera projector for the Void Sower space battlefield.
///
/// Transforms normalized 3D orbital trench coordinates `(normX, elevationY, normZ)`
/// into 2D viewport screen coordinates with configurable camera pitch, yaw, and
/// dynamic lateral chase tracking.
class CombatCamera3D {
  /// Creates a [CombatCamera3D] configuration.
  const CombatCamera3D({
    this.mode = CombatCameraMode.chase3D,
    this.pitchDeg = 26.0,
    this.yawDeg = 0.0,
    this.followX = 0.5,
  });

  /// Active camera preset mode.
  final CombatCameraMode mode;

  /// Camera elevation pitch angle in degrees (`15.0` to `80.0`).
  final double pitchDeg;

  /// Camera azimuthal yaw orbit angle in degrees (`-45.0` to `+45.0`).
  final double yawDeg;

  /// Normalized lateral X position (`0.0` to `1.0`) of the Dreadnought for chase parallax.
  final double followX;

  /// Pitch angle in radians.
  double get pitchRad => pitchDeg.clamp(14.0, 82.0) * (math.pi / 180.0);

  /// Yaw angle in radians.
  double get yawRad => yawDeg.clamp(-45.0, 45.0) * (math.pi / 180.0);

  /// Relative mesh pitch bias in radians so 3D ship meshes tilt with the camera pitch.
  double get meshPitchBiasRad {
    // At 80 deg (top-down), mesh pitch bias is ~0. At 26 deg (chase 3D), mesh tilts
    // ~0.58 rad (~33 deg) so the camera views the 3D aft/dorsal superstructure in perspective.
    final normTilt = ((80.0 - pitchDeg.clamp(14.0, 80.0)) / 66.0).clamp(
      0.0,
      1.0,
    );
    return normTilt * 0.62;
  }

  /// Relative mesh yaw bias in radians so 3D ship meshes rotate with the camera yaw.
  double get meshYawBiasRad => -yawRad * 0.85;

  /// Perspective foreshortening strength derived from camera pitch.
  ///
  /// Tuned for a wide-field panoramic 3D space theater so the 8 orbital lanes
  /// remain broad and readable all the way to the deep-space horizon.
  double get _perspStrength {
    final p = pitchRad;
    return 0.56 * math.cos(p * 0.78);
  }

  /// Computes the 2D vanishing point `(vpX, vpY)` on a viewport of [size].
  ///
  /// Locked horizontally to `size.width * 0.5` and positioned below the top
  /// comms HUD banner (`~19%` viewport height) so deep-space stellar targets
  /// never overlap the header HUD.
  Offset vanishingPoint(Size size) {
    final p = pitchRad;
    final vpX = size.width * 0.5;
    final vpY = size.height * (0.165 + (1.0 - math.sin(p)) * 0.045);
    return Offset(vpX, vpY);
  }

  /// Screen Y coordinate of the near threshold defense line (`normZ = 0.0`).
  double nearThresholdY(Size size) => size.height - 20.0;

  /// Screen Y coordinate of the far apogee trench horizon (`normZ = 1.0`).
  double farHorizonY(Size size) {
    final vp = vanishingPoint(size);
    final p = pitchRad;
    return (vp.dy + size.height * (0.055 + 0.035 * math.sin(p))).clamp(
      size.height * 0.22,
      size.height * 0.32,
    );
  }

  /// Projects a 3D world point `(normX, elevationY, normZ)` onto the 2D canvas of [size].
  ///
  /// - [normX]: `0.0` (port trench wall) to `1.0` (starboard trench wall).
  /// - [elevationY]: `0.0` (trench floor grid) to `1.0` (high orbital altitude).
  /// - [normZ]: `0.0` (near threshold defense line), `1.0` (tactical spawn gate),
  ///   up to `8.0+` (infinite deep-space star horizon).
  ProjectedPoint3D project(
    Size size, {
    required double normX,
    required double normZ,
    double elevationY = 0.0,
  }) {
    final clampedZ = normZ.clamp(-0.05, 8.0);
    final centeredX = normX - 0.5;
    final pRad = pitchRad;

    final persp = _perspStrength;
    final scaleAtZ =
        1.0 / math.max(0.18, 1.0 + math.max(0.0, clampedZ) * persp);
    final scaleAtFar = 1.0 / (1.0 + 1.0 * persp);

    final nearY = nearThresholdY(size);
    final farY = farHorizonY(size);
    final denom = math.max(0.05, 1.0 - scaleAtFar);

    final double groundY;
    if (clampedZ <= 1.0) {
      final tZ = ((1.0 - scaleAtZ) / denom).clamp(-0.05, 1.0);
      groundY = nearY - tZ * (nearY - farY);
    } else {
      final vpY = vanishingPoint(size).dy;
      final deepFrac = 1.0 - (1.0 / clampedZ);
      groundY = farY - deepFrac * (farY - vpY);
    }

    // Near threshold width spans 96% of viewport width (matching the 8 C1..C8 dock columns)
    final baseSpanW = size.width * 0.96;
    final centerLineX = size.width * 0.5;
    final groundX = centerLineX + (centeredX * baseSpanW) * scaleAtZ;

    // 3D vertical elevation lifts point upward perpendicular to the trench floor
    final verticalFactor = math.cos(pRad * 0.52);
    final liftPx = elevationY * size.height * 0.22 * scaleAtZ * verticalFactor;

    final screenX = groundX;
    final screenY = groundY - liftPx;

    return ProjectedPoint3D(
      screenOffset: Offset(screenX, screenY),
      groundOffset: Offset(groundX, groundY),
      perspectiveScale: scaleAtZ,
      normZ: clampedZ,
    );
  }

  /// Unprojects a 2D screen touch point [localPosition] back onto the 3D trench floor
  /// returning normalized `(normX, normZ)` in `[0.0, 1.0]`.
  Offset unprojectToTrenchFloor(Size size, Offset localPosition) {
    final nearY = nearThresholdY(size);
    final farY = farHorizonY(size);
    final spanY = math.max(1.0, nearY - farY);

    final tZ = ((nearY - localPosition.dy) / spanY).clamp(0.0, 1.0);
    final persp = _perspStrength;
    final scaleAtFar = 1.0 / (1.0 + persp);
    final scaleAtZ = (1.0 - tZ * (1.0 - scaleAtFar)).clamp(0.20, 1.0);
    final normZ = ((1.0 / scaleAtZ - 1.0) / math.max(0.1, persp)).clamp(
      0.0,
      1.0,
    );

    final centerLineX = size.width * 0.5;
    final baseSpanW = math.max(1.0, size.width * 0.96 * scaleAtZ);
    final centeredX = (localPosition.dx - centerLineX) / baseSpanW;
    final normX = (centeredX + 0.5).clamp(0.0, 1.0);

    return Offset(normX, normZ);
  }

  /// Creates a copy of this [CombatCamera3D] with updated fields.
  CombatCamera3D copyWith({
    CombatCameraMode? mode,
    double? pitchDeg,
    double? yawDeg,
    double? followX,
  }) {
    return CombatCamera3D(
      mode: mode ?? this.mode,
      pitchDeg: pitchDeg ?? this.pitchDeg,
      yawDeg: yawDeg ?? this.yawDeg,
      followX: followX ?? this.followX,
    );
  }

  /// Cycles to the next [CombatCameraMode] preset and applies its default pitch and yaw.
  CombatCamera3D nextMode() {
    final values = CombatCameraMode.values;
    final nextIndex = (mode.index + 1) % values.length;
    final next = values[nextIndex];
    return CombatCamera3D(
      mode: next,
      pitchDeg: next.defaultPitchDeg,
      yawDeg: next.defaultYawDeg,
      followX: followX,
    );
  }

  /// Adjusts camera pitch and yaw angles interactively and switches mode to [CombatCameraMode.orbit3D].
  CombatCamera3D withAdjustedAngles({double dPitch = 0.0, double dYaw = 0.0}) {
    return CombatCamera3D(
      mode: CombatCameraMode.orbit3D,
      pitchDeg: (pitchDeg + dPitch).clamp(15.0, 80.0),
      yawDeg: (yawDeg + dYaw).clamp(-42.0, 42.0),
      followX: followX,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CombatCamera3D &&
        other.mode == mode &&
        (other.pitchDeg - pitchDeg).abs() < 0.01 &&
        (other.yawDeg - yawDeg).abs() < 0.01 &&
        (other.followX - followX).abs() < 0.005;
  }

  @override
  int get hashCode => Object.hash(
    mode,
    (pitchDeg * 100).round(),
    (yawDeg * 100).round(),
    (followX * 200).round(),
  );
}
