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
import 'package:void_sower/domain/models/sowing_mutation.dart';
import 'package:void_sower/domain/services/void_incursion_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Void Incursion Rogue-Lite Service Tests', () {
    setUp(() {
      VoidIncursionService.instance.resetForTesting();
    });

    test('startNewRun initializes fresh run state with wave 1', () {
      final incursion = VoidIncursionService.instance;
      incursion.startNewRun();

      expect(incursion.isInRun, isTrue);
      expect(incursion.currentWave, equals(1));
      expect(incursion.runScore, equals(0));
      expect(incursion.activeMutations, isEmpty);
      expect(incursion.currentDifficultyTier, equals(0));
    });

    test('generateSectorForWave creates escalating difficulty parameters', () {
      final incursion = VoidIncursionService.instance;
      final wave1Sector = incursion.generateSectorForWave(1);
      final wave5Sector = incursion.generateSectorForWave(5);
      final wave10Sector = incursion.generateSectorForWave(10);

      expect(wave1Sector.difficultyTier, equals(0));
      expect(wave5Sector.difficultyTier, equals(1));
      expect(wave10Sector.difficultyTier, equals(2));

      expect(
        wave10Sector.reinforcementQuota,
        greaterThan(wave1Sector.reinforcementQuota),
      );
    });

    test('generateMutationChoices returns 3 distinct unequipped mutations', () {
      final incursion = VoidIncursionService.instance;
      incursion.startNewRun();

      final choices = incursion.generateMutationChoices();
      expect(choices.length, equals(3));
      expect(choices.toSet().length, equals(3)); // All distinct
    });

    test('selectMutation accumulates mutation modifiers correctly', () {
      final incursion = VoidIncursionService.instance;
      incursion.startNewRun();

      final nyumbaMutation = SowingMutation.allCatalog.firstWhere(
        (m) => m.id == 'overclocked_nyumba',
      );
      final focusMutation = SowingMutation.allCatalog.firstWhere(
        (m) => m.id == 'quadratic_focus',
      );

      incursion.selectMutation(nyumbaMutation);
      expect(incursion.hasDoubleNyumba, isTrue);

      incursion.selectMutation(focusMutation);
      expect(incursion.totalLanceMultiplier, closeTo(1.35, 0.01));
      expect(incursion.activeMutations.length, equals(2));
    });

    test('recordWaveVictory advances wave and accumulates run score', () {
      final incursion = VoidIncursionService.instance;
      incursion.startNewRun();

      incursion.recordWaveVictory(15000);
      expect(incursion.currentWave, equals(2));
      expect(incursion.runScore, equals(15000));

      incursion.recordWaveVictory(25000);
      expect(incursion.currentWave, equals(3));
      expect(incursion.runScore, equals(40000));
    });

    test('endRun terminates active incursion run', () {
      final incursion = VoidIncursionService.instance;
      incursion.startNewRun();
      expect(incursion.isInRun, isTrue);

      incursion.endRun();
      expect(incursion.isInRun, isFalse);
    });
  });
}
