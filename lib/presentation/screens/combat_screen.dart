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

import '../../core/logging.dart';
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
    this.autoStartSolver = false,
  });

  final IVoidSowerEngine engine;
  final int difficultyTier;
  final VoidCallback? onReturnToMap;
  final bool autoStartSolver;

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
  final List<EnemyBullet> _enemyBullets = [];
  double _enemyFireCooldown = 1.0;
  int _bulletIdCounter = 0;
  int? _activeSowBay;
  bool _isSowAnimating = false;

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

  late int _currentDifficultyTier;
  bool _isGameOverModalVisible = false;
  bool _isVictoryModalVisible = false;
  bool _isAutoSolving = false;
  double _solverCooldown = 0.0;

  @override
  void initState() {
    super.initState();
    _currentDifficultyTier = widget.difficultyTier;
    _isAutoSolving = widget.autoStartSolver;
    _showTutorial = !widget.autoStartSolver && (widget.difficultyTier == 0);
    if (_isAutoSolving) {
      _solverCooldown = 0.4;
    }
    _startCombat();

    _ticker = createTicker(_onTick);
    _ticker.start();
  }

  void _startCombat() {
    _selectedBay = null;
    _prediction = null;
    _enemyBullets.clear();
    _activeSowBay = null;
    _isSowAnimating = false;
    _enemyFireCooldown = 1.0;
    vlog(6, 'Combat initialized for sector difficulty $_currentDifficultyTier');
    widget.engine.initialize(startingCores: 28, boundaryY: 0.15);
    widget.engine.generateWave(
      difficulty: _currentDifficultyTier,
      randomSeed: DateTime.now().millisecondsSinceEpoch % 100000,
      coreBudget: 16 + (_currentDifficultyTier * 4),
      initialVelocityY: 0.02 + (_currentDifficultyTier * 0.008),
    );
    _syncState();
  }

  void _advanceNextSector() {
    _currentDifficultyTier = (_currentDifficultyTier + 1) % 3;
    _startCombat();
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

    final size = MediaQuery.of(context).size;
    final corridorWidth = size.width / 8.0;
    final boundaryY = size.height * 0.82;
    final topMargin = size.height * 0.06;

    // 1. Enemy assault craft firing dropping plasma bullets down corridors
    _enemyFireCooldown -= clampedDt;
    if (_enemyFireCooldown <= 0.0 && _enemies.isNotEmpty) {
      _enemyFireCooldown = 1.0 + _random.nextDouble() * 0.8;
      final activeEnemies = _enemies
          .where(
            (e) => !e.isDestroyed && e.worldPosY > 0.12 && e.worldPosY < 0.85,
          )
          .toList();
      if (activeEnemies.isNotEmpty) {
        final shooter = activeEnemies[_random.nextInt(activeEnemies.length)];
        final enemyX = (shooter.assignedCorridor + 0.5) * corridorWidth;
        final normY = shooter.worldPosY.clamp(0.0, 1.0);
        final enemyY =
            topMargin + ((1.0 - normY) / 0.85) * (boundaryY - topMargin);

        Color bulletColor = VoidTheme.crimsonFlare;
        if (shooter.vesselType == 2) {
          bulletColor = VoidTheme.solarGold;
        } else if (shooter.vesselType == 1) {
          bulletColor = VoidTheme.nebulaAmethyst;
        }

        _enemyBullets.add(
          EnemyBullet(
            id: ++_bulletIdCounter,
            assignedCorridor: shooter.assignedCorridor,
            x: enemyX,
            y: enemyY + 15.0,
            velocityY: 190.0 + (_random.nextDouble() * 40.0),
            color: bulletColor,
          ),
        );
        vlog(
          6,
          'Enemy vessel in corridor ${shooter.assignedCorridor} fired bullet',
        );
      }
    }

    // 2. Update enemy bullets & collision checks
    final dreadX =
        (_dreadnought.orbitalPositionX > 0.0 &&
            _dreadnought.orbitalPositionX <= 1.0)
        ? _dreadnought.orbitalPositionX * size.width
        : size.width * 0.5;

    final lanceCorridors = <int>{};
    for (final lance in _lances) {
      if (lance.active) {
        final c = lance.firingBayIndex < 8
            ? lance.firingBayIndex
            : 15 - lance.firingBayIndex;
        lanceCorridors.add(c);
      }
    }

    _enemyBullets.removeWhere((bullet) {
      bullet.update(clampedDt);

      // Intercepted by active Particle Lance beam
      if (lanceCorridors.contains(bullet.assignedCorridor)) {
        _particleService.spawnFlakBurst(
          bullet.x,
          bullet.y,
          VoidTheme.plasmaCyan,
          count: 12,
        );
        if (_damageNumbers.length < 8) {
          _damageNumbers.add(
            FloatingDamageNumber(
              text: 'DEFLECT +50',
              x: bullet.x,
              y: bullet.y,
              color: VoidTheme.plasmaCyan,
            ),
          );
        }
        return true;
      }

      // Intercepted by active Flak Bursts
      for (final flak in _flaks) {
        if (!flak.active) continue;
        final flakX = flak.worldPosX <= 1.0
            ? flak.worldPosX * size.width
            : flak.worldPosX;
        final flakY = flak.worldPosY <= 1.0
            ? topMargin +
                  ((1.0 - flak.worldPosY.clamp(0.0, 1.0)) / 0.85) *
                      (boundaryY - topMargin)
            : flak.worldPosY;
        final rawRadius = flak.blastRadius <= 1.0
            ? flak.blastRadius * size.width
            : flak.blastRadius;
        if ((bullet.x - flakX).abs() < rawRadius &&
            (bullet.y - flakY).abs() < rawRadius) {
          _particleService.spawnFlakBurst(
            bullet.x,
            bullet.y,
            VoidTheme.solarGold,
            count: 10,
          );
          if (_damageNumbers.length < 8) {
            _damageNumbers.add(
              FloatingDamageNumber(
                text: 'INTERCEPT +25',
                x: bullet.x,
                y: bullet.y,
                color: VoidTheme.solarGold,
              ),
            );
          }
          return true;
        }
      }

      // Reached Atmospheric Boundary / Dreadnought Flagship
      if (bullet.y >= boundaryY) {
        final hitDread = (bullet.x - dreadX).abs() < 34.0;
        if (hitDread) {
          _particleService.spawnFlakBurst(
            bullet.x,
            boundaryY,
            VoidTheme.emeraldShield,
            count: 14,
          );
          HapticService.instance.injectionClick();
          if (_damageNumbers.length < 8) {
            _damageNumbers.add(
              FloatingDamageNumber(
                text: '-10 SHIELD',
                x: bullet.x,
                y: boundaryY - 20,
                color: VoidTheme.emeraldShield,
                isCritical: true,
              ),
            );
          }
        } else {
          _particleService.spawnLanceSparks(
            bullet.x,
            boundaryY,
            VoidTheme.crimsonFlare,
            count: 8,
          );
          if (_damageNumbers.length < 8) {
            _damageNumbers.add(
              FloatingDamageNumber(
                text: '-5 ATMOS',
                x: bullet.x,
                y: boundaryY - 15,
                color: VoidTheme.crimsonFlare,
              ),
            );
          }
        }
        return true;
      }

      return bullet.y > size.height;
    });

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

    // Automatic AI Tactical Solver Step
    if (_isAutoSolving && !_isGameOverModalVisible && !_isVictoryModalVisible) {
      _solverCooldown -= clampedDt;
      if (_solverCooldown <= 0.0 && _dreadnought.isIdle) {
        _executeSolverStep();
        _solverCooldown = 1.0;
      }
    }

    if (mounted) {
      setState(() {});
    }
  }

  void _executeSolverStep() {
    if (_dreadnought.reserveCores == 0 || _dreadnought.isCascading) return;
    if (_showTutorial) {
      _showTutorial = false;
    }

    final activeEnemies = _enemies
        .where((e) => !e.isDestroyed && e.worldPosY > 0.15)
        .toList();
    if (activeEnemies.isEmpty) return;

    final activeCorridors = activeEnemies
        .map((e) => e.assignedCorridor)
        .toSet();

    int bestBay = 0;
    int bestDir = 1;
    double bestScore = -1.0;

    for (int bay = 0; bay < 16; bay++) {
      for (final dir in [1, -1]) {
        final pred = widget.engine.predictSow(bay, dir);
        double score = 0.0;

        if (pred.triggersLance &&
            activeCorridors.contains(pred.terminalCorridor)) {
          score += 1000.0 + (pred.predictedDamage * 10.0);
        }
        if (pred.triggersRelay) {
          score += 600.0 + (pred.totalCascadeLaps * 150.0);
        }
        if (pred.terminalBay >= 8) {
          score += 80.0;
        }
        if (bay < _bays.length) {
          score += _bays[bay].chargeUnits * 25.0;
        }

        if (score > bestScore) {
          bestScore = score;
          bestBay = bay;
          bestDir = dir;
        }
      }
    }

    _selectedBay = bestBay;
    _prediction = widget.engine.predictSow(bestBay, bestDir);

    // Slide dreadnought to match target corridor
    final targetCorridor = _prediction?.terminalCorridor ?? (bestBay % 8);
    final targetX = (targetCorridor / 7.0).clamp(0.0, 1.0);
    widget.engine.slideDreadnought(targetX);

    final mass = (bestBay < _bays.length) ? _bays[bestBay].chargeUnits : 1;
    _animateSowTraversal(
      originBay: bestBay,
      direction: bestDir,
      mass: mass + 1,
      onComplete: () {
        _handleInjectCore(bestBay, bestDir);
      },
    );
  }

  void _animateSowTraversal({
    required int originBay,
    required int direction,
    required int mass,
    required VoidCallback onComplete,
  }) {
    if (_isSowAnimating) {
      onComplete();
      return;
    }
    _isSowAnimating = true;

    final hops = math.min(math.max(mass, 1), 16);
    var currentHop = 0;
    var currentBay = originBay;

    void step() {
      if (!mounted) {
        _isSowAnimating = false;
        return;
      }
      if (currentHop >= hops) {
        setState(() {
          _activeSowBay = currentBay;
        });
        Future.delayed(const Duration(milliseconds: 90), () {
          if (mounted) {
            setState(() {
              _activeSowBay = null;
              _isSowAnimating = false;
            });
            onComplete();
          }
        });
        return;
      }

      currentBay = (currentBay + direction + 16) & 0x0F;
      currentHop++;
      setState(() {
        _activeSowBay = currentBay;
      });
      HapticService.instance.sowTick();
      AudioService.instance.playSowStep();

      Future.delayed(const Duration(milliseconds: 65), step);
    }

    step();
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
    final mass = (bayIndex < _bays.length) ? _bays[bayIndex].chargeUnits : 1;
    _animateSowTraversal(
      originBay: bayIndex,
      direction: direction,
      mass: mass + 1,
      onComplete: () {
        HapticService.instance.sowTick();
        AudioService.instance.playSowStep();
        widget.engine.injectCore(bayIndex, direction);
        vlog(6, 'Player sow action on bay $bayIndex dir $direction complete');
        setState(() {
          _selectedBay = bayIndex;
          _prediction = widget.engine.predictSow(bayIndex, direction);
        });
      },
    );
  }

  void _handleInjectCore(int bayIndex, int direction) {
    HapticService.instance.injectionClick();
    AudioService.instance.playSowStep();
    widget.engine.injectCore(bayIndex, direction);
    vlog(6, 'Core injected into bay $bayIndex dir $direction');
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

    if (_isAutoSolving) {
      Future.delayed(const Duration(milliseconds: 1800), () {
        if (mounted && _isGameOverModalVisible) {
          Navigator.of(context).pop();
          _isGameOverModalVisible = false;
          _startCombat();
        }
      });
    }
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
          _advanceNextSector();
        },
      ),
    );

    if (_isAutoSolving) {
      Future.delayed(const Duration(milliseconds: 1800), () {
        if (mounted && _isVictoryModalVisible) {
          Navigator.of(context).pop();
          _isVictoryModalVisible = false;
          _advanceNextSector();
        }
      });
    }
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
                  difficultyTier: _currentDifficultyTier,
                  onSettingsTap: _openCodex,
                  onTutorialTap: () => setState(() => _showTutorial = true),
                  isAutoSolving: _isAutoSolving,
                  onToggleAutoSolve: () => setState(() {
                    _isAutoSolving = !_isAutoSolving;
                    if (_isAutoSolving) {
                      _showTutorial = false;
                      _solverCooldown = 0.3;
                    }
                  }),
                ),

                // AI Tactical Solver Banner
                if (_isAutoSolving)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    color: VoidTheme.obsidianBlack.withValues(alpha: 0.7),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12.0,
                          vertical: 3.0,
                        ),
                        decoration: BoxDecoration(
                          color: VoidTheme.cardSurface.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(10.0),
                          border: Border.all(
                            color: VoidTheme.crimsonFlare,
                            width: 1.0,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: VoidTheme.crimsonFlare.withValues(
                                alpha: 0.3,
                              ),
                              blurRadius: 6.0,
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.smart_toy,
                              color: VoidTheme.crimsonFlare,
                              size: 13.0,
                            ),
                            SizedBox(width: 6.0),
                            Text(
                              'AI TACTICAL SOLVER ACTIVE',
                              style: TextStyle(
                                color: VoidTheme.crimsonFlare,
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
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
                          enemyBullets: _enemyBullets,
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
                  activeSowBay: _activeSowBay,
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
