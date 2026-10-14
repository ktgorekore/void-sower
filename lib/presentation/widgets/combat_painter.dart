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

import '../../domain/models/dreadnought_state.dart';
import '../../domain/models/enemy_bullet.dart';
import '../../domain/models/enemy_craft.dart';
import '../../domain/models/flak_burst.dart';
import '../../domain/models/floating_damage_number.dart';
import '../../domain/models/lance_beam.dart';
import '../services/particle_service.dart';
import '../theme/void_theme.dart';
import 'combat_camera_3d.dart';
import 'dreadnought_3d_mesh.dart';
import 'invader_3d_mesh.dart';

/// Retained Skia 3D perspective background layer rendering the 8 converging
/// orbital trench corridors, 3D lateral canyon walls with structural pylons,
/// deep-space ringed Afrofuturist planet, and planetary defense rails.
class CombatBackgroundPainter extends CustomPainter {
  const CombatBackgroundPainter({
    this.isLowBattery = false,
    this.camera = const CombatCamera3D(),
  });

  final bool isLowBattery;
  final CombatCamera3D camera;

  static final Paint _corridorPaint = Paint()
    ..color = VoidTheme.plasmaCyan.withValues(alpha: 0.28)
    ..strokeWidth = 1.2
    ..style = PaintingStyle.stroke;

  static final Paint _trenchWallFillPaint = Paint()
    ..color = const Color(0xFF0B1528).withValues(alpha: 0.72)
    ..style = PaintingStyle.fill;

  static final Paint _trenchWallRailPaint = Paint()
    ..color = VoidTheme.plasmaCyan.withValues(alpha: 0.55)
    ..strokeWidth = 1.6
    ..style = PaintingStyle.stroke;

  static final Paint _trenchPylonPaint = Paint()
    ..color = VoidTheme.nebulaAmethyst.withValues(alpha: 0.40)
    ..strokeWidth = 1.2
    ..style = PaintingStyle.stroke;

  static final Paint _planetBodyPaint = Paint()
    ..color = const Color(0xFF140D2B)
    ..style = PaintingStyle.fill;

  static final Paint _planetRimPaint = Paint()
    ..color = VoidTheme.nebulaAmethystLight.withValues(alpha: 0.65)
    ..strokeWidth = 1.5
    ..style = PaintingStyle.stroke;

  static final Paint _planetRingPaint = Paint()
    ..color = VoidTheme.solarGold.withValues(alpha: 0.45)
    ..strokeWidth = 2.0
    ..style = PaintingStyle.stroke;

  static final Paint _planetRingInnerPaint = Paint()
    ..color = VoidTheme.plasmaCyan.withValues(alpha: 0.35)
    ..strokeWidth = 1.2
    ..style = PaintingStyle.stroke;

  static final Paint _boundaryPaint = Paint()
    ..color = VoidTheme.crimsonFlare.withValues(alpha: 0.65)
    ..strokeWidth = 1.8
    ..style = PaintingStyle.stroke;

  static final Paint _railPaint = Paint()
    ..color = VoidTheme.solarGold.withValues(alpha: 0.35)
    ..strokeWidth = 1.5
    ..style = PaintingStyle.stroke;

  static final Paint _horizonArcPaint = Paint()
    ..color = VoidTheme.plasmaCyan.withValues(alpha: 0.22)
    ..strokeWidth = 1.1
    ..style = PaintingStyle.stroke;

  static final Paint _horizonGlowPaint = Paint()
    ..color = VoidTheme.plasmaCyan.withValues(alpha: 0.08)
    ..strokeWidth = 2.8
    ..style = PaintingStyle.stroke;

  static final TextPainter _apogeePainter = TextPainter(
    text: TextSpan(
      text: 'APOGEE HORIZON  Z: +40km',
      style: TextStyle(
        color: VoidTheme.plasmaCyan.withValues(alpha: 0.55),
        fontSize: 6.8,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
        fontFamily: 'monospace',
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();

  static final TextPainter _midCombatPainter = TextPainter(
    text: TextSpan(
      text: 'MID-COMBAT HORIZON  Z: +20km',
      style: TextStyle(
        color: VoidTheme.plasmaCyan.withValues(alpha: 0.55),
        fontSize: 6.8,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
        fontFamily: 'monospace',
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();

  static final TextPainter _forwardEngagePainter = TextPainter(
    text: TextSpan(
      text: 'FORWARD ENGAGE HORIZON  Z: +10km',
      style: TextStyle(
        color: VoidTheme.plasmaCyan.withValues(alpha: 0.55),
        fontSize: 6.8,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
        fontFamily: 'monospace',
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();

  static final Path _scratchArcPath = Path();

  /// Static pre-laid out painter for atmospheric threshold label.
  @visibleForTesting
  static TextPainter get thresholdPainter => _thresholdPainter;

  @visibleForTesting
  static TextPainter get apogeePainter => _apogeePainter;

  @visibleForTesting
  static TextPainter get midCombatPainter => _midCombatPainter;

  @visibleForTesting
  static TextPainter get forwardEngagePainter => _forwardEngagePainter;

  static final TextPainter _thresholdPainter = TextPainter(
    text: TextSpan(
      text: '▼ THRESHOLD ▼',
      style: TextStyle(
        color: VoidTheme.crimsonFlare.withValues(alpha: 0.85),
        fontSize: 7.5,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.2,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();

  void _draw3DSkyboxAndPlanet(Canvas canvas, Size size) {
    final vp = camera.vanishingPoint(size);
    final planetCenter = Offset(
      vp.dx,
      (vp.dy - size.height * 0.03).clamp(36.0, size.height * 0.25),
    );
    final planetR = size.width * 0.085;

    // 1. Shaded 3D Planet Sphere
    canvas.drawCircle(planetCenter, planetR, _planetBodyPaint);
    canvas.drawCircle(planetCenter, planetR, _planetRimPaint);

    // 3D Latitude / Longitude Wireframe Meridiens
    if (!isLowBattery) {
      final latRect = Rect.fromCenter(
        center: planetCenter,
        width: planetR * 2.0,
        height: planetR * 0.75 * math.sin(camera.pitchRad).clamp(0.25, 1.0),
      );
      canvas.drawOval(latRect, _horizonArcPaint);
      final lonRect = Rect.fromCenter(
        center: planetCenter,
        width: planetR * 0.85,
        height: planetR * 2.0,
      );
      canvas.drawOval(lonRect, _horizonArcPaint);
    }

    // 2. Tilted 3D Orbital Planetary Rings (responds to camera pitch & yaw)
    canvas.save();
    canvas.translate(planetCenter.dx, planetCenter.dy);
    canvas.rotate(-camera.yawRad * 0.45 - 0.12);
    final ringTilt = math.sin(camera.pitchRad * 0.75).clamp(0.18, 0.65);
    final outerRingRect = Rect.fromCenter(
      center: Offset.zero,
      width: planetR * 3.6,
      height: planetR * 3.6 * ringTilt,
    );
    final innerRingRect = Rect.fromCenter(
      center: Offset.zero,
      width: planetR * 2.7,
      height: planetR * 2.7 * ringTilt,
    );
    canvas.drawOval(outerRingRect, _planetRingPaint);
    canvas.drawOval(innerRingRect, _planetRingInnerPaint);
    canvas.restore();
  }

  void _draw3DTrenchWallSide(
    Canvas canvas,
    Size size, {
    required double normX,
  }) {
    const wallHeight = 0.24;
    final nearFloor = camera.project(size, normX: normX, normZ: 0.0);
    final farFloor = camera.project(size, normX: normX, normZ: 1.0);
    final nearTop = camera.project(
      size,
      normX: normX,
      normZ: 0.0,
      elevationY: wallHeight,
    );
    final farTop = camera.project(
      size,
      normX: normX,
      normZ: 1.0,
      elevationY: wallHeight,
    );

    // 1. Extruded 3D Canyon Side-Wall Quad
    _scratchArcPath.reset();
    _scratchArcPath.moveTo(
      nearFloor.groundOffset.dx,
      nearFloor.groundOffset.dy,
    );
    _scratchArcPath.lineTo(farFloor.groundOffset.dx, farFloor.groundOffset.dy);
    _scratchArcPath.lineTo(farTop.screenOffset.dx, farTop.screenOffset.dy);
    _scratchArcPath.lineTo(nearTop.screenOffset.dx, nearTop.screenOffset.dy);
    _scratchArcPath.close();
    canvas.drawPath(_scratchArcPath, _trenchWallFillPaint);

    // 2. Top 3D Canyon Guard Rail
    canvas.drawLine(
      nearTop.screenOffset,
      farTop.screenOffset,
      _trenchWallRailPaint,
    );

    // 3. Vertical 3D Structural Pylons along the Canyon Wall
    for (var s = 0; s <= 6; s++) {
      final z = s / 6.0;
      final pFloor = camera.project(size, normX: normX, normZ: z);
      final pTop = camera.project(
        size,
        normX: normX,
        normZ: z,
        elevationY: wallHeight,
      );
      canvas.drawLine(
        pFloor.groundOffset,
        pTop.screenOffset,
        _trenchPylonPaint,
      );
    }
  }

  void _draw3DDepthRib(
    Canvas canvas,
    Size size,
    double normZ,
    TextPainter? labelPainter,
  ) {
    final leftPt = camera.project(size, normX: 0.0, normZ: normZ);
    final rightPt = camera.project(size, normX: 1.0, normZ: normZ);
    if (!isLowBattery && labelPainter != null) {
      canvas.drawLine(
        leftPt.groundOffset,
        rightPt.groundOffset,
        _horizonGlowPaint,
      );
    }
    canvas.drawLine(
      leftPt.groundOffset,
      rightPt.groundOffset,
      _horizonArcPaint,
    );
    if (labelPainter != null) {
      final lx = (rightPt.groundOffset.dx - labelPainter.width - 6.0).clamp(
        8.0,
        size.width - labelPainter.width - 8.0,
      );
      labelPainter.paint(canvas, Offset(lx, rightPt.groundOffset.dy + 2.0));
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Deep-Space 3D Skybox & Ringed Afrofuturist Planet at Vanishing Horizon
    _draw3DSkyboxAndPlanet(canvas, size);

    // 2. 3D Extruded Orbital Trench Canyon Side-Walls (Port & Starboard)
    _draw3DTrenchWallSide(canvas, size, normX: 0.0);
    _draw3DTrenchWallSide(canvas, size, normX: 1.0);

    // 3. 8 Converging 3D Perspective Trench Floor Corridors (C1..C8)
    for (var i = 0; i <= 8; i++) {
      final normX = i / 8.0;
      final nearPt = camera.project(size, normX: normX, normZ: 0.0);
      final farPt = camera.project(size, normX: normX, normZ: 1.0);
      canvas.drawLine(
        nearPt.groundOffset,
        farPt.groundOffset,
        (i == 0 || i == 8) ? _trenchWallRailPaint : _corridorPaint,
      );
    }

    // 4. Transverse 3D Perspective Depth Ribs along Trench Floor
    for (final z in const [0.14, 0.42, 0.72, 1.0]) {
      _draw3DDepthRib(canvas, size, z, null);
    }
    _draw3DDepthRib(canvas, size, 0.88, _apogeePainter);
    _draw3DDepthRib(canvas, size, 0.56, _midCombatPainter);
    _draw3DDepthRib(canvas, size, 0.28, _forwardEngagePainter);

    // 5. 3D Threshold Defense Boundary Line at normZ = 0.0
    final threshLeft = camera.project(size, normX: 0.0, normZ: 0.0);
    final threshRight = camera.project(size, normX: 1.0, normZ: 0.0);
    canvas.drawLine(
      threshLeft.groundOffset,
      threshRight.groundOffset,
      _boundaryPaint,
    );

    _thresholdPainter.paint(
      canvas,
      Offset(
        threshLeft.groundOffset.dx + 10.0,
        threshLeft.groundOffset.dy - 12.0,
      ),
    );

    // 6. Planetary Defense Base Rail
    canvas.drawLine(
      Offset(0, size.height - 1.5),
      Offset(size.width, size.height - 1.5),
      _railPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CombatBackgroundPainter oldDelegate) =>
      oldDelegate.isLowBattery != isLowBattery || oldDelegate.camera != camera;
}

/// 60/120 FPS dynamic CustomPainter rendering particle lances, secondary flak bursts,
/// enemy vessels, enemy projectiles, visual particles, and the player's flagship dreadnought.
///
/// Employs zero-allocation object pools for all [Paint], [Path], and [TextPainter] geometry,
/// completely eliminating heap churn and Scudo allocator lock contention.
class CombatPainter extends CustomPainter {
  CombatPainter({
    required this.dreadnought,
    required this.enemies,
    required this.lances,
    required this.flaks,
    required this.particles,
    this.damageNumbers = const [],
    this.enemyBullets = const [],
    this.millTriadBays = const <int>{},
    this.predictedDamage,
    required this.animationTime,
    this.isLowBattery = false,
    this.camera = const CombatCamera3D(),
    super.repaint,
  });

  final DreadnoughtState dreadnought;
  final List<EnemyCraft> enemies;
  final List<LanceBeam> lances;
  final List<FlakBurst> flaks;
  final List<VisualParticle> particles;
  final List<FloatingDamageNumber> damageNumbers;
  final List<EnemyBullet> enemyBullets;
  final Set<int> millTriadBays;
  final double? predictedDamage;
  final double animationTime;
  final bool isLowBattery;
  final CombatCamera3D camera;

  static final Dreadnought3DMesh _dreadMesh = Dreadnought3DMesh();
  static final Invader3DMesh _invaderMesh = Invader3DMesh();
  static final Paint _millCorridorPaint = Paint()
    ..color = VoidTheme.solarGold.withValues(alpha: 0.10)
    ..style = PaintingStyle.fill;
  static final Paint _millBorderPaint = Paint()
    ..color = VoidTheme.solarGold.withValues(alpha: 0.55)
    ..strokeWidth = 1.4
    ..style = PaintingStyle.stroke;

  // ---------------------------------------------------------------------------
  // Reusable Path Scratchpads & Pre-compiled Static Geometry
  // ---------------------------------------------------------------------------
  static final Path _scratchVolumetricLancePath = Path();
  static final Path _scratchLeftFlamePath = Path();
  static final Path _scratchRightFlamePath = Path();
  static final Path _scratchReticlePath = Path();
  static final Path _scratchBarPath = Path();

  // ---------------------------------------------------------------------------
  // Pre-allocated Static Paint Pools (Zero Allocations & Zero MaskFilter Blurs)
  // ---------------------------------------------------------------------------
  static final Paint _lanceCorePaint = Paint()
    ..color = Colors.white
    ..strokeCap = StrokeCap.round;

  static final Shader _staticLanceGlowShader = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [
      Colors.transparent,
      VoidTheme.plasmaCyan.withValues(alpha: 0.50),
      Colors.white.withValues(alpha: 0.85),
      VoidTheme.plasmaCyan.withValues(alpha: 0.50),
      Colors.transparent,
    ],
  ).createShader(const Rect.fromLTWH(-1.0, 0, 2.0, 1.0));

  static final Paint _lanceGlowPaint = Paint()
    ..style = PaintingStyle.fill
    ..shader = _staticLanceGlowShader;

  static final Paint _muzzlePaint = Paint()..color = Colors.white;
  static final Paint _muzzleGlowPaint = Paint()
    ..color = VoidTheme.plasmaCyan.withValues(alpha: 0.45)
    ..style = PaintingStyle.fill;

  static final Paint _muzzleSpikePaint = Paint()
    ..color = VoidTheme.solarGold
    ..strokeWidth = 2.5;

  static final Paint _impactPaint = Paint()
    ..color = VoidTheme.plasmaCyan.withValues(alpha: 0.85)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3.0;

  static final Paint _flakPaint = Paint()..style = PaintingStyle.stroke;

  static final Paint _enemyShadowFillPaint = Paint()
    ..color = Colors.black.withValues(alpha: 0.45)
    ..style = PaintingStyle.fill;

  static final Paint _enemyShadowRingPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.1;

  static final Paint _baoRingOrbitPaint = Paint()
    ..color = VoidTheme.plasmaCyan.withValues(alpha: 0.35)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.2;

  static final Paint _baoRingNodePaint = Paint()..style = PaintingStyle.fill;

  static final Paint _warpSingularityPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.0;

  static final Paint _healthBgPaint = Paint()..color = Colors.black54;
  static final Paint _healthHullPaint = Paint()..color = Colors.redAccent;
  static final Paint _healthShieldPaint = Paint()..color = VoidTheme.plasmaCyan;

  static final Paint _bulletTailPaint = Paint()..style = PaintingStyle.stroke;
  static final Paint _bulletGlowPaint = Paint()..style = PaintingStyle.fill;
  static final Paint _bulletOrbPaint = Paint()..style = PaintingStyle.fill;
  static final Paint _bulletCenterPaint = Paint()
    ..color = Colors.white
    ..style = PaintingStyle.fill;

  static final Paint _particlePaint = Paint()..style = PaintingStyle.fill;

  static final Paint _highlightPaint = Paint()
    ..color = VoidTheme.plasmaCyan.withValues(alpha: 0.08)
    ..style = PaintingStyle.fill;

  static final Paint _aimGlowPaint = Paint()
    ..strokeWidth = 4.5
    ..style = PaintingStyle.stroke;

  static final Paint _aimPaint = Paint()
    ..strokeWidth = 1.8
    ..style = PaintingStyle.stroke;

  static final Paint _corridorBorderPaint = Paint()
    ..strokeWidth = 1.0
    ..style = PaintingStyle.stroke;

  static final Paint _lockPaint = Paint()
    ..color = VoidTheme.solarGold.withValues(alpha: 0.85)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.8;

  static final Paint _lockCrosshairPaint = Paint()
    ..color = VoidTheme.crimsonFlare
    ..strokeWidth = 1.4
    ..style = PaintingStyle.stroke;

  static final Paint _flamePaint = Paint()
    ..color = VoidTheme.plasmaCyan.withValues(alpha: 0.75)
    ..style = PaintingStyle.fill;

  static final Paint _shieldArcPaint = Paint()
    ..color = VoidTheme.plasmaCyan
    ..strokeWidth = 2.4
    ..style = PaintingStyle.stroke;

  static final Paint _shieldGlowPaint = Paint()
    ..color = VoidTheme.plasmaCyan.withValues(alpha: 0.35)
    ..strokeWidth = 5.0
    ..style = PaintingStyle.stroke;

  // ---------------------------------------------------------------------------
  // Pre-computed Text Layout Pool (8 Tactical Conduits C1..C8)
  // ---------------------------------------------------------------------------
  static final List<TextPainter> _conduitLabelPainters = List.generate(8, (i) {
    final painter = TextPainter(
      text: TextSpan(
        text: '⌖ [C${i + 1}]',
        style: const TextStyle(
          color: VoidTheme.solarGold,
          fontSize: 8.5,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.8,
          shadows: [Shadow(color: Colors.black, blurRadius: 4.0)],
        ),
      ),
    );
    painter.textDirection = TextDirection.ltr;
    painter.layout();
    return painter;
  });

  static final Paint _damageTagBgPaint = Paint()
    ..color = VoidTheme.obsidianBlack.withValues(alpha: 0.92)
    ..style = PaintingStyle.fill;

  static final Paint _damageTagBorderPaint = Paint()
    ..color = VoidTheme.plasmaCyan
    ..strokeWidth = 1.0
    ..style = PaintingStyle.stroke;

  static final Map<int, TextPainter> _damageTagPainters = {
    for (final dmg in [16, 32, 64, 128, 256, 512, 1024])
      dmg: _createDamageTagPainter(dmg),
  };

  static TextPainter _createDamageTagPainter(int dmg) {
    return TextPainter(
      text: TextSpan(
        text: '⚡ ${dmg}x DMG',
        style: const TextStyle(
          color: VoidTheme.plasmaCyan,
          fontSize: 9.5,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
  }

  static TextPainter _getDamageTagPainter(int dmgValue) {
    var painter = _damageTagPainters[dmgValue];
    if (painter == null) {
      if (_damageTagPainters.length >= 32) {
        _damageTagPainters.removeWhere(
          (k, _) => ![16, 32, 64, 128, 256, 512, 1024].contains(k),
        );
      }
      painter = _createDamageTagPainter(dmgValue);
      _damageTagPainters[dmgValue] = painter;
    }
    return painter;
  }

  /// Pre-allocated lookup table for proximity tiers (+10%, +20%, +30%, +40%, +50%, +60%).
  static final List<TextPainter> _vanguardTagPainters = List.generate(7, (i) {
    final bonus = (i == 0 ? 10 : i * 10);
    return TextPainter(
      text: TextSpan(
        text: '⚡ VANGUARD +$bonus% LANCE',
        style: const TextStyle(
          color: VoidTheme.solarGold,
          fontSize: 8.5,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.8,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
  });

  // Pre-computed flight hint text painters across 16 discrete opacity tiers
  static final List<TextPainter> _flightHintPainters = List.generate(16, (i) {
    final alpha = (0.20 + (i / 15.0) * (0.95 - 0.20)).clamp(0.0, 1.0);
    final painter = TextPainter(
      text: TextSpan(
        text: '▲   ▲   ▲',
        style: TextStyle(
          color: VoidTheme.plasmaCyan.withValues(alpha: alpha),
          fontSize: 9.5,
          fontWeight: FontWeight.w900,
          letterSpacing: 2.0,
          shadows: [
            Shadow(
              color: Colors.black.withValues(alpha: alpha),
              blurRadius: 4.0,
            ),
            Shadow(
              color: VoidTheme.plasmaCyan.withValues(alpha: alpha),
              blurRadius: 8.0,
            ),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    return painter;
  });

  @visibleForTesting
  static List<TextPainter> get vanguardTagPainters => _vanguardTagPainters;

  @visibleForTesting
  static Map<int, TextPainter> get damageTagPainters => _damageTagPainters;

  @visibleForTesting
  static TextPainter get flightHintPainter => _flightHintPainters.last;

  @visibleForTesting
  static List<TextPainter> get flightHintPainters => _flightHintPainters;

  @visibleForTesting
  static Path get scratchReticlePath => _scratchReticlePath;

  @visibleForTesting
  static Path get scratchBarPath => _scratchBarPath;

  // ---------------------------------------------------------------------------
  // 3D Space Motion & Kinetic Cues Static Paints
  // ---------------------------------------------------------------------------
  static final Paint _bowShockPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.2;

  static final Paint _anchorRingPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.2
    ..color = VoidTheme.plasmaCyan.withValues(alpha: 0.45);

  static final Paint _anchorTetherPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.0;

  @visibleForTesting
  static Paint get anchorRingPaint => _anchorRingPaint;

  @visibleForTesting
  static Paint get anchorTetherPaint => _anchorTetherPaint;

  static final Paint _bowShockGlowPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 6.0;

  static final Paint _contrailPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.4
    ..strokeCap = StrokeCap.round;

  static final Paint _altimeterRailPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.2
    ..color = const Color(0xFF1E293B);

  static final Paint _altimeterTickPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.2
    ..color = const Color(0xFF334155);

  static final Paint _altimeterMarkerPaint = Paint()
    ..style = PaintingStyle.fill
    ..color = VoidTheme.plasmaCyan;

  static final Paint _altimeterMarkerGlowPaint = Paint()
    ..style = PaintingStyle.fill
    ..color = VoidTheme.plasmaCyan.withValues(alpha: 0.35);

  static final TextPainter _altimeterOrbitPainter = TextPainter(
    text: const TextSpan(
      text: 'ORB',
      style: TextStyle(
        color: VoidTheme.emeraldShield,
        fontSize: 6.5,
        fontWeight: FontWeight.w900,
        letterSpacing: 0.5,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();

  static final TextPainter _altimeterStratoPainter = TextPainter(
    text: const TextSpan(
      text: 'STR',
      style: TextStyle(
        color: VoidTheme.textMuted,
        fontSize: 6.5,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();

  static final TextPainter _altimeterDeepSpacePainter = TextPainter(
    text: const TextSpan(
      text: 'DEEP',
      style: TextStyle(
        color: VoidTheme.plasmaCyan,
        fontSize: 6.5,
        fontWeight: FontWeight.w900,
        letterSpacing: 0.5,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();

  static final TextPainter _altimeterVanguardPainter = TextPainter(
    text: const TextSpan(
      text: '+60%',
      style: TextStyle(
        color: VoidTheme.solarGold,
        fontSize: 6.5,
        fontWeight: FontWeight.w900,
        letterSpacing: 0.5,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();

  @override
  void paint(Canvas canvas, Size size) {
    final topMargin = size.height * 0.06;
    final boundaryY = size.height - 18.0;

    final dreadNormX =
        (dreadnought.orbitalPositionX > 0.0 &&
            dreadnought.orbitalPositionX <= 1.0)
        ? dreadnought.orbitalPositionX
        : 0.4375;
    final cam = camera.copyWith(followX: dreadNormX);

    final forwardDepth =
        (dreadnought.orbitalPositionY - dreadnought.boundaryLineY).clamp(
          0.0,
          0.45,
        );
    final normForward = forwardDepth / 0.45;
    final dreadNormZ = normForward * 0.58;
    final dreadElevation = 0.14 + normForward * 0.12;

    // 0. Draw Morabaraba 3-Bay Mill Triad 3D Perspective Resonance Corridors
    if (millTriadBays.isNotEmpty) {
      for (final bay in millTriadBays) {
        final c = (bay - 8).clamp(0, 7);
        final leftX = c / 8.0;
        final rightX = (c + 1) / 8.0;
        final nearLeft = cam.project(size, normX: leftX, normZ: 0.0);
        final nearRight = cam.project(size, normX: rightX, normZ: 0.0);
        final farLeft = cam.project(size, normX: leftX, normZ: 1.0);
        final farRight = cam.project(size, normX: rightX, normZ: 1.0);

        _scratchVolumetricLancePath.reset();
        _scratchVolumetricLancePath.moveTo(
          farLeft.groundOffset.dx,
          farLeft.groundOffset.dy,
        );
        _scratchVolumetricLancePath.lineTo(
          farRight.groundOffset.dx,
          farRight.groundOffset.dy,
        );
        _scratchVolumetricLancePath.lineTo(
          nearRight.groundOffset.dx,
          nearRight.groundOffset.dy,
        );
        _scratchVolumetricLancePath.lineTo(
          nearLeft.groundOffset.dx,
          nearLeft.groundOffset.dy,
        );
        _scratchVolumetricLancePath.close();

        canvas.drawPath(_scratchVolumetricLancePath, _millCorridorPaint);
        canvas.drawPath(_scratchVolumetricLancePath, _millBorderPaint);
      }
    }

    // 1. Draw Active Particle Lances in 3D Perspective Space
    final isMultiBeamBarrage = lances.length > 1;
    for (var i = 0; i < lances.length; i++) {
      final lance = lances[i];
      if (!lance.active) continue;
      final corridor = (lance.firingBayIndex >= 8)
          ? (lance.firingBayIndex - 8)
          : lance.firingBayIndex;
      final laneNormX = (lance.originX > 0.0 && lance.originX <= 1.0)
          ? lance.originX
          : (corridor + 0.5) / 8.0;

      final nearBeam = cam.project(
        size,
        normX: laneNormX,
        normZ: dreadNormZ,
        elevationY: dreadElevation,
      );
      final farBeam = cam.project(
        size,
        normX: laneNormX,
        normZ: 1.02,
        elevationY: dreadElevation,
      );

      final rawWidth = lance.beamWidth <= 1.0
          ? (lance.beamWidth * size.width)
          : lance.beamWidth;
      final beamW = math.max(rawWidth, 14.0);
      final prowW = beamW * 1.35 * nearBeam.perspectiveScale;
      final deepSpaceW = beamW * 1.15 * farBeam.perspectiveScale;

      _scratchVolumetricLancePath.reset();
      _scratchVolumetricLancePath.moveTo(
        nearBeam.screenOffset.dx - prowW * 0.5,
        nearBeam.screenOffset.dy,
      );
      _scratchVolumetricLancePath.lineTo(
        farBeam.screenOffset.dx - deepSpaceW * 0.5,
        farBeam.screenOffset.dy,
      );
      _scratchVolumetricLancePath.lineTo(
        farBeam.screenOffset.dx + deepSpaceW * 0.5,
        farBeam.screenOffset.dy,
      );
      _scratchVolumetricLancePath.lineTo(
        nearBeam.screenOffset.dx + prowW * 0.5,
        nearBeam.screenOffset.dy,
      );
      _scratchVolumetricLancePath.close();

      canvas.drawPath(_scratchVolumetricLancePath, _lanceGlowPaint);

      _lanceCorePaint
        ..color = isMultiBeamBarrage ? VoidTheme.solarGoldLight : Colors.white
        ..strokeWidth = math.max(beamW * 0.36 * nearBeam.perspectiveScale, 3.8);
      canvas.drawLine(
        nearBeam.screenOffset,
        farBeam.screenOffset,
        _lanceCorePaint,
      );

      // 3D Shockwave Rings along the beam axis in perspective
      for (final ringZ in const [0.28, 0.58, 0.86]) {
        if (ringZ <= dreadNormZ) continue;
        final ringPt = cam.project(
          size,
          normX: laneNormX,
          normZ: ringZ,
          elevationY: dreadElevation,
        );
        final rw = beamW * 2.2 * ringPt.perspectiveScale;
        final rh = rw * 0.42;
        canvas.drawOval(
          Rect.fromCenter(center: ringPt.screenOffset, width: rw, height: rh),
          _impactPaint,
        );
      }

      // Muzzle Flare at 3D Turret Origin
      canvas.drawCircle(
        nearBeam.screenOffset,
        beamW * 1.5 * nearBeam.perspectiveScale,
        _muzzleGlowPaint,
      );
      canvas.drawCircle(
        nearBeam.screenOffset,
        beamW * 0.75 * nearBeam.perspectiveScale,
        _muzzlePaint,
      );
      canvas.drawLine(
        Offset(
          nearBeam.screenOffset.dx - beamW * 2.1 * nearBeam.perspectiveScale,
          nearBeam.screenOffset.dy,
        ),
        Offset(
          nearBeam.screenOffset.dx + beamW * 2.1 * nearBeam.perspectiveScale,
          nearBeam.screenOffset.dy,
        ),
        _muzzleSpikePaint,
      );

      // Far Horizon Impact Flare
      canvas.drawCircle(
        farBeam.screenOffset,
        beamW * 1.6 * farBeam.perspectiveScale,
        _impactPaint,
      );
    }

    // 2. Draw Active Secondary Flak Bursts in 3D Perspective
    for (var i = 0; i < flaks.length; i++) {
      final flak = flaks[i];
      if (!flak.active) continue;
      final progress =
          1.0 - (flak.remainingLifetime / math.max(flak.lifetime, 0.01));
      final rawRadius = flak.blastRadius <= 1.0
          ? (flak.blastRadius * size.width)
          : flak.blastRadius;
      final alpha = (1.0 - progress).clamp(0.0, 1.0);

      final normX = flak.worldPosX <= 1.0
          ? flak.worldPosX
          : (flak.worldPosX / size.width).clamp(0.0, 1.0);
      final normZ = flak.worldPosY <= 1.0
          ? (1.0 - (flak.worldPosY.clamp(0.0, 0.85) / 0.85)).clamp(0.0, 1.0)
          : ((boundaryY - flak.worldPosY) /
                    math.max(boundaryY - topMargin, 1.0))
                .clamp(0.0, 1.0);

      final flakProj = cam.project(
        size,
        normX: normX,
        normZ: normZ,
        elevationY: 0.18,
      );
      final radius = rawRadius * progress * flakProj.perspectiveScale;

      _flakPaint
        ..color = VoidTheme.solarGold.withValues(alpha: alpha * 0.85)
        ..strokeWidth = 3.0 * (1.0 - progress);

      canvas.drawOval(
        Rect.fromCenter(
          center: flakProj.screenOffset,
          width: radius * 2.0,
          height: radius * 1.15,
        ),
        _flakPaint,
      );
    }

    // 3. Draw 3D Polyhedral Enemy Assault Craft (Back-to-Front Painter's Order)
    for (var i = 0; i < enemies.length; i++) {
      final enemy = enemies[i];
      if (enemy.isDestroyed) continue;
      final normX = (enemy.worldPosX > 0.0 && enemy.worldPosX <= 1.0)
          ? enemy.worldPosX
          : (enemy.assignedCorridor + 0.5) / 8.0;
      final normZ = (enemy.worldPosY <= 1.0)
          ? (1.0 - (enemy.worldPosY.clamp(0.0, 0.85) / 0.85)).clamp(0.0, 1.05)
          : ((boundaryY - enemy.worldPosY) /
                    math.max(boundaryY - topMargin, 1.0))
                .clamp(0.0, 1.05);

      _drawEnemyVessel3D(
        canvas,
        size,
        cam,
        normX: normX,
        normZ: normZ,
        enemy: enemy,
      );
    }

    // 4. Draw Descending Enemy Plasma Bullets
    for (var i = 0; i < enemyBullets.length; i++) {
      _drawEnemyBullet(canvas, enemyBullets[i]);
    }

    // 5. Draw Visual Particles
    for (var i = 0; i < particles.length; i++) {
      final p = particles[i];
      _particlePaint.color = p.color.withValues(alpha: p.alpha);
      canvas.drawCircle(Offset(p.x, p.y), p.radius, _particlePaint);
    }

    // 6. Draw 3D Dreadnought Flagship & 3D Holographic Bao Ring
    _drawDreadnoughtPlatform(canvas, size, cam, boundaryY);

    // 7. Draw Floating Arcade Damage Numbers (Pre-Laid Out Text Painters)
    for (var i = 0; i < damageNumbers.length; i++) {
      final num = damageNumbers[i];
      if (num.remainingLifetime <= 0.0) continue;
      final px = (num.x <= 1.0 && num.x > 0.0) ? num.x * size.width : num.x;
      final py = (num.y <= 1.0 && num.y > 0.0) ? num.y * size.height : num.y;
      if (py < 40.0) continue;
      num.textPainter.paint(
        canvas,
        Offset(px - (num.textPainter.width / 2), py),
      );
    }
  }

  /// Renders a descending enemy plasma projectile with zero-allocation geometry.
  void _drawEnemyBullet(Canvas canvas, EnemyBullet bullet) {
    canvas.save();
    canvas.translate(bullet.x, bullet.y);

    final glowColor = Color(
      (89 << 24) | (bullet.color.toARGB32() & 0x00FFFFFF),
    );

    _bulletTailPaint
      ..color = glowColor
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset.zero, const Offset(0.0, -16.0), _bulletTailPaint);

    _bulletGlowPaint.color = glowColor;
    canvas.drawCircle(Offset.zero, bullet.radius * 1.8, _bulletGlowPaint);

    _bulletOrbPaint.color = bullet.color;
    canvas.drawCircle(Offset.zero, bullet.radius, _bulletOrbPaint);

    canvas.drawCircle(Offset.zero, bullet.radius * 0.45, _bulletCenterPaint);

    canvas.restore();
  }

  /// Renders an enemy assault craft in true 3D perspective using [Invader3DMesh],
  /// complete with a 3D trench floor shadow ellipse and vertical altitude tether.
  void _drawEnemyVessel3D(
    Canvas canvas,
    Size size,
    CombatCamera3D cam, {
    required double normX,
    required double normZ,
    required EnemyCraft enemy,
  }) {
    // 3D flight altitude above the orbital trench floor (with subtle 3D hover oscillation)
    final baseElevation = enemy.vesselType == 2
        ? 0.28
        : (enemy.vesselType == 1 ? 0.22 : 0.17);
    final hoverBob = 0.025 * math.sin(animationTime * 2.8 + enemy.entityId);
    final elevationY = baseElevation + hoverBob;

    final proj = cam.project(
      size,
      normX: normX,
      normZ: normZ,
      elevationY: elevationY,
    );
    final x = proj.screenOffset.dx;
    final y = proj.screenOffset.dy;
    final gx = proj.groundOffset.dx;
    final gy = proj.groundOffset.dy;
    final pScale = proj.perspectiveScale;

    if (y < -60.0 || y > size.height + 40.0) return;

    final sizeRatio = enemy.vesselType == 2
        ? 1.55
        : (enemy.vesselType == 1 ? 1.22 : 0.96);
    final meshScale = (0.58 + 0.68 * pScale) * sizeRatio;
    final warpProgress = enemy.warpInProgress.clamp(0.0, 1.0);

    // 1. 3D Ground Shadow Ring & Vertical Altitude Laser Tether on Trench Floor
    final shadowW = 36.0 * meshScale;
    final shadowH = 12.0 * meshScale * math.sin(cam.pitchRad).clamp(0.28, 0.85);
    final shadowRect = Rect.fromCenter(
      center: Offset(gx, gy),
      width: shadowW,
      height: shadowH,
    );
    canvas.drawOval(shadowRect, _enemyShadowFillPaint);

    final accentColor = enemy.vesselType == 2
        ? VoidTheme.crimsonFlare
        : (enemy.vesselType == 1
              ? VoidTheme.plasmaCyan
              : VoidTheme.nebulaAmethystLight);
    _enemyShadowRingPaint.color = accentColor.withValues(
      alpha: 0.42 * warpProgress,
    );
    canvas.drawOval(shadowRect, _enemyShadowRingPaint);

    // Vertical 3D altitude tether connecting floor shadow to 3D ship hull
    _anchorTetherPaint.color = accentColor.withValues(
      alpha: 0.28 * warpProgress,
    );
    canvas.drawLine(
      Offset(gx, gy),
      Offset(x, y + 8.0 * meshScale),
      _anchorTetherPaint,
    );

    // 2. Collapsing Warp Singularity Ring (if vessel is still warping in)
    if (warpProgress < 0.95) {
      final invProgress = (1.0 - warpProgress).clamp(0.0, 1.0);
      final ringRadius = (34.0 * meshScale) * (0.25 + 0.75 * invProgress);
      _warpSingularityPaint
        ..color = VoidTheme.plasmaCyan.withValues(alpha: invProgress * 0.8)
        ..strokeWidth = 2.0 * pScale;
      canvas.drawCircle(Offset(x, y), ringRadius, _warpSingularityPaint);
    }

    // 3. Render True 3D Polyhedral Ship Mesh (camera-angle responsive!)
    final effectivePitch =
        enemy.pitchAngleRad +
        cam.meshPitchBiasRad +
        0.12 * math.cos(animationTime * 2.0 + enemy.entityId);
    final effectiveRoll =
        enemy.bankAngleRad +
        cam.yawRad * 0.42 +
        0.14 * math.sin(animationTime * 1.6 + enemy.entityId);
    final effectiveYaw =
        cam.meshYawBiasRad +
        0.12 * math.sin(animationTime * 1.8 + enemy.entityId);

    _invaderMesh.projectAndPaint(
      canvas,
      center: Offset(x, y),
      vesselType: enemy.vesselType,
      pitchRad: effectivePitch,
      rollRad: effectiveRoll,
      yawRad: effectiveYaw,
      scale: meshScale,
      warpInProgress: warpProgress,
      animationTime: animationTime,
      isLowBattery: isLowBattery,
    );

    // 4. Render 3-Corridor Segmented Boss Shield Arc for Flagships (vesselType == 2)
    final corridorSpanW = (size.width * 0.92 / 8.0) * pScale;
    final hh = 24.0 * meshScale;
    if (enemy.vesselType == 2 && enemy.currentShields > 0) {
      final shieldRatio = (enemy.currentShields / math.max(enemy.maxShields, 1))
          .clamp(0.0, 1.0);
      _shieldGlowPaint.color = VoidTheme.plasmaCyan.withValues(
        alpha: 0.28 * shieldRatio,
      );
      _shieldArcPaint.color = VoidTheme.plasmaCyan.withValues(
        alpha: 0.88 * shieldRatio,
      );
      for (var seg = -1; seg <= 1; seg++) {
        final segX = x + seg * (corridorSpanW * 0.85);
        final segY = y + hh * 0.45;
        final segRect = Rect.fromCenter(
          center: Offset(segX, segY),
          width: corridorSpanW * 0.78,
          height: hh * 0.9,
        );
        canvas.drawArc(
          segRect,
          0.15 * math.pi,
          0.70 * math.pi,
          false,
          _shieldGlowPaint,
        );
        canvas.drawArc(
          segRect,
          0.15 * math.pi,
          0.70 * math.pi,
          false,
          _shieldArcPaint,
        );
      }
    }

    // 5. Health / Shield Gauges above 3D Hull
    final barW = math.max(36.0 * meshScale, 28.0 * pScale);
    const barH = 3.2;
    final barY = y - hh - 10.0;
    final barLeft = x - barW / 2;

    final hullFraction = (enemy.currentHull / math.max(enemy.maxHull, 1.0))
        .clamp(0.0, 1.0);
    _scratchBarPath.reset();
    _scratchBarPath.moveTo(barLeft, barY);
    _scratchBarPath.lineTo(barLeft + barW, barY);
    _scratchBarPath.lineTo(barLeft + barW, barY + barH);
    _scratchBarPath.lineTo(barLeft, barY + barH);
    _scratchBarPath.close();
    canvas.drawPath(_scratchBarPath, _healthBgPaint);

    if (hullFraction > 0.0) {
      _scratchBarPath.reset();
      _scratchBarPath.moveTo(barLeft, barY);
      _scratchBarPath.lineTo(barLeft + barW * hullFraction, barY);
      _scratchBarPath.lineTo(barLeft + barW * hullFraction, barY + barH);
      _scratchBarPath.lineTo(barLeft, barY + barH);
      _scratchBarPath.close();
      canvas.drawPath(_scratchBarPath, _healthHullPaint);
    }

    if (enemy.maxShields > 0) {
      final shieldFraction = (enemy.currentShields / enemy.maxShields).clamp(
        0.0,
        1.0,
      );
      final sBarY = barY - 4.5;
      _scratchBarPath.reset();
      _scratchBarPath.moveTo(barLeft, sBarY);
      _scratchBarPath.lineTo(barLeft + barW, sBarY);
      _scratchBarPath.lineTo(barLeft + barW, sBarY + barH);
      _scratchBarPath.lineTo(barLeft, sBarY + barH);
      _scratchBarPath.close();
      canvas.drawPath(_scratchBarPath, _healthBgPaint);

      if (shieldFraction > 0.0) {
        _scratchBarPath.reset();
        _scratchBarPath.moveTo(barLeft, sBarY);
        _scratchBarPath.lineTo(barLeft + barW * shieldFraction, sBarY);
        _scratchBarPath.lineTo(barLeft + barW * shieldFraction, sBarY + barH);
        _scratchBarPath.lineTo(barLeft, sBarY + barH);
        _scratchBarPath.close();
        canvas.drawPath(_scratchBarPath, _healthShieldPaint);
      }
    }
  }

  /// Renders the 3D flagship dreadnought, 3D holographic 16-bay Bao capacitor ring,
  /// 3D perspective corridor runway, and targeting reticles.
  void _drawDreadnoughtPlatform(
    Canvas canvas,
    Size size,
    CombatCamera3D cam,
    double boundaryY,
  ) {
    final topMargin = size.height * 0.06;
    final dreadNormX =
        (dreadnought.orbitalPositionX > 0.0 &&
            dreadnought.orbitalPositionX <= 1.0)
        ? dreadnought.orbitalPositionX
        : 0.4375;

    final forwardDepth =
        (dreadnought.orbitalPositionY - dreadnought.boundaryLineY).clamp(
          0.0,
          0.45,
        );
    final normForward = forwardDepth / 0.45;
    final dreadNormZ = normForward * 0.58;
    final dreadElevation = 0.14 + normForward * 0.12;

    final shipProj = cam.project(
      size,
      normX: dreadNormX,
      normZ: dreadNormZ,
      elevationY: dreadElevation,
    );
    final centerX = shipProj.screenOffset.dx;
    final shipY = shipProj.screenOffset.dy;
    final groundX = shipProj.groundOffset.dx;
    final groundY = shipProj.groundOffset.dy;
    final scale = (0.85 + 0.25 * shipProj.perspectiveScale);
    final prowY = shipY - 38.0 * scale;

    // 1. Active Corridor 3D Perspective Runway & Raised 3D Guide Rails
    final activeCorridor = (dreadNormX * 8.0).floor().clamp(0, 7);
    final leftNormX = activeCorridor / 8.0;
    final rightNormX = (activeCorridor + 1) / 8.0;

    final nearLeft = cam.project(size, normX: leftNormX, normZ: 0.0);
    final nearRight = cam.project(size, normX: rightNormX, normZ: 0.0);
    final farLeft = cam.project(size, normX: leftNormX, normZ: 1.0);
    final farRight = cam.project(size, normX: rightNormX, normZ: 1.0);

    _scratchVolumetricLancePath.reset();
    _scratchVolumetricLancePath.moveTo(
      farLeft.groundOffset.dx,
      farLeft.groundOffset.dy,
    );
    _scratchVolumetricLancePath.lineTo(
      farRight.groundOffset.dx,
      farRight.groundOffset.dy,
    );
    _scratchVolumetricLancePath.lineTo(
      nearRight.groundOffset.dx,
      nearRight.groundOffset.dy,
    );
    _scratchVolumetricLancePath.lineTo(
      nearLeft.groundOffset.dx,
      nearLeft.groundOffset.dy,
    );
    _scratchVolumetricLancePath.close();

    _highlightPaint.color = VoidTheme.plasmaCyan.withValues(alpha: 0.11);
    canvas.drawPath(_scratchVolumetricLancePath, _highlightPaint);

    _corridorBorderPaint.color = VoidTheme.plasmaCyan.withValues(alpha: 0.45);
    canvas.drawLine(
      nearLeft.groundOffset,
      farLeft.groundOffset,
      _corridorBorderPaint,
    );
    canvas.drawLine(
      nearRight.groundOffset,
      farRight.groundOffset,
      _corridorBorderPaint,
    );

    // 2. 3D Perspective Targeting Laser Beam from Dreadnought Prow to Far Horizon
    final farAim = cam.project(
      size,
      normX: dreadNormX,
      normZ: 1.0,
      elevationY: dreadElevation,
    );
    final aimPulse = 0.40 + 0.25 * math.sin(animationTime * 10.0);
    _aimGlowPaint.color = VoidTheme.plasmaCyan.withValues(
      alpha: aimPulse * 0.45,
    );
    canvas.drawLine(Offset(centerX, prowY), farAim.screenOffset, _aimGlowPaint);

    _aimPaint.color = Colors.white.withValues(alpha: aimPulse * 0.90);
    _aimPaint.strokeWidth = 1.8;
    canvas.drawLine(Offset(centerX, prowY), farAim.screenOffset, _aimPaint);

    // 3. Holographic 3D Lock-On Reticles on Enemies in Active Corridor
    for (var i = 0; i < enemies.length; i++) {
      final enemy = enemies[i];
      if (!enemy.isDestroyed && enemy.assignedCorridor == activeCorridor) {
        final eNormX = (enemy.worldPosX > 0.0 && enemy.worldPosX <= 1.0)
            ? enemy.worldPosX
            : (enemy.assignedCorridor + 0.5) / 8.0;
        final eNormZ = (enemy.worldPosY <= 1.0)
            ? (1.0 - (enemy.worldPosY.clamp(0.0, 0.85) / 0.85)).clamp(0.0, 1.05)
            : ((boundaryY - enemy.worldPosY) /
                      math.max(boundaryY - topMargin, 1.0))
                  .clamp(0.0, 1.05);
        final eElev = enemy.vesselType == 2
            ? 0.28
            : (enemy.vesselType == 1 ? 0.22 : 0.17);
        final eProj = cam.project(
          size,
          normX: eNormX,
          normZ: eNormZ,
          elevationY: eElev,
        );
        final enemyX = eProj.screenOffset.dx;
        final ey = eProj.screenOffset.dy;
        final lockSize =
            (16.0 + 2.0 * math.sin(animationTime * 8.0)) *
            (0.65 + 0.45 * eProj.perspectiveScale);
        final cornerLen = lockSize * 0.45;

        _scratchReticlePath.reset();
        _scratchReticlePath.moveTo(
          enemyX - lockSize + cornerLen,
          ey - lockSize,
        );
        _scratchReticlePath.lineTo(enemyX - lockSize, ey - lockSize);
        _scratchReticlePath.lineTo(
          enemyX - lockSize,
          ey - lockSize + cornerLen,
        );
        _scratchReticlePath.moveTo(
          enemyX + lockSize - cornerLen,
          ey - lockSize,
        );
        _scratchReticlePath.lineTo(enemyX + lockSize, ey - lockSize);
        _scratchReticlePath.lineTo(
          enemyX + lockSize,
          ey - lockSize + cornerLen,
        );
        _scratchReticlePath.moveTo(
          enemyX - lockSize + cornerLen,
          ey + lockSize,
        );
        _scratchReticlePath.lineTo(enemyX - lockSize, ey + lockSize);
        _scratchReticlePath.lineTo(
          enemyX - lockSize,
          ey + lockSize - cornerLen,
        );
        _scratchReticlePath.moveTo(
          enemyX + lockSize - cornerLen,
          ey + lockSize,
        );
        _scratchReticlePath.lineTo(enemyX + lockSize, ey + lockSize);
        _scratchReticlePath.lineTo(
          enemyX + lockSize,
          ey + lockSize - cornerLen,
        );
        canvas.drawPath(_scratchReticlePath, _lockPaint);

        _scratchReticlePath.reset();
        _scratchReticlePath.moveTo(enemyX - 3.5, ey);
        _scratchReticlePath.lineTo(enemyX + 3.5, ey);
        _scratchReticlePath.moveTo(enemyX, ey - 3.5);
        _scratchReticlePath.lineTo(enemyX, ey + 3.5);
        canvas.drawPath(_scratchReticlePath, _lockCrosshairPaint);

        final dmgValue = (predictedDamage != null && predictedDamage! > 0)
            ? predictedDamage!.toInt()
            : 16;
        final tagPainter = _getDamageTagPainter(dmgValue);

        final tagWidth = tagPainter.width + 10.0;
        const tagHeight = 18.0;
        final tagX = (enemyX + lockSize + 4.0 + tagWidth > size.width)
            ? enemyX - lockSize - 4.0 - tagWidth
            : enemyX + lockSize + 4.0;
        final tagY = ey - tagHeight * 0.5;

        final tagRRect = RRect.fromLTRBR(
          tagX,
          tagY,
          tagX + tagWidth,
          tagY + tagHeight,
          const Radius.circular(4.0),
        );
        canvas.drawRRect(tagRRect, _damageTagBgPaint);
        canvas.drawRRect(tagRRect, _damageTagBorderPaint);

        tagPainter.paint(
          canvas,
          Offset(tagX + 5.0, tagY + (tagHeight - tagPainter.height) * 0.5),
        );
      }
    }

    // 4. 3D Ground Projection Anchor Ring & Vertical Altitude Tether on Trench Floor
    final anchorW = 54.0 * shipProj.perspectiveScale;
    final anchorH =
        18.0 *
        shipProj.perspectiveScale *
        math.sin(cam.pitchRad).clamp(0.28, 0.85);
    final anchorRect = Rect.fromLTWH(
      groundX - anchorW * 0.5,
      groundY - anchorH * 0.5,
      anchorW,
      anchorH,
    );
    canvas.drawOval(anchorRect, _anchorRingPaint);

    final tetherAlpha = (0.28 + 0.35 * normForward).clamp(0.0, 0.65);
    _anchorTetherPaint.color = VoidTheme.plasmaCyan.withValues(
      alpha: tetherAlpha,
    );
    canvas.drawLine(
      Offset(groundX, groundY),
      Offset(centerX, shipY + 14.0 * scale),
      _anchorTetherPaint,
    );

    // 5. 3D Tilted 16-Bay Holographic Bao Capacitor Ring Orbiting the Dreadnought
    final ringRx = 66.0 * scale;
    final ringRy =
        66.0 * scale * math.sin(cam.pitchRad * 0.85).clamp(0.28, 0.78);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(centerX, shipY),
        width: ringRx * 2.0,
        height: ringRy * 2.0,
      ),
      _baoRingOrbitPaint,
    );
    final activeFrontlineBay = activeCorridor + 8;
    for (var b = 0; b < 16; b++) {
      final theta =
          (b / 16.0) * 2.0 * math.pi - math.pi * 0.5 - cam.yawRad * 0.6;
      final bx = centerX + ringRx * math.cos(theta);
      final by = shipY + ringRy * math.sin(theta);
      final isFrontline = b >= 8;
      final isTriad = millTriadBays.contains(b);
      final isActiveBay = b == activeFrontlineBay;
      _baoRingNodePaint.color = isTriad || isActiveBay
          ? VoidTheme.solarGold
          : (isFrontline
                ? VoidTheme.plasmaCyan.withValues(alpha: 0.85)
                : VoidTheme.nebulaAmethystLight.withValues(alpha: 0.75));
      final nodeR =
          (isTriad || isActiveBay ? 3.4 : (isFrontline ? 2.4 : 1.9)) * scale;
      canvas.drawCircle(Offset(bx, by), nodeR, _baoRingNodePaint);
    }

    // 6. 3D Spatial Attitude Angles & Perspective Dreadnought Mesh Projection
    final lateralDisplacement =
        (dreadnought.targetPositionX - dreadnought.orbitalPositionX).clamp(
          -0.25,
          0.25,
        );
    final rollRad =
        lateralDisplacement * 24.0 * (math.pi / 180.0) - cam.yawRad * 0.38;
    final pitchRad = -normForward * 0.26 - cam.meshPitchBiasRad * 0.72;
    final yawRad = lateralDisplacement * 0.14 + cam.meshYawBiasRad * 0.65;

    _dreadMesh.projectAndPaint(
      canvas,
      center: Offset(centerX, shipY),
      pitchRad: pitchRad,
      rollRad: rollRad,
      yawRad: yawRad,
      scale: scale,
      animationTime: animationTime,
      isLowBattery: isLowBattery,
    );

    // 7. 3D Aligned Twin Plasma Engine Exhaust Flames
    final thrustScale = (1.0 + 1.2 * normForward) * scale;
    final flameHeight =
        (20.0 + math.sin(animationTime * 20.0) * 5.0) * thrustScale;
    final leftBellX = _dreadMesh.projX[Dreadnought3DMesh.vPortEngineBell];
    final leftBellY = _dreadMesh.projY[Dreadnought3DMesh.vPortEngineBell];
    final rightBellX = _dreadMesh.projX[Dreadnought3DMesh.vStbdEngineBell];
    final rightBellY = _dreadMesh.projY[Dreadnought3DMesh.vStbdEngineBell];

    _scratchLeftFlamePath.reset();
    _scratchLeftFlamePath.moveTo(leftBellX - 5.0 * scale, leftBellY);
    _scratchLeftFlamePath.lineTo(leftBellX, leftBellY + flameHeight);
    _scratchLeftFlamePath.lineTo(leftBellX + 5.0 * scale, leftBellY);
    _scratchLeftFlamePath.close();
    canvas.drawPath(_scratchLeftFlamePath, _flamePaint);

    _scratchRightFlamePath.reset();
    _scratchRightFlamePath.moveTo(rightBellX - 5.0 * scale, rightBellY);
    _scratchRightFlamePath.lineTo(rightBellX, rightBellY + flameHeight);
    _scratchRightFlamePath.lineTo(rightBellX + 5.0 * scale, rightBellY);
    _scratchRightFlamePath.close();
    canvas.drawPath(_scratchRightFlamePath, _flamePaint);

    // 8. Trailing Ion Contrails during deep space forward flight
    if (normForward > 0.05) {
      final contrailLen = (35.0 + 45.0 * normForward) * scale;
      final contrailAlpha = (0.2 + 0.5 * normForward).clamp(0.0, 0.7);
      _contrailPaint.color = VoidTheme.plasmaCyan.withValues(
        alpha: contrailAlpha,
      );
      canvas.drawLine(
        Offset(leftBellX, leftBellY + flameHeight * 0.7),
        Offset(leftBellX, leftBellY + flameHeight + contrailLen),
        _contrailPaint,
      );
      canvas.drawLine(
        Offset(rightBellX, rightBellY + flameHeight * 0.7),
        Offset(rightBellX, rightBellY + flameHeight + contrailLen),
        _contrailPaint,
      );
    }

    // 9. Deep Space Energetic Bow Shock Ripple Ahead of 3D Prow
    if (normForward > 0.06) {
      final prowTipX = _dreadMesh.projX[Dreadnought3DMesh.vProwTip];
      final prowTipY = _dreadMesh.projY[Dreadnought3DMesh.vProwTip];
      final shockAlpha = (normForward * 0.85).clamp(0.0, 0.85);
      final shockW =
          104.0 * scale * (1.15 + 0.25 * math.sin(animationTime * 18.0));
      final shockH = 24.0 * scale;
      final shockCenterY = prowTipY - 8.0 * scale;
      _bowShockGlowPaint.color = VoidTheme.plasmaCyan.withValues(
        alpha: shockAlpha * 0.45,
      );
      _bowShockPaint.color = Colors.white.withValues(alpha: shockAlpha * 0.90);
      final shockRect = Rect.fromLTWH(
        prowTipX - shockW * 0.5,
        shockCenterY - shockH * 0.5,
        shockW,
        shockH,
      );
      canvas.drawArc(
        shockRect,
        math.pi * 1.15,
        math.pi * 0.7,
        false,
        _bowShockGlowPaint,
      );
      canvas.drawArc(
        shockRect,
        math.pi * 1.15,
        math.pi * 0.7,
        false,
        _bowShockPaint,
      );
    }

    // 10. Forward Kinetic Energy Canopy Shield Arc
    final shieldW = 104.0 * scale * 1.15;
    final shieldH = 48.0 * scale;
    final shieldCenterY = shipY - 10.0 * scale;
    final shieldRect = Rect.fromLTWH(
      centerX - shieldW * 0.5,
      shieldCenterY - shieldH * 0.5,
      shieldW,
      shieldH,
    );
    canvas.drawArc(
      shieldRect,
      math.pi * 1.15,
      math.pi * 0.7,
      false,
      _shieldGlowPaint,
    );
    canvas.drawArc(
      shieldRect,
      math.pi * 1.15,
      math.pi * 0.7,
      false,
      _shieldArcPaint,
    );

    // Upward Flight Discovery Hint
    if (normForward < 0.25) {
      final pulse = (0.5 + 0.5 * math.sin(animationTime * 4.0)).clamp(
        0.2,
        0.95,
      );
      final bucket = (((pulse - 0.20) / 0.75) * 15.0).round().clamp(0, 15);
      final painter = _flightHintPainters[bucket];
      final hintX = centerX - painter.width * 0.5;
      final hintY = shipY - 54.0;
      painter.paint(canvas, Offset(hintX, hintY));
    }

    // Defender Conduit Label
    if (normForward > 0.08) {
      final labelPainter = _conduitLabelPainters[activeCorridor];
      final labelX = (centerX - (labelPainter.width / 2)).clamp(
        8.0,
        size.width - labelPainter.width - 8.0,
      );
      labelPainter.paint(canvas, Offset(labelX, shipY + 16.0));
    }

    // Proximity Vanguard Telemetry Badge
    if (dreadnought.proximityMultiplier > 1.01) {
      final tierIndex = ((dreadnought.proximityMultiplier - 1.0) * 10)
          .clamp(0, 6)
          .toInt();
      final tagPainter = _vanguardTagPainters[tierIndex];
      final tagW = tagPainter.width + 8.0;
      const tagH = 15.0;
      final tagCenterY = (normForward > 0.08) ? (shipY + 34.0) : (prowY - 26.0);
      final tagLeft = centerX - tagW * 0.5;
      final tagTop = tagCenterY - tagH * 0.5;
      final tagRect = RRect.fromLTRBR(
        tagLeft,
        tagTop,
        tagLeft + tagW,
        tagTop + tagH,
        const Radius.circular(3.0),
      );
      canvas.drawRRect(tagRect, _damageTagBgPaint);
      canvas.drawRRect(tagRect, _damageTagBorderPaint);
      tagPainter.paint(
        canvas,
        Offset(
          centerX - tagPainter.width * 0.5,
          tagCenterY - tagPainter.height * 0.5,
        ),
      );
    }

    // -------------------------------------------------------------------------
    // Tactical Spatial Altimeter / Elevation Rail (Left Margin)
    // -------------------------------------------------------------------------
    final maxTravelY = (boundaryY - topMargin) * 0.60;
    final railBottom = boundaryY - 4.0;
    final railTop = railBottom - maxTravelY;
    const railX = 14.0;

    canvas.drawLine(
      Offset(railX, railTop - 6.0),
      Offset(railX, railBottom + 6.0),
      _altimeterRailPaint,
    );

    final yOrbit = railBottom;
    final yStrato = railBottom - maxTravelY * 0.35;
    final yDeep = railBottom - maxTravelY * 0.70;
    final yVanguard = railTop;

    canvas.drawLine(
      Offset(railX - 3.0, yOrbit),
      Offset(railX + 5.0, yOrbit),
      _altimeterTickPaint,
    );
    canvas.drawLine(
      Offset(railX - 2.0, yStrato),
      Offset(railX + 4.0, yStrato),
      _altimeterTickPaint,
    );
    canvas.drawLine(
      Offset(railX - 2.0, yDeep),
      Offset(railX + 4.0, yDeep),
      _altimeterTickPaint,
    );
    canvas.drawLine(
      Offset(railX - 3.0, yVanguard),
      Offset(railX + 5.0, yVanguard),
      _altimeterTickPaint,
    );

    _altimeterOrbitPainter.paint(
      canvas,
      Offset(railX + 8.0, yOrbit - _altimeterOrbitPainter.height / 2.0),
    );
    _altimeterStratoPainter.paint(
      canvas,
      Offset(railX + 8.0, yStrato - _altimeterStratoPainter.height / 2.0),
    );
    _altimeterDeepSpacePainter.paint(
      canvas,
      Offset(railX + 8.0, yDeep - _altimeterDeepSpacePainter.height / 2.0),
    );
    _altimeterVanguardPainter.paint(
      canvas,
      Offset(railX + 8.0, yVanguard - _altimeterVanguardPainter.height / 2.0),
    );

    final markerY = shipY.clamp(railTop, railBottom);
    canvas.drawCircle(Offset(railX, markerY), 4.5, _altimeterMarkerGlowPaint);
    canvas.drawCircle(Offset(railX, markerY), 2.5, _altimeterMarkerPaint);
    canvas.drawLine(
      Offset(railX - 4.0, markerY),
      Offset(railX + 4.0, markerY),
      _altimeterMarkerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CombatPainter oldDelegate) => true;
}
