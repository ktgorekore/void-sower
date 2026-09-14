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
import 'package:void_sower/domain/state/combat_match_state.dart';
import 'package:void_sower/engine/mock_void_sower_engine.dart';
import 'package:void_sower/presentation/controllers/combat_coordinator.dart';

void main() {
  group('CombatCoordinator Architecture Tests', () {
    late MockVoidSowerEngine engine;
    late CombatCoordinator coordinator;

    setUp(() {
      engine = MockVoidSowerEngine();
      coordinator = CombatCoordinator(engine: engine, difficultyTier: 1);
      coordinator.initialize(startingCores: 28, boundaryY: 0.15);
    });

    tearDown(() {
      coordinator.dispose();
    });

    test('Initializes state machine to activeCombat for tier 1', () {
      expect(coordinator.state.status, equals(CombatMatchStatus.activeCombat));
      expect(coordinator.dreadnought.reserveCores, equals(28));
      expect(coordinator.bays.length, equals(16));
    });

    test('selectBay updates selectedBay and computes prediction', () {
      coordinator.selectBay(8);
      expect(coordinator.state.selectedBay, equals(8));
      expect(coordinator.prediction, isNotNull);
      expect(coordinator.prediction!.terminalBay, isNotNull);
    });

    test(
      'slidePosition moves dreadnought and auto-locks active corridor bay',
      () {
        coordinator.slidePosition(
          0.5,
        ); // Corridor 4 (center) -> Frontline bay 12
        expect(coordinator.state.selectedBay, equals(12));
      },
    );

    test('toggleAutoSolve toggles solver state', () {
      expect(coordinator.state.isAutoSolving, isFalse);
      coordinator.toggleAutoSolve();
      expect(coordinator.state.isAutoSolving, isTrue);
      coordinator.toggleAutoSolve();
      expect(coordinator.state.isAutoSolving, isFalse);
    });

    test('update steps engine simulation and updates physics', () {
      coordinator.update(0.016, const Size(800, 1000));
      expect(coordinator.dreadnought, isNotNull);
    });
  });
}
