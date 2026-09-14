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

/// 60 FPS CustomPainter rendering combat corridors, particle lances,
/// secondary flak bursts, enemy vessels, dropping enemy projectiles,
/// and the player's flagship dreadnought.
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

  @override
  void paint(Canvas canvas, Size size) {
    final corridorWidth = size.width / 8.0;

    // 1. Draw 8 Tactical Combat Corridors
    final corridorPaint = Paint()
      ..color = VoidTheme.cosmicNavy.withValues(alpha: 0.35)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    for (var i = 1; i < 8; i++) {
      final x = i * corridorWidth;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), corridorPaint);
    }

    // 2. Draw Atmospheric Defense Boundary Line
    final boundaryY = size.height - 32.0;
    final boundaryPaint = Paint()
      ..color = VoidTheme.crimsonFlare.withValues(alpha: 0.5)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(0, boundaryY),
      Offset(size.width, boundaryY),
      boundaryPaint,
    );

    // 3. Draw Active Particle Lances (FIRED UPWARD FROM DREADNOUGHT)
    for (final lance in lances) {
      if (!lance.active) continue;
      final corridor = (lance.firingBayIndex >= 8)
          ? (lance.firingBayIndex - 8)
          : lance.firingBayIndex;
      final centerX = (corridor + 0.5) * corridorWidth;
      final rawWidth = lance.beamWidth <= 1.0
          ? (lance.beamWidth * size.width)
          : lance.beamWidth;
      final beamW = math.max(rawWidth, 10.0);

      // Upward firing lance outer glow: Brightest at Dreadnought turret (bottom), shooting UP!
      final glowPaint = Paint()
        ..shader =
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
            )
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

      canvas.drawRect(
        Rect.fromLTWH(centerX - beamW * 1.5, 0, beamW * 3, boundaryY),
        glowPaint,
      );

      // Core axial laser beam
      final corePaint = Paint()
        ..color = Colors.white
        ..strokeWidth = math.max(beamW * 0.4, 4.0)
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(
        Offset(centerX, boundaryY),
        Offset(centerX, 0),
        corePaint,
      );

      // Muzzle Flare at the Dreadnought Turret
      final muzzlePaint = Paint()
        ..color = Colors.white
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawCircle(Offset(centerX, boundaryY), beamW * 1.6, muzzlePaint);

      final muzzleSpikePaint = Paint()
        ..color = VoidTheme.solarGold
        ..strokeWidth = 2.5;
      canvas.drawLine(
        Offset(centerX - beamW * 2.2, boundaryY),
        Offset(centerX + beamW * 2.2, boundaryY),
        muzzleSpikePaint,
      );

      // Impact shockwave at top (invader line)
      final impactPaint = Paint()
        ..color = VoidTheme.plasmaCyan.withValues(alpha: 0.85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0;
      canvas.drawCircle(Offset(centerX, 25), beamW * 1.8, impactPaint);
    }

    // 4. Draw Active Secondary Flak Bursts
    final topMargin = size.height * 0.06;
    for (final flak in flaks) {
      if (!flak.active) continue;
      final progress =
          1.0 - (flak.remainingLifetime / math.max(flak.lifetime, 0.01));
      final rawRadius = flak.blastRadius <= 1.0
          ? (flak.blastRadius * size.width)
          : flak.blastRadius;
      final radius = rawRadius * progress;
      final alpha = (1.0 - progress).clamp(0.0, 1.0);

      final flakPaint = Paint()
        ..color = VoidTheme.solarGold.withValues(alpha: alpha * 0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0 * (1.0 - progress);

      final flakX = flak.worldPosX <= 1.0
          ? flak.worldPosX * size.width
          : flak.worldPosX;
      final flakY = flak.worldPosY <= 1.0
          ? topMargin +
                ((1.0 - flak.worldPosY.clamp(0.0, 1.0)) / 0.85) *
                    (boundaryY - topMargin)
          : flak.worldPosY;

      canvas.drawCircle(Offset(flakX, flakY), radius, flakPaint);
    }

    // 5. Draw Enemy Assault Craft
    for (final enemy in enemies) {
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

    // 6. Draw Descending Enemy Plasma Bullets
    for (final bullet in enemyBullets) {
      _drawEnemyBullet(canvas, bullet);
    }

    // 7. Draw Visual Particles
    for (final p in particles) {
      final pPaint = Paint()
        ..color = p.color.withValues(alpha: p.alpha)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(p.x, p.y), p.radius, pPaint);
    }

    // 8. Draw Dreadnought Flagship on Defense Horizon
    _drawDreadnoughtPlatform(canvas, size, boundaryY);

    // 9. Draw Floating Arcade Damage Numbers
    for (final num in damageNumbers) {
      final alpha = (num.remainingLifetime / num.lifetime).clamp(0.0, 1.0);
      final textSpan = TextSpan(
        text: num.text,
        style: TextStyle(
          color: num.color.withValues(alpha: alpha),
          fontSize: num.isCritical ? 15.0 : 12.0,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(
              color: VoidTheme.obsidianBlack.withValues(alpha: alpha),
              blurRadius: 4.0,
            ),
          ],
        ),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(canvas, Offset(num.x - (textPainter.width / 2), num.y));
    }
  }

  void _drawEnemyBullet(Canvas canvas, EnemyBullet bullet) {
    // 1. Motion tail streak pointing upward (bullet moves downward)
    final tailPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [
          bullet.color.withValues(alpha: 0.85),
          bullet.color.withValues(alpha: 0.15),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(bullet.x - 2.5, bullet.y - 18, 5, 18))
      ..style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromLTWH(bullet.x - 2.0, bullet.y - 18, 4, 18),
      tailPaint,
    );

    // 2. Outer plasma glow
    final glowPaint = Paint()
      ..color = bullet.color.withValues(alpha: 0.55)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    canvas.drawCircle(
      Offset(bullet.x, bullet.y),
      bullet.radius * 1.9,
      glowPaint,
    );

    // 3. Core plasma orb
    final orbPaint = Paint()
      ..color = bullet.color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(bullet.x, bullet.y), bullet.radius, orbPaint);

    // 4. White-hot center
    final centerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      Offset(bullet.x, bullet.y),
      bullet.radius * 0.45,
      centerPaint,
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

    final hullPath = Path();
    hullPath.moveTo(x, y + h); // Nose pointing downward toward player!
    hullPath.lineTo(x - w / 2, y - h / 2);
    hullPath.lineTo(x, y - h / 4);
    hullPath.lineTo(x + w / 2, y - h / 2);
    hullPath.close();

    // Hull fill
    final hullPaint = Paint()
      ..color = enemy.vesselType == 2
          ? VoidTheme.crimsonFlare
          : VoidTheme.nebulaAmethyst
      ..style = PaintingStyle.fill;
    canvas.drawPath(hullPath, hullPaint);

    // Hull outline
    final outlinePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.8)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawPath(hullPath, outlinePaint);

    // Health / Shield Gauges
    final barW = w * 1.2;
    final barH = 3.0;
    final barY = y - h / 2 - 8.0;

    // Hull bar
    final hullFraction = (enemy.currentHull / math.max(enemy.maxHull, 1.0))
        .clamp(0.0, 1.0);
    final bgBarPaint = Paint()..color = Colors.black54;
    canvas.drawRect(Rect.fromLTWH(x - barW / 2, barY, barW, barH), bgBarPaint);
    final hullBarPaint = Paint()..color = Colors.redAccent;
    canvas.drawRect(
      Rect.fromLTWH(x - barW / 2, barY, barW * hullFraction, barH),
      hullBarPaint,
    );

    // Shield bar (if has shields)
    if (enemy.maxShields > 0) {
      final shieldFraction = (enemy.currentShields / enemy.maxShields).clamp(
        0.0,
        1.0,
      );
      final shieldBarPaint = Paint()..color = VoidTheme.plasmaCyan;
      canvas.drawRect(
        Rect.fromLTWH(x - barW / 2, barY - 4.0, barW * shieldFraction, barH),
        shieldBarPaint,
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
    final shipY = boundaryY + 8.0;

    // 1. Planetary Defense Horizon Line
    final railPaint = Paint()
      ..color = VoidTheme.solarGold.withValues(alpha: 0.35)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(0, boundaryY + 18),
      Offset(size.width, boundaryY + 18),
      railPaint,
    );

    // Active corridor highlight under dreadnought
    final activeCorridor = (centerX / (size.width / 8.0)).floor().clamp(0, 7);
    final corridorWidth = size.width / 8.0;
    final targetCenterX = (activeCorridor + 0.5) * corridorWidth;

    final highlightPaint = Paint()
      ..color = VoidTheme.plasmaCyan.withValues(alpha: 0.08)
      ..style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromLTWH(
        activeCorridor * corridorWidth,
        0,
        corridorWidth,
        boundaryY,
      ),
      highlightPaint,
    );

    // 1b. Targeting Alignment Laser Beam (Option 1 Unified Conduit)
    final aimPulse = 0.22 + 0.12 * math.sin(animationTime * 10.0);
    final aimPaint = Paint()
      ..color = VoidTheme.plasmaCyan.withValues(alpha: aimPulse)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(targetCenterX, boundaryY),
      Offset(targetCenterX, 0),
      aimPaint,
    );

    // Lock-on reticles on any descending enemies in active corridor
    final topMargin = size.height * 0.06;
    for (final enemy in enemies) {
      if (!enemy.isDestroyed && enemy.assignedCorridor == activeCorridor) {
        final double ey = (enemy.worldPosY <= 1.0)
            ? topMargin +
                  ((1.0 - enemy.worldPosY.clamp(0.0, 1.0)) / 0.85) *
                      (boundaryY - topMargin)
            : enemy.worldPosY;
        final lockPaint = Paint()
          ..color = VoidTheme.solarGold.withValues(alpha: 0.85)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.8;
        final lockSize = 16.0 + 2.0 * math.sin(animationTime * 8.0);
        canvas.drawRect(
          Rect.fromCenter(
            center: Offset(targetCenterX, ey),
            width: lockSize * 2,
            height: lockSize * 2,
          ),
          lockPaint,
        );
      }
    }

    // 2. Animated Twin Plasma Thrusters
    final flameHeight = 13.0 + math.sin(animationTime * 20.0) * 4.0;
    final leftThrusterX = centerX - 14.0;
    final rightThrusterX = centerX + 14.0;
    final thrusterY = shipY + 10.0;

    final flamePaint = Paint()
      ..shader =
          LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              VoidTheme.plasmaCyan,
              VoidTheme.solarGold.withValues(alpha: 0.7),
              Colors.transparent,
            ],
          ).createShader(
            Rect.fromLTWH(leftThrusterX - 4, thrusterY, 8, flameHeight),
          );

    final leftFlamePath = Path()
      ..moveTo(leftThrusterX - 3.5, thrusterY)
      ..lineTo(leftThrusterX, thrusterY + flameHeight)
      ..lineTo(leftThrusterX + 3.5, thrusterY)
      ..close();
    canvas.drawPath(leftFlamePath, flamePaint);

    final rightFlamePath = Path()
      ..moveTo(rightThrusterX - 3.5, thrusterY)
      ..lineTo(rightThrusterX, thrusterY + flameHeight)
      ..lineTo(rightThrusterX + 3.5, thrusterY)
      ..close();
    canvas.drawPath(rightFlamePath, flamePaint);

    // 3. Dreadnought Flagship Hull
    const shipW = 58.0;
    const shipH = 28.0;

    // Delta wings & chassis
    final hullPath = Path()
      ..moveTo(centerX, shipY - 14) // Forward lance turret nose pointing UP!
      ..lineTo(centerX + 11, shipY - 4)
      ..lineTo(centerX + shipW / 2, shipY + 6) // Starboard wingtip
      ..lineTo(centerX + 18, shipY + 11) // Starboard thruster mount
      ..lineTo(centerX + 8, shipY + 7)
      ..lineTo(centerX - 8, shipY + 7)
      ..lineTo(centerX - 18, shipY + 11) // Port thruster mount
      ..lineTo(centerX - shipW / 2, shipY + 6) // Port wingtip
      ..lineTo(centerX - 11, shipY - 4)
      ..close();

    // Hull obsidian base
    final hullFillPaint = Paint()
      ..color = VoidTheme.obsidianBlack
      ..style = PaintingStyle.fill;
    canvas.drawPath(hullPath, hullFillPaint);

    // Hull armor plating gradient
    final armorPaint = Paint()
      ..shader =
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
          )
      ..style = PaintingStyle.fill;
    canvas.drawPath(hullPath, armorPaint);

    // Hull glowing cyan trim & outlines
    final outlinePaint = Paint()
      ..color = VoidTheme.plasmaCyan
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke;
    canvas.drawPath(hullPath, outlinePaint);

    // 4. Forward Twin Particle Lance Turrets (Pointing UP)
    final turretPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(centerX - 3.5, shipY - 8),
      Offset(centerX - 3.5, shipY - 16),
      turretPaint,
    );
    canvas.drawLine(
      Offset(centerX + 3.5, shipY - 8),
      Offset(centerX + 3.5, shipY - 16),
      turretPaint,
    );

    // 5. Central Plasma Reactor Core
    final coreGlow = 4.0 + math.sin(animationTime * 10.0) * 1.5;
    final coreGlowPaint = Paint()
      ..color = VoidTheme.plasmaCyan.withValues(alpha: 0.65)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    canvas.drawCircle(Offset(centerX, shipY + 1), coreGlow + 2, coreGlowPaint);

    final coreCenterPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(centerX, shipY + 1), 3.0, coreCenterPaint);

    // 6. Forward Kinetic Energy Shield Arc
    final shieldArcPaint = Paint()
      ..color = VoidTheme.emeraldShield.withValues(alpha: 0.6)
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke;
    final shieldRect = Rect.fromCenter(
      center: Offset(centerX, shipY - 6),
      width: shipW * 1.15,
      height: 28,
    );
    canvas.drawArc(
      shieldRect,
      math.pi * 1.15,
      math.pi * 0.7,
      false,
      shieldArcPaint,
    );

    // 7. Unmistakable Flagship Label HUD
    final labelSpan = TextSpan(
      text: '▲ DREADNOUGHT CONDUIT [C${activeCorridor + 1}] ▲',
      style: const TextStyle(
        color: VoidTheme.solarGold,
        fontSize: 8.5,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.2,
        shadows: [Shadow(color: Colors.black, blurRadius: 4.0)],
      ),
    );
    final labelPainter = TextPainter(
      text: labelSpan,
      textDirection: TextDirection.ltr,
    )..layout();
    final labelX = (centerX - (labelPainter.width / 2)).clamp(
      8.0,
      size.width - labelPainter.width - 8.0,
    );
    labelPainter.paint(canvas, Offset(labelX, shipY + 26));
  }

  @override
  bool shouldRepaint(covariant CombatPainter oldDelegate) => true;
}
