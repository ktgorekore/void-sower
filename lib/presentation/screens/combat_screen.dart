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

import '../../core/logging.dart';
import '../../domain/models/campaign_sector.dart';
import '../../domain/models/dreadnought_state.dart';
import '../../domain/models/pro_feature.dart';
import '../../domain/services/ad_service.dart';
import '../../domain/services/campaign_service.dart';
import '../../domain/services/daily_sortie_service.dart';
import '../../domain/services/entitlement_service.dart';
import '../../domain/services/game_engine_interface.dart';
import '../../domain/services/persistence_service.dart';
import '../../domain/services/void_incursion_service.dart';
import '../../domain/state/combat_match_state.dart';
import '../controllers/combat_coordinator.dart';
import '../controllers/combat_overlay_state.dart';
import '../services/haptic_service.dart';
import '../theme/void_theme.dart';
import 'campaign_map_screen.dart';
import '../widgets/combat_painter.dart';
import '../widgets/command_arc_widget.dart';
import '../widgets/game_over_dialog.dart';
import '../widgets/hud_header.dart';
import '../widgets/landscape_orientation_shield.dart';
import '../widgets/mutation_selection_dialog.dart';
import '../widgets/pause_menu_dialog.dart';
import '../widgets/profile_modal.dart';
import '../../domain/models/bay_role.dart';
import '../widgets/pro_boost_modal.dart';
import '../widgets/pro_upgrade_modal.dart';
import '../widgets/rewarded_ad_modal.dart';
import '../widgets/settings_modal.dart';
import '../widgets/starfield_3d.dart';
import '../widgets/tactical_directives_modal.dart';
import '../widgets/tutorial_overlay.dart';
import '../widgets/victory_dialog.dart';
import '../services/audio_service.dart';

/// Primary Combat Viewport shell coordinating 60 Hz rendering, state machine
/// event observation, and one-thumb input routing.
class CombatScreen extends StatefulWidget {
  const CombatScreen({
    super.key,
    required this.engine,
    this.difficultyTier = 0,
    this.sectorId = 1,
    this.sector,
    this.startingCores,
    this.initialVelocity,
    this.onReturnToMap,
    this.autoStartSolver = false,
    this.startWithTutorial = false,
    this.isIncursionRun = false,
    this.isDailySortie = false,
  });

  final IVoidSowerEngine engine;
  final int difficultyTier;
  final int sectorId;
  final CampaignSector? sector;
  final int? startingCores;
  final double? initialVelocity;
  final VoidCallback? onReturnToMap;
  final bool autoStartSolver;
  final bool startWithTutorial;
  final bool isIncursionRun;
  final bool isDailySortie;

  @override
  State<CombatScreen> createState() => _CombatScreenState();
}

class _CombatScreenState extends State<CombatScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final CombatCoordinator _coordinator;
  late final Ticker _ticker;
  late final ValueNotifier<double> _renderNotifier;
  late final ValueNotifier<int> _directiveNotifier;
  late final Starfield3DSimulation _starfieldSimulation;

  int _lastDirectiveHash = 0;

  Duration _lastElapsed = Duration.zero;
  double _animationTime = 0.0;
  Size? _combatViewportSize;

  int _currentDifficultyTier = 0;
  int _currentSectorId = 1;
  CombatOverlayState _overlayState = CombatOverlayState.none;
  Timer? _autoAdvanceTimer;

  CampaignSector get _activeSector =>
      widget.sector ?? CampaignService.instance.getSector(_currentSectorId);

  int _lastReserveCores = -1;
  int _lastTotalScore = -1;
  int _lastInvadersRemaining = -1;
  CombatMatchStatus? _lastStatus;
  int? _lastSelectedBay;
  int? _lastActiveSowBay;
  bool _lastAutoSolving = false;
  int _targetFps = 60;
  int _lastTickMicros = 0;
  double _viewportDragDx = 0.0;
  double _viewportDragDy = 0.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _renderNotifier = ValueNotifier<double>(0.0);
    _directiveNotifier = ValueNotifier<int>(0);
    _starfieldSimulation = Starfield3DSimulation();
    final isLowBattery = PersistenceService.instance.lowBatteryMode;
    _targetFps = isLowBattery ? 30 : PersistenceService.instance.targetFps;

    _currentSectorId = widget.sector?.sectorId ?? widget.sectorId;
    final sector = _activeSector;
    _currentDifficultyTier =
        widget.sector?.difficultyTier ?? sector.difficultyTier;
    _coordinator = CombatCoordinator(
      engine: widget.engine,
      difficultyTier: _currentDifficultyTier,
    );
    _coordinator.addListener(_onCoordinatorStateChanged);
    _coordinator.initialize(
      difficulty: _currentDifficultyTier,
      sector: sector,
      startingCores: widget.startingCores,
      initialVelocity: widget.initialVelocity,
      autoStartSolver: widget.autoStartSolver,
      startWithTutorial: widget.startWithTutorial,
      isIncursionRun: widget.isIncursionRun,
    );

    _ticker = createTicker(_onTick);
    _resumeTicker();
    unawaited(AudioService.instance.updateAudioFocus());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (mounted && _overlayState == CombatOverlayState.none) {
        _resumeTicker();
        AudioService.instance.resumeBgm();
        AudioService.instance.updateAudioFocus();
      }
    } else {
      if (_ticker.isActive) {
        _ticker.stop();
      }
      AudioService.instance.pauseBgm();
      AudioService.instance.releaseAudioFocus();
    }
  }

  /// Safely starts or resumes the 60 Hz ticker, resetting microsecond offsets
  /// to eliminate any frame-dropping freezes when returning from dialogs or external ad activities.
  void _resumeTicker() {
    _lastTickMicros = 0;
    _lastElapsed = Duration.zero;
    if (!_ticker.isTicking) {
      _ticker.start();
    }
  }

  void _onTick(Duration elapsed) {
    try {
      final nowMicros = elapsed.inMicroseconds;
      if (_lastTickMicros > 0 && nowMicros >= _lastTickMicros) {
        final frameIntervalMicros = (1000000 / _targetFps).round();
        if ((nowMicros - _lastTickMicros) < (frameIntervalMicros - 1500)) {
          return;
        }
      }
      _lastTickMicros = nowMicros;

      final dtSeconds =
          (_lastElapsed == Duration.zero || elapsed < _lastElapsed)
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

      final dread = _coordinator.dreadnought;
      var remaining = 0;
      final enemies = _coordinator.enemies;
      for (var i = 0; i < enemies.length; i++) {
        if (!enemies[i].isDestroyed) remaining++;
      }
      final state = _coordinator.state;

      final isVanguard = dread.proximityMultiplier > 1.01;
      final questStateHash = Object.hash(
        dread.quest,
        dread.questProgress,
        isVanguard,
      );
      if (questStateHash != _lastDirectiveHash) {
        _lastDirectiveHash = questStateHash;
        _directiveNotifier.value++;
      }

      final hudChanged =
          dread.reserveCores != _lastReserveCores ||
          dread.totalScore != _lastTotalScore ||
          remaining != _lastInvadersRemaining ||
          state.status != _lastStatus ||
          state.selectedBay != _lastSelectedBay ||
          state.activeSowBay != _lastActiveSowBay ||
          state.isAutoSolving != _lastAutoSolving;

      if (hudChanged) {
        if (state.status != _lastStatus) {
          vlog(
            1,
            'Combat status transitioned: ${_lastStatus?.name} -> ${state.status.name}',
          );
        }
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

      final forwardDepth = (dread.orbitalPositionY - dread.boundaryLineY).clamp(
        0.0,
        0.45,
      );
      final normForward = forwardDepth / 0.45;
      final velocityDx = (dread.targetPositionX - dread.orbitalPositionX).clamp(
        -1.0,
        1.0,
      );
      _starfieldSimulation.update(
        dt: clampedDt,
        normForward: normForward,
        velocityDx: velocityDx,
        viewportSize: viewport,
        isLowBattery: PersistenceService.instance.lowBatteryMode,
      );

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
    final defeatSector = _activeSector;
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

    final bool hasActivePro =
        EntitlementService.instance.hasActivePro ||
        PersistenceService.instance.isProUnlocked;
    final bool isIncursion =
        widget.isIncursionRun || _coordinator.isIncursionRun;
    final int rewardCores = _coordinator.initialCores * 2;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => GameOverDialog(
        score: currentScore,
        highScore: _coordinator.highScore,
        isAmmoDepleted: _coordinator.dreadnought.reserveCores <= 0,
        isAiAssisted: isAiAssisted,
        armDuration: const Duration(milliseconds: 500),
        canRewind: _coordinator.canChronoRewind,
        rewindsRemaining: _coordinator.chronoRewindsRemaining,
        rewardCores: rewardCores,
        isPro: hasActivePro,
        watchAdLabel: hasActivePro
            ? (isIncursion
                  ? null
                  : 'SUMMON AUXILIARY CORES (+$rewardCores CORES)')
            : (isIncursion
                  ? 'WATCH AD (UNLOCK 5m PRO & UNLIMITED CORES)'
                  : 'WATCH AD (+$rewardCores CORES & +5m PRO)'),
        onWatchAdForCores: (hasActivePro && isIncursion)
            ? null
            : () async {
                _autoAdvanceTimer?.cancel();
                if (!hasActivePro) {
                  final rewarded = await AdService.instance.showRewardedAd();
                  if (!dialogContext.mounted) return;
                  if (!rewarded) return;
                }
                if (!dialogContext.mounted) return;
                Navigator.of(dialogContext).pop();
                HapticService.instance.injectionClick();
                final coresToGrant =
                    (_coordinator.isUnlimitedCores || isIncursion)
                    ? 5000
                    : rewardCores;
                _coordinator.grantEmergencyCores(coresToGrant);
                _coordinator.resumeCombat();
                _overlayState = CombatOverlayState.none;
                _resumeTicker();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        hasActivePro
                            ? '⚡ PRO AUXILIARY CORES INJECTED (+$coresToGrant CORES)'
                            : '⚡ EMERGENCY CORES INJECTED (+$coresToGrant CORES)',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      backgroundColor: hasActivePro
                          ? VoidTheme.solarGold
                          : VoidTheme.emeraldShield,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                  setState(() {});
                }
              },
        onRewind: () {
          _autoAdvanceTimer?.cancel();
          Navigator.of(dialogContext).pop();
          _coordinator.triggerChronoRewind();
          _overlayState = CombatOverlayState.none;
          _resumeTicker();
          if (mounted) setState(() {});
        },
        onRetry: () {
          _autoAdvanceTimer?.cancel();
          Navigator.of(dialogContext).pop();
          _restartCombat();
        },
        onReturnToMap: () {
          _autoAdvanceTimer?.cancel();
          Navigator.of(dialogContext).pop();
          _overlayState = CombatOverlayState.none;
          _openMap(campaignId: 'kilwa_basin');
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

  Future<void> _showVictoryModal({bool isReopen = false}) async {
    final fromReview =
        _overlayState == CombatOverlayState.victoryReview || isReopen;
    if (fromReview) {
      // Re-opening victory dialog from battlefield review dock or pro modal
    } else if (_overlayState.isTerminalFlow || _overlayState.isModalOpen) {
      return;
    }

    if (!fromReview) {
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
      final currentSector = _activeSector;
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
    }

    if (!mounted) {
      return;
    }
    _overlayState = CombatOverlayState.victoryModal;

    final currentSector = _activeSector;
    final score = _coordinator.dreadnought.totalScore;
    final cores = _coordinator.dreadnought.reserveCores;
    final isAiAssisted = _coordinator.hasUsedAiSolver;

    final operation = CampaignService.instance.getOperation(
      currentSector.campaignId,
    );
    final isPro = EntitlementService.instance.hasActivePro;
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

    if (widget.isIncursionRun) {
      final currentWave = VoidIncursionService.instance.currentWave;
      PersistenceService.instance.setIncursionBestWave(currentWave);
      final draftMutations = VoidIncursionService.instance.getRandomMutations(
        3,
      );

      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => MutationSelectionDialog(
          waveNumber: currentWave,
          mutations: draftMutations,
          onSelected: (mutation) {
            VoidIncursionService.instance.addMutation(mutation);
            VoidIncursionService.instance.advanceWave();
            Navigator.of(dialogContext).pop();
            _startIncursionWave();
          },
        ),
      );
      return;
    }

    if (widget.isDailySortie) {
      PersistenceService.instance.setDailyHighScore(
        DailySortieService.instance.todayDateKey,
        score,
      );
    }

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
        armDuration: fromReview
            ? Duration.zero
            : const Duration(milliseconds: 500),
        canAdvance: canAdvance,
        isAiAssisted: isAiAssisted,
        onUpgradePro: !isPro
            ? () {
                _autoAdvanceTimer?.cancel();
                Navigator.of(dialogContext).pop();
                _overlayState = CombatOverlayState.proUpgrade;
                showDialog<void>(
                  context: context,
                  barrierColor: Colors.black.withValues(alpha: 0.75),
                  builder: (context) => ProUpgradeModal(
                    highlightedFeature: ProFeature.proCampaignTheaters,
                    onUnlocked: () {
                      if (mounted) setState(() {});
                    },
                  ),
                ).then((_) {
                  if (!mounted) return;
                  if (EntitlementService.instance.hasActivePro) {
                    final currSector = CampaignService.instance.getSector(
                      _currentSectorId,
                    );
                    final op = CampaignService.instance.getOperation(
                      currSector.campaignId,
                    );
                    final maxSector = op.baseSectorId + op.sectors.length - 1;
                    if (_currentSectorId < maxSector) {
                      _advanceNextSector();
                    } else {
                      _showVictoryModal(isReopen: true);
                    }
                  } else {
                    _showVictoryModal(isReopen: true);
                  }
                });
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
          _openMap(campaignId: 'kilwa_basin');
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
    if (widget.isIncursionRun) {
      VoidIncursionService.instance.startNewRun();
      _startIncursionWave();
      return;
    }
    final sector = _activeSector;
    _currentDifficultyTier = sector.difficultyTier;
    _coordinator.initialize(
      difficulty: _currentDifficultyTier,
      sector: sector,
      startingCores: widget.startingCores,
      initialVelocity: widget.initialVelocity,
      autoStartSolver: _coordinator.state.isAutoSolving,
    );
    _resumeTicker();
    if (mounted) setState(() {});
  }

  void _startIncursionWave() {
    _overlayState = CombatOverlayState.none;
    final incursionSector = VoidIncursionService.instance.getCurrentSector();
    _currentDifficultyTier = incursionSector.difficultyTier;
    _coordinator.initialize(
      difficulty: _currentDifficultyTier,
      sector: incursionSector,
      autoStartSolver: _coordinator.state.isAutoSolving,
      isIncursionRun: true,
    );
    _resumeTicker();
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
    _resumeTicker();
    if (mounted) setState(() {});
  }

  void _openCodex({bool returnToPauseMenu = false}) {
    if (_overlayState != CombatOverlayState.none &&
        _overlayState != CombatOverlayState.paused) {
      return;
    }
    _overlayState = CombatOverlayState.codex;
    _coordinator.pauseCombat();
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
      if (mounted) {
        if (returnToPauseMenu) {
          _openPauseMenu();
        } else {
          if (_coordinator.state.status != CombatMatchStatus.briefing) {
            _resumeCombat();
          }
        }
        setState(() {});
      }
    });
  }

  void _openSettings({bool returnToPauseMenu = false}) {
    if (_overlayState != CombatOverlayState.none &&
        _overlayState != CombatOverlayState.paused) {
      return;
    }
    _overlayState = CombatOverlayState.settings;
    _coordinator.pauseCombat();
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
      if (mounted) {
        _targetFps = PersistenceService.instance.lowBatteryMode
            ? 30
            : PersistenceService.instance.targetFps;
        if (returnToPauseMenu) {
          _openPauseMenu();
        } else {
          if (_coordinator.state.status != CombatMatchStatus.briefing) {
            _resumeCombat();
          }
        }
        setState(() {});
      }
    });
  }

  void _openProBoostModal({bool returnToPauseMenu = false}) {
    if (_overlayState != CombatOverlayState.none &&
        _overlayState != CombatOverlayState.paused) {
      return;
    }
    final previousOverlay = _overlayState;
    _overlayState = CombatOverlayState.proUpgrade;
    final wasActive =
        _coordinator.state.status == CombatMatchStatus.activeCombat;
    if (wasActive) _coordinator.pauseCombat();
    final wasTicking = _ticker.isTicking;
    if (wasTicking) _ticker.stop();

    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.75),
      builder: (context) => ProBoostModal(
        onBoostUpdated: () {
          if (mounted) setState(() {});
        },
      ),
    ).then((_) {
      _overlayState = CombatOverlayState.none;
      if (mounted) {
        if (returnToPauseMenu) {
          _openPauseMenu();
        } else if (previousOverlay != CombatOverlayState.paused && wasActive) {
          _resumeCombat();
        }
        setState(() {});
      }
    });
  }

  void _openEmergencyFlare() {
    if (_overlayState != CombatOverlayState.none) return;
    _overlayState = CombatOverlayState.emergencyFlare;
    _coordinator.pauseCombat();
    final wasTicking = _ticker.isTicking;
    if (wasTicking) _ticker.stop();

    final rewardCores = _coordinator.initialCores * 2;
    showDialog<void>(
      context: context,
      builder: (context) => RewardedAdModal(
        rewardCores: rewardCores,
        onCoresGranted: (cores) {
          _coordinator.grantEmergencyCores(cores);
        },
      ),
    ).then((_) {
      _overlayState = CombatOverlayState.none;
      if (mounted) {
        _resumeCombat();
        setState(() {});
      }
    });
  }

  void _openProfile() {
    if (_overlayState != CombatOverlayState.none) return;
    _overlayState = CombatOverlayState.profile;
    _coordinator.pauseCombat();
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
      if (mounted) {
        _coordinator.resumeCombat();
        if (wasTicking) _resumeTicker();
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _autoAdvanceTimer?.cancel();
    _ticker.dispose();
    _renderNotifier.dispose();
    _directiveNotifier.dispose();
    _coordinator.removeListener(_onCoordinatorStateChanged);
    _coordinator.dispose();
    AudioService.instance.pauseBgm();
    AudioService.instance.releaseAudioFocus();
    super.dispose();
  }

  @visibleForTesting
  ValueNotifier<int> get directiveNotifier => _directiveNotifier;

  void _toggleAutoSolve() {
    if (EntitlementService.instance.isFeatureAccessible(
      ProFeature.aiTacticalSolver,
    )) {
      _coordinator.toggleAutoSolve();
    } else {
      if (_overlayState != CombatOverlayState.none &&
          _overlayState != CombatOverlayState.paused) {
        return;
      }
      final previousOverlay = _overlayState;
      _overlayState = CombatOverlayState.proUpgrade;
      final wasTicking = _ticker.isTicking;
      if (wasTicking) _ticker.stop();
      _coordinator.pauseCombat();

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
        _overlayState = previousOverlay;
        if (mounted) {
          if (previousOverlay != CombatOverlayState.paused) {
            _coordinator.resumeCombat();
            if (wasTicking) _resumeTicker();
          }
          setState(() {});
        }
      });
    }
  }

  void _openProUpgradeModal() {
    if (_overlayState != CombatOverlayState.none &&
        _overlayState != CombatOverlayState.victoryReview) {
      return;
    }
    final previousOverlay = _overlayState;
    _overlayState = CombatOverlayState.proUpgrade;
    final wasActive =
        _coordinator.state.status == CombatMatchStatus.activeCombat;
    if (wasActive) _coordinator.pauseCombat();
    final wasTicking = _ticker.isTicking;
    if (wasTicking) _ticker.stop();

    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.75),
      builder: (context) => ProUpgradeModal(
        onUnlocked: () {
          if (mounted) setState(() {});
        },
      ),
    ).then((_) {
      if (!mounted) return;
      if (previousOverlay == CombatOverlayState.victoryReview) {
        _overlayState = CombatOverlayState.victoryReview;
        setState(() {});
      } else {
        _overlayState = CombatOverlayState.none;
        if (wasActive) _coordinator.resumeCombat();
        if (wasTicking) _resumeTicker();
        setState(() {});
      }
    });
  }

  void _openMap({String? campaignId}) {
    final targetCampaign = campaignId ?? 'kilwa_basin';
    PersistenceService.instance.setActiveCampaignId(targetCampaign);
    if (widget.onReturnToMap != null) {
      widget.onReturnToMap!();
    } else {
      final wasTicking = _ticker.isTicking;
      if (wasTicking) _ticker.stop();
      Navigator.of(context)
          .push(
            MaterialPageRoute<void>(
              builder: (context) => CampaignMapScreen(
                engine: widget.engine,
                initialCampaignId: targetCampaign,
              ),
            ),
          )
          .then((_) {
            if (mounted && wasTicking) {
              _resumeTicker();
            }
          });
    }
  }

  void _openPauseMenu() {
    if (_overlayState != CombatOverlayState.none) return;
    _coordinator.pauseCombat();
    _overlayState = CombatOverlayState.paused;
    final wasTicking = _ticker.isTicking;
    if (wasTicking) _ticker.stop();

    bool shouldResumeOnClose = true;

    showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.75),
      builder: (dialogContext) => AnimatedBuilder(
        animation: _coordinator,
        builder: (context, _) => PauseMenuDialog(
          sectorId: _currentSectorId,
          sectorName: _activeSector.name,
          difficultyTier: _currentDifficultyTier,
          score: _coordinator.competitiveScore,
          highScore: _coordinator.highScore,
          canRewind: _coordinator.canChronoRewind,
          rewindsRemaining: _coordinator.chronoRewindsRemaining,
          onRewind: () {
            shouldResumeOnClose = false;
            Navigator.of(dialogContext).pop();
            _coordinator.triggerChronoRewind();
            _coordinator.resumeCombat();
            _overlayState = CombatOverlayState.none;
            _resumeTicker();
            if (mounted) setState(() {});
          },
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
            _openMap(campaignId: 'kilwa_basin');
          },
          onMap: () {
            shouldResumeOnClose = false;
            Navigator.of(dialogContext).pop();
            _overlayState = CombatOverlayState.none;
            _openMap(campaignId: 'kilwa_basin');
          },
          onCodex: () {
            shouldResumeOnClose = false;
            Navigator.of(dialogContext).pop();
            _overlayState = CombatOverlayState.none;
            _openCodex(returnToPauseMenu: true);
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
            _openSettings(returnToPauseMenu: true);
          },
          onProBoost: () {
            shouldResumeOnClose = false;
            Navigator.of(dialogContext).pop();
            _overlayState = CombatOverlayState.none;
            _openProBoostModal(returnToPauseMenu: true);
          },
          isAutoSolving: _coordinator.state.isAutoSolving,
          onToggleAutoSolve: () {
            _toggleAutoSolve();
          },
        ),
      ),
    ).then((_) {
      if (_overlayState == CombatOverlayState.paused) {
        _overlayState = CombatOverlayState.none;
      }
      if (mounted &&
          shouldResumeOnClose &&
          _coordinator.state.status == CombatMatchStatus.paused) {
        _resumeCombat();
      } else if (mounted &&
          wasTicking &&
          !_ticker.isTicking &&
          shouldResumeOnClose) {
        _resumeTicker();
      }
    });
  }

  void _resumeCombat() {
    _resumeTicker();
    _coordinator.resumeCombat();
    if (mounted) setState(() {});
  }

  void _toggleTacticalPause() {
    if (_coordinator.state.status == CombatMatchStatus.paused) {
      _resumeCombat();
    } else {
      _openPauseMenu();
    }
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

    final currentSector = _activeSector;
    final operation = CampaignService.instance.getOperation(
      currentSector.campaignId,
    );
    final isPro = EntitlementService.instance.hasActivePro;
    final maxSectorInOperation =
        operation.baseSectorId + operation.sectors.length - 1;
    final nextSectorCandidate = _currentSectorId < maxSectorInOperation
        ? CampaignService.instance.getSector(_currentSectorId + 1)
        : null;
    final canAdvance =
        nextSectorCandidate != null &&
        (isPro || nextSectorCandidate.isUnlocked);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _toggleTacticalPause();
      },
      child: Scaffold(
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
                              isPro: EntitlementService.instance.hasActivePro,
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
                                  matchState.status ==
                                      CombatMatchStatus.paused ||
                                  _overlayState == CombatOverlayState.paused,
                              onTogglePause: _toggleTacticalPause,
                              onRestartTap: _restartCombat,
                              onStopTap: _openMap,
                              onMapTap: _openMap,
                              onNextSectorTap: () {
                                if (_overlayState ==
                                    CombatOverlayState.victoryReview) {
                                  _showVictoryModal(isReopen: true);
                                } else {
                                  _advanceNextSector();
                                }
                              },
                              isSecured: isSecured,
                              onSettingsTap: _openSettings,
                              onCodexTap: _openCodex,
                              onTutorialTap: _coordinator.showTutorial,
                              onEmergencyFlareTap: _openEmergencyFlare,
                              onProTap: _openProBoostModal,
                              isUnlimitedCores: _coordinator.isUnlimitedCores,
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
                                          onPanStart: (_) {
                                            _viewportDragDx = 0.0;
                                            _viewportDragDy = 0.0;
                                          },
                                          onPanUpdate: (details) {
                                            _viewportDragDx += details.delta.dx;
                                            _viewportDragDy += details.delta.dy;
                                            final normX =
                                                (details.localPosition.dx /
                                                        constraints.maxWidth)
                                                    .clamp(0.0, 1.0);
                                            final boundaryY =
                                                constraints.maxHeight - 18.0;
                                            final topMargin =
                                                constraints.maxHeight * 0.06;
                                            final baselineShipY =
                                                boundaryY - 28.0;
                                            final maxTravelY =
                                                (boundaryY - topMargin) * 0.60;
                                            final forwardRatio =
                                                (details.localPosition.dy <
                                                    baselineShipY)
                                                ? ((baselineShipY -
                                                              details
                                                                  .localPosition
                                                                  .dy) /
                                                          maxTravelY)
                                                      .clamp(0.0, 1.0)
                                                : 0.0;
                                            final baseBoundaryY = _coordinator
                                                .dreadnought
                                                .boundaryLineY;
                                            final normY =
                                                (baseBoundaryY +
                                                        forwardRatio * 0.45)
                                                    .clamp(baseBoundaryY, 0.65);
                                            _coordinator.slidePosition2D(
                                              normX,
                                              normY,
                                              snapToCorridor: false,
                                            );
                                          },
                                          onPanEnd: (details) {
                                            if (!matchState.canReceiveInput &&
                                                (_coordinator
                                                            .dreadnought
                                                            .reserveCores <=
                                                        0 ||
                                                    _coordinator
                                                        .state
                                                        .isAutoSolving)) {
                                              return;
                                            }
                                            final vx = details
                                                .velocity
                                                .pixelsPerSecond
                                                .dx;
                                            final vy = details
                                                .velocity
                                                .pixelsPerSecond
                                                .dy;

                                            final activeCorridor =
                                                (_coordinator
                                                            .dreadnought
                                                            .orbitalPositionX *
                                                        8.0)
                                                    .floor()
                                                    .clamp(0, 7);
                                            final activeBay =
                                                activeCorridor + 8;

                                            final totalDragDistance =
                                                _viewportDragDx.abs() +
                                                _viewportDragDy.abs();

                                            // 1. Minimal displacement tap -> Quick-fire axial lance
                                            if (totalDragDistance < 15.0) {
                                              _coordinator
                                                  .quickFireActiveCorridor();
                                            }
                                            // 2. Upward flick -> Quick-fire axial lance / inject core (Namua)
                                            else if ((vy < -140.0 ||
                                                    _viewportDragDy < -20.0) &&
                                                _viewportDragDy.abs() >
                                                    _viewportDragDx.abs()) {
                                              _coordinator
                                                  .quickFireActiveCorridor();
                                            }
                                            // 3. Swiped RIGHT (Clockwise)
                                            else if (_viewportDragDx > 10.0 &&
                                                (vx > 90.0 ||
                                                    _viewportDragDx > 25.0)) {
                                              final resolvedDir =
                                                  BayRole.resolveSowDirection(
                                                    activeBay,
                                                    1,
                                                  );
                                              _coordinator.setSowDirection(
                                                resolvedDir,
                                              );
                                              _coordinator.sow(
                                                activeBay,
                                                resolvedDir,
                                              );
                                            }
                                            // 4. Swiped LEFT (Counter-Clockwise)
                                            else if (_viewportDragDx < -10.0 &&
                                                (vx < -90.0 ||
                                                    _viewportDragDx < -25.0)) {
                                              final resolvedDir =
                                                  BayRole.resolveSowDirection(
                                                    activeBay,
                                                    -1,
                                                  );
                                              _coordinator.setSowDirection(
                                                resolvedDir,
                                              );
                                              _coordinator.sow(
                                                activeBay,
                                                resolvedDir,
                                              );
                                            } else {
                                              // Settle smoothly into corridor center upon finger release
                                              final currentNormX = _coordinator
                                                  .dreadnought
                                                  .orbitalPositionX;
                                              final currentNormY = _coordinator
                                                  .dreadnought
                                                  .orbitalPositionY;
                                              _coordinator.slidePosition2D(
                                                currentNormX,
                                                currentNormY,
                                                snapToCorridor: true,
                                              );
                                            }
                                          },
                                          onDoubleTap: () {
                                            _coordinator
                                                .quickFireActiveCorridor();
                                          },
                                          onTap: () {
                                            _coordinator
                                                .quickFireActiveCorridor();
                                          },
                                          child: Stack(
                                            fit: StackFit.expand,
                                            children: [
                                              // 3D Perspective Warp Starfield & Kilwa Cosmic Dust
                                              RepaintBoundary(
                                                child: ListenableBuilder(
                                                  listenable: _renderNotifier,
                                                  builder: (context, _) {
                                                    final dread = _coordinator
                                                        .dreadnought;
                                                    final forwardDepth =
                                                        (dread.orbitalPositionY -
                                                                dread
                                                                    .boundaryLineY)
                                                            .clamp(0.0, 0.45);
                                                    final normForward =
                                                        forwardDepth / 0.45;
                                                    return Starfield3DWidget(
                                                      simulation:
                                                          _starfieldSimulation,
                                                      normForward: normForward,
                                                      animationTime:
                                                          _animationTime,
                                                      isLowBattery:
                                                          PersistenceService
                                                              .instance
                                                              .lowBatteryMode,
                                                    );
                                                  },
                                                ),
                                              ),
                                              // Retained Static Skia Surface (Corridors & Defense Rails)
                                              RepaintBoundary(
                                                child: CustomPaint(
                                                  painter:
                                                      CombatBackgroundPainter(
                                                        isLowBattery:
                                                            PersistenceService
                                                                .instance
                                                                .lowBatteryMode,
                                                      ),
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
                                                          lances: _coordinator
                                                              .lances,
                                                          flaks: _coordinator
                                                              .flaks,
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
                                                          isLowBattery:
                                                              PersistenceService
                                                                  .instance
                                                                  .lowBatteryMode,
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
                                  // Live Deep-Space Tactical Sortie Directive Banner
                                  Positioned(
                                    top: 6.0,
                                    left: 14.0,
                                    right: 14.0,
                                    child: IgnorePointer(
                                      child: ListenableBuilder(
                                        listenable: _directiveNotifier,
                                        builder: (context, _) {
                                          final dread =
                                              _coordinator.dreadnought;
                                          final quest = dread.quest;
                                          final hasActiveQuest =
                                              quest != QuestType.none;
                                          final isVanguard =
                                              dread.proximityMultiplier > 1.01;

                                          return Row(
                                            children: [
                                              Expanded(
                                                child: Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 8.0,
                                                        vertical: 3.5,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: VoidTheme
                                                        .obsidianBlack
                                                        .withValues(
                                                          alpha: 0.82,
                                                        ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          6.0,
                                                        ),
                                                    border: Border.all(
                                                      color: hasActiveQuest
                                                          ? VoidTheme.solarGold
                                                                .withValues(
                                                                  alpha: 0.5,
                                                                )
                                                          : VoidTheme.plasmaCyan
                                                                .withValues(
                                                                  alpha: 0.3,
                                                                ),
                                                      width: 1.0,
                                                    ),
                                                  ),
                                                  child: Row(
                                                    children: [
                                                      Icon(
                                                        hasActiveQuest
                                                            ? Icons.explore
                                                            : Icons.radar,
                                                        size: 12.0,
                                                        color: hasActiveQuest
                                                            ? VoidTheme
                                                                  .solarGold
                                                            : VoidTheme
                                                                  .plasmaCyan,
                                                      ),
                                                      const SizedBox(
                                                        width: 5.0,
                                                      ),
                                                      Expanded(
                                                        child: Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          mainAxisSize:
                                                              MainAxisSize.min,
                                                          children: [
                                                            Text(
                                                              hasActiveQuest
                                                                  ? quest.title
                                                                        .toUpperCase()
                                                                  : 'DEEP SPACE WARFARE',
                                                              maxLines: 1,
                                                              overflow:
                                                                  TextOverflow
                                                                      .ellipsis,
                                                              style: const TextStyle(
                                                                color: Colors
                                                                    .white,
                                                                fontSize: 8.5,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w900,
                                                                letterSpacing:
                                                                    0.7,
                                                              ),
                                                            ),
                                                            if (hasActiveQuest) ...[
                                                              const SizedBox(
                                                                height: 2.0,
                                                              ),
                                                              ClipRRect(
                                                                borderRadius:
                                                                    BorderRadius.circular(
                                                                      1.5,
                                                                    ),
                                                                child: LinearProgressIndicator(
                                                                  value: dread
                                                                      .questProgress
                                                                      .clamp(
                                                                        0.0,
                                                                        1.0,
                                                                      ),
                                                                  minHeight:
                                                                      2.0,
                                                                  backgroundColor:
                                                                      Colors
                                                                          .white12,
                                                                  valueColor:
                                                                      const AlwaysStoppedAnimation<
                                                                        Color
                                                                      >(
                                                                        VoidTheme
                                                                            .solarGold,
                                                                      ),
                                                                ),
                                                              ),
                                                            ],
                                                          ],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                              if (isVanguard) ...[
                                                const SizedBox(width: 6.0),
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 6.0,
                                                        vertical: 3.5,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: VoidTheme
                                                        .obsidianBlack
                                                        .withValues(
                                                          alpha: 0.88,
                                                        ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          6.0,
                                                        ),
                                                    border: Border.all(
                                                      color: VoidTheme.solarGold
                                                          .withValues(
                                                            alpha: 0.75,
                                                          ),
                                                      width: 1.0,
                                                    ),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      const Icon(
                                                        Icons.bolt,
                                                        size: 12.0,
                                                        color:
                                                            VoidTheme.solarGold,
                                                      ),
                                                      const SizedBox(
                                                        width: 2.0,
                                                      ),
                                                      Text(
                                                        '+${((dread.proximityMultiplier - 1.0) * 100).toInt()}%',
                                                        style: const TextStyle(
                                                          color: VoidTheme
                                                              .solarGold,
                                                          fontSize: 9.0,
                                                          fontWeight:
                                                              FontWeight.w900,
                                                          letterSpacing: 0.5,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ],
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                  if (matchState.status ==
                                          CombatMatchStatus.paused &&
                                      !_overlayState.isModalOpen)
                                    Positioned(
                                      top: 6.0,
                                      left: 16.0,
                                      right: 16.0,
                                      child: Center(
                                        child: GestureDetector(
                                          behavior: HitTestBehavior.opaque,
                                          onTap: _resumeCombat,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12.0,
                                              vertical: 5.0,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(
                                                0xFF0F172A,
                                              ).withValues(alpha: 0.9),
                                              borderRadius:
                                                  BorderRadius.circular(12.0),
                                              border: Border.all(
                                                color: VoidTheme.solarGold
                                                    .withValues(alpha: 0.85),
                                                width: 1.2,
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: VoidTheme.solarGold
                                                      .withValues(alpha: 0.25),
                                                  blurRadius: 8.0,
                                                  spreadRadius: 1.0,
                                                ),
                                              ],
                                            ),
                                            child: const Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.play_circle_filled,
                                                  color: VoidTheme.solarGold,
                                                  size: 14.0,
                                                ),
                                                SizedBox(width: 5.0),
                                                Text(
                                                  'PAUSED • TAP TO RESUME',
                                                  style: TextStyle(
                                                    color: VoidTheme.solarGold,
                                                    fontSize: 9.0,
                                                    fontWeight: FontWeight.w800,
                                                    letterSpacing: 0.6,
                                                  ),
                                                ),
                                              ],
                                            ),
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
                                            horizontal: 8.0,
                                            vertical: 2.0,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(
                                              0xFF0F172A,
                                            ).withValues(alpha: 0.8),
                                            borderRadius: BorderRadius.circular(
                                              10.0,
                                            ),
                                            border: Border.all(
                                              color: VoidTheme.crimsonFlare
                                                  .withValues(alpha: 0.7),
                                              width: 0.8,
                                            ),
                                          ),
                                          child: const Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.smart_toy,
                                                color: VoidTheme.crimsonFlare,
                                                size: 11.0,
                                              ),
                                              SizedBox(width: 4.0),
                                              Text(
                                                'AI TACTICAL SOLVER ACTIVE',
                                                style: TextStyle(
                                                  color: VoidTheme.crimsonFlare,
                                                  fontSize: 8.0,
                                                  fontWeight: FontWeight.bold,
                                                  letterSpacing: 0.6,
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
                                                  onTap: () {
                                                    if (canAdvance) {
                                                      _advanceNextSector();
                                                    } else if (nextSectorCandidate !=
                                                            null &&
                                                        !isPro) {
                                                      _openProUpgradeModal();
                                                    } else {
                                                      _restartCombat();
                                                    }
                                                  },
                                                  child: Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 12.0,
                                                          vertical: 6.0,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: canAdvance
                                                          ? VoidTheme
                                                                .emeraldShield
                                                          : (nextSectorCandidate !=
                                                                        null &&
                                                                    !isPro
                                                                ? VoidTheme
                                                                      .solarGold
                                                                : VoidTheme
                                                                      .plasmaCyan),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            6.0,
                                                          ),
                                                      boxShadow: [
                                                        BoxShadow(
                                                          color:
                                                              (canAdvance
                                                                      ? VoidTheme
                                                                            .emeraldShield
                                                                      : (nextSectorCandidate !=
                                                                                    null &&
                                                                                !isPro
                                                                            ? VoidTheme.solarGold
                                                                            : VoidTheme.plasmaCyan))
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
                                                          canAdvance
                                                              ? 'NEXT SECTOR'
                                                              : (nextSectorCandidate !=
                                                                            null &&
                                                                        !isPro
                                                                    ? 'UNLOCK PRO'
                                                                    : 'REPLAY SECTOR'),
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
                                                        Icon(
                                                          canAdvance
                                                              ? Icons
                                                                    .navigate_next
                                                              : (nextSectorCandidate !=
                                                                            null &&
                                                                        !isPro
                                                                    ? Icons
                                                                          .workspace_premium
                                                                    : Icons
                                                                          .replay),
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
                                                    _showVictoryModal(
                                                      isReopen: true,
                                                    );
                                                  },
                                                  child: Container(
                                                    padding:
                                                        const EdgeInsets.all(
                                                          5.0,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color:
                                                          VoidTheme.cardSurface,
                                                      shape: BoxShape.circle,
                                                      border: Border.all(
                                                        color: VoidTheme
                                                            .solarGold
                                                            .withValues(
                                                              alpha: 0.5,
                                                            ),
                                                        width: 1.0,
                                                      ),
                                                    ),
                                                    child: const Icon(
                                                      Icons.military_tech,
                                                      color:
                                                          VoidTheme.solarGold,
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
                              sowDirection: _coordinator.sowDirection,
                              onBaySelected: _coordinator.selectBay,
                              onSowAction: _coordinator.sow,
                              onInjectCore: _coordinator.injectCore,
                              onSlidePosition: _coordinator.slidePosition,
                              onDirectionChanged: _coordinator.setSowDirection,
                              tacticalAdvice: _coordinator.tacticalAdvice,
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
      ),
    );
  }
}
