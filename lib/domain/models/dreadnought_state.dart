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

/// Tactical quest types for deep-space sorties.
enum QuestType {
  none(0, 'Deep Space Recon', 'Standard sector defense'),
  outpostReclamation(1, 'Outpost Reclamation', 'Secure and hold forward orbital outpost'),
  convoyEscort(2, 'Convoy Escort', 'Shield resource cargo hulls from raiders'),
  capitalSiege(3, 'Capital Dreadnought Siege', 'Penetrate and collapse flagship shielding'),
  warpRiftCollapse(4, 'Warp Rift Collapse', 'Discharge resonance pulses into spatial fissures'),
  asteroidProspecting(5, 'Asteroid Prospecting', 'Extract crystalline fuel cores under fire');

  const QuestType(this.id, this.title, this.description);
  final int id;
  final String title;
  final String description;

  static QuestType fromId(int id) {
    return QuestType.values.firstWhere(
      (q) => q.id == id,
      orElse: () => QuestType.none,
    );
  }
}

/// Tactical quest progress status.
enum QuestStatus {
  inactive(0, 'Standby'),
  inProgress(1, 'Active'),
  completed(2, 'Victorious'),
  failed(3, 'Failed');

  const QuestStatus(this.id, this.label);
  final int id;
  final String label;

  static QuestStatus fromId(int id) {
    return QuestStatus.values.firstWhere(
      (s) => s.id == id,
      orElse: () => QuestStatus.inactive,
    );
  }
}

/// State representation of the Dreadnought flagship and simulation FSM.
class DreadnoughtState {
  const DreadnoughtState({
    required this.orbitalPositionX,
    required this.targetPositionX,
    this.orbitalPositionY = 0.20,
    this.targetPositionY = 0.20,
    required this.boundaryLineY,
    this.proximityMultiplier = 1.0,
    required this.reserveCores,
    required this.totalScore,
    required this.coresUsed,
    this.questProgress = 0.0,
    required this.isCascading,
    required this.currentSimState,
    this.activeQuestType = 0,
    this.questStatus = 0,
  });

  final double orbitalPositionX;
  final double targetPositionX;
  final double orbitalPositionY;
  final double targetPositionY;
  final double boundaryLineY;
  final double proximityMultiplier;
  final int reserveCores;
  final int totalScore;
  final int coresUsed;
  final double questProgress;
  final bool isCascading;
  final int currentSimState; // 0..8 (OrbitalIdle to GameOver)
  final int activeQuestType;
  final int questStatus;

  bool get isVictory => currentSimState == 7;
  bool get isGameOver => currentSimState == 8;
  bool get isIdle => currentSimState == 0;

  QuestType get quest => QuestType.fromId(activeQuestType);
  QuestStatus get status => QuestStatus.fromId(questStatus);

  /// Creates a copy of this state with optional updated parameters.
  DreadnoughtState copyWith({
    double? orbitalPositionX,
    double? targetPositionX,
    double? orbitalPositionY,
    double? targetPositionY,
    double? boundaryLineY,
    double? proximityMultiplier,
    int? reserveCores,
    int? totalScore,
    int? coresUsed,
    double? questProgress,
    bool? isCascading,
    int? currentSimState,
    int? activeQuestType,
    int? questStatus,
  }) {
    return DreadnoughtState(
      orbitalPositionX: orbitalPositionX ?? this.orbitalPositionX,
      targetPositionX: targetPositionX ?? this.targetPositionX,
      orbitalPositionY: orbitalPositionY ?? this.orbitalPositionY,
      targetPositionY: targetPositionY ?? this.targetPositionY,
      boundaryLineY: boundaryLineY ?? this.boundaryLineY,
      proximityMultiplier: proximityMultiplier ?? this.proximityMultiplier,
      reserveCores: reserveCores ?? this.reserveCores,
      totalScore: totalScore ?? this.totalScore,
      coresUsed: coresUsed ?? this.coresUsed,
      questProgress: questProgress ?? this.questProgress,
      isCascading: isCascading ?? this.isCascading,
      currentSimState: currentSimState ?? this.currentSimState,
      activeQuestType: activeQuestType ?? this.activeQuestType,
      questStatus: questStatus ?? this.questStatus,
    );
  }
}
