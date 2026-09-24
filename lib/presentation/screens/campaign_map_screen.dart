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

  void _launchAiSolver() {
    HapticService.instance.injectionClick();
    final targetSector = _sectors.firstWhere(
      (s) => s.isUnlocked && !s.isLiberated,
      orElse: () => _sectors.firstWhere(
        (s) => s.isUnlocked,
        orElse: () => _sectors.first,
      ),
    );
    _launchSectorWithAi(targetSector);
  }

  void _openCodex() {
    showDialog<void>(
      context: context,
      builder: (context) =>
          TacticalDirectivesModal(onLaunchAcademy: _launchAcademy),
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
              Text(
                'Defend the orbital horizon from invading carrier wings. '
                'Sow plasma across your 16 capacitor bays to unleash axial quadratic lances '
                'and liberate the ${sector.name} basin.',
                style: const TextStyle(
                  color: VoidTheme.textSecondary,
                  fontSize: 12.5,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20.0),
              TactileButton(
                label: 'ENGAGE BATTLE',
                icon: Icons.rocket_launch,
                onPressed: () {
                  Navigator.of(context).pop();
                  _launchSector(sector);
                },
                accentColor: VoidTheme.solarGold,
                height: 48.0,
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
        padding: const EdgeInsets.all(4.0),
        decoration: BoxDecoration(
          color: VoidTheme.cardSurface.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(10.0),
          border: Border.all(
            color: VoidTheme.plasmaCyan.withValues(alpha: 0.2),
            width: 1.0,
          ),
        ),
        child: Row(
          children: operations.map((op) {
            final isSelected = op.id == _activeCampaignId;
            final isLocked = op.isProRequired && !isPro;

            return Expanded(
              child: GestureDetector(
                onTap: () => _switchCampaign(op.id),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    vertical: 7.0,
                    horizontal: 4.0,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? VoidTheme.solarGold.withValues(alpha: 0.18)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(7.0),
                    border: Border.all(
                      color: isSelected
                          ? VoidTheme.solarGold
                          : Colors.transparent,
                      width: 1.0,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(
                              op.id == 'kilwa_basin' ? 'KILWA BASIN' : op.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: isSelected
                                    ? VoidTheme.solarGold
                                    : (isLocked
                                          ? VoidTheme.textMuted
                                          : VoidTheme.starWhite),
                                fontSize: 9.5,
                                fontWeight: isSelected
                                    ? FontWeight.w900
                                    : FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          if (isLocked) ...[
                            const SizedBox(width: 3.0),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 3.0,
                                vertical: 1.0,
                              ),
                              decoration: BoxDecoration(
                                color: VoidTheme.solarGold.withValues(
                                  alpha: 0.25,
                                ),
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
                                  fontSize: 6.5,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2.0),
                      Text(
                        '${op.liberatedCount}/${op.totalSectors} LIBERATED',
                        style: TextStyle(
                          color: isSelected
                              ? VoidTheme.plasmaCyan
                              : VoidTheme.textMuted,
                          fontSize: 7.5,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                        ),
                      ),
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
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 3.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
        decoration: BoxDecoration(
          color: VoidTheme.obsidianBlack.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(8.0),
          border: Border.all(
            color: doctrineColor.withValues(alpha: 0.3),
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

  @override
  Widget build(BuildContext context) {
    final activeOp = CampaignService.instance.getOperation(_activeCampaignId);

    return Scaffold(
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
                    // 1. Top Navigation Bar (5 tabs matching Home Screen mockup)
                    _buildTopNavBar(),

                    // 2. Large Centered Title & Liberation Progress Bar
                    _buildCampaignHeader(activeOp),

                    // 3. Theater Switcher Tabs (Kilwa Basin, Phantom Drift, Void Swarm)
                    _buildTheaterSwitcher(),

                    // 4. Tactical Doctrine & Mission Briefing Banner
                    _buildDoctrineBanner(),

                    // 5. Campaign Sector Mission Cards List
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 6.0,
                        ),
                        itemCount: _sectors.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 8.0),
                        itemBuilder: (context, index) {
                          final s = _sectors[index];
                          return _buildSectorCard(s);
                        },
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

  /// Builds the 5-tab top navigation bar exactly matching home_screen_redesign mockup:
  /// [ SECTORS ] [ FLEET ] [ PILOT ] [ DIRECTIVES ] [ SETTINGS ]
  Widget _buildTopNavBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
      decoration: BoxDecoration(
        color: VoidTheme.obsidianBlack,
        border: Border(
          bottom: BorderSide(
            color: VoidTheme.plasmaCyan.withValues(alpha: 0.15),
            width: 1.0,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildTopNavTab(
            icon: Icons.map_outlined,
            label: 'SECTORS',
            isActive: true,
            tooltip: 'Campaign Sectors',
            onTap: () {},
          ),
          _buildTopNavTab(
            icon: Icons.rocket_launch,
            label: 'FLEET',
            isActive: false,
            tooltip: 'Fleet Hangar',
            onTap: _openHangar,
          ),
          _buildTopNavTab(
            icon: Icons.account_circle_outlined,
            label: 'PILOT',
            isActive: false,
            tooltip: 'Pilot Profile',
            onTap: _openProfile,
          ),
          _buildTopNavTab(
            icon: Icons.school,
            label: 'DIRECTIVES',
            isActive: false,
            tooltip: 'Flight Academy',
            onTap: _openCodex,
          ),
          _buildTopNavTab(
            icon: Icons.smart_toy,
            label: 'AI',
            isActive: false,
            tooltip: 'AI Tactical Auto-Solver',
            onTap: _launchAiSolver,
          ),
          _buildTopNavTab(
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

  Widget _buildTopNavTab({
    required IconData icon,
    required String label,
    required bool isActive,
    required String tooltip,
    required VoidCallback onTap,
  }) {
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
              Icon(
                icon,
                color: isActive
                    ? VoidTheme.plasmaCyan
                    : VoidTheme.textSecondary,
                size: 22.0,
              ),
              const SizedBox(height: 3.0),
              Text(
                label,
                style: TextStyle(
                  color: isActive
                      ? VoidTheme.plasmaCyan
                      : VoidTheme.textSecondary,
                  fontSize: 9.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 3.0),
              Container(
                height: 2.8,
                width: 32.0,
                decoration: BoxDecoration(
                  color: isActive ? VoidTheme.plasmaCyan : Colors.transparent,
                  borderRadius: BorderRadius.circular(1.4),
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                            color: VoidTheme.plasmaCyan.withValues(alpha: 0.7),
                            blurRadius: 4.0,
                          ),
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
      padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 4.0),
      child: Column(
        children: [
          const Text(
            'VOID SOWER',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: VoidTheme.plasmaCyan,
              fontSize: 10.0,
              fontWeight: FontWeight.w900,
              letterSpacing: 2.5,
            ),
          ),
          const SizedBox(height: 2.0),
          Text(
            activeOp.title.toUpperCase(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: VoidTheme.solarGold,
              fontSize: 18.0,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.8,
              shadows: [Shadow(color: Color(0x66FFB300), blurRadius: 8.0)],
            ),
          ),
          const SizedBox(height: 2.0),
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 4.0,
            children: [
              const Text(
                'ORBITAL COMMAND DECK',
                style: TextStyle(
                  color: VoidTheme.plasmaCyanLight,
                  fontSize: 9.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
              const Text(
                '•',
                style: TextStyle(color: VoidTheme.textMuted, fontSize: 9.5),
              ),
              Text(
                'LIBERATED: $liberatedCount / $totalSectors (${(percent * 100).toInt()}%)',
                style: const TextStyle(
                  color: VoidTheme.solarGoldLight,
                  fontSize: 9.5,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6.0),
          Container(
            height: 5.0,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2.5),
              boxShadow: [
                BoxShadow(
                  color: VoidTheme.plasmaCyan.withValues(alpha: 0.45),
                  blurRadius: 6.0,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2.5),
              child: LinearProgressIndicator(
                value: percent,
                backgroundColor: VoidTheme.cardSurface,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  VoidTheme.plasmaCyan,
                ),
                minHeight: 5.0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectorCard(CampaignSector sector) {
    final isLiberated = sector.isLiberated;
    final isUnlocked = sector.isUnlocked;

    Color borderColor;
    double borderWidth;
    List<BoxShadow>? shadows;
    Widget leadingAvatar;
    Widget titleWidget;
    Widget subtitleWidget;
    Widget trailingWidget;

    if (isLiberated) {
      borderColor = VoidTheme.emeraldShield;
      borderWidth = 1.4;
      shadows = [
        BoxShadow(
          color: VoidTheme.emeraldShield.withValues(alpha: 0.12),
          blurRadius: 6.0,
        ),
      ];
      leadingAvatar = const CircleAvatar(
        backgroundColor: VoidTheme.emeraldShield,
        child: Icon(
          Icons.check_circle,
          color: VoidTheme.obsidianBlack,
          size: 20.0,
        ),
      );
      titleWidget = Row(
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
            padding: const EdgeInsets.symmetric(horizontal: 5.0, vertical: 1.0),
            decoration: BoxDecoration(
              color: VoidTheme.emeraldShield.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(4.0),
              border: Border.all(color: VoidTheme.emeraldShield, width: 0.8),
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
      );
      subtitleWidget = Wrap(
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
      );
      trailingWidget = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Tooltip(
            message: 'Auto-Solve with AI',
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: VoidTheme.plasmaCyan.withValues(alpha: 0.5),
                  width: 1.0,
                ),
                backgroundColor: VoidTheme.cardSurface,
                padding: const EdgeInsets.symmetric(
                  horizontal: 6.0,
                  vertical: 4.0,
                ),
                minimumSize: const Size(36.0, 30.0),
              ),
              onPressed: () => _launchSectorWithAi(sector),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.smart_toy,
                    size: 13.0,
                    color: VoidTheme.plasmaCyan,
                  ),
                  SizedBox(width: 2.0),
                  Text(
                    'AI',
                    style: TextStyle(
                      color: VoidTheme.plasmaCyan,
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
              backgroundColor: VoidTheme.cardSurface,
              foregroundColor: VoidTheme.emeraldShield,
              side: const BorderSide(
                color: VoidTheme.emeraldShield,
                width: 1.0,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 10.0,
                vertical: 6.0,
              ),
            ),
            icon: const Icon(Icons.refresh, size: 14.0),
            onPressed: () => _launchSector(sector),
            label: const Text(
              'REPLAY',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.0),
            ),
          ),
        ],
      );
    } else if (isUnlocked) {
      borderColor = VoidTheme.solarGold;
      borderWidth = 1.8;
      shadows = [
        BoxShadow(
          color: VoidTheme.solarGold.withValues(alpha: 0.2),
          blurRadius: 8.0,
        ),
      ];
      leadingAvatar = const CircleAvatar(
        backgroundColor: VoidTheme.solarGold,
        child: Icon(Icons.radar, color: VoidTheme.obsidianBlack, size: 20.0),
      );
      titleWidget = Row(
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
            padding: const EdgeInsets.symmetric(horizontal: 5.0, vertical: 1.0),
            decoration: BoxDecoration(
              color: VoidTheme.solarGold.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(4.0),
              border: Border.all(color: VoidTheme.solarGold, width: 0.8),
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
      );
      subtitleWidget = Text(
        '${sector.region.toUpperCase()} • TIER ${sector.difficultyTier + 1} • VANGUARD ASSAULT',
        style: const TextStyle(
          color: VoidTheme.solarGoldLight,
          fontSize: 10.0,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.4,
        ),
      );
      trailingWidget = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Tooltip(
            message: 'Auto-Solve with AI',
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: VoidTheme.plasmaCyan.withValues(alpha: 0.7),
                  width: 1.0,
                ),
                backgroundColor: VoidTheme.cardSurface,
                padding: const EdgeInsets.symmetric(
                  horizontal: 6.0,
                  vertical: 4.0,
                ),
                minimumSize: const Size(36.0, 30.0),
              ),
              onPressed: () => _launchSectorWithAi(sector),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.smart_toy,
                    size: 13.0,
                    color: VoidTheme.plasmaCyan,
                  ),
                  SizedBox(width: 2.0),
                  Text(
                    'AI',
                    style: TextStyle(
                      color: VoidTheme.plasmaCyan,
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
              backgroundColor: VoidTheme.solarGold,
              foregroundColor: VoidTheme.obsidianBlack,
              padding: const EdgeInsets.symmetric(
                horizontal: 12.0,
                vertical: 6.0,
              ),
            ),
            icon: const Icon(Icons.rocket_launch, size: 14.0),
            onPressed: () => _launchSector(sector),
            label: const Text(
              'ENGAGE',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5),
            ),
          ),
        ],
      );
    } else {
      borderColor = VoidTheme.crimsonFlare.withValues(alpha: 0.35);
      borderWidth = 1.2;
      shadows = null;
      leadingAvatar = CircleAvatar(
        backgroundColor: VoidTheme.cardSurface,
        child: Icon(
          Icons.lock,
          color: VoidTheme.crimsonFlare.withValues(alpha: 0.8),
          size: 18.0,
        ),
      );
      titleWidget = Text(
        sector.name,
        style: const TextStyle(
          color: VoidTheme.textMuted,
          fontWeight: FontWeight.bold,
          fontSize: 14.0,
        ),
        overflow: TextOverflow.ellipsis,
      );
      subtitleWidget = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${sector.region.toUpperCase()} • TIER ${sector.difficultyTier + 1} [BLOCKADED]',
            style: TextStyle(
              color: VoidTheme.textMuted.withValues(alpha: 0.7),
              fontSize: 9.5,
            ),
          ),
          const SizedBox(height: 3.0),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
            decoration: BoxDecoration(
              color: VoidTheme.crimsonFlare.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(4.0),
              border: Border.all(
                color: VoidTheme.crimsonFlare.withValues(alpha: 0.35),
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
      );
      trailingWidget = OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          foregroundColor: VoidTheme.solarGoldLight,
          side: BorderSide(
            color: VoidTheme.solarGold.withValues(alpha: 0.4),
            width: 1.0,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
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
      );
    }

    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          color: isUnlocked ? VoidTheme.cardSurface : VoidTheme.deepSpaceVoid,
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(color: borderColor, width: borderWidth),
          boxShadow: shadows,
        ),
        child: ListTile(
          onTap: () => isUnlocked
              ? _showSectorBriefing(sector)
              : _showLockedSectorDialog(sector),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16.0,
            vertical: 6.0,
          ),
          leading: leadingAvatar,
          title: titleWidget,
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 2.0),
            child: subtitleWidget,
          ),
          trailing: trailingWidget,
        ),
      ),
    );
  }
}
