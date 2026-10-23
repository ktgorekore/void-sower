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
/// spacecraft renderer for Invader assault craft (Drones, Cruisers, and Flagships).
///
/// Uses `vector_math` 3D transformations, Z-sorted closed-manifold hull triangles,
/// hardware-accelerated [ui.Vertices.raw] Gouraud shading, 3D weapon pods, and
/// glossy 3D canopies without per-frame heap allocations or wireframe clutter.
class Invader3DMesh {
  /// Initializes the 3D topology buffers for Drone, Cruiser, and Flagship.
  Invader3DMesh() {
    _initGeometry();
  }

  /// Maximum vertex count among all three invader classes (Flagship: 24 capacity).
  static const int maxVertices = 24;
  static const int _maxTriangles = 28;

  // Local model coordinate pools per vessel class (0: Drone, 1: Cruiser, 2: Flagship)
  final List<Float32List> _localX = List.generate(
    3,
    (_) => Float32List(maxVertices),
  );
  final List<Float32List> _localY = List.generate(
    3,
    (_) => Float32List(maxVertices),
  );
  final List<Float32List> _localZ = List.generate(
    3,
    (_) => Float32List(maxVertices),
  );

  // Outward unit vertex normals per vessel class
  final List<Float32List> _normX = List.generate(
    3,
    (_) => Float32List(maxVertices),
  );
  final List<Float32List> _normY = List.generate(
    3,
    (_) => Float32List(maxVertices),
  );
  final List<Float32List> _normZ = List.generate(
    3,
    (_) => Float32List(maxVertices),
  );

  // Transformed 3D camera space coordinate buffers
  final Float32List _camX = Float32List(maxVertices);
  final Float32List _camY = Float32List(maxVertices);
  final Float32List _camZ = Float32List(maxVertices);

  // Projected 2D screen coordinate buffers
  final Float32List _projX = Float32List(maxVertices);
  final Float32List _projY = Float32List(maxVertices);

  // Pre-allocated buffers for hardware-accelerated ui.Vertices.raw
  final Float32List _interleavedPositions = Float32List(maxVertices * 2);
  final Int32List _gouraudColors = Int32List(maxVertices);
  final Uint16List _sortedIndices = Uint16List(_maxTriangles * 3);
  late final List<Float32List> _vertexPositionsViews = <Float32List>[
    Float32List.sublistView(_interleavedPositions, 0, 10 * 2),
    Float32List.sublistView(_interleavedPositions, 0, 16 * 2),
    Float32List.sublistView(_interleavedPositions, 0, 20 * 2),
  ];
  late final List<Int32List> _vertexColorsViews = <Int32List>[
    Int32List.sublistView(_gouraudColors, 0, 10),
    Int32List.sublistView(_gouraudColors, 0, 16),
    Int32List.sublistView(_gouraudColors, 0, 20),
  ];
  late final List<Uint16List> _indexBufferViews = <Uint16List>[
    Uint16List.sublistView(_sortedIndices, 0, 14 * 3),
    Uint16List.sublistView(_sortedIndices, 0, 20 * 3),
    Uint16List.sublistView(_sortedIndices, 0, 28 * 3),
  ];
  final Float32List _triDepth = Float32List(_maxTriangles);
  final Int32List _triOrder = Int32List(_maxTriangles);
  final vm.Matrix3 _rotMatrix = vm.Matrix3.identity();

  /// Screen X coordinates of the most recently projected mesh vertices.
  Float32List get projX => _projX;

  /// Screen Y coordinates of the most recently projected mesh vertices.
  Float32List get projY => _projY;

  // Directional Cosmic Key-Light Vector (Normalized from upper-forward starlight)
  static const double _lightDirX = 0.34;
  static const double _lightDirY = -0.52;
  static const double _lightDirZ = 0.78;

  // Reusable scratch paths and paints to eliminate per-frame allocations
  static final Path _scratchFacetPath = Path();
  static final Path _scratchWarpRingPath = Path();
  static final Path _scratchCanopyPath = Path();

  static final Paint _verticesPaint = Paint()..style = PaintingStyle.fill;
  static final Paint _facetPaint = Paint()
    ..style = PaintingStyle.fill
    ..isAntiAlias = true;
  static final Paint _panelSeamPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.85;
  static final Paint _specularRimPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.3
    ..strokeCap = StrokeCap.round;
  static final Paint _warpGlowPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.5;
  static final Paint _enginePlumePaint = Paint()..style = PaintingStyle.fill;
  static final Paint _engineCorePaint = Paint()
    ..style = PaintingStyle.fill
    ..color = Colors.white;
  static final Paint _canopyPaint = Paint()..style = PaintingStyle.fill;

  // ---------------------------------------------------------------------------
  // Closed-Manifold Triangle Index Tables per Vessel Class
  // ---------------------------------------------------------------------------
  static final Uint16List _droneTriangles = Uint16List.fromList([
    // Ventral Keel & Side Skirts (0..5)
    droneNose, droneVentral, dronePortShoulder,
    droneNose, droneStbdShoulder, droneVentral,
    droneVentral, dronePortWingtip, dronePortShoulder,
    droneVentral, droneStbdShoulder, droneStbdWingtip,
    droneVentral, dronePortEngine, dronePortWingtip,
    droneVentral, droneStbdWingtip, droneStbdEngine,
    // Aft Ventral & Engine Fairings (6..7)
    droneVentral, droneAftKeel, dronePortEngine,
    droneVentral, droneStbdEngine, droneAftKeel,
    // Dorsal Swept Wings (8..9)
    dronePortShoulder, dronePortWingtip, dronePortEngine,
    droneStbdShoulder, droneStbdEngine, droneStbdWingtip,
    // Dorsal Forward Fuselage (10..11)
    droneNose, dronePortShoulder, droneCockpit,
    droneNose, droneCockpit, droneStbdShoulder,
    // Dorsal Aft Spine & Engine Deck (12..13)
    droneCockpit, dronePortShoulder, dronePortEngine,
    droneCockpit, droneStbdEngine, droneStbdShoulder,
  ]);

  static final Uint16List _cruiserTriangles = Uint16List.fromList([
    // Ventral Keel & Under-Hull Armor (0..7)
    cruiserProw, cruiserVentralProw, cruiserPortArmor,
    cruiserProw, cruiserStbdArmor, cruiserVentralProw,
    cruiserVentralProw, cruiserVentralKeel, cruiserPortPod,
    cruiserVentralProw, cruiserStbdPod, cruiserVentralKeel,
    cruiserVentralKeel, cruiserPortFlank, cruiserPortPod,
    cruiserVentralKeel, cruiserStbdPod, cruiserStbdFlank,
    cruiserVentralKeel, cruiserPortEngine, cruiserPortFlank,
    cruiserVentralKeel, cruiserStbdFlank, cruiserStbdEngine,
    // Outer Swept Fins & Side Pods (8..11)
    cruiserPortPod, cruiserPortFin, cruiserPortFlank,
    cruiserStbdPod, cruiserStbdFlank, cruiserStbdFin,
    cruiserPortArmor, cruiserPortPod, cruiserDorsalArmor,
    cruiserStbdArmor, cruiserDorsalArmor, cruiserStbdPod,
    // Aft Engine Deck (12..15)
    cruiserDorsalArmor, cruiserPortFlank, cruiserPortEngine,
    cruiserDorsalArmor, cruiserStbdEngine, cruiserStbdFlank,
    cruiserDorsalArmor, cruiserPortEngine, cruiserSternCenter,
    cruiserDorsalArmor, cruiserSternCenter, cruiserStbdEngine,
    // Forward Armored Prow & Command Bridge (16..19)
    cruiserProw, cruiserPortArmor, cruiserBridge,
    cruiserProw, cruiserBridge, cruiserStbdArmor,
    cruiserBridge, cruiserPortArmor, cruiserDorsalArmor,
    cruiserBridge, cruiserDorsalArmor, cruiserStbdArmor,
  ]);

  static final Uint16List _flagshipTriangles = Uint16List.fromList([
    // Ventral Citadel Keel & Under-Bastions (0..7)
    flagSpinalCannon, flagVentralCore, flagProwLeft,
    flagSpinalCannon, flagProwRight, flagVentralCore,
    flagVentralCore, flagPortBastion, flagProwLeft,
    flagVentralCore, flagProwRight, flagStbdBastion,
    flagVentralCore, flagVentralKeel, flagPortBroadside,
    flagVentralCore, flagStbdBroadside, flagVentralKeel,
    flagVentralKeel, flagPortHangar, flagPortBroadside,
    flagVentralKeel, flagStbdBroadside, flagStbdHangar,
    // Heavy Outer Wings & Sub-Engines (8..13)
    flagPortBroadside, flagPortWingtip, flagPortHangar,
    flagStbdBroadside, flagStbdHangar, flagStbdWingtip,
    flagPortHangar, flagPortWingtip, flagPortSubEngine,
    flagStbdHangar, flagStbdSubEngine, flagStbdWingtip,
    flagPortHangar, flagPortSubEngine, flagPortWarpDrive,
    flagStbdHangar, flagStbdWarpDrive, flagStbdSubEngine,
    // Broadside Armor & Hangar Decks (14..17)
    flagPortBastion, flagPortBroadside, flagUpperCitadel,
    flagStbdBastion, flagUpperCitadel, flagStbdBroadside,
    flagUpperCitadel, flagPortBroadside, flagPortHangar,
    flagUpperCitadel, flagStbdHangar, flagStbdBroadside,
    // Aft Warp Drive Citadel (18..21)
    flagUpperCitadel, flagPortHangar, flagPortWarpDrive,
    flagUpperCitadel, flagStbdWarpDrive, flagStbdHangar,
    flagUpperCitadel, flagPortWarpDrive, flagSternCenter,
    flagUpperCitadel, flagSternCenter, flagStbdWarpDrive,
    // Forward Spinal Cannon & Command Citadel (22..27)
    flagSpinalCannon, flagProwLeft, flagCommandTower,
    flagSpinalCannon, flagCommandTower, flagProwRight,
    flagProwLeft, flagPortBastion, flagCommandTower,
    flagProwRight, flagCommandTower, flagStbdBastion,
    flagCommandTower, flagPortBastion, flagUpperCitadel,
    flagCommandTower, flagUpperCitadel, flagStbdBastion,
  ]);

  void _initGeometry() {
    _initDroneGeometry();
    _initCruiserGeometry();
    _initFlagshipGeometry();
    for (var t = 0; t < 3; t++) {
      final count = t == 2 ? 20 : (t == 1 ? 16 : 10);
      for (var i = 0; i < count; i++) {
        final vx = _localX[t][i];
        final vy = _localY[t][i];
        final vz = _localZ[t][i] * 2.4;
        final len = math.sqrt(vx * vx + vy * vy + vz * vz);
        if (len > 0.001) {
          _normX[t][i] = vx / len;
          _normY[t][i] = vy / len;
          _normZ[t][i] = vz / len;
        } else {
          _normX[t][i] = 0.0;
          _normY[t][i] = 0.0;
          _normZ[t][i] = 1.0;
        }
      }
    }
  }

  // Drone Topology (10 vertices): Sleek 3D Armored Interceptor
  static const int droneNose = 0;
  static const int droneCockpit = 1;
  static const int dronePortShoulder = 2;
  static const int dronePortWingtip = 3;
  static const int droneStbdShoulder = 4;
  static const int droneStbdWingtip = 5;
  static const int dronePortEngine = 6;
  static const int droneStbdEngine = 7;
  static const int droneAftKeel = 8;
  static const int droneVentral = 9;

  void _initDroneGeometry() {
    final x = _localX[0];
    final y = _localY[0];
    final z = _localZ[0];

    x[droneNose] = 0.0;
    y[droneNose] = 20.0;
    z[droneNose] = 2.0;

    x[droneCockpit] = 0.0;
    y[droneCockpit] = 4.0;
    z[droneCockpit] = 8.0;

    x[dronePortShoulder] = -10.0;
    y[dronePortShoulder] = 2.0;
    z[dronePortShoulder] = 3.5;

    x[dronePortWingtip] = -21.0;
    y[dronePortWingtip] = -12.0;
    z[dronePortWingtip] = -1.5;

    x[droneStbdShoulder] = 10.0;
    y[droneStbdShoulder] = 2.0;
    z[droneStbdShoulder] = 3.5;

    x[droneStbdWingtip] = 21.0;
    y[droneStbdWingtip] = -12.0;
    z[droneStbdWingtip] = -1.5;

    x[dronePortEngine] = -7.0;
    y[dronePortEngine] = -16.0;
    z[dronePortEngine] = 1.0;

    x[droneStbdEngine] = 7.0;
    y[droneStbdEngine] = -16.0;
    z[droneStbdEngine] = 1.0;

    x[droneAftKeel] = 0.0;
    y[droneAftKeel] = -14.0;
    z[droneAftKeel] = 3.0;

    x[droneVentral] = 0.0;
    y[droneVentral] = 2.0;
    z[droneVentral] = -7.0;
  }

  // Cruiser Topology (16 vertices): Heavy 3D Armored Gunship Wedge
  static const int cruiserProw = 0;
  static const int cruiserBridge = 1;
  static const int cruiserDorsalArmor = 2;
  static const int cruiserPortArmor = 3;
  static const int cruiserStbdArmor = 4;
  static const int cruiserPortPod = 5;
  static const int cruiserStbdPod = 6;
  static const int cruiserPortFin = 7;
  static const int cruiserStbdFin = 8;
  static const int cruiserSternCenter = 9;
  static const int cruiserPortEngine = 10;
  static const int cruiserStbdEngine = 11;
  static const int cruiserVentralProw = 12;
  static const int cruiserVentralKeel = 13;
  static const int cruiserPortFlank = 14;
  static const int cruiserStbdFlank = 15;

  void _initCruiserGeometry() {
    final x = _localX[1];
    final y = _localY[1];
    final z = _localZ[1];

    x[cruiserProw] = 0.0;
    y[cruiserProw] = 27.0;
    z[cruiserProw] = 4.0;

    x[cruiserBridge] = 0.0;
    y[cruiserBridge] = 8.0;
    z[cruiserBridge] = 13.0;

    x[cruiserDorsalArmor] = 0.0;
    y[cruiserDorsalArmor] = -6.0;
    z[cruiserDorsalArmor] = 10.5;

    x[cruiserPortArmor] = -14.0;
    y[cruiserPortArmor] = 10.0;
    z[cruiserPortArmor] = 5.5;

    x[cruiserStbdArmor] = 14.0;
    y[cruiserStbdArmor] = 10.0;
    z[cruiserStbdArmor] = 5.5;

    x[cruiserPortPod] = -26.0;
    y[cruiserPortPod] = -4.0;
    z[cruiserPortPod] = 3.5;

    x[cruiserStbdPod] = 26.0;
    y[cruiserStbdPod] = -4.0;
    z[cruiserStbdPod] = 3.5;

    x[cruiserPortFin] = -31.0;
    y[cruiserPortFin] = -18.0;
    z[cruiserPortFin] = -2.0;

    x[cruiserStbdFin] = 31.0;
    y[cruiserStbdFin] = -18.0;
    z[cruiserStbdFin] = -2.0;

    x[cruiserSternCenter] = 0.0;
    y[cruiserSternCenter] = -22.0;
    z[cruiserSternCenter] = 2.5;

    x[cruiserPortEngine] = -12.0;
    y[cruiserPortEngine] = -24.0;
    z[cruiserPortEngine] = 1.5;

    x[cruiserStbdEngine] = 12.0;
    y[cruiserStbdEngine] = -24.0;
    z[cruiserStbdEngine] = 1.5;

    x[cruiserVentralProw] = 0.0;
    y[cruiserVentralProw] = 16.0;
    z[cruiserVentralProw] = -8.5;

    x[cruiserVentralKeel] = 0.0;
    y[cruiserVentralKeel] = -8.0;
    z[cruiserVentralKeel] = -9.5;

    x[cruiserPortFlank] = -18.0;
    y[cruiserPortFlank] = -14.0;
    z[cruiserPortFlank] = -1.0;

    x[cruiserStbdFlank] = 18.0;
    y[cruiserStbdFlank] = -14.0;
    z[cruiserStbdFlank] = -1.0;
  }

  // Flagship Topology (20 vertices): Capital 3D Dreadnought Carrier
  static const int flagSpinalCannon = 0;
  static const int flagProwLeft = 1;
  static const int flagProwRight = 2;
  static const int flagCommandTower = 3;
  static const int flagUpperCitadel = 4;
  static const int flagPortBastion = 5;
  static const int flagStbdBastion = 6;
  static const int flagPortBroadside = 7;
  static const int flagStbdBroadside = 8;
  static const int flagPortHangar = 9;
  static const int flagStbdHangar = 10;
  static const int flagPortWingtip = 11;
  static const int flagStbdWingtip = 12;
  static const int flagSternCenter = 13;
  static const int flagPortWarpDrive = 14;
  static const int flagStbdWarpDrive = 15;
  static const int flagVentralCore = 16;
  static const int flagVentralKeel = 17;
  static const int flagPortSubEngine = 18;
  static const int flagStbdSubEngine = 19;

  void _initFlagshipGeometry() {
    final x = _localX[2];
    final y = _localY[2];
    final z = _localZ[2];

    x[flagSpinalCannon] = 0.0;
    y[flagSpinalCannon] = 36.0;
    z[flagSpinalCannon] = 4.5;

    x[flagProwLeft] = -11.0;
    y[flagProwLeft] = 26.0;
    z[flagProwLeft] = 6.5;

    x[flagProwRight] = 11.0;
    y[flagProwRight] = 26.0;
    z[flagProwRight] = 6.5;

    x[flagCommandTower] = 0.0;
    y[flagCommandTower] = 6.0;
    z[flagCommandTower] = 18.5;

    x[flagUpperCitadel] = 0.0;
    y[flagUpperCitadel] = -8.0;
    z[flagUpperCitadel] = 14.5;

    x[flagPortBastion] = -22.0;
    y[flagPortBastion] = 14.0;
    z[flagPortBastion] = 8.5;

    x[flagStbdBastion] = 22.0;
    y[flagStbdBastion] = 14.0;
    z[flagStbdBastion] = 8.5;

    x[flagPortBroadside] = -34.0;
    y[flagPortBroadside] = -2.0;
    z[flagPortBroadside] = 6.0;

    x[flagStbdBroadside] = 34.0;
    y[flagStbdBroadside] = -2.0;
    z[flagStbdBroadside] = 6.0;

    x[flagPortHangar] = -25.0;
    y[flagPortHangar] = -18.0;
    z[flagPortHangar] = 4.0;

    x[flagStbdHangar] = 25.0;
    y[flagStbdHangar] = -18.0;
    z[flagStbdHangar] = 4.0;

    x[flagPortWingtip] = -42.0;
    y[flagPortWingtip] = -25.0;
    z[flagPortWingtip] = -2.0;

    x[flagStbdWingtip] = 42.0;
    y[flagStbdWingtip] = -25.0;
    z[flagStbdWingtip] = -2.0;

    x[flagSternCenter] = 0.0;
    y[flagSternCenter] = -32.0;
    z[flagSternCenter] = 4.5;

    x[flagPortWarpDrive] = -16.0;
    y[flagPortWarpDrive] = -35.0;
    z[flagPortWarpDrive] = 2.0;

    x[flagStbdWarpDrive] = 16.0;
    y[flagStbdWarpDrive] = -35.0;
    z[flagStbdWarpDrive] = 2.0;

    x[flagVentralCore] = 0.0;
    y[flagVentralCore] = 8.0;
    z[flagVentralCore] = -12.0;

    x[flagVentralKeel] = 0.0;
    y[flagVentralKeel] = -16.0;
    z[flagVentralKeel] = -14.0;

    x[flagPortSubEngine] = -28.0;
    y[flagPortSubEngine] = -29.0;
    z[flagPortSubEngine] = 0.0;

    x[flagStbdSubEngine] = 28.0;
    y[flagStbdSubEngine] = -29.0;
    z[flagStbdSubEngine] = 0.0;
  }

  /// Transforms and projects the solid 3D invader spacecraft model onto [canvas].
  void projectAndPaint(
    Canvas canvas, {
    required Offset center,
    required int vesselType,
    required double pitchRad,
    required double rollRad,
    required double yawRad,
    required double scale,
    required double warpInProgress,
    required double animationTime,
    bool isLowBattery = false,
  }) {
    final typeIndex = vesselType.clamp(0, 2);
    final count = typeIndex == 2 ? 20 : (typeIndex == 1 ? 16 : 10);

    // -------------------------------------------------------------------------
    // 1. Warp-In Singularity Rift Effect (when vessel is materializing)
    // -------------------------------------------------------------------------
    if (warpInProgress < 1.0) {
      _paintWarpSingularity(
        canvas,
        center,
        scale,
        warpInProgress,
        animationTime,
        typeIndex,
      );
    }

    final visibilityAlpha = warpInProgress.clamp(0.25, 1.0);

    // -------------------------------------------------------------------------
    // 2. 3D Rotation Matrix Calculation via vector_math (Pitch * Yaw * Roll)
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

    const double cameraZ = 320.0;
    const double focalLength = 320.0;

    final localXs = _localX[typeIndex];
    final localYs = _localY[typeIndex];
    final localZs = _localZ[typeIndex];
    final normXs = _normX[typeIndex];
    final normYs = _normY[typeIndex];
    final normZs = _normZ[typeIndex];

    // Base hull and specular colors per class
    final Color hullPrimary;
    final Color hullAccent;
    if (typeIndex == 2) {
      hullPrimary = const Color(0xFF7F1D3A);
      hullAccent = const Color(0xFFFDA4AF);
    } else if (typeIndex == 1) {
      hullPrimary = const Color(0xFF1E4E79);
      hullAccent = const Color(0xFF7DD3FC);
    } else {
      hullPrimary = const Color(0xFF582C8E);
      hullAccent = const Color(0xFFD8B4FE);
    }

    // -------------------------------------------------------------------------
    // 3. Vertex Transformation, Gouraud Normal Lighting & Projection
    // -------------------------------------------------------------------------
    for (var i = 0; i < count; i++) {
      final lx = localXs[i] * scale;
      final ly = localYs[i] * scale;
      final lz = localZs[i] * scale;

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

      final nx = r11 * normXs[i] + r12 * normYs[i] + r13 * normZs[i];
      final ny = r21 * normXs[i] + r22 * normYs[i] + r23 * normZs[i];
      final nz = r31 * normXs[i] + r32 * normYs[i] + r33 * normZs[i];

      final dot = (nx * _lightDirX + ny * _lightDirY + nz.abs() * _lightDirZ)
          .clamp(0.0, 1.0);
      final intensity = 0.42 + 0.58 * dot;
      final spec = dot * dot * 0.32;

      final a = (visibilityAlpha * 255.0).round().clamp(0, 255);
      final r = ((hullPrimary.r * intensity + hullAccent.r * spec) * 255.0)
          .round()
          .clamp(0, 255);
      final g = ((hullPrimary.g * intensity + hullAccent.g * spec) * 255.0)
          .round()
          .clamp(0, 255);
      final b = ((hullPrimary.b * intensity + hullAccent.b * spec) * 255.0)
          .round()
          .clamp(0, 255);
      _gouraudColors[i] = (a << 24) | (r << 16) | (g << 8) | b;
    }

    // -------------------------------------------------------------------------
    // 4. Aft Thruster Exhaust Cones (drawn behind solid 3D hull)
    // -------------------------------------------------------------------------
    switch (typeIndex) {
      case 0:
        _paintDroneEngines(canvas, scale, animationTime, visibilityAlpha);
        break;
      case 1:
        _paintCruiserEngines(canvas, scale, animationTime, visibilityAlpha);
        break;
      case 2:
        _paintFlagshipEngines(canvas, scale, animationTime, visibilityAlpha);
        break;
    }

    // -------------------------------------------------------------------------
    // 5. Z-Sorted Closed-Manifold Solid 3D Hull Rendering (Gouraud + Bevel)
    // -------------------------------------------------------------------------
    final tris = typeIndex == 2
        ? _flagshipTriangles
        : (typeIndex == 1 ? _cruiserTriangles : _droneTriangles);
    final triCount = tris.length ~/ 3;

    for (var t = 0; t < triCount; t++) {
      final base = t * 3;
      final i0 = tris[base];
      final i1 = tris[base + 1];
      final i2 = tris[base + 2];
      _triDepth[t] = (_camZ[i0] + _camZ[i1] + _camZ[i2]) * 0.333333;
      _triOrder[t] = t;
    }

    for (var i = 1; i < triCount; i++) {
      final keyTri = _triOrder[i];
      final keyDepth = _triDepth[keyTri];
      var j = i - 1;
      while (j >= 0 && _triDepth[_triOrder[j]] > keyDepth) {
        _triOrder[j + 1] = _triOrder[j];
        j--;
      }
      _triOrder[j + 1] = keyTri;
    }

    for (var s = 0; s < triCount; s++) {
      final t = _triOrder[s];
      final src = t * 3;
      final dst = s * 3;
      _sortedIndices[dst] = tris[src];
      _sortedIndices[dst + 1] = tris[src + 1];
      _sortedIndices[dst + 2] = tris[src + 2];
    }

    final vertices = ui.Vertices.raw(
      ui.VertexMode.triangles,
      _vertexPositionsViews[typeIndex],
      colors: _vertexColorsViews[typeIndex],
      indices: _indexBufferViews[typeIndex],
    );
    canvas.drawVertices(vertices, BlendMode.dst, _verticesPaint);
    vertices.dispose();

    // Solid Blinn-Phong bevelled armor plates with dark panel seams
    if (!isLowBattery) {
      _panelSeamPaint.color = const Color(
        0xFF060913,
      ).withValues(alpha: visibilityAlpha * 0.48);
      for (var s = 0; s < triCount; s++) {
        final t = _triOrder[s];
        final src = t * 3;
        _paintSolidArmorPlate(
          canvas,
          tris[src],
          tris[src + 1],
          tris[src + 2],
          baseColor: hullPrimary,
          specColor: hullAccent,
          alpha: visibilityAlpha,
          isLowBattery: isLowBattery,
        );
      }
    }

    // -------------------------------------------------------------------------
    // 6. Class-Specific 3D Canopies, Spinal Cannons & Specular Bevel Rims
    // -------------------------------------------------------------------------
    switch (typeIndex) {
      case 0:
        _paintDroneCanopyAndRim(canvas, scale, visibilityAlpha, isLowBattery);
        break;
      case 1:
        _paintCruiserCanopyAndRim(canvas, scale, visibilityAlpha, isLowBattery);
        break;
      case 2:
        _paintFlagshipCitadelAndRim(
          canvas,
          scale,
          visibilityAlpha,
          isLowBattery,
        );
        break;
    }
  }

  // ---------------------------------------------------------------------------
  // Warp-In Singularity Distortion FX
  // ---------------------------------------------------------------------------
  void _paintWarpSingularity(
    Canvas canvas,
    Offset center,
    double scale,
    double warpInProgress,
    double animationTime,
    int vesselType,
  ) {
    final invProgress = (1.0 - warpInProgress).clamp(0.0, 1.0);
    final ringRadius = (24.0 + 30.0 * invProgress) * scale;
    final ringAlpha = (invProgress * 0.85).clamp(0.0, 1.0);

    final riftColor = vesselType == 2
        ? VoidTheme.crimsonFlare
        : (vesselType == 1 ? VoidTheme.nebulaAmethyst : VoidTheme.plasmaCyan);

    _warpGlowPaint
      ..color = riftColor.withValues(alpha: ringAlpha)
      ..strokeWidth = 2.2 * invProgress;

    canvas.drawCircle(center, ringRadius, _warpGlowPaint);

    _scratchWarpRingPath.reset();
    final arcAngle = animationTime * 8.0;
    final arcRadius = ringRadius * 0.7;
    _scratchWarpRingPath.addArc(
      Rect.fromLTWH(
        center.dx - arcRadius,
        center.dy - arcRadius,
        arcRadius * 2,
        arcRadius * 2,
      ),
      arcAngle,
      math.pi * 0.8,
    );
    _warpGlowPaint
      ..color = Colors.white.withValues(alpha: ringAlpha * 0.75)
      ..strokeWidth = 1.6;
    canvas.drawPath(_scratchWarpRingPath, _warpGlowPaint);
  }

  // ---------------------------------------------------------------------------
  // Solid 3D Canopies, Weapon Pods & Leading-Edge Specular Rims
  // ---------------------------------------------------------------------------
  void _paintDroneCanopyAndRim(
    Canvas canvas,
    double scale,
    double alpha,
    bool isLowBattery,
  ) {
    // Glossy 3D crimson-violet sensor canopy bubble
    _scratchCanopyPath
      ..reset()
      ..moveTo(
        _projX[droneNose] * 0.55 + _projX[droneCockpit] * 0.45,
        _projY[droneNose] * 0.55 + _projY[droneCockpit] * 0.45,
      )
      ..lineTo(
        _projX[droneCockpit] * 0.70 + _projX[dronePortShoulder] * 0.30,
        _projY[droneCockpit] * 0.70 + _projY[dronePortShoulder] * 0.30,
      )
      ..lineTo(
        _projX[droneAftKeel] * 0.45 + _projX[droneCockpit] * 0.55,
        _projY[droneAftKeel] * 0.45 + _projY[droneCockpit] * 0.55,
      )
      ..lineTo(
        _projX[droneCockpit] * 0.70 + _projX[droneStbdShoulder] * 0.30,
        _projY[droneCockpit] * 0.70 + _projY[droneStbdShoulder] * 0.30,
      )
      ..close();
    _canopyPaint.color = const Color(
      0xFFE879F9,
    ).withValues(alpha: alpha * 0.88);
    canvas.drawPath(_scratchCanopyPath, _canopyPaint);

    if (!isLowBattery) {
      _specularRimPaint.color = const Color(
        0xFFF0ABFC,
      ).withValues(alpha: alpha * 0.65);
      canvas.drawLine(
        Offset(_projX[droneNose], _projY[droneNose]),
        Offset(_projX[dronePortWingtip], _projY[dronePortWingtip]),
        _specularRimPaint,
      );
      canvas.drawLine(
        Offset(_projX[droneNose], _projY[droneNose]),
        Offset(_projX[droneStbdWingtip], _projY[droneStbdWingtip]),
        _specularRimPaint,
      );
    }

    canvas.drawCircle(
      Offset(_projX[droneCockpit], _projY[droneCockpit]),
      (1.8 * scale).clamp(1.2, 3.0),
      _engineCorePaint,
    );
  }

  void _paintCruiserCanopyAndRim(
    Canvas canvas,
    double scale,
    double alpha,
    bool isLowBattery,
  ) {
    // 3D Armored Bridge Window & Dorsal Citadel
    _scratchCanopyPath
      ..reset()
      ..moveTo(
        _projX[cruiserProw] * 0.45 + _projX[cruiserBridge] * 0.55,
        _projY[cruiserProw] * 0.45 + _projY[cruiserBridge] * 0.55,
      )
      ..lineTo(
        _projX[cruiserBridge] * 0.68 + _projX[cruiserPortArmor] * 0.32,
        _projY[cruiserBridge] * 0.68 + _projY[cruiserPortArmor] * 0.32,
      )
      ..lineTo(_projX[cruiserDorsalArmor], _projY[cruiserDorsalArmor])
      ..lineTo(
        _projX[cruiserBridge] * 0.68 + _projX[cruiserStbdArmor] * 0.32,
        _projY[cruiserBridge] * 0.68 + _projY[cruiserStbdArmor] * 0.32,
      )
      ..close();
    _canopyPaint.color = const Color(
      0xFF38BDF8,
    ).withValues(alpha: alpha * 0.90);
    canvas.drawPath(_scratchCanopyPath, _canopyPaint);

    if (!isLowBattery) {
      _specularRimPaint.color = const Color(
        0xFFBAE6FD,
      ).withValues(alpha: alpha * 0.68);
      canvas.drawLine(
        Offset(_projX[cruiserProw], _projY[cruiserProw]),
        Offset(_projX[cruiserPortPod], _projY[cruiserPortPod]),
        _specularRimPaint,
      );
      canvas.drawLine(
        Offset(_projX[cruiserProw], _projY[cruiserProw]),
        Offset(_projX[cruiserStbdPod], _projY[cruiserStbdPod]),
        _specularRimPaint,
      );
    }

    canvas.drawCircle(
      Offset(_projX[cruiserBridge], _projY[cruiserBridge]),
      (2.2 * scale).clamp(1.4, 3.6),
      _engineCorePaint,
    );
  }

  void _paintFlagshipCitadelAndRim(
    Canvas canvas,
    double scale,
    double alpha,
    bool isLowBattery,
  ) {
    // 3D Golden-Crimson Command Bastion & Spinal Siege Cannon Core
    _scratchCanopyPath
      ..reset()
      ..moveTo(_projX[flagSpinalCannon], _projY[flagSpinalCannon])
      ..lineTo(
        _projX[flagCommandTower] * 0.68 + _projX[flagProwLeft] * 0.32,
        _projY[flagCommandTower] * 0.68 + _projY[flagProwLeft] * 0.32,
      )
      ..lineTo(_projX[flagUpperCitadel], _projY[flagUpperCitadel])
      ..lineTo(
        _projX[flagCommandTower] * 0.68 + _projX[flagProwRight] * 0.32,
        _projY[flagCommandTower] * 0.68 + _projY[flagProwRight] * 0.32,
      )
      ..close();
    _canopyPaint.color = VoidTheme.solarGold.withValues(alpha: alpha * 0.88);
    canvas.drawPath(_scratchCanopyPath, _canopyPaint);

    if (!isLowBattery) {
      _specularRimPaint.color = const Color(
        0xFFFECDD3,
      ).withValues(alpha: alpha * 0.72);
      canvas.drawLine(
        Offset(_projX[flagSpinalCannon], _projY[flagSpinalCannon]),
        Offset(_projX[flagCommandTower], _projY[flagCommandTower]),
        _specularRimPaint,
      );
      canvas.drawLine(
        Offset(_projX[flagProwLeft], _projY[flagProwLeft]),
        Offset(_projX[flagPortBroadside], _projY[flagPortBroadside]),
        _specularRimPaint,
      );
      canvas.drawLine(
        Offset(_projX[flagProwRight], _projY[flagProwRight]),
        Offset(_projX[flagStbdBroadside], _projY[flagStbdBroadside]),
        _specularRimPaint,
      );
    }

    canvas.drawCircle(
      Offset(_projX[flagCommandTower], _projY[flagCommandTower]),
      (2.8 * scale).clamp(1.6, 4.5),
      _engineCorePaint,
    );
  }

  void _paintDroneEngines(
    Canvas canvas,
    double scale,
    double animationTime,
    double alpha,
  ) {
    final flameH = (8.0 + math.sin(animationTime * 24.0) * 2.5) * scale;
    _drawFlame(
      canvas,
      dronePortEngine,
      flameH,
      scale,
      const Color(0xFFD946EF),
      alpha,
    );
    _drawFlame(
      canvas,
      droneStbdEngine,
      flameH,
      scale,
      const Color(0xFFD946EF),
      alpha,
    );
  }

  void _paintCruiserEngines(
    Canvas canvas,
    double scale,
    double animationTime,
    double alpha,
  ) {
    final flameH = (11.0 + math.sin(animationTime * 22.0) * 3.5) * scale;
    _drawFlame(
      canvas,
      cruiserPortEngine,
      flameH,
      scale,
      VoidTheme.plasmaCyan,
      alpha,
    );
    _drawFlame(
      canvas,
      cruiserStbdEngine,
      flameH,
      scale,
      VoidTheme.plasmaCyan,
      alpha,
    );
  }

  void _paintFlagshipEngines(
    Canvas canvas,
    double scale,
    double animationTime,
    double alpha,
  ) {
    final flameH = (14.0 + math.sin(animationTime * 20.0) * 4.0) * scale;
    _drawFlame(
      canvas,
      flagPortWarpDrive,
      flameH,
      scale,
      VoidTheme.solarGold,
      alpha,
    );
    _drawFlame(
      canvas,
      flagStbdWarpDrive,
      flameH,
      scale,
      VoidTheme.solarGold,
      alpha,
    );
    _drawFlame(
      canvas,
      flagPortSubEngine,
      flameH * 0.72,
      scale,
      VoidTheme.crimsonFlare,
      alpha,
    );
    _drawFlame(
      canvas,
      flagStbdSubEngine,
      flameH * 0.72,
      scale,
      VoidTheme.crimsonFlare,
      alpha,
    );
  }

  void _drawFlame(
    Canvas canvas,
    int engineVertex,
    double height,
    double scale,
    Color flameColor,
    double alpha,
  ) {
    final ex = _projX[engineVertex];
    final ey = _projY[engineVertex];
    final w = 3.4 * scale;

    _scratchFacetPath
      ..reset()
      ..moveTo(ex - w, ey)
      ..lineTo(ex, ey - height)
      ..lineTo(ex + w, ey)
      ..close();

    _enginePlumePaint.color = flameColor.withValues(alpha: alpha * 0.85);
    canvas.drawPath(_scratchFacetPath, _enginePlumePaint);
    canvas.drawCircle(
      Offset(ex, ey),
      (1.6 * scale).clamp(0.8, 3.2),
      _engineCorePaint,
    );
  }

  // ---------------------------------------------------------------------------
  // Solid 3D Armor Plate Shading (Blinn-Phong + Dark Panel Seams, Zero Wireframe)
  // ---------------------------------------------------------------------------
  void _paintSolidArmorPlate(
    Canvas canvas,
    int v0,
    int v1,
    int v2, {
    required Color baseColor,
    required Color specColor,
    required double alpha,
    bool isLowBattery = false,
  }) {
    final ax = _camX[v1] - _camX[v0];
    final ay = _camY[v1] - _camY[v0];
    final az = _camZ[v1] - _camZ[v0];

    final bx = _camX[v2] - _camX[v0];
    final by = _camY[v2] - _camY[v0];
    final bz = _camZ[v2] - _camZ[v0];

    final nx = ay * bz - az * by;
    final ny = az * bx - ax * bz;
    final nz = ax * by - ay * bx;

    final length = math.sqrt(nx * nx + ny * ny + nz * nz);
    if (length < 0.0001) return;

    final invLen = 1.0 / length;
    final normX = nx * invLen;
    final normY = ny * invLen;
    final normZ = nz * invLen;

    final rawDot =
        normX * _lightDirX + normY * _lightDirY + normZ.abs() * _lightDirZ;
    final lightDot = rawDot.clamp(0.0, 1.0);
    final intensity = 0.44 + 0.56 * lightDot;
    final spec = lightDot * lightDot * 0.28;

    final r = (baseColor.r * intensity + specColor.r * spec).clamp(0.0, 1.0);
    final g = (baseColor.g * intensity + specColor.g * spec).clamp(0.0, 1.0);
    final b = (baseColor.b * intensity + specColor.b * spec).clamp(0.0, 1.0);

    _facetPaint.color = Color.from(
      alpha: alpha * 0.82,
      red: r,
      green: g,
      blue: b,
    );

    _scratchFacetPath
      ..reset()
      ..moveTo(_projX[v0], _projY[v0])
      ..lineTo(_projX[v1], _projY[v1])
      ..lineTo(_projX[v2], _projY[v2])
      ..close();

    canvas.drawPath(_scratchFacetPath, _facetPaint);
    if (!isLowBattery) {
      canvas.drawPath(_scratchFacetPath, _panelSeamPaint);
    }
  }
}
