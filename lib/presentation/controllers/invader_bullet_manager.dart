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

import '../../domain/models/bay_state.dart';
import '../../domain/models/enemy_bullet.dart';
import '../../domain/models/enemy_craft.dart';
import '../../domain/models/flak_burst.dart';
import '../../domain/models/floating_damage_number.dart';
import '../../domain/models/lance_beam.dart';
import '../services/particle_service.dart';
import '../theme/void_theme.dart';

/// Callback invoked when an enemy projectile breaches a frontline capacitor conduit.
typedef OnConduitBreached = void Function(int corridor, double x, double y);

/// Callback invoked when an enemy projectile breaches the atmospheric defense perimeter.
typedef OnAtmosphereBreached = void Function(double x, double y);

/// Callback invoked when an enemy projectile is deflected by kinetic shielding or Kimbi bays.
typedef OnBulletDeflected = void Function(double x, double y, Color color);

/// Encapsulates enemy projectile firing, descent physics, and raycasting
/// against upward particle lances, radial flak detonations, and atmospheric boundaries.
class InvaderBulletManager {
  InvaderBulletManager({
    required this.particleService,
    required this.damageNumbers,
    required this.onConduitBreached,
    required this.onAtmosphereBreached,
    required this.onBulletDeflected,
  });

  final ParticleService particleService;
  final List<FloatingDamageNumber> damageNumbers;
  final OnConduitBreached onConduitBreached;
  final OnAtmosphereBreached onAtmosphereBreached;
  final OnBulletDeflected onBulletDeflected;

  final List<EnemyBullet> _bullets = <EnemyBullet>[];
  final math.Random _random = math.Random();

  double _enemyFireCooldown = 1.0;
  int _bulletIdCounter = 0;

  /// Active bullets in flight.
  List<EnemyBullet> get bullets => _bullets;

  /// Clears all active bullets.
  void clear() {
    _bullets.clear();
    _enemyFireCooldown = 1.0;
  }

  /// Updates firing cadence, projectile movement, and collision detections.
  void update({
    required double dt,
    required Size viewportSize,
    required double boundaryY,
    required double dreadX,
    required List<EnemyCraft> enemies,
    required List<LanceBeam> lances,
    required List<FlakBurst> flaks,
    List<BayState> bays = const [],
  }) {
    final corridorWidth = viewportSize.width / 8.0;
    final topMargin = viewportSize.height * 0.06;

    // 1. Enemy assault craft firing dropping plasma bullets down corridors
    _enemyFireCooldown -= dt;
    if (_enemyFireCooldown <= 0.0 && enemies.isNotEmpty) {
      _enemyFireCooldown = 1.0 + _random.nextDouble() * 0.8;
      final frontEnemiesByCorridor = <int, EnemyCraft>{};
      for (var i = 0; i < enemies.length; i++) {
        final e = enemies[i];
        if (!e.isDestroyed && e.worldPosY > 0.15 && e.worldPosY <= 1.0) {
          final c = e.assignedCorridor;
          if (!frontEnemiesByCorridor.containsKey(c) ||
              e.worldPosY < frontEnemiesByCorridor[c]!.worldPosY) {
            frontEnemiesByCorridor[c] = e;
          }
        }
      }
      if (frontEnemiesByCorridor.isNotEmpty) {
        final candidates = frontEnemiesByCorridor.values.toList();
        candidates.shuffle(_random);
        final shooters = candidates.take(math.min(2, candidates.length));

        for (final shooter in shooters) {
          final enemyX = (shooter.assignedCorridor + 0.5) * corridorWidth;
          final normY = shooter.worldPosY.clamp(0.0, 1.0);
          final enemyY =
              topMargin + ((1.0 - normY) / 0.85) * (boundaryY - topMargin);
          final mouthY = enemyY + 16.0;

          Color bulletColor = VoidTheme.crimsonFlare;
          if (shooter.vesselType == 1) {
            bulletColor = VoidTheme.solarGold;
          } else if (shooter.vesselType == 2) {
            bulletColor = VoidTheme.nebulaAmethyst;
          }

          _bullets.add(
            EnemyBullet(
              id: ++_bulletIdCounter,
              assignedCorridor: shooter.assignedCorridor,
              x: enemyX,
              y: mouthY,
              velocityY: 210.0,
              radius: 5.0,
              color: bulletColor,
            ),
          );

          particleService.spawnLanceSparks(
            enemyX,
            mouthY,
            bulletColor,
            count: 6,
          );
        }
      }
    }

    // 2. Identify corridors with active upward Particle Lances
    final lanceCorridors = <int>{};
    for (final lance in lances) {
      if (lance.active) {
        final c = (lance.firingBayIndex >= 8)
            ? (lance.firingBayIndex - 8)
            : lance.firingBayIndex;
        lanceCorridors.add(c);
        final originCorridor = (lance.originX * 8.0).floor().clamp(0, 7);
        lanceCorridors.add(originCorridor);
      }
    }

    // 3. Update active bullets and test collisions
    _bullets.removeWhere((bullet) {
      bullet.update(dt);

      // A. Intercepted by active Particle Lance beam
      if (lanceCorridors.contains(bullet.assignedCorridor)) {
        particleService.spawnFlakBurst(
          bullet.x,
          bullet.y,
          VoidTheme.plasmaCyan,
          count: 14,
        );
        onBulletDeflected(bullet.x, bullet.y, VoidTheme.plasmaCyan);
        if (damageNumbers.length < 8) {
          damageNumbers.add(
            FloatingDamageNumber(
              text: 'DEFLECT +50',
              x: bullet.x,
              y: bullet.y,
              color: VoidTheme.plasmaCyan,
              isCritical: true,
            ),
          );
        }
        return true;
      }

      // B. Intercepted by active Flak Bursts
      for (final flak in flaks) {
        if (!flak.active) continue;
        final flakX = flak.worldPosX * viewportSize.width;
        final rawRadius = flak.blastRadius * viewportSize.width;
        final normFlakY = flak.worldPosY.clamp(0.0, 1.0);
        final flakY =
            topMargin + ((1.0 - normFlakY) / 0.85) * (boundaryY - topMargin);

        if ((bullet.x - flakX).abs() < rawRadius &&
            (bullet.y - flakY).abs() < rawRadius) {
          particleService.spawnFlakBurst(
            bullet.x,
            bullet.y,
            VoidTheme.solarGold,
            count: 10,
          );
          onBulletDeflected(bullet.x, bullet.y, VoidTheme.solarGold);
          if (damageNumbers.length < 8) {
            damageNumbers.add(
              FloatingDamageNumber(
                text: 'FLAK VAPOR +25',
                x: bullet.x,
                y: bullet.y,
                color: VoidTheme.solarGold,
              ),
            );
          }
          return true;
        }
      }

      // C. Reached Atmospheric Boundary / Dreadnought Flagship
      if (bullet.y >= boundaryY) {
        final hitDread = (bullet.x - dreadX).abs() < 46.0;
        if (hitDread) {
          final activeCorridor = (bullet.x / corridorWidth).floor().clamp(0, 7);
          final bayIndex = 8 + activeCorridor;
          final isCharged =
              bayIndex < bays.length && bays[bayIndex].chargeUnits > 0;

          if (isCharged) {
            particleService.spawnFlakBurst(
              bullet.x,
              boundaryY,
              VoidTheme.plasmaCyan,
              count: 18,
            );
            if (damageNumbers.length < 8) {
              damageNumbers.add(
                FloatingDamageNumber(
                  text: 'CANOPY DEFLECT! +50',
                  x: bullet.x,
                  y: boundaryY - 24,
                  color: VoidTheme.plasmaCyan,
                  isCritical: true,
                ),
              );
            }
            onBulletDeflected(bullet.x, boundaryY, VoidTheme.plasmaCyan);
          } else {
            particleService.spawnFlakBurst(
              bullet.x,
              boundaryY,
              VoidTheme.crimsonFlare,
              count: 18,
            );
            if (damageNumbers.length < 8) {
              damageNumbers.add(
                FloatingDamageNumber(
                  text: 'CONDUIT BREACH! -1 CORE & DRAINED',
                  x: bullet.x,
                  y: boundaryY - 24,
                  color: VoidTheme.crimsonFlare,
                  isCritical: true,
                ),
              );
            }
            onConduitBreached(activeCorridor, bullet.x, boundaryY);
          }
        } else {
          particleService.spawnLanceSparks(
            bullet.x,
            boundaryY,
            VoidTheme.solarGold,
            count: 8,
          );
          if (damageNumbers.length < 8) {
            damageNumbers.add(
              FloatingDamageNumber(
                text: '-5 ATMOS PASS',
                x: bullet.x,
                y: boundaryY - 15,
                color: VoidTheme.solarGold,
              ),
            );
          }
          onAtmosphereBreached(bullet.x, boundaryY);
        }
        return true;
      }

      return bullet.y > viewportSize.height;
    });
  }
}
