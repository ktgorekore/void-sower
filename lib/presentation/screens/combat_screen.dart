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
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../domain/models/bay_state.dart';
import '../../domain/models/dreadnought_state.dart';
import '../../domain/models/enemy_craft.dart';
import '../../domain/models/flak_burst.dart';
import '../../domain/models/lance_beam.dart';
import '../../domain/models/prediction_result.dart';
import '../../domain/services/game_engine_interface.dart';
import '../services/audio_service.dart';
import '../services/haptic_service.dart';
import '../services/particle_service.dart';
import '../theme/void_theme.dart';
import '../widgets/bao_codex_dialog.dart';
import '../widgets/combat_painter.dart';
import '../widgets/command_arc_widget.dart';
import '../widgets/game_over_dialog.dart';
import '../widgets/hud_header.dart';
import '../widgets/projection_shelf.dart';
import '../widgets/tutorial_overlay.dart';
import '../widgets/victory_dialog.dart';

/// Primary Combat Viewport coordinating 60 Hz simulation, rendering, and one-thumb controls.
class CombatScreen extends StatefulWidget {
  const CombatScreen({
    super.key,
    required this.engine,
    this.difficultyTier = 0,
    this.onReturnToMap,
  });

  final IVoidSowerEngine engine;
  final int difficultyTier;
  final VoidCallback? onReturnToMap;

  @override
  State<CombatScreen> createState() => _CombatScreenState();
}

class _CombatScreenState extends State<CombatScreen>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  Duration _lastElapsed = Duration.zero;
  double _animationTime = 0.0;

  final ParticleService _particleService = ParticleService(maxParticles: 300);
  final List<FloatingDamageNumber> _damageNumbers = [];
  final math.Random _random = math.Random();
  Offset _screenShake = Offset.zero;
  bool _showTutorial = false;

  int? _selectedBay;
  PredictionResult? _prediction;

  late DreadnoughtState _dreadnought;
  List<BayState> _bays = const [];
  List<EnemyCraft> _enemies = const [];
  List<LanceBeam> _lances = const [];
  List<FlakBurst> _flaks = const [];

  bool _isGameOverModalVisible = false;
  bool _isVictoryModalVisible = false;

  @override
  void initState() {
    super.initState();
    _showTutorial = widget.difficultyTier == 0;
    _startCombat();

    _ticker = createTicker(_onTick);
    _ticker.start();
  }

  void _startCombat() {
    widget.engine.initialize(startingCores: 28, boundaryY: 0.15);
    widget.engine.generateWave(
      difficulty: widget.difficultyTier,
      randomSeed: DateTime.now().millisecondsSinceEpoch % 100000,
      coreBudget: 16 + (widget.difficultyTier * 4),
      initialVelocityY: 0.02 + (widget.difficultyTier * 0.008),
    );
    _syncState();
  }

  void _onTick(Duration elapsed) {
    final dtSeconds = (_lastElapsed == Duration.zero)
        ? 0.016
        : (elapsed - _lastElapsed).inMicroseconds / 1000000.0;
    _lastElapsed = elapsed;
    final clampedDt = dtSeconds.clamp(0.001, 0.05);

    _animationTime += clampedDt;

    // Advance deterministic engine simulation
    widget.engine.stepSimulation(clampedDt);
    _particleService.update(clampedDt);

    // Update floating arcade damage numbers
    _damageNumbers.removeWhere((d) => !d.update(clampedDt));

    // Screen shake damping
    if (_screenShake != Offset.zero) {
      _screenShake = Offset(_screenShake.dx * 0.82, _screenShake.dy * 0.82);
      if (_screenShake.distance < 0.2) _screenShake = Offset.zero;
    }

    // Sync entities
    _syncState();

    // Spawn damage numbers and camera shake when lances fire
    for (final lance in _lances) {
      if (lance.active) {
        _screenShake = Offset(
          (_random.nextDouble() - 0.5) * 5.5,
          (_random.nextDouble() - 0.5) * 5.5,
        );
        if (_damageNumbers.length < 5 && _random.nextDouble() < 0.25) {
          final corridor = lance.firingBayIndex < 8
              ? lance.firingBayIndex
              : 15 - lance.firingBayIndex;
          _damageNumbers.add(
            FloatingDamageNumber(
              text: '${(lance.totalDamage * 10).toInt()}',
              x: (corridor + 0.5) * (MediaQuery.of(context).size.width / 8.0),
              y: MediaQuery.of(context).size.height * 0.35,
              color: VoidTheme.plasmaCyan,
              isCritical: lance.totalDamage >= 2.0,
            ),
          );
        }
      }
    }

    // Check FSM states
    if (_dreadnought.isGameOver && !_isGameOverModalVisible) {
      _isGameOverModalVisible = true;
      AudioService.instance.playGameOver();
      _showGameOver();
    } else if (_dreadnought.isVictory && !_isVictoryModalVisible) {
      _isVictoryModalVisible = true;
      AudioService.instance.playVictory();
      _showVictory();
    }

    if (mounted) {
      setState(() {});
    }
  }

  void _syncState() {
    _dreadnought = widget.engine.getDreadnoughtState();
    _bays = widget.engine.getBays();
    _enemies = widget.engine.getEnemies();
    _lances = widget.engine.getLances();
    _flaks = widget.engine.getFlaks();
  }

  void _handleBaySelected(int bayIndex) {
    setState(() {
      _selectedBay = bayIndex;
      _prediction = widget.engine.predictSow(bayIndex, 1);
    });
  }

  void _handleSowAction(int bayIndex, int direction) {
    HapticService.instance.sowTick();
    AudioService.instance.playSowStep();
    widget.engine.injectCore(bayIndex, direction);
    setState(() {
      _selectedBay = bayIndex;
      _prediction = widget.engine.predictSow(bayIndex, direction);
    });
  }

  void _handleInjectCore(int bayIndex, int direction) {
    HapticService.instance.injectionClick();
    AudioService.instance.playSowStep();
    widget.engine.injectCore(bayIndex, direction);
    setState(() {
      _selectedBay = bayIndex;
      _prediction = widget.engine.predictSow(bayIndex, direction);
    });
  }

  void _handleSlidePosition(double targetX) {
    widget.engine.slideDreadnought(targetX);
  }

  void _showGameOver() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => GameOverDialog(
        score: _dreadnought.totalScore,
        onRetry: () {
          Navigator.of(context).pop();
          _isGameOverModalVisible = false;
          _startCombat();
        },
        onReturnToMap: () {
          Navigator.of(context).pop();
          widget.onReturnToMap?.call();
        },
      ),
    );
  }

  void _showVictory() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => VictoryDialog(
        score: _dreadnought.totalScore,
        coresRemaining: _dreadnought.reserveCores,
        onNextSector: () {
          Navigator.of(context).pop();
          _isVictoryModalVisible = false;
          _startCombat();
        },
      ),
    );
  }

  void _openCodex() {
    showDialog<void>(
      context: context,
      builder: (context) => const BaoCodexDialog(),
    );
  }

  @override
  void dispose() {
    _ticker.dispose();
    _particleService.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VoidTheme.obsidianBlack,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                // Top HUD
                HudHeader(
                  reserveCores: _dreadnought.reserveCores,
                  score: _dreadnought.totalScore,
                  difficultyTier: widget.difficultyTier,
                  onSettingsTap: _openCodex,
                  onTutorialTap: () => setState(() => _showTutorial = true),
                ),

                // Tactical Combat Corridor (Upper Viewport)
                Expanded(
                  child: RepaintBoundary(
                    child: Transform.translate(
                      offset: _screenShake,
                      child: CustomPaint(
                        size: Size.infinite,
                        painter: CombatPainter(
                          dreadnought: _dreadnought,
                          enemies: _enemies,
                          lances: _lances,
                          flaks: _flaks,
                          particles: _particleService.activeParticles,
                          damageNumbers: _damageNumbers,
                          animationTime: _animationTime,
                        ),
                      ),
                    ),
                  ),
                ),

                // Middle Dynamic Projection Shelf
                ProjectionShelf(
                  prediction: _prediction,
                  selectedBay: _selectedBay,
                ),

                // Lower Primary Thumb Command Arc
                CommandArcWidget(
                  bays: _bays,
                  selectedBay: _selectedBay,
                  onBaySelected: _handleBaySelected,
                  onSowAction: _handleSowAction,
                  onInjectCore: _handleInjectCore,
                  onSlidePosition: _handleSlidePosition,
                ),
              ],
            ),
          ),

          // Flight Academy Onboarding Overlay
          if (_showTutorial)
            Positioned.fill(
              child: TutorialOverlay(
                onDismiss: () => setState(() => _showTutorial = false),
              ),
            ),
        ],
      ),
    );
  }
}
