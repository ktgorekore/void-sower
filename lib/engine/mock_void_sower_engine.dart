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

import '../domain/models/bay_state.dart';
import '../domain/models/dreadnought_state.dart';
import '../domain/models/enemy_craft.dart';
import '../domain/models/flak_burst.dart';
import '../domain/models/lance_beam.dart';
import '../domain/models/prediction_result.dart';
import '../domain/services/game_engine_interface.dart';

/// Pure Dart mock implementation of [IVoidSowerEngine] for deterministic unit and widget tests.
class MockVoidSowerEngine implements IVoidSowerEngine {
  MockVoidSowerEngine() {
    _initBays();
  }

  int _reserveCores = 32;
  double _boundaryY = 800.0;
  double _orbitalX = 0.0;
  double _targetX = 0.0;
  int _score = 0;
  int _coresUsed = 0;
  int _simState = 0;
  bool _isCascading = false;

  final List<int> _bayCharges = List<int>.filled(16, 2);
  final List<EnemyCraft> _enemies = <EnemyCraft>[];
  final List<LanceBeam> _lances = <LanceBeam>[];
  final List<FlakBurst> _flaks = <FlakBurst>[];
  bool _lateralDrift = false;
  double _elapsedDriftTime = 0.0;

  void _initBays() {
    for (var i = 0; i < 16; i++) {
      _bayCharges[i] = 2;
    }
  }

  @override
  void initialize({int startingCores = 32, double boundaryY = 0.15}) {
    _reserveCores = startingCores;
    _boundaryY = boundaryY;
    _orbitalX = 0.4375;
    _targetX = 0.4375;
    _score = 0;
    _coresUsed = 0;
    _simState = 0;
    _isCascading = false;
    _lateralDrift = false;
    _elapsedDriftTime = 0.0;
    _initBays();
    _enemies.clear();
    _lances.clear();
    _flaks.clear();
  }

  @override
  int generateWave({
    int difficulty = 0,
    int randomSeed = 42,
    int coreBudget = 16,
    double initialVelocityY = 0.025,
  }) {
    _enemies.clear();
    final count = (difficulty + 1) * 4;
    final speed = initialVelocityY <= 1.0 ? initialVelocityY : 0.025;
    for (var i = 0; i < count; i++) {
      final corridor = i % 8;
      _enemies.add(
        EnemyCraft(
          entityId: i + 1,
          assignedCorridor: corridor,
          worldPosX: (corridor + 0.5) / 8.0,
          worldPosY: 0.90 - (i * 0.05),
          velocityY: speed,
          currentShields: 50.0 + (difficulty * 25.0),
          maxShields: 50.0 + (difficulty * 25.0),
          currentHull: 100.0,
          maxHull: 100.0,
          vesselType: difficulty > 1 && i == count - 1 ? 2 : (i % 2),
          isDestroyed: false,
        ),
      );
    }
    return _enemies.length;
  }

  @override
  int injectCore(int bayIndex, int direction) {
    if (_reserveCores == 0) return 0;
    _reserveCores--;
    _coresUsed++;

    var currentBay = bayIndex & 0x0F;
    var carriedMass = _bayCharges[currentBay] + 1;
    _bayCharges[currentBay] = 0;

    var steps = 0;
    while (carriedMass > 0) {
      currentBay = (currentBay + direction + 16) & 0x0F;
      _bayCharges[currentBay]++;
      carriedMass--;
      steps++;
    }

    final finalMass = _bayCharges[currentBay];
    final isFrontline = currentBay >= 8;

    if (isFrontline && finalMass >= 1) {
      final corridor = currentBay - 8;
      final lanceX = (corridor + 0.5) / 8.0;
      _lances.add(
        LanceBeam(
          firingBayIndex: currentBay,
          originX: lanceX,
          originY: _boundaryY,
          beamWidth: 0.04 + (finalMass * 0.015),
          sustainedDuration: 0.5,
          remainingDuration: 0.5,
          totalDamage: finalMass * finalMass * 100.0,
          active: true,
        ),
      );
    }
    _score += (finalMass * finalMass * 10);

    return steps;
  }

  @override
  void slideDreadnought(double targetX) {
    _targetX = targetX;
  }

  @override
  void damageConduit(int bayIndex) {
    if (_reserveCores > 0) {
      _reserveCores--;
    }
    if (bayIndex >= 0 && bayIndex < 16) {
      _bayCharges[bayIndex] = 0;
    }
    if (_reserveCores == 0 && _bayCharges.every((c) => c == 0)) {
      _simState = 8; // GameOver
    }
  }

  @override
  void damageAtmosphere(int penalty) {
    _score = math.max(0, _score - penalty);
  }

  @override
  void grantCores(int count) {
    _reserveCores += count;
  }

  @override
  void setLateralDrift(bool enabled) {
    _lateralDrift = enabled;
  }

  @override
  bool spawnEnemy({
    required int corridor,
    required double worldPosY,
    required double velocityY,
    required double shields,
    required double hull,
    required int vesselType,
  }) {
    if (corridor < 0 || corridor >= 8) return false;
    final nextId = 10000 + _enemies.length;
    final corridorX = (corridor + 0.5) / 8.0;
    _enemies.add(
      EnemyCraft(
        entityId: nextId,
        assignedCorridor: corridor,
        worldPosX: corridorX,
        worldPosY: worldPosY,
        velocityY: velocityY,
        currentShields: shields,
        maxShields: shields,
        currentHull: hull,
        maxHull: hull,
        vesselType: vesselType,
        isDestroyed: false,
      ),
    );
    if (_simState == 7) {
      _simState = 0; // OrbitalIdle
    }
    return true;
  }

  @override
  void stepSimulation(double deltaTime) {
    // Interpolate dreadnought lateral position
    _orbitalX +=
        (_targetX - _orbitalX) *
        (1.0 - (0.5 * deltaTime * 20.0)).clamp(0.0, 1.0);

    if (_lateralDrift) {
      _elapsedDriftTime += deltaTime;
    }

    // Update enemies
    for (var i = 0; i < _enemies.length; i++) {
      final e = _enemies[i];
      if (e.isDestroyed) continue;

      final newY = e.worldPosY - (e.velocityY * deltaTime);
      if (newY <= _boundaryY) {
        _simState = 8; // GameOver
      }

      var posX = e.worldPosX;
      var corridor = e.assignedCorridor;
      if (_lateralDrift) {
        final phase = e.entityId * 1.57;
        final lateralVel = math.sin(_elapsedDriftTime * 2.8 + phase) * 0.28;
        posX = (posX + lateralVel * deltaTime).clamp(0.06, 0.94);
        corridor = (posX * 8.0).floor().clamp(0, 7);
      }

      // Lance collision check
      var hull = e.currentHull;
      var shields = e.currentShields;
      var destroyed = e.isDestroyed;

      for (final l in _lances) {
        if (!l.active) continue;
        if ((posX - l.originX).abs() < 0.08) {
          final dmg = l.totalDamage * deltaTime * 2.0;
          if (shields > 0) {
            shields = (shields - dmg).clamp(0.0, e.maxShields);
          } else {
            hull = (hull - dmg).clamp(0.0, e.maxHull);
          }
          if (hull <= 0) {
            destroyed = true;
            _flaks.add(
              FlakBurst(
                worldPosX: posX,
                worldPosY: newY,
                blastRadius: 0.15,
                areaDamage: 50.0,
                lifetime: 0.4,
                remainingLifetime: 0.4,
                active: true,
              ),
            );
          }
        }
      }

      _enemies[i] = EnemyCraft(
        entityId: e.entityId,
        assignedCorridor: corridor,
        worldPosX: posX,
        worldPosY: newY,
        velocityY: e.velocityY,
        currentShields: shields,
        maxShields: e.maxShields,
        currentHull: hull,
        maxHull: e.maxHull,
        vesselType: e.vesselType,
        isDestroyed: destroyed,
      );
    }

    final bool anyAlive = _enemies.any((e) => !e.isDestroyed);
    if (!anyAlive && _enemies.isNotEmpty) {
      _simState = 7; // Victory
    }

    // Update lances
    for (var i = _lances.length - 1; i >= 0; i--) {
      final l = _lances[i];
      final rem = l.remainingDuration - deltaTime;
      if (rem <= 0) {
        _lances.removeAt(i);
      } else {
        _lances[i] = LanceBeam(
          firingBayIndex: l.firingBayIndex,
          originX: l.originX,
          originY: l.originY,
          beamWidth: l.beamWidth,
          sustainedDuration: l.sustainedDuration,
          remainingDuration: rem,
          totalDamage: l.totalDamage,
          active: true,
        );
      }
    }

    // Update flaks
    for (var i = _flaks.length - 1; i >= 0; i--) {
      final f = _flaks[i];
      final rem = f.remainingLifetime - deltaTime;
      if (rem <= 0) {
        _flaks.removeAt(i);
      } else {
        _flaks[i] = FlakBurst(
          worldPosX: f.worldPosX,
          worldPosY: f.worldPosY,
          blastRadius: f.blastRadius,
          areaDamage: f.areaDamage,
          lifetime: f.lifetime,
          remainingLifetime: rem,
          active: true,
        );
      }
    }
  }

  @override
  PredictionResult predictSow(int startBay, int direction) {
    final carried = _bayCharges[startBay & 0x0F] + 1;
    final term = (startBay + (carried * direction) + 160) & 0x0F;
    final finalMass = _bayCharges[term] + 1;
    final isFrontline = term >= 8;

    return PredictionResult(
      terminalBay: term,
      terminalCorridor: isFrontline ? term - 8 : -1,
      finalMass: finalMass,
      predictedDamage: isFrontline
          ? finalMass * finalMass * 100.0 * _lanceAlphaMultiplier
          : 0.0,
      totalCascadeLaps: carried ~/ 16,
      triggersLance: isFrontline,
      triggersRelay: !isFrontline && finalMass >= 4,
    );
  }

  @override
  List<BayState> getBays() {
    final result = <BayState>[];
    for (var i = 0; i < 16; i++) {
      final isFrontline = i >= 8;
      result.add(
        BayState(
          bayIndex: i,
          tier: isFrontline ? 1 : 0,
          gridColumn: isFrontline ? (i - 8) : 0,
          chargeUnits: _bayCharges[i],
          radialPositionRad: (i / 16.0) * 6.2831853,
          isFrontline: isFrontline,
          isNyumba: i == 3 || i == 4,
          isKichwa: i == 8 || i == 15,
          isKimbi: i == 9 || i == 14,
        ),
      );
    }
    return result;
  }

  @override
  List<EnemyCraft> getEnemies() => List<EnemyCraft>.from(_enemies);

  @override
  List<LanceBeam> getLances() => List<LanceBeam>.from(_lances);

  @override
  List<FlakBurst> getFlaks() => List<FlakBurst>.from(_flaks);

  @override
  DreadnoughtState getDreadnoughtState() {
    return DreadnoughtState(
      orbitalPositionX: _orbitalX,
      targetPositionX: _targetX,
      reserveCores: _reserveCores,
      boundaryLineY: _boundaryY,
      isCascading: _isCascading,
      totalScore: _score,
      currentSimState: _simState,
      coresUsed: _coresUsed,
    );
  }

  @override
  void reset() {
    initialize(startingCores: 32, boundaryY: _boundaryY);
  }

  double _lanceAlphaMultiplier = 1.0;

  /// Exposes the current lance alpha multiplier for test verification.
  double get lanceAlphaMultiplier => _lanceAlphaMultiplier;

  @override
  void setLanceAlphaMultiplier(double multiplier) {
    _lanceAlphaMultiplier = multiplier > 0.0 ? multiplier : 1.0;
  }

  @override
  void restoreSnapshot({
    required List<int> bayCharges,
    required int reserveCores,
    required int totalScore,
  }) {
    for (var i = 0; i < 16 && i < bayCharges.length; i++) {
      _bayCharges[i] = bayCharges[i];
    }
    _reserveCores = reserveCores;
    _score = totalScore;
    _isCascading = false;
    _simState = 0;
    _lances.clear();
    _flaks.clear();
  }

  @override
  TacticalStepResult? solveTacticalStep() {
    int bestBay = 11;
    int bestDir = 1;
    double bestDmg = 0.0;
    for (var b = 0; b < 16; b++) {
      if (b < 8 && _bayCharges[b] == 0) continue;
      for (final d in [1, -1]) {
        final pred = predictSow(b, d);
        if (pred.predictedDamage > bestDmg) {
          bestDmg = pred.predictedDamage;
          bestBay = b;
          bestDir = d;
        }
      }
    }
    return TacticalStepResult(
      bayIndex: bestBay,
      direction: bestDir,
      confidence: 0.92,
      predictedDamage: bestDmg,
    );
  }

  /// Test-only hook to set an enemy's destroyed state directly.
  void setEnemyDestroyedForTesting(int entityId, bool destroyed) {
    for (var i = 0; i < _enemies.length; i++) {
      if (_enemies[i].entityId == entityId) {
        _enemies[i] = _enemies[i].copyWith(isDestroyed: destroyed);
        break;
      }
    }
  }

  @override
  void dispose() {
    _enemies.clear();
    _lances.clear();
    _flaks.clear();
  }
}
