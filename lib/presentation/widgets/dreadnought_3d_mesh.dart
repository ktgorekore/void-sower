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
import 'dart:typed_data';
import 'package:flutter/material.dart';

import '../theme/void_theme.dart';

/// High-performance, zero-allocation 3D polygonal mesh renderer for the
/// Dreadnought Flagship.
///
/// Implements full 3D spatial transformation (pitch, roll, yaw, perspective projection)
/// and directional cosmic starlight shading with zero per-frame heap allocations.
/// All local vertices, transformed coordinates, and projected screen points are
/// managed within pre-allocated [Float32List] memory pools.
class Dreadnought3DMesh {
  /// Initializes the 3D model vertices, facet indices, and scratch buffers.
  Dreadnought3DMesh() {
    _initMeshGeometry();
  }

  // ---------------------------------------------------------------------------
  // 3D Model Topology: 16 Local Vertices (X, Y, Z in Local Model Coordinates)
  //
  // Coordinates system:
  //   +X: Starboard (right)
  //   -X: Port (left)
  //   -Y: Prow (forward heading)
  //   +Y: Stern (aft / engines)
  //   +Z: Dorsal (upward towards camera / command bridge)
  //   -Z: Ventral (downward / keel)
  // ---------------------------------------------------------------------------
  static const int vertexCount = 16;

  // Local model coordinate buffers (immutable source geometry)
  final Float32List _localX = Float32List(vertexCount);
  final Float32List _localY = Float32List(vertexCount);
  final Float32List _localZ = Float32List(vertexCount);

  // Transformed 3D camera space coordinate buffers
  final Float32List _camX = Float32List(vertexCount);
  final Float32List _camY = Float32List(vertexCount);
  final Float32List _camZ = Float32List(vertexCount);

  // Projected 2D screen coordinate buffers
  final Float32List _projX = Float32List(vertexCount);
  final Float32List _projY = Float32List(vertexCount);

  // Facet normal scratch components
  static final Float32List _facetNormalX = Float32List(12);
  static final Float32List _facetNormalY = Float32List(12);
  static final Float32List _facetNormalZ = Float32List(12);
  static final Float32List _facetLight = Float32List(12);

  // Directional Cosmic Key-Light Vector (Normalized from upper-right space)
  static const double _lightDirX = 0.35355;
  static const double _lightDirY = -0.53033;
  static const double _lightDirZ = 0.77055;

  // Reusable scratch path to eliminate per-frame Path allocations
  static final Path _scratchFacetPath = Path();
  static final Path _scratchEnginePath = Path();

  // Static pre-cached paint instances
  static final Paint _facetPaint = Paint()..style = PaintingStyle.fill;
  static final Paint _facetOutlinePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.2
    ..color = VoidTheme.plasmaCyan.withValues(alpha: 0.85);

  static final Paint _ridgeGlowPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.0
    ..color = Colors.white.withValues(alpha: 0.90);

  static final Paint _engineBellPaint = Paint()
    ..style = PaintingStyle.fill
    ..color = const Color(0xFF1E293B);

  static final Paint _engineGazePaint = Paint()
    ..style = PaintingStyle.fill
    ..color = VoidTheme.plasmaCyan;

  static final Paint _reactorCenterPaint = Paint()
    ..style = PaintingStyle.fill
    ..color = Colors.white;

  static final Paint _reactorCorePaint = Paint()
    ..style = PaintingStyle.fill
    ..color = VoidTheme.plasmaCyan;

  static final Paint _reactorGlowPaint = Paint()
    ..style = PaintingStyle.fill
    ..color = VoidTheme.plasmaCyan.withValues(alpha: 0.35);

  static final Paint _navPortPaint = Paint()
    ..style = PaintingStyle.fill
    ..color = VoidTheme.crimsonFlare;

  static final Paint _navStarboardPaint = Paint()
    ..style = PaintingStyle.fill
    ..color = VoidTheme.emeraldShield;

  // ---------------------------------------------------------------------------
  // Vertex Indices Definitions
  // ---------------------------------------------------------------------------
  static const int vProwTip = 0;
  static const int vProwSpine = 1;
  static const int vBridgeApex = 2;
  static const int vReactorCore = 3;
  static const int vSternKeel = 4;
  static const int vPortShoulder = 5;
  static const int vPortWingMid = 6;
  static const int vPortWingtip = 7;
  static const int vPortEngineMount = 8;
  static const int vPortEngineBell = 9;
  static const int vStbdShoulder = 10;
  static const int vStbdWingMid = 11;
  static const int vStbdWingtip = 12;
  static const int vStbdEngineMount = 13;
  static const int vStbdEngineBell = 14;
  static const int vVentralKeel = 15;

  void _initMeshGeometry() {
    // 0: Prow Tip (Forward elevated prow)
    _localX[vProwTip] = 0.0;
    _localY[vProwTip] = -38.0;
    _localZ[vProwTip] = 8.0;

    // 1: Prow Spine (Armored dorsal ridge)
    _localX[vProwSpine] = 0.0;
    _localY[vProwSpine] = -18.0;
    _localZ[vProwSpine] = 14.0;

    // 2: Bridge Apex (Command superstructure)
    _localX[vBridgeApex] = 0.0;
    _localY[vBridgeApex] = 2.0;
    _localZ[vBridgeApex] = 18.0;

    // 3: Reactor Core (Aft of bridge)
    _localX[vReactorCore] = 0.0;
    _localY[vReactorCore] = 10.0;
    _localZ[vReactorCore] = 12.0;

    // 4: Stern Keel (Rear lower hull)
    _localX[vSternKeel] = 0.0;
    _localY[vSternKeel] = 22.0;
    _localZ[vSternKeel] = -2.0;

    // 5: Port Shoulder (Upper inner wing)
    _localX[vPortShoulder] = -22.0;
    _localY[vPortShoulder] = -2.0;
    _localZ[vPortShoulder] = 8.0;

    // 6: Port Wing Mid (Intermediate swept wing)
    _localX[vPortWingMid] = -42.0;
    _localY[vPortWingMid] = 8.0;
    _localZ[vPortWingMid] = 2.0;

    // 7: Port Wingtip (Outer canted wingtip)
    _localX[vPortWingtip] = -54.0;
    _localY[vPortWingtip] = 16.0;
    _localZ[vPortWingtip] = -6.0;

    // 8: Port Engine Mount
    _localX[vPortEngineMount] = -22.0;
    _localY[vPortEngineMount] = 18.0;
    _localZ[vPortEngineMount] = 4.0;

    // 9: Port Engine Bell (Exhaust nozzle)
    _localX[vPortEngineBell] = -22.0;
    _localY[vPortEngineBell] = 24.0;
    _localZ[vPortEngineBell] = 0.0;

    // 10: Starboard Shoulder (Upper inner wing)
    _localX[vStbdShoulder] = 22.0;
    _localY[vStbdShoulder] = -2.0;
    _localZ[vStbdShoulder] = 8.0;

    // 11: Starboard Wing Mid (Intermediate swept wing)
    _localX[vStbdWingMid] = 42.0;
    _localY[vStbdWingMid] = 8.0;
    _localZ[vStbdWingMid] = 2.0;

    // 12: Starboard Wingtip (Outer canted wingtip)
    _localX[vStbdWingtip] = 54.0;
    _localY[vStbdWingtip] = 16.0;
    _localZ[vStbdWingtip] = -6.0;

    // 13: Starboard Engine Mount
    _localX[vStbdEngineMount] = 22.0;
    _localY[vStbdEngineMount] = 18.0;
    _localZ[vStbdEngineMount] = 4.0;

    // 14: Starboard Engine Bell (Exhaust nozzle)
    _localX[vStbdEngineBell] = 22.0;
    _localY[vStbdEngineBell] = 24.0;
    _localZ[vStbdEngineBell] = 0.0;

    // 15: Ventral Keel Floor (Bottom hull spine)
    _localX[vVentralKeel] = 0.0;
    _localY[vVentralKeel] = 4.0;
    _localZ[vVentralKeel] = -12.0;
  }

  /// Transforms and projects the 3D flagship mesh, rendering all shaded facets
  /// onto [canvas].
  ///
  /// [center]: Viewport pivot coordinate for the dreadnought flagship.
  /// [pitchRad]: 3D pitch angle in radians (negative = nose pitches down into space).
  /// [rollRad]: 3D roll/bank angle in radians (positive = banks starboard).
  /// [yawRad]: 3D yaw angle in radians.
  /// [scale]: Base physical scale multiplier.
  /// [animationTime]: Global continuous animation clock in seconds.
  /// [isLowBattery]: When true, skips multi-pass glow passes to minimize GPU thermal footprint.
  void projectAndPaint(
    Canvas canvas, {
    required Offset center,
    required double pitchRad,
    required double rollRad,
    required double yawRad,
    required double scale,
    required double animationTime,
    bool isLowBattery = false,
  }) {
    // -------------------------------------------------------------------------
    // 1. 3D Rotation Matrix Calculation (Pitch * Yaw * Roll)
    // -------------------------------------------------------------------------
    final cp = math.cos(pitchRad);
    final sp = math.sin(pitchRad);
    final cr = math.cos(rollRad);
    final sr = math.sin(rollRad);
    final cy = math.cos(yawRad);
    final sy = math.sin(yawRad);

    // Combined rotation matrix R = R_pitch * R_yaw * R_roll
    final r11 = cy * cr + sy * sp * sr;
    final r12 = -cy * sr + sy * sp * cr;
    final r13 = sy * cp;

    final r21 = cp * sr;
    final r22 = cp * cr;
    final r23 = -sp;

    final r31 = -sy * cr + cy * sp * sr;
    final r32 = sy * sr + cy * sp * cr;
    final r33 = cy * cp;

    // Camera focal parameters
    const double cameraZ = 300.0;
    const double focalLength = 300.0;

    // -------------------------------------------------------------------------
    // 2. Vertex Transformation & Perspective Projection
    // -------------------------------------------------------------------------
    for (var i = 0; i < vertexCount; i++) {
      final lx = _localX[i] * scale;
      final ly = _localY[i] * scale;
      final lz = _localZ[i] * scale;

      // Rotate into camera space
      final rx = r11 * lx + r12 * ly + r13 * lz;
      final ry = r21 * lx + r22 * ly + r23 * lz;
      final rz = r31 * lx + r32 * ly + r33 * lz;

      _camX[i] = rx;
      _camY[i] = ry;
      _camZ[i] = rz;

      // Perspective divide
      final zDepth = math.max(1.0, cameraZ + rz);
      final invZ = focalLength / zDepth;

      _projX[i] = center.dx + rx * invZ;
      _projY[i] = center.dy + ry * invZ;
    }

    // -------------------------------------------------------------------------
    // 3. Facet Shading & Rendering
    // -------------------------------------------------------------------------

    // Facet 1: Dorsal Prow Left
    _paintFacet(
      canvas,
      0,
      vProwTip,
      vProwSpine,
      vPortShoulder,
      baseColor: const Color(0xFF0F172A),
      isLowBattery: isLowBattery,
    );

    // Facet 2: Dorsal Prow Right
    _paintFacet(
      canvas,
      1,
      vProwTip,
      vStbdShoulder,
      vProwSpine,
      baseColor: const Color(0xFF0F172A),
      isLowBattery: isLowBattery,
    );

    // Facet 3: Bridge Deck Left
    _paintFacet(
      canvas,
      2,
      vProwSpine,
      vBridgeApex,
      vPortShoulder,
      baseColor: const Color(0xFF1E293B),
      isLowBattery: isLowBattery,
    );

    // Facet 4: Bridge Deck Right
    _paintFacet(
      canvas,
      3,
      vProwSpine,
      vStbdShoulder,
      vBridgeApex,
      baseColor: const Color(0xFF1E293B),
      isLowBattery: isLowBattery,
    );

    // Facet 5: Port Canted Main Wing
    _paintQuad(
      canvas,
      4,
      vPortShoulder,
      vPortWingMid,
      vPortWingtip,
      vPortEngineMount,
      baseColor: const Color(0xFF0A101F),
      isLowBattery: isLowBattery,
    );

    // Facet 6: Starboard Canted Main Wing
    _paintQuad(
      canvas,
      5,
      vStbdShoulder,
      vStbdEngineMount,
      vStbdWingtip,
      vStbdWingMid,
      baseColor: const Color(0xFF0A101F),
      isLowBattery: isLowBattery,
    );

    // Facet 7: Aft Deck & Keel Plate
    _paintQuad(
      canvas,
      6,
      vBridgeApex,
      vPortEngineMount,
      vSternKeel,
      vStbdEngineMount,
      baseColor: const Color(0xFF162033),
      isLowBattery: isLowBattery,
    );

    // -------------------------------------------------------------------------
    // 4. Center Dorsal Spine Highlight
    // -------------------------------------------------------------------------
    canvas.drawLine(
      Offset(_projX[vProwTip], _projY[vProwTip]),
      Offset(_projX[vBridgeApex], _projY[vBridgeApex]),
      _ridgeGlowPaint,
    );

    // Forward Particle Lance Turret tips in 3D
    final lanceTipLeft = Offset(
      _projX[vProwSpine] - 6.5 * scale,
      _projY[vProwSpine] - 12.0 * scale,
    );
    final lanceTipRight = Offset(
      _projX[vProwSpine] + 6.5 * scale,
      _projY[vProwSpine] - 12.0 * scale,
    );
    canvas.drawLine(
      Offset(_projX[vProwSpine] - 6.5 * scale, _projY[vProwSpine]),
      lanceTipLeft,
      _ridgeGlowPaint,
    );
    canvas.drawLine(
      Offset(_projX[vProwSpine] + 6.5 * scale, _projY[vProwSpine]),
      lanceTipRight,
      _ridgeGlowPaint,
    );
    canvas.drawCircle(lanceTipLeft, 2.0, _reactorCenterPaint);
    canvas.drawCircle(lanceTipRight, 2.0, _reactorCenterPaint);

    // -------------------------------------------------------------------------
    // 5. 3D Twin Engine Exhaust Nozzles
    // -------------------------------------------------------------------------
    _paintEngineNozzle(
      canvas,
      vPortEngineBell,
      scale,
      isLowBattery: isLowBattery,
    );
    _paintEngineNozzle(
      canvas,
      vStbdEngineBell,
      scale,
      isLowBattery: isLowBattery,
    );

    // -------------------------------------------------------------------------
    // 6. Navigation Strobe Beacons (Port Crimson, Starboard Emerald)
    // -------------------------------------------------------------------------
    final portStrobe = 0.5 + 0.5 * math.sin(animationTime * 15.0);
    final stbdStrobe = 0.5 + 0.5 * math.cos(animationTime * 15.0);
    _navPortPaint.color = VoidTheme.crimsonFlare.withValues(alpha: portStrobe);
    _navStarboardPaint.color = VoidTheme.emeraldShield.withValues(
      alpha: stbdStrobe,
    );

    canvas.drawCircle(
      Offset(_projX[vPortWingtip], _projY[vPortWingtip]),
      3.2 * scale,
      _navPortPaint,
    );
    canvas.drawCircle(
      Offset(_projX[vStbdWingtip], _projY[vStbdWingtip]),
      3.2 * scale,
      _navStarboardPaint,
    );

    // -------------------------------------------------------------------------
    // 7. Pulsating Central Plasma Reactor Core
    // -------------------------------------------------------------------------
    final coreX = _projX[vReactorCore];
    final coreY = _projY[vReactorCore];
    final corePulse = 1.0 + 0.25 * math.sin(animationTime * 12.0);

    if (!isLowBattery) {
      canvas.drawCircle(
        Offset(coreX, coreY),
        10.0 * scale * corePulse,
        _reactorGlowPaint,
      );
    }
    canvas.drawCircle(
      Offset(coreX, coreY),
      5.0 * scale * corePulse,
      _reactorCorePaint,
    );
    canvas.drawCircle(
      Offset(coreX, coreY),
      2.2 * scale * corePulse,
      _reactorCenterPaint,
    );
  }

  /// Renders a 3D triangular hull facet ([i0], [i1], [i2]) with directional lighting.
  ///
  /// Computes face normal in camera space via vector cross product, calculates
  /// Lambertian directional illumination against the cosmic key-light vector,
  /// modulates [baseColor], and rasters the facet path onto [canvas].
  /// In [isLowBattery] mode, facet outline strokes are omitted to halve draw calls.
  void _paintFacet(
    Canvas canvas,
    int facetIdx,
    int i0,
    int i1,
    int i2, {
    required Color baseColor,
    bool isLowBattery = false,
  }) {
    // Compute facet normal in camera space
    final ax = _camX[i1] - _camX[i0];
    final ay = _camY[i1] - _camY[i0];
    final az = _camZ[i1] - _camZ[i0];

    final bx = _camX[i2] - _camX[i0];
    final by = _camY[i2] - _camY[i0];
    final bz = _camZ[i2] - _camZ[i0];

    var nx = ay * bz - az * by;
    var ny = az * bx - ax * bz;
    var nz = ax * by - ay * bx;

    final len = math.sqrt(nx * nx + ny * ny + nz * nz);
    if (len > 0.0001) {
      nx /= len;
      ny /= len;
      nz /= len;
    }

    _facetNormalX[facetIdx] = nx;
    _facetNormalY[facetIdx] = ny;
    _facetNormalZ[facetIdx] = nz;

    // Dot product with directional cosmic key-light
    final dot = nx * _lightDirX + ny * _lightDirY + nz * _lightDirZ;
    final light = (0.35 + 0.65 * math.max(0.0, dot)).clamp(0.25, 1.0);
    _facetLight[facetIdx] = light;

    // Shade base color
    final shadedColor = Color.fromARGB(
      (baseColor.a * 255.0).round().clamp(0, 255),
      (baseColor.r * 255.0 * light).round().clamp(0, 255),
      (baseColor.g * 255.0 * light).round().clamp(0, 255),
      (baseColor.b * 255.0 * light).round().clamp(0, 255),
    );

    _facetPaint.color = shadedColor;

    _scratchFacetPath.reset();
    _scratchFacetPath.moveTo(_projX[i0], _projY[i0]);
    _scratchFacetPath.lineTo(_projX[i1], _projY[i1]);
    _scratchFacetPath.lineTo(_projX[i2], _projY[i2]);
    _scratchFacetPath.close();

    canvas.drawPath(_scratchFacetPath, _facetPaint);
    if (!isLowBattery) {
      canvas.drawPath(_scratchFacetPath, _facetOutlinePaint);
    }
  }

  /// Renders a 3D quadrilateral hull facet ([i0], [i1], [i2], [i3]) with directional lighting.
  ///
  /// Computes face normal from the first three coplanar vertices in camera space,
  /// calculates directional illumination against the cosmic key-light vector,
  /// modulates [baseColor], and rasters the quad path onto [canvas].
  /// In [isLowBattery] mode, facet outline strokes are omitted to halve draw calls.
  void _paintQuad(
    Canvas canvas,
    int facetIdx,
    int i0,
    int i1,
    int i2,
    int i3, {
    required Color baseColor,
    bool isLowBattery = false,
  }) {
    // Normal from first three vertices
    final ax = _camX[i1] - _camX[i0];
    final ay = _camY[i1] - _camY[i0];
    final az = _camZ[i1] - _camZ[i0];

    final bx = _camX[i2] - _camX[i0];
    final by = _camY[i2] - _camY[i0];
    final bz = _camZ[i2] - _camZ[i0];

    var nx = ay * bz - az * by;
    var ny = az * bx - ax * bz;
    var nz = ax * by - ay * bx;

    final len = math.sqrt(nx * nx + ny * ny + nz * nz);
    if (len > 0.0001) {
      nx /= len;
      ny /= len;
      nz /= len;
    }

    final dot = nx * _lightDirX + ny * _lightDirY + nz * _lightDirZ;
    final light = (0.30 + 0.70 * math.max(0.0, dot)).clamp(0.20, 1.0);

    final shadedColor = Color.fromARGB(
      (baseColor.a * 255.0).round().clamp(0, 255),
      (baseColor.r * 255.0 * light).round().clamp(0, 255),
      (baseColor.g * 255.0 * light).round().clamp(0, 255),
      (baseColor.b * 255.0 * light).round().clamp(0, 255),
    );

    _facetPaint.color = shadedColor;

    _scratchFacetPath.reset();
    _scratchFacetPath.moveTo(_projX[i0], _projY[i0]);
    _scratchFacetPath.lineTo(_projX[i1], _projY[i1]);
    _scratchFacetPath.lineTo(_projX[i2], _projY[i2]);
    _scratchFacetPath.lineTo(_projX[i3], _projY[i3]);
    _scratchFacetPath.close();

    canvas.drawPath(_scratchFacetPath, _facetPaint);
    if (!isLowBattery) {
      canvas.drawPath(_scratchFacetPath, _facetOutlinePaint);
    }
  }

  /// Renders a 3D cylindrical engine exhaust nozzle at the projected vertex [bellIdx].
  ///
  /// Rasters an elliptical bell housing using [scale]-adjusted dimensions via [Rect.fromLTWH],
  /// applies an outline stroke (omitted when [isLowBattery] is true), and
  /// renders the glowing inner emitter aperture circle.
  void _paintEngineNozzle(
    Canvas canvas,
    int bellIdx,
    double scale, {
    bool isLowBattery = false,
  }) {
    final bx = _projX[bellIdx];
    final by = _projY[bellIdx];
    final nozzleRadiusX = 5.5 * scale;
    final nozzleRadiusY = 3.5 * scale;

    _scratchEnginePath.reset();
    _scratchEnginePath.addOval(
      Rect.fromLTWH(
        bx - nozzleRadiusX,
        by - nozzleRadiusY,
        nozzleRadiusX * 2.0,
        nozzleRadiusY * 2.0,
      ),
    );

    canvas.drawPath(_scratchEnginePath, _engineBellPaint);
    if (!isLowBattery) {
      canvas.drawPath(_scratchEnginePath, _facetOutlinePaint);
    }

    // Inner glowing emitter aperture
    canvas.drawCircle(Offset(bx, by), 2.2 * scale, _engineGazePaint);
  }

  // ---------------------------------------------------------------------------
  // Projected Screen & Camera Space Coordinate Accessors
  // ---------------------------------------------------------------------------
  /// Projected 2D screen X coordinates for all 16 vertices.
  Float32List get projX => _projX;

  /// Projected 2D screen Y coordinates for all 16 vertices.
  Float32List get projY => _projY;

  /// Camera space Z coordinate view for testing.
  @visibleForTesting
  Float32List get camZ => _camZ;
}
