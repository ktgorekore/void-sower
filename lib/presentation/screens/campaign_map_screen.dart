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

import '../../domain/models/campaign_sector.dart';
import '../../domain/models/user_profile.dart';
import '../../domain/services/campaign_service.dart';
import '../../domain/services/game_engine_interface.dart';
import '../../domain/services/persistence_service.dart';
import '../services/haptic_service.dart';
import '../theme/void_theme.dart';
import '../widgets/bao_codex_dialog.dart';
import '../widgets/fleet_hangar_dialog.dart';
import '../widgets/landscape_orientation_shield.dart';
import '../widgets/profile_modal.dart';
import '../widgets/settings_modal.dart';
import '../widgets/tactile_button.dart';
import 'combat_screen.dart';
import 'stats_dashboard_screen.dart';

/// Interactive Star Map Screen for the Kilwa Nebula Basin Campaign.
class CampaignMapScreen extends StatefulWidget {
  const CampaignMapScreen({super.key, required this.engine});

  final IVoidSowerEngine engine;

  @override
  State<CampaignMapScreen> createState() => _CampaignMapScreenState();
}

class _CampaignMapScreenState extends State<CampaignMapScreen> {
  late List<CampaignSector> _sectors;
  String _selectedChassisId = 'mk1_bastion';

  @override
  void initState() {
    super.initState();
    _sectors = CampaignService.instance.getSectors();
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
          onReturnToMap: () {
            Navigator.of(context).pop();
            setState(() {
              _sectors = CampaignService.instance.getSectors();
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
            _sectors = CampaignService.instance.getSectors();
          });
        },
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
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(22.0),
          decoration: VoidTheme.glassmorphic(
            borderColor: VoidTheme.crimsonFlare,
            borderWidth: 1.5,
            borderRadius: 20.0,
          ),
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
                    if (sector.requiredSectorName != null) ...[
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
              if (requiredSector != null && requiredSector.isUnlocked) ...[
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
              ] else
                TactileButton(
                  label: 'DISMISS INTEL',
                  icon: Icons.close,
                  onPressed: () => Navigator.of(context).pop(),
                  accentColor: VoidTheme.plasmaCyan,
                  isPrimary: false,
                  height: 44.0,
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = PersistenceService.instance.userProfile;

    return Scaffold(
      backgroundColor: VoidTheme.obsidianBlack,
      appBar: AppBar(
        backgroundColor: VoidTheme.obsidianBlack,
        elevation: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'VOID SOWER',
              style: TextStyle(
                color: VoidTheme.solarGold,
                fontSize: 16.0,
                fontWeight: FontWeight.w900,
                letterSpacing: 2.0,
              ),
            ),
            Text(
              'KILWA NEBULA BASIN',
              style: TextStyle(
                color: VoidTheme.plasmaCyan,
                fontSize: 9.5,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.rocket_launch, color: VoidTheme.plasmaCyan),
            tooltip: 'Fleet Hangar',
            onPressed: _openHangar,
          ),
          IconButton(
            icon: const Icon(Icons.account_circle, color: VoidTheme.solarGold),
            tooltip: 'Pilot Profile',
            onPressed: _openProfile,
          ),
          IconButton(
            icon: const Icon(
              Icons.menu_book_rounded,
              color: VoidTheme.solarGoldLight,
            ),
            tooltip: 'Bao Codex',
            onPressed: _openCodex,
          ),
          IconButton(
            icon: const Icon(
              Icons.leaderboard_rounded,
              color: VoidTheme.starWhite,
            ),
            tooltip: 'Combat Telemetry',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (context) => const StatsDashboardScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(
              Icons.settings_rounded,
              color: VoidTheme.solarGold,
            ),
            tooltip: 'Fleet Settings',
            onPressed: _openSettings,
          ),
        ],
      ),
      body: LayoutBuilder(
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
                  // Command Deck Status Row
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 4.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 8.0,
                              height: 8.0,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: VoidTheme.emeraldShield,
                                boxShadow: [
                                  BoxShadow(
                                    color: VoidTheme.emeraldShield,
                                    blurRadius: 6.0,
                                    spreadRadius: 1.0,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8.0),
                            const Text(
                              'ORBITAL COMMAND DECK',
                              style: TextStyle(
                                color: VoidTheme.emeraldShield,
                                fontSize: 10.0,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ],
                        ),
                        Builder(
                          builder: (context) {
                            final liberatedCount = _sectors
                                .where((s) => s.isLiberated)
                                .length;
                            final totalSectors = _sectors.length;
                            final percent = totalSectors > 0
                                ? liberatedCount / totalSectors
                                : 0.0;
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'LIBERATED: $liberatedCount / $totalSectors (${(percent * 100).toInt()}%)',
                                  style: const TextStyle(
                                    color: VoidTheme.solarGold,
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 3.0),
                                SizedBox(
                                  width: 100.0,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(2.0),
                                    child: LinearProgressIndicator(
                                      value: percent,
                                      backgroundColor: VoidTheme.cardSurface,
                                      valueColor:
                                          const AlwaysStoppedAnimation<Color>(
                                            VoidTheme.emeraldShield,
                                          ),
                                      minHeight: 3.5,
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  // Pilot Profile & Active Flagship Cards Row
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 6.0,
                    ),
                    child: Row(
                      children: [
                        // 1. Prominent Pilot Profile Card
                        Expanded(child: _buildPilotProfileCard(profile)),
                        const SizedBox(width: 10.0),
                        // 2. Prominent Active Flagship Card
                        Expanded(child: _buildFlagshipCard()),
                      ],
                    ),
                  ),

                  // Campaign Sector List Header
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 4.0),
                    child: Row(
                      children: [
                        Icon(
                          Icons.radar,
                          color: VoidTheme.solarGold,
                          size: 14.0,
                        ),
                        SizedBox(width: 6.0),
                        Text(
                          'MISSION TARGETS • SELECT SECTOR',
                          style: TextStyle(
                            color: VoidTheme.solarGold,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Sector List
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 6.0,
                      ),
                      itemCount: _sectors.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 10.0),
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
    );
  }

  Widget _buildPilotProfileCard(UserProfile profile) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _openProfile,
        borderRadius: BorderRadius.circular(12.0),
        child: Container(
          padding: const EdgeInsets.all(10.0),
          decoration: BoxDecoration(
            color: VoidTheme.cardSurface.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(12.0),
            border: Border.all(
              color: profile.isGoogleLinked
                  ? VoidTheme.plasmaCyan
                  : VoidTheme.solarGold.withValues(alpha: 0.7),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color:
                    (profile.isGoogleLinked
                            ? VoidTheme.plasmaCyan
                            : VoidTheme.solarGold)
                        .withValues(alpha: 0.12),
                blurRadius: 8.0,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Category Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.account_circle,
                        color: profile.isGoogleLinked
                            ? VoidTheme.plasmaCyan
                            : VoidTheme.solarGold,
                        size: 13.0,
                      ),
                      const SizedBox(width: 4.0),
                      Text(
                        'USER PROFILE',
                        style: TextStyle(
                          color: profile.isGoogleLinked
                              ? VoidTheme.plasmaCyan
                              : VoidTheme.solarGold,
                          fontSize: 9.0,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: profile.isGoogleLinked
                        ? VoidTheme.plasmaCyan
                        : VoidTheme.solarGold,
                    size: 14.0,
                  ),
                ],
              ),
              const SizedBox(height: 8.0),
              // Avatar & Pilot Identifiers
              Row(
                children: [
                  Container(
                    width: 34.0,
                    height: 34.0,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: VoidTheme.obsidianBlack,
                      border: Border.all(
                        color: profile.isGoogleLinked
                            ? VoidTheme.plasmaCyan
                            : VoidTheme.solarGold,
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.person,
                        color: profile.isGoogleLinked
                            ? VoidTheme.plasmaCyan
                            : VoidTheme.solarGold,
                        size: 20.0,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          profile.callsign,
                          style: const TextStyle(
                            color: VoidTheme.starWhite,
                            fontSize: 12.0,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.4,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 1.0),
                        Text(
                          '${profile.rank.title.toUpperCase()} • ${profile.isGoogleLinked ? "GOOGLE" : "GUEST"}',
                          style: TextStyle(
                            color: profile.isGoogleLinked
                                ? VoidTheme.plasmaCyan
                                : VoidTheme.emeraldShield,
                            fontSize: 8.0,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6.0),
              const Text(
                'Tap to manage dossier',
                style: TextStyle(color: VoidTheme.textMuted, fontSize: 8.0),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFlagshipCard() {
    final chassisName = _selectedChassisId == 'mk1_bastion'
        ? 'MK-I Bastion'
        : (_selectedChassisId == 'mk2_monsoon'
              ? 'MK-II Monsoon'
              : 'MK-III Singularity');

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _openHangar,
        borderRadius: BorderRadius.circular(12.0),
        child: Container(
          padding: const EdgeInsets.all(10.0),
          decoration: BoxDecoration(
            color: VoidTheme.cardSurface.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(12.0),
            border: Border.all(
              color: VoidTheme.plasmaCyan.withValues(alpha: 0.7),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: VoidTheme.plasmaCyan.withValues(alpha: 0.12),
                blurRadius: 8.0,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Category Header
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.rocket_launch,
                        color: VoidTheme.plasmaCyan,
                        size: 13.0,
                      ),
                      SizedBox(width: 4.0),
                      Text(
                        'ACTIVE FLEET',
                        style: TextStyle(
                          color: VoidTheme.plasmaCyan,
                          fontSize: 9.0,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: VoidTheme.plasmaCyan,
                    size: 14.0,
                  ),
                ],
              ),
              const SizedBox(height: 8.0),
              // Flagship Emblem & Info
              Row(
                children: [
                  Container(
                    width: 34.0,
                    height: 34.0,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: VoidTheme.obsidianBlack,
                      border: Border.all(
                        color: VoidTheme.plasmaCyan,
                        width: 1.5,
                      ),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.rocket_launch,
                        color: VoidTheme.plasmaCyan,
                        size: 18.0,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          chassisName,
                          style: const TextStyle(
                            color: VoidTheme.plasmaCyanLight,
                            fontSize: 12.0,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.4,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 1.0),
                        const Text(
                          'DREADNOUGHT • HANGAR',
                          style: TextStyle(
                            color: VoidTheme.solarGold,
                            fontSize: 8.0,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6.0),
              const Text(
                'Tap to open fleet hangar',
                style: TextStyle(color: VoidTheme.textMuted, fontSize: 8.0),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
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
      trailingWidget = ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: VoidTheme.cardSurface,
          foregroundColor: VoidTheme.emeraldShield,
          side: const BorderSide(color: VoidTheme.emeraldShield, width: 1.0),
          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
        ),
        icon: const Icon(Icons.refresh, size: 14.0),
        onPressed: () => _launchSector(sector),
        label: const Text(
          'REPLAY',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.0),
        ),
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
      trailingWidget = ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: VoidTheme.solarGold,
          foregroundColor: VoidTheme.obsidianBlack,
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
        ),
        icon: const Icon(Icons.rocket_launch, size: 14.0),
        onPressed: () => _launchSector(sector),
        label: const Text(
          'ENGAGE',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5),
        ),
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
