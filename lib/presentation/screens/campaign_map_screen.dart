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

import '../../domain/models/campaign_operation.dart';
import '../../domain/models/campaign_sector.dart';
import '../../domain/models/pro_feature.dart';
import '../../domain/models/sector_combat_doctrine.dart';
import '../../domain/services/campaign_service.dart';
import '../../domain/services/daily_sortie_service.dart';
import '../../domain/services/entitlement_service.dart';
import '../../domain/services/game_engine_interface.dart';
import '../../domain/services/persistence_service.dart';
import '../../domain/services/void_incursion_service.dart';
import '../services/haptic_service.dart';
import '../theme/void_theme.dart';
import '../widgets/fleet_hangar_dialog.dart';
import '../widgets/landscape_orientation_shield.dart';
import '../widgets/profile_modal.dart';
import '../widgets/pro_upgrade_modal.dart';
import '../widgets/settings_modal.dart';
import '../widgets/tactical_directives_modal.dart';
import '../widgets/tactile_button.dart';
import '../../main.dart';
import 'combat_screen.dart';
import 'simulation_lab_screen.dart';

/// Operational view mode for the star map command deck.
enum StarmapViewMode {
  /// Standard progressive campaign sectors across galactic theaters.
  campaign,

  /// Tactical operations: Daily Sortie, Void Incursion, and Pro Overcharge.
  specialOps,
}

/// Interactive Star Map Screen for the Kilwa Nebula Basin Campaign.
class CampaignMapScreen extends StatefulWidget {
  const CampaignMapScreen({
    super.key,
    required this.engine,
    this.initialCampaignId,
  });

  final IVoidSowerEngine engine;
  final String? initialCampaignId;

  @override
  State<CampaignMapScreen> createState() => _CampaignMapScreenState();
}

class _CampaignMapScreenState extends State<CampaignMapScreen>
    with WidgetsBindingObserver, RouteAware {
  late String _activeCampaignId;
  late List<CampaignSector> _sectors;
  String _selectedChassisId = 'mk1_bastion';
  Timer? _boostCountdownTimer;
  StarmapViewMode _activeViewMode = StarmapViewMode.campaign;

  /// Visible for testing to verify timer suspension on route push.
  @visibleForTesting
  bool get isBoostTimerActive =>
      _boostCountdownTimer != null && _boostCountdownTimer!.isActive;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.initialCampaignId != null &&
        widget.initialCampaignId!.isNotEmpty) {
      _activeCampaignId = widget.initialCampaignId!;
      PersistenceService.instance.setActiveCampaignId(_activeCampaignId);
    } else {
      _activeCampaignId = PersistenceService.instance.activeCampaignId;
    }
    _selectedChassisId = PersistenceService.instance.selectedChassisId;
    _sectors = CampaignService.instance.getSectors(_activeCampaignId);

    EntitlementService.instance.addListener(_onEntitlementChanged);
    _startBoostTimerIfNeeded();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final modalRoute = ModalRoute.of(context);
    if (modalRoute != null) {
      routeObserver.subscribe(this, modalRoute);
    }
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    WidgetsBinding.instance.removeObserver(this);
    _boostCountdownTimer?.cancel();
    _boostCountdownTimer = null;
    EntitlementService.instance.removeListener(_onEntitlementChanged);
    super.dispose();
  }

  @override
  void didPushNext() {
    // Screen is covered by a newly pushed route (such as CombatScreen);
    // pause countdown timer to conserve battery and eliminate invisible rebuilds.
    _boostCountdownTimer?.cancel();
    _boostCountdownTimer = null;
  }

  @override
  void didPopNext() {
    // Screen is revealed again after top route is popped
    if (mounted) {
      _startBoostTimerIfNeeded();
      setState(() {});
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      _boostCountdownTimer?.cancel();
      _boostCountdownTimer = null;
    } else {
      if (mounted) {
        _startBoostTimerIfNeeded();
        setState(() {});
      }
    }
  }

  void _onEntitlementChanged() {
    if (!mounted) return;
    setState(() {});
    _startBoostTimerIfNeeded();
  }

  void _startBoostTimerIfNeeded() {
    if (EntitlementService.instance.isBoostActive) {
      _boostCountdownTimer ??= Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        if (EntitlementService.instance.isBoostActive) {
          setState(() {});
        } else {
          _boostCountdownTimer?.cancel();
          _boostCountdownTimer = null;
          setState(() {});
        }
      });
    } else {
      _boostCountdownTimer?.cancel();
      _boostCountdownTimer = null;
    }
  }

  Future<void> _handleWatchAdForBoost() async {
    HapticService.instance.injectionClick();
    final success = await EntitlementService.instance.unlockWithRewardedAd();
    if (!mounted) return;
    if (success) {
      final mins = EntitlementService.instance.boostMinutesRemaining;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '⚡ +5m PRO BOOST ACTIVE ($mins/60m)',
            style: const TextStyle(
              fontFamily: 'monospace',
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: VoidTheme.solarGold,
          duration: const Duration(seconds: 3),
        ),
      );
      setState(() {
        _sectors = CampaignService.instance.getSectors(_activeCampaignId);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Holo-transmission unavailable. Please try again shortly.',
            style: TextStyle(fontFamily: 'monospace'),
          ),
          backgroundColor: VoidTheme.crimsonFlare,
        ),
      );
    }
  }

  void _switchCampaign(String campaignId) {
    HapticService.instance.injectionClick();
    setState(() {
      _activeCampaignId = campaignId;
      PersistenceService.instance.setActiveCampaignId(campaignId);
      _sectors = CampaignService.instance.getSectors(_activeCampaignId);
    });
  }

  void _openProUpgrade([ProFeature? highlightedFeature]) {
    showDialog<void>(
      context: context,
      builder: (context) => ProUpgradeModal(
        highlightedFeature: highlightedFeature,
        onUnlocked: () {
          setState(() {
            _sectors = CampaignService.instance.getSectors(_activeCampaignId);
          });
        },
      ),
    );
  }

  void _launchSector(CampaignSector sector) {
    if (!sector.isUnlocked) {
      _showLockedSectorDialog(sector);
      return;
    }
    HapticService.instance.injectionClick();

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => CombatScreen(
          engine: widget.engine,
          difficultyTier: sector.difficultyTier,
          sectorId: sector.sectorId,
          sector: sector,
          onReturnToMap: () {
            Navigator.of(context).pop();
            setState(() {
              _activeCampaignId = PersistenceService.instance.activeCampaignId;
              _sectors = CampaignService.instance.getSectors(_activeCampaignId);
            });
          },
        ),
      ),
    );
  }

  void _openHangar() {
    showDialog<void>(
      context: context,
      builder: (context) => FleetHangarDialog(
        selectedChassisId: _selectedChassisId,
        onChassisSelected: (newId) {
          setState(() => _selectedChassisId = newId);
          PersistenceService.instance.setSelectedChassisId(newId);
        },
      ),
    );
  }

  void _launchAcademy() {
    HapticService.instance.injectionClick();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => CombatScreen(
          engine: widget.engine,
          difficultyTier: 0,
          sectorId: 1,
          startWithTutorial: true,
          onReturnToMap: () {
            Navigator.of(context).pop();
            setState(() {
              _activeCampaignId = PersistenceService.instance.activeCampaignId;
              _sectors = CampaignService.instance.getSectors(_activeCampaignId);
            });
          },
        ),
      ),
    );
  }

  void _launchSectorWithAi(CampaignSector sector) {
    HapticService.instance.injectionClick();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => CombatScreen(
          engine: widget.engine,
          difficultyTier: sector.difficultyTier,
          sectorId: sector.sectorId,
          sector: sector,
          autoStartSolver: true,
          onReturnToMap: () {
            Navigator.of(context).pop();
            setState(() {
              _activeCampaignId = PersistenceService.instance.activeCampaignId;
              _sectors = CampaignService.instance.getSectors(_activeCampaignId);
            });
          },
        ),
      ),
    );
  }

  void _openSimulationLab() {
    HapticService.instance.injectionClick();
    if (!EntitlementService.instance.isFeatureAccessible(
      ProFeature.orbitalSimulationLab,
    )) {
      _openProUpgrade(ProFeature.orbitalSimulationLab);
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => SimulationLabScreen(engine: widget.engine),
      ),
    );
  }

  void _openCodex() {
    showDialog<void>(
      context: context,
      builder: (context) => TacticalDirectivesModal(
        onLaunchAcademy: _launchAcademy,
        onLaunchSimulationLab: _openSimulationLab,
      ),
    );
  }

  void _openProfile() {
    showDialog<void>(
      context: context,
      builder: (context) => ProfileModal(
        onProfileUpdated: () {
          setState(() {});
        },
      ),
    );
  }

  void _openSettings() {
    showDialog<void>(
      context: context,
      builder: (context) => SettingsModal(
        onDataWiped: () {
          setState(() {
            _activeCampaignId = 'kilwa_basin';
            _sectors = CampaignService.instance.getSectors(_activeCampaignId);
          });
        },
        onLaunchAcademy: _launchAcademy,
      ),
    );
  }

  void _showSectorBriefing(CampaignSector sector) {
    if (!sector.isUnlocked) {
      _showLockedSectorDialog(sector);
      return;
    }
    HapticService.instance.sowTick();

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.fromLTRB(20.0, 12.0, 20.0, 24.0),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(24.0),
            ),
            border: Border.all(
              color: const Color(0xFFF59E0B).withValues(alpha: 0.8),
              width: 1.5,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x99000000),
                blurRadius: 24.0,
                offset: Offset(0, -4),
              ),
              BoxShadow(
                color: Color(0x2BF59E0B),
                blurRadius: 16.0,
                spreadRadius: -2,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag handle pill
              Center(
                child: Container(
                  width: 36.0,
                  height: 4.0,
                  margin: const EdgeInsets.only(bottom: 14.0),
                  decoration: BoxDecoration(
                    color: const Color(0xFF334155),
                    borderRadius: BorderRadius.circular(2.0),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      sector.name.toUpperCase(),
                      style: const TextStyle(
                        color: VoidTheme.solarGold,
                        fontSize: 16.0,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                  Row(
                    children: List.generate(3, (i) {
                      return Icon(
                        i < sector.starsEarned ? Icons.star : Icons.star_border,
                        color: VoidTheme.solarGold,
                        size: 18.0,
                      );
                    }),
                  ),
                ],
              ),
              const SizedBox(height: 6.0),
              Text(
                '${sector.region.toUpperCase()} • THREAT TIER ${sector.difficultyTier + 1}',
                style: const TextStyle(
                  color: VoidTheme.plasmaCyan,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 10.0),
              // 3px neon track
              Container(
                height: 3.0,
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B),
                  borderRadius: BorderRadius.circular(1.5),
                  boxShadow: const [
                    BoxShadow(color: Color(0x80F59E0B), blurRadius: 6.0),
                  ],
                ),
              ),
              const SizedBox(height: 12.0),
              Container(
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: const Color(0xFF070C18),
                  borderRadius: BorderRadius.circular(10.0),
                  border: Border.all(
                    color: const Color(0xFF1E293B),
                    width: 1.0,
                  ),
                ),
                child: const Text(
                  'Defend the orbital perimeter and neutralize all descending hostiles.',
                  style: TextStyle(
                    color: Color(0xFFCBD5E1),
                    fontSize: 12.0,
                    height: 1.35,
                  ),
                ),
              ),
              const SizedBox(height: 18.0),
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TactileButton(
                      label: 'LAUNCH',
                      icon: Icons.rocket_launch,
                      onPressed: () {
                        Navigator.of(context).pop();
                        _launchSector(sector);
                      },
                      accentColor: VoidTheme.solarGold,
                      height: 48.0,
                    ),
                  ),
                  const SizedBox(width: 10.0),
                  Expanded(
                    flex: 2,
                    child: TactileButton(
                      label: 'AI SOLVE',
                      icon: Icons.smart_toy,
                      onPressed: () {
                        Navigator.of(context).pop();
                        _launchSectorWithAi(sector);
                      },
                      accentColor: VoidTheme.plasmaCyan,
                      height: 48.0,
                      isPrimary: false,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showLockedSectorDialog(CampaignSector sector) {
    HapticService.instance.sowTick();

    final requiredSector = sector.requiredSectorId != null
        ? CampaignService.instance.getSector(sector.requiredSectorId!)
        : null;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.fromLTRB(20.0, 12.0, 20.0, 24.0),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(24.0),
            ),
            border: Border.all(color: VoidTheme.crimsonFlare, width: 1.5),
            boxShadow: const [
              BoxShadow(
                color: Color(0x99000000),
                blurRadius: 24.0,
                offset: Offset(0, -4),
              ),
              BoxShadow(
                color: Color(0x2BEF4444),
                blurRadius: 16.0,
                spreadRadius: -2,
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Drag handle pill
                Center(
                  child: Container(
                    width: 36.0,
                    height: 4.0,
                    margin: const EdgeInsets.only(bottom: 14.0),
                    decoration: BoxDecoration(
                      color: const Color(0xFF334155),
                      borderRadius: BorderRadius.circular(2.0),
                    ),
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 38.0,
                      height: 38.0,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: VoidTheme.crimsonFlare.withValues(alpha: 0.2),
                        border: Border.all(
                          color: VoidTheme.crimsonFlare,
                          width: 1.5,
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.lock,
                          color: VoidTheme.crimsonFlare,
                          size: 20.0,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12.0),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'SECTOR ${sector.sectorId}: ${sector.name.toUpperCase()}',
                            style: const TextStyle(
                              color: VoidTheme.starWhite,
                              fontSize: 15.0,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 2.0),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6.0,
                                  vertical: 1.5,
                                ),
                                decoration: BoxDecoration(
                                  color: VoidTheme.crimsonFlare.withValues(
                                    alpha: 0.2,
                                  ),
                                  borderRadius: BorderRadius.circular(4.0),
                                ),
                                child: const Text(
                                  'IMPERIAL ORBITAL BLOCKADE DETECTED',
                                  style: TextStyle(
                                    color: VoidTheme.crimsonFlare,
                                    fontSize: 9.0,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12.0),
                // 3px neon track
                Container(
                  height: 3.0,
                  decoration: BoxDecoration(
                    color: VoidTheme.crimsonFlare,
                    borderRadius: BorderRadius.circular(1.5),
                    boxShadow: const [
                      BoxShadow(color: Color(0x80EF4444), blurRadius: 6.0),
                    ],
                  ),
                ),
                const SizedBox(height: 14.0),
                // Clearance Node Box
                Container(
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: const Color(0xFF070C18),
                    borderRadius: BorderRadius.circular(10.0),
                    border: Border.all(
                      color: sector.isProRequired
                          ? VoidTheme.solarGold
                          : const Color(0xFF334155),
                      width: 1.0,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            sector.isProRequired
                                ? Icons.workspace_premium
                                : Icons.hub_outlined,
                            color: sector.isProRequired
                                ? VoidTheme.solarGold
                                : VoidTheme.plasmaCyan,
                            size: 15.0,
                          ),
                          const SizedBox(width: 6.0),
                          Text(
                            sector.isProRequired
                                ? 'PRO OPERATION'
                                : 'CLEARANCE REQUIREMENT',
                            style: TextStyle(
                              color: sector.isProRequired
                                  ? VoidTheme.solarGold
                                  : VoidTheme.plasmaCyan,
                              fontSize: 10.0,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6.0),
                      Text(
                        sector.unlockRequirement,
                        style: const TextStyle(
                          color: VoidTheme.textPrimary,
                          fontSize: 11.5,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16.0),
                // Action Buttons
                if (sector.isProRequired &&
                    !EntitlementService.instance.hasActivePro) ...[
                  TactileButton(
                    label: 'WATCH AD (+5m PRO)',
                    icon: Icons.play_circle_filled,
                    onPressed: () {
                      Navigator.of(context).pop();
                      _handleWatchAdForBoost();
                    },
                    accentColor: VoidTheme.emeraldShield,
                    height: 44.0,
                  ),
                  const SizedBox(height: 8.0),
                  TactileButton(
                    label: 'UNLOCK PRO — \$1.29',
                    icon: Icons.workspace_premium,
                    onPressed: () {
                      Navigator.of(context).pop();
                      _openProUpgrade();
                    },
                    accentColor: VoidTheme.solarGold,
                    height: 44.0,
                  ),
                  const SizedBox(height: 8.0),
                  TactileButton(
                    label: 'DISMISS',
                    icon: Icons.close,
                    onPressed: () => Navigator.of(context).pop(),
                    accentColor: VoidTheme.textMuted,
                    isPrimary: false,
                    height: 40.0,
                  ),
                ] else if (requiredSector != null &&
                    requiredSector.isUnlocked) ...[
                  TactileButton(
                    label: 'DEPLOY • S${sector.requiredSectorId}',
                    icon: Icons.rocket_launch,
                    onPressed: () {
                      Navigator.of(context).pop();
                      _launchSector(requiredSector);
                    },
                    accentColor: VoidTheme.solarGold,
                    height: 44.0,
                  ),
                  const SizedBox(height: 8.0),
                  TactileButton(
                    label: 'DISMISS',
                    icon: Icons.close,
                    onPressed: () => Navigator.of(context).pop(),
                    accentColor: VoidTheme.textMuted,
                    isPrimary: false,
                    height: 40.0,
                  ),
                ] else ...[
                  TactileButton(
                    label: 'DISMISS',
                    icon: Icons.close,
                    onPressed: () => Navigator.of(context).pop(),
                    accentColor: VoidTheme.textMuted,
                    isPrimary: false,
                    height: 40.0,
                  ),
                ],
                if (!sector.isProRequired &&
                    !EntitlementService.instance.hasActivePro) ...[
                  const SizedBox(height: 8.0),
                  TactileButton(
                    label: 'UNLOCK PRO — \$1.29',
                    icon: Icons.workspace_premium,
                    onPressed: () {
                      Navigator.of(context).pop();
                      _openProUpgrade();
                    },
                    accentColor: VoidTheme.solarGold,
                    height: 44.0,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTheaterSwitcher() {
    final List<CampaignOperation> operations = CampaignService.instance
        .getOperations();
    final isPro = EntitlementService.instance.hasActivePro;
    final isSpecialOps = _activeViewMode == StarmapViewMode.specialOps;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: Container(
        height: 32.0,
        padding: const EdgeInsets.all(2.0),
        decoration: BoxDecoration(
          color: const Color(0xFF070C18),
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(color: const Color(0xFF1E293B), width: 1.0),
        ),
        child: Row(
          children: [
            ...operations.map((op) {
              final isSelected = !isSpecialOps && op.id == _activeCampaignId;
              final isLocked = op.isProRequired && !isPro;

              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    HapticService.instance.sowTick();
                    setState(() {
                      _activeViewMode = StarmapViewMode.campaign;
                    });
                    _switchCampaign(op.id);
                  },
                  child: Container(
                    height: 28.0,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF0284C7)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(14.0),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF38BDF8)
                            : Colors.transparent,
                        width: 1.0,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: const Color(
                                  0xFF0284C7,
                                ).withValues(alpha: 0.4),
                                blurRadius: 6.0,
                              ),
                            ]
                          : null,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            op.id == 'kilwa_basin' ? 'KILWA BASIN' : op.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : (isLocked
                                        ? VoidTheme.textMuted
                                        : const Color(0xFF94A3B8)),
                              fontSize: 9.0,
                              fontWeight: isSelected
                                  ? FontWeight.w900
                                  : FontWeight.w700,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                        if (isLocked) ...[
                          const SizedBox(width: 3.0),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4.0,
                              vertical: 1.0,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFFF59E0B,
                              ).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(3.0),
                              border: Border.all(
                                color: const Color(0xFFF59E0B),
                                width: 0.6,
                              ),
                            ),
                            child: const Text(
                              'PRO',
                              style: TextStyle(
                                color: Color(0xFFFBBF24),
                                fontSize: 6.5,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            }),
            // 4. Special Ops tab
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  HapticService.instance.sowTick();
                  setState(() {
                    _activeViewMode = StarmapViewMode.specialOps;
                  });
                },
                child: Container(
                  height: 28.0,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isSpecialOps
                        ? const Color(0xFF7C3AED)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(14.0),
                    border: Border.all(
                      color: isSpecialOps
                          ? const Color(0xFFA78BFA)
                          : Colors.transparent,
                      width: 1.0,
                    ),
                    boxShadow: isSpecialOps
                        ? [
                            BoxShadow(
                              color: const Color(
                                0xFF7C3AED,
                              ).withValues(alpha: 0.4),
                              blurRadius: 6.0,
                            ),
                          ]
                        : null,
                  ),
                  child: Text(
                    'SPECIAL OPS',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isSpecialOps
                          ? Colors.white
                          : const Color(0xFF94A3B8),
                      fontSize: 9.0,
                      fontWeight: isSpecialOps
                          ? FontWeight.w900
                          : FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDoctrineBanner() {
    final CampaignOperation op = CampaignService.instance.getOperation(
      _activeCampaignId,
    );
    IconData doctrineIcon;
    Color doctrineColor;
    String doctrineTag;

    switch (op.defaultDoctrine) {
      case SectorCombatDoctrine.phantomDrift:
        doctrineIcon = Icons.swap_horiz;
        doctrineColor = VoidTheme.plasmaCyan;
        doctrineTag = 'PHANTOM DRIFT • LATERAL EVASION';
        break;
      case SectorCombatDoctrine.voidSwarm:
        doctrineIcon = Icons.hub;
        doctrineColor = VoidTheme.crimsonFlare;
        doctrineTag = 'VOID SWARM • HORDE CRUCIBLE & CORE SIPHON';
        break;
      case SectorCombatDoctrine.standardOrbital:
        doctrineIcon = Icons.shield;
        doctrineColor = VoidTheme.emeraldShield;
        doctrineTag = 'STANDARD ORBITAL • PLANETARY SIEGE';
        break;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 3.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
        decoration: BoxDecoration(
          color: VoidTheme.obsidianBlack.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(8.0),
          border: Border.all(
            color: doctrineColor.withValues(alpha: 0.35),
            width: 0.8,
          ),
        ),
        child: Row(
          children: [
            Icon(doctrineIcon, color: doctrineColor, size: 14.0),
            const SizedBox(width: 6.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    doctrineTag,
                    style: TextStyle(
                      color: doctrineColor,
                      fontSize: 8.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.6,
                    ),
                  ),
                  const SizedBox(height: 1.0),
                  Text(
                    op.tacticalBriefing,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: VoidTheme.textMuted,
                      fontSize: 8.0,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpecialOpsView() {
    return Expanded(
      child: ListView(
        key: const PageStorageKey<String>('special_ops_list'),
        padding: const EdgeInsets.fromLTRB(16.0, 4.0, 16.0, 16.0),
        children: [
          _buildDailySortieHeroCard(),
          const SizedBox(height: 12.0),
          _buildVoidIncursionHeroCard(),
          const SizedBox(height: 12.0),
          _buildProOverchargeFullStation(),
        ],
      ),
    );
  }

  Widget _buildDailySortieHeroCard() {
    final daily = DailySortieService.instance;
    final todayScore = daily.todayBestScore;
    final todaySector = daily.getTodaySector();

    return Container(
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(14.0),
        border: Border.all(
          color: VoidTheme.solarGold.withValues(alpha: 0.5),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: VoidTheme.solarGold.withValues(alpha: 0.08),
            blurRadius: 10.0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7.0),
                decoration: BoxDecoration(
                  color: VoidTheme.solarGold.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: VoidTheme.solarGold.withValues(alpha: 0.4),
                    width: 1.0,
                  ),
                ),
                child: const Icon(
                  Icons.calendar_today,
                  color: VoidTheme.solarGold,
                  size: 15.0,
                ),
              ),
              const SizedBox(width: 10.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'DAILY SORTIE',
                      style: TextStyle(
                        color: VoidTheme.solarGold,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                      ),
                    ),
                    SizedBox(height: 2.0),
                    Text(
                      '24H GLOBAL ROTATION',
                      style: TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 8.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8.0,
                  vertical: 3.0,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(6.0),
                ),
                child: Text(
                  todayScore > 0 ? '$todayScore PTS' : 'UNRANKED',
                  style: TextStyle(
                    color: todayScore > 0
                        ? VoidTheme.emeraldShield
                        : VoidTheme.textMuted,
                    fontSize: 10.0,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10.0),
          Container(
            padding: const EdgeInsets.all(10.0),
            decoration: BoxDecoration(
              color: const Color(0xFF070B19),
              borderRadius: BorderRadius.circular(8.0),
              border: Border.all(color: const Color(0xFF1E293B), width: 0.8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'TARGET: ${todaySector.name.toUpperCase()}',
                      style: const TextStyle(
                        color: VoidTheme.starWhite,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'THREAT TIER ${daily.todayDifficultyTier + 1}',
                      style: const TextStyle(
                        color: VoidTheme.plasmaCyan,
                        fontSize: 9.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4.0),
                const Text(
                  'Compete on a globally synchronized seed. Capture cores and defend the orbital bay.',
                  style: TextStyle(
                    color: VoidTheme.textSecondary,
                    fontSize: 10.5,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10.0),
          SizedBox(
            width: double.infinity,
            height: 40.0,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: VoidTheme.solarGold,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              icon: const Icon(Icons.rocket_launch, size: 15.0),
              label: const Text(
                'LAUNCH SORTIE',
                style: TextStyle(
                  fontSize: 11.0,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.6,
                ),
              ),
              onPressed: () {
                HapticService.instance.injectionClick();
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (context) => CombatScreen(
                      engine: widget.engine,
                      difficultyTier: daily.todayDifficultyTier,
                      sectorId: 999,
                      sector: daily.getTodaySector(),
                      isDailySortie: true,
                      onReturnToMap: () {
                        Navigator.of(context).pop();
                        setState(() {});
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVoidIncursionHeroCard() {
    final incursion = VoidIncursionService.instance;
    final bestWave = PersistenceService.instance.getIncursionBestWave();

    return Container(
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(14.0),
        border: Border.all(
          color: VoidTheme.crimsonFlare.withValues(alpha: 0.5),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: VoidTheme.crimsonFlare.withValues(alpha: 0.08),
            blurRadius: 10.0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7.0),
                decoration: BoxDecoration(
                  color: VoidTheme.crimsonFlare.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: VoidTheme.crimsonFlare.withValues(alpha: 0.4),
                    width: 1.0,
                  ),
                ),
                child: const Icon(
                  Icons.all_inclusive,
                  color: VoidTheme.crimsonFlare,
                  size: 15.0,
                ),
              ),
              const SizedBox(width: 10.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'VOID INCURSION',
                      style: TextStyle(
                        color: VoidTheme.crimsonFlare,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                      ),
                    ),
                    SizedBox(height: 2.0),
                    Text(
                      'ENDLESS WAVES',
                      style: TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 8.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8.0,
                  vertical: 3.0,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(6.0),
                ),
                child: Text(
                  bestWave > 0 ? 'BEST: WAVE $bestWave' : 'NO RECORD',
                  style: TextStyle(
                    color: bestWave > 0
                        ? VoidTheme.plasmaCyan
                        : VoidTheme.textMuted,
                    fontSize: 10.0,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10.0),
          Container(
            padding: const EdgeInsets.all(10.0),
            decoration: BoxDecoration(
              color: const Color(0xFF070B19),
              borderRadius: BorderRadius.circular(8.0),
              border: Border.all(color: const Color(0xFF1E293B), width: 0.8),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SURVIVAL MODE',
                  style: TextStyle(
                    color: VoidTheme.starWhite,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 4.0),
                Text(
                  'Push through random spawns and hostile waves. Earn multiplier bonuses as you venture deeper.',
                  style: TextStyle(
                    color: VoidTheme.textSecondary,
                    fontSize: 10.5,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10.0),
          SizedBox(
            width: double.infinity,
            height: 40.0,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: VoidTheme.crimsonFlare,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              icon: const Icon(Icons.flash_on, size: 15.0),
              label: const Text(
                'START INCURSION',
                style: TextStyle(
                  fontSize: 11.0,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.6,
                ),
              ),
              onPressed: () {
                HapticService.instance.injectionClick();
                incursion.startNewRun();
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (context) => CombatScreen(
                      engine: widget.engine,
                      difficultyTier: incursion
                          .getCurrentSector()
                          .difficultyTier,
                      sectorId: 1000,
                      sector: incursion.getCurrentSector(),
                      isIncursionRun: true,
                      onReturnToMap: () {
                        Navigator.of(context).pop();
                        setState(() {});
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProOverchargeFullStation() {
    final ent = EntitlementService.instance;
    final isLifetime = ent.isProUnlocked;
    final isBoostActive = ent.isBoostActive;
    final mins = ent.boostMinutesRemaining;
    final litSegments = ent.boostSegmentsLit;
    final isMax = ent.isMaxBoostReached;

    return Container(
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isLifetime
              ? [
                  const Color(0xFF1E1B4B).withValues(alpha: 0.9),
                  const Color(0xFF312E81).withValues(alpha: 0.9),
                ]
              : [const Color(0xFF0F172A), const Color(0xFF0B132B)],
        ),
        borderRadius: BorderRadius.circular(14.0),
        border: Border.all(
          color: isLifetime
              ? VoidTheme.solarGold
              : isBoostActive
              ? VoidTheme.plasmaCyan
              : VoidTheme.solarGold.withValues(alpha: 0.4),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: (isBoostActive ? VoidTheme.plasmaCyan : VoidTheme.solarGold)
                .withValues(alpha: 0.1),
            blurRadius: 10.0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7.0),
                decoration: BoxDecoration(
                  color:
                      (isLifetime
                              ? VoidTheme.solarGold
                              : isBoostActive
                              ? VoidTheme.plasmaCyan
                              : VoidTheme.solarGold)
                          .withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color:
                        (isLifetime
                                ? VoidTheme.solarGold
                                : isBoostActive
                                ? VoidTheme.plasmaCyan
                                : VoidTheme.solarGold)
                            .withValues(alpha: 0.4),
                    width: 1.0,
                  ),
                ),
                child: Icon(
                  isLifetime ? Icons.workspace_premium : Icons.bolt,
                  color: isLifetime
                      ? VoidTheme.solarGold
                      : isBoostActive
                      ? VoidTheme.plasmaCyan
                      : VoidTheme.solarGold,
                  size: 15.0,
                ),
              ),
              const SizedBox(width: 10.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isLifetime ? 'PRO COMMANDER FLEET' : 'PRO OVERCHARGE',
                      style: TextStyle(
                        color: isLifetime
                            ? VoidTheme.solarGold
                            : isBoostActive
                            ? VoidTheme.plasmaCyan
                            : VoidTheme.starWhite,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 2.0),
                    Text(
                      isLifetime
                          ? 'ALL PRO FEATURES UNLOCKED'
                          : isBoostActive
                          ? 'BOOST: ${ent.formattedRemainingBoostTime} ($mins/60m)'
                          : 'UNLOCK PRO FOR 5 MINS (UP TO 60m)',
                      style: const TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 8.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (!isLifetime) ...[
            const SizedBox(height: 12.0),
            // 12-segment visual battery
            Row(
              children: List.generate(12, (index) {
                final isLit = index < litSegments;
                return Expanded(
                  child: Container(
                    height: 5.0,
                    margin: EdgeInsets.only(right: index < 11 ? 2.5 : 0.0),
                    decoration: BoxDecoration(
                      color: isLit
                          ? (isBoostActive
                                ? VoidTheme.plasmaCyan
                                : VoidTheme.solarGold)
                          : const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(2.0),
                      boxShadow: isLit
                          ? [
                              BoxShadow(
                                color:
                                    (isBoostActive
                                            ? VoidTheme.plasmaCyan
                                            : VoidTheme.solarGold)
                                        .withValues(alpha: 0.6),
                                blurRadius: 4.0,
                              ),
                            ]
                          : null,
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 6.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'BATTERY: $mins / 60m',
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 8.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  '+5m PER AD',
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 8.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10.0),
            SizedBox(
              width: double.infinity,
              height: 40.0,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isMax
                      ? const Color(0xFF1E293B)
                      : VoidTheme.emeraldShield,
                  foregroundColor: isMax
                      ? VoidTheme.emeraldShield
                      : VoidTheme.obsidianBlack,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                icon: Icon(
                  isMax ? Icons.check_circle : Icons.play_circle_filled,
                  size: 15.0,
                ),
                label: Text(
                  isMax ? 'BOOST FULL (60m)' : 'WATCH AD (+5m PRO)',
                  style: const TextStyle(
                    fontSize: 11.0,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.6,
                  ),
                ),
                onPressed: isMax ? null : _handleWatchAdForBoost,
              ),
            ),
          ],
          const SizedBox(height: 10.0),
          // Included Features List
          Container(
            padding: const EdgeInsets.all(10.0),
            decoration: BoxDecoration(
              color: const Color(0xFF070B19),
              borderRadius: BorderRadius.circular(8.0),
              border: Border.all(color: const Color(0xFF1E293B), width: 0.8),
            ),
            child: Column(
              children: [
                _buildProFeatureRow(
                  'All 27 Multi-Theater Campaign Sectors',
                  Icons.travel_explore,
                ),
                const SizedBox(height: 6.0),
                _buildProFeatureRow(
                  'Orbital Simulation Lab & AI Battle Solver',
                  Icons.science,
                ),
                const SizedBox(height: 6.0),
                _buildProFeatureRow(
                  'Full Dreadnought Fleet Chassis Hangar',
                  Icons.rocket_launch,
                ),
                const SizedBox(height: 6.0),
                _buildProFeatureRow(
                  'Detailed Combat Analysis & Telemetry',
                  Icons.analytics,
                ),
              ],
            ),
          ),
          if (!isLifetime) ...[
            const SizedBox(height: 8.0),
            Center(
              child: TextButton.icon(
                onPressed: () => _openProUpgrade(),
                icon: const Icon(
                  Icons.workspace_premium,
                  color: VoidTheme.solarGold,
                  size: 13.0,
                ),
                label: const Text(
                  'GET LIFETIME PRO',
                  style: TextStyle(
                    color: VoidTheme.solarGold,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProFeatureRow(String text, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: VoidTheme.plasmaCyan, size: 12.0),
        const SizedBox(width: 8.0),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: VoidTheme.starWhite,
              fontSize: 9.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const Icon(Icons.check, color: VoidTheme.emeraldShield, size: 12.0),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeOp = CampaignService.instance.getOperation(_activeCampaignId);

    return PopScope(
      canPop: Navigator.of(context).canPop(),
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        } else {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute<void>(
              builder: (context) => CombatScreen(engine: widget.engine),
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: VoidTheme.obsidianBlack,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth > constraints.maxHeight &&
                  constraints.maxHeight < 520.0) {
                return const LandscapeOrientationShield();
              }

              return Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 640.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 1. Unified Sector Header (Eyebrow, Title, Liberated Tag, 4px Neon Track)
                      _buildCampaignHeader(activeOp),

                      // 2. 32px Theater Switcher Tabs (Kilwa Basin, Phantom Drift, Void Swarm, Special Ops)
                      _buildTheaterSwitcher(),

                      if (_activeViewMode == StarmapViewMode.campaign &&
                          _activeCampaignId != 'kilwa_basin')
                        _buildDoctrineBanner(),

                      if (_activeViewMode == StarmapViewMode.campaign) ...[
                        // 3. Orbital Mission Track List with Left Spline and Nodes
                        Expanded(
                          child: ListView.builder(
                            key: const PageStorageKey<String>(
                              'campaign_sectors_list',
                            ),
                            padding: const EdgeInsets.fromLTRB(
                              16.0,
                              4.0,
                              16.0,
                              12.0,
                            ),
                            itemCount: _sectors.length,
                            itemBuilder: (context, index) {
                              final s = _sectors[index];
                              return _buildSectorRow(
                                sector: s,
                                index: index,
                                isFirst: index == 0,
                                isLast: index == _sectors.length - 1,
                              );
                            },
                          ),
                        ),
                      ] else ...[
                        // Special Ops Command Deck
                        _buildSpecialOpsView(),
                      ],

                      // 4. Fixed Bottom Navigation Bar
                      _buildBottomNavBar(),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  /// Builds the UX 3.0 floating cybernetic bottom command dock:
  /// [ SECTORS ] [ FLEET ] [ PILOT ] [ DIRECTIVES ] [ SETTINGS ]
  Widget _buildBottomNavBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(10.0, 4.0, 10.0, 8.0),
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A).withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(color: const Color(0xFF1E293B), width: 1.2),
          boxShadow: const [
            BoxShadow(
              color: Color(0x99000000),
              blurRadius: 16.0,
              offset: Offset(0, 4),
            ),
            BoxShadow(
              color: Color(0x1F00F0FF),
              blurRadius: 12.0,
              spreadRadius: -2,
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: _buildNavTab(
                icon: Icons.map_outlined,
                label: 'SECTORS',
                isActive: true,
                tooltip: 'Campaign Sectors',
                onTap: () {
                  if (_activeViewMode != StarmapViewMode.campaign) {
                    HapticService.instance.sowTick();
                    setState(() {
                      _activeViewMode = StarmapViewMode.campaign;
                    });
                  }
                },
              ),
            ),
            Expanded(
              child: _buildNavTab(
                icon: Icons.rocket_launch,
                label: 'FLEET',
                isActive: false,
                tooltip: 'Fleet Hangar',
                onTap: _openHangar,
              ),
            ),
            Expanded(
              child: _buildNavTab(
                icon: Icons.account_circle_outlined,
                label: 'PILOT',
                isActive: false,
                tooltip: 'Pilot Profile',
                onTap: _openProfile,
              ),
            ),
            Expanded(
              child: _buildNavTab(
                icon: Icons.school,
                label: 'DIRECTIVES',
                isActive: false,
                tooltip: 'Flight Academy',
                onTap: _openCodex,
              ),
            ),
            Expanded(
              child: _buildNavTab(
                icon: Icons.settings_outlined,
                label: 'SETTINGS',
                isActive: false,
                tooltip: 'Fleet Settings',
                onTap: _openSettings,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavTab({
    required IconData icon,
    required String label,
    required bool isActive,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    const activeColor = Color(0xFF00F0FF);
    const inactiveColor = Color(0xFF64748B);

    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticService.instance.sowTick();
            onTap();
          },
          borderRadius: BorderRadius.circular(12.0),
          child: Container(
            constraints: const BoxConstraints(minHeight: 48.0),
            padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 5.0),
            decoration: isActive
                ? BoxDecoration(
                    color: const Color(0x1F00F0FF),
                    borderRadius: BorderRadius.circular(12.0),
                    border: Border.all(
                      color: const Color(0x5500F0FF),
                      width: 1.0,
                    ),
                  )
                : null,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: isActive ? activeColor : inactiveColor,
                  size: isActive ? 20.0 : 19.0,
                ),
                const SizedBox(height: 3.0),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isActive ? Colors.white : inactiveColor,
                    fontSize: 8.5,
                    fontWeight: isActive ? FontWeight.w900 : FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 3.0),
                Container(
                  height: 3.0,
                  width: isActive ? 22.0 : 6.0,
                  decoration: BoxDecoration(
                    color: isActive ? activeColor : const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(1.5),
                    boxShadow: isActive
                        ? const [
                            BoxShadow(
                              color: Color(0x9900F0FF),
                              blurRadius: 6.0,
                              spreadRadius: 0.5,
                            ),
                          ]
                        : null,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Builds the integrated command header matching sectors.svg:
  /// Eyebrow, 20px bold title, glowing LIBERATED tag, and 4px neon progress track.
  Widget _buildCampaignHeader(CampaignOperation activeOp) {
    final liberatedCount = _sectors.where((s) => s.isLiberated).length;
    final totalSectors = _sectors.length;
    final percent = totalSectors > 0 ? liberatedCount / totalSectors : 0.0;
    final titleText = _activeViewMode == StarmapViewMode.specialOps
        ? 'SPECIAL OPERATIONS'
        : (activeOp.id == 'kilwa_basin'
              ? 'KILWA NEBULA BASIN'
              : activeOp.title.toUpperCase());

    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 6.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'VOID SOWER // ORBITAL COMMAND',
            style: TextStyle(
              color: Color(0xFF38BDF8),
              fontSize: 8.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 3.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  HapticService.instance.sowTick();
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  } else {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute<void>(
                        builder: (context) =>
                            CombatScreen(engine: widget.engine),
                      ),
                    );
                  }
                },
                child: Container(
                  width: 44.0,
                  height: 44.0,
                  alignment: Alignment.center,
                  margin: const EdgeInsets.only(right: 6.0),
                  child: Container(
                    width: 36.0,
                    height: 36.0,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(18.0),
                      border: Border.all(
                        color: const Color(0xFF1E293B),
                        width: 1.0,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.arrow_back_ios_new,
                      color: Color(0xFF38BDF8),
                      size: 16.0,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  titleText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20.0,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.4,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                height: 26.0,
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                decoration: BoxDecoration(
                  color: const Color(0xFF032541),
                  borderRadius: BorderRadius.circular(13.0),
                  border: Border.all(
                    color: const Color(0xFF00F0FF),
                    width: 1.0,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8.0,
                      height: 8.0,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF00F0FF),
                        boxShadow: [
                          BoxShadow(color: Color(0x9900F0FF), blurRadius: 4.0),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6.0),
                    Text(
                      _activeViewMode == StarmapViewMode.specialOps
                          ? 'ACTIVE OPS'
                          : 'LIBERATED $liberatedCount/$totalSectors',
                      style: const TextStyle(
                        color: Color(0xFFE0F2FE),
                        fontSize: 9.0,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6.0),
          // 4px Progress Track
          Container(
            height: 4.0,
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(2.0),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: percent.clamp(0.02, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF00F0FF),
                  borderRadius: BorderRadius.circular(2.0),
                  boxShadow: const [
                    BoxShadow(color: Color(0x9900F0FF), blurRadius: 4.0),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectorRow({
    required CampaignSector sector,
    required int index,
    required bool isFirst,
    required bool isLast,
  }) {
    final activeObjectiveSector = _sectors.firstWhere(
      (s) => s.isUnlocked && !s.isLiberated,
      orElse: () => _sectors.firstWhere(
        (s) => s.isUnlocked,
        orElse: () => _sectors.first,
      ),
    );
    final isHeroObjective =
        sector.sectorId == activeObjectiveSector.sectorId &&
        !sector.isLiberated;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Trajectory connection spline on left
          SizedBox(
            width: 36.0,
            child: CustomPaint(
              painter: SplineLinePainter(
                isFirst: isFirst,
                isLast: isLast,
                lineColor: isHeroObjective
                    ? const Color(0xFF00E5FF)
                    : const Color(0xFF0284C7),
              ),
              child: Center(child: _buildSplineNode(sector, isHeroObjective)),
            ),
          ),
          const SizedBox(width: 8.0),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: _buildSectorCard(sector, isHeroObjective),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSplineNode(CampaignSector sector, bool isHeroObjective) {
    if (sector.isLiberated) {
      return Container(
        width: 26.0,
        height: 26.0,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Color(0xFF0284C7),
          boxShadow: [BoxShadow(color: Color(0x660284C7), blurRadius: 6.0)],
        ),
        child: const Icon(Icons.check, color: Colors.white, size: 15.0),
      );
    } else if (isHeroObjective) {
      return Container(
        width: 32.0,
        height: 32.0,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF082F49),
          border: Border.all(color: const Color(0xFF00E5FF), width: 2.0),
          boxShadow: const [
            BoxShadow(
              color: Color(0x9900E5FF),
              blurRadius: 10.0,
              spreadRadius: 1.0,
            ),
          ],
        ),
        child: Center(
          child: Container(
            width: 10.0,
            height: 10.0,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF00E5FF),
            ),
          ),
        ),
      );
    } else if (sector.isUnlocked) {
      return Container(
        width: 26.0,
        height: 26.0,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF082F49),
          border: Border.all(color: const Color(0xFF0284C7), width: 1.5),
        ),
        child: const Icon(Icons.radar, color: Color(0xFF38BDF8), size: 15.0),
      );
    } else {
      return Container(
        width: 24.0,
        height: 24.0,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF1E293B),
          border: Border.all(color: const Color(0xFF334155), width: 1.0),
        ),
        child: const Icon(Icons.lock, color: Color(0xFF64748B), size: 12.0),
      );
    }
  }

  Widget _buildSectorCard(CampaignSector sector, bool isHeroObjective) {
    if (sector.isLiberated) {
      return _buildLiberatedSectorCard(sector);
    } else if (isHeroObjective) {
      return _buildHeroObjectiveCard(sector);
    } else if (sector.isUnlocked) {
      return _buildUnlockedSectorCard(sector);
    } else {
      return _buildLockedSectorCard(sector);
    }
  }

  Widget _buildLiberatedSectorCard(CampaignSector sector) {
    final stars = sector.starsEarned > 0 ? sector.starsEarned : 3;
    final score = sector.bestScore > 0
        ? sector.bestScore
        : (sector.starsEarned > 0 ? sector.starsEarned * 1400 : 4200);

    return Material(
      color: Colors.transparent,
      child: Ink(
        height: 56.0,
        decoration: BoxDecoration(
          color: const Color(0xFF0A101D),
          borderRadius: BorderRadius.circular(14.0),
          border: Border.all(color: const Color(0xFF1E293B), width: 1.0),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(14.0),
          onTap: () => _showSectorBriefing(sector),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14.0),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        sector.name,
                        style: const TextStyle(
                          color: VoidTheme.starWhite,
                          fontWeight: FontWeight.w800,
                          fontSize: 12.0,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2.0),
                      Text(
                        '${sector.region} • Tier ${sector.difficultyTier + 1}',
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 9.0,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      List.generate(3, (i) => i < stars ? '★' : '☆').join(),
                      style: const TextStyle(
                        color: Color(0xFFFBBF24),
                        fontSize: 10.0,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 2.0),
                    Text(
                      '$score PTS',
                      style: const TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 8.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroObjectiveCard(CampaignSector sector) {
    return Material(
      color: Colors.transparent,
      child: Ink(
        height: 76.0,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0C233C), Color(0xFF071322)],
          ),
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(color: const Color(0xFF00F0FF), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00F0FF).withValues(alpha: 0.25),
              blurRadius: 12.0,
              spreadRadius: 1.0,
            ),
          ],
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16.0),
          onTap: () => _showSectorBriefing(sector),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14.0),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7.0,
                          vertical: 2.0,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0284C7),
                          borderRadius: BorderRadius.circular(7.5),
                        ),
                        child: const Text(
                          'ACTIVE SIEGE',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 7.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4.0),
                      Text(
                        sector.name,
                        style: const TextStyle(
                          color: VoidTheme.starWhite,
                          fontWeight: FontWeight.w900,
                          fontSize: 14.0,
                          letterSpacing: 0.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2.0),
                      Text(
                        '${sector.region} • Tier ${sector.difficultyTier + 1} Corridors',
                        style: const TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 9.5,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8.0),
                GestureDetector(
                  onTap: () => _launchSector(sector),
                  child: Container(
                    width: 104.0,
                    height: 40.0,
                    decoration: BoxDecoration(
                      color: const Color(0xFF00F0FF),
                      borderRadius: BorderRadius.circular(20.0),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00F0FF).withValues(alpha: 0.4),
                          blurRadius: 8.0,
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.play_arrow,
                          size: 16.0,
                          color: Color(0xFF04182B),
                        ),
                        SizedBox(width: 2.0),
                        Text(
                          'ENGAGE',
                          style: TextStyle(
                            color: Color(0xFF04182B),
                            fontSize: 11.0,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUnlockedSectorCard(CampaignSector sector) {
    return Material(
      color: Colors.transparent,
      child: Ink(
        height: 56.0,
        decoration: BoxDecoration(
          color: const Color(0xFF0A101D),
          borderRadius: BorderRadius.circular(14.0),
          border: Border.all(color: const Color(0xFF0284C7), width: 1.0),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(14.0),
          onTap: () => _showSectorBriefing(sector),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14.0),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        sector.name,
                        style: const TextStyle(
                          color: VoidTheme.starWhite,
                          fontWeight: FontWeight.w800,
                          fontSize: 12.0,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2.0),
                      Text(
                        '${sector.region} • Tier ${sector.difficultyTier + 1}',
                        style: const TextStyle(
                          color: Color(0xFF38BDF8),
                          fontSize: 9.0,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => _launchSector(sector),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12.0,
                      vertical: 6.0,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(12.0),
                      border: Border.all(
                        color: const Color(0xFF0284C7),
                        width: 1.0,
                      ),
                    ),
                    child: const Text(
                      'ENGAGE',
                      style: TextStyle(
                        color: Color(0xFF38BDF8),
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLockedSectorCard(CampaignSector sector) {
    return Material(
      color: Colors.transparent,
      child: Ink(
        height: 56.0,
        decoration: BoxDecoration(
          color: const Color(0xFF080C16).withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(14.0),
          border: Border.all(color: const Color(0xFF1E293B), width: 1.0),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(14.0),
          onTap: () => _showLockedSectorDialog(sector),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14.0),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        sector.name,
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w800,
                          fontSize: 12.0,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2.0),
                      Text(
                        sector.unlockRequirement.isNotEmpty
                            ? 'UNLOCK: ${sector.unlockRequirement}'
                            : '${sector.region} • Tier ${sector.difficultyTier + 1}',
                        style: const TextStyle(
                          color: Color(0xFF475569),
                          fontSize: 9.0,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8.0),
                const Text(
                  'LOCKED',
                  style: TextStyle(
                    fontSize: 10.0,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF64748B),
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Custom painter rendering dashed hyperlane trajectory splines between mission nodes.
class SplineLinePainter extends CustomPainter {
  const SplineLinePainter({
    required this.isFirst,
    required this.isLast,
    this.lineColor = const Color(0xFF0284C7),
  });

  final bool isFirst;
  final bool isLast;
  final Color lineColor;

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2.0;
    final centerY = size.height / 2.0;

    final paint = Paint()
      ..color = lineColor.withValues(alpha: 0.5)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    const dashLength = 4.0;
    const dashSpace = 4.0;

    if (!isFirst) {
      var y = 0.0;
      final targetY = centerY - 14.0;
      while (y < targetY) {
        final nextY = (y + dashLength < targetY) ? y + dashLength : targetY;
        canvas.drawLine(Offset(centerX, y), Offset(centerX, nextY), paint);
        y += dashLength + dashSpace;
      }
    }

    if (!isLast) {
      var y = centerY + 14.0;
      final targetY = size.height;
      while (y < targetY) {
        final nextY = (y + dashLength < targetY) ? y + dashLength : targetY;
        canvas.drawLine(Offset(centerX, y), Offset(centerX, nextY), paint);
        y += dashLength + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant SplineLinePainter oldDelegate) =>
      oldDelegate.isFirst != isFirst ||
      oldDelegate.isLast != isLast ||
      oldDelegate.lineColor != lineColor;
}
