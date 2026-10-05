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

import 'dart:math' as math;
import 'package:flutter/foundation.dart';

import '../models/campaign_sector.dart';
import '../models/sector_combat_doctrine.dart';
import '../models/sector_progression_status.dart';
import '../models/sowing_mutation.dart';
import 'persistence_service.dart';

/// Service managing rogue-lite Void Incursion runs, escalating wave difficulty,
/// procedural sector parameters, and active Sowing Mutations.
class VoidIncursionService extends ChangeNotifier {
  VoidIncursionService._();
  static final VoidIncursionService instance = VoidIncursionService._();

  int _currentWave = 1;
  int _runScore = 0;
  bool _isInRun = false;
  final List<SowingMutation> _activeMutations = [];
  final math.Random _random = math.Random();

  /// Whether an incursion run is currently active.
  bool get isInRun => _isInRun;

  /// Current wave number (1-indexed).
  int get currentWave => _currentWave;

  /// Total cumulative score in the current incursion run.
  int get runScore => _runScore;

  /// Active mutations/relics collected during this run.
  List<SowingMutation> get activeMutations =>
      List.unmodifiable(_activeMutations);

  /// Threat tier based on wave progression (0: Patrol, 1: Monsoon, 2: Singularity).
  int get currentDifficultyTier {
    if (_currentWave <= 3) return 0;
    if (_currentWave <= 7) return 1;
    return 2;
  }

  // --- Aggregate Mutation Combat Modifiers ---

  /// Cumulative lance focal damage multiplier.
  double get totalLanceMultiplier =>
      _activeMutations.fold(1.0, (acc, m) => acc * m.lanceDamageMultiplier);

  /// Extra reserve cores granted at start of sorties.
  int get totalBonusCores =>
      _activeMutations.fold(0, (acc, m) => acc + m.bonusStartingCores);

  /// Extra plasma cores harvested on enemy defeat.
  int get totalCoreSiphonBonus =>
      _activeMutations.fold(0, (acc, m) => acc + m.coreSiphonBonus);

  /// Whether Nyumba bays double output and fire twin lances.
  bool get hasDoubleNyumba => _activeMutations.any((m) => m.doubleNyumbaOutput);

  /// Whether traversing a complete 16-bay lap plants flak mines.
  bool get hasFlakMineOnLap => _activeMutations.any((m) => m.flakMineOnLap);

  /// Whether particle lances pull adjacent enemies toward the beam axis.
  bool get hasGravitonPull => _activeMutations.any((m) => m.gravitonBeamPull);

  /// Whether sowing into inner bays mirrors charge to frontline batteries.
  bool get hasQuantumMirror =>
      _activeMutations.any((m) => m.quantumMirrorCharge);

  /// Total kinetic deflection shields available for dreadnought canopy.
  int get totalPhaseCanopyShields =>
      _activeMutations.fold(0, (acc, m) => acc + m.phaseCanopyShields);

  /// Commences a brand-new Void Incursion run.
  void startNewRun() {
    _currentWave = 1;
    _runScore = 0;
    _isInRun = true;
    _activeMutations.clear();
    notifyListeners();
  }

  /// Concludes the active run and records high-wave statistics.
  void endRun() {
    _isInRun = false;
    notifyListeners();
  }

  /// Generates a procedural [CampaignSector] configured for the current [wave].
  CampaignSector generateSectorForWave(int wave) {
    final tier = (wave <= 3) ? 0 : ((wave <= 7) ? 1 : 2);
    final quota = 16 + (wave * 6);
    final siphon = 1 + totalCoreSiphonBonus + (tier > 0 ? 1 : 0);

    SectorCombatDoctrine doctrine;
    if (wave % 3 == 1) {
      doctrine = SectorCombatDoctrine.standardOrbital;
    } else if (wave % 3 == 2) {
      doctrine = SectorCombatDoctrine.phantomDrift;
    } else {
      doctrine = SectorCombatDoctrine.voidSwarm;
    }

    return CampaignSector(
      sectorId: 9000 + wave,
      name: 'VOID INCURSION: WAVE $wave',
      region: 'Deep Void Abyss • Threat Tier ${tier + 1}',
      difficultyTier: tier,
      starsEarned: 0,
      bestScore: 0,
      isUnlocked: true,
      campaignId: 'void_incursion',
      doctrine: doctrine,
      reinforcementQuota: quota,
      coreSiphonPerKill: siphon,
    );
  }

  /// Selects 3 distinct random mutations from the catalog as post-wave options.
  List<SowingMutation> generateMutationChoices() {
    final available = SowingMutation.allCatalog
        .where((m) => !_activeMutations.any((active) => active.id == m.id))
        .toList();

    if (available.isEmpty) {
      return SowingMutation.allCatalog.take(3).toList();
    }

    available.shuffle(_random);
    return available.take(math.min(3, available.length)).toList();
  }

  /// Selects a mutation to equip for the current run.
  void selectMutation(SowingMutation mutation) {
    _activeMutations.add(mutation);
    notifyListeners();
  }

  /// Records wave victory and prepares for the subsequent wave.
  void recordWaveVictory(int waveScore) {
    _runScore += waveScore;
    _currentWave++;
    notifyListeners();
  }

  /// Resets incursion state for testing.
  @visibleForTesting
  void resetForTesting() {
    _currentWave = 1;
    _runScore = 0;
    _isInRun = false;
    _activeMutations.clear();
    notifyListeners();
  }
}
