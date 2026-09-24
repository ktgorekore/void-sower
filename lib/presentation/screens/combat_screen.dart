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

import '../../domain/models/campaign_sector.dart';
import '../../domain/models/pro_feature.dart';
import '../../domain/services/campaign_service.dart';
import '../../domain/services/entitlement_service.dart';
import '../../domain/services/game_engine_interface.dart';
import '../../domain/services/persistence_service.dart';
import '../../domain/state/combat_match_state.dart';
import '../controllers/combat_coordinator.dart';
import '../controllers/combat_overlay_state.dart';
import '../theme/void_theme.dart';
import 'campaign_map_screen.dart';
import '../widgets/combat_painter.dart';
import '../widgets/command_arc_widget.dart';
import '../widgets/game_over_dialog.dart';
import '../widgets/hud_header.dart';
import '../widgets/landscape_orientation_shield.dart';
import '../widgets/pause_menu_dialog.dart';
import '../widgets/profile_modal.dart';
import '../widgets/pro_upgrade_modal.dart';
import '../widgets/rewarded_ad_modal.dart';
import '../widgets/settings_modal.dart';
import '../widgets/tactical_directives_modal.dart';
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
    this.sector,
    this.onReturnToMap,
    this.autoStartSolver = false,
    this.startWithTutorial = false,
  });

  final IVoidSowerEngine engine;
  final int difficultyTier;
  final int sectorId;
  final CampaignSector? sector;
  final VoidCallback? onReturnToMap;
  final bool autoStartSolver;
  final bool startWithTutorial;

  @override
  State<CombatScreen> createState() => _CombatScreenState();
}

class _CombatScreenState extends State<CombatScreen>
    with SingleTickerProviderStateMixin {
  late final CombatCoordinator _coordinator;
  late final Ticker _ticker;
  late final ValueNotifier<double> _renderNotifier;

  Duration _lastElapsed = Duration.zero;
  double _animationTime = 0.0;
  Size? _combatViewportSize;

  int _currentDifficultyTier = 0;
  int _currentSectorId = 1;
  CombatOverlayState _overlayState = CombatOverlayState.none;
  Timer? _autoAdvanceTimer;

  int _lastReserveCores = -1;
  int _lastTotalScore = -1;
  int _lastInvadersRemaining = -1;
  CombatMatchStatus? _lastStatus;
  int? _lastSelectedBay;
  int? _lastActiveSowBay;
  bool _lastAutoSolving = false;
  int _targetFps = 60;
  int _lastTickMicros = 0;

  @override
  void initState() {
    super.initState();
    _renderNotifier = ValueNotifier<double>(0.0);
    final isLowBattery = PersistenceService.instance.lowBatteryMode;
    _targetFps = isLowBattery ? 30 : PersistenceService.instance.targetFps;

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
      sector: widget.sector ?? sector,
      autoStartSolver: widget.autoStartSolver,
      startWithTutorial: widget.startWithTutorial,
    );

    _ticker = createTicker(_onTick);
    _ticker.start();
  }

  int _tickCount = 0;

  void _onTick(Duration elapsed) {
    try {
      final nowMicros = elapsed.inMicroseconds;
      if (_lastTickMicros > 0) {
        final frameIntervalMicros = (1000000 / _targetFps).round();
        if ((nowMicros - _lastTickMicros) < (frameIntervalMicros - 1500)) {
          return;
        }
      }
      _lastTickMicros = nowMicros;

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
      if (_overlayState == CombatOverlayState.none) {
        if (matchStatus == CombatMatchStatus.defeat) {
          _showGameOverModal();
        } else if (matchStatus == CombatMatchStatus.victory) {
          _showVictoryModal();
        }
      }
      if (_tickCount++ % 60 == 0) {
        debugPrint(
          '[VoidSower CombatScreen] Tick $_tickCount: status=${_coordinator.state.status.name}, enemies=${_coordinator.enemies.length}, bullets=${_coordinator.bulletManager.bullets.length}, lances=${_coordinator.lances.where((l) => l.active).length}',
        );
      }

      final dread = _coordinator.dreadnought;
      final remaining = _coordinator.enemies
          .where((e) => !e.isDestroyed)
          .length;
      final state = _coordinator.state;

      final hudChanged =
          dread.reserveCores != _lastReserveCores ||
          dread.totalScore != _lastTotalScore ||
          remaining != _lastInvadersRemaining ||
          state.status != _lastStatus ||
          state.selectedBay != _lastSelectedBay ||
          state.activeSowBay != _lastActiveSowBay ||
          state.isAutoSolving != _lastAutoSolving;

      if (hudChanged) {
        _lastReserveCores = dread.reserveCores;
        _lastTotalScore = dread.totalScore;
        _lastInvadersRemaining = remaining;
        _lastStatus = state.status;
        _lastSelectedBay = state.selectedBay;
        _lastActiveSowBay = state.activeSowBay;
        _lastAutoSolving = state.isAutoSolving;
        if (mounted) {
          setState(() {});
        }
      }

      _renderNotifier.value = _animationTime;
    } catch (e, stack) {
      debugPrint(
        '[VoidSower CombatScreen] CRITICAL ERROR IN _onTick: $e\n$stack',
      );
    }
  }

  void _onCoordinatorStateChanged() {
    if (!mounted) return;
    final matchStatus = _coordinator.state.status;

    if (_overlayState == CombatOverlayState.none) {
      if (matchStatus == CombatMatchStatus.defeat) {
        _showGameOverModal();
      } else if (matchStatus == CombatMatchStatus.victory) {
        _showVictoryModal();
      }
    }

    setState(() {});
  }

  Future<void> _showGameOverModal() async {
    if (_overlayState.isTerminalFlow || _overlayState.isModalOpen) return;
    _overlayState = CombatOverlayState.defeatGrace;
    _autoAdvanceTimer?.cancel();

    // 400ms grace period so in-flight shooting taps subside and breach explosion renders
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted || _overlayState != CombatOverlayState.defeatGrace) {
      return;
    }

    final currentScore = _coordinator.dreadnought.totalScore;
    final defeatSector = CampaignService.instance.getSector(_currentSectorId);
    final isAiAssisted = _coordinator.hasUsedAiSolver;

    if (!isAiAssisted) {
      await PersistenceService.instance.recordSectorDefeat(
        sectorId: _currentSectorId,
        score: currentScore,
        lancesFired: _coordinator.sessionLancesFired,
        flakBursts: _coordinator.sessionFlakBursts,
        seedsSown: _coordinator.sessionSeedsSown,
        maxCascadeLaps: _coordinator.sessionMaxCascade,
        flightTimeSeconds: _coordinator.sessionFlightTimeSeconds,
        chassisId: PersistenceService.instance.selectedChassisId,
        campaignId: defeatSector.campaignId,
      );
    }

    if (!mounted || _overlayState != CombatOverlayState.defeatGrace) {
      return;
    }
    _overlayState = CombatOverlayState.defeatModal;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => GameOverDialog(
        score: currentScore,
        highScore: _coordinator.highScore,
        isAmmoDepleted: _coordinator.dreadnought.reserveCores <= 0,
        isAiAssisted: isAiAssisted,
        armDuration: const Duration(milliseconds: 500),
        onRetry: () {
          _autoAdvanceTimer?.cancel();
          Navigator.of(dialogContext).pop();
          _restartCombat();
        },
        onReturnToMap: () {
          _autoAdvanceTimer?.cancel();
          Navigator.of(dialogContext).pop();
          _overlayState = CombatOverlayState.none;
          _openMap();
        },
      ),
    );

    if (_coordinator.state.isAutoSolving) {
      _autoAdvanceTimer = Timer(const Duration(milliseconds: 1800), () {
        if (mounted && _overlayState == CombatOverlayState.defeatModal) {
          Navigator.of(context, rootNavigator: true).pop();
          _restartCombat();
        }
      });
    }
  }

  Future<void> _showVictoryModal() async {
    if (_overlayState == CombatOverlayState.victoryReview) {
      // Re-opening victory dialog from battlefield review dock
    } else if (_overlayState.isTerminalFlow || _overlayState.isModalOpen) {
      return;
    }
    _overlayState = CombatOverlayState.victoryGrace;
    _autoAdvanceTimer?.cancel();

    // 600ms grace period so in-flight shooting taps clear, animations finish,
    // and victory fanfare plays before modal interrupts.
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted || _overlayState != CombatOverlayState.victoryGrace) {
      return;
    }

    final score = _coordinator.dreadnought.totalScore;
    final cores = _coordinator.dreadnought.reserveCores;
    final enemiesNeutralized = _coordinator.enemies
        .where((e) => e.isDestroyed)
        .length;
    final currentSector = CampaignService.instance.getSector(_currentSectorId);
    final isAiAssisted = _coordinator.hasUsedAiSolver;

    if (!isAiAssisted) {
      await PersistenceService.instance.recordSectorVictory(
        sectorId: _currentSectorId,
        score: score,
        coresRemaining: cores,
        enemiesNeutralized: enemiesNeutralized > 0 ? enemiesNeutralized : 4,
        lancesFired: _coordinator.sessionLancesFired,
        flakBursts: _coordinator.sessionFlakBursts,
        seedsSown: _coordinator.sessionSeedsSown,
        maxCascadeLaps: _coordinator.sessionMaxCascade,
        flightTimeSeconds: _coordinator.sessionFlightTimeSeconds,
        chassisId: PersistenceService.instance.selectedChassisId,
        campaignId: currentSector.campaignId,
      );
    }

    if (!mounted || _overlayState != CombatOverlayState.victoryGrace) {
      return;
    }
    _overlayState = CombatOverlayState.victoryModal;

    final operation = CampaignService.instance.getOperation(
      currentSector.campaignId,
    );
    final isPro = EntitlementService.instance.isProUnlocked;
    final maxSectorInOperation =
        operation.baseSectorId + operation.sectors.length - 1;
    final nextSectorCandidate = _currentSectorId < maxSectorInOperation
        ? CampaignService.instance.getSector(_currentSectorId + 1)
        : null;
    final canAdvance =
        nextSectorCandidate != null &&
        (isPro || nextSectorCandidate.isUnlocked);
    final isNewUnlock = !isPro && canAdvance;
    final nextSector = isNewUnlock ? nextSectorCandidate : null;
    final liberatedInCampaign = PersistenceService.instance
        .getLiberatedSectorsForCampaign(currentSector.campaignId);

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => VictoryDialog(
        score: score,
        highScore: _coordinator.highScore,
        coresRemaining: cores,
        sectorId: _currentSectorId,
        sectorName: currentSector.name,
        isNewUnlock: isNewUnlock,
        unlockedSectorName: nextSector?.name,
        campaignProgressText:
            '$liberatedInCampaign / ${operation.sectors.length} LIBERATED',
        armDuration: const Duration(milliseconds: 500),
        canAdvance: canAdvance,
        isAiAssisted: isAiAssisted,
        onUpgradePro: !isPro
            ? () {
                _autoAdvanceTimer?.cancel();
                Navigator.of(dialogContext).pop();
                showDialog<void>(
                  context: context,
                  builder: (context) => ProUpgradeModal(
                    highlightedFeature: ProFeature.proCampaignTheaters,
                    onUnlocked: () {
                      if (mounted) setState(() {});
                    },
                  ),
                );
              }
            : null,
        onNextSector: () {
          _autoAdvanceTimer?.cancel();
          Navigator.of(dialogContext).pop();
          if (canAdvance) {
            _advanceNextSector();
          } else {
            _restartCombat();
          }
        },
        onReturnToMap: () {
          _autoAdvanceTimer?.cancel();
          Navigator.of(dialogContext).pop();
          _overlayState = CombatOverlayState.none;
          _openMap();
        },
        onDismiss: () {
          _autoAdvanceTimer?.cancel();
          Navigator.of(dialogContext).pop();
          _overlayState = CombatOverlayState.victoryReview;
          if (mounted) setState(() {});
        },
      ),
    );

    if (_coordinator.state.isAutoSolving && canAdvance) {
      _autoAdvanceTimer = Timer(const Duration(milliseconds: 1800), () {
        if (mounted && _overlayState == CombatOverlayState.victoryModal) {
          Navigator.of(context, rootNavigator: true).pop();
          _advanceNextSector();
        }
      });
    }
  }

  void _restartCombat() {
    _overlayState = CombatOverlayState.none;
    final sector = CampaignService.instance.getSector(_currentSectorId);
    _currentDifficultyTier = sector.difficultyTier;
    _coordinator.initialize(
      difficulty: _currentDifficultyTier,
      sector: sector,
      autoStartSolver: _coordinator.state.isAutoSolving,
    );
    if (!_ticker.isTicking) {
      _lastElapsed = Duration.zero;
      _ticker.start();
    }
    if (mounted) setState(() {});
  }

  void _advanceNextSector() {
    _overlayState = CombatOverlayState.none;
    final currentSector = CampaignService.instance.getSector(_currentSectorId);
    final operation = CampaignService.instance.getOperation(
      currentSector.campaignId,
    );
    final maxSectorInOperation =
        operation.baseSectorId + operation.sectors.length - 1;
    if (_currentSectorId < maxSectorInOperation) {
      _currentSectorId++;
    }
    final sector = CampaignService.instance.getSector(_currentSectorId);
    _currentDifficultyTier = sector.difficultyTier;
    _coordinator.initialize(
      difficulty: _currentDifficultyTier,
      sector: sector,
      autoStartSolver: _coordinator.state.isAutoSolving,
    );
    if (!_ticker.isTicking) {
      _lastElapsed = Duration.zero;
      _ticker.start();
    }
    if (mounted) setState(() {});
  }

  void _openCodex() {
    if (_overlayState != CombatOverlayState.none) return;
    _overlayState = CombatOverlayState.codex;
    final wasTicking = _ticker.isTicking;
    if (wasTicking) _ticker.stop();
    if (_coordinator.state.status == CombatMatchStatus.briefing) {
      _coordinator.dismissTutorial();
    }

    showDialog<void>(
      context: context,
      builder: (context) => TacticalDirectivesModal(
        onLaunchAcademy: () {
          _coordinator.showTutorial();
        },
      ),
    ).then((_) {
      _overlayState = CombatOverlayState.none;
      if (mounted &&
          wasTicking &&
          _coordinator.state.status != CombatMatchStatus.briefing) {
        _ticker.start();
      }
    });
  }

  void _openSettings() {
    if (_overlayState != CombatOverlayState.none) return;
    _overlayState = CombatOverlayState.settings;
    final wasTicking = _ticker.isTicking;
    if (wasTicking) _ticker.stop();

    showDialog<void>(
      context: context,
      builder: (context) => SettingsModal(
        onLaunchAcademy: () {
          _coordinator.showTutorial();
        },
        onResetTutorial: () {
          _coordinator.showTutorial();
        },
      ),
    ).then((_) {
      _overlayState = CombatOverlayState.none;
      if (mounted &&
          wasTicking &&
          _coordinator.state.status != CombatMatchStatus.briefing) {
        _ticker.start();
      }
    });
  }

  void _openEmergencyFlare() {
    if (_overlayState != CombatOverlayState.none) return;
    _overlayState = CombatOverlayState.emergencyFlare;
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
      _overlayState = CombatOverlayState.none;
      if (mounted && wasTicking) {
        _ticker.start();
      }
    });
  }

  void _openProfile() {
    if (_overlayState != CombatOverlayState.none) return;
    _overlayState = CombatOverlayState.profile;
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
      _overlayState = CombatOverlayState.none;
      if (mounted && wasTicking) {
        _ticker.start();
      }
    });
  }

  @override
  void dispose() {
    _autoAdvanceTimer?.cancel();
    _ticker.dispose();
    _renderNotifier.dispose();
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
        if (mounted && wasTicking) {
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
            if (mounted && wasTicking) {
              _ticker.start();
            }
          });
    }
  }

  void _openPauseMenu() {
    if (_overlayState != CombatOverlayState.none) return;
    _coordinator.pauseCombat();
    _overlayState = CombatOverlayState.paused;

    bool shouldResumeOnClose = true;

    showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.75),
      builder: (dialogContext) => PauseMenuDialog(
        sectorId: _currentSectorId,
        sectorName: CampaignService.instance.getSector(_currentSectorId).name,
        difficultyTier: _currentDifficultyTier,
        score: _coordinator.competitiveScore,
        highScore: _coordinator.highScore,
        onResume: () {
          Navigator.of(dialogContext).pop();
        },
        onRestart: () {
          shouldResumeOnClose = false;
          Navigator.of(dialogContext).pop();
          _restartCombat();
        },
        onAbort: () {
          shouldResumeOnClose = false;
          Navigator.of(dialogContext).pop();
          _overlayState = CombatOverlayState.none;
          _openMap();
        },
        onMap: () {
          shouldResumeOnClose = false;
          Navigator.of(dialogContext).pop();
          _overlayState = CombatOverlayState.none;
          _openMap();
        },
        onCodex: () {
          shouldResumeOnClose = false;
          Navigator.of(dialogContext).pop();
          _overlayState = CombatOverlayState.none;
          _openCodex();
        },
        onAcademy: () {
          shouldResumeOnClose = false;
          Navigator.of(dialogContext).pop();
          _overlayState = CombatOverlayState.none;
          _coordinator.showTutorial();
        },
        onSettings: () {
          shouldResumeOnClose = false;
          Navigator.of(dialogContext).pop();
          _overlayState = CombatOverlayState.none;
          _openSettings();
        },
        isAutoSolving: _coordinator.state.isAutoSolving,
        onToggleAutoSolve: () {
          _toggleAutoSolve();
          (dialogContext as Element).markNeedsBuild();
        },
      ),
    ).then((_) {
      if (_overlayState == CombatOverlayState.paused) {
        _overlayState = CombatOverlayState.none;
      }
      if (mounted &&
          shouldResumeOnClose &&
          _coordinator.state.status == CombatMatchStatus.paused) {
        _resumeCombat();
      }
    });
  }

  void _resumeCombat() {
    if (!_ticker.isTicking) {
      _lastElapsed = Duration.zero;
      _ticker.start();
    }
    _coordinator.resumeCombat();
    if (mounted) setState(() {});
  }

  void _toggleTacticalPause() {
    _openPauseMenu();
  }

  @override
  Widget build(BuildContext context) {
    final matchState = _coordinator.state;
    final dread = _coordinator.dreadnought;

    final isSecured =
        matchState.status == CombatMatchStatus.victory ||
        (_coordinator.enemies.isNotEmpty &&
            _coordinator.enemies.every((e) => e.isDestroyed) &&
            _coordinator.remainingReinforcements <= 0);

    return Scaffold(
      backgroundColor: VoidTheme.obsidianBlack,
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Compact landscape guard (height < 520 dp on landscape devices)
          if (constraints.maxWidth > constraints.maxHeight &&
              constraints.maxHeight < 520.0) {
            return const LandscapeOrientationShield();
          }

          final isTabletWidth = constraints.maxWidth > 580.0;

          return Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 580.0),
              decoration: isTabletWidth
                  ? BoxDecoration(
                      border: Border.symmetric(
                        vertical: BorderSide(
                          color: VoidTheme.cardSurface.withValues(alpha: 0.8),
                          width: 1.5,
                        ),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: VoidTheme.plasmaCyan.withValues(alpha: 0.08),
                          blurRadius: 18.0,
                          spreadRadius: 2.0,
                        ),
                      ],
                    )
                  : null,
              child: Stack(
                children: [
                  SafeArea(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Top HUD (Isolated RepaintBoundary)
                        RepaintBoundary(
                          child: HudHeader(
                            userProfile:
                                PersistenceService.instance.userProfile,
                            onProfileTap: _openProfile,
                            reserveCores: dread.reserveCores,
                            score: _coordinator.competitiveScore,
                            highScore: _coordinator.highScore,
                            isAiAssisted: _coordinator.hasUsedAiSolver,
                            isPro: EntitlementService.instance.isProUnlocked,
                            difficultyTier: _currentDifficultyTier,
                            sectorId: _currentSectorId,
                            sectorName: CampaignService.instance
                                .getSector(_currentSectorId)
                                .name,
                            totalInvaders:
                                _coordinator.enemies.length +
                                _coordinator.remainingReinforcements,
                            invadersRemaining:
                                _coordinator.enemies
                                    .where((e) => !e.isDestroyed)
                                    .length +
                                _coordinator.remainingReinforcements,
                            isPaused:
                                matchState.status == CombatMatchStatus.paused ||
                                _overlayState == CombatOverlayState.paused,
                            onTogglePause: _toggleTacticalPause,
                            onRestartTap: _restartCombat,
                            onStopTap: _openMap,
                            onMapTap: _openMap,
                            onNextSectorTap: () {
                              if (_overlayState ==
                                  CombatOverlayState.victoryReview) {
                                _showVictoryModal();
                              } else {
                                _advanceNextSector();
                              }
                            },
                            isSecured: isSecured,
                            onSettingsTap: _openSettings,
                            onCodexTap: _openCodex,
                            onTutorialTap: _coordinator.showTutorial,
                            onEmergencyFlareTap: _openEmergencyFlare,
                            isAutoSolving: matchState.isAutoSolving,
                            onToggleAutoSolve: _toggleAutoSolve,
                          ),
                        ),

                        // Tactical Combat Corridor (Upper Viewport)
                        Expanded(
                          child: RepaintBoundary(
                            child: Stack(
                              children: [
                                Positioned.fill(
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
                                            _coordinator
                                                .quickFireActiveCorridor();
                                          }
                                        },
                                        onTap: () {
                                          if (matchState.canReceiveInput) {
                                            _coordinator
                                                .quickFireActiveCorridor();
                                          }
                                        },
                                        child: Stack(
                                          fit: StackFit.expand,
                                          children: [
                                            // Retained Static Skia Surface (Corridors & Defense Rails)
                                            const RepaintBoundary(
                                              child: CustomPaint(
                                                painter:
                                                    CombatBackgroundPainter(),
                                              ),
                                            ),
                                            // Dynamic Combat Entities Layer (Zero Allocation & Isolated Repaint)
                                            RepaintBoundary(
                                              child: ListenableBuilder(
                                                listenable: _renderNotifier,
                                                builder: (context, _) {
                                                  return Transform.translate(
                                                    offset: _coordinator
                                                        .state
                                                        .screenShake,
                                                    child: CustomPaint(
                                                      size:
                                                          _combatViewportSize!,
                                                      painter: CombatPainter(
                                                        dreadnought:
                                                            _coordinator
                                                                .dreadnought,
                                                        enemies: _coordinator
                                                            .enemies,
                                                        lances:
                                                            _coordinator.lances,
                                                        flaks:
                                                            _coordinator.flaks,
                                                        particles: _coordinator
                                                            .particleService
                                                            .activeParticles,
                                                        damageNumbers:
                                                            _coordinator
                                                                .damageNumbers,
                                                        enemyBullets:
                                                            _coordinator
                                                                .bulletManager
                                                                .bullets,
                                                        predictedDamage:
                                                            _coordinator
                                                                .prediction
                                                                ?.predictedDamage,
                                                        animationTime:
                                                            _animationTime,
                                                      ),
                                                    ),
                                                  );
                                                },
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                if (matchState.status ==
                                        CombatMatchStatus.paused &&
                                    !_overlayState.isModalOpen)
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
                                          color: VoidTheme.obsidianBlack
                                              .withValues(alpha: 0.9),
                                          borderRadius: BorderRadius.circular(
                                            10.0,
                                          ),
                                          border: Border.all(
                                            color: VoidTheme.solarGold,
                                            width: 1.2,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: VoidTheme.solarGold
                                                  .withValues(alpha: 0.35),
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
                                          color: VoidTheme.cardSurface
                                              .withValues(alpha: 0.85),
                                          borderRadius: BorderRadius.circular(
                                            10.0,
                                          ),
                                          border: Border.all(
                                            color: VoidTheme.crimsonFlare,
                                            width: 1.0,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: VoidTheme.crimsonFlare
                                                  .withValues(alpha: 0.3),
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
                                // Ergonomic Sector Secured Bottom Command Dock when modal is dismissed
                                if (isSecured &&
                                    _overlayState ==
                                        CombatOverlayState.victoryReview)
                                  Positioned(
                                    bottom: 12.0,
                                    left: 16.0,
                                    right: 16.0,
                                    child: Center(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 14.0,
                                          vertical: 10.0,
                                        ),
                                        decoration: BoxDecoration(
                                          color: VoidTheme.obsidianBlack
                                              .withValues(alpha: 0.95),
                                          borderRadius: BorderRadius.circular(
                                            12.0,
                                          ),
                                          border: Border.all(
                                            color: VoidTheme.emeraldShield,
                                            width: 1.2,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: VoidTheme.emeraldShield
                                                  .withValues(alpha: 0.3),
                                              blurRadius: 10.0,
                                            ),
                                          ],
                                        ),
                                        child: FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              // Star Map Button
                                              GestureDetector(
                                                onTap: _openMap,
                                                child: Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 10.0,
                                                        vertical: 6.0,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color:
                                                        VoidTheme.cardSurface,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          6.0,
                                                        ),
                                                    border: Border.all(
                                                      color: VoidTheme
                                                          .textSecondary
                                                          .withValues(
                                                            alpha: 0.5,
                                                          ),
                                                      width: 1.0,
                                                    ),
                                                  ),
                                                  child: const Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Icon(
                                                        Icons.map_outlined,
                                                        color: VoidTheme
                                                            .textSecondary,
                                                        size: 13.0,
                                                      ),
                                                      SizedBox(width: 4.0),
                                                      Text(
                                                        'MAP',
                                                        style: TextStyle(
                                                          color: VoidTheme
                                                              .textSecondary,
                                                          fontSize: 10.0,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          letterSpacing: 0.4,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8.0),
                                              // Replay Button
                                              GestureDetector(
                                                onTap: _restartCombat,
                                                child: Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 10.0,
                                                        vertical: 6.0,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color:
                                                        VoidTheme.cardSurface,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          6.0,
                                                        ),
                                                    border: Border.all(
                                                      color: VoidTheme
                                                          .plasmaCyan
                                                          .withValues(
                                                            alpha: 0.8,
                                                          ),
                                                      width: 1.0,
                                                    ),
                                                  ),
                                                  child: const Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Icon(
                                                        Icons.replay,
                                                        color: VoidTheme
                                                            .plasmaCyan,
                                                        size: 13.0,
                                                      ),
                                                      SizedBox(width: 4.0),
                                                      Text(
                                                        'REPLAY',
                                                        style: TextStyle(
                                                          color: VoidTheme
                                                              .plasmaCyan,
                                                          fontSize: 10.0,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          letterSpacing: 0.4,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8.0),
                                              // Advance to Next Sector Button
                                              GestureDetector(
                                                onTap: _advanceNextSector,
                                                child: Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 12.0,
                                                        vertical: 6.0,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color:
                                                        VoidTheme.emeraldShield,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          6.0,
                                                        ),
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: VoidTheme
                                                            .emeraldShield
                                                            .withValues(
                                                              alpha: 0.4,
                                                            ),
                                                        blurRadius: 6.0,
                                                      ),
                                                    ],
                                                  ),
                                                  child: Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Text(
                                                        _currentSectorId < 9
                                                            ? 'NEXT SECTOR'
                                                            : 'REPLAY SECTOR',
                                                        style: const TextStyle(
                                                          color: VoidTheme
                                                              .obsidianBlack,
                                                          fontSize: 10.0,
                                                          fontWeight:
                                                              FontWeight.w900,
                                                          letterSpacing: 0.5,
                                                        ),
                                                      ),
                                                      const SizedBox(
                                                        width: 4.0,
                                                      ),
                                                      const Icon(
                                                        Icons.navigate_next,
                                                        color: VoidTheme
                                                            .obsidianBlack,
                                                        size: 15.0,
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 6.0),
                                              // Quick Recap Button to reopen victory dialog
                                              GestureDetector(
                                                onTap: () {
                                                  _showVictoryModal();
                                                },
                                                child: Container(
                                                  padding: const EdgeInsets.all(
                                                    5.0,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color:
                                                        VoidTheme.cardSurface,
                                                    shape: BoxShape.circle,
                                                    border: Border.all(
                                                      color: VoidTheme.solarGold
                                                          .withValues(
                                                            alpha: 0.5,
                                                          ),
                                                      width: 1.0,
                                                    ),
                                                  ),
                                                  child: const Icon(
                                                    Icons.military_tech,
                                                    color: VoidTheme.solarGold,
                                                    size: 15.0,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),

                        // Lower Primary Thumb Command Arc (Isolated RepaintBoundary)
                        RepaintBoundary(
                          child: CommandArcWidget(
                            bays: _coordinator.bays,
                            selectedBay: matchState.selectedBay,
                            activeSowBay: matchState.activeSowBay,
                            onBaySelected: _coordinator.selectBay,
                            onSowAction: _coordinator.sow,
                            onInjectCore: _coordinator.injectCore,
                            onSlidePosition: _coordinator.slidePosition,
                          ),
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
            ),
          );
        },
      ),
    );
  }
}
