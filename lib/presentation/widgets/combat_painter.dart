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

    // 1. Draw 8 Tactical Combat Corridors
    for (var i = 1; i < 8; i++) {
      final x = i * corridorWidth;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), _corridorPaint);
    }

    // 2. Draw Atmospheric Defense Boundary Line
    final boundaryY = size.height - 48.0;
    canvas.drawLine(
      Offset(0, boundaryY),
      Offset(size.width, boundaryY),
      _boundaryPaint,
    );

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

  static final Paint _aimPaint = Paint()
    ..strokeWidth = 1.5
    ..style = PaintingStyle.stroke;

  static final Paint _lockPaint = Paint()
    ..color = VoidTheme.solarGold.withValues(alpha: 0.85)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.8;

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
    ..color = VoidTheme.emeraldShield.withValues(alpha: 0.6)
    ..strokeWidth = 2.2
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
        text: '▲ DEFENDER CONDUIT [C${i + 1}] ▲',
        style: const TextStyle(
          color: VoidTheme.solarGold,
          fontSize: 9.0,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.2,
          shadows: [Shadow(color: Colors.black, blurRadius: 4.0)],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    return painter;
  });

  @override
  void paint(Canvas canvas, Size size) {
    final corridorWidth = size.width / 8.0;
    final boundaryY = size.height - 48.0;

    // 1. Draw Active Particle Lances (FIRED AXIALLY FROM DREADNOUGHT PROW)
    for (var i = 0; i < lances.length; i++) {
      final lance = lances[i];
      if (!lance.active) continue;
      final corridor = (lance.firingBayIndex >= 8)
          ? (lance.firingBayIndex - 8)
          : lance.firingBayIndex;
      final centerX = (lance.originX > 0.0 && lance.originX <= 1.0)
          ? lance.originX * size.width
          : (dreadnought.orbitalPositionX > 0.0 &&
                dreadnought.orbitalPositionX <= 1.0)
          ? dreadnought.orbitalPositionX * size.width
          : (corridor + 0.5) * corridorWidth;
      final rawWidth = lance.beamWidth <= 1.0
          ? (lance.beamWidth * size.width)
          : lance.beamWidth;
      final beamW = math.max(rawWidth, 12.0);

      // Lance outer glow (Zero-allocation static shader with hardware canvas transform)
      canvas.save();
      canvas.translate(centerX, 0);
      canvas.scale(beamW * 1.5, boundaryY);
      canvas.drawRect(const Rect.fromLTWH(-1.0, 0, 2.0, 1.0), _lanceGlowPaint);
      canvas.restore();

      // Core axial laser beam
      _lanceCorePaint.strokeWidth = math.max(beamW * 0.4, 4.0);
      canvas.drawLine(
        Offset(centerX, boundaryY),
        Offset(centerX, 0),
        _lanceCorePaint,
      );

      // Muzzle Flare at the Dreadnought Turret (Zero MaskFilter)
      canvas.drawCircle(
        Offset(centerX, boundaryY),
        beamW * 1.6,
        _muzzleGlowPaint,
      );
      canvas.drawCircle(Offset(centerX, boundaryY), beamW * 0.8, _muzzlePaint);
      canvas.drawLine(
        Offset(centerX - beamW * 2.2, boundaryY),
        Offset(centerX + beamW * 2.2, boundaryY),
        _muzzleSpikePaint,
      );

      // Impact shockwave at top
      canvas.drawCircle(Offset(centerX, 25), beamW * 1.8, _impactPaint);
    }

    // 2. Draw Active Secondary Flak Bursts
    final topMargin = size.height * 0.06;
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
      num.textPainter.paint(
        canvas,
        Offset(num.x - (num.textPainter.width / 2), num.y),
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
    final dreadNormX =
        (dreadnought.orbitalPositionX > 0.0 &&
            dreadnought.orbitalPositionX <= 1.0)
        ? dreadnought.orbitalPositionX
        : 0.4375;
    final centerX = dreadNormX * size.width;
    final shipY = boundaryY + 12.0;

    // Active corridor highlight under dreadnought (Energized Runway Track)
    final activeCorridor = (centerX / (size.width / 8.0)).floor().clamp(0, 7);
    final corridorWidth = size.width / 8.0;

    _highlightPaint.color = VoidTheme.plasmaCyan.withValues(alpha: 0.14);
    canvas.drawRect(
      Rect.fromLTWH(
        activeCorridor * corridorWidth,
        0,
        corridorWidth,
        boundaryY,
      ),
      _highlightPaint,
    );

    // Targeting Alignment Laser Beam (Pulsing high-visibility beam aligned with ship prow)
    final aimPulse = 0.40 + 0.25 * math.sin(animationTime * 10.0);
    _aimPaint.color = VoidTheme.plasmaCyan.withValues(alpha: aimPulse);
    _aimPaint.strokeWidth = 2.0;
    canvas.drawLine(Offset(centerX, boundaryY), Offset(centerX, 0), _aimPaint);

    // Lock-on reticles on descending enemies in active corridor
    final topMargin = size.height * 0.06;
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
        canvas.drawRect(
          Rect.fromCenter(
            center: Offset(enemyX, ey),
            width: lockSize * 2,
            height: lockSize * 2,
          ),
          _lockPaint,
        );
      }
    }

    // Animated Twin Plasma Thrusters (Enlarged and spread to 24.0)
    final flameHeight = 22.0 + math.sin(animationTime * 20.0) * 6.0;
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

    // Dreadnought Flagship Hull (Enlarged to 104x48 dp for commanding presence)
    const shipW = 104.0;

    canvas.save();
    canvas.translate(centerX, shipY);

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

    // Forward Kinetic Energy Shield Arc
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
      _shieldArcPaint,
    );
    canvas.restore();

    // Defender Conduit Label (Zero-Allocation Pre-Laid Out Painter)
    final labelPainter = _conduitLabelPainters[activeCorridor];
    final labelX = (centerX - (labelPainter.width / 2)).clamp(
      8.0,
      size.width - labelPainter.width - 8.0,
    );
    labelPainter.paint(canvas, Offset(labelX, shipY + 23.0));
  }

  @override
  bool shouldRepaint(covariant CombatPainter oldDelegate) => true;
}
