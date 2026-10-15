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
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' as vm;

import '../theme/void_theme.dart';

/// High-performance, zero-allocation Solid 3D Gouraud-shaded & bevel-armored
/// spacecraft renderer for the Dreadnought Defender Flagship.
///
/// Uses `vector_math` 3D transformation matrices, Z-sorted closed-manifold
/// hull triangles, hardware-accelerated [ui.Vertices.raw] Gouraud shading,
/// extruded 3D thruster nacelles, and a glossy 3D command canopy with zero
/// per-frame heap allocations.
class Dreadnought3DMesh {
  /// Initializes the 3D model vertices, closed-manifold triangle topology,
  /// vertex normals, and pre-allocated scratch buffers.
  Dreadnought3DMesh() {
    _initMeshGeometry();
  }

  // ---------------------------------------------------------------------------
  // 3D Model Topology: 16 Local Vertices (X, Y, Z in Local Model Coordinates)
  //
  // Coordinate system:
  //   +X: Starboard (right)
  //   -X: Port (left)
  //   -Y: Prow (forward heading into deep space)
  //   +Y: Stern (aft / engines)
  //   +Z: Dorsal (upward towards camera / command bridge)
  //   -Z: Ventral (downward / keel)
  // ---------------------------------------------------------------------------
  static const int vertexCount = 16;

  // Local model coordinate buffers (immutable source geometry)
  final Float32List _localX = Float32List(vertexCount);
  final Float32List _localY = Float32List(vertexCount);
  final Float32List _localZ = Float32List(vertexCount);

  // Local smooth vertex normals for Gouraud Blinn-Phong lighting
  final Float32List _normX = Float32List(vertexCount);
  final Float32List _normY = Float32List(vertexCount);
  final Float32List _normZ = Float32List(vertexCount);

  // Transformed 3D camera space coordinate buffers
  final Float32List _camX = Float32List(vertexCount);
  final Float32List _camY = Float32List(vertexCount);
  final Float32List _camZ = Float32List(vertexCount);

  // Projected 2D screen coordinate buffers
  final Float32List _projX = Float32List(vertexCount);
  final Float32List _projY = Float32List(vertexCount);

  // Pre-allocated buffers for hardware-accelerated ui.Vertices.raw
  static const int _triangleCount = 20;
  final Float32List _interleavedPositions = Float32List(vertexCount * 2);
  final Int32List _gouraudVertexColors = Int32List(vertexCount);
  final Uint16List _sortedIndices = Uint16List(_triangleCount * 3);
  final Float32List _triDepth = Float32List(_triangleCount);
  final Int32List _triOrder = Int32List(_triangleCount);

  // Pre-allocated vector_math rotation matrix
  final vm.Matrix3 _rotMatrix = vm.Matrix3.identity();

  // Closed-manifold 20-triangle hull topology (3 indices per triangle)
  static final Uint16List _hullTriangles = Uint16List.fromList([
    // Ventral Keel & Underbody Chines (0..5)
    vProwTip, vVentralKeel, vPortShoulder,
    vProwTip, vStbdShoulder, vVentralKeel,
    vVentralKeel, vSternKeel, vPortEngineMount,
    vVentralKeel, vStbdEngineMount, vSternKeel,
    vPortShoulder, vVentralKeel, vPortEngineMount,
    vStbdShoulder, vStbdEngineMount, vVentralKeel,
    // Port & Starboard Lower Wing Under-Plates (6..9)
    vPortShoulder, vPortWingMid, vPortEngineMount,
    vPortWingMid, vPortWingtip, vPortEngineBell,
    vStbdShoulder, vStbdEngineMount, vStbdWingMid,
    vStbdWingMid, vStbdEngineBell, vStbdWingtip,
    // Aft Engine Deck & Nacelle Fairings (10..13)
    vPortEngineMount, vPortEngineBell, vSternKeel,
    vStbdEngineMount, vSternKeel, vStbdEngineBell,
    vBridgeApex, vPortEngineMount, vReactorCore,
    vBridgeApex, vReactorCore, vStbdEngineMount,
    // Main Swept Delta Wings (14..15)
    vPortShoulder, vPortWingMid, vPortWingtip,
    vStbdShoulder, vStbdWingtip, vStbdWingMid,
    // Forward Dorsal Prow Armor (16..17)
    vProwTip, vProwSpine, vPortShoulder,
    vProwTip, vStbdShoulder, vProwSpine,
    // Command Citadel Upper Hull (18..19)
    vProwSpine, vBridgeApex, vPortShoulder,
    vProwSpine, vStbdShoulder, vBridgeApex,
  ]);

  // Base armor color index per triangle (0..3)
  static final Uint8List _hullTriColorIdx = Uint8List.fromList([
    2, 2, 2, 2, 2, 2, // Ventral keel
    2, 0, 2, 0, // Lower wing plates
    1, 1, 3, 3, // Aft deck & reactor housing
    0, 0, // Swept outer wings
    1, 1, // Forward dorsal prow
    3, 3, // Command citadel
  ]);

  // Directional Cosmic Key-Light Vector (Normalized from upper-forward starlight)
  static const double _lightDirX = 0.32;
  static const double _lightDirY = -0.58;
  static const double _lightDirZ = 0.75;

  // Pre-calculated base colors palette (Rich 3D Metallic Navy, Cobalt & Titanium)
  static const List<Color> _baseColors = [
    Color(0xFF1B3B6F), // 0: Port/Stbd Forward Flank
    Color(0xFF28559A), // 1: Midship Broadside
    Color(0xFF102547), // 2: Ventral Keel & Wing Roots
    Color(0xFF336BC2), // 3: Dorsal Deck & Citadel
  ];

  // Lookup table: [baseColorIndex][lightStep 0..100]
  static final List<List<Color>> _shadedColorLUT = List.generate(
    _baseColors.length,
    (cIdx) {
      final base = _baseColors[cIdx];
      return List.generate(101, (step) {
        final light = step / 100.0;
        final spec = math.pow(math.max(0.0, light - 0.55) / 0.45, 2.0) * 58.0;
        return Color.fromARGB(
          (base.a * 255.0).round().clamp(0, 255),
          (base.r * 255.0 * light + spec).round().clamp(0, 255),
          (base.g * 255.0 * light + spec * 1.1).round().clamp(0, 255),
          (base.b * 255.0 * light + spec * 1.25).round().clamp(0, 255),
        );
      });
    },
  );

  // Reusable scratch paths to eliminate per-frame allocations
  static final Path _scratchFacetPath = Path();
  static final Path _scratchNozzlePath = Path();
  static final Path _scratchCanopyPath = Path();

  /// Shaded color lookup table view for unit testing.
  @visibleForTesting
  static List<List<Color>> get shadedColorLUT => _shadedColorLUT;

  /// Scratch nozzle path for testing.
  @visibleForTesting
  static Path get scratchNozzlePath => _scratchNozzlePath;

  // Static pre-cached paint instances
  static final Paint _verticesPaint = Paint()..style = PaintingStyle.fill;
  static final Paint _facetPaint = Paint()
    ..style = PaintingStyle.fill
    ..isAntiAlias = true;
  static final Paint _panelSeamPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.85
    ..color = const Color(0xFF09152B).withValues(alpha: 0.55);
  static final Paint _hullRimPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.4
    ..strokeCap = StrokeCap.round
    ..color = const Color(0xFF93C5FD).withValues(alpha: 0.72);
  static final Paint _canopyFillPaint = Paint()
    ..style = PaintingStyle.fill
    ..color = const Color(0xFF0EA5E9).withValues(alpha: 0.88);
  static final Paint _canopyGlintPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.6
    ..strokeCap = StrokeCap.round
    ..color = Colors.white.withValues(alpha: 0.85);
  static final Paint _cannonBarrelPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3.2
    ..strokeCap = StrokeCap.round
    ..color = const Color(0xFF475569);
  static final Paint _cannonCorePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.4
    ..strokeCap = StrokeCap.round
    ..color = VoidTheme.plasmaCyan;
  static final Paint _engineBellPaint = Paint()
    ..style = PaintingStyle.fill
    ..color = const Color(0xFF1E293B);
  static final Paint _engineRimPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.3
    ..color = const Color(0xFF64748B);
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
    ..color = VoidTheme.plasmaCyan.withValues(alpha: 0.32);
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
    // 0: Prow Tip (Forward sculpted armored nose)
    _localX[vProwTip] = 0.0;
    _localY[vProwTip] = -38.0;
    _localZ[vProwTip] = 8.0;

    // 1: Prow Spine (Armored dorsal forward ridge)
    _localX[vProwSpine] = 0.0;
    _localY[vProwSpine] = -18.0;
    _localZ[vProwSpine] = 14.0;

    // 2: Bridge Apex (Elevated 3D Command Citadel)
    _localX[vBridgeApex] = 0.0;
    _localY[vBridgeApex] = 2.0;
    _localZ[vBridgeApex] = 18.0;

    // 3: Reactor Core (Aft dorsal power dome)
    _localX[vReactorCore] = 0.0;
    _localY[vReactorCore] = 10.0;
    _localZ[vReactorCore] = 12.0;

    // 4: Stern Keel (Rear armored tailcone)
    _localX[vSternKeel] = 0.0;
    _localY[vSternKeel] = 22.0;
    _localZ[vSternKeel] = -2.0;

    // 5: Port Shoulder (Upper inner hull chine)
    _localX[vPortShoulder] = -22.0;
    _localY[vPortShoulder] = -2.0;
    _localZ[vPortShoulder] = 8.0;

    // 6: Port Wing Mid (Intermediate swept wing plate)
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

    // 10: Starboard Shoulder (Upper inner hull chine)
    _localX[vStbdShoulder] = 22.0;
    _localY[vStbdShoulder] = -2.0;
    _localZ[vStbdShoulder] = 8.0;

    // 11: Starboard Wing Mid (Intermediate swept wing plate)
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

    // 15: Ventral Keel Floor (Deep bottom hull spine)
    _localX[vVentralKeel] = 0.0;
    _localY[vVentralKeel] = 4.0;
    _localZ[vVentralKeel] = -12.0;

    // Precompute outward-pointing unit vertex normals
    for (var i = 0; i < vertexCount; i++) {
      final vx = _localX[i];
      final vy = _localY[i];
      final vz = _localZ[i] * 2.2;
      final len = math.sqrt(vx * vx + vy * vy + vz * vz);
      if (len > 0.001) {
        _normX[i] = vx / len;
        _normY[i] = vy / len;
        _normZ[i] = vz / len;
      } else {
        _normX[i] = 0.0;
        _normY[i] = 0.0;
        _normZ[i] = 1.0;
      }
    }
  }

  /// Transforms and projects the solid 3D flagship model onto [canvas].
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
    // 1. 3D Rotation Matrix Calculation via vector_math (Pitch * Yaw * Roll)
    // -------------------------------------------------------------------------
    final cp = math.cos(pitchRad);
    final sp = math.sin(pitchRad);
    final cr = math.cos(rollRad);
    final sr = math.sin(rollRad);
    final cy = math.cos(yawRad);
    final sy = math.sin(yawRad);

    final r11 = cy * cr + sy * sp * sr;
    final r12 = -cy * sr + sy * sp * cr;
    final r13 = sy * cp;

    final r21 = cp * sr;
    final r22 = cp * cr;
    final r23 = -sp;

    final r31 = -sy * cr + cy * sp * sr;
    final r32 = sy * sr + cy * sp * cr;
    final r33 = cy * cp;

    _rotMatrix.setValues(r11, r21, r31, r12, r22, r32, r13, r23, r33);

    const double cameraZ = 300.0;
    const double focalLength = 300.0;

    // -------------------------------------------------------------------------
    // 2. Vertex Transformation, Normal Lighting & Perspective Projection
    // -------------------------------------------------------------------------
    for (var i = 0; i < vertexCount; i++) {
      final lx = _localX[i] * scale;
      final ly = _localY[i] * scale;
      final lz = _localZ[i] * scale;

      final rx = r11 * lx + r12 * ly + r13 * lz;
      final ry = r21 * lx + r22 * ly + r23 * lz;
      final rz = r31 * lx + r32 * ly + r33 * lz;

      _camX[i] = rx;
      _camY[i] = ry;
      _camZ[i] = rz;

      final zDepth = math.max(1.0, cameraZ + rz);
      final invZ = focalLength / zDepth;

      final px = center.dx + rx * invZ;
      final py = center.dy + ry * invZ;
      _projX[i] = px;
      _projY[i] = py;
      _interleavedPositions[i * 2] = px;
      _interleavedPositions[i * 2 + 1] = py;

      // Rotate vertex normal for smooth Gouraud Blinn-Phong shading
      final nx = r11 * _normX[i] + r12 * _normY[i] + r13 * _normZ[i];
      final ny = r21 * _normX[i] + r22 * _normY[i] + r23 * _normZ[i];
      final nz = r31 * _normX[i] + r32 * _normY[i] + r33 * _normZ[i];

      final dot = nx * _lightDirX + ny * _lightDirY + nz * _lightDirZ;
      final light = (0.34 + 0.66 * math.max(0.0, dot)).clamp(0.22, 1.0);
      final step = (light * 100.0).round().clamp(0, 100);
      final colorIdx = (i <= vReactorCore)
          ? 3
          : ((i == vVentralKeel || i == vSternKeel) ? 2 : 1);
      _gouraudVertexColors[i] = _shadedColorLUT[colorIdx][step].toARGB32();
    }

    // -------------------------------------------------------------------------
    // 3. Z-Sort Closed-Manifold 3D Hull Triangles (Painter's Order + Gouraud)
    // -------------------------------------------------------------------------
    for (var t = 0; t < _triangleCount; t++) {
      final base = t * 3;
      final i0 = _hullTriangles[base];
      final i1 = _hullTriangles[base + 1];
      final i2 = _hullTriangles[base + 2];
      _triDepth[t] = (_camZ[i0] + _camZ[i1] + _camZ[i2]) * 0.333333;
      _triOrder[t] = t;
    }

    // Insertion sort on 20 triangles (fastest for small N, zero allocations)
    for (var i = 1; i < _triangleCount; i++) {
      final keyTri = _triOrder[i];
      final keyDepth = _triDepth[keyTri];
      var j = i - 1;
      while (j >= 0 && _triDepth[_triOrder[j]] > keyDepth) {
        _triOrder[j + 1] = _triOrder[j];
        j--;
      }
      _triOrder[j + 1] = keyTri;
    }

    for (var s = 0; s < _triangleCount; s++) {
      final t = _triOrder[s];
      final src = t * 3;
      final dst = s * 3;
      _sortedIndices[dst] = _hullTriangles[src];
      _sortedIndices[dst + 1] = _hullTriangles[src + 1];
      _sortedIndices[dst + 2] = _hullTriangles[src + 2];
    }

    // Hardware-accelerated Gouraud-shaded 3D hull pass
    final hullVertices = ui.Vertices.raw(
      ui.VertexMode.triangles,
      _interleavedPositions,
      colors: _gouraudVertexColors,
      indices: _sortedIndices,
    );
    canvas.drawVertices(hullVertices, BlendMode.dst, _verticesPaint);

    // -------------------------------------------------------------------------
    // 4. Sculpted 3D Bevelled Armor Plates (Flat-normal specular + dark seams)
    // -------------------------------------------------------------------------
    for (var s = 0; s < _triangleCount; s++) {
      final t = _triOrder[s];
      final src = t * 3;
      _paintSolidArmorTriangle(
        canvas,
        _hullTriangles[src],
        _hullTriangles[src + 1],
        _hullTriangles[src + 2],
        colorIdx: _hullTriColorIdx[t],
        isLowBattery: isLowBattery,
      );
    }

    // -------------------------------------------------------------------------
    // 5. Heavy 3D Twin Forward Particle Cannon Pods (Nose Barrels)
    // -------------------------------------------------------------------------
    final prowX = _projX[vProwTip];
    final prowY = _projY[vProwTip];
    final spineX = _projX[vProwSpine];
    final spineY = _projY[vProwSpine];
    final barrelSpread = 5.2 * scale;
    final barrelLen = 10.5 * scale;

    _cannonBarrelPaint.strokeWidth = (3.0 * scale).clamp(1.5, 5.5);
    _cannonCorePaint.strokeWidth = (1.3 * scale).clamp(0.8, 2.5);

    final portMount = Offset(
      (prowX * 0.65 + spineX * 0.35) - barrelSpread,
      prowY * 0.65 + spineY * 0.35,
    );
    final stbdMount = Offset(
      (prowX * 0.65 + spineX * 0.35) + barrelSpread,
      prowY * 0.65 + spineY * 0.35,
    );
    final portMuzzle = Offset(portMount.dx, portMount.dy - barrelLen);
    final stbdMuzzle = Offset(stbdMount.dx, stbdMount.dy - barrelLen);

    canvas.drawLine(portMount, portMuzzle, _cannonBarrelPaint);
    canvas.drawLine(stbdMount, stbdMuzzle, _cannonBarrelPaint);
    canvas.drawLine(portMount, portMuzzle, _cannonCorePaint);
    canvas.drawLine(stbdMount, stbdMuzzle, _cannonCorePaint);
    canvas.drawCircle(portMuzzle, 1.8 * scale, _reactorCenterPaint);
    canvas.drawCircle(stbdMuzzle, 1.8 * scale, _reactorCenterPaint);

    // -------------------------------------------------------------------------
    // 6. Glossy 3D Smoked-Sapphire Command Canopy & Dorsal Spine Bevel
    // -------------------------------------------------------------------------
    _scratchCanopyPath
      ..reset()
      ..moveTo(_projX[vProwSpine], _projY[vProwSpine])
      ..lineTo(
        (_projX[vBridgeApex] * 0.72 + _projX[vPortShoulder] * 0.28),
        (_projY[vBridgeApex] * 0.72 + _projY[vPortShoulder] * 0.28),
      )
      ..lineTo(_projX[vReactorCore], _projY[vReactorCore])
      ..lineTo(
        (_projX[vBridgeApex] * 0.72 + _projX[vStbdShoulder] * 0.28),
        (_projY[vBridgeApex] * 0.72 + _projY[vStbdShoulder] * 0.28),
      )
      ..close();
    canvas.drawPath(_scratchCanopyPath, _canopyFillPaint);
    canvas.drawLine(
      Offset(_projX[vProwSpine], _projY[vProwSpine]),
      Offset(_projX[vBridgeApex], _projY[vBridgeApex]),
      _canopyGlintPaint,
    );

    if (!isLowBattery) {
      // Specular metallic leading-edge highlight along outer wing bevels only
      canvas.drawLine(
        Offset(_projX[vProwTip], _projY[vProwTip]),
        Offset(_projX[vPortShoulder], _projY[vPortShoulder]),
        _hullRimPaint,
      );
      canvas.drawLine(
        Offset(_projX[vProwTip], _projY[vProwTip]),
        Offset(_projX[vStbdShoulder], _projY[vStbdShoulder]),
        _hullRimPaint,
      );
      canvas.drawLine(
        Offset(_projX[vPortShoulder], _projY[vPortShoulder]),
        Offset(_projX[vPortWingtip], _projY[vPortWingtip]),
        _hullRimPaint,
      );
      canvas.drawLine(
        Offset(_projX[vStbdShoulder], _projY[vStbdShoulder]),
        Offset(_projX[vStbdWingtip], _projY[vStbdWingtip]),
        _hullRimPaint,
      );
    }

    // -------------------------------------------------------------------------
    // 7. 3D Twin Cylindrical Engine Exhaust Nozzles & Plasma Afterburners
    // -------------------------------------------------------------------------
    _paintEngineNozzle(
      canvas,
      vPortEngineMount,
      vPortEngineBell,
      scale,
      animationTime,
      isLowBattery: isLowBattery,
    );
    _paintEngineNozzle(
      canvas,
      vStbdEngineMount,
      vStbdEngineBell,
      scale,
      animationTime,
      isLowBattery: isLowBattery,
    );

    // -------------------------------------------------------------------------
    // 8. Navigation Strobe Beacons (Port Crimson, Starboard Emerald)
    // -------------------------------------------------------------------------
    final portStrobe = 0.55 + 0.45 * math.sin(animationTime * 15.0);
    final stbdStrobe = 0.55 + 0.45 * math.cos(animationTime * 15.0);
    _navPortPaint.color = VoidTheme.crimsonFlare.withValues(alpha: portStrobe);
    _navStarboardPaint.color = VoidTheme.emeraldShield.withValues(
      alpha: stbdStrobe,
    );

    canvas.drawCircle(
      Offset(_projX[vPortWingtip], _projY[vPortWingtip]),
      2.8 * scale,
      _navPortPaint,
    );
    canvas.drawCircle(
      Offset(_projX[vStbdWingtip], _projY[vStbdWingtip]),
      2.8 * scale,
      _navStarboardPaint,
    );

    // -------------------------------------------------------------------------
    // 9. Pulsating Central 3D Plasma Reactor Core Dome
    // -------------------------------------------------------------------------
    final coreX = _projX[vReactorCore];
    final coreY = _projY[vReactorCore];
    final corePulse = 1.0 + 0.20 * math.sin(animationTime * 12.0);

    if (!isLowBattery) {
      canvas.drawCircle(
        Offset(coreX, coreY),
        8.5 * scale * corePulse,
        _reactorGlowPaint,
      );
    }
    canvas.drawCircle(
      Offset(coreX, coreY),
      4.4 * scale * corePulse,
      _reactorCorePaint,
    );
    canvas.drawCircle(
      Offset(coreX, coreY),
      2.0 * scale * corePulse,
      _reactorCenterPaint,
    );
  }

  /// Renders a solid 3D triangular armor plate with Blinn-Phong lighting and
  /// subtle dark panel bevel seams (never bright wireframe lines).
  void _paintSolidArmorTriangle(
    Canvas canvas,
    int i0,
    int i1,
    int i2, {
    required int colorIdx,
    bool isLowBattery = false,
  }) {
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

    final dot = nx * _lightDirX + ny * _lightDirY + nz.abs() * _lightDirZ;
    final light = (0.36 + 0.64 * math.max(0.0, dot)).clamp(0.24, 1.0);
    final lightStep = (light * 100.0).round().clamp(0, 100);
    _facetPaint.color = _shadedColorLUT[colorIdx.clamp(0, 3)][lightStep]
        .withValues(alpha: 0.78);

    _scratchFacetPath
      ..reset()
      ..moveTo(_projX[i0], _projY[i0])
      ..lineTo(_projX[i1], _projY[i1])
      ..lineTo(_projX[i2], _projY[i2])
      ..close();

    canvas.drawPath(_scratchFacetPath, _facetPaint);
    if (!isLowBattery) {
      canvas.drawPath(_scratchFacetPath, _panelSeamPaint);
    }
  }

  /// Renders a solid 3D cylindrical engine nacelle and afterburner nozzle.
  void _paintEngineNozzle(
    Canvas canvas,
    int mountIdx,
    int bellIdx,
    double scale,
    double animationTime, {
    bool isLowBattery = false,
  }) {
    final mx = _projX[mountIdx];
    final my = _projY[mountIdx];
    final bx = _projX[bellIdx];
    final by = _projY[bellIdx];
    final nozzleRadiusX = 5.4 * scale;
    final nozzleRadiusY = 3.4 * scale;

    // 3D cylindrical nacelle housing from mount to bell
    _scratchFacetPath
      ..reset()
      ..moveTo(mx - nozzleRadiusX * 0.88, my)
      ..lineTo(mx + nozzleRadiusX * 0.88, my)
      ..lineTo(bx + nozzleRadiusX, by)
      ..lineTo(bx - nozzleRadiusX, by)
      ..close();
    canvas.drawPath(_scratchFacetPath, _engineBellPaint);

    // Zero-allocation elliptical nozzle rim using _scratchNozzlePath
    _scratchNozzlePath.reset();
    for (var step = 0; step < 16; step++) {
      final theta = step * (2.0 * math.pi / 16.0);
      final px = bx + nozzleRadiusX * math.cos(theta);
      final py = by + nozzleRadiusY * math.sin(theta);
      if (step == 0) {
        _scratchNozzlePath.moveTo(px, py);
      } else {
        _scratchNozzlePath.lineTo(px, py);
      }
    }
    _scratchNozzlePath.close();

    canvas.drawPath(_scratchNozzlePath, _engineBellPaint);
    if (!isLowBattery) {
      canvas.drawPath(_scratchNozzlePath, _engineRimPaint);
    }

    // Inner glowing plasma afterburner cone
    final plumeLen = (7.5 + 2.5 * math.sin(animationTime * 22.0)) * scale;
    _scratchFacetPath
      ..reset()
      ..moveTo(bx - nozzleRadiusX * 0.65, by)
      ..lineTo(bx, by + plumeLen)
      ..lineTo(bx + nozzleRadiusX * 0.65, by)
      ..close();
    canvas.drawPath(_scratchFacetPath, _reactorGlowPaint);
    canvas.drawCircle(Offset(bx, by), 2.5 * scale, _engineGazePaint);
    canvas.drawCircle(Offset(bx, by), 1.2 * scale, _reactorCenterPaint);
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
