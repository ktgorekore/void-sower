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

import '../../domain/models/pro_feature.dart';
import '../../domain/services/campaign_service.dart';
import '../../domain/services/entitlement_service.dart';
import '../../domain/services/game_engine_interface.dart';
import '../../domain/services/persistence_service.dart';
import '../../domain/state/combat_match_state.dart';
import '../controllers/combat_coordinator.dart';
import '../theme/void_theme.dart';
import 'campaign_map_screen.dart';
import '../widgets/bao_codex_dialog.dart';
import '../widgets/combat_painter.dart';
import '../widgets/command_arc_widget.dart';
import '../widgets/game_over_dialog.dart';
import '../widgets/hud_header.dart';
import '../widgets/profile_modal.dart';
import '../widgets/pro_upgrade_modal.dart';
import '../widgets/projection_shelf.dart';
import '../widgets/rewarded_ad_modal.dart';
import '../widgets/settings_modal.dart';
import '../widgets/tutorial_overlay.dart';
import '../widgets/victory_dialog.dart';

/// Primary Combat Viewport shell coordinating 60 Hz rendering, state machine
/// event observation, and one-thumb input routing.
class CombatScreen extends StatefulWidget {
  const CombatScreen({
    super.key,
    required this.engine,
    this.difficultyTier = 0,
    this.sectorId = 1,
    this.onReturnToMap,
    this.autoStartSolver = false,
  });

  final IVoidSowerEngine engine;
  final int difficultyTier;
  final int sectorId;
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
  int _currentSectorId = 1;
  bool _isModalOpen = false;
  Timer? _autoAdvanceTimer;

  @override
  void initState() {
    super.initState();
    _currentSectorId = widget.sectorId;
    final sector = CampaignService.instance.getSector(_currentSectorId);
    _currentDifficultyTier = sector.difficultyTier;
    _coordinator = CombatCoordinator(
      engine: widget.engine,
      difficultyTier: _currentDifficultyTier,
    );
    _coordinator.addListener(_onCoordinatorStateChanged);
    _coordinator.initialize(
      difficulty: _currentDifficultyTier,
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
        isAmmoDepleted: _coordinator.dreadnought.reserveCores <= 0,
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
          _openMap();
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

  Future<void> _showVictoryModal() async {
    _isModalOpen = true;
    _autoAdvanceTimer?.cancel();

    final score = _coordinator.dreadnought.totalScore;
    final cores = _coordinator.dreadnought.reserveCores;
    final enemiesNeutralized = _coordinator.enemies
        .where((e) => e.isDestroyed)
        .length;
    final previousLiberated = PersistenceService.instance.liberatedSectors;

    await PersistenceService.instance.recordSectorVictory(
      sectorId: _currentSectorId,
      score: score,
      coresRemaining: cores,
      enemiesNeutralized: enemiesNeutralized > 0 ? enemiesNeutralized : 4,
    );

    if (!mounted) return;

    final newLiberated = PersistenceService.instance.liberatedSectors;
    final isNewUnlock =
        newLiberated > previousLiberated && _currentSectorId < 9;
    final nextSector = isNewUnlock
        ? CampaignService.instance.getSector(_currentSectorId + 1)
        : null;
    final allSectors = CampaignService.instance.getSectors();
    final liberatedCount = allSectors.where((s) => s.isLiberated).length;
    final currentSector = CampaignService.instance.getSector(_currentSectorId);

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => VictoryDialog(
        score: score,
        coresRemaining: cores,
        sectorId: _currentSectorId,
        sectorName: currentSector.name,
        isNewUnlock: isNewUnlock,
        unlockedSectorName: nextSector?.name,
        campaignProgressText: '$liberatedCount / 9 LIBERATED',
        onNextSector: () {
          _autoAdvanceTimer?.cancel();
          Navigator.of(dialogContext).pop();
          _isModalOpen = false;
          _advanceNextSector();
        },
        onReturnToMap: () {
          _autoAdvanceTimer?.cancel();
          Navigator.of(dialogContext).pop();
          _isModalOpen = false;
          _openMap();
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
    final sector = CampaignService.instance.getSector(_currentSectorId);
    _currentDifficultyTier = sector.difficultyTier;
    _coordinator.initialize(
      difficulty: _currentDifficultyTier,
      autoStartSolver: _coordinator.state.isAutoSolving,
    );
  }

  void _advanceNextSector() {
    if (_currentSectorId < 9) {
      _currentSectorId++;
    }
    final sector = CampaignService.instance.getSector(_currentSectorId);
    _currentDifficultyTier = sector.difficultyTier;
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

  void _openSettings() {
    final wasTicking = _ticker.isTicking;
    if (wasTicking) _ticker.stop();

    showDialog<void>(
      context: context,
      builder: (context) => SettingsModal(
        onResetTutorial: () {
          _coordinator.showTutorial();
        },
      ),
    ).then((_) {
      if (mounted &&
          wasTicking &&
          _coordinator.state.status == CombatMatchStatus.activeCombat) {
        _ticker.start();
      }
    });
  }

  void _openEmergencyFlare() {
    final wasTicking = _ticker.isTicking;
    if (wasTicking) _ticker.stop();

    showDialog<void>(
      context: context,
      builder: (context) => RewardedAdModal(
        onCoresGranted: (cores) {
          _coordinator.grantEmergencyCores(cores);
        },
      ),
    ).then((_) {
      if (mounted &&
          wasTicking &&
          _coordinator.state.status == CombatMatchStatus.activeCombat) {
        _ticker.start();
      }
    });
  }

  void _openProfile() {
    final wasTicking = _ticker.isTicking;
    if (wasTicking) _ticker.stop();

    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.75),
      builder: (context) => ProfileModal(
        onProfileUpdated: () {
          if (mounted) setState(() {});
        },
      ),
    ).then((_) {
      if (mounted &&
          wasTicking &&
          _coordinator.state.status == CombatMatchStatus.activeCombat) {
        _ticker.start();
      }
    });
  }

  @override
  void dispose() {
    _autoAdvanceTimer?.cancel();
    _ticker.dispose();
    _coordinator.removeListener(_onCoordinatorStateChanged);
    _coordinator.dispose();
    super.dispose();
  }

  void _toggleAutoSolve() {
    if (EntitlementService.instance.isFeatureAccessible(
      ProFeature.aiTacticalSolver,
    )) {
      _coordinator.toggleAutoSolve();
    } else {
      final wasTicking = _ticker.isTicking;
      if (wasTicking) _ticker.stop();

      showDialog<void>(
        context: context,
        barrierColor: Colors.black.withValues(alpha: 0.75),
        builder: (context) => ProUpgradeModal(
          highlightedFeature: ProFeature.aiTacticalSolver,
          onUnlocked: () {
            if (mounted) {
              setState(() {});
              _coordinator.toggleAutoSolve();
            }
          },
        ),
      ).then((_) {
        if (mounted &&
            wasTicking &&
            _coordinator.state.status == CombatMatchStatus.activeCombat) {
          _ticker.start();
        }
      });
    }
  }

  void _openMap() {
    if (widget.onReturnToMap != null) {
      widget.onReturnToMap!();
    } else {
      final wasTicking = _ticker.isTicking;
      if (wasTicking) _ticker.stop();
      Navigator.of(context)
          .push(
            MaterialPageRoute<void>(
              builder: (context) => CampaignMapScreen(engine: widget.engine),
            ),
          )
          .then((_) {
            if (mounted &&
                wasTicking &&
                _coordinator.state.status == CombatMatchStatus.activeCombat) {
              _ticker.start();
            }
          });
    }
  }

  void _toggleTacticalPause() {
    if (EntitlementService.instance.isFeatureAccessible(
      ProFeature.tacticalPause,
    )) {
      _coordinator.toggleTacticalPause();
    } else {
      final wasTicking = _ticker.isTicking;
      if (wasTicking) _ticker.stop();

      showDialog<void>(
        context: context,
        barrierColor: Colors.black.withValues(alpha: 0.75),
        builder: (context) => ProUpgradeModal(
          highlightedFeature: ProFeature.tacticalPause,
          onUnlocked: () {
            if (mounted) {
              setState(() {});
              _coordinator.toggleTacticalPause();
            }
          },
        ),
      ).then((_) {
        if (mounted &&
            wasTicking &&
            _coordinator.state.status == CombatMatchStatus.activeCombat) {
          _ticker.start();
        }
      });
    }
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
                  userProfile: PersistenceService.instance.userProfile,
                  onProfileTap: _openProfile,
                  reserveCores: dread.reserveCores,
                  score: dread.totalScore,
                  difficultyTier: _currentDifficultyTier,
                  sectorId: _currentSectorId,
                  sectorName: CampaignService.instance
                      .getSector(_currentSectorId)
                      .name,
                  totalInvaders: _coordinator.enemies.length,
                  invadersRemaining: _coordinator.enemies
                      .where((e) => !e.isDestroyed)
                      .length,
                  isPaused: matchState.status == CombatMatchStatus.paused,
                  onTogglePause: _toggleTacticalPause,
                  onMapTap: _openMap,
                  onSettingsTap: _openSettings,
                  onCodexTap: _openCodex,
                  onTutorialTap: _coordinator.showTutorial,
                  onEmergencyFlareTap: _openEmergencyFlare,
                  isAutoSolving: matchState.isAutoSolving,
                  onToggleAutoSolve: _toggleAutoSolve,
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
                                  onDoubleTap: () {
                                    if (matchState.canReceiveInput) {
                                      _coordinator.quickFireActiveCorridor();
                                    }
                                  },
                                  onTap: () {
                                    if (matchState.canReceiveInput) {
                                      _coordinator.quickFireActiveCorridor();
                                    }
                                  },
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      // Retained Static Skia Surface (Corridors & Defense Rails)
                                      const RepaintBoundary(
                                        child: CustomPaint(
                                          painter: CombatBackgroundPainter(),
                                        ),
                                      ),
                                      // Dynamic Combat Entities Layer (Zero Allocation)
                                      CustomPaint(
                                        size: _combatViewportSize!,
                                        painter: CombatPainter(
                                          dreadnought: dread,
                                          enemies: _coordinator.enemies,
                                          lances: _coordinator.lances,
                                          flaks: _coordinator.flaks,
                                          particles: _coordinator
                                              .particleService
                                              .activeParticles,
                                          damageNumbers:
                                              _coordinator.damageNumbers,
                                          enemyBullets: _coordinator
                                              .bulletManager
                                              .bullets,
                                          animationTime: _animationTime,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        if (matchState.status == CombatMatchStatus.paused)
                          Positioned(
                            top: 8.0,
                            left: 16.0,
                            right: 16.0,
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12.0,
                                  vertical: 4.0,
                                ),
                                decoration: BoxDecoration(
                                  color: VoidTheme.obsidianBlack.withValues(
                                    alpha: 0.9,
                                  ),
                                  borderRadius: BorderRadius.circular(10.0),
                                  border: Border.all(
                                    color: VoidTheme.solarGold,
                                    width: 1.2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: VoidTheme.solarGold.withValues(
                                        alpha: 0.35,
                                      ),
                                      blurRadius: 8.0,
                                    ),
                                  ],
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.pause_circle_filled,
                                      color: VoidTheme.solarGold,
                                      size: 14.0,
                                    ),
                                    SizedBox(width: 5.0),
                                    Text(
                                      'TACTICAL TIME DILATION • SLIDE TO AIM • TAP TO FIRE',
                                      style: TextStyle(
                                        color: VoidTheme.solarGold,
                                        fontSize: 8.5,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 0.4,
                                      ),
                                    ),
                                  ],
                                ),
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
                        // Sector Secured Banner when all hostiles are wiped
                        if (_coordinator.enemies.isNotEmpty &&
                            _coordinator.enemies.every((e) => e.isDestroyed))
                          Positioned(
                            top: 36.0,
                            left: 20.0,
                            right: 20.0,
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14.0,
                                  vertical: 6.0,
                                ),
                                decoration: BoxDecoration(
                                  color: VoidTheme.obsidianBlack.withValues(
                                    alpha: 0.92,
                                  ),
                                  borderRadius: BorderRadius.circular(12.0),
                                  border: Border.all(
                                    color: VoidTheme.emeraldShield,
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: VoidTheme.emeraldShield.withValues(
                                        alpha: 0.4,
                                      ),
                                      blurRadius: 10.0,
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.verified,
                                      color: VoidTheme.emeraldShield,
                                      size: 16.0,
                                    ),
                                    const SizedBox(width: 6.0),
                                    Text(
                                      'SECTOR $_currentSectorId SECURED • ALL HOSTILES ELIMINATED',
                                      style: const TextStyle(
                                        color: VoidTheme.emeraldShield,
                                        fontSize: 10.0,
                                        fontWeight: FontWeight.w900,
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
              child: TutorialOverlay(
                onDismiss: _coordinator.dismissTutorial,
                onOpenCodex: _openCodex,
              ),
            ),
        ],
      ),
    );
  }
}
