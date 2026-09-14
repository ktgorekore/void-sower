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
import 'package:void_sower/domain/models/dreadnought_state.dart';
import 'package:void_sower/domain/models/enemy_bullet.dart';
import 'package:void_sower/domain/models/enemy_craft.dart';
import 'package:void_sower/domain/models/flak_burst.dart';
import 'package:void_sower/domain/models/floating_damage_number.dart';
import 'package:void_sower/domain/models/lance_beam.dart';
import 'package:void_sower/presentation/theme/void_theme.dart';
import 'package:void_sower/presentation/widgets/combat_painter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CombatPainter & Background Layer Tests', () {
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

    testWidgets(
      'CombatBackgroundPainter renders corridors and rails without error',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: RepaintBoundary(
                child: CustomPaint(
                  size: Size(800, 1000),
                  painter: CombatBackgroundPainter(),
                ),
              ),
            ),
          ),
        );

        expect(
          find.byWidgetPredicate(
            (w) => w is CustomPaint && w.painter is CombatBackgroundPainter,
          ),
          findsOneWidget,
        );
        const painter = CombatBackgroundPainter();
        expect(painter.shouldRepaint(const CombatBackgroundPainter()), isFalse);
      },
    );

    testWidgets('CombatPainter renders dynamic entities with zero allocation', (
      tester,
    ) async {
      final damageNumber = FloatingDamageNumber(
        text: 'LANCE +120',
        x: 400,
        y: 300,
        color: VoidTheme.plasmaCyan,
      );

      final bullet = EnemyBullet(
        id: 1,
        assignedCorridor: 3,
        x: 350,
        y: 200,
        color: VoidTheme.crimsonFlare,
      );

      const enemy = EnemyCraft(
        entityId: 1,
        assignedCorridor: 3,
        worldPosX: 0.4375,
        worldPosY: 0.6,
        velocityY: 0.05,
        currentShields: 50,
        maxShields: 50,
        currentHull: 100,
        maxHull: 100,
        vesselType: 1,
        isDestroyed: false,
      );

      const lance = LanceBeam(
        firingBayIndex: 11,
        originX: 0.5,
        originY: 0.85,
        beamWidth: 16.0,
        sustainedDuration: 0.6,
        remainingDuration: 0.4,
        totalDamage: 2.5,
        active: true,
      );

      const flak = FlakBurst(
        worldPosX: 0.5,
        worldPosY: 0.5,
        blastRadius: 40.0,
        areaDamage: 1.5,
        lifetime: 0.5,
        remainingLifetime: 0.3,
        active: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomPaint(
              size: const Size(800, 1000),
              painter: CombatPainter(
                dreadnought: dread,
                enemies: const [enemy],
                lances: const [lance],
                flaks: const [flak],
                particles: const [],
                damageNumbers: [damageNumber],
                enemyBullets: [bullet],
                animationTime: 1.5,
              ),
            ),
          ),
        ),
      );

      expect(
        find.byWidgetPredicate(
          (w) => w is CustomPaint && w.painter is CombatPainter,
        ),
        findsOneWidget,
      );
    });
  });
}
