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

import 'package:flutter_test/flutter_test.dart';
import 'package:void_sower/domain/models/dreadnought_state.dart';
import 'package:void_sower/domain/models/enemy_craft.dart';
import 'package:void_sower/engine/mock_void_sower_engine.dart';
import 'package:void_sower/presentation/controllers/tactical_solver_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TacticalSolverController Optimization & Pacing Tests', () {
    late MockVoidSowerEngine engine;

    setUp(() {
      engine = MockVoidSowerEngine();
      engine.initialize(startingCores: 28, boundaryY: 0.15);
    });

    DreadnoughtState createDreadnought({
      int reserveCores = 28,
      bool isCascading = false,
      int currentSimState = 0,
    }) {
      return DreadnoughtState(
        orbitalPositionX: 0.5,
        targetPositionX: 0.5,
        reserveCores: reserveCores,
        boundaryLineY: 0.15,
        isCascading: isCascading,
        totalScore: 0,
        currentSimState: currentSimState,
        coresUsed: 0,
      );
    }

    EnemyCraft createEnemy({
      int id = 1,
      int corridor = 3,
      double posY = 0.5,
      double hull = 100,
      bool isDestroyed = false,
    }) {
      return EnemyCraft(
        entityId: id,
        assignedCorridor: corridor,
        worldPosX: (corridor + 0.5) / 8.0,
        worldPosY: posY,
        velocityY: 0.05,
        currentShields: 0,
        maxShields: 0,
        currentHull: hull,
        maxHull: 100,
        vesselType: 0,
        isDestroyed: isDestroyed,
      );
    }

    test('Does not select moves when reserveCores is zero', () {
      bool moveCalled = false;
      final controller = TacticalSolverController(
        engine: engine,
        onMoveSelected: (bay, dir, x) {
          moveCalled = true;
        },
      );

      final dread = createDreadnought(reserveCores: 0);
      controller.update(
        dt: 0.016,
        dreadnought: dread,
        bays: engine.getBays(),
        enemies: [createEnemy()],
      );

      expect(moveCalled, isFalse);
    });

    test('Does not select moves when cascading or not idle', () {
      bool moveCalled = false;
      final controller = TacticalSolverController(
        engine: engine,
        onMoveSelected: (bay, dir, x) {
          moveCalled = true;
        },
      );

      // Cascading
      controller.update(
        dt: 0.016,
        dreadnought: createDreadnought(isCascading: true),
        bays: engine.getBays(),
        enemies: [createEnemy()],
      );
      expect(moveCalled, isFalse);

      // Not idle (sim state 1 = SowingActive)
      controller.update(
        dt: 0.016,
        dreadnought: createDreadnought(currentSimState: 1),
        bays: engine.getBays(),
        enemies: [createEnemy()],
      );
      expect(moveCalled, isFalse);
    });

    test('Does not select moves when all enemies are destroyed', () {
      bool moveCalled = false;
      final controller = TacticalSolverController(
        engine: engine,
        onMoveSelected: (bay, dir, x) {
          moveCalled = true;
        },
      );

      controller.update(
        dt: 0.016,
        dreadnought: createDreadnought(),
        bays: engine.getBays(),
        enemies: [createEnemy(isDestroyed: true, hull: 0)],
      );
      expect(moveCalled, isFalse);
    });

    test(
      'Adaptive Pacing: Critical proximity triggers 0.16s emergency cooldown',
      () {
        int? selectedBay;
        int? selectedDir;
        double? selectedTargetX;

        final controller = TacticalSolverController(
          engine: engine,
          onMoveSelected: (bay, dir, x) {
            selectedBay = bay;
            selectedDir = dir;
            selectedTargetX = x;
          },
        );

        // Enemy dangerously close: Y = 0.25 (dist = 0.10 < 0.25)
        controller.update(
          dt: 0.016,
          dreadnought: createDreadnought(),
          bays: engine.getBays(),
          enemies: [createEnemy(corridor: 2, posY: 0.25)],
        );

        expect(selectedBay, isNotNull);
        expect(selectedDir, isNotNull);
        expect(selectedTargetX, isNotNull);
        expect(controller.cooldown, closeTo(0.16, 0.001));
      },
    );

    test('Adaptive Pacing: Mid-range proximity sets 0.32s cooldown', () {
      final controller = TacticalSolverController(
        engine: engine,
        onMoveSelected: (bay, dir, x) {},
      );

      // Enemy mid-range: Y = 0.55 (dist = 0.40 < 0.50)
      controller.update(
        dt: 0.016,
        dreadnought: createDreadnought(),
        bays: engine.getBays(),
        enemies: [createEnemy(corridor: 5, posY: 0.55)],
      );

      expect(controller.cooldown, closeTo(0.32, 0.001));
    });

    test('Adaptive Pacing: Long range sets 0.55s cooldown', () {
      final controller = TacticalSolverController(
        engine: engine,
        onMoveSelected: (bay, dir, x) {},
      );

      // Enemy long range: Y = 0.90 (dist = 0.75 >= 0.50)
      controller.update(
        dt: 0.016,
        dreadnought: createDreadnought(),
        bays: engine.getBays(),
        enemies: [createEnemy(corridor: 5, posY: 0.90)],
      );

      expect(controller.cooldown, closeTo(0.55, 0.001));
    });
  });
}
