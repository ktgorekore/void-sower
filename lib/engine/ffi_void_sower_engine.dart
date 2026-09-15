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

import 'dart:ffi' as ffi;
import 'dart:io';

import 'package:ffi/ffi.dart';

import '../domain/models/bay_state.dart';
import '../domain/models/dreadnought_state.dart';
import '../domain/models/enemy_craft.dart';
import '../domain/models/flak_burst.dart';
import '../domain/models/lance_beam.dart';
import '../domain/models/prediction_result.dart';
import '../domain/services/game_engine_interface.dart';
import 'void_sower_bindings_generated.dart';

/// Native C++ FFI implementation of [IVoidSowerEngine].
///
/// Pre-allocates native struct memory pointers via [calloc] once upon initialization
/// to eliminate per-frame garbage collection pressure on the 60 Hz simulation hot path.
class FfiVoidSowerEngine implements IVoidSowerEngine {
  FfiVoidSowerEngine({VoidSowerBindings? bindings})
    : _bindings = bindings ?? VoidSowerBindings(_loadNativeLibrary()) {
    const vlogLevel = int.fromEnvironment('VLOG_LEVEL', defaultValue: 0);
    if (vlogLevel > 0) {
      _bindings.void_sower_set_vlog_level(vlogLevel);
    }
    _cachedBaysPtr = calloc<VoidSowerBayFFI>(kMaxBays);
    _cachedEnemiesPtr = calloc<VoidSowerEnemyFFI>(kMaxEnemies);
    _cachedLancesPtr = calloc<VoidSowerLanceFFI>(kMaxLances);
    _cachedFlaksPtr = calloc<VoidSowerFlakFFI>(kMaxFlaks);
    _cachedDreadnoughtPtr = calloc<VoidSowerDreadnoughtFFI>();
    _cachedPredictionPtr = calloc<VoidSowerPredictionFFI>();
    _cachedWaveConfigPtr = calloc<VoidSowerWaveConfigFFI>();
  }

  static const int kMaxBays = 16;
  static const int kMaxEnemies = 64;
  static const int kMaxLances = 16;
  static const int kMaxFlaks = 32;

  final VoidSowerBindings _bindings;

  late final ffi.Pointer<VoidSowerBayFFI> _cachedBaysPtr;
  late final ffi.Pointer<VoidSowerEnemyFFI> _cachedEnemiesPtr;
  late final ffi.Pointer<VoidSowerLanceFFI> _cachedLancesPtr;
  late final ffi.Pointer<VoidSowerFlakFFI> _cachedFlaksPtr;
  late final ffi.Pointer<VoidSowerDreadnoughtFFI> _cachedDreadnoughtPtr;
  late final ffi.Pointer<VoidSowerPredictionFFI> _cachedPredictionPtr;
  late final ffi.Pointer<VoidSowerWaveConfigFFI> _cachedWaveConfigPtr;

  final List<BayState> _cachedBaysList = List<BayState>.generate(
    kMaxBays,
    (i) => BayState(
      bayIndex: i,
      tier: i >= 8 ? 1 : 0,
      gridColumn: i >= 8 ? i - 8 : 0,
      chargeUnits: 0,
      radialPositionRad: 0.0,
      isFrontline: i >= 8,
      isNyumba: i == 3 || i == 4,
      isKichwa: i == 8 || i == 15,
      isKimbi: i == 9 || i == 14,
    ),
  );
  final List<EnemyCraft> _cachedEnemiesList = [];
  final List<LanceBeam> _cachedLancesList = [];
  final List<FlakBurst> _cachedFlaksList = [];
  DreadnoughtState? _cachedDreadnoughtState;

  bool _isDisposed = false;

  void _checkDisposed() {
    if (_isDisposed) {
      throw StateError(
        'Cannot invoke native FFI operations on a disposed FfiVoidSowerEngine instance.',
      );
    }
  }

  static ffi.DynamicLibrary _loadNativeLibrary() {
    if (Platform.isAndroid || Platform.isLinux) {
      try {
        return ffi.DynamicLibrary.open('libvoid_sower.so');
      } catch (_) {
        try {
          return ffi.DynamicLibrary.open('src/build/libvoid_sower.so');
        } catch (_) {
          try {
            return ffi.DynamicLibrary.open('build/libvoid_sower.so');
          } catch (_) {
            return ffi.DynamicLibrary.process();
          }
        }
      }
    } else if (Platform.isMacOS || Platform.isIOS) {
      try {
        return ffi.DynamicLibrary.open('libvoid_sower.dylib');
      } catch (_) {
        return ffi.DynamicLibrary.process();
      }
    } else if (Platform.isWindows) {
      return ffi.DynamicLibrary.open('void_sower.dll');
    }
    return ffi.DynamicLibrary.process();
  }

  @override
  void initialize({int startingCores = 32, double boundaryY = 800.0}) {
    _checkDisposed();
    _bindings.void_sower_init(startingCores, boundaryY);
  }

  @override
  int generateWave({
    int difficulty = 0,
    int randomSeed = 42,
    int coreBudget = 16,
    double initialVelocityY = 15.0,
  }) {
    _checkDisposed();
    _cachedWaveConfigPtr.ref.difficulty = difficulty;
    _cachedWaveConfigPtr.ref.random_seed = randomSeed;
    _cachedWaveConfigPtr.ref.core_budget = coreBudget;
    _cachedWaveConfigPtr.ref.initial_velocity_y = initialVelocityY;

    return _bindings.void_sower_generate_wave(_cachedWaveConfigPtr);
  }

  @override
  int injectCore(int bayIndex, int direction) {
    _checkDisposed();
    return _bindings.void_sower_inject_core(bayIndex, direction);
  }

  @override
  void slideDreadnought(double targetX) {
    _checkDisposed();
    _bindings.void_sower_slide_dreadnought(targetX);
  }

  @override
  void stepSimulation(double deltaTime) {
    _checkDisposed();
    _bindings.void_sower_step_simulation(deltaTime);
  }

  @override
  void damageConduit(int bayIndex) {
    _checkDisposed();
    _bindings.void_sower_damage_conduit(bayIndex);
  }

  @override
  void damageAtmosphere(int penalty) {
    _checkDisposed();
    _bindings.void_sower_damage_atmosphere(penalty);
  }

  @override
  PredictionResult predictSow(int startBay, int direction) {
    _checkDisposed();
    _bindings.void_sower_predict_sow(startBay, direction, _cachedPredictionPtr);

    final ref = _cachedPredictionPtr.ref;
    return PredictionResult(
      terminalBay: ref.terminal_bay,
      terminalCorridor: ref.terminal_corridor,
      finalMass: ref.final_mass,
      predictedDamage: ref.predicted_damage,
      totalCascadeLaps: ref.total_cascade_laps,
      triggersLance: ref.triggers_lance != 0,
      triggersRelay: ref.triggers_relay != 0,
    );
  }

  @override
  List<BayState> getBays() {
    _checkDisposed();
    _bindings.void_sower_get_bays(_cachedBaysPtr, kMaxBays);

    for (var i = 0; i < kMaxBays; i++) {
      final bay = _cachedBaysPtr[i];
      final current = _cachedBaysList[i];
      final isFrontline = bay.is_frontline != 0;
      final isNyumba = bay.is_nyumba != 0;
      final isKichwa = bay.is_kichwa != 0;
      final isKimbi = bay.is_kimbi != 0;

      if (current.chargeUnits != bay.charge_units ||
          current.isFrontline != isFrontline ||
          current.tier != bay.tier ||
          current.gridColumn != bay.grid_column ||
          current.radialPositionRad != bay.radial_position_rad ||
          current.isNyumba != isNyumba ||
          current.isKichwa != isKichwa ||
          current.isKimbi != isKimbi) {
        _cachedBaysList[i] = BayState(
          bayIndex: bay.bay_index,
          tier: bay.tier,
          gridColumn: bay.grid_column,
          chargeUnits: bay.charge_units,
          radialPositionRad: bay.radial_position_rad,
          isFrontline: isFrontline,
          isNyumba: isNyumba,
          isKichwa: isKichwa,
          isKimbi: isKimbi,
        );
      }
    }
    return _cachedBaysList;
  }

  @override
  List<EnemyCraft> getEnemies() {
    _checkDisposed();
    final count = _bindings.void_sower_get_enemies(
      _cachedEnemiesPtr,
      kMaxEnemies,
    );
    _cachedEnemiesList.clear();

    for (var i = 0; i < count; i++) {
      final e = _cachedEnemiesPtr[i];
      _cachedEnemiesList.add(
        EnemyCraft(
          entityId: e.entity_id,
          assignedCorridor: e.assigned_corridor,
          worldPosX: e.world_pos_x,
          worldPosY: e.world_pos_y,
          velocityY: e.velocity_y,
          currentShields: e.current_shields,
          maxShields: e.max_shields,
          currentHull: e.current_hull,
          maxHull: e.max_hull,
          vesselType: e.vessel_type,
          isDestroyed: e.is_destroyed != 0,
        ),
      );
    }
    return _cachedEnemiesList;
  }

  @override
  List<LanceBeam> getLances() {
    _checkDisposed();
    final count = _bindings.void_sower_get_lances(_cachedLancesPtr, kMaxLances);
    _cachedLancesList.clear();

    for (var i = 0; i < count; i++) {
      final l = _cachedLancesPtr[i];
      _cachedLancesList.add(
        LanceBeam(
          firingBayIndex: l.firing_bay_index,
          originX: l.origin_x,
          originY: l.origin_y,
          beamWidth: l.beam_width,
          sustainedDuration: l.sustained_duration,
          remainingDuration: l.remaining_duration,
          totalDamage: l.total_damage,
          active: l.active != 0,
        ),
      );
    }
    return _cachedLancesList;
  }

  @override
  List<FlakBurst> getFlaks() {
    _checkDisposed();
    final count = _bindings.void_sower_get_flaks(_cachedFlaksPtr, kMaxFlaks);
    _cachedFlaksList.clear();

    for (var i = 0; i < count; i++) {
      final f = _cachedFlaksPtr[i];
      _cachedFlaksList.add(
        FlakBurst(
          worldPosX: f.world_pos_x,
          worldPosY: f.world_pos_y,
          blastRadius: f.blast_radius,
          areaDamage: f.area_damage,
          lifetime: f.lifetime,
          remainingLifetime: f.remaining_lifetime,
          active: f.active != 0,
        ),
      );
    }
    return _cachedFlaksList;
  }

  @override
  DreadnoughtState getDreadnoughtState() {
    _checkDisposed();
    _bindings.void_sower_get_dreadnought_state(_cachedDreadnoughtPtr);
    final d = _cachedDreadnoughtPtr.ref;
    final isCascading = d.is_cascading != 0;

    final cached = _cachedDreadnoughtState;
    if (cached != null &&
        cached.orbitalPositionX == d.orbital_position_x &&
        cached.targetPositionX == d.target_position_x &&
        cached.reserveCores == d.reserve_cores &&
        cached.boundaryLineY == d.boundary_line_y &&
        cached.isCascading == isCascading &&
        cached.totalScore == d.total_score &&
        cached.currentSimState == d.current_sim_state &&
        cached.coresUsed == d.cores_used) {
      return cached;
    }

    final newState = DreadnoughtState(
      orbitalPositionX: d.orbital_position_x,
      targetPositionX: d.target_position_x,
      reserveCores: d.reserve_cores,
      boundaryLineY: d.boundary_line_y,
      isCascading: isCascading,
      totalScore: d.total_score,
      currentSimState: d.current_sim_state,
      coresUsed: d.cores_used,
    );
    _cachedDreadnoughtState = newState;
    return newState;
  }

  @override
  void reset() {
    _checkDisposed();
    _bindings.void_sower_reset();
    _cachedEnemiesList.clear();
    _cachedLancesList.clear();
    _cachedFlaksList.clear();
    _cachedDreadnoughtState = null;
  }

  @override
  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;

    _cachedEnemiesList.clear();
    _cachedLancesList.clear();
    _cachedFlaksList.clear();
    _cachedDreadnoughtState = null;

    calloc.free(_cachedBaysPtr);
    calloc.free(_cachedEnemiesPtr);
    calloc.free(_cachedLancesPtr);
    calloc.free(_cachedFlaksPtr);
    calloc.free(_cachedDreadnoughtPtr);
    calloc.free(_cachedPredictionPtr);
    calloc.free(_cachedWaveConfigPtr);

    _bindings.void_sower_free();
  }
}
