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
import 'package:void_sower/engine/mock_void_sower_engine.dart';
import 'package:void_sower/presentation/controllers/combat_coordinator.dart';
import 'package:void_sower/presentation/widgets/combat_painter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Deep Space Flight & Tactical Quest Mechanics Tests', () {
    test('DreadnoughtState models 2D flight and quest telemetry', () {
      const state = DreadnoughtState(
        orbitalPositionX: 0.5,
        targetPositionX: 0.5,
        orbitalPositionY: 0.425,
        targetPositionY: 0.425,
        boundaryLineY: 0.20,
        proximityMultiplier: 1.30,
        reserveCores: 24,
        totalScore: 12000,
        coresUsed: 8,
        questProgress: 0.5,
        isCascading: false,
        currentSimState: 0,
        activeQuestType: 1,
        questStatus: 1,
      );

      expect(state.orbitalPositionY, equals(0.425));
      expect(state.proximityMultiplier, equals(1.30));
      expect(state.quest, equals(QuestType.outpostReclamation));
      expect(state.status, equals(QuestStatus.inProgress));
      expect(state.quest.title, equals('Outpost Reclamation'));

      final updated = state.copyWith(
        orbitalPositionY: 0.65,
        proximityMultiplier: 1.60,
        questProgress: 1.0,
        questStatus: 2,
      );

      expect(updated.orbitalPositionY, equals(0.65));
      expect(updated.proximityMultiplier, equals(1.60));
      expect(updated.questProgress, equals(1.0));
      expect(updated.status, equals(QuestStatus.completed));
    });

    test(
      'MockVoidSowerEngine smoothly interpolates 2D space flight and scales proximity',
      () {
        final engine = MockVoidSowerEngine();
        engine.initialize(startingCores: 32, boundaryY: 0.20);

        var dread = engine.getDreadnoughtState();
        expect(dread.orbitalPositionY, equals(0.20));
        expect(dread.proximityMultiplier, equals(1.0));

        // Push forward into deep space
        engine.setDreadnoughtTarget(0.5, 0.65);
        expect(engine.getDreadnoughtState().targetPositionY, equals(0.65));

        // Step simulation multiple frames to allow smooth interpolation
        for (var i = 0; i < 30; i++) {
          engine.stepSimulation(1.0 / 60.0);
        }

        dread = engine.getDreadnoughtState();
        expect(dread.orbitalPositionY, greaterThan(0.50));
        expect(dread.proximityMultiplier, greaterThan(1.40));

        // Clamping bounds above 0.65
        engine.setDreadnoughtTarget(0.5, 0.95);
        expect(engine.getDreadnoughtState().targetPositionY, equals(0.65));

        // Clamping bounds below boundaryLineY (0.20)
        engine.setDreadnoughtTarget(0.5, 0.05);
        expect(engine.getDreadnoughtState().targetPositionY, equals(0.20));
      },
    );

    test('MockVoidSowerEngine tactical quest lifecycle updates', () {
      final engine = MockVoidSowerEngine();
      engine.initialize(startingCores: 32, boundaryY: 0.20);

      expect(engine.getDreadnoughtState().activeQuestType, equals(0));
      expect(engine.getDreadnoughtState().questStatus, equals(0));

      // Activate Outpost Reclamation (id = 1)
      engine.setActiveQuest(1);
      var dread = engine.getDreadnoughtState();
      expect(dread.activeQuestType, equals(1));
      expect(dread.questStatus, equals(1)); // InProgress

      // Update progress
      engine.updateQuest(0.85, 1);
      dread = engine.getDreadnoughtState();
      expect(dread.questProgress, equals(0.85));
      expect(dread.status, equals(QuestStatus.inProgress));

      // Complete quest
      engine.updateQuest(1.0, 2);
      dread = engine.getDreadnoughtState();
      expect(dread.questProgress, equals(1.0));
      expect(dread.status, equals(QuestStatus.completed));
    });

    test(
      'CombatCoordinator steers 2D position and updates tactical quests',
      () {
        final engine = MockVoidSowerEngine();
        final coordinator = CombatCoordinator(engine: engine);
        coordinator.initialize(boundaryY: 0.20);

        expect(coordinator.dreadnought.orbitalPositionY, equals(0.20));

        // Steer dreadnought across space
        coordinator.slidePosition2D(0.75, 0.50);
        expect(
          coordinator.dreadnought.targetPositionX,
          equals(0.8125),
        ); // Snapped corridor center
        expect(coordinator.dreadnought.targetPositionY, equals(0.50));

        // Activate Convoy Escort quest
        coordinator.setActiveQuest(2);
        expect(coordinator.dreadnought.activeQuestType, equals(2));
        expect(coordinator.dreadnought.quest, equals(QuestType.convoyEscort));

        // Update progress
        coordinator.updateQuest(0.60, 1);
        expect(coordinator.dreadnought.questProgress, equals(0.60));
        expect(coordinator.dreadnought.status, equals(QuestStatus.inProgress));
      },
    );

    testWidgets(
      'CombatPainter renders forward vanguard position and proximity badge',
      (tester) async {
        const forwardDread = DreadnoughtState(
          orbitalPositionX: 0.5,
          targetPositionX: 0.5,
          orbitalPositionY: 0.65,
          targetPositionY: 0.65,
          boundaryLineY: 0.20,
          proximityMultiplier: 1.60,
          reserveCores: 24,
          totalScore: 10000,
          coresUsed: 5,
          questProgress: 0.75,
          isCascading: false,
          currentSimState: 0,
          activeQuestType: 1,
          questStatus: 1,
        );

        final painter = CombatPainter(
          dreadnought: forwardDread,
          enemies: const [],
          lances: const [],
          flaks: const [],
          particles: const [],
          animationTime: 1.5,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CustomPaint(size: const Size(400, 800), painter: painter),
            ),
          ),
        );

        expect(find.byType(CustomPaint), findsWidgets);
      },
    );
  });
}
