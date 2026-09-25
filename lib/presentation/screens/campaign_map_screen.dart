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

import 'package:flutter/material.dart';

import '../../domain/models/campaign_operation.dart';
import '../../domain/models/campaign_sector.dart';
import '../../domain/models/pro_feature.dart';
import '../../domain/models/sector_combat_doctrine.dart';
import '../../domain/services/campaign_service.dart';
import '../../domain/services/entitlement_service.dart';
import '../../domain/services/game_engine_interface.dart';
import '../../domain/services/persistence_service.dart';
import '../services/haptic_service.dart';
import '../theme/void_theme.dart';
import '../widgets/fleet_hangar_dialog.dart';
import '../widgets/landscape_orientation_shield.dart';
import '../widgets/profile_modal.dart';
import '../widgets/pro_upgrade_modal.dart';
import '../widgets/settings_modal.dart';
import '../widgets/tactical_directives_modal.dart';
import '../widgets/tactile_button.dart';
import 'combat_screen.dart';
import 'simulation_lab_screen.dart';

/// Interactive Star Map Screen for the Kilwa Nebula Basin Campaign.
class CampaignMapScreen extends StatefulWidget {
  const CampaignMapScreen({super.key, required this.engine});

  final IVoidSowerEngine engine;

  @override
  State<CampaignMapScreen> createState() => _CampaignMapScreenState();
}

class _CampaignMapScreenState extends State<CampaignMapScreen> {
  late String _activeCampaignId;
  late List<CampaignSector> _sectors;
  String _selectedChassisId = 'mk1_bastion';

  @override
  void initState() {
    super.initState();
    _activeCampaignId = PersistenceService.instance.activeCampaignId;
    _selectedChassisId = PersistenceService.instance.selectedChassisId;
    _sectors = CampaignService.instance.getSectors(_activeCampaignId);
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
          padding: const EdgeInsets.all(22.0),
          decoration: VoidTheme.glassmorphic(
            borderColor: VoidTheme.solarGold,
            borderWidth: 1.5,
            borderRadius: 20.0,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    sector.name.toUpperCase(),
                    style: const TextStyle(
                      color: VoidTheme.solarGold,
                      fontSize: 16.0,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
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
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              const Divider(color: VoidTheme.cardSurface, height: 20.0),
              const Text(
                'Defend the orbital perimeter and neutralize all descending hostiles.',
                style: TextStyle(
                  color: VoidTheme.textSecondary,
                  fontSize: 12.0,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 20.0),
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TactileButton(
                      label: 'ENGAGE BATTLE',
                      icon: Icons.rocket_launch,
                      onPressed: () {
                        Navigator.of(context).pop();
                        _launchSector(sector);
                      },
                      accentColor: VoidTheme.solarGold,
                      height: 48.0,
                    ),
                  ),
                  const SizedBox(width: 8.0),
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
          padding: const EdgeInsets.all(22.0),
          decoration: VoidTheme.glassmorphic(
            borderColor: VoidTheme.crimsonFlare,
            borderWidth: 1.5,
            borderRadius: 20.0,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
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
                          const Text(
                            'IMPERIAL ORBITAL BLOCKADE DETECTED',
                            style: TextStyle(
                              color: VoidTheme.crimsonFlare,
                              fontSize: 10.0,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16.0),
                // Requirement Box
                Container(
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: VoidTheme.cardSurface.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(10.0),
                    border: Border.all(
                      color: VoidTheme.solarGold.withValues(alpha: 0.6),
                      width: 1.2,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.vpn_key,
                            color: VoidTheme.solarGold,
                            size: 14.0,
                          ),
                          SizedBox(width: 6.0),
                          Text(
                            'CLEARANCE REQUIREMENT',
                            style: TextStyle(
                              color: VoidTheme.solarGold,
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
                          fontSize: 12.5,
                          height: 1.4,
                        ),
                      ),
                      if (sector.requiredSectorName != null &&
                          !sector.isProRequired) ...[
                        const SizedBox(height: 6.0),
                        Text(
                          'Target Hyperlane: Sector ${sector.requiredSectorId} (${sector.requiredSectorName})',
                          style: const TextStyle(
                            color: VoidTheme.plasmaCyan,
                            fontSize: 11.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 18.0),
                // Action Buttons
                if (sector.isProRequired) ...[
                  TactileButton(
                    label: 'INSTANTLY UNLOCK ALL SECTORS • PRO',
                    icon: Icons.workspace_premium,
                    onPressed: () {
                      Navigator.of(context).pop();
                      _openProUpgrade();
                    },
                    accentColor: VoidTheme.solarGold,
                    height: 46.0,
                  ),
                  const SizedBox(height: 8.0),
                  TactileButton(
                    label: 'DISMISS INTEL',
                    icon: Icons.close,
                    onPressed: () => Navigator.of(context).pop(),
                    accentColor: VoidTheme.textMuted,
                    isPrimary: false,
                    height: 40.0,
                  ),
                ] else if (requiredSector != null &&
                    requiredSector.isUnlocked) ...[
                  TactileButton(
                    label: 'DEPLOY TO SECTOR ${sector.requiredSectorId}',
                    icon: Icons.rocket_launch,
                    onPressed: () {
                      Navigator.of(context).pop();
                      _launchSector(requiredSector);
                    },
                    accentColor: VoidTheme.solarGold,
                    height: 46.0,
                  ),
                  const SizedBox(height: 8.0),
                  TactileButton(
                    label: 'DISMISS INTEL',
                    icon: Icons.close,
                    onPressed: () => Navigator.of(context).pop(),
                    accentColor: VoidTheme.textMuted,
                    isPrimary: false,
                    height: 40.0,
                  ),
                ] else ...[
                  TactileButton(
                    label: 'DISMISS INTEL',
                    icon: Icons.close,
                    onPressed: () => Navigator.of(context).pop(),
                    accentColor: VoidTheme.plasmaCyan,
                    isPrimary: false,
                    height: 44.0,
                  ),
                ],
                if (!sector.isProRequired &&
                    !EntitlementService.instance.isProUnlocked) ...[
                  const SizedBox(height: 8.0),
                  TactileButton(
                    label: 'INSTANTLY UNLOCK ALL SECTORS • PRO',
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
    final isPro = EntitlementService.instance.isProUnlocked;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: Container(
        height: 38.0,
        padding: const EdgeInsets.all(2.5),
        decoration: BoxDecoration(
          color: const Color(0xFF070C18),
          borderRadius: BorderRadius.circular(19.0),
          border: Border.all(color: const Color(0xFF1E293B), width: 1.0),
        ),
        child: Row(
          children: operations.map((op) {
            final isSelected = op.id == _activeCampaignId;
            final isLocked = op.isProRequired && !isPro;

            return Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _switchCampaign(op.id),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  height: 33.0,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF0284C7)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(17.0),
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
                              blurRadius: 8.0,
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
                                      : const Color(0xFF64748B)),
                            fontSize: 10.0,
                            fontWeight: isSelected
                                ? FontWeight.w900
                                : FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      if (isLocked) ...[
                        const SizedBox(width: 4.0),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4.0,
                            vertical: 1.0,
                          ),
                          decoration: BoxDecoration(
                            color: VoidTheme.solarGold.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(3.0),
                            border: Border.all(
                              color: VoidTheme.solarGold,
                              width: 0.6,
                            ),
                          ),
                          child: const Text(
                            'PRO',
                            style: TextStyle(
                              color: VoidTheme.solarGold,
                              fontSize: 7.0,
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
          }).toList(),
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
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 2.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
        decoration: BoxDecoration(
          color: VoidTheme.obsidianBlack.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(8.0),
          border: Border.all(
            color: doctrineColor.withValues(alpha: 0.25),
            width: 0.8,
          ),
        ),
        child: Row(
          children: [
            Icon(doctrineIcon, color: doctrineColor, size: 13.0),
            const SizedBox(width: 6.0),
            Text(
              doctrineTag,
              style: TextStyle(
                color: doctrineColor,
                fontSize: 8.5,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.6,
              ),
            ),
            const SizedBox(width: 6.0),
            Expanded(
              child: Text(
                op.tacticalBriefing,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: VoidTheme.textMuted,
                  fontSize: 8.0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeOp = CampaignService.instance.getOperation(_activeCampaignId);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
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
                      // 1. Large Centered Title & Liberation Progress Bar
                      _buildCampaignHeader(activeOp),

                      // 2. Theater Switcher Tabs (Kilwa Basin, Phantom Drift, Void Swarm)
                      _buildTheaterSwitcher(),

                      // 3. Tactical Doctrine & Mission Briefing Banner
                      _buildDoctrineBanner(),

                      // 4. Orbital Mission Track List with Left Spline and Nodes
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(
                            16.0,
                            4.0,
                            16.0,
                            8.0,
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

                      // 5. Fixed Bottom Navigation Bar
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

  /// Builds the 5-tab bottom navigation bar matching the redesign mockup:
  /// [ SECTORS ] [ FLEET ] [ PILOT ] [ DIRECTIVES ] [ SETTINGS ]
  Widget _buildBottomNavBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
      decoration: const BoxDecoration(
        color: Color(0xFF070C18),
        border: Border(top: BorderSide(color: Color(0xFF1E293B), width: 1.0)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavTab(
            icon: Icons.map_outlined,
            label: 'SECTORS',
            isActive: true,
            tooltip: 'Campaign Sectors',
            onTap: () {},
          ),
          _buildNavTab(
            icon: Icons.rocket_launch,
            label: 'FLEET',
            isActive: false,
            tooltip: 'Fleet Hangar',
            onTap: _openHangar,
          ),
          _buildNavTab(
            icon: Icons.account_circle_outlined,
            label: 'PILOT',
            isActive: false,
            tooltip: 'Pilot Profile',
            onTap: _openProfile,
          ),
          _buildNavTab(
            icon: Icons.school,
            label: 'DIRECTIVES',
            isActive: false,
            tooltip: 'Flight Academy',
            onTap: _openCodex,
          ),
          _buildNavTab(
            icon: Icons.settings_outlined,
            label: 'SETTINGS',
            isActive: false,
            tooltip: 'Fleet Settings',
            onTap: _openSettings,
          ),
        ],
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
    final color = isActive ? const Color(0xFF00E5FF) : const Color(0xFF64748B);

    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: () {
          HapticService.instance.sowTick();
          onTap();
        },
        borderRadius: BorderRadius.circular(8.0),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 20.0),
              const SizedBox(height: 3.0),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 9.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 3.0),
              Container(
                height: 2.5,
                width: 28.0,
                decoration: BoxDecoration(
                  color: isActive
                      ? const Color(0xFF00E5FF)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(1.2),
                  boxShadow: isActive
                      ? const [
                          BoxShadow(color: Color(0x9900E5FF), blurRadius: 4.0),
                        ]
                      : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the centered campaign title, liberation subtitle, and glowing progress bar.
  Widget _buildCampaignHeader(CampaignOperation activeOp) {
    final liberatedCount = _sectors.where((s) => s.isLiberated).length;
    final totalSectors = _sectors.length;
    final percent = totalSectors > 0 ? liberatedCount / totalSectors : 0.0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 10.0, 16.0, 6.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'VOID SOWER',
                          style: TextStyle(
                            color: Color(0xFF38BDF8),
                            fontSize: 9.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(width: 4.0),
                        Text(
                          '//',
                          style: TextStyle(
                            color: VoidTheme.textMuted.withValues(alpha: 0.6),
                            fontSize: 8.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 4.0),
                        const Text(
                          'ORBITAL COMMAND DECK',
                          style: TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 9.0,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2.0),
                    Text(
                      activeOp.title.toUpperCase(),
                      style: const TextStyle(
                        color: VoidTheme.starWhite,
                        fontSize: 18.0,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.4,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8.0),
              // Sector Liberation Pill matching SVG
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10.0,
                  vertical: 5.0,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(14.0),
                  border: Border.all(
                    color: const Color(0xFF0284C7),
                    width: 1.0,
                  ),
                ),
                child: Text(
                  'LIBERATED: $liberatedCount / $totalSectors (${(percent * 100).toInt()}%)',
                  style: const TextStyle(
                    color: Color(0xFF38BDF8),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6.0),
          Container(
            height: 3.0,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(1.5),
              boxShadow: [
                BoxShadow(
                  color: VoidTheme.plasmaCyan.withValues(alpha: 0.4),
                  blurRadius: 4.0,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(1.5),
              child: LinearProgressIndicator(
                value: percent,
                backgroundColor: const Color(0xFF1E293B),
                valueColor: const AlwaysStoppedAnimation<Color>(
                  VoidTheme.plasmaCyan,
                ),
                minHeight: 3.0,
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
      return Material(
        color: Colors.transparent,
        child: Ink(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
            ),
            borderRadius: BorderRadius.circular(14.0),
            border: Border.all(color: const Color(0xFF1E293B), width: 1.0),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(14.0),
            onTap: () => _showSectorBriefing(sector),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 14.0,
                vertical: 10.0,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                sector.name,
                                style: const TextStyle(
                                  color: VoidTheme.textPrimary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14.0,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6.0),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5.0,
                                vertical: 1.0,
                              ),
                              decoration: BoxDecoration(
                                color: VoidTheme.emeraldShield.withValues(
                                  alpha: 0.2,
                                ),
                                borderRadius: BorderRadius.circular(4.0),
                                border: Border.all(
                                  color: VoidTheme.emeraldShield,
                                  width: 0.8,
                                ),
                              ),
                              child: const Text(
                                'LIBERATED',
                                style: TextStyle(
                                  color: VoidTheme.emeraldShield,
                                  fontSize: 8.0,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3.0),
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 6.0,
                          runSpacing: 2.0,
                          children: [
                            Text(
                              '${sector.region.toUpperCase()} • TIER ${sector.difficultyTier + 1}',
                              style: const TextStyle(
                                color: VoidTheme.plasmaCyan,
                                fontSize: 10.0,
                                letterSpacing: 0.5,
                              ),
                            ),
                            if (sector.starsEarned > 0)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: List.generate(
                                  sector.starsEarned,
                                  (i) => const Icon(
                                    Icons.star,
                                    size: 11.0,
                                    color: VoidTheme.solarGold,
                                  ),
                                ),
                              ),
                            if (sector.bestScore > 0)
                              Text(
                                'BEST: ${sector.bestScore}',
                                style: const TextStyle(
                                  color: VoidTheme.textSecondary,
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '★ ${sector.bestScore > 0 ? sector.bestScore : (sector.starsEarned > 0 ? sector.starsEarned * 1400 : 4200)}',
                        style: const TextStyle(
                          color: VoidTheme.solarGold,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(width: 8.0),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F172A),
                          foregroundColor: VoidTheme.emeraldShield,
                          side: const BorderSide(
                            color: VoidTheme.emeraldShield,
                            width: 1.0,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10.0,
                            vertical: 5.0,
                          ),
                          minimumSize: const Size(0, 30.0),
                        ),
                        icon: const Icon(Icons.refresh, size: 12.0),
                        onPressed: () => _launchSector(sector),
                        label: const Text(
                          'REPLAY',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 10.5,
                            letterSpacing: 0.4,
                          ),
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

    if (isHeroObjective) {
      return Material(
        color: Colors.transparent,
        child: Ink(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF082F49), Color(0xFF0C4A6E)],
            ),
            borderRadius: BorderRadius.circular(16.0),
            border: Border.all(color: const Color(0xFF00E5FF), width: 1.8),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00E5FF).withValues(alpha: 0.35),
                blurRadius: 12.0,
                spreadRadius: 1.0,
              ),
            ],
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16.0),
            onTap: () => _showSectorBriefing(sector),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 14.0,
                vertical: 12.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7.0,
                          vertical: 2.0,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0284C7),
                          borderRadius: BorderRadius.circular(4.0),
                        ),
                        child: const Text(
                          'OBJECTIVE',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 8.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                      Text(
                        'TIER ${sector.difficultyTier + 1}',
                        style: const TextStyle(
                          color: Color(0xFF38BDF8),
                          fontSize: 10.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6.0),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              sector.name,
                              style: const TextStyle(
                                color: VoidTheme.starWhite,
                                fontWeight: FontWeight.w900,
                                fontSize: 16.0,
                                letterSpacing: 0.4,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2.0),
                            Text(
                              sector.region.toUpperCase(),
                              style: const TextStyle(
                                color: Color(0xFF93C5FD),
                                fontSize: 10.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8.0),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Tooltip(
                            message: 'Auto-Solve with AI',
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(
                                  color: Color(0xFF00E5FF),
                                  width: 1.0,
                                ),
                                backgroundColor: const Color(0xFF082F49),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6.0,
                                  vertical: 4.0,
                                ),
                                minimumSize: const Size(34.0, 30.0),
                              ),
                              onPressed: () => _launchSectorWithAi(sector),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.smart_toy,
                                    size: 13.0,
                                    color: Color(0xFF00E5FF),
                                  ),
                                  SizedBox(width: 2.0),
                                  Text(
                                    'AI',
                                    style: TextStyle(
                                      color: Color(0xFF00E5FF),
                                      fontWeight: FontWeight.w900,
                                      fontSize: 10.0,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 6.0),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF00E5FF),
                              foregroundColor: const Color(0xFF041226),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14.0,
                                vertical: 8.0,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                              elevation: 4.0,
                            ),
                            icon: const Icon(
                              Icons.rocket_launch,
                              size: 14.0,
                              color: Color(0xFF041226),
                            ),
                            onPressed: () => _launchSector(sector),
                            label: const Text(
                              'ENGAGE',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 11.5,
                                color: Color(0xFF041226),
                              ),
                            ),
                          ),
                        ],
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

    if (sector.isUnlocked) {
      return Material(
        color: Colors.transparent,
        child: Ink(
          decoration: BoxDecoration(
            color: VoidTheme.cardSurface,
            borderRadius: BorderRadius.circular(12.0),
            border: Border.all(color: VoidTheme.solarGold, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: VoidTheme.solarGold.withValues(alpha: 0.2),
                blurRadius: 8.0,
              ),
            ],
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(12.0),
            onTap: () => _showSectorBriefing(sector),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 14.0,
                vertical: 10.0,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                sector.name,
                                style: const TextStyle(
                                  color: VoidTheme.starWhite,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 14.0,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6.0),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5.0,
                                vertical: 1.0,
                              ),
                              decoration: BoxDecoration(
                                color: VoidTheme.solarGold.withValues(
                                  alpha: 0.2,
                                ),
                                borderRadius: BorderRadius.circular(4.0),
                                border: Border.all(
                                  color: VoidTheme.solarGold,
                                  width: 0.8,
                                ),
                              ),
                              child: const Text(
                                'OBJECTIVE',
                                style: TextStyle(
                                  color: VoidTheme.solarGold,
                                  fontSize: 8.0,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3.0),
                        Text(
                          '${sector.region.toUpperCase()} • TIER ${sector.difficultyTier + 1}',
                          style: const TextStyle(
                            color: VoidTheme.solarGoldLight,
                            fontSize: 10.0,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: VoidTheme.solarGold,
                      foregroundColor: VoidTheme.obsidianBlack,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12.0,
                        vertical: 6.0,
                      ),
                      minimumSize: const Size(0, 32.0),
                    ),
                    icon: const Icon(Icons.rocket_launch, size: 14.0),
                    onPressed: () => _launchSector(sector),
                    label: const Text(
                      'ENGAGE',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 11.5,
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

    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          color: const Color(0xFF0B111E).withValues(alpha: 0.75),
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(color: const Color(0xFF1E293B), width: 1.0),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12.0),
          onTap: () => _showLockedSectorDialog(sector),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 14.0,
              vertical: 10.0,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        sector.name,
                        style: const TextStyle(
                          color: VoidTheme.textMuted,
                          fontWeight: FontWeight.bold,
                          fontSize: 14.0,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3.0),
                      Text(
                        '${sector.region.toUpperCase()} • TIER ${sector.difficultyTier + 1}',
                        style: TextStyle(
                          color: VoidTheme.textMuted.withValues(alpha: 0.7),
                          fontSize: 9.5,
                        ),
                      ),
                      const SizedBox(height: 3.0),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6.0,
                          vertical: 2.0,
                        ),
                        decoration: BoxDecoration(
                          color: VoidTheme.crimsonFlare.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4.0),
                          border: Border.all(
                            color: VoidTheme.crimsonFlare.withValues(
                              alpha: 0.35,
                            ),
                            width: 0.8,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.lock,
                              size: 10.0,
                              color: VoidTheme.solarGoldLight,
                            ),
                            const SizedBox(width: 4.0),
                            Flexible(
                              child: Text(
                                'UNLOCK: ${sector.unlockRequirement}',
                                style: const TextStyle(
                                  color: VoidTheme.solarGoldLight,
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8.0),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: VoidTheme.solarGoldLight,
                    side: BorderSide(
                      color: VoidTheme.solarGold.withValues(alpha: 0.4),
                      width: 1.0,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8.0,
                      vertical: 4.0,
                    ),
                  ),
                  icon: const Icon(Icons.info_outline, size: 12.0),
                  label: const Text(
                    'LOCKED',
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  onPressed: () => _showLockedSectorDialog(sector),
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
