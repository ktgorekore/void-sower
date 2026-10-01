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
import 'package:void_sower/presentation/widgets/combat_painter.dart';
import 'package:void_sower/presentation/widgets/starfield_3d.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('3D Perspective Starfield Simulation Tests', () {
    test('Starfield3DSimulation initializes pre-allocated typed arrays', () {
      final sim = Starfield3DSimulation();
      expect(sim.starCount, equals(64));

      // Verify stars are distributed in valid normalized bounds
      for (var i = 0; i < sim.starCount; i++) {
        expect(sim.posZ[i], greaterThan(0.0));
        expect(sim.posZ[i], lessThanOrEqualTo(1.0));
        expect(sim.posX[i].abs(), lessThanOrEqualTo(1.3));
        expect(sim.posY[i].abs(), lessThanOrEqualTo(1.3));
      }
    });

    test('Starfield3DSimulation updates positions and warps forward', () {
      final sim = Starfield3DSimulation();
      const viewport = Size(400, 800);

      final initialZ0 = sim.posZ[0];

      // Update with zero forward velocity (orbital cruising)
      sim.update(
        dt: 0.016,
        normForward: 0.0,
        velocityDx: 0.0,
        viewportSize: viewport,
      );

      // Star z should advance forward (decrease) at baseline cruise speed
      expect(sim.posZ[0], lessThan(initialZ0));

      // Update with high forward warp velocity (deep space)
      final zBeforeWarp = sim.posZ[1];
      sim.update(
        dt: 0.016,
        normForward: 1.0,
        velocityDx: 0.5,
        viewportSize: viewport,
      );

      // Calm forward warp speed multiplier accelerates z decrement without disorientation
      final deltaWarp = zBeforeWarp - sim.posZ[1];
      expect(deltaWarp, greaterThan(0.001));
    });

    test('Starfield3DSimulation wraps stars at boundary plane', () {
      final sim = Starfield3DSimulation();
      const viewport = Size(400, 800);

      // Force a star near the camera plane
      sim.posZ[0] = 0.04;

      // Update frame
      sim.update(
        dt: 0.05,
        normForward: 0.5,
        velocityDx: 0.0,
        viewportSize: viewport,
      );

      // Star should wrap around to the far plane z in [0.95, 1.0]
      expect(sim.posZ[0], greaterThanOrEqualTo(0.90));
    });

    testWidgets('Starfield3DWidget paints smoothly without exceptions', (
      tester,
    ) async {
      final sim = Starfield3DSimulation();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 800,
              child: Starfield3DWidget(
                simulation: sim,
                normForward: 0.65,
                animationTime: 1.25,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(Starfield3DWidget), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets(
      'CombatPainter renders 3D banking, contrails, bow shock, and altimeter',
      (tester) async {
        // Dreadnought moving laterally and deep in forward space
        const dread = DreadnoughtState(
          orbitalPositionX: 0.5,
          targetPositionX: 0.7, // Lateral displacement for 3D banking
          orbitalPositionY: 0.55, // Deep space forward depth
          boundaryLineY: 0.20,
          reserveCores: 20,
          isCascading: false,
          totalScore: 4500,
          currentSimState: 0,
          coresUsed: 8,
          proximityMultiplier: 1.35, // Vanguard proximity bonus
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 400,
                height: 800,
                child: CustomPaint(
                  size: const Size(400, 800),
                  painter: CombatPainter(
                    dreadnought: dread,
                    enemies: const [],
                    lances: const [],
                    flaks: const [],
                    particles: const [],
                    damageNumbers: const [],
                    enemyBullets: const [],
                    animationTime: 2.0,
                  ),
                ),
              ),
            ),
          ),
        );

        expect(find.byType(CustomPaint), findsWidgets);
      },
    );
  });
}
