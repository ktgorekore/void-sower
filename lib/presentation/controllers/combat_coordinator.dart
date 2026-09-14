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
import '../../domain/models/dreadnought_state.dart';
import '../../domain/models/enemy_craft.dart';
import '../../domain/models/flak_burst.dart';
import '../../domain/models/floating_damage_number.dart';
import '../../domain/models/lance_beam.dart';
import '../../domain/models/prediction_result.dart';
import '../../domain/services/game_engine_interface.dart';
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
  PredictionResult? prediction;

  Set<int> _activeLanceBays = <int>{};
  bool _hasActiveFlak = false;
  bool _isDisposed = false;
  Completer<void>? _sowAnimationCompleter;

  int _currentDifficulty = 0;
  int get currentDifficulty => _currentDifficulty;

  /// Initializes engine entities, procedurally generates the solvable combat wave,
  /// and primes the FSM.
  void initialize({
    int? difficulty,
    int startingCores = 28,
    double boundaryY = 0.15,
    bool autoStartSolver = false,
  }) {
    _currentDifficulty = difficulty ?? difficultyTier;
    vlog(
      6,
      'CombatCoordinator: Initializing sector difficulty $_currentDifficulty',
    );
    engine.initialize(startingCores: startingCores, boundaryY: boundaryY);
    engine.generateWave(
      difficulty: _currentDifficulty,
      randomSeed: DateTime.now().millisecondsSinceEpoch % 100000,
      coreBudget: 16 + (_currentDifficulty * 4),
      initialVelocityY: 0.02 + (_currentDifficulty * 0.008),
    );
    _syncDomainState();

    damageNumbers.clear();
    bulletManager.clear();
    _activeLanceBays.clear();
    _hasActiveFlak = false;

    const initialBay = 11;
    prediction = engine.predictSow(initialBay, 1);

    _state = CombatMatchState(
      status: (_currentDifficulty == 0 && !autoStartSolver)
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
  }

  /// Core 60 Hz update step driving physics, FSM, and rendering state.
  void update(double dt, Size viewportSize) {
    if (_isDisposed) return;
    final clampedDt = dt.clamp(0.001, 0.05);

    // 1. Advance native C++ simulation
    engine.stepSimulation(clampedDt);
    _syncDomainState();

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
    );

    // 6. Reactive audio triggers on newly active lances and flak detonations
    for (final lance in lances) {
      if (lance.active && !_activeLanceBays.contains(lance.firingBayIndex)) {
        audio.onLanceFired();
      }
    }
    _activeLanceBays = lances
        .where((l) => l.active)
        .map((l) => l.firingBayIndex)
        .toSet();

    final nowHasFlak = flaks.any((f) => f.active);
    if (nowHasFlak && !_hasActiveFlak) {
      audio.onFlakDetonated();
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
          damageNumbers.add(
            FloatingDamageNumber(
              text: '${(lance.totalDamage * 10).toInt()}',
              x: (corridor + 0.5) * (viewportSize.width / 8.0),
              y: viewportSize.height * 0.35,
              color: VoidTheme.plasmaCyan,
              isCritical: lance.totalDamage >= 2.0,
            ),
          );
        }
      }
    }

    // 8. FSM Terminal State Evaluations
    if (dreadnought.isGameOver && _state.status != CombatMatchStatus.defeat) {
      _state = _state.copyWith(status: CombatMatchStatus.defeat);
      audio.onDefeat();
      notifyListeners();
    } else if (dreadnought.isVictory &&
        _state.status != CombatMatchStatus.victory) {
      _state = _state.copyWith(status: CombatMatchStatus.victory);
      audio.onVictory();
      notifyListeners();
    }

    // 9. Autonomous AI Tactical Solver step
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
    engine.slideDreadnought(targetSlideX);
    _state = _state.copyWith(selectedBay: bayIndex);
    prediction = engine.predictSow(bayIndex, direction);
    sow(bayIndex, direction);
  }

  /// Selects a bay for aiming and forward prediction.
  void selectBay(int bayIndex) {
    if (!_state.canReceiveInput) return;
    _state = _state.copyWith(selectedBay: bayIndex);
    prediction = engine.predictSow(bayIndex, 1);
    notifyListeners();
  }

  /// Triggers a sequential pit-to-pit sowing traversal animation then executes on native engine.
  void sow(int bayIndex, int direction) {
    if (_state.status == CombatMatchStatus.sowingSequence) return;
    final mass = (bayIndex < bays.length) ? bays[bayIndex].chargeUnits : 1;

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
      if (_isDisposed || remainingHops <= 0) {
        if (!_isDisposed) {
          HapticService.instance.sowTick();
          audio.onSowStep(cascadeDepth: 0);
          engine.injectCore(bayIndex, direction);
          vlog(
            6,
            'CombatCoordinator: Sow completed for bay $bayIndex dir $direction',
          );
          _syncDomainState();
          _state = _state.copyWith(
            status: CombatMatchStatus.activeCombat,
            clearActiveSowBay: true,
            selectedBay: bayIndex,
          );
          prediction = engine.predictSow(bayIndex, direction);
          notifyListeners();
        }
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

      Future.delayed(const Duration(milliseconds: 65), step);
    }

    step();
  }

  /// Direct core injection into a designated bay.
  void injectCore(int bayIndex, int direction) {
    if (!_state.canReceiveInput) return;
    HapticService.instance.injectionClick();
    audio.onCoreInjected();
    engine.injectCore(bayIndex, direction);
    vlog(
      6,
      'CombatCoordinator: Injected core into bay $bayIndex dir $direction',
    );
    _syncDomainState();
    _state = _state.copyWith(selectedBay: bayIndex);
    prediction = engine.predictSow(bayIndex, direction);
    notifyListeners();
  }

  /// Sets the dreadnought's target horizontal position.
  void slidePosition(double targetX) {
    engine.slideDreadnought(targetX);
    final corridor = (targetX * 8.0).floor().clamp(0, 7);
    final frontlineBay = corridor + 8;
    if (_state.selectedBay != frontlineBay &&
        _state.status != CombatMatchStatus.sowingSequence) {
      _state = _state.copyWith(selectedBay: frontlineBay);
      prediction = engine.predictSow(frontlineBay, 1);
      notifyListeners();
    }
  }

  /// Dismisses tactical tutorial overlay and starts active combat.
  void dismissTutorial() {
    if (_state.status == CombatMatchStatus.briefing) {
      _state = _state.copyWith(status: CombatMatchStatus.activeCombat);
      notifyListeners();
    }
  }

  /// Toggles the autonomous tactical AI solver.
  void toggleAutoSolve() {
    final next = !_state.isAutoSolving;
    _state = _state.copyWith(
      isAutoSolving: next,
      status: next && _state.status == CombatMatchStatus.briefing
          ? CombatMatchStatus.activeCombat
          : _state.status,
    );
    solverController.reset();
    notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    if (_sowAnimationCompleter != null &&
        !_sowAnimationCompleter!.isCompleted) {
      _sowAnimationCompleter!.complete();
    }
    damageNumbers.clear();
    bulletManager.clear();
    _state = _state.copyWith(status: CombatMatchStatus.disposed);
    super.dispose();
  }
}
