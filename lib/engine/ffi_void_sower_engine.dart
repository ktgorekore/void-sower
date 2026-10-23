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
import 'package:flutter/foundation.dart';

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
  /// Constructs a native FFI engine wrapper and pre-allocates native polling buffers.
  FfiVoidSowerEngine({VoidSowerBindings? bindings})
    : _bindings = bindings ?? VoidSowerBindings(_loadNativeLibrary()) {
    _bindings.void_sower_retain();
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
    _cachedSnapshotChargesPtr = calloc<ffi.Uint32>(kMaxBays);
    _cachedSolveBayPtr = calloc<ffi.Uint8>();
    _cachedSolveDirPtr = calloc<ffi.Int8>();
    _cachedSolveConfPtr = calloc<ffi.Float>();
    _cachedSolveDmgPtr = calloc<ffi.Float>();
  }

  /// Total capacity of the power-of-two dreadnought capacitor ring.
  static const int kMaxBays = 16;

  /// Maximum number of active enemy assault craft polled per frame.
  static const int kMaxEnemies = 128;

  /// Maximum number of concurrent particle lance beams polled per frame.
  static const int kMaxLances = 16;

  /// Maximum number of concurrent flak burst detonations polled per frame.
  static const int kMaxFlaks = 32;

  final VoidSowerBindings _bindings;

  late final ffi.Pointer<VoidSowerBayFFI> _cachedBaysPtr;
  late final ffi.Pointer<VoidSowerEnemyFFI> _cachedEnemiesPtr;
  late final ffi.Pointer<VoidSowerLanceFFI> _cachedLancesPtr;
  late final ffi.Pointer<VoidSowerFlakFFI> _cachedFlaksPtr;
  late final ffi.Pointer<VoidSowerDreadnoughtFFI> _cachedDreadnoughtPtr;
  late final ffi.Pointer<VoidSowerPredictionFFI> _cachedPredictionPtr;
  late final ffi.Pointer<VoidSowerWaveConfigFFI> _cachedWaveConfigPtr;
  late final ffi.Pointer<ffi.Uint32> _cachedSnapshotChargesPtr;
  late final ffi.Pointer<ffi.Uint8> _cachedSolveBayPtr;
  late final ffi.Pointer<ffi.Int8> _cachedSolveDirPtr;
  late final ffi.Pointer<ffi.Float> _cachedSolveConfPtr;
  late final ffi.Pointer<ffi.Float> _cachedSolveDmgPtr;

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

  /// Initializes the native simulation engine with [startingCores] and [boundaryY].
  @override
  void initialize({int startingCores = 32, double boundaryY = 0.15}) {
    _checkDisposed();
    _bindings.void_sower_init(startingCores, boundaryY);
  }

  /// Generates a procedurally solvable assault wave via backward-play inversion.
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

  /// Injects a reactor core into [bayIndex] and initiates a cascade in [direction].
  @override
  int injectCore(int bayIndex, int direction) {
    _checkDisposed();
    return _bindings.void_sower_inject_core(bayIndex, direction);
  }

  /// Fires stored plasma mass from frontline [bayIndex] down its assigned corridor.
  @override
  int dischargeBay(int bayIndex, {double damageMultiplier = 1.0}) {
    _checkDisposed();
    return _bindings.void_sower_discharge_bay(bayIndex, damageMultiplier);
  }

  /// Executes a Fanorona vector strike (approach lance or withdrawal pulse).
  @override
  int triggerFanoronaStrike({required bool isApproach}) {
    _checkDisposed();
    return _bindings.void_sower_trigger_fanorona_strike(isApproach ? 1 : 0);
  }

  /// Executes a Yoté surgical orbital cull strike against [entityId].
  @override
  int cullEnemy(int entityId) {
    _checkDisposed();
    return _bindings.void_sower_cull_enemy(entityId);
  }

  /// Slides the dreadnought horizontally toward normalized [targetX].
  @override
  void slideDreadnought(double targetX) {
    _checkDisposed();
    _bindings.void_sower_slide_dreadnought(targetX);
  }

  /// Sets the 2D target position of the dreadnought to ([targetX], [targetY]).
  @override
  void setDreadnoughtTarget(double targetX, double targetY) {
    _checkDisposed();
    _bindings.void_sower_set_dreadnought_target(targetX, targetY);
  }

  /// Configures the active tactical quest type for the current sector.
  @override
  void setActiveQuest(int questType) {
    _checkDisposed();
    _bindings.void_sower_set_active_quest(questType);
  }

  /// Updates tactical quest [progress] and [status] in native state.
  @override
  void updateQuest(double progress, int status) {
    _checkDisposed();
    _bindings.void_sower_update_quest(progress, status);
  }

  /// Advances the native deterministic physics and ECS simulation by [deltaTime].
  @override
  void stepSimulation(double deltaTime) {
    _checkDisposed();
    _bindings.void_sower_step_simulation(deltaTime);
  }

  /// Applies a direct enemy ordnance hit against capacitor [bayIndex].
  @override
  void damageConduit(int bayIndex) {
    _checkDisposed();
    _bindings.void_sower_damage_conduit(bayIndex);
  }

  /// Applies an atmospheric perimeter breach [penalty] to the reactor.
  @override
  void damageAtmosphere(int penalty) {
    _checkDisposed();
    _bindings.void_sower_damage_atmosphere(penalty);
  }

  /// Grants [count] bonus reserve plasma cores to the dreadnought reactor.
  @override
  void grantCores(int count) {
    _checkDisposed();
    _bindings.void_sower_grant_cores(count);
  }

  /// Enables or disables lateral evasive drift for descending enemy craft.
  @override
  void setLateralDrift(bool enabled) {
    _checkDisposed();
    _bindings.void_sower_set_lateral_drift(enabled ? 1 : 0);
  }

  /// Spawns a reinforcement enemy vessel into [corridor].
  @override
  bool spawnEnemy({
    required int corridor,
    required double worldPosY,
    required double velocityY,
    required double shields,
    required double hull,
    required int vesselType,
  }) {
    _checkDisposed();
    return _bindings.void_sower_spawn_enemy(
          corridor,
          worldPosY,
          velocityY,
          shields,
          hull,
          vesselType,
        ) !=
        0;
  }

  /// Performs a dry-run trajectory projection from [startBay] in [direction].
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

  /// Polls and returns the current state of all 16 capacitor bays.
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

  /// Polls and returns the current list of active and recently destroyed enemy craft.
  @override
  List<EnemyCraft> getEnemies() {
    _checkDisposed();
    final count = _bindings.void_sower_get_enemies(
      _cachedEnemiesPtr,
      kMaxEnemies,
    );
    while (_cachedEnemiesList.length > count) {
      _cachedEnemiesList.removeLast();
    }

    for (var i = 0; i < count; i++) {
      final e = _cachedEnemiesPtr[i];
      final isDestroyed = e.is_destroyed != 0;
      if (i < _cachedEnemiesList.length) {
        final current = _cachedEnemiesList[i];
        if (current.entityId == e.entity_id &&
            current.assignedCorridor == e.assigned_corridor &&
            current.worldPosX == e.world_pos_x &&
            current.worldPosY == e.world_pos_y &&
            current.velocityY == e.velocity_y &&
            current.currentShields == e.current_shields &&
            current.maxShields == e.max_shields &&
            current.currentHull == e.current_hull &&
            current.maxHull == e.max_hull &&
            current.vesselType == e.vessel_type &&
            current.isDestroyed == isDestroyed &&
            current.worldPosZ == e.world_pos_z &&
            current.bankAngleRad == e.bank_angle_rad &&
            current.pitchAngleRad == e.pitch_angle_rad &&
            current.behaviorMode == e.behavior_mode &&
            current.warpInProgress == e.warp_in_progress) {
          continue;
        }
        _cachedEnemiesList[i] = EnemyCraft(
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
          isDestroyed: isDestroyed,
          worldPosZ: e.world_pos_z,
          bankAngleRad: e.bank_angle_rad,
          pitchAngleRad: e.pitch_angle_rad,
          behaviorMode: e.behavior_mode,
          warpInProgress: e.warp_in_progress,
        );
      } else {
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
            isDestroyed: isDestroyed,
            worldPosZ: e.world_pos_z,
            bankAngleRad: e.bank_angle_rad,
            pitchAngleRad: e.pitch_angle_rad,
            behaviorMode: e.behavior_mode,
            warpInProgress: e.warp_in_progress,
          ),
        );
      }
    }
    return _cachedEnemiesList;
  }

  /// Polls and returns active particle lance beams.
  @override
  List<LanceBeam> getLances() {
    _checkDisposed();
    final count = _bindings.void_sower_get_lances(_cachedLancesPtr, kMaxLances);
    while (_cachedLancesList.length > count) {
      _cachedLancesList.removeLast();
    }

    for (var i = 0; i < count; i++) {
      final l = _cachedLancesPtr[i];
      final active = l.active != 0;
      if (i < _cachedLancesList.length) {
        final current = _cachedLancesList[i];
        if (current.firingBayIndex == l.firing_bay_index &&
            current.originX == l.origin_x &&
            current.originY == l.origin_y &&
            current.beamWidth == l.beam_width &&
            current.sustainedDuration == l.sustained_duration &&
            current.remainingDuration == l.remaining_duration &&
            current.totalDamage == l.total_damage &&
            current.active == active) {
          continue;
        }
        _cachedLancesList[i] = LanceBeam(
          firingBayIndex: l.firing_bay_index,
          originX: l.origin_x,
          originY: l.origin_y,
          beamWidth: l.beam_width,
          sustainedDuration: l.sustained_duration,
          remainingDuration: l.remaining_duration,
          totalDamage: l.total_damage,
          active: active,
        );
      } else {
        _cachedLancesList.add(
          LanceBeam(
            firingBayIndex: l.firing_bay_index,
            originX: l.origin_x,
            originY: l.origin_y,
            beamWidth: l.beam_width,
            sustainedDuration: l.sustained_duration,
            remainingDuration: l.remaining_duration,
            totalDamage: l.total_damage,
            active: active,
          ),
        );
      }
    }
    return _cachedLancesList;
  }

  /// Polls and returns active secondary radial flak bursts.
  @override
  List<FlakBurst> getFlaks() {
    _checkDisposed();
    final count = _bindings.void_sower_get_flaks(_cachedFlaksPtr, kMaxFlaks);
    while (_cachedFlaksList.length > count) {
      _cachedFlaksList.removeLast();
    }

    for (var i = 0; i < count; i++) {
      final f = _cachedFlaksPtr[i];
      final active = f.active != 0;
      if (i < _cachedFlaksList.length) {
        final current = _cachedFlaksList[i];
        if (current.worldPosX == f.world_pos_x &&
            current.worldPosY == f.world_pos_y &&
            current.blastRadius == f.blast_radius &&
            current.areaDamage == f.area_damage &&
            current.lifetime == f.lifetime &&
            current.remainingLifetime == f.remaining_lifetime &&
            current.active == active) {
          continue;
        }
        _cachedFlaksList[i] = FlakBurst(
          worldPosX: f.world_pos_x,
          worldPosY: f.world_pos_y,
          blastRadius: f.blast_radius,
          areaDamage: f.area_damage,
          lifetime: f.lifetime,
          remainingLifetime: f.remaining_lifetime,
          active: active,
        );
      } else {
        _cachedFlaksList.add(
          FlakBurst(
            worldPosX: f.world_pos_x,
            worldPosY: f.world_pos_y,
            blastRadius: f.blast_radius,
            areaDamage: f.area_damage,
            lifetime: f.lifetime,
            remainingLifetime: f.remaining_lifetime,
            active: active,
          ),
        );
      }
    }
    return _cachedFlaksList;
  }

  /// Polls and returns the current dreadnought flagship state.
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
        cached.orbitalPositionY == d.orbital_position_y &&
        cached.targetPositionY == d.target_position_y &&
        cached.proximityMultiplier == d.proximity_multiplier &&
        cached.reserveCores == d.reserve_cores &&
        cached.boundaryLineY == d.boundary_line_y &&
        cached.isCascading == isCascading &&
        cached.totalScore == d.total_score &&
        cached.currentSimState == d.current_sim_state &&
        cached.coresUsed == d.cores_used &&
        cached.questProgress == d.quest_progress &&
        cached.activeQuestType == d.active_quest_type &&
        cached.questStatus == d.quest_status) {
      return cached;
    }

    final newState = DreadnoughtState(
      orbitalPositionX: d.orbital_position_x,
      targetPositionX: d.target_position_x,
      orbitalPositionY: d.orbital_position_y,
      targetPositionY: d.target_position_y,
      boundaryLineY: d.boundary_line_y,
      proximityMultiplier: d.proximity_multiplier,
      reserveCores: d.reserve_cores,
      totalScore: d.total_score,
      coresUsed: d.cores_used,
      questProgress: d.quest_progress,
      isCascading: isCascading,
      currentSimState: d.current_sim_state,
      activeQuestType: d.active_quest_type,
      questStatus: d.quest_status,
    );
    _cachedDreadnoughtState = newState;
    return newState;
  }

  /// Configures the chassis particle lance damage [multiplier].
  @override
  void setLanceAlphaMultiplier(double multiplier) {
    _checkDisposed();
    _bindings.void_sower_set_lance_alpha(multiplier);
  }

  /// Restores native simulation state from an archived turn snapshot.
  @override
  void restoreSnapshot({
    required List<int> bayCharges,
    required int reserveCores,
    required int totalScore,
    int chargesLength = kMaxBays,
  }) {
    _checkDisposed();
    final clampedLength = chargesLength.clamp(0, kMaxBays);
    // Zero-fill all 16 slots to guarantee trailing slots do not retain stale memory
    for (var i = 0; i < kMaxBays; i++) {
      _cachedSnapshotChargesPtr[i] = (i < bayCharges.length)
          ? bayCharges[i]
          : 0;
    }
    _bindings.void_sower_restore_snapshot(
      _cachedSnapshotChargesPtr,
      clampedLength,
      reserveCores,
      totalScore,
    );
    _cachedDreadnoughtState = null;
  }

  /// Read-only inspection of native snapshot charges pointer for testing.
  @visibleForTesting
  ffi.Pointer<ffi.Uint32> get cachedSnapshotChargesPtr {
    _checkDisposed();
    return _cachedSnapshotChargesPtr;
  }

  /// Computes the optimal tactical move via native Monte Carlo Tree Search.
  @override
  TacticalStepResult? solveTacticalStep() {
    _checkDisposed();
    final res = _bindings.void_sower_solve_tactical_step(
      _cachedSolveBayPtr,
      _cachedSolveDirPtr,
      _cachedSolveConfPtr,
      _cachedSolveDmgPtr,
    );
    if (res == 1) {
      return TacticalStepResult(
        bayIndex: _cachedSolveBayPtr.value,
        direction: _cachedSolveDirPtr.value,
        confidence: _cachedSolveConfPtr.value,
        predictedDamage: _cachedSolveDmgPtr.value,
      );
    }
    return null;
  }

  /// Resets the native simulation engine to default baseline state.
  @override
  void reset() {
    _checkDisposed();
    _bindings.void_sower_reset();
    _cachedEnemiesList.clear();
    _cachedLancesList.clear();
    _cachedFlaksList.clear();
    _cachedDreadnoughtState = null;
  }

  /// Frees all pre-allocated native FFI buffers and releases native engine leases.
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
    calloc.free(_cachedSnapshotChargesPtr);
    calloc.free(_cachedSolveBayPtr);
    calloc.free(_cachedSolveDirPtr);
    calloc.free(_cachedSolveConfPtr);
    calloc.free(_cachedSolveDmgPtr);

    _bindings.void_sower_release();
  }
}
