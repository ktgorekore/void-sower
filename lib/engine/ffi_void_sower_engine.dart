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

  bool _isDisposed = false;

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
    _bindings.void_sower_init(startingCores, boundaryY);
  }

  @override
  int generateWave({
    int difficulty = 0,
    int randomSeed = 42,
    int coreBudget = 16,
    double initialVelocityY = 15.0,
  }) {
    _cachedWaveConfigPtr.ref.difficulty = difficulty;
    _cachedWaveConfigPtr.ref.random_seed = randomSeed;
    _cachedWaveConfigPtr.ref.core_budget = coreBudget;
    _cachedWaveConfigPtr.ref.initial_velocity_y = initialVelocityY;

    return _bindings.void_sower_generate_wave(_cachedWaveConfigPtr);
  }

  @override
  int injectCore(int bayIndex, int direction) {
    return _bindings.void_sower_inject_core(bayIndex, direction);
  }

  @override
  void slideDreadnought(double targetX) {
    _bindings.void_sower_slide_dreadnought(targetX);
  }

  @override
  void stepSimulation(double deltaTime) {
    _bindings.void_sower_step_simulation(deltaTime);
  }

  @override
  PredictionResult predictSow(int startBay, int direction) {
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
    _bindings.void_sower_get_bays(_cachedBaysPtr, kMaxBays);
    final results = <BayState>[];

    for (var i = 0; i < kMaxBays; i++) {
      final bay = _cachedBaysPtr[i];
      results.add(
        BayState(
          bayIndex: bay.bay_index,
          tier: bay.tier,
          gridColumn: bay.grid_column,
          chargeUnits: bay.charge_units,
          radialPositionRad: bay.radial_position_rad,
          isFrontline: bay.is_frontline != 0,
          isNyumba: bay.is_nyumba != 0,
          isKichwa: bay.is_kichwa != 0,
          isKimbi: bay.is_kimbi != 0,
        ),
      );
    }
    return results;
  }

  @override
  List<EnemyCraft> getEnemies() {
    final count = _bindings.void_sower_get_enemies(
      _cachedEnemiesPtr,
      kMaxEnemies,
    );
    final results = <EnemyCraft>[];

    for (var i = 0; i < count; i++) {
      final e = _cachedEnemiesPtr[i];
      results.add(
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
    return results;
  }

  @override
  List<LanceBeam> getLances() {
    final count = _bindings.void_sower_get_lances(_cachedLancesPtr, kMaxLances);
    final results = <LanceBeam>[];

    for (var i = 0; i < count; i++) {
      final l = _cachedLancesPtr[i];
      results.add(
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
    return results;
  }

  @override
  List<FlakBurst> getFlaks() {
    final count = _bindings.void_sower_get_flaks(_cachedFlaksPtr, kMaxFlaks);
    final results = <FlakBurst>[];

    for (var i = 0; i < count; i++) {
      final f = _cachedFlaksPtr[i];
      results.add(
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
    return results;
  }

  @override
  DreadnoughtState getDreadnoughtState() {
    _bindings.void_sower_get_dreadnought_state(_cachedDreadnoughtPtr);
    final d = _cachedDreadnoughtPtr.ref;

    return DreadnoughtState(
      orbitalPositionX: d.orbital_position_x,
      targetPositionX: d.target_position_x,
      reserveCores: d.reserve_cores,
      boundaryLineY: d.boundary_line_y,
      isCascading: d.is_cascading != 0,
      totalScore: d.total_score,
      currentSimState: d.current_sim_state,
      coresUsed: d.cores_used,
    );
  }

  @override
  void reset() {
    _bindings.void_sower_reset();
  }

  @override
  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;

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
