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
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../domain/services/game_engine_interface.dart';
import '../../domain/state/combat_match_state.dart';
import '../controllers/combat_coordinator.dart';
import '../theme/void_theme.dart';
import '../widgets/bao_codex_dialog.dart';
import '../widgets/combat_painter.dart';
import '../widgets/command_arc_widget.dart';
import '../widgets/game_over_dialog.dart';
import '../widgets/hud_header.dart';
import '../widgets/projection_shelf.dart';
import '../widgets/tutorial_overlay.dart';
import '../widgets/victory_dialog.dart';

/// Primary Combat Viewport shell coordinating 60 Hz rendering, state machine
/// event observation, and one-thumb input routing.
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
  late final CombatCoordinator _coordinator;
  late final Ticker _ticker;

  Duration _lastElapsed = Duration.zero;
  double _animationTime = 0.0;
  Size? _combatViewportSize;

  int _currentDifficultyTier = 0;
  bool _isModalOpen = false;
  Timer? _autoAdvanceTimer;

  @override
  void initState() {
    super.initState();
    _currentDifficultyTier = widget.difficultyTier;
    _coordinator = CombatCoordinator(
      engine: widget.engine,
      difficultyTier: widget.difficultyTier,
    );
    _coordinator.addListener(_onCoordinatorStateChanged);
    _coordinator.initialize(
      difficulty: widget.difficultyTier,
      autoStartSolver: widget.autoStartSolver,
    );

    _ticker = createTicker(_onTick);
    _ticker.start();
  }

  int _tickCount = 0;

  void _onTick(Duration elapsed) {
    try {
      final dtSeconds = (_lastElapsed == Duration.zero)
          ? 0.016
          : (elapsed - _lastElapsed).inMicroseconds / 1000000.0;
      _lastElapsed = elapsed;
      final clampedDt = dtSeconds.clamp(0.001, 0.05);
      _animationTime += clampedDt;

      final viewport =
          _combatViewportSize ??
          Size(
            MediaQuery.sizeOf(context).width,
            MediaQuery.sizeOf(context).height * 0.78,
          );
      _coordinator.update(clampedDt, viewport);
      final matchStatus = _coordinator.state.status;
      if (matchStatus == CombatMatchStatus.defeat && !_isModalOpen) {
        _showGameOverModal();
      } else if (matchStatus == CombatMatchStatus.victory && !_isModalOpen) {
        _showVictoryModal();
      }
      if (_tickCount++ % 60 == 0) {
        debugPrint(
          '[VoidSower CombatScreen] Tick $_tickCount: status=${_coordinator.state.status.name}, enemies=${_coordinator.enemies.length}, bullets=${_coordinator.bulletManager.bullets.length}, lances=${_coordinator.lances.where((l) => l.active).length}',
        );
      }
      if (mounted) {
        setState(() {});
      }
    } catch (e, stack) {
      debugPrint(
        '[VoidSower CombatScreen] CRITICAL ERROR IN _onTick: $e\n$stack',
      );
    }
  }

  void _onCoordinatorStateChanged() {
    if (!mounted) return;
    final matchStatus = _coordinator.state.status;

    if (matchStatus == CombatMatchStatus.defeat && !_isModalOpen) {
      _showGameOverModal();
    } else if (matchStatus == CombatMatchStatus.victory && !_isModalOpen) {
      _showVictoryModal();
    }

    setState(() {});
  }

  void _showGameOverModal() {
    _isModalOpen = true;
    _autoAdvanceTimer?.cancel();

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => GameOverDialog(
        score: _coordinator.dreadnought.totalScore,
        onRetry: () {
          _autoAdvanceTimer?.cancel();
          Navigator.of(dialogContext).pop();
          _isModalOpen = false;
          _restartCombat();
        },
        onReturnToMap: () {
          _autoAdvanceTimer?.cancel();
          Navigator.of(dialogContext).pop();
          _isModalOpen = false;
          widget.onReturnToMap?.call();
        },
      ),
    );

    if (_coordinator.state.isAutoSolving) {
      _autoAdvanceTimer = Timer(const Duration(milliseconds: 1800), () {
        if (mounted && _isModalOpen) {
          Navigator.of(context, rootNavigator: true).pop();
          _isModalOpen = false;
          _restartCombat();
        }
      });
    }
  }

  void _showVictoryModal() {
    _isModalOpen = true;
    _autoAdvanceTimer?.cancel();

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => VictoryDialog(
        score: _coordinator.dreadnought.totalScore,
        coresRemaining: _coordinator.dreadnought.reserveCores,
        onNextSector: () {
          _autoAdvanceTimer?.cancel();
          Navigator.of(dialogContext).pop();
          _isModalOpen = false;
          _advanceNextSector();
        },
      ),
    );

    if (_coordinator.state.isAutoSolving) {
      _autoAdvanceTimer = Timer(const Duration(milliseconds: 1800), () {
        if (mounted && _isModalOpen) {
          Navigator.of(context, rootNavigator: true).pop();
          _isModalOpen = false;
          _advanceNextSector();
        }
      });
    }
  }

  void _restartCombat() {
    _coordinator.initialize(
      difficulty: _currentDifficultyTier,
      autoStartSolver: _coordinator.state.isAutoSolving,
    );
  }

  void _advanceNextSector() {
    _currentDifficultyTier = (_currentDifficultyTier + 1) % 3;
    _coordinator.initialize(
      difficulty: _currentDifficultyTier,
      autoStartSolver: _coordinator.state.isAutoSolving,
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
    _autoAdvanceTimer?.cancel();
    _ticker.dispose();
    _coordinator.removeListener(_onCoordinatorStateChanged);
    _coordinator.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final matchState = _coordinator.state;
    final dread = _coordinator.dreadnought;

    return Scaffold(
      backgroundColor: VoidTheme.obsidianBlack,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                // Top HUD
                HudHeader(
                  reserveCores: dread.reserveCores,
                  score: dread.totalScore,
                  difficultyTier: _currentDifficultyTier,
                  onSettingsTap: _openCodex,
                  onTutorialTap: () {
                    _coordinator.dismissTutorial();
                  },
                  isAutoSolving: matchState.isAutoSolving,
                  onToggleAutoSolve: _coordinator.toggleAutoSolve,
                ),

                // Tactical Combat Corridor (Upper Viewport)
                Expanded(
                  child: RepaintBoundary(
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: Transform.translate(
                            offset: matchState.screenShake,
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                _combatViewportSize = Size(
                                  constraints.maxWidth,
                                  constraints.maxHeight,
                                );
                                return GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onPanUpdate: (details) {
                                    final normX =
                                        (details.localPosition.dx /
                                                constraints.maxWidth)
                                            .clamp(0.0, 1.0);
                                    _coordinator.slidePosition(normX);
                                  },
                                  onTap: () {
                                    if (matchState.selectedBay != null &&
                                        matchState.canReceiveInput) {
                                      _coordinator.injectCore(
                                        matchState.selectedBay!,
                                        1,
                                      );
                                    }
                                  },
                                  child: CustomPaint(
                                    size: _combatViewportSize!,
                                    painter: CombatPainter(
                                      dreadnought: dread,
                                      enemies: _coordinator.enemies,
                                      lances: _coordinator.lances,
                                      flaks: _coordinator.flaks,
                                      particles: _coordinator
                                          .particleService
                                          .activeParticles,
                                      damageNumbers: _coordinator.damageNumbers,
                                      enemyBullets:
                                          _coordinator.bulletManager.bullets,
                                      animationTime: _animationTime,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        // Floating AI Tactical Solver Badge (Zero vertical footprint)
                        if (matchState.isAutoSolving)
                          Positioned(
                            top: 6.0,
                            left: 0,
                            right: 0,
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10.0,
                                  vertical: 2.5,
                                ),
                                decoration: BoxDecoration(
                                  color: VoidTheme.cardSurface.withValues(
                                    alpha: 0.85,
                                  ),
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
                                      size: 12.0,
                                    ),
                                    SizedBox(width: 5.0),
                                    Text(
                                      'AI TACTICAL SOLVER ACTIVE',
                                      style: TextStyle(
                                        color: VoidTheme.crimsonFlare,
                                        fontSize: 9.0,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                // Middle Dynamic Projection Shelf
                ProjectionShelf(
                  prediction: _coordinator.prediction,
                  selectedBay: matchState.selectedBay,
                ),

                // Lower Primary Thumb Command Arc
                CommandArcWidget(
                  bays: _coordinator.bays,
                  selectedBay: matchState.selectedBay,
                  activeSowBay: matchState.activeSowBay,
                  onBaySelected: _coordinator.selectBay,
                  onSowAction: _coordinator.sow,
                  onInjectCore: _coordinator.injectCore,
                  onSlidePosition: _coordinator.slidePosition,
                ),
              ],
            ),
          ),

          // Flight Academy Onboarding Overlay
          if (matchState.status == CombatMatchStatus.briefing)
            Positioned.fill(
              child: TutorialOverlay(onDismiss: _coordinator.dismissTutorial),
            ),
        ],
      ),
    );
  }
}
