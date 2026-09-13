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
import '../../domain/models/enemy_craft.dart';
import '../../domain/models/flak_burst.dart';
import '../../domain/models/lance_beam.dart';
import '../services/particle_service.dart';
import '../theme/void_theme.dart';

/// 60 FPS CustomPainter rendering combat corridors, particle lances,
/// secondary flak bursts, enemy vessels, and particle systems.
class CombatPainter extends CustomPainter {
  CombatPainter({
    required this.dreadnought,
    required this.enemies,
    required this.lances,
    required this.flaks,
    required this.particles,
    required this.animationTime,
  });

  final DreadnoughtState dreadnought;
  final List<EnemyCraft> enemies;
  final List<LanceBeam> lances;
  final List<FlakBurst> flaks;
  final List<VisualParticle> particles;
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
    final boundaryY = size.height * 0.82;
    final boundaryPaint = Paint()
      ..color = VoidTheme.crimsonFlare.withValues(alpha: 0.5)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(0, boundaryY),
      Offset(size.width, boundaryY),
      boundaryPaint,
    );

    // 3. Draw Active Particle Lances
    for (final lance in lances) {
      if (!lance.active) continue;
      final corridor = lance.firingBayIndex < 8
          ? lance.firingBayIndex
          : 15 - lance.firingBayIndex;
      final centerX =
          (corridor + 0.5) * corridorWidth + dreadnought.orbitalPositionX;
      final beamW = math.max(lance.beamWidth, 8.0);

      // Lance outer glow
      final glowPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            VoidTheme.plasmaCyan.withValues(alpha: 0.9),
            VoidTheme.plasmaCyan.withValues(alpha: 0.2),
          ],
        ).createShader(Rect.fromLTWH(centerX - beamW, 0, beamW * 2, boundaryY))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

      canvas.drawRect(
        Rect.fromLTWH(centerX - beamW, 0, beamW * 2, boundaryY),
        glowPaint,
      );

      // Lance core axial beam
      final corePaint = Paint()
        ..color = Colors.white
        ..strokeWidth = math.max(beamW * 0.3, 3.0)
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(
        Offset(centerX, boundaryY),
        Offset(centerX, 0),
        corePaint,
      );
    }

    // 4. Draw Active Secondary Flak Bursts
    for (final flak in flaks) {
      if (!flak.active) continue;
      final progress =
          1.0 - (flak.remainingLifetime / math.max(flak.lifetime, 0.01));
      final radius = flak.blastRadius * progress;
      final alpha = (1.0 - progress).clamp(0.0, 1.0);

      final flakPaint = Paint()
        ..color = VoidTheme.solarGold.withValues(alpha: alpha * 0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0 * (1.0 - progress);

      canvas.drawCircle(
        Offset(flak.worldPosX + (size.width / 2), flak.worldPosY),
        radius,
        flakPaint,
      );
    }

    // 5. Draw Enemy Assault Craft
    for (final enemy in enemies) {
      if (enemy.isDestroyed) continue;
      final x = (enemy.assignedCorridor + 0.5) * corridorWidth;
      final y = enemy.worldPosY;

      if (y < -50 || y > size.height) continue;

      _drawEnemyVessel(canvas, x, y, enemy, corridorWidth);
    }

    // 6. Draw Visual Particles
    for (final p in particles) {
      final pPaint = Paint()
        ..color = p.color.withValues(alpha: p.alpha)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(p.x, p.y), p.radius, pPaint);
    }

    // 7. Draw Dreadnought Flagship Platform on Horizon
    _drawDreadnoughtPlatform(canvas, size, boundaryY);
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
    hullPath.moveTo(x, y + h); // Nose pointing downward
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
    final centerX = (size.width / 2) + dreadnought.orbitalPositionX;
    final platformW = size.width * 0.85;

    // Platform glow arc
    final arcPaint = Paint()
      ..color = VoidTheme.solarGold.withValues(alpha: 0.4)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final rect = Rect.fromCenter(
      center: Offset(centerX, boundaryY + 120),
      width: platformW,
      height: 180,
    );
    canvas.drawArc(rect, math.pi * 1.15, math.pi * 0.7, false, arcPaint);

    // Core capacitor emitter hub
    final emitterPaint = Paint()
      ..color = VoidTheme.solarGold
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(centerX, boundaryY + 15), 6.0, emitterPaint);
  }

  @override
  bool shouldRepaint(covariant CombatPainter oldDelegate) => true;
}
