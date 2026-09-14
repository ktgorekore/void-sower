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

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_sower/domain/models/enemy_craft.dart';
import 'package:void_sower/domain/models/floating_damage_number.dart';
import 'package:void_sower/domain/models/lance_beam.dart';
import 'package:void_sower/presentation/controllers/invader_bullet_manager.dart';
import 'package:void_sower/presentation/services/particle_service.dart';

void main() {
  group('InvaderBulletManager Tests', () {
    late ParticleService particleService;
    late List<FloatingDamageNumber> damageNumbers;
    int conduitBreachCount = 0;
    int atmosphereBreachCount = 0;
    int bulletDeflectCount = 0;
    late InvaderBulletManager manager;

    setUp(() {
      particleService = ParticleService(maxParticles: 50);
      damageNumbers = <FloatingDamageNumber>[];
      conduitBreachCount = 0;
      atmosphereBreachCount = 0;
      bulletDeflectCount = 0;

      manager = InvaderBulletManager(
        particleService: particleService,
        damageNumbers: damageNumbers,
        onConduitBreached: (c, x, y) => conduitBreachCount++,
        onAtmosphereBreached: (x, y) => atmosphereBreachCount++,
        onBulletDeflected: (x, y, color) => bulletDeflectCount++,
      );
    });

    test('Enemy assault craft spawns bullets over time', () {
      final enemies = [
        const EnemyCraft(
          entityId: 1,
          assignedCorridor: 3,
          worldPosX: 0.4375,
          worldPosY: 0.5,
          velocityY: 0.05,
          currentShields: 100,
          maxShields: 100,
          currentHull: 100,
          maxHull: 100,
          vesselType: 0,
          isDestroyed: false,
        ),
      ];

      // Step time enough to trigger enemy fire cooldown (initial cooldown is 1.0s)
      manager.update(
        dt: 1.5,
        viewportSize: const Size(800, 1000),
        boundaryY: 880,
        dreadX: 400,
        enemies: enemies,
        lances: const [],
        flaks: const [],
      );

      expect(manager.bullets, isNotEmpty);
      expect(manager.bullets.first.assignedCorridor, equals(3));
    });

    test('Particle Lance intercepts and deflects bullets in corridor', () {
      final enemies = [
        const EnemyCraft(
          entityId: 1,
          assignedCorridor: 2,
          worldPosX: 0.3125,
          worldPosY: 0.6,
          velocityY: 0.05,
          currentShields: 100,
          maxShields: 100,
          currentHull: 100,
          maxHull: 100,
          vesselType: 0,
          isDestroyed: false,
        ),
      ];

      // Spawn bullet in corridor 2
      manager.update(
        dt: 1.5,
        viewportSize: const Size(800, 1000),
        boundaryY: 880,
        dreadX: 400,
        enemies: enemies,
        lances: const [],
        flaks: const [],
      );
      expect(manager.bullets.length, equals(1));

      // Active lance firing in frontline bay 10 (corridor 10 - 8 = 2)
      const lances = [
        LanceBeam(
          firingBayIndex: 10,
          originX: 0.3125,
          originY: 880,
          beamWidth: 0.05,
          sustainedDuration: 0.5,
          remainingDuration: 0.5,
          totalDamage: 400,
          active: true,
        ),
      ];

      manager.update(
        dt: 0.016,
        viewportSize: const Size(800, 1000),
        boundaryY: 880,
        dreadX: 400,
        enemies: enemies,
        lances: lances,
        flaks: const [],
      );

      // Bullet intercepted and deflected!
      expect(manager.bullets, isEmpty);
      expect(bulletDeflectCount, equals(1));
      expect(damageNumbers.any((d) => d.text == 'DEFLECT +50'), isTrue);
    });

    test('Direct hit on flagship triggers conduit breach', () {
      final enemies = [
        const EnemyCraft(
          entityId: 1,
          assignedCorridor: 4,
          worldPosX: 0.5625,
          worldPosY: 0.9,
          velocityY: 0.05,
          currentShields: 100,
          maxShields: 100,
          currentHull: 100,
          maxHull: 100,
          vesselType: 0,
          isDestroyed: false,
        ),
      ];

      // Spawn bullet
      manager.update(
        dt: 1.5,
        viewportSize: const Size(800, 1000),
        boundaryY: 880,
        dreadX: 450, // Dreadnought aligned with corridor 4 (centerX = 450)
        enemies: enemies,
        lances: const [],
        flaks: const [],
      );
      expect(manager.bullets.isNotEmpty, isTrue);

      // Advance bullet past boundaryY (880)
      manager.update(
        dt: 5.0,
        viewportSize: const Size(800, 1000),
        boundaryY: 880,
        dreadX: 450,
        enemies: const [],
        lances: const [],
        flaks: const [],
      );

      expect(conduitBreachCount, equals(1));
      expect(
        damageNumbers.any((d) => d.text.contains('CONDUIT BREACH')),
        isTrue,
      );
    });
  });
}
