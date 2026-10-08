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
import 'dreadnought_3d_mesh.dart';

/// Retained Skia static background layer rendering the 8 tactical corridors,
/// atmospheric defense boundary line, and planetary defense rails.
///
/// Wrapped in a [RepaintBoundary] so Flutter rasterizes this geometry to an offscreen
/// GPU surface once, consuming zero raster cycles on subsequent dynamic frame ticks.
class CombatBackgroundPainter extends CustomPainter {
  const CombatBackgroundPainter({this.isLowBattery = false});

  final bool isLowBattery;

  static final Paint _corridorPaint = Paint()
    ..color = VoidTheme.cosmicNavy.withValues(alpha: 0.35)
    ..strokeWidth = 1.0
    ..style = PaintingStyle.stroke;

  static final Paint _boundaryPaint = Paint()
    ..color = VoidTheme.crimsonFlare.withValues(alpha: 0.5)
    ..strokeWidth = 1.5
    ..style = PaintingStyle.stroke;

  static final Paint _railPaint = Paint()
    ..color = VoidTheme.solarGold.withValues(alpha: 0.35)
    ..strokeWidth = 1.5
    ..style = PaintingStyle.stroke;

  static final Paint _horizonArcPaint = Paint()
    ..color = VoidTheme.plasmaCyan.withValues(alpha: 0.14)
    ..strokeWidth = 1.0
    ..style = PaintingStyle.stroke;

  static final Paint _horizonGlowPaint = Paint()
    ..color = VoidTheme.plasmaCyan.withValues(alpha: 0.05)
    ..strokeWidth = 2.5
    ..style = PaintingStyle.stroke;

  static final TextPainter _apogeePainter = TextPainter(
    text: TextSpan(
      text: 'APOGEE HORIZON  Z: +40km',
      style: TextStyle(
        color: VoidTheme.plasmaCyan.withValues(alpha: 0.40),
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
        color: VoidTheme.plasmaCyan.withValues(alpha: 0.40),
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
        color: VoidTheme.plasmaCyan.withValues(alpha: 0.40),
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

  void _drawDepthHorizon(
    Canvas canvas,
    Size size,
    double y,
    double sag,
    TextPainter labelPainter,
  ) {
    _scratchArcPath.reset();
    _scratchArcPath.moveTo(0, y);
    _scratchArcPath.quadraticBezierTo(size.width * 0.5, y + sag, size.width, y);
    if (!isLowBattery) {
      canvas.drawPath(_scratchArcPath, _horizonGlowPaint);
    }
    canvas.drawPath(_scratchArcPath, _horizonArcPaint);
    labelPainter.paint(
      canvas,
      Offset(size.width - labelPainter.width - 12.0, y + 2.0),
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final corridorWidth = size.width / 8.0;
    final boundaryY = size.height - 18.0;
    final vpX = size.width * 0.5;

    // 1. Draw 8 Tactical Combat Corridors (3D Converging Guides extending to viewport base)
    if (isLowBattery) {
      for (var i = 1; i < 8; i++) {
        final xBottom = i * corridorWidth;
        final xTop = vpX + (xBottom - vpX) * 0.85;
        canvas.drawLine(
          Offset(xTop, 0.0),
          Offset(xBottom, size.height),
          _corridorPaint,
        );
      }
    } else {
      for (var i = 1; i < 8; i++) {
        final xBottom = i * corridorWidth;
        // Subtle 15% perspective convergence towards vanishing point (0.5, 0.18)
        final xTop = vpX + (xBottom - vpX) * 0.85;
        var y = 0.0;
        while (y < size.height) {
          final t0 = (y / size.height).clamp(0.0, 1.0);
          final t1 = (math.min(y + 4.0, size.height) / size.height).clamp(
            0.0,
            1.0,
          );
          final x0 = xTop + (xBottom - xTop) * t0;
          final x1 = xTop + (xBottom - xTop) * t1;
          canvas.drawLine(
            Offset(x0, y),
            Offset(x1, math.min(y + 4.0, size.height)),
            _corridorPaint,
          );
          y += 8.0;
        }
      }
    }

    // 1b. Concentric 3D Depth Horizon Rings (Apogee, Mid-Combat, Forward Engage)
    final yApogee = size.height * 0.20;
    final yMidCombat = size.height * 0.42;
    final yForwardEngage = size.height * 0.65;

    _drawDepthHorizon(canvas, size, yApogee, 12.0, _apogeePainter);
    _drawDepthHorizon(canvas, size, yMidCombat, 16.0, _midCombatPainter);
    _drawDepthHorizon(
      canvas,
      size,
      yForwardEngage,
      20.0,
      _forwardEngagePainter,
    );

    // 2. Draw Atmospheric Defense Boundary Line & Futuristic Label
    canvas.drawLine(
      Offset(0, boundaryY),
      Offset(size.width, boundaryY),
      _boundaryPaint,
    );

    _thresholdPainter.paint(canvas, Offset(14.0, boundaryY - 11.0));

    // 3. Draw Planetary Defense Horizon Line
    canvas.drawLine(
      Offset(0, size.height - 1.5),
      Offset(size.width, size.height - 1.5),
      _railPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CombatBackgroundPainter oldDelegate) =>
      oldDelegate.isLowBattery != isLowBattery;
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
    this.predictedDamage,
    required this.animationTime,
    this.isLowBattery = false,
    super.repaint,
  });

  final DreadnoughtState dreadnought;
  final List<EnemyCraft> enemies;
  final List<LanceBeam> lances;
  final List<FlakBurst> flaks;
  final List<VisualParticle> particles;
  final List<FloatingDamageNumber> damageNumbers;
  final List<EnemyBullet> enemyBullets;
  final double? predictedDamage;
  final double animationTime;
  final bool isLowBattery;

  static final Dreadnought3DMesh _dreadMesh = Dreadnought3DMesh();

  // ---------------------------------------------------------------------------
  // Reusable Path Scratchpads & Pre-compiled Static Geometry
  // ---------------------------------------------------------------------------
  static final Path _scratchVolumetricLancePath = Path();
  static final Path _scratchLeftFlamePath = Path();
  static final Path _scratchRightFlamePath = Path();
  static final Path _scratchEnemyHullPath = Path();
  static final Path _scratchEnemyDetailPath = Path();
  static final Path _scratchEnemyThrusterPath = Path();
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

  // Invader Vessel Vector Rendering Paints (Zero Allocations)
  static final Paint _enemyDroneHullPaint = Paint()
    ..color = const Color(0xFF160D2A)
    ..style = PaintingStyle.fill;

  static final Paint _enemyDroneAccentPaint = Paint()
    ..color = VoidTheme.nebulaAmethyst
    ..style = PaintingStyle.fill;

  static final Paint _enemyCruiserHullPaint = Paint()
    ..color = const Color(0xFF0C1026)
    ..style = PaintingStyle.fill;

  static final Paint _enemyCruiserAccentPaint = Paint()
    ..color = VoidTheme.nebulaAmethyst
    ..style = PaintingStyle.fill;

  static final Paint _enemyFlagshipHullPaint = Paint()
    ..color = const Color(0xFF220A14)
    ..style = PaintingStyle.fill;

  static final Paint _enemyFlagshipAccentPaint = Paint()
    ..color = VoidTheme.crimsonFlare
    ..style = PaintingStyle.fill;

  static final Paint _enemyOutlinePaint = Paint()
    ..color = Colors.white.withValues(alpha: 0.85)
    ..strokeWidth = 1.4
    ..style = PaintingStyle.stroke;

  static final Paint _enemyCruiserConduitPaint = Paint()
    ..color = VoidTheme.plasmaCyan
    ..strokeWidth = 1.5
    ..style = PaintingStyle.stroke;

  static final Paint _enemyFlagshipGoldPaint = Paint()
    ..color = VoidTheme.solarGold
    ..style = PaintingStyle.fill;

  static final Paint _enemyCorePaint = Paint()
    ..color = Colors.white
    ..style = PaintingStyle.fill;

  static final Paint _enemyThrusterFlamePaint = Paint()
    ..color = VoidTheme.plasmaCyan.withValues(alpha: 0.85)
    ..style = PaintingStyle.fill;

  static final Paint _enemyThrusterCorePaint = Paint()
    ..color = Colors.white.withValues(alpha: 0.90)
    ..style = PaintingStyle.fill;

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
      textDirection: TextDirection.ltr,
    )..layout();
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
    final corridorWidth = size.width / 8.0;
    final boundaryY = size.height - 18.0;

    final forwardDepth =
        (dreadnought.orbitalPositionY - dreadnought.boundaryLineY).clamp(
          0.0,
          0.45,
        );
    final normForward = forwardDepth / 0.45;
    final maxTravelY = (boundaryY - topMargin) * 0.60;
    final baselineShipY = boundaryY - 28.0;
    final shipY = baselineShipY - (normForward * maxTravelY);
    final scale = 1.0 - normForward * 0.15;
    final shipProwY = shipY - 38.0 * scale;

    // 1. Draw Active Particle Lances (FIRED AXIALLY FROM DREADNOUGHT PROW)
    for (var i = 0; i < lances.length; i++) {
      final lance = lances[i];
      if (!lance.active) continue;
      final corridor = (lance.firingBayIndex >= 8)
          ? (lance.firingBayIndex - 8)
          : lance.firingBayIndex;
      final centerX =
          (dreadnought.orbitalPositionX >= 0.0 &&
              dreadnought.orbitalPositionX <= 1.0)
          ? dreadnought.orbitalPositionX * size.width
          : (lance.originX >= 0.0 && lance.originX <= 1.0)
          ? lance.originX * size.width
          : (corridor + 0.5) * corridorWidth;
      final rawWidth = lance.beamWidth <= 1.0
          ? (lance.beamWidth * size.width)
          : lance.beamWidth;
      final beamW = math.max(rawWidth, 12.0);

      // Volumetric 3D perspective beam cone tapering into deep space (Y = 0)
      final prowW = beamW * 1.3;
      final deepSpaceW = beamW * 0.45;
      _scratchVolumetricLancePath.reset();
      _scratchVolumetricLancePath.moveTo(centerX - prowW * 0.5, shipProwY);
      _scratchVolumetricLancePath.lineTo(centerX - deepSpaceW * 0.5, 0);
      _scratchVolumetricLancePath.lineTo(centerX + deepSpaceW * 0.5, 0);
      _scratchVolumetricLancePath.lineTo(centerX + prowW * 0.5, shipProwY);
      _scratchVolumetricLancePath.close();

      // Outer glow along volumetric cone
      canvas.drawPath(_scratchVolumetricLancePath, _lanceGlowPaint);

      // Core axial laser beam
      _lanceCorePaint.strokeWidth = math.max(beamW * 0.35, 3.5);
      canvas.drawLine(
        Offset(centerX, shipProwY),
        Offset(centerX, 0),
        _lanceCorePaint,
      );

      // Muzzle Flare at the Dreadnought Turret (Zero MaskFilter)
      canvas.drawCircle(
        Offset(centerX, shipProwY),
        beamW * 1.6,
        _muzzleGlowPaint,
      );
      canvas.drawCircle(Offset(centerX, shipProwY), beamW * 0.8, _muzzlePaint);
      canvas.drawLine(
        Offset(centerX - beamW * 2.2, shipProwY),
        Offset(centerX + beamW * 2.2, shipProwY),
        _muzzleSpikePaint,
      );

      // Impact shockwave at top
      canvas.drawCircle(Offset(centerX, 25), beamW * 1.8, _impactPaint);
    }

    // 2. Draw Active Secondary Flak Bursts
    for (var i = 0; i < flaks.length; i++) {
      final flak = flaks[i];
      if (!flak.active) continue;
      final progress =
          1.0 - (flak.remainingLifetime / math.max(flak.lifetime, 0.01));
      final rawRadius = flak.blastRadius <= 1.0
          ? (flak.blastRadius * size.width)
          : flak.blastRadius;
      final radius = rawRadius * progress;
      final alpha = (1.0 - progress).clamp(0.0, 1.0);

      _flakPaint
        ..color = VoidTheme.solarGold.withValues(alpha: alpha * 0.8)
        ..strokeWidth = 3.0 * (1.0 - progress);

      final flakX = flak.worldPosX <= 1.0
          ? flak.worldPosX * size.width
          : flak.worldPosX;
      final flakY = flak.worldPosY <= 1.0
          ? topMargin +
                ((1.0 - flak.worldPosY.clamp(0.0, 1.0)) / 0.85) *
                    (boundaryY - topMargin)
          : flak.worldPosY;

      canvas.drawCircle(Offset(flakX, flakY), radius, _flakPaint);
    }

    // 3. Draw Enemy Assault Craft
    for (var i = 0; i < enemies.length; i++) {
      final enemy = enemies[i];
      if (enemy.isDestroyed) continue;
      final x = (enemy.worldPosX > 0.0 && enemy.worldPosX <= 1.0)
          ? enemy.worldPosX * size.width
          : (enemy.assignedCorridor + 0.5) * corridorWidth;
      final double y;
      if (enemy.worldPosY <= 1.0) {
        final normY = enemy.worldPosY.clamp(0.0, 1.0);
        y = topMargin + ((1.0 - normY) / 0.85) * (boundaryY - topMargin);
      } else {
        y = enemy.worldPosY;
      }

      if (y < -50 || y > size.height) continue;
      _drawEnemyVessel(
        canvas,
        x,
        y,
        enemy,
        corridorWidth,
        topMargin,
        boundaryY,
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

    // 6. Draw Dreadnought Flagship on Defense Horizon
    _drawDreadnoughtPlatform(canvas, size, boundaryY);

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
  ///
  /// Reuses a single [bulletOffset] coordinate for all circle and line drawing
  /// operations and computes alpha blending directly via 32-bit ARGB bitwise
  /// shifts without invoking [Color.withValues].
  void _drawEnemyBullet(Canvas canvas, EnemyBullet bullet) {
    canvas.save();
    canvas.translate(bullet.x, bullet.y);

    final glowColor = Color(
      (89 << 24) | (bullet.color.toARGB32() & 0x00FFFFFF),
    );

    // 1. Zero-allocation motion tail streak pointing upward
    _bulletTailPaint
      ..color = glowColor
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset.zero, const Offset(0.0, -16.0), _bulletTailPaint);

    // 2. Outer plasma glow (Hardware-accelerated zero-blur halo)
    _bulletGlowPaint.color = glowColor;
    canvas.drawCircle(Offset.zero, bullet.radius * 1.8, _bulletGlowPaint);

    // 3. Core plasma orb
    _bulletOrbPaint.color = bullet.color;
    canvas.drawCircle(Offset.zero, bullet.radius, _bulletOrbPaint);

    // 4. White-hot center
    canvas.drawCircle(Offset.zero, bullet.radius * 0.45, _bulletCenterPaint);

    canvas.restore();
  }

  /// Renders an enemy assault craft ([enemy]) at the specified screen coordinate ([x], [y]).
  ///
  /// Applies 3D perspective scaling ([depthScale]) relative to the atmospheric
  /// defense line ([boundaryY]) and top viewport margin ([topMargin]). Selects hull
  /// geometry and colors based on [EnemyCraft.vesselType] (drone, cruiser, flagship),
  /// Renders an enemy assault craft ([enemy]) at the specified screen coordinate ([x], [y]).
  ///
  /// Restores and refines the classic 2D vector arrowhead/delta silhouette aesthetic with:
  /// - Distinct tactical hull geometries for Drones (0), Cruisers (1), and Flagships (2).
  /// - 3D perspective depth scaling ([depthScale]) from deep space (0.65x) to defense horizon (1.0x).
  /// - Smooth banking roll ([bankAngleRad]) and dive pitch ([pitchAngleRad]) transformations.
  /// - Hyperspace warp-in scaling and collapsing singularity ring FX ([warpInProgress]).
  /// - Animated engine plasma thruster plumes oriented upward against descent direction.
  /// - Real-time hull and shield energy gauge bars positioned horizontally above the vessel.
  void _drawEnemyVessel(
    Canvas canvas,
    double x,
    double y,
    EnemyCraft enemy,
    double width,
    double topMargin,
    double boundaryY,
  ) {
    final normDepth = ((y - topMargin) / math.max(boundaryY - topMargin, 1.0))
        .clamp(0.0, 1.0);
    // 3D perspective depth scaling: 0.65x in deep space -> 1.0x at defense line
    final depthScale = 0.65 + 0.35 * normDepth;
    // Balanced vessel size ratios: Drones fit agilely, Cruisers occupy lane, Flagships command
    final sizeRatio = enemy.vesselType == 2
        ? 1.6
        : (enemy.vesselType == 1 ? 1.2 : 0.8);
    final w = (width * 0.5) * sizeRatio * depthScale;
    final h = (width * 0.4) * sizeRatio * depthScale;
    final hw = w * 0.5;
    final hh = h * 0.75;

    final warpProgress = enemy.warpInProgress.clamp(0.0, 1.0);

    // 1. Draw Collapsing Warp Singularity Ring (if vessel is still warping in)
    if (warpProgress < 0.95) {
      final invProgress = (1.0 - warpProgress).clamp(0.0, 1.0);
      final ringRadius = (w * 1.1) * (0.25 + 0.75 * invProgress);
      _warpSingularityPaint
        ..color = VoidTheme.plasmaCyan.withValues(alpha: invProgress * 0.8)
        ..strokeWidth = 2.0 * depthScale;
      canvas.drawCircle(Offset(x, y), ringRadius, _warpSingularityPaint);
    }

    // 2. Transform canvas for banking, pitching, warp-scaling, and translation
    canvas.save();
    canvas.translate(x, y);

    if (enemy.bankAngleRad != 0.0) {
      canvas.rotate(enemy.bankAngleRad * 0.7);
    }

    // Warp-in scale expansion & pitch foreshortening
    final warpScale = 0.25 + 0.75 * warpProgress;
    final pitchFactor = 1.0 + enemy.pitchAngleRad * 0.25;
    if (warpScale != 1.0 || pitchFactor != 1.0) {
      canvas.scale(warpScale, warpScale * pitchFactor);
    }

    // 3. Render Hull Silhouette, Cockpit, and Thrusters by Vessel Type
    switch (enemy.vesselType) {
      case 2:
        _drawFlagshipVessel(
          canvas,
          hw,
          hh,
          depthScale,
          warpProgress,
          enemy.entityId,
        );
        break;
      case 1:
        _drawCruiserVessel(
          canvas,
          hw,
          hh,
          depthScale,
          warpProgress,
          enemy.entityId,
        );
        break;
      case 0:
      default:
        _drawDroneVessel(
          canvas,
          hw,
          hh,
          depthScale,
          warpProgress,
          enemy.entityId,
        );
        break;
    }

    canvas.restore();

    // 4. Health / Shield Gauges (rendered in screen space so they remain horizontal)
    final barW = math.max(w * 1.2, 26.0 * depthScale);
    const barH = 3.0;
    final barY = y - hh - 8.0;
    final barLeft = x - barW / 2;

    // Hull bar
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

    // Shield bar (if vessel has shields)
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

  void _drawDroneVessel(
    Canvas canvas,
    double hw,
    double hh,
    double depthScale,
    double warpProgress,
    int entityId,
  ) {
    // Aft Twin Engine Thrusters
    final flameH =
        (5.0 + 2.5 * math.sin(animationTime * 18.0 + entityId * 5.0)) *
        depthScale;
    _scratchEnemyThrusterPath.reset();
    // Port thruster
    _scratchEnemyThrusterPath.moveTo(-hw * 0.35 - 2.0 * depthScale, -hh * 0.65);
    _scratchEnemyThrusterPath.lineTo(-hw * 0.35, -hh * 0.65 - flameH);
    _scratchEnemyThrusterPath.lineTo(-hw * 0.35 + 2.0 * depthScale, -hh * 0.65);
    _scratchEnemyThrusterPath.close();
    // Starboard thruster
    _scratchEnemyThrusterPath.moveTo(hw * 0.35 - 2.0 * depthScale, -hh * 0.65);
    _scratchEnemyThrusterPath.lineTo(hw * 0.35, -hh * 0.65 - flameH);
    _scratchEnemyThrusterPath.lineTo(hw * 0.35 + 2.0 * depthScale, -hh * 0.65);
    _scratchEnemyThrusterPath.close();

    _enemyThrusterFlamePaint.color = VoidTheme.plasmaCyan.withValues(
      alpha: 0.85 * warpProgress,
    );
    canvas.drawPath(_scratchEnemyThrusterPath, _enemyThrusterFlamePaint);

    // Drone Delta Chevron Hull
    _scratchEnemyHullPath.reset();
    _scratchEnemyHullPath.moveTo(0, hh); // Sharp prow pointing towards defender
    _scratchEnemyHullPath.lineTo(hw * 0.95, -hh * 0.65);
    _scratchEnemyHullPath.lineTo(hw * 0.85, -hh);
    _scratchEnemyHullPath.lineTo(hw * 0.35, -hh * 0.65);
    _scratchEnemyHullPath.lineTo(0, -hh * 0.35);
    _scratchEnemyHullPath.lineTo(-hw * 0.35, -hh * 0.65);
    _scratchEnemyHullPath.lineTo(-hw * 0.85, -hh);
    _scratchEnemyHullPath.lineTo(-hw * 0.95, -hh * 0.65);
    _scratchEnemyHullPath.close();

    _enemyDroneHullPaint.color = const Color(
      0xFF160D2A,
    ).withValues(alpha: warpProgress);
    canvas.drawPath(_scratchEnemyHullPath, _enemyDroneHullPaint);

    // Inner Amethyst Armor Facet
    _scratchEnemyDetailPath.reset();
    _scratchEnemyDetailPath.moveTo(0, hh * 0.45);
    _scratchEnemyDetailPath.lineTo(hw * 0.40, -hh * 0.15);
    _scratchEnemyDetailPath.lineTo(0, -hh * 0.05);
    _scratchEnemyDetailPath.lineTo(-hw * 0.40, -hh * 0.15);
    _scratchEnemyDetailPath.close();

    _enemyDroneAccentPaint.color = VoidTheme.nebulaAmethyst.withValues(
      alpha: 0.85 * warpProgress,
    );
    canvas.drawPath(_scratchEnemyDetailPath, _enemyDroneAccentPaint);

    // Crisp Neon Hull Outline
    _enemyOutlinePaint.color = Colors.white.withValues(
      alpha: 0.85 * warpProgress,
    );
    canvas.drawPath(_scratchEnemyHullPath, _enemyOutlinePaint);

    // Core Sensor
    _enemyCorePaint.color = Colors.white.withValues(alpha: 0.95 * warpProgress);
    canvas.drawCircle(Offset(0, -hh * 0.05), 2.0 * depthScale, _enemyCorePaint);
  }

  void _drawCruiserVessel(
    Canvas canvas,
    double hw,
    double hh,
    double depthScale,
    double warpProgress,
    int entityId,
  ) {
    // Twin Heavy Engine Thrusters
    final flameH =
        (7.0 + 3.5 * math.sin(animationTime * 16.0 + entityId * 4.0)) *
        depthScale;
    _scratchEnemyThrusterPath.reset();
    // Port engine nacelle flame
    _scratchEnemyThrusterPath.moveTo(-hw * 0.75 - 3.0 * depthScale, -hh);
    _scratchEnemyThrusterPath.lineTo(-hw * 0.75, -hh - flameH);
    _scratchEnemyThrusterPath.lineTo(-hw * 0.75 + 3.0 * depthScale, -hh);
    _scratchEnemyThrusterPath.close();
    // Starboard engine nacelle flame
    _scratchEnemyThrusterPath.moveTo(hw * 0.75 - 3.0 * depthScale, -hh);
    _scratchEnemyThrusterPath.lineTo(hw * 0.75, -hh - flameH);
    _scratchEnemyThrusterPath.lineTo(hw * 0.75 + 3.0 * depthScale, -hh);
    _scratchEnemyThrusterPath.close();

    _enemyThrusterFlamePaint.color = VoidTheme.plasmaCyan.withValues(
      alpha: 0.85 * warpProgress,
    );
    canvas.drawPath(_scratchEnemyThrusterPath, _enemyThrusterFlamePaint);

    // Heavy Cruiser Stepped Chassis
    _scratchEnemyHullPath.reset();
    _scratchEnemyHullPath.moveTo(0, hh * 1.0); // Central plasma rail prow
    _scratchEnemyHullPath.lineTo(hw * 0.20, hh * 0.55); // Inner mandible notch
    _scratchEnemyHullPath.lineTo(
      hw * 0.45,
      hh * 0.85,
    ); // Starboard assault mandible
    _scratchEnemyHullPath.lineTo(hw * 0.55, hh * 0.15); // Waist armor
    _scratchEnemyHullPath.lineTo(
      hw * 1.0,
      -hh * 0.40,
    ); // Broad delta wing shoulder
    _scratchEnemyHullPath.lineTo(hw * 0.75, -hh); // Starboard engine nacelle
    _scratchEnemyHullPath.lineTo(hw * 0.30, -hh * 0.60); // Inner exhaust bay
    _scratchEnemyHullPath.lineTo(0, -hh * 0.35); // Keel notch
    _scratchEnemyHullPath.lineTo(-hw * 0.30, -hh * 0.60);
    _scratchEnemyHullPath.lineTo(-hw * 0.75, -hh);
    _scratchEnemyHullPath.lineTo(-hw * 1.0, -hh * 0.40);
    _scratchEnemyHullPath.lineTo(-hw * 0.55, hh * 0.15);
    _scratchEnemyHullPath.lineTo(-hw * 0.45, hh * 0.85);
    _scratchEnemyHullPath.lineTo(-hw * 0.20, hh * 0.55);
    _scratchEnemyHullPath.close();

    _enemyCruiserHullPaint.color = const Color(
      0xFF0C1026,
    ).withValues(alpha: warpProgress);
    canvas.drawPath(_scratchEnemyHullPath, _enemyCruiserHullPaint);

    // Primary Nebula Amethyst Armor Plating
    _scratchEnemyDetailPath.reset();
    _scratchEnemyDetailPath.moveTo(0, hh * 0.40);
    _scratchEnemyDetailPath.lineTo(hw * 0.45, -hh * 0.15);
    _scratchEnemyDetailPath.lineTo(0, -hh * 0.10);
    _scratchEnemyDetailPath.lineTo(-hw * 0.45, -hh * 0.15);
    _scratchEnemyDetailPath.close();

    _enemyCruiserAccentPaint.color = VoidTheme.nebulaAmethyst.withValues(
      alpha: 0.90 * warpProgress,
    );
    canvas.drawPath(_scratchEnemyDetailPath, _enemyCruiserAccentPaint);

    // Glowing Plasma Conduits along Mandibles
    _scratchEnemyDetailPath.reset();
    _scratchEnemyDetailPath.moveTo(hw * 0.42, hh * 0.80);
    _scratchEnemyDetailPath.lineTo(hw * 0.25, hh * 0.20);
    _scratchEnemyDetailPath.lineTo(0, 0);
    _scratchEnemyDetailPath.moveTo(-hw * 0.42, hh * 0.80);
    _scratchEnemyDetailPath.lineTo(-hw * 0.25, hh * 0.20);
    _scratchEnemyDetailPath.lineTo(0, 0);

    _enemyCruiserConduitPaint.color = VoidTheme.plasmaCyan.withValues(
      alpha: 0.90 * warpProgress,
    );
    canvas.drawPath(_scratchEnemyDetailPath, _enemyCruiserConduitPaint);

    // Outer Neon Outline
    _enemyOutlinePaint.color = Colors.white.withValues(
      alpha: 0.85 * warpProgress,
    );
    canvas.drawPath(_scratchEnemyHullPath, _enemyOutlinePaint);

    // Central Reactor Singularity Core
    _enemyCorePaint.color = VoidTheme.plasmaCyanLight.withValues(
      alpha: 0.95 * warpProgress,
    );
    canvas.drawCircle(Offset.zero, 3.0 * depthScale, _enemyCorePaint);
    _enemyCorePaint.color = Colors.white.withValues(alpha: 0.95 * warpProgress);
    canvas.drawCircle(Offset.zero, 1.5 * depthScale, _enemyCorePaint);
  }

  void _drawFlagshipVessel(
    Canvas canvas,
    double hw,
    double hh,
    double depthScale,
    double warpProgress,
    int entityId,
  ) {
    // Massive Crimson Thruster Plumes
    final flameH =
        (10.0 + 5.0 * math.sin(animationTime * 14.0 + entityId * 3.0)) *
        depthScale;
    _scratchEnemyThrusterPath.reset();
    // Port heavy engine block flame
    _scratchEnemyThrusterPath.moveTo(-hw * 0.52 - 4.0 * depthScale, -hh);
    _scratchEnemyThrusterPath.lineTo(-hw * 0.52, -hh - flameH);
    _scratchEnemyThrusterPath.lineTo(-hw * 0.52 + 4.0 * depthScale, -hh);
    _scratchEnemyThrusterPath.close();
    // Starboard heavy engine block flame
    _scratchEnemyThrusterPath.moveTo(hw * 0.52 - 4.0 * depthScale, -hh);
    _scratchEnemyThrusterPath.lineTo(hw * 0.52, -hh - flameH);
    _scratchEnemyThrusterPath.lineTo(hw * 0.52 + 4.0 * depthScale, -hh);
    _scratchEnemyThrusterPath.close();

    _enemyThrusterFlamePaint.color = VoidTheme.crimsonFlare.withValues(
      alpha: 0.85 * warpProgress,
    );
    canvas.drawPath(_scratchEnemyThrusterPath, _enemyThrusterFlamePaint);

    // Inner Flame Core
    if (!isLowBattery) {
      _scratchEnemyThrusterPath.reset();
      _scratchEnemyThrusterPath.moveTo(-hw * 0.52 - 2.0 * depthScale, -hh);
      _scratchEnemyThrusterPath.lineTo(-hw * 0.52, -hh - flameH * 0.55);
      _scratchEnemyThrusterPath.lineTo(-hw * 0.52 + 2.0 * depthScale, -hh);
      _scratchEnemyThrusterPath.close();
      _scratchEnemyThrusterPath.moveTo(hw * 0.52 - 2.0 * depthScale, -hh);
      _scratchEnemyThrusterPath.lineTo(hw * 0.52, -hh - flameH * 0.55);
      _scratchEnemyThrusterPath.lineTo(hw * 0.52 + 2.0 * depthScale, -hh);
      _scratchEnemyThrusterPath.close();

      _enemyThrusterCorePaint.color = VoidTheme.solarGoldLight.withValues(
        alpha: 0.90 * warpProgress,
      );
      canvas.drawPath(_scratchEnemyThrusterPath, _enemyThrusterCorePaint);
    }

    // Flagship Command Dreadnought Hull
    _scratchEnemyHullPath.reset();
    _scratchEnemyHullPath.moveTo(0, hh * 1.05); // Armored beak prow
    _scratchEnemyHullPath.lineTo(hw * 0.28, hh * 0.72); // Prow armor plate
    _scratchEnemyHullPath.lineTo(
      hw * 0.55,
      hh * 0.35,
    ); // Forward weapon sponson
    _scratchEnemyHullPath.lineTo(
      hw * 1.05,
      -hh * 0.25,
    ); // Heavy swept weapon wing
    _scratchEnemyHullPath.lineTo(hw * 0.88, -hh * 0.85); // Wing armor fin
    _scratchEnemyHullPath.lineTo(
      hw * 0.52,
      -hh,
    ); // Starboard heavy reactor block
    _scratchEnemyHullPath.lineTo(hw * 0.22, -hh * 0.65); // Exhaust notch
    _scratchEnemyHullPath.lineTo(0, -hh * 0.45); // Keel spine
    _scratchEnemyHullPath.lineTo(-hw * 0.22, -hh * 0.65);
    _scratchEnemyHullPath.lineTo(-hw * 0.52, -hh);
    _scratchEnemyHullPath.lineTo(-hw * 0.88, -hh * 0.85);
    _scratchEnemyHullPath.lineTo(-hw * 1.05, -hh * 0.25);
    _scratchEnemyHullPath.lineTo(-hw * 0.55, hh * 0.35);
    _scratchEnemyHullPath.lineTo(-hw * 0.28, hh * 0.72);
    _scratchEnemyHullPath.close();

    _enemyFlagshipHullPaint.color = const Color(
      0xFF220A14,
    ).withValues(alpha: warpProgress);
    canvas.drawPath(_scratchEnemyHullPath, _enemyFlagshipHullPaint);

    // Crimson Flare Heavy Armor Wings
    _scratchEnemyDetailPath.reset();
    _scratchEnemyDetailPath.moveTo(0, hh * 0.60);
    _scratchEnemyDetailPath.lineTo(hw * 0.65, -hh * 0.10);
    _scratchEnemyDetailPath.lineTo(hw * 0.45, -hh * 0.40);
    _scratchEnemyDetailPath.lineTo(0, -hh * 0.20);
    _scratchEnemyDetailPath.lineTo(-hw * 0.45, -hh * 0.40);
    _scratchEnemyDetailPath.lineTo(-hw * 0.65, -hh * 0.10);
    _scratchEnemyDetailPath.close();

    _enemyFlagshipAccentPaint.color = VoidTheme.crimsonFlare.withValues(
      alpha: 0.90 * warpProgress,
    );
    canvas.drawPath(_scratchEnemyDetailPath, _enemyFlagshipAccentPaint);

    // Solar Gold Command Bridge Citadel
    _scratchEnemyDetailPath.reset();
    _scratchEnemyDetailPath.moveTo(0, hh * 0.25);
    _scratchEnemyDetailPath.lineTo(hw * 0.28, -hh * 0.05);
    _scratchEnemyDetailPath.lineTo(0, -hh * 0.28);
    _scratchEnemyDetailPath.lineTo(-hw * 0.28, -hh * 0.05);
    _scratchEnemyDetailPath.close();

    _enemyFlagshipGoldPaint.color = VoidTheme.solarGold.withValues(
      alpha: 0.95 * warpProgress,
    );
    canvas.drawPath(_scratchEnemyDetailPath, _enemyFlagshipGoldPaint);

    // Hull Outline
    _enemyOutlinePaint.color = Colors.white.withValues(
      alpha: 0.85 * warpProgress,
    );
    canvas.drawPath(_scratchEnemyHullPath, _enemyOutlinePaint);

    // Central Singularity Power Core
    _enemyCorePaint.color = VoidTheme.crimsonFlare.withValues(
      alpha: 0.95 * warpProgress,
    );
    canvas.drawCircle(Offset(0, -hh * 0.05), 3.5 * depthScale, _enemyCorePaint);
    _enemyCorePaint.color = Colors.white.withValues(alpha: 0.95 * warpProgress);
    canvas.drawCircle(Offset(0, -hh * 0.05), 1.8 * depthScale, _enemyCorePaint);
  }

  /// Renders the flagship dreadnought defense platform, HUD telemetry, and targeting reticles.
  ///
  /// Projects the dreadnought hull mesh along with:
  /// - Energized active corridor highlight guide lines beneath the flagship.
  /// - Dynamic aim laser beam projected axially from ship prow towards space.
  /// - Holographic corner-bracket lock-on reticles and cached damage tags on active targets.
  /// - 3D polygonal mesh transformation and twin engine plasma thrust plumes.
  /// - Deep space bow shock ripple and forward kinetic canopy shield arcs.
  /// - Tactical spatial elevation rail with altitude sector ticks and elevation marker.
  void _drawDreadnoughtPlatform(Canvas canvas, Size size, double boundaryY) {
    final topMargin = size.height * 0.06;
    final dreadNormX =
        (dreadnought.orbitalPositionX > 0.0 &&
            dreadnought.orbitalPositionX <= 1.0)
        ? dreadnought.orbitalPositionX
        : 0.4375;
    final centerX = dreadNormX * size.width;

    final forwardDepth =
        (dreadnought.orbitalPositionY - dreadnought.boundaryLineY).clamp(
          0.0,
          0.45,
        );
    final normForward = forwardDepth / 0.45;
    final maxTravelY = (boundaryY - topMargin) * 0.60;
    final baselineShipY = boundaryY - 28.0;
    final shipY = baselineShipY - (normForward * maxTravelY);
    final scale = 1.0 - normForward * 0.15;
    final prowY = shipY - 38.0 * scale;

    // Active corridor highlight under dreadnought (Energized Runway Track)
    final activeCorridor = (centerX / (size.width / 8.0)).floor().clamp(0, 7);
    final corridorWidth = size.width / 8.0;
    final corridorLeft = activeCorridor * corridorWidth;
    final corridorRight = corridorLeft + corridorWidth;

    _highlightPaint.color = VoidTheme.plasmaCyan.withValues(alpha: 0.12);
    canvas.drawRect(
      Rect.fromLTWH(corridorLeft, 0, corridorWidth, size.height),
      _highlightPaint,
    );

    // Active corridor energetic boundary guide lines
    _corridorBorderPaint.color = VoidTheme.plasmaCyan.withValues(alpha: 0.28);
    canvas.drawLine(
      Offset(corridorLeft, 0),
      Offset(corridorLeft, size.height),
      _corridorBorderPaint,
    );
    canvas.drawLine(
      Offset(corridorRight, 0),
      Offset(corridorRight, size.height),
      _corridorBorderPaint,
    );

    // Targeting Alignment Laser Beam (Pulsing dual-core beam aligned with ship prow in 2D space)
    final aimPulse = 0.40 + 0.25 * math.sin(animationTime * 10.0);
    _aimGlowPaint.color = VoidTheme.plasmaCyan.withValues(
      alpha: aimPulse * 0.45,
    );
    canvas.drawLine(Offset(centerX, prowY), Offset(centerX, 0), _aimGlowPaint);

    _aimPaint.color = Colors.white.withValues(alpha: aimPulse * 0.90);
    _aimPaint.strokeWidth = 1.8;
    canvas.drawLine(Offset(centerX, prowY), Offset(centerX, 0), _aimPaint);

    // Holographic corner-bracket lock-on reticles on descending enemies in active corridor
    for (var i = 0; i < enemies.length; i++) {
      final enemy = enemies[i];
      if (!enemy.isDestroyed && enemy.assignedCorridor == activeCorridor) {
        final enemyX = (enemy.worldPosX > 0.0 && enemy.worldPosX <= 1.0)
            ? enemy.worldPosX * size.width
            : (enemy.assignedCorridor + 0.5) * corridorWidth;
        final double ey = (enemy.worldPosY <= 1.0)
            ? topMargin +
                  ((1.0 - enemy.worldPosY.clamp(0.0, 1.0)) / 0.85) *
                      (boundaryY - topMargin)
            : enemy.worldPosY;
        final lockSize = 16.0 + 2.0 * math.sin(animationTime * 8.0);
        final cornerLen = lockSize * 0.45;

        _scratchReticlePath.reset();
        // Top-left corner
        _scratchReticlePath.moveTo(
          enemyX - lockSize + cornerLen,
          ey - lockSize,
        );
        _scratchReticlePath.lineTo(enemyX - lockSize, ey - lockSize);
        _scratchReticlePath.lineTo(
          enemyX - lockSize,
          ey - lockSize + cornerLen,
        );
        // Top-right corner
        _scratchReticlePath.moveTo(
          enemyX + lockSize - cornerLen,
          ey - lockSize,
        );
        _scratchReticlePath.lineTo(enemyX + lockSize, ey - lockSize);
        _scratchReticlePath.lineTo(
          enemyX + lockSize,
          ey - lockSize + cornerLen,
        );
        // Bottom-left corner
        _scratchReticlePath.moveTo(
          enemyX - lockSize + cornerLen,
          ey + lockSize,
        );
        _scratchReticlePath.lineTo(enemyX - lockSize, ey + lockSize);
        _scratchReticlePath.lineTo(
          enemyX - lockSize,
          ey + lockSize - cornerLen,
        );
        // Bottom-right corner
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

        // Center crosshair pips
        _scratchReticlePath.reset();
        _scratchReticlePath.moveTo(enemyX - 3.5, ey);
        _scratchReticlePath.lineTo(enemyX + 3.5, ey);
        _scratchReticlePath.moveTo(enemyX, ey - 3.5);
        _scratchReticlePath.lineTo(enemyX, ey + 3.5);
        canvas.drawPath(_scratchReticlePath, _lockCrosshairPaint);

        // Clean Damage Preview Tag (⚡ 16x DMG)
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

    // 3D Spatial Attitude Angles & Perspective Depth Scale
    final lateralDisplacement =
        (dreadnought.targetPositionX - dreadnought.orbitalPositionX).clamp(
          -0.25,
          0.25,
        );
    final rollRad = lateralDisplacement * 24.0 * (math.pi / 180.0);
    // 3D Pitch: Warship visibly pitches nose-down into space (-15 deg) under forward thrust
    final pitchRad = -normForward * 0.26;
    // 3D Yaw: Slight turning heading into lateral slide
    final yawRad = lateralDisplacement * 0.14;

    // Ground projection anchor ring and vertical depth tether on baseline plane
    if (normForward > 0.04) {
      final anchorW = 44.0 * (1.0 - normForward * 0.25) * scale;
      final anchorH = 12.0 * (1.0 - normForward * 0.25) * scale;
      final anchorRect = Rect.fromLTWH(
        centerX - anchorW * 0.5,
        baselineShipY - anchorH * 0.5,
        anchorW,
        anchorH,
      );
      canvas.drawOval(anchorRect, _anchorRingPaint);

      final tetherAlpha = (0.15 + 0.35 * normForward).clamp(0.0, 0.5);
      _anchorTetherPaint.color = VoidTheme.plasmaCyan.withValues(
        alpha: tetherAlpha,
      );
      canvas.drawLine(
        Offset(centerX, baselineShipY),
        Offset(centerX, shipY + 18.0 * scale),
        _anchorTetherPaint,
      );
    }

    // 1. Render true 3D Polygonal Dreadnought Flagship Mesh
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

    // 2. 3D Aligned Twin Plasma Engine Exhaust Flames
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

    // 3. Trailing Ion Contrails during deep space forward flight
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

    // 4. Deep Space Energetic Bow Shock Ripple Ahead of 3D Prow
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

    // 5. Forward Kinetic Energy Canopy Shield Arc
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

    // Upward Flight Discovery Hint (Zero-Allocation Pre-Laid Out Opacity Lookup Table)
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

    // Defender Conduit Label (Zero-Allocation Pre-Laid Out Painter)
    // Only displayed when cruising in deep space to avoid cluttering docked orbit
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
    final railBottom = boundaryY - 4.0;
    final railTop = railBottom - maxTravelY;
    const railX = 14.0;

    // Background rail guide line
    canvas.drawLine(
      Offset(railX, railTop - 6.0),
      Offset(railX, railBottom + 6.0),
      _altimeterRailPaint,
    );

    // Altitude sector tick elevations
    final yOrbit = railBottom;
    final yStrato = railBottom - maxTravelY * 0.35;
    final yDeep = railBottom - maxTravelY * 0.70;
    final yVanguard = railTop;

    // Tick marks
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

    // Sector Labels
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

    // Current elevation marker chevron (Directly tracks ship's vertical coordinate)
    final markerY = shipY;
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
