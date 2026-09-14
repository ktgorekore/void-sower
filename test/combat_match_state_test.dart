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
import 'package:void_sower/domain/state/combat_match_state.dart';

void main() {
  group('CombatMatchState FSM Tests', () {
    test('Initial factory defaults to activeCombat when tutorial false', () {
      final state = CombatMatchState.initial(startWithTutorial: false);
      expect(state.status, equals(CombatMatchStatus.activeCombat));
      expect(state.canReceiveInput, isTrue);
      expect(state.isTerminal, isFalse);
      expect(state.isAutoSolving, isFalse);
    });

    test('Initial factory starts with briefing when tutorial true', () {
      final state = CombatMatchState.initial(startWithTutorial: true);
      expect(state.status, equals(CombatMatchStatus.briefing));
      expect(state.canReceiveInput, isFalse);
      expect(state.isTerminal, isFalse);
    });

    test('Input is blocked during sowingSequence and autoSolving', () {
      var state = const CombatMatchState(
        status: CombatMatchStatus.activeCombat,
      );
      expect(state.canReceiveInput, isTrue);

      state = state.copyWith(status: CombatMatchStatus.sowingSequence);
      expect(state.canReceiveInput, isFalse);

      state = state.copyWith(
        status: CombatMatchStatus.activeCombat,
        isAutoSolving: true,
      );
      expect(state.canReceiveInput, isFalse);
    });

    test('isTerminal is true only for victory and defeat', () {
      expect(
        const CombatMatchState(
          status: CombatMatchStatus.activeCombat,
        ).isTerminal,
        isFalse,
      );
      expect(
        const CombatMatchState(status: CombatMatchStatus.victory).isTerminal,
        isTrue,
      );
      expect(
        const CombatMatchState(status: CombatMatchStatus.defeat).isTerminal,
        isTrue,
      );
    });

    test(
      'copyWith properly clears or retains selectedBay and activeSowBay',
      () {
        const state = CombatMatchState(
          status: CombatMatchStatus.activeCombat,
          selectedBay: 8,
          activeSowBay: 10,
        );

        final cleared = state.copyWith(
          clearSelectedBay: true,
          clearActiveSowBay: true,
        );
        expect(cleared.selectedBay, isNull);
        expect(cleared.activeSowBay, isNull);

        final retained = state.copyWith(
          status: CombatMatchStatus.sowingSequence,
        );
        expect(retained.selectedBay, equals(8));
        expect(retained.activeSowBay, equals(10));
      },
    );
  });
}
