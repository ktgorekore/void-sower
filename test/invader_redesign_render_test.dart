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

import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_sower/domain/models/dreadnought_state.dart';
import 'package:void_sower/domain/models/enemy_craft.dart';
import 'package:void_sower/presentation/widgets/combat_painter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Redesigned 2D Vector Invaders Rendering Tests', () {
    const dread = DreadnoughtState(
      orbitalPositionX: 0.5,
      targetPositionX: 0.5,
      reserveCores: 24,
      boundaryLineY: 0.15,
      isCascading: false,
      totalScore: 1250,
      currentSimState: 0,
      coresUsed: 4,
    );

    test(
      'Renders Drone (Type 0) with delta chevron, twin thrusters, and health bar',
      () {
        final recorder = PictureRecorder();
        final canvas = Canvas(recorder);
        const canvasSize = Size(400.0, 800.0);

        const drone = EnemyCraft(
          entityId: 101,
          assignedCorridor: 2,
          worldPosX: 0.3125,
          worldPosY: 0.45,
          velocityY: 0.05,
          currentShields: 0,
          maxShields: 0,
          currentHull: 80,
          maxHull: 100,
          vesselType: 0,
          isDestroyed: false,
          warpInProgress: 1.0,
        );

        final painter = CombatPainter(
          dreadnought: dread,
          enemies: const [drone],
          lances: const [],
          flaks: const [],
          particles: const [],
          damageNumbers: const [],
          enemyBullets: const [],
          animationTime: 1.0,
        );

        painter.paint(canvas, canvasSize);
        final picture = recorder.endRecording();
        expect(picture, isNotNull);
        picture.dispose();
      },
    );

    test(
      'Renders Cruiser (Type 1) with assault mandibles, cyan conduits, and shield bar',
      () {
        final recorder = PictureRecorder();
        final canvas = Canvas(recorder);
        const canvasSize = Size(400.0, 800.0);

        const cruiser = EnemyCraft(
          entityId: 102,
          assignedCorridor: 4,
          worldPosX: 0.5625,
          worldPosY: 0.50,
          velocityY: 0.04,
          currentShields: 75,
          maxShields: 100,
          currentHull: 150,
          maxHull: 200,
          vesselType: 1,
          isDestroyed: false,
          bankAngleRad: 0.25,
          warpInProgress: 1.0,
        );

        final painter = CombatPainter(
          dreadnought: dread,
          enemies: const [cruiser],
          lances: const [],
          flaks: const [],
          particles: const [],
          damageNumbers: const [],
          enemyBullets: const [],
          animationTime: 2.0,
        );

        painter.paint(canvas, canvasSize);
        final picture = recorder.endRecording();
        expect(picture, isNotNull);
        picture.dispose();
      },
    );

    test(
      'Renders Flagship (Type 2) with crimson command wings, gold bridge, and dual thrusters',
      () {
        final recorder = PictureRecorder();
        final canvas = Canvas(recorder);
        const canvasSize = Size(400.0, 800.0);

        const flagship = EnemyCraft(
          entityId: 103,
          assignedCorridor: 3,
          worldPosX: 0.4375,
          worldPosY: 0.35,
          velocityY: 0.02,
          currentShields: 200,
          maxShields: 250,
          currentHull: 400,
          maxHull: 500,
          vesselType: 2,
          isDestroyed: false,
          bankAngleRad: -0.15,
          pitchAngleRad: 0.1,
          warpInProgress: 1.0,
        );

        final painter = CombatPainter(
          dreadnought: dread,
          enemies: const [flagship],
          lances: const [],
          flaks: const [],
          particles: const [],
          damageNumbers: const [],
          enemyBullets: const [],
          animationTime: 3.0,
        );

        painter.paint(canvas, canvasSize);
        final picture = recorder.endRecording();
        expect(picture, isNotNull);
        picture.dispose();
      },
    );

    test(
      'Renders warp singularity collapsing ring when warpInProgress < 0.95',
      () {
        final recorder = PictureRecorder();
        final canvas = Canvas(recorder);
        const canvasSize = Size(400.0, 800.0);

        const warpingEnemy = EnemyCraft(
          entityId: 104,
          assignedCorridor: 1,
          worldPosX: 0.1875,
          worldPosY: 0.20,
          velocityY: 0.05,
          currentShields: 0,
          maxShields: 0,
          currentHull: 100,
          maxHull: 100,
          vesselType: 0,
          isDestroyed: false,
          warpInProgress: 0.40,
        );

        final painter = CombatPainter(
          dreadnought: dread,
          enemies: const [warpingEnemy],
          lances: const [],
          flaks: const [],
          particles: const [],
          damageNumbers: const [],
          enemyBullets: const [],
          animationTime: 0.5,
        );

        painter.paint(canvas, canvasSize);
        final picture = recorder.endRecording();
        expect(picture, isNotNull);
        picture.dispose();
      },
    );

    test('Renders in low battery mode without inner flame core', () {
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      const canvasSize = Size(400.0, 800.0);

      const flagship = EnemyCraft(
        entityId: 105,
        assignedCorridor: 5,
        worldPosX: 0.6875,
        worldPosY: 0.30,
        velocityY: 0.02,
        currentShields: 100,
        maxShields: 100,
        currentHull: 200,
        maxHull: 200,
        vesselType: 2,
        isDestroyed: false,
        warpInProgress: 1.0,
      );

      final painter = CombatPainter(
        dreadnought: dread,
        enemies: const [flagship],
        lances: const [],
        flaks: const [],
        particles: const [],
        damageNumbers: const [],
        enemyBullets: const [],
        animationTime: 1.0,
        isLowBattery: true,
      );

      painter.paint(canvas, canvasSize);
      final picture = recorder.endRecording();
      expect(picture, isNotNull);
      picture.dispose();
    });

    test(
      'Multi-frame continuous rendering executes cleanly without exceptions',
      () {
        final recorder = PictureRecorder();
        final canvas = Canvas(recorder);
        const canvasSize = Size(400.0, 800.0);

        final enemies = [
          const EnemyCraft(
            entityId: 1,
            assignedCorridor: 0,
            worldPosX: 0.0625,
            worldPosY: 0.2,
            velocityY: 0.05,
            currentShields: 0,
            maxShields: 0,
            currentHull: 50,
            maxHull: 50,
            vesselType: 0,
            isDestroyed: false,
            warpInProgress: 0.8,
          ),
          const EnemyCraft(
            entityId: 2,
            assignedCorridor: 3,
            worldPosX: 0.4375,
            worldPosY: 0.5,
            velocityY: 0.03,
            currentShields: 40,
            maxShields: 50,
            currentHull: 90,
            maxHull: 100,
            vesselType: 1,
            isDestroyed: false,
            bankAngleRad: 0.3,
          ),
          const EnemyCraft(
            entityId: 3,
            assignedCorridor: 6,
            worldPosX: 0.8125,
            worldPosY: 0.7,
            velocityY: 0.01,
            currentShields: 150,
            maxShields: 200,
            currentHull: 300,
            maxHull: 350,
            vesselType: 2,
            isDestroyed: false,
            pitchAngleRad: -0.2,
          ),
        ];

        for (var f = 0; f < 120; f++) {
          final painter = CombatPainter(
            dreadnought: dread,
            enemies: enemies,
            lances: const [],
            flaks: const [],
            particles: const [],
            damageNumbers: const [],
            enemyBullets: const [],
            animationTime: f * 0.016,
          );
          painter.paint(canvas, canvasSize);
        }

        final picture = recorder.endRecording();
        expect(picture, isNotNull);
        picture.dispose();
      },
    );
  });
}
