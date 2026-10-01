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

/// Retained Skia static background layer rendering the 8 tactical corridors,
/// atmospheric defense boundary line, and planetary defense rails.
///
/// Wrapped in a [RepaintBoundary] so Flutter rasterizes this geometry to an offscreen
/// GPU surface once, consuming zero raster cycles on subsequent dynamic frame ticks.
class CombatBackgroundPainter extends CustomPainter {
  const CombatBackgroundPainter();

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

  @override
  void paint(Canvas canvas, Size size) {
    final corridorWidth = size.width / 8.0;

    // 1. Draw 8 Tactical Combat Corridors (Dashed Futuristic Guides)
    for (var i = 1; i < 8; i++) {
      final x = i * corridorWidth;
      var y = 0.0;
      while (y < size.height) {
        canvas.drawLine(
          Offset(x, y),
          Offset(x, math.min(y + 4.0, size.height)),
          _corridorPaint,
        );
        y += 8.0;
      }
    }

    // 2. Draw Atmospheric Defense Boundary Line & Futuristic Label
    final boundaryY = size.height - 48.0;
    canvas.drawLine(
      Offset(0, boundaryY),
      Offset(size.width, boundaryY),
      _boundaryPaint,
    );

    final thresholdPainter = TextPainter(
      text: TextSpan(
        text: 'ATMOSPHERIC THRESHOLD',
        style: TextStyle(
          color: VoidTheme.crimsonFlare.withValues(alpha: 0.85),
          fontSize: 7.5,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.2,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    thresholdPainter.paint(canvas, Offset(14.0, boundaryY - 12.0));

    // 3. Draw Planetary Defense Horizon Line
    canvas.drawLine(
      Offset(0, boundaryY + 22),
      Offset(size.width, boundaryY + 22),
      _railPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CombatBackgroundPainter oldDelegate) => false;
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

  // ---------------------------------------------------------------------------
  // Reusable Path Scratchpads & Pre-compiled Static Geometry
  // ---------------------------------------------------------------------------
  static final Path _scratchEnemyHullPath = Path();
  static final Path _scratchLeftFlamePath = Path();
  static final Path _scratchRightFlamePath = Path();

  static final Path _staticDreadHullPath = Path()
    ..moveTo(0, -23.0) // Nose pointing UP
    ..lineTo(18.0, -7.0)
    ..lineTo(52.0, 11.0) // Starboard wingtip
    ..lineTo(32.0, 19.0) // Starboard mount
    ..lineTo(15.0, 12.0)
    ..lineTo(-15.0, 12.0)
    ..lineTo(-32.0, 19.0) // Port mount
    ..lineTo(-52.0, 11.0) // Port wingtip
    ..lineTo(-18.0, -7.0)
    ..close();

  static final Path _staticProwChevronPath = Path()
    ..moveTo(0, -36.0)
    ..lineTo(8.0, -28.0)
    ..lineTo(0, -30.0)
    ..lineTo(-8.0, -28.0)
    ..close();

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

  static final Paint _enemyDroneHullPaint = Paint()
    ..color = VoidTheme.nebulaAmethyst
    ..style = PaintingStyle.fill;

  static final Paint _enemyCruiserHullPaint = Paint()
    ..color = VoidTheme.nebulaAmethyst
    ..style = PaintingStyle.fill;

  static final Paint _enemyFlagshipHullPaint = Paint()
    ..color = VoidTheme.crimsonFlare
    ..style = PaintingStyle.fill;

  static final Paint _enemyOutlinePaint = Paint()
    ..color = Colors.white.withValues(alpha: 0.8)
    ..strokeWidth = 1.5
    ..style = PaintingStyle.stroke;

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

  static final Paint _dreadFillPaint = Paint()
    ..color = VoidTheme.obsidianBlack
    ..style = PaintingStyle.fill;

  static final Shader _staticDreadArmorShader = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      VoidTheme.solarGold.withValues(alpha: 0.9),
      VoidTheme.cardSurface,
      VoidTheme.obsidianBlack,
    ],
  ).createShader(const Rect.fromLTWH(-52.0, -23.0, 104.0, 48.0));

  static final Paint _dreadArmorPaint = Paint()
    ..style = PaintingStyle.fill
    ..shader = _staticDreadArmorShader;

  static final Paint _dreadOutlinePaint = Paint()
    ..color = VoidTheme.plasmaCyan
    ..strokeWidth = 1.8
    ..style = PaintingStyle.stroke;

  static final Paint _turretPaint = Paint()
    ..color = Colors.white
    ..strokeWidth = 2.2
    ..strokeCap = StrokeCap.round;

  static final Paint _coreGlowPaint = Paint()
    ..color = VoidTheme.plasmaCyan.withValues(alpha: 0.35)
    ..style = PaintingStyle.fill;

  static final Paint _coreCenterPaint = Paint()
    ..color = Colors.white
    ..style = PaintingStyle.fill;

  static final Paint _shieldArcPaint = Paint()
    ..color = VoidTheme.plasmaCyan
    ..strokeWidth = 2.4
    ..style = PaintingStyle.stroke;

  static final Paint _shieldGlowPaint = Paint()
    ..color = VoidTheme.plasmaCyan.withValues(alpha: 0.35)
    ..strokeWidth = 5.0
    ..style = PaintingStyle.stroke;

  static final Paint _portNavPaint = Paint()..style = PaintingStyle.fill;
  static final Paint _starboardNavPaint = Paint()..style = PaintingStyle.fill;
  static final Paint _prowChevronPaint = Paint()..style = PaintingStyle.fill;
  static final Paint _coreOuterGlowPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.5
    ..color = VoidTheme.solarGold.withValues(alpha: 0.6);

  // ---------------------------------------------------------------------------
  // Pre-computed Text Layout Pool (8 Tactical Conduits C1..C8)
  // ---------------------------------------------------------------------------
  static final List<TextPainter> _conduitLabelPainters = List.generate(8, (i) {
    final painter = TextPainter(
      text: TextSpan(
        text: 'DEFENDER CONDUIT [C${i + 1}]',
        style: const TextStyle(
          color: VoidTheme.solarGold,
          fontSize: 9.0,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.0,
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

  static final TextPainter _damageTagTextPainter = TextPainter(
    textDirection: TextDirection.ltr,
  );

  static final TextPainter _proximityTagTextPainter = TextPainter(
    textDirection: TextDirection.ltr,
  );

  // ---------------------------------------------------------------------------
  // 3D Space Motion & Kinetic Cues Static Paints
  // ---------------------------------------------------------------------------
  static final Paint _bowShockPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.2;

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
      text: 'ORBIT',
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
      text: 'STRATO',
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
      text: 'DEEP SPACE',
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
      text: 'VANGUARD +60%',
      style: TextStyle(
        color: VoidTheme.solarGold,
        fontSize: 6.5,
        fontWeight: FontWeight.w900,
        letterSpacing: 0.5,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();

  static final TextPainter _flightHintPainter = TextPainter(
    text: const TextSpan(
      text: '▲ DRAG UP FOR DEEP SPACE ▲',
      style: TextStyle(
        color: VoidTheme.plasmaCyan,
        fontSize: 8.5,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.0,
        shadows: [
          Shadow(color: Colors.black, blurRadius: 4.0),
          Shadow(color: VoidTheme.plasmaCyan, blurRadius: 8.0),
        ],
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();

  @override
  void paint(Canvas canvas, Size size) {
    final topMargin = size.height * 0.06;
    final corridorWidth = size.width / 8.0;
    final boundaryY = size.height - 48.0;

    final forwardDepth =
        (dreadnought.orbitalPositionY - dreadnought.boundaryLineY).clamp(
          0.0,
          0.45,
        );
    final normForward = forwardDepth / 0.45;
    final maxTravelY = (boundaryY - topMargin) * 0.60;
    final shipY = (boundaryY + 12.0) - (normForward * maxTravelY);
    final shipProwY = shipY - 28.0;

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

      // Lance outer glow (Zero-allocation static shader with hardware canvas transform)
      canvas.save();
      canvas.translate(centerX, 0);
      canvas.scale(beamW * 1.5, shipProwY);
      canvas.drawRect(const Rect.fromLTWH(-1.0, 0, 2.0, 1.0), _lanceGlowPaint);
      canvas.restore();

      // Core axial laser beam
      _lanceCorePaint.strokeWidth = math.max(beamW * 0.4, 4.0);
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
      _drawEnemyVessel(canvas, x, y, enemy, corridorWidth);
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

  void _drawEnemyBullet(Canvas canvas, EnemyBullet bullet) {
    // 1. Zero-allocation motion tail streak pointing upward
    _bulletTailPaint
      ..color = bullet.color.withValues(alpha: 0.35)
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(bullet.x, bullet.y),
      Offset(bullet.x, bullet.y - 16.0),
      _bulletTailPaint,
    );

    // 2. Outer plasma glow (Hardware-accelerated zero-blur halo)
    _bulletGlowPaint.color = bullet.color.withValues(alpha: 0.35);
    canvas.drawCircle(
      Offset(bullet.x, bullet.y),
      bullet.radius * 1.8,
      _bulletGlowPaint,
    );

    // 3. Core plasma orb
    _bulletOrbPaint.color = bullet.color;
    canvas.drawCircle(
      Offset(bullet.x, bullet.y),
      bullet.radius,
      _bulletOrbPaint,
    );

    // 4. White-hot center
    canvas.drawCircle(
      Offset(bullet.x, bullet.y),
      bullet.radius * 0.45,
      _bulletCenterPaint,
    );
  }

  void _drawEnemyVessel(
    Canvas canvas,
    double x,
    double y,
    EnemyCraft enemy,
    double width,
  ) {
    final sizeRatio = enemy.vesselType == 2
        ? 1.6
        : (enemy.vesselType == 1 ? 1.2 : 0.8);
    final w = (width * 0.5) * sizeRatio;
    final h = (width * 0.4) * sizeRatio;

    _scratchEnemyHullPath.reset();
    _scratchEnemyHullPath.moveTo(x, y + h); // Nose pointing downward
    _scratchEnemyHullPath.lineTo(x - w / 2, y - h / 2);
    _scratchEnemyHullPath.lineTo(x, y - h / 4);
    _scratchEnemyHullPath.lineTo(x + w / 2, y - h / 2);
    _scratchEnemyHullPath.close();

    // Hull fill
    final hullPaint = enemy.vesselType == 2
        ? _enemyFlagshipHullPaint
        : (enemy.vesselType == 1
              ? _enemyCruiserHullPaint
              : _enemyDroneHullPaint);
    canvas.drawPath(_scratchEnemyHullPath, hullPaint);

    // Hull outline
    canvas.drawPath(_scratchEnemyHullPath, _enemyOutlinePaint);

    // Health / Shield Gauges
    final barW = w * 1.2;
    const barH = 3.0;
    final barY = y - h / 2 - 8.0;

    // Hull bar
    final hullFraction = (enemy.currentHull / math.max(enemy.maxHull, 1.0))
        .clamp(0.0, 1.0);
    canvas.drawRect(
      Rect.fromLTWH(x - barW / 2, barY, barW, barH),
      _healthBgPaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(x - barW / 2, barY, barW * hullFraction, barH),
      _healthHullPaint,
    );

    // Shield bar (if vessel has shields)
    if (enemy.maxShields > 0) {
      final shieldFraction = (enemy.currentShields / enemy.maxShields).clamp(
        0.0,
        1.0,
      );
      canvas.drawRect(
        Rect.fromLTWH(x - barW / 2, barY - 4.0, barW * shieldFraction, barH),
        _healthShieldPaint,
      );
    }
  }

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
    final shipY = (boundaryY + 12.0) - (normForward * maxTravelY);
    final prowY = shipY - 28.0;

    // Active corridor highlight under dreadnought (Energized Runway Track)
    final activeCorridor = (centerX / (size.width / 8.0)).floor().clamp(0, 7);
    final corridorWidth = size.width / 8.0;
    final corridorLeft = activeCorridor * corridorWidth;
    final corridorRight = corridorLeft + corridorWidth;

    _highlightPaint.color = VoidTheme.plasmaCyan.withValues(alpha: 0.12);
    canvas.drawRect(
      Rect.fromLTWH(corridorLeft, 0, corridorWidth, boundaryY),
      _highlightPaint,
    );

    // Active corridor energetic boundary guide lines
    _corridorBorderPaint.color = VoidTheme.plasmaCyan.withValues(alpha: 0.28);
    canvas.drawLine(
      Offset(corridorLeft, 0),
      Offset(corridorLeft, boundaryY),
      _corridorBorderPaint,
    );
    canvas.drawLine(
      Offset(corridorRight, 0),
      Offset(corridorRight, boundaryY),
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

        // 4 High-tech Corner Brackets
        // Top-left
        canvas.drawLine(
          Offset(enemyX - lockSize, ey - lockSize),
          Offset(enemyX - lockSize + cornerLen, ey - lockSize),
          _lockPaint,
        );
        canvas.drawLine(
          Offset(enemyX - lockSize, ey - lockSize),
          Offset(enemyX - lockSize, ey - lockSize + cornerLen),
          _lockPaint,
        );
        // Top-right
        canvas.drawLine(
          Offset(enemyX + lockSize, ey - lockSize),
          Offset(enemyX + lockSize - cornerLen, ey - lockSize),
          _lockPaint,
        );
        canvas.drawLine(
          Offset(enemyX + lockSize, ey - lockSize),
          Offset(enemyX + lockSize, ey - lockSize + cornerLen),
          _lockPaint,
        );
        // Bottom-left
        canvas.drawLine(
          Offset(enemyX - lockSize, ey + lockSize),
          Offset(enemyX - lockSize + cornerLen, ey + lockSize),
          _lockPaint,
        );
        canvas.drawLine(
          Offset(enemyX - lockSize, ey + lockSize),
          Offset(enemyX - lockSize, ey + lockSize - cornerLen),
          _lockPaint,
        );
        // Bottom-right
        canvas.drawLine(
          Offset(enemyX + lockSize, ey + lockSize),
          Offset(enemyX + lockSize - cornerLen, ey + lockSize),
          _lockPaint,
        );
        canvas.drawLine(
          Offset(enemyX + lockSize, ey + lockSize),
          Offset(enemyX + lockSize, ey + lockSize - cornerLen),
          _lockPaint,
        );

        // Center crosshair pips
        canvas.drawLine(
          Offset(enemyX - 3.5, ey),
          Offset(enemyX + 3.5, ey),
          _lockCrosshairPaint,
        );
        canvas.drawLine(
          Offset(enemyX, ey - 3.5),
          Offset(enemyX, ey + 3.5),
          _lockCrosshairPaint,
        );

        // Clean Damage Preview Tag (⚡ 16x DMG)
        final dmgValue = (predictedDamage != null && predictedDamage! > 0)
            ? predictedDamage!.toInt()
            : 16;
        final tagText = '⚡ ${dmgValue}x DMG';
        _damageTagTextPainter.text = TextSpan(
          text: tagText,
          style: const TextStyle(
            color: VoidTheme.plasmaCyan,
            fontSize: 9.5,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        );
        _damageTagTextPainter.layout();

        final tagWidth = _damageTagTextPainter.width + 10.0;
        const tagHeight = 18.0;
        final tagX = (enemyX + lockSize + 4.0 + tagWidth > size.width)
            ? enemyX - lockSize - 4.0 - tagWidth
            : enemyX + lockSize + 4.0;
        final tagY = ey - tagHeight / 2.0;

        final tagRRect = RRect.fromRectAndRadius(
          Rect.fromLTWH(tagX, tagY, tagWidth, tagHeight),
          const Radius.circular(4.0),
        );
        canvas.drawRRect(tagRRect, _damageTagBgPaint);
        canvas.drawRRect(tagRRect, _damageTagBorderPaint);

        _damageTagTextPainter.paint(
          canvas,
          Offset(
            tagX + 5.0,
            tagY + (tagHeight - _damageTagTextPainter.height) / 2.0,
          ),
        );
      }
    }

    // 3D Banking and Perspective Foreshortening
    final lateralDisplacement =
        (dreadnought.targetPositionX - dreadnought.orbitalPositionX).clamp(
          -0.25,
          0.25,
        );
    final bankAngleRad = lateralDisplacement * 24.0 * (math.pi / 180.0);
    final bankForeshortening = 1.0 - bankAngleRad.abs() * 0.12;

    // Animated Twin Plasma Thrusters (Enlarged and elongated during deep-space forward thrust)
    final thrustScale = 1.0 + 1.2 * normForward;
    final flameHeight =
        (22.0 + math.sin(animationTime * 20.0) * 6.0) * thrustScale;
    final leftThrusterX = centerX - 24.0;
    final rightThrusterX = centerX + 24.0;
    final thrusterY = shipY + 16.0;

    _scratchLeftFlamePath.reset();
    _scratchLeftFlamePath.moveTo(leftThrusterX - 6.0, thrusterY);
    _scratchLeftFlamePath.lineTo(leftThrusterX, thrusterY + flameHeight);
    _scratchLeftFlamePath.lineTo(leftThrusterX + 6.0, thrusterY);
    _scratchLeftFlamePath.close();
    canvas.drawPath(_scratchLeftFlamePath, _flamePaint);

    _scratchRightFlamePath.reset();
    _scratchRightFlamePath.moveTo(rightThrusterX - 6.0, thrusterY);
    _scratchRightFlamePath.lineTo(rightThrusterX, thrusterY + flameHeight);
    _scratchRightFlamePath.lineTo(rightThrusterX + 6.0, thrusterY);
    _scratchRightFlamePath.close();
    canvas.drawPath(_scratchRightFlamePath, _flamePaint);

    // Trailing Ion Contrails during deep space forward flight
    if (normForward > 0.05) {
      final contrailLen = 35.0 + 45.0 * normForward;
      final contrailAlpha = (0.2 + 0.5 * normForward).clamp(0.0, 0.7);
      _contrailPaint.color = VoidTheme.plasmaCyan.withValues(
        alpha: contrailAlpha,
      );
      canvas.drawLine(
        Offset(leftThrusterX, thrusterY + flameHeight * 0.8),
        Offset(leftThrusterX, thrusterY + flameHeight + contrailLen),
        _contrailPaint,
      );
      canvas.drawLine(
        Offset(rightThrusterX, thrusterY + flameHeight * 0.8),
        Offset(rightThrusterX, thrusterY + flameHeight + contrailLen),
        _contrailPaint,
      );
    }

    // Dreadnought Flagship Hull (Enlarged to 104x48 dp for commanding presence)
    const shipW = 104.0;

    canvas.save();
    canvas.translate(centerX, shipY);
    canvas.rotate(bankAngleRad);
    canvas.scale(bankForeshortening, 1.0);

    // Deep Space Energetic Bow Shock Ripple (Ahead of Prow)
    if (normForward > 0.06) {
      final shockAlpha = (normForward * 0.85).clamp(0.0, 0.85);
      final shockW = shipW * (1.15 + 0.25 * math.sin(animationTime * 18.0));
      _bowShockGlowPaint.color = VoidTheme.plasmaCyan.withValues(
        alpha: shockAlpha * 0.45,
      );
      _bowShockPaint.color = Colors.white.withValues(alpha: shockAlpha * 0.90);
      final shockRect = Rect.fromLTRB(-shockW / 2, -44.0, shockW / 2, -18.0);
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

    // Hull obsidian base
    canvas.drawPath(_staticDreadHullPath, _dreadFillPaint);

    // Hull armor plating gradient (Pre-compiled zero-allocation static shader)
    canvas.drawPath(_staticDreadHullPath, _dreadArmorPaint);

    // Hull cyan trim outline
    _dreadOutlinePaint.strokeWidth = 2.4;
    canvas.drawPath(_staticDreadHullPath, _dreadOutlinePaint);

    // Forward Twin Particle Lance Turrets (Longer with emitter tips)
    _turretPaint.strokeWidth = 3.2;
    canvas.drawLine(
      const Offset(-6.5, -12.0),
      const Offset(-6.5, -28.0),
      _turretPaint,
    );
    canvas.drawLine(
      const Offset(6.5, -12.0),
      const Offset(6.5, -28.0),
      _turretPaint,
    );
    canvas.drawCircle(const Offset(-6.5, -28.0), 2.5, _coreCenterPaint);
    canvas.drawCircle(const Offset(6.5, -28.0), 2.5, _coreCenterPaint);

    // Prow Tactical Alignment Chevron / Beacon (Instant Centerline Recognition)
    final chevronPulse = 0.65 + 0.35 * math.sin(animationTime * 12.0);
    _prowChevronPaint.color = VoidTheme.solarGold.withValues(
      alpha: chevronPulse,
    );
    canvas.drawPath(_staticProwChevronPath, _prowChevronPaint);

    // Wingtip Port (Crimson) and Starboard (Emerald) Navigation Lights
    final portStrobe = 0.5 + 0.5 * math.sin(animationTime * 15.0);
    final stbdStrobe = 0.5 + 0.5 * math.cos(animationTime * 15.0);
    _portNavPaint.color = VoidTheme.crimsonFlare.withValues(alpha: portStrobe);
    _starboardNavPaint.color = VoidTheme.emeraldShield.withValues(
      alpha: stbdStrobe,
    );
    canvas.drawCircle(const Offset(-shipW / 2, 11.0), 3.5, _portNavPaint);
    canvas.drawCircle(const Offset(shipW / 2, 11.0), 3.5, _starboardNavPaint);

    // Central Plasma Reactor Core (Multi-Ring Energy Aura, Hardware Accelerated)
    final coreGlow = 8.0 + math.sin(animationTime * 10.0) * 2.5;
    canvas.drawCircle(const Offset(0, 3.0), coreGlow + 5.0, _coreGlowPaint);
    canvas.drawCircle(const Offset(0, 3.0), 14.0, _coreOuterGlowPaint);
    canvas.drawCircle(const Offset(0, 3.0), 5.0, _coreCenterPaint);

    // Forward Kinetic Energy Canopy Shield Arc (Glow + Core)
    const shieldRect = Rect.fromLTRB(
      -shipW * 1.15 / 2,
      -34.0,
      shipW * 1.15 / 2,
      14.0,
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
    canvas.restore();

    // Upward Flight Discovery Hint (Pulsing text when stationary in orbit to teach deep-space flight)
    if (normForward < 0.25) {
      final pulse = (0.5 + 0.5 * math.sin(animationTime * 4.0)).clamp(
        0.2,
        0.95,
      );
      _flightHintPainter.text = TextSpan(
        text: '▲ DRAG UP FOR DEEP SPACE ▲',
        style: TextStyle(
          color: VoidTheme.plasmaCyan.withValues(alpha: pulse),
          fontSize: 8.5,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.0,
          shadows: [
            const Shadow(color: Colors.black, blurRadius: 4.0),
            Shadow(
              color: VoidTheme.plasmaCyan.withValues(alpha: pulse * 0.6),
              blurRadius: 8.0,
            ),
          ],
        ),
      );
      _flightHintPainter.layout();
      _flightHintPainter.paint(
        canvas,
        Offset(centerX - _flightHintPainter.width / 2.0, shipY - 54.0),
      );
    }

    // Defender Conduit Label (Zero-Allocation Pre-Laid Out Painter)
    final labelPainter = _conduitLabelPainters[activeCorridor];
    final labelX = (centerX - (labelPainter.width / 2)).clamp(
      8.0,
      size.width - labelPainter.width - 8.0,
    );
    labelPainter.paint(canvas, Offset(labelX, shipY + 23.0));

    // Proximity Vanguard Telemetry Badge
    if (dreadnought.proximityMultiplier > 1.01) {
      final bonusPercent = ((dreadnought.proximityMultiplier - 1.0) * 100)
          .toInt();
      final bonusText = '⚡ VANGUARD +$bonusPercent% LANCE';
      _proximityTagTextPainter.text = TextSpan(
        text: bonusText,
        style: const TextStyle(
          color: VoidTheme.solarGold,
          fontSize: 8.5,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.8,
        ),
      );
      _proximityTagTextPainter.layout();
      final tagW = _proximityTagTextPainter.width + 8.0;
      const tagH = 15.0;
      final tagRect = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(centerX, shipY + 40.0),
          width: tagW,
          height: tagH,
        ),
        const Radius.circular(3.0),
      );
      canvas.drawRRect(tagRect, _damageTagBgPaint);
      canvas.drawRRect(tagRect, _damageTagBorderPaint);
      _proximityTagTextPainter.paint(
        canvas,
        Offset(
          centerX - _proximityTagTextPainter.width / 2.0,
          shipY + 40.0 - _proximityTagTextPainter.height / 2.0,
        ),
      );
    }

    // -------------------------------------------------------------------------
    // Tactical Spatial Altimeter / Elevation Rail (Left Margin)
    // -------------------------------------------------------------------------
    final railBottom = boundaryY + 12.0;
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
