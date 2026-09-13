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

  void _initBays() {
    for (var i = 0; i < 16; i++) {
      _bayCharges[i] = 2;
    }
  }

  @override
  void initialize({int startingCores = 32, double boundaryY = 0.15}) {
    _reserveCores = startingCores;
    _boundaryY = boundaryY;
    _orbitalX = 0.5;
    _targetX = 0.5;
    _score = 0;
    _coresUsed = 0;
    _simState = 0;
    _isCascading = false;
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
    final isFrontline = currentBay < 8;

    if (isFrontline && finalMass >= 4) {
      final corridor = currentBay < 8 ? currentBay : 15 - currentBay;
      final lanceX = (corridor + 0.5) / 8.0;
      _lances.add(
        LanceBeam(
          firingBayIndex: currentBay,
          originX: lanceX,
          originY: _boundaryY,
          beamWidth: 0.04 + (finalMass * 0.015),
          sustainedDuration: 0.5,
          remainingDuration: 0.5,
          totalDamage: finalMass * finalMass * 15.0,
          active: true,
        ),
      );
      _score += (finalMass * finalMass * 10);
    }

    return steps;
  }

  @override
  void slideDreadnought(double targetX) {
    _targetX = targetX;
  }

  @override
  void stepSimulation(double deltaTime) {
    // Interpolate dreadnought lateral position
    _orbitalX +=
        (_targetX - _orbitalX) *
        (1.0 - (0.5 * deltaTime * 20.0)).clamp(0.0, 1.0);

    // Update enemies
    var destroyedCount = 0;
    for (var i = 0; i < _enemies.length; i++) {
      final e = _enemies[i];
      if (e.isDestroyed) continue;

      final newY = e.worldPosY - (e.velocityY * deltaTime);
      if (newY <= _boundaryY) {
        _simState = 8; // GameOver
      }

      // Lance collision check
      var hull = e.currentHull;
      var shields = e.currentShields;
      var destroyed = e.isDestroyed;

      for (final l in _lances) {
        if (!l.active) continue;
        if ((e.worldPosX - l.originX).abs() < 0.08) {
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
                worldPosX: e.worldPosX,
                worldPosY: e.worldPosY,
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

      if (destroyed) {
        destroyedCount++;
      }

      _enemies[i] = EnemyCraft(
        entityId: e.entityId,
        assignedCorridor: e.assignedCorridor,
        worldPosX: e.worldPosX,
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

    if (destroyedCount == _enemies.length && _enemies.isNotEmpty) {
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
    final isFrontline = term < 8;

    return PredictionResult(
      terminalBay: term,
      terminalCorridor: isFrontline ? term : -1,
      finalMass: finalMass,
      predictedDamage: isFrontline && finalMass >= 4
          ? finalMass * finalMass * 15.0
          : 0.0,
      totalCascadeLaps: carried ~/ 16,
      triggersLance: isFrontline && finalMass >= 4,
      triggersRelay: !isFrontline && finalMass >= 6,
    );
  }

  @override
  List<BayState> getBays() {
    final result = <BayState>[];
    for (var i = 0; i < 16; i++) {
      final isFrontline = i < 8;
      result.add(
        BayState(
          bayIndex: i,
          tier: isFrontline ? 1 : 0,
          gridColumn: isFrontline ? i : 15 - i,
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

  @override
  void dispose() {
    _enemies.clear();
    _lances.clear();
    _flaks.clear();
  }
}
