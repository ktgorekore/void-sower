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

/// High-performance, zero-allocation 3D polygonal mesh renderer for Invader
/// assault craft (Drones, Cruisers, and Flagships).
///
/// Implements 3D spatial transformation (pitch dive, banking roll, heading yaw,
/// and perspective projection) with cosmic key-light shading and warp-in
/// singularity visual effects without per-frame heap allocations.
class Invader3DMesh {
  /// Initializes the 3D topology buffers for Drone, Cruiser, and Flagship.
  Invader3DMesh() {
    _initGeometry();
  }

  // Maximum vertex count among all three invader classes (Flagship: 24 vertices).
  static const int maxVertices = 24;

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

  // Transformed 3D camera space coordinate buffers
  final Float32List _camX = Float32List(maxVertices);
  final Float32List _camY = Float32List(maxVertices);
  final Float32List _camZ = Float32List(maxVertices);

  // Projected 2D screen coordinate buffers
  final Float32List _projX = Float32List(maxVertices);
  final Float32List _projY = Float32List(maxVertices);

  /// Screen X coordinates of the most recently projected mesh vertices.
  Float32List get projX => _projX;

  /// Screen Y coordinates of the most recently projected mesh vertices.
  Float32List get projY => _projY;

  // Directional Cosmic Key-Light Vector (Normalized from upper-right space)
  static const double _lightDirX = 0.35355;
  static const double _lightDirY = -0.53033;
  static const double _lightDirZ = 0.77055;

  // Reusable scratch path and paints to eliminate per-frame allocations
  static final Path _scratchFacetPath = Path();
  static final Path _scratchWarpRingPath = Path();

  static final Paint _facetPaint = Paint()..style = PaintingStyle.fill;
  static final Paint _wireframePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.2;

  static final Paint _warpGlowPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.5;

  static final Paint _engineFlamePaint = Paint()
    ..style = PaintingStyle.fill
    ..color = VoidTheme.solarGold;

  // ---------------------------------------------------------------------------
  // Geometry Definitions
  // Coordinates:
  //   +X: Starboard (right)
  //   -X: Port (left)
  //   +Y: Nose / Prow (pointing downward towards player)
  //   -Y: Stern / Engines (aft)
  //   +Z: Dorsal (facing camera)
  //   -Z: Ventral (keel facing deep space)
  // ---------------------------------------------------------------------------

  void _initGeometry() {
    _initDroneGeometry();
    _initCruiserGeometry();
    _initFlagshipGeometry();
  }

  // Drone Topology (10 vertices): Sleek arrowhead fighter
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

    // Nose forward
    x[droneNose] = 0.0;
    y[droneNose] = 20.0;
    z[droneNose] = 2.0;

    // Cockpit dorsal ridge
    x[droneCockpit] = 0.0;
    y[droneCockpit] = 4.0;
    z[droneCockpit] = 7.0;

    // Port shoulder
    x[dronePortShoulder] = -10.0;
    y[dronePortShoulder] = 2.0;
    z[dronePortShoulder] = 3.0;

    // Port wingtip
    x[dronePortWingtip] = -22.0;
    y[dronePortWingtip] = -12.0;
    z[dronePortWingtip] = -1.0;

    // Starboard shoulder
    x[droneStbdShoulder] = 10.0;
    y[droneStbdShoulder] = 2.0;
    z[droneStbdShoulder] = 3.0;

    // Starboard wingtip
    x[droneStbdWingtip] = 22.0;
    y[droneStbdWingtip] = -12.0;
    z[droneStbdWingtip] = -1.0;

    // Port engine
    x[dronePortEngine] = -7.0;
    y[dronePortEngine] = -16.0;
    z[dronePortEngine] = 0.0;

    // Starboard engine
    x[droneStbdEngine] = 7.0;
    y[droneStbdEngine] = -16.0;
    z[droneStbdEngine] = 0.0;

    // Aft keel
    x[droneAftKeel] = 0.0;
    y[droneAftKeel] = -14.0;
    z[droneAftKeel] = 2.0;

    // Ventral spine
    x[droneVentral] = 0.0;
    y[droneVentral] = 2.0;
    z[droneVentral] = -6.0;
  }

  // Cruiser Topology (16 vertices): Armored hexagonal wedge
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
    y[cruiserProw] = 28.0;
    z[cruiserProw] = 4.0;

    x[cruiserBridge] = 0.0;
    y[cruiserBridge] = 8.0;
    z[cruiserBridge] = 12.0;

    x[cruiserDorsalArmor] = 0.0;
    y[cruiserDorsalArmor] = -6.0;
    z[cruiserDorsalArmor] = 10.0;

    x[cruiserPortArmor] = -14.0;
    y[cruiserPortArmor] = 10.0;
    z[cruiserPortArmor] = 5.0;

    x[cruiserStbdArmor] = 14.0;
    y[cruiserStbdArmor] = 10.0;
    z[cruiserStbdArmor] = 5.0;

    x[cruiserPortPod] = -28.0;
    y[cruiserPortPod] = -4.0;
    z[cruiserPortPod] = 3.0;

    x[cruiserStbdPod] = 28.0;
    y[cruiserStbdPod] = -4.0;
    z[cruiserStbdPod] = 3.0;

    x[cruiserPortFin] = -34.0;
    y[cruiserPortFin] = -18.0;
    z[cruiserPortFin] = -2.0;

    x[cruiserStbdFin] = 34.0;
    y[cruiserStbdFin] = -18.0;
    z[cruiserStbdFin] = -2.0;

    x[cruiserSternCenter] = 0.0;
    y[cruiserSternCenter] = -22.0;
    z[cruiserSternCenter] = 2.0;

    x[cruiserPortEngine] = -12.0;
    y[cruiserPortEngine] = -24.0;
    z[cruiserPortEngine] = 1.0;

    x[cruiserStbdEngine] = 12.0;
    y[cruiserStbdEngine] = -24.0;
    z[cruiserStbdEngine] = 1.0;

    x[cruiserVentralProw] = 0.0;
    y[cruiserVentralProw] = 16.0;
    z[cruiserVentralProw] = -8.0;

    x[cruiserVentralKeel] = 0.0;
    y[cruiserVentralKeel] = -8.0;
    z[cruiserVentralKeel] = -9.0;

    x[cruiserPortFlank] = -18.0;
    y[cruiserPortFlank] = -14.0;
    z[cruiserPortFlank] = -1.0;

    x[cruiserStbdFlank] = 18.0;
    y[cruiserStbdFlank] = -14.0;
    z[cruiserStbdFlank] = -1.0;
  }

  // Flagship Topology (20 vertices): Imposing capital war fortress
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
    y[flagSpinalCannon] = 38.0;
    z[flagSpinalCannon] = 4.0;

    x[flagProwLeft] = -12.0;
    y[flagProwLeft] = 28.0;
    z[flagProwLeft] = 6.0;

    x[flagProwRight] = 12.0;
    y[flagProwRight] = 28.0;
    z[flagProwRight] = 6.0;

    x[flagCommandTower] = 0.0;
    y[flagCommandTower] = 6.0;
    z[flagCommandTower] = 18.0;

    x[flagUpperCitadel] = 0.0;
    y[flagUpperCitadel] = -8.0;
    z[flagUpperCitadel] = 14.0;

    x[flagPortBastion] = -24.0;
    y[flagPortBastion] = 14.0;
    z[flagPortBastion] = 8.0;

    x[flagStbdBastion] = 24.0;
    y[flagStbdBastion] = 14.0;
    z[flagStbdBastion] = 8.0;

    x[flagPortBroadside] = -38.0;
    y[flagPortBroadside] = -2.0;
    z[flagPortBroadside] = 6.0;

    x[flagStbdBroadside] = 38.0;
    y[flagStbdBroadside] = -2.0;
    z[flagStbdBroadside] = 6.0;

    x[flagPortHangar] = -28.0;
    y[flagPortHangar] = -18.0;
    z[flagPortHangar] = 4.0;

    x[flagStbdHangar] = 28.0;
    y[flagStbdHangar] = -18.0;
    z[flagStbdHangar] = 4.0;

    x[flagPortWingtip] = -48.0;
    y[flagPortWingtip] = -26.0;
    z[flagPortWingtip] = -2.0;

    x[flagStbdWingtip] = 48.0;
    y[flagStbdWingtip] = -26.0;
    z[flagStbdWingtip] = -2.0;

    x[flagSternCenter] = 0.0;
    y[flagSternCenter] = -32.0;
    z[flagSternCenter] = 4.0;

    x[flagPortWarpDrive] = -18.0;
    y[flagPortWarpDrive] = -36.0;
    z[flagPortWarpDrive] = 2.0;

    x[flagStbdWarpDrive] = 18.0;
    y[flagStbdWarpDrive] = -36.0;
    z[flagStbdWarpDrive] = 2.0;

    x[flagVentralCore] = 0.0;
    y[flagVentralCore] = 8.0;
    z[flagVentralCore] = -12.0;

    x[flagVentralKeel] = 0.0;
    y[flagVentralKeel] = -16.0;
    z[flagVentralKeel] = -14.0;

    x[flagPortSubEngine] = -32.0;
    y[flagPortSubEngine] = -30.0;
    z[flagPortSubEngine] = 0.0;

    x[flagStbdSubEngine] = 32.0;
    y[flagStbdSubEngine] = -30.0;
    z[flagStbdSubEngine] = 0.0;
  }

  /// Transforms and projects the 3D invader mesh onto [canvas].
  ///
  /// [center]: Viewport pivot coordinate for the craft.
  /// [vesselType]: 0 (Drone), 1 (Cruiser), or 2 (Flagship).
  /// [pitchRad]: 3D pitch dive angle in radians.
  /// [rollRad]: 3D banking roll angle in radians.
  /// [yawRad]: 3D yaw heading angle in radians.
  /// [scale]: Base physical scale multiplier.
  /// [warpInProgress]: Warp-in progress factor (0.0 to 1.0). When < 1.0,
  /// renders singularity rift rings and hologram wireframe apparition.
  /// [animationTime]: Continuous global animation timer in seconds.
  /// [isLowBattery]: When true, reduces glow and overlay passes.
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

    final visibilityAlpha = warpInProgress.clamp(0.15, 1.0);

    // -------------------------------------------------------------------------
    // 2. 3D Rotation Matrix Calculation (Pitch * Yaw * Roll)
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

    const double cameraZ = 320.0;
    const double focalLength = 320.0;

    final localXs = _localX[typeIndex];
    final localYs = _localY[typeIndex];
    final localZs = _localZ[typeIndex];

    // -------------------------------------------------------------------------
    // 3. Vertex Transformation & Perspective Projection
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

      _projX[i] = center.dx + rx * invZ;
      _projY[i] = center.dy + ry * invZ;
    }

    // -------------------------------------------------------------------------
    // 4. Facet & Wireframe Rendering by Class
    // -------------------------------------------------------------------------
    switch (typeIndex) {
      case 0:
        _paintDroneMesh(canvas, visibilityAlpha, isLowBattery);
        _paintDroneEngines(canvas, scale, animationTime);
        break;
      case 1:
        _paintCruiserMesh(canvas, visibilityAlpha, isLowBattery);
        _paintCruiserEngines(canvas, scale, animationTime);
        break;
      case 2:
        _paintFlagshipMesh(canvas, visibilityAlpha, isLowBattery);
        _paintFlagshipEngines(canvas, scale, animationTime);
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
    final ringRadius = (32.0 + 40.0 * invProgress) * scale;
    final ringAlpha = (invProgress * 0.9).clamp(0.0, 1.0);

    final riftColor = vesselType == 2
        ? VoidTheme.crimsonFlare
        : (vesselType == 1 ? VoidTheme.nebulaAmethyst : VoidTheme.plasmaCyan);

    _warpGlowPaint
      ..color = riftColor.withValues(alpha: ringAlpha)
      ..strokeWidth = 2.5 * invProgress;

    // Collapsing singularity ring
    canvas.drawCircle(center, ringRadius, _warpGlowPaint);

    // Dynamic chromatic aberration arc
    _scratchWarpRingPath.reset();
    final arcAngle = animationTime * 8.0;
    _scratchWarpRingPath.addArc(
      Rect.fromCircle(center: center, radius: ringRadius * 0.7),
      arcAngle,
      math.pi * 0.8,
    );
    _warpGlowPaint
      ..color = Colors.white.withValues(alpha: ringAlpha * 0.75)
      ..strokeWidth = 1.8;
    canvas.drawPath(_scratchWarpRingPath, _warpGlowPaint);
  }

  // ---------------------------------------------------------------------------
  // Drone Facet Drawing
  // ---------------------------------------------------------------------------
  void _paintDroneMesh(Canvas canvas, double alpha, bool isLowBattery) {
    const baseColor = Color(0xFF1E112A);
    const outlineColor = VoidTheme.nebulaAmethystLight;

    // Dorsal Port Wing
    _paintFacet(
      canvas,
      droneNose,
      dronePortShoulder,
      droneCockpit,
      baseColor: baseColor,
      outlineColor: outlineColor,
      alpha: alpha,
    );
    _paintFacet(
      canvas,
      dronePortShoulder,
      dronePortWingtip,
      dronePortEngine,
      baseColor: const Color(0xFF120B1C),
      outlineColor: outlineColor,
      alpha: alpha,
    );

    // Dorsal Starboard Wing
    _paintFacet(
      canvas,
      droneNose,
      droneCockpit,
      droneStbdShoulder,
      baseColor: baseColor,
      outlineColor: outlineColor,
      alpha: alpha,
    );
    _paintFacet(
      canvas,
      droneStbdShoulder,
      droneStbdEngine,
      droneStbdWingtip,
      baseColor: const Color(0xFF120B1C),
      outlineColor: outlineColor,
      alpha: alpha,
    );

    // Center Spine & Aft
    _paintFacet(
      canvas,
      droneCockpit,
      dronePortEngine,
      droneAftKeel,
      baseColor: const Color(0xFF261638),
      outlineColor: outlineColor,
      alpha: alpha,
    );
    _paintFacet(
      canvas,
      droneCockpit,
      droneAftKeel,
      droneStbdEngine,
      baseColor: const Color(0xFF261638),
      outlineColor: outlineColor,
      alpha: alpha,
    );
  }

  void _paintDroneEngines(Canvas canvas, double scale, double animationTime) {
    final flameH = (8.0 + math.sin(animationTime * 24.0) * 3.0) * scale;
    _drawFlame(canvas, dronePortEngine, flameH, scale);
    _drawFlame(canvas, droneStbdEngine, flameH, scale);
  }

  // ---------------------------------------------------------------------------
  // Cruiser Facet Drawing
  // ---------------------------------------------------------------------------
  void _paintCruiserMesh(Canvas canvas, double alpha, bool isLowBattery) {
    const baseColor = Color(0xFF1A1333);
    const outlineColor = VoidTheme.plasmaCyan;

    // Prow facets
    _paintFacet(
      canvas,
      cruiserProw,
      cruiserPortArmor,
      cruiserBridge,
      baseColor: baseColor,
      outlineColor: outlineColor,
      alpha: alpha,
    );
    _paintFacet(
      canvas,
      cruiserProw,
      cruiserBridge,
      cruiserStbdArmor,
      baseColor: baseColor,
      outlineColor: outlineColor,
      alpha: alpha,
    );

    // Lateral pods
    _paintFacet(
      canvas,
      cruiserPortArmor,
      cruiserPortPod,
      cruiserDorsalArmor,
      baseColor: const Color(0xFF130E26),
      outlineColor: outlineColor,
      alpha: alpha,
    );
    _paintFacet(
      canvas,
      cruiserStbdArmor,
      cruiserDorsalArmor,
      cruiserStbdPod,
      baseColor: const Color(0xFF130E26),
      outlineColor: outlineColor,
      alpha: alpha,
    );

    // Wings / Fins
    _paintFacet(
      canvas,
      cruiserPortPod,
      cruiserPortFin,
      cruiserPortFlank,
      baseColor: const Color(0xFF0F0B1E),
      outlineColor: outlineColor,
      alpha: alpha,
    );
    _paintFacet(
      canvas,
      cruiserStbdPod,
      cruiserStbdFlank,
      cruiserStbdFin,
      baseColor: const Color(0xFF0F0B1E),
      outlineColor: outlineColor,
      alpha: alpha,
    );

    // Aft superstructure
    _paintFacet(
      canvas,
      cruiserDorsalArmor,
      cruiserPortEngine,
      cruiserSternCenter,
      baseColor: const Color(0xFF231B45),
      outlineColor: outlineColor,
      alpha: alpha,
    );
    _paintFacet(
      canvas,
      cruiserDorsalArmor,
      cruiserSternCenter,
      cruiserStbdEngine,
      baseColor: const Color(0xFF231B45),
      outlineColor: outlineColor,
      alpha: alpha,
    );
  }

  void _paintCruiserEngines(Canvas canvas, double scale, double animationTime) {
    final flameH = (12.0 + math.sin(animationTime * 22.0) * 4.0) * scale;
    _drawFlame(canvas, cruiserPortEngine, flameH, scale);
    _drawFlame(canvas, cruiserStbdEngine, flameH, scale);
  }

  // ---------------------------------------------------------------------------
  // Flagship Facet Drawing
  // ---------------------------------------------------------------------------
  void _paintFlagshipMesh(Canvas canvas, double alpha, bool isLowBattery) {
    const baseColor = Color(0xFF2A0D15);
    const outlineColor = VoidTheme.crimsonFlare;

    // Heavy prow spinal cannon
    _paintFacet(
      canvas,
      flagSpinalCannon,
      flagProwLeft,
      flagCommandTower,
      baseColor: baseColor,
      outlineColor: outlineColor,
      alpha: alpha,
    );
    _paintFacet(
      canvas,
      flagSpinalCannon,
      flagCommandTower,
      flagProwRight,
      baseColor: baseColor,
      outlineColor: outlineColor,
      alpha: alpha,
    );

    // Bastions
    _paintFacet(
      canvas,
      flagProwLeft,
      flagPortBastion,
      flagCommandTower,
      baseColor: const Color(0xFF200A10),
      outlineColor: outlineColor,
      alpha: alpha,
    );
    _paintFacet(
      canvas,
      flagProwRight,
      flagCommandTower,
      flagStbdBastion,
      baseColor: const Color(0xFF200A10),
      outlineColor: outlineColor,
      alpha: alpha,
    );

    // Broadside armor plates
    _paintFacet(
      canvas,
      flagPortBastion,
      flagPortBroadside,
      flagUpperCitadel,
      baseColor: const Color(0xFF18070C),
      outlineColor: outlineColor,
      alpha: alpha,
    );
    _paintFacet(
      canvas,
      flagStbdBastion,
      flagUpperCitadel,
      flagStbdBroadside,
      baseColor: const Color(0xFF18070C),
      outlineColor: outlineColor,
      alpha: alpha,
    );

    // Heavy swept wings
    _paintFacet(
      canvas,
      flagPortBroadside,
      flagPortWingtip,
      flagPortHangar,
      baseColor: const Color(0xFF14050A),
      outlineColor: outlineColor,
      alpha: alpha,
    );
    _paintFacet(
      canvas,
      flagStbdBroadside,
      flagStbdHangar,
      flagStbdWingtip,
      baseColor: const Color(0xFF14050A),
      outlineColor: outlineColor,
      alpha: alpha,
    );

    // Stern Citadel & Warp drives
    _paintFacet(
      canvas,
      flagUpperCitadel,
      flagPortWarpDrive,
      flagSternCenter,
      baseColor: const Color(0xFF38121D),
      outlineColor: outlineColor,
      alpha: alpha,
    );
    _paintFacet(
      canvas,
      flagUpperCitadel,
      flagSternCenter,
      flagStbdWarpDrive,
      baseColor: const Color(0xFF38121D),
      outlineColor: outlineColor,
      alpha: alpha,
    );
  }

  void _paintFlagshipEngines(
    Canvas canvas,
    double scale,
    double animationTime,
  ) {
    final flameH = (18.0 + math.sin(animationTime * 20.0) * 5.0) * scale;
    _drawFlame(canvas, flagPortWarpDrive, flameH, scale);
    _drawFlame(canvas, flagStbdWarpDrive, flameH, scale);
    _drawFlame(canvas, flagPortSubEngine, flameH * 0.7, scale);
    _drawFlame(canvas, flagStbdSubEngine, flameH * 0.7, scale);
  }

  // ---------------------------------------------------------------------------
  // Engine Flame Primitive
  // ---------------------------------------------------------------------------
  void _drawFlame(
    Canvas canvas,
    int engineVertex,
    double height,
    double scale,
  ) {
    final ex = _projX[engineVertex];
    final ey = _projY[engineVertex];
    final w = 4.0 * scale;

    _scratchFacetPath.reset();
    _scratchFacetPath.moveTo(ex - w, ey);
    _scratchFacetPath.lineTo(ex, ey - height); // Exhaust plumes backward (-Y)
    _scratchFacetPath.lineTo(ex + w, ey);
    _scratchFacetPath.close();

    canvas.drawPath(_scratchFacetPath, _engineFlamePaint);
  }

  // ---------------------------------------------------------------------------
  // Facet Shading & Projection Math
  // ---------------------------------------------------------------------------
  void _paintFacet(
    Canvas canvas,
    int v0,
    int v1,
    int v2, {
    required Color baseColor,
    required Color outlineColor,
    required double alpha,
  }) {
    // 1. Calculate Face Normal via 3D Cross Product in Camera Space
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

    // 2. Backface Culling (Dorsal faces face towards camera: normZ > 0)
    if (normZ <= -0.1) return;

    // 3. Directional Starlight Dot Product
    final lightDot =
        (normX * _lightDirX + normY * _lightDirY + normZ * _lightDirZ).clamp(
          0.0,
          1.0,
        );
    final intensity = 0.50 + 0.50 * lightDot;

    final r = (baseColor.r * intensity).clamp(0.0, 1.0);
    final g = (baseColor.g * intensity).clamp(0.0, 1.0);
    final b = (baseColor.b * intensity).clamp(0.0, 1.0);

    _facetPaint.color = Color.from(
      alpha: alpha * baseColor.a,
      red: r,
      green: g,
      blue: b,
    );

    // 4. Construct Screen Path from Projected 2D Vertices
    _scratchFacetPath.reset();
    _scratchFacetPath.moveTo(_projX[v0], _projY[v0]);
    _scratchFacetPath.lineTo(_projX[v1], _projY[v1]);
    _scratchFacetPath.lineTo(_projX[v2], _projY[v2]);
    _scratchFacetPath.close();

    canvas.drawPath(_scratchFacetPath, _facetPaint);

    // 5. Wireframe Edge Accent
    _wireframePaint.color = outlineColor.withValues(alpha: alpha * 0.75);
    canvas.drawPath(_scratchFacetPath, _wireframePaint);
  }
}
