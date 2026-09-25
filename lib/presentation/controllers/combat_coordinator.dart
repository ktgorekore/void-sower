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

import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../core/logging.dart';
import '../../domain/models/bay_state.dart';
import '../../domain/models/campaign_sector.dart';
import '../../domain/models/dreadnought_state.dart';
import '../../domain/models/enemy_craft.dart';
import '../../domain/models/flak_burst.dart';
import '../../domain/models/floating_damage_number.dart';
import '../../domain/models/lance_beam.dart';
import '../../domain/models/prediction_result.dart';
import '../../domain/models/pro_feature.dart';
import '../../domain/models/sector_combat_doctrine.dart';
import '../../domain/models/swarm_wave_phase.dart';
import '../../domain/services/entitlement_service.dart';
import '../../domain/services/game_engine_interface.dart';
import '../../domain/services/persistence_service.dart';
import '../../domain/state/combat_match_state.dart';
import '../services/haptic_service.dart';
import '../services/particle_service.dart';
import '../theme/void_theme.dart';
import 'combat_audio_orchestrator.dart';
import 'invader_bullet_manager.dart';
import 'tactical_solver_controller.dart';

/// Central coordinator managing the 60 Hz combat loop, state machine transitions,
/// bullet physics, and presentation state.
class CombatCoordinator extends ChangeNotifier {
  CombatCoordinator({
    required this.engine,
    this.difficultyTier = 0,
    ParticleService? particleService,
    CombatAudioOrchestrator? audioOrchestrator,
  }) : particleService = particleService ?? ParticleService(maxParticles: 300),
       audio = audioOrchestrator ?? CombatAudioOrchestrator() {
    bulletManager = InvaderBulletManager(
      particleService: this.particleService,
      damageNumbers: damageNumbers,
      onConduitBreached: _handleConduitBreached,
      onAtmosphereBreached: _handleAtmosphereBreached,
      onBulletDeflected: _handleBulletDeflected,
    );

    solverController = TacticalSolverController(
      engine: engine,
      onMoveSelected: _handleSolverMove,
    );
  }

  final IVoidSowerEngine engine;
  final int difficultyTier;
  final ParticleService particleService;
  final CombatAudioOrchestrator audio;
  late final InvaderBulletManager bulletManager;
  late final TacticalSolverController solverController;

  final List<FloatingDamageNumber> damageNumbers = <FloatingDamageNumber>[];
  final math.Random _random = math.Random();

  CombatMatchState _state = CombatMatchState.initial();
  CombatMatchState get state => _state;

  late DreadnoughtState dreadnought;
  List<BayState> bays = const [];
  List<EnemyCraft> enemies = const [];
  List<LanceBeam> lances = const [];
  List<FlakBurst> flaks = const [];
  PredictionResult? _prediction;
  PredictionResult? get prediction => _prediction;
  set prediction(PredictionResult? val) {
    _prediction = val;
    if (!_hasUsedAiSolver &&
        !_state.isAutoSolving &&
        val != null &&
        val.totalCascadeLaps > _sessionMaxCascade) {
      _sessionMaxCascade = val.totalCascadeLaps;
    }
  }

  int _sowDirection = 1;

  /// Active sowing direction (+1 for clockwise/right, -1 for counter-clockwise/left).
  int get sowDirection => _sowDirection;

  /// Changes the active sowing direction and updates the forward prediction.
  void setSowDirection(int direction) {
    if (direction != 1 && direction != -1) return;
    _sowDirection = direction;
    final bay = _state.selectedBay ?? 8;
    prediction = engine.predictSow(bay, _sowDirection);
    notifyListeners();
  }

  int _sessionLancesFired = 0;
  int get sessionLancesFired => _sessionLancesFired;

  int _sessionFlakBursts = 0;
  int get sessionFlakBursts => _sessionFlakBursts;

  int _sessionSeedsSown = 0;
  int get sessionSeedsSown => _sessionSeedsSown;

  int _sessionMaxCascade = 0;
  int get sessionMaxCascade => _sessionMaxCascade;

  bool _hasUsedAiSolver = false;
  bool get hasUsedAiSolver => _hasUsedAiSolver;

  DateTime _sessionStartTime = DateTime.now();
  int get sessionFlightTimeSeconds =>
      math.max(0, DateTime.now().difference(_sessionStartTime).inSeconds);

  Set<int> _activeLanceBays = <int>{};
  bool _hasActiveFlak = false;
  bool _isDisposed = false;
  Completer<void>? _sowAnimationCompleter;
  int _sowAnimationGeneration = 0;
  int? _pendingSowBay;
  int? _pendingSowDirection;

  CampaignSector? _sector;
  CampaignSector? get sector => _sector;

  SwarmWavePhase _swarmPhase = SwarmWavePhase.secured;
  SwarmWavePhase get swarmPhase => _swarmPhase;

  int _remainingReinforcements = 0;
  int get remainingReinforcements => _remainingReinforcements;

  final Set<int> _neutralizedEnemyIds = <int>{};
  final Set<int> _activeEnemyIds = <int>{};

  int _currentDifficulty = 0;
  int get currentDifficulty => _currentDifficulty;

  int _highScore = 0;
  int get highScore => math.max(
    _highScore,
    _hasUsedAiSolver ? _highScore : dreadnought.totalScore,
  );

  int get competitiveScore => _hasUsedAiSolver ? 0 : dreadnought.totalScore;

  /// Initializes engine entities, procedurally generates the solvable combat wave,
  /// and primes the FSM.
  void initialize({
    CampaignSector? sector,
    int? difficulty,
    int startingCores = 28,
    double boundaryY = 0.15,
    bool autoStartSolver = false,
    bool startWithTutorial = false,
  }) {
    _sector = sector;
    _hasUsedAiSolver = autoStartSolver;
    _finalizePendingSow();
    _highScore = PersistenceService.instance.highScore;
    _currentDifficulty = difficulty ?? sector?.difficultyTier ?? difficultyTier;
    _neutralizedEnemyIds.clear();
    _activeEnemyIds.clear();
    _sessionLancesFired = 0;
    _sessionFlakBursts = 0;
    _sessionSeedsSown = 0;
    _sessionMaxCascade = 0;
    _sessionStartTime = DateTime.now();

    final doctrine = sector?.doctrine ?? SectorCombatDoctrine.standardOrbital;
    _remainingReinforcements = sector?.reinforcementQuota ?? 0;
    _swarmPhase = (doctrine == SectorCombatDoctrine.voidSwarm)
        ? SwarmWavePhase.initialAssault
        : SwarmWavePhase.secured;

    vlog(
      6,
      'CombatCoordinator: Initializing sector ${sector?.sectorId ?? "custom"} difficulty $_currentDifficulty doctrine $doctrine',
    );
    final initialCores = (sector != null && sector.sectorId == 1)
        ? 36
        : startingCores;
    engine.initialize(startingCores: initialCores, boundaryY: boundaryY);
    engine.setLateralDrift(doctrine == SectorCombatDoctrine.phantomDrift);
    final int waveSeed = sector != null
        ? (sector.sectorId == 1 ? 8 : (sector.sectorId * 7919))
        : 8;
    final double initialVel = _currentDifficulty == 0
        ? 0.010
        : (0.02 + (_currentDifficulty * 0.008));
    engine.generateWave(
      difficulty: _currentDifficulty,
      randomSeed: waveSeed,
      coreBudget: 16 + (_currentDifficulty * 4),
      initialVelocityY: initialVel,
    );
    _syncDomainState();
    _activeEnemyIds.addAll(
      enemies.where((e) => !e.isDestroyed).map((e) => e.entityId),
    );

    damageNumbers.clear();
    bulletManager.clear();
    _activeLanceBays.clear();
    _hasActiveFlak = false;

    const initialBay = 11;
    prediction = engine.predictSow(initialBay, 1);

    final shouldShowTutorial =
        startWithTutorial ||
        (!PersistenceService.instance.hasCompletedTutorial &&
            _currentDifficulty == 0 &&
            !autoStartSolver);

    _state = CombatMatchState(
      status: shouldShowTutorial
          ? CombatMatchStatus.briefing
          : CombatMatchStatus.activeCombat,
      isAutoSolving: autoStartSolver,
      selectedBay: initialBay,
    );

    if (autoStartSolver) {
      solverController.reset();
    }
    notifyListeners();
  }

  /// Synchronizes entity snapshots from the native C++ engine.
  void _syncDomainState() {
    dreadnought = engine.getDreadnoughtState();
    bays = engine.getBays();
    enemies = engine.getEnemies();
    lances = engine.getLances();
    flaks = engine.getFlaks();

    if (!_hasUsedAiSolver && dreadnought.totalScore > _highScore) {
      _highScore = dreadnought.totalScore;
      unawaited(PersistenceService.instance.setHighScore(_highScore));
    }
  }

  /// Grants emergency auxiliary plasma cores (e.g. from a rewarded ad transmission).
  void grantEmergencyCores(int bonusCores) {
    if (_isDisposed) return;
    engine.grantCores(bonusCores);
    dreadnought = dreadnought.copyWith(
      reserveCores: dreadnought.reserveCores + bonusCores,
    );
    notifyListeners();
  }

  /// Handles enemy neutralization, awards tactical core siphon, and spawns swarm reinforcements.
  void _handleEnemyNeutralized({
    required int entityId,
    required int vesselType,
    required double worldPosX,
    required int assignedCorridor,
    required SectorCombatDoctrine doctrine,
    required Size viewportSize,
  }) {
    if (_neutralizedEnemyIds.contains(entityId)) return;
    _neutralizedEnemyIds.add(entityId);

    // Tactical Core Siphon (grantEmergencyCores already forwards to engine)
    final siphonAmount =
        _sector?.coreSiphonPerKill ??
        (vesselType == 2 ? 3 : (vesselType == 1 ? 2 : 1));
    grantEmergencyCores(siphonAmount);

    final enemyCorridorX = (worldPosX > 0.0 && worldPosX <= 1.0)
        ? worldPosX * viewportSize.width
        : (assignedCorridor + 0.5) * (viewportSize.width / 8.0);

    damageNumbers.add(
      FloatingDamageNumber(
        text: '+$siphonAmount CORES (SIPHON)',
        x: enemyCorridorX,
        y: viewportSize.height * 0.40,
        color: VoidTheme.solarGold,
        isCritical: siphonAmount >= 2,
      ),
    );
    HapticService.instance.sowTick();

    // Void Swarm horde reinforcement spawning
    if (doctrine == SectorCombatDoctrine.voidSwarm &&
        _remainingReinforcements > 0) {
      _remainingReinforcements--;
      final respawnCorridor = _random.nextInt(8);
      final vType = (_remainingReinforcements % 4 == 0)
          ? 1
          : ((_remainingReinforcements == 0) ? 2 : 0);
      final shields = (vType == 2) ? 150.0 : (vType == 1 ? 60.0 : 0.0);
      final hull = (vType == 2) ? 250.0 : (vType == 1 ? 100.0 : 40.0);
      final velY = 0.02 + (_currentDifficulty * 0.006);

      engine.spawnEnemy(
        corridor: respawnCorridor,
        worldPosY: 0.96,
        velocityY: velY,
        shields: shields,
        hull: hull,
        vesselType: vType,
      );

      if (_remainingReinforcements == 0) {
        _swarmPhase = SwarmWavePhase.finalStand;
      } else if (_swarmPhase == SwarmWavePhase.initialAssault) {
        _swarmPhase = SwarmWavePhase.reinforcementWaves;
      }
    }
  }

  /// Core 60 Hz update step driving physics, FSM, and rendering state.
  void update(double dt, Size viewportSize) {
    if (_isDisposed) return;
    final clampedDt = dt.clamp(0.001, 0.05);

    // If game is in tactical tutorial briefing, paused, defeated, or victorious, freeze combat simulation!
    // This guarantees enemies stop moving and shooting when the match reaches a terminal state.
    final bool allEnemiesDestroyed =
        enemies.isNotEmpty && enemies.every((e) => e.isDestroyed);
    if (_state.status == CombatMatchStatus.briefing ||
        _state.status == CombatMatchStatus.paused ||
        _state.status == CombatMatchStatus.defeat ||
        _state.status == CombatMatchStatus.victory ||
        dreadnought.isGameOver ||
        (dreadnought.isVictory &&
            _remainingReinforcements <= 0 &&
            allEnemiesDestroyed)) {
      lances = const [];
      damageNumbers.clear();
      particleService.update(clampedDt * 0.2);
      return;
    }

    // 1. Advance native C++ simulation
    engine.stepSimulation(clampedDt);
    _syncDomainState();

    // Check for newly neutralized enemies for Tactical Core Siphon & Horde Reinforcements
    final doctrine = _sector?.doctrine ?? SectorCombatDoctrine.standardOrbital;
    final currentLivingEnemyIds = <int>{};
    bool spawnedReinforcements = false;

    for (final enemy in enemies) {
      if (!enemy.isDestroyed) {
        currentLivingEnemyIds.add(enemy.entityId);
      } else if (!_neutralizedEnemyIds.contains(enemy.entityId)) {
        _handleEnemyNeutralized(
          entityId: enemy.entityId,
          vesselType: enemy.vesselType,
          worldPosX: enemy.worldPosX,
          assignedCorridor: enemy.assignedCorridor,
          doctrine: doctrine,
          viewportSize: viewportSize,
        );
        spawnedReinforcements = true;
      }
    }

    // Defensive fallback: check if any previously active enemy disappeared from the enemies snapshot
    for (final activeId in _activeEnemyIds) {
      if (!currentLivingEnemyIds.contains(activeId) &&
          !_neutralizedEnemyIds.contains(activeId)) {
        _handleEnemyNeutralized(
          entityId: activeId,
          vesselType: 0,
          worldPosX: 0.5,
          assignedCorridor: 4,
          doctrine: doctrine,
          viewportSize: viewportSize,
        );
        spawnedReinforcements = true;
      }
    }
    _activeEnemyIds
      ..clear()
      ..addAll(currentLivingEnemyIds);

    // If reinforcements were spawned, re-sync domain state immediately so dreadnought state (restored to OrbitalIdle)
    // and enemies (new reinforcement craft) are immediately available.
    if (spawnedReinforcements) {
      _syncDomainState();
    }

    // Check if orbital was breached, ammo exhausted, or victory achieved during simulation step
    final bool isAmmoExhausted =
        dreadnought.reserveCores <= 0 &&
        !dreadnought.isCascading &&
        !lances.any((l) => l.active) &&
        enemies.any((e) => !e.isDestroyed);

    if (dreadnought.isGameOver || isAmmoExhausted) {
      if (_state.status != CombatMatchStatus.defeat) {
        _state = _state.copyWith(status: CombatMatchStatus.defeat);
        audio.onDefeat();
        notifyListeners();
      }
      bulletManager.clear();
      particleService.update(clampedDt * 0.2);
      return;
    } else if (dreadnought.isVictory &&
        _remainingReinforcements <= 0 &&
        enemies.every((e) => e.isDestroyed)) {
      if (_state.status != CombatMatchStatus.victory) {
        _swarmPhase = SwarmWavePhase.secured;
        _state = _state.copyWith(status: CombatMatchStatus.victory);
        audio.onVictory();
        notifyListeners();
      }
      bulletManager.clear();
      lances = const [];
      damageNumbers.clear();
      particleService.update(clampedDt * 0.2);
      return;
    }

    // 2. Decay screen shake
    if (_state.screenShake != Offset.zero) {
      final decayed = Offset(
        _state.screenShake.dx * 0.82,
        _state.screenShake.dy * 0.82,
      );
      _state = _state.copyWith(
        screenShake: decayed.distance < 0.2 ? Offset.zero : decayed,
      );
    }

    // 3. Update floating damage numbers
    damageNumbers.removeWhere((damage) => !damage.update(clampedDt));

    // 4. Update particles
    particleService.update(clampedDt);

    // 5. Update enemy bullets & collisions
    final boundaryY = viewportSize.height - 48.0;
    final dreadX =
        (dreadnought.orbitalPositionX > 0.0 &&
            dreadnought.orbitalPositionX <= 1.0)
        ? dreadnought.orbitalPositionX * viewportSize.width
        : viewportSize.width * 0.5;

    bulletManager.update(
      dt: clampedDt,
      viewportSize: viewportSize,
      boundaryY: boundaryY,
      dreadX: dreadX,
      enemies: enemies,
      lances: lances,
      flaks: flaks,
      bays: bays,
    );

    // 6. Reactive audio triggers on newly active lances and flak detonations
    for (final lance in lances) {
      if (lance.active && !_activeLanceBays.contains(lance.firingBayIndex)) {
        audio.onLanceFired();
        if (!_state.isAutoSolving && !_hasUsedAiSolver) {
          _sessionLancesFired++;
        }
      }
    }
    _activeLanceBays = lances
        .where((l) => l.active)
        .map((l) => l.firingBayIndex)
        .toSet();

    final nowHasFlak = flaks.any((f) => f.active);
    if (nowHasFlak && !_hasActiveFlak) {
      audio.onFlakDetonated();
      if (!_state.isAutoSolving && !_hasUsedAiSolver) {
        _sessionFlakBursts++;
      }
    }
    _hasActiveFlak = nowHasFlak;

    // 7. Spawn floating lance damage numbers and shake
    for (final lance in lances) {
      if (lance.active) {
        _applyScreenShake(3.5);
        if (damageNumbers.length < 5 && _random.nextDouble() < 0.25) {
          final corridor = (lance.firingBayIndex >= 8)
              ? (lance.firingBayIndex - 8)
              : lance.firingBayIndex;
          final lanceX = (lance.originX > 0.0 && lance.originX <= 1.0)
              ? lance.originX * viewportSize.width
              : (corridor + 0.5) * (viewportSize.width / 8.0);
          damageNumbers.add(
            FloatingDamageNumber(
              text: '${(lance.totalDamage * 10).toInt()}',
              x: lanceX,
              y: viewportSize.height * 0.35,
              color: VoidTheme.plasmaCyan,
              isCritical: lance.totalDamage >= 2.0,
            ),
          );
        }
      }
    }

    // 8. Autonomous AI Tactical Solver step
    if (_state.isAutoSolving &&
        _state.status == CombatMatchStatus.activeCombat) {
      solverController.update(
        dt: clampedDt,
        dreadnought: dreadnought,
        bays: bays,
        enemies: enemies,
      );
    }
  }

  void _applyScreenShake(double intensity) {
    _state = _state.copyWith(
      screenShake: Offset(
        (_random.nextDouble() - 0.5) * intensity * 2,
        (_random.nextDouble() - 0.5) * intensity * 2,
      ),
    );
  }

  void _handleConduitBreached(int corridor, double x, double y) {
    final bayIndex = 8 + corridor.clamp(0, 7);
    engine.damageConduit(bayIndex);
    audio.onShieldHit();
    HapticService.instance.injectionClick();
    _applyScreenShake(12.0);
  }

  void _handleAtmosphereBreached(double x, double y) {
    engine.damageAtmosphere(5);
  }

  void _handleBulletDeflected(double x, double y, Color color) {
    audio.onBulletDeflected();
    HapticService.instance.sowTick();
  }

  void _handleSolverMove(int bayIndex, int direction, double targetSlideX) {
    _hasUsedAiSolver = true;
    engine.slideDreadnought(targetSlideX);
    _state = _state.copyWith(selectedBay: bayIndex);
    prediction = engine.predictSow(bayIndex, direction);
    sow(bayIndex, direction);
    EntitlementService.instance.consumeAiSolverMove();
    if (!EntitlementService.instance.isFeatureAccessible(
      ProFeature.aiTacticalSolver,
    )) {
      toggleAutoSolve();
    }
  }

  /// Selects a bay for aiming and forward prediction with optional direction.
  void selectBay(int bayIndex, [int? direction]) {
    if (!_state.canReceiveInput) return;
    if (direction != null && (direction == 1 || direction == -1)) {
      _sowDirection = direction;
    }
    _state = _state.copyWith(selectedBay: bayIndex);
    prediction = engine.predictSow(bayIndex, _sowDirection);
    notifyListeners();
  }

  /// Sows from the currently selected bay in the specified direction.
  void sowDirectional(int direction) {
    if (direction != 1 && direction != -1) return;
    _sowDirection = direction;
    final bay = _state.selectedBay ?? 8;
    sow(bay, direction);
  }

  /// Finalizes any active sowing sequence immediately into the native engine
  /// and invalidates pending animation steps. This guarantees the simulation
  /// domain state is fully synchronized before pausing, resetting, or disposing.
  void _finalizePendingSow() {
    _sowAnimationGeneration++;
    if (_pendingSowBay != null && _pendingSowDirection != null) {
      final bay = _pendingSowBay!;
      final dir = _pendingSowDirection!;
      _pendingSowBay = null;
      _pendingSowDirection = null;

      HapticService.instance.sowTick();
      audio.onSowStep(cascadeDepth: 0);
      engine.injectCore(bay, dir);
      vlog(
        6,
        'CombatCoordinator: Finalized pending sow for bay $bay dir $dir on pause/reset',
      );
      _syncDomainState();
      prediction = engine.predictSow(bay, dir);
    }
    if (_sowAnimationCompleter != null &&
        !_sowAnimationCompleter!.isCompleted) {
      _sowAnimationCompleter!.complete();
    }
  }

  /// Triggers a sequential pit-to-pit sowing traversal animation then executes on native engine.
  void sow(int bayIndex, int direction) {
    if (_state.status != CombatMatchStatus.activeCombat) return;
    final mass = (bayIndex < bays.length) ? bays[bayIndex].chargeUnits : 1;
    if (!_state.isAutoSolving && !_hasUsedAiSolver) {
      _sessionSeedsSown += mass;
    }

    _sowAnimationGeneration++;
    final generation = _sowAnimationGeneration;
    _pendingSowBay = bayIndex;
    _pendingSowDirection = direction;
    _sowDirection = direction;

    _state = _state.copyWith(
      status: CombatMatchStatus.sowingSequence,
      selectedBay: bayIndex,
    );
    notifyListeners();

    if (_sowAnimationCompleter != null &&
        !_sowAnimationCompleter!.isCompleted) {
      _sowAnimationCompleter!.complete();
    }
    _sowAnimationCompleter = Completer<void>();

    int currentBay = bayIndex;
    int remainingHops = mass + 1;
    int hopIndex = 0;

    void step() {
      if (_isDisposed || generation != _sowAnimationGeneration) {
        return;
      }

      if (remainingHops <= 0) {
        HapticService.instance.sowTick();
        audio.onSowStep(cascadeDepth: 0);
        engine.injectCore(bayIndex, direction);
        vlog(
          6,
          'CombatCoordinator: Sow completed for bay $bayIndex dir $direction',
        );
        _syncDomainState();
        _pendingSowBay = null;
        _pendingSowDirection = null;

        final nextStatus = (_state.status == CombatMatchStatus.paused)
            ? CombatMatchStatus.paused
            : CombatMatchStatus.activeCombat;

        _state = _state.copyWith(
          status: nextStatus,
          clearActiveSowBay: true,
          selectedBay: bayIndex,
        );
        prediction = engine.predictSow(bayIndex, direction);
        notifyListeners();

        if (_sowAnimationCompleter != null &&
            !_sowAnimationCompleter!.isCompleted) {
          _sowAnimationCompleter!.complete();
        }
        return;
      }

      currentBay = (currentBay + direction + 16) & 0x0F;
      remainingHops--;
      hopIndex++;

      _state = _state.copyWith(activeSowBay: currentBay);
      HapticService.instance.sowTick();
      audio.onSowStep(cascadeDepth: hopIndex ~/ 8);
      notifyListeners();

      unawaited(Future.delayed(const Duration(milliseconds: 65), step));
    }

    step();
  }

  /// Direct core injection into a designated bay.
  void injectCore(int bayIndex, int direction) {
    if (!_state.canReceiveInput) return;
    _sessionSeedsSown++;
    HapticService.instance.injectionClick();
    audio.onCoreInjected();
    engine.injectCore(bayIndex, direction);
    vlog(
      6,
      'CombatCoordinator: Injected core into bay $bayIndex dir $direction',
    );
    damageNumbers.add(
      FloatingDamageNumber(
        text: '-1 CORE (NAMUA)',
        x: dreadnought.orbitalPositionX,
        y: (dreadnought.boundaryLineY + 0.04).clamp(0.0, 1.0),
        color: VoidTheme.solarGold,
        isCritical: false,
      ),
    );
    _syncDomainState();
    _state = _state.copyWith(selectedBay: bayIndex);
    prediction = engine.predictSow(bayIndex, direction);
    notifyListeners();
  }

  /// Discharges an immediate axial particle lance from the Dreadnought's prow
  /// into the current corridor, drawing from the aligned bay or injecting a core.
  void quickFireActiveCorridor() {
    if (!_state.canReceiveInput) return;
    if (_state.status == CombatMatchStatus.paused) {
      _state = _state.copyWith(status: CombatMatchStatus.activeCombat);
    }
    final corridor = (dreadnought.orbitalPositionX * 8.0).floor().clamp(0, 7);
    final activeBay = corridor + 8;
    // Sowing inward along the frontline keeps single-hop shots on the frontline batteries
    final direction = (corridor >= 4) ? -1 : 1;

    _sessionSeedsSown++;
    HapticService.instance.injectionClick();
    audio.onCoreInjected();

    engine.injectCore(activeBay, direction);
    vlog(
      6,
      'CombatCoordinator: Quick-fire active corridor $corridor via bay $activeBay dir $direction',
    );

    damageNumbers.add(
      FloatingDamageNumber(
        text: '-1 CORE (AXIAL LANCE)',
        x:
            (dreadnought.orbitalPositionX > 0.0 &&
                dreadnought.orbitalPositionX <= 1.0)
            ? dreadnought.orbitalPositionX
            : 0.4375,
        y: (dreadnought.boundaryLineY + 0.04).clamp(0.0, 1.0),
        color: VoidTheme.solarGold,
        isCritical: false,
      ),
    );

    _syncDomainState();
    _state = _state.copyWith(selectedBay: activeBay);
    prediction = engine.predictSow(activeBay, direction);
    notifyListeners();
  }

  /// Sets the dreadnought's target horizontal position.
  void slidePosition(double targetX) {
    final clampedX = targetX.clamp(0.0, 1.0);
    final corridor = (clampedX * 8.0).floor().clamp(0, 7);
    final snappedX = (corridor + 0.5) / 8.0;
    engine.slideDreadnought(snappedX);
    if (_state.status == CombatMatchStatus.paused) {
      dreadnought = dreadnought.copyWith(
        orbitalPositionX: snappedX,
        targetPositionX: snappedX,
      );
    }
    final frontlineBay = corridor + 8;
    if (_state.selectedBay != frontlineBay &&
        _state.status != CombatMatchStatus.sowingSequence) {
      _state = _state.copyWith(selectedBay: frontlineBay);
      prediction = engine.predictSow(frontlineBay, _sowDirection);
    }
    notifyListeners();
  }

  /// Opens tactical tutorial overlay (pausing combat).
  void showTutorial() {
    _state = _state.copyWith(status: CombatMatchStatus.briefing);
    notifyListeners();
  }

  /// Dismisses tactical tutorial overlay and starts active combat.
  void dismissTutorial() {
    if (_state.status == CombatMatchStatus.briefing) {
      PersistenceService.instance.setCompletedTutorial(true);
      _state = _state.copyWith(status: CombatMatchStatus.activeCombat);
      notifyListeners();
    }
  }

  /// Toggles the autonomous tactical AI solver.
  void toggleAutoSolve() {
    final next = !_state.isAutoSolving;
    if (next) {
      _hasUsedAiSolver = true;
    }
    _state = _state.copyWith(
      isAutoSolving: next,
      status: next && _state.status == CombatMatchStatus.briefing
          ? CombatMatchStatus.activeCombat
          : _state.status,
    );
    solverController.reset();
    notifyListeners();
  }

  /// Toggles tactical pause (time-dilation) allowing commanders to plan shots.
  void toggleTacticalPause() {
    if (_state.status == CombatMatchStatus.activeCombat ||
        _state.status == CombatMatchStatus.sowingSequence) {
      _finalizePendingSow();
      _state = _state.copyWith(
        status: CombatMatchStatus.paused,
        clearActiveSowBay: true,
      );
      notifyListeners();
    } else if (_state.status == CombatMatchStatus.paused) {
      _state = _state.copyWith(status: CombatMatchStatus.activeCombat);
      notifyListeners();
    }
  }

  /// Pauses the combat simulation.
  void pauseCombat() {
    if (_state.status == CombatMatchStatus.activeCombat ||
        _state.status == CombatMatchStatus.sowingSequence) {
      _finalizePendingSow();
      _state = _state.copyWith(
        status: CombatMatchStatus.paused,
        clearActiveSowBay: true,
      );
      notifyListeners();
    }
  }

  /// Resumes the combat simulation from paused state.
  void resumeCombat() {
    if (_state.status == CombatMatchStatus.paused) {
      _state = _state.copyWith(status: CombatMatchStatus.activeCombat);
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _finalizePendingSow();
    damageNumbers.clear();
    bulletManager.clear();
    _state = _state.copyWith(status: CombatMatchStatus.disposed);
    super.dispose();
  }
}
