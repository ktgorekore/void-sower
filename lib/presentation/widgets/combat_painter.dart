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
  // Reusable Path Scratchpads (Zero-Allocation Geometry)
  // ---------------------------------------------------------------------------
  static final Path _scratchEnemyHullPath = Path();
  static final Path _scratchDreadHullPath = Path();
  static final Path _scratchLeftFlamePath = Path();
  static final Path _scratchRightFlamePath = Path();

  // ---------------------------------------------------------------------------
  // Pre-allocated Static Paint Pools (Eliminates Scudo HybridMutex Contention)
  // ---------------------------------------------------------------------------
  static final Paint _lanceCorePaint = Paint()
    ..color = Colors.white
    ..strokeCap = StrokeCap.round;

  static final Paint _lanceGlowPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

  static final Paint _muzzlePaint = Paint()
    ..color = Colors.white
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

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
  static final Paint _bulletGlowPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
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

  static final Paint _flamePaint = Paint()..style = PaintingStyle.fill;

  static final Paint _dreadFillPaint = Paint()
    ..color = VoidTheme.obsidianBlack
    ..style = PaintingStyle.fill;

  static final Paint _dreadArmorPaint = Paint()..style = PaintingStyle.fill;

  static final Paint _dreadOutlinePaint = Paint()
    ..color = VoidTheme.plasmaCyan
    ..strokeWidth = 1.8
    ..style = PaintingStyle.stroke;

  static final Paint _turretPaint = Paint()
    ..color = Colors.white
    ..strokeWidth = 2.2
    ..strokeCap = StrokeCap.round;

  static final Paint _coreGlowPaint = Paint()
    ..color = VoidTheme.plasmaCyan.withValues(alpha: 0.65)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);

  static final Paint _coreCenterPaint = Paint()
    ..color = Colors.white
    ..style = PaintingStyle.fill;

  static final Paint _shieldArcPaint = Paint()
    ..color = VoidTheme.emeraldShield.withValues(alpha: 0.6)
    ..strokeWidth = 2.2
    ..style = PaintingStyle.stroke;

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

      // Lance outer glow
      _lanceGlowPaint.shader =
          LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              VoidTheme.plasmaCyan.withValues(alpha: 0.95),
              VoidTheme.plasmaCyan.withValues(alpha: 0.70),
              Colors.white.withValues(alpha: 0.85),
            ],
          ).createShader(
            Rect.fromLTWH(centerX - beamW * 1.5, 0, beamW * 3, boundaryY),
          );

      canvas.drawRect(
        Rect.fromLTWH(centerX - beamW * 1.5, 0, beamW * 3, boundaryY),
        _lanceGlowPaint,
      );

      // Core axial laser beam
      _lanceCorePaint.strokeWidth = math.max(beamW * 0.4, 4.0);
      canvas.drawLine(
        Offset(centerX, boundaryY),
        Offset(centerX, 0),
        _lanceCorePaint,
      );

      // Muzzle Flare at the Dreadnought Turret
      canvas.drawCircle(Offset(centerX, boundaryY), beamW * 1.6, _muzzlePaint);
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
      final x = (enemy.assignedCorridor + 0.5) * corridorWidth;
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

    // 2. Outer plasma glow
    _bulletGlowPaint.color = bullet.color.withValues(alpha: 0.55);
    canvas.drawCircle(
      Offset(bullet.x, bullet.y),
      bullet.radius * 1.9,
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
        : 0.5;
    final centerX = dreadNormX * size.width;
    final shipY = boundaryY + 12.0;

    // Active corridor highlight under dreadnought
    final activeCorridor = (centerX / (size.width / 8.0)).floor().clamp(0, 7);
    final corridorWidth = size.width / 8.0;
    final targetCenterX = (activeCorridor + 0.5) * corridorWidth;

    canvas.drawRect(
      Rect.fromLTWH(
        activeCorridor * corridorWidth,
        0,
        corridorWidth,
        boundaryY,
      ),
      _highlightPaint,
    );

    // Targeting Alignment Laser Beam
    final aimPulse = 0.22 + 0.12 * math.sin(animationTime * 10.0);
    _aimPaint.color = VoidTheme.plasmaCyan.withValues(alpha: aimPulse);
    canvas.drawLine(
      Offset(targetCenterX, boundaryY),
      Offset(targetCenterX, 0),
      _aimPaint,
    );

    // Lock-on reticles on descending enemies in active corridor
    final topMargin = size.height * 0.06;
    for (var i = 0; i < enemies.length; i++) {
      final enemy = enemies[i];
      if (!enemy.isDestroyed && enemy.assignedCorridor == activeCorridor) {
        final double ey = (enemy.worldPosY <= 1.0)
            ? topMargin +
                  ((1.0 - enemy.worldPosY.clamp(0.0, 1.0)) / 0.85) *
                      (boundaryY - topMargin)
            : enemy.worldPosY;
        final lockSize = 16.0 + 2.0 * math.sin(animationTime * 8.0);
        canvas.drawRect(
          Rect.fromCenter(
            center: Offset(targetCenterX, ey),
            width: lockSize * 2,
            height: lockSize * 2,
          ),
          _lockPaint,
        );
      }
    }

    // Animated Twin Plasma Thrusters
    final flameHeight = 13.0 + math.sin(animationTime * 20.0) * 4.0;
    final leftThrusterX = centerX - 14.0;
    final rightThrusterX = centerX + 14.0;
    final thrusterY = shipY + 10.0;

    _flamePaint.shader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        VoidTheme.plasmaCyan,
        VoidTheme.solarGold.withValues(alpha: 0.7),
        Colors.transparent,
      ],
    ).createShader(Rect.fromLTWH(leftThrusterX - 4, thrusterY, 8, flameHeight));

    _scratchLeftFlamePath.reset();
    _scratchLeftFlamePath.moveTo(leftThrusterX - 3.5, thrusterY);
    _scratchLeftFlamePath.lineTo(leftThrusterX, thrusterY + flameHeight);
    _scratchLeftFlamePath.lineTo(leftThrusterX + 3.5, thrusterY);
    _scratchLeftFlamePath.close();
    canvas.drawPath(_scratchLeftFlamePath, _flamePaint);

    _scratchRightFlamePath.reset();
    _scratchRightFlamePath.moveTo(rightThrusterX - 3.5, thrusterY);
    _scratchRightFlamePath.lineTo(rightThrusterX, thrusterY + flameHeight);
    _scratchRightFlamePath.lineTo(rightThrusterX + 3.5, thrusterY);
    _scratchRightFlamePath.close();
    canvas.drawPath(_scratchRightFlamePath, _flamePaint);

    // Dreadnought Flagship Hull
    const shipW = 58.0;
    const shipH = 28.0;

    _scratchDreadHullPath.reset();
    _scratchDreadHullPath.moveTo(centerX, shipY - 14); // Nose pointing UP
    _scratchDreadHullPath.lineTo(centerX + 11, shipY - 4);
    _scratchDreadHullPath.lineTo(
      centerX + shipW / 2,
      shipY + 6,
    ); // Starboard wingtip
    _scratchDreadHullPath.lineTo(centerX + 18, shipY + 11); // Starboard mount
    _scratchDreadHullPath.lineTo(centerX + 8, shipY + 7);
    _scratchDreadHullPath.lineTo(centerX - 8, shipY + 7);
    _scratchDreadHullPath.lineTo(centerX - 18, shipY + 11); // Port mount
    _scratchDreadHullPath.lineTo(
      centerX - shipW / 2,
      shipY + 6,
    ); // Port wingtip
    _scratchDreadHullPath.lineTo(centerX - 11, shipY - 4);
    _scratchDreadHullPath.close();

    // Hull obsidian base
    canvas.drawPath(_scratchDreadHullPath, _dreadFillPaint);

    // Hull armor plating gradient
    _dreadArmorPaint.shader =
        LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            VoidTheme.solarGold.withValues(alpha: 0.85),
            VoidTheme.cardSurface,
            VoidTheme.obsidianBlack,
          ],
        ).createShader(
          Rect.fromLTWH(centerX - shipW / 2, shipY - 14, shipW, shipH),
        );
    canvas.drawPath(_scratchDreadHullPath, _dreadArmorPaint);

    // Hull cyan trim outline
    canvas.drawPath(_scratchDreadHullPath, _dreadOutlinePaint);

    // Forward Twin Particle Lance Turrets
    canvas.drawLine(
      Offset(centerX - 3.5, shipY - 8),
      Offset(centerX - 3.5, shipY - 16),
      _turretPaint,
    );
    canvas.drawLine(
      Offset(centerX + 3.5, shipY - 8),
      Offset(centerX + 3.5, shipY - 16),
      _turretPaint,
    );

    // Central Plasma Reactor Core
    final coreGlow = 4.0 + math.sin(animationTime * 10.0) * 1.5;
    canvas.drawCircle(Offset(centerX, shipY + 1), coreGlow + 2, _coreGlowPaint);
    canvas.drawCircle(Offset(centerX, shipY + 1), 3.0, _coreCenterPaint);

    // Forward Kinetic Energy Shield Arc
    const shieldRect = Rect.fromLTRB(
      -shipW * 1.15 / 2,
      -14,
      shipW * 1.15 / 2,
      14,
    );
    canvas.save();
    canvas.translate(centerX, shipY - 6);
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
    labelPainter.paint(canvas, Offset(labelX, shipY + 16.0));
  }

  @override
  bool shouldRepaint(covariant CombatPainter oldDelegate) => true;
}
