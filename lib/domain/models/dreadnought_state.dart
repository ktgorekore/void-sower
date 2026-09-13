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

/// State representation of the Dreadnought flagship and simulation FSM.
class DreadnoughtState {
  const DreadnoughtState({
    required this.orbitalPositionX,
    required this.targetPositionX,
    required this.reserveCores,
    required this.boundaryLineY,
    required this.isCascading,
    required this.totalScore,
    required this.currentSimState,
    required this.coresUsed,
  });

  final double orbitalPositionX;
  final double targetPositionX;
  final int reserveCores;
  final double boundaryLineY;
  final bool isCascading;
  final int totalScore;
  final int currentSimState; // 0..8 (OrbitalIdle to GameOver)
  final int coresUsed;

  bool get isVictory => currentSimState == 7;
  bool get isGameOver => currentSimState == 8;
  bool get isIdle => currentSimState == 0;
}
