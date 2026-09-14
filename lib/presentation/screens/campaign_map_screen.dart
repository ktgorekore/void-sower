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
import '../../domain/services/campaign_service.dart';
import '../../domain/services/game_engine_interface.dart';
import '../../domain/services/persistence_service.dart';
import '../services/haptic_service.dart';
import '../theme/void_theme.dart';
import '../widgets/bao_codex_dialog.dart';
import '../widgets/fleet_hangar_dialog.dart';
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
    if (!sector.isUnlocked) return;
    HapticService.instance.injectionClick();

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => CombatScreen(
          engine: widget.engine,
          difficultyTier: sector.difficultyTier,
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
    if (!sector.isUnlocked) return;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VoidTheme.obsidianBlack,
      appBar: AppBar(
        backgroundColor: VoidTheme.obsidianBlack,
        elevation: 0,
        title: const Text(
          'KILWA NEBULA BASIN',
          style: TextStyle(
            color: VoidTheme.solarGold,
            fontSize: 16.0,
            fontWeight: FontWeight.bold,
            letterSpacing: 2.0,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.precision_manufacturing,
              color: VoidTheme.plasmaCyan,
            ),
            tooltip: 'Fleet Hangar',
            onPressed: _openHangar,
          ),
          IconButton(
            icon: const Icon(Icons.badge, color: VoidTheme.plasmaCyanLight),
            tooltip: 'Pilot Profile',
            onPressed: _openProfile,
          ),
          IconButton(
            icon: const Icon(Icons.menu_book, color: VoidTheme.solarGold),
            tooltip: 'Bao Codex',
            onPressed: _openCodex,
          ),
          IconButton(
            icon: const Icon(Icons.bar_chart, color: VoidTheme.starWhite),
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
            icon: const Icon(Icons.settings, color: VoidTheme.solarGold),
            tooltip: 'Fleet Settings',
            onPressed: _openSettings,
          ),
        ],
      ),
      body: Column(
        children: [
          // Pilot Profile & Active Flagship Status Row
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 6.0,
            ),
            child: Row(
              children: [
                // Pilot Profile Pill
                Expanded(
                  child: GestureDetector(
                    onTap: _openProfile,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10.0,
                        vertical: 8.0,
                      ),
                      decoration: BoxDecoration(
                        color: VoidTheme.cardSurface.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(8.0),
                        border: Border.all(
                          color:
                              PersistenceService
                                  .instance
                                  .userProfile
                                  .isGoogleLinked
                              ? VoidTheme.plasmaCyan
                              : VoidTheme.solarGold.withValues(alpha: 0.5),
                          width: 1.0,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            PersistenceService
                                .instance
                                .userProfile
                                .insignia
                                .iconData,
                            color:
                                PersistenceService
                                    .instance
                                    .userProfile
                                    .isGoogleLinked
                                ? VoidTheme.plasmaCyan
                                : VoidTheme.solarGold,
                            size: 16.0,
                          ),
                          const SizedBox(width: 8.0),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  PersistenceService
                                      .instance
                                      .userProfile
                                      .callsign,
                                  style: const TextStyle(
                                    color: VoidTheme.starWhite,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  '${PersistenceService.instance.userProfile.rank.title.toUpperCase()} • ${PersistenceService.instance.userProfile.isGoogleLinked ? "GOOGLE" : "GUEST"}',
                                  style: TextStyle(
                                    color:
                                        PersistenceService
                                            .instance
                                            .userProfile
                                            .isGoogleLinked
                                        ? VoidTheme.plasmaCyan
                                        : VoidTheme.emeraldShield,
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right,
                            color: VoidTheme.solarGold,
                            size: 16.0,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8.0),
                // Active Flagship Status Banner
                Expanded(
                  child: GestureDetector(
                    onTap: _openHangar,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10.0,
                        vertical: 8.0,
                      ),
                      decoration: BoxDecoration(
                        color: VoidTheme.cardSurface.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(8.0),
                        border: Border.all(
                          color: VoidTheme.plasmaCyan.withValues(alpha: 0.4),
                          width: 1.0,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.flight,
                            color: VoidTheme.plasmaCyan,
                            size: 16.0,
                          ),
                          const SizedBox(width: 8.0),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _selectedChassisId == 'mk1_bastion'
                                      ? 'MK-I Bastion'
                                      : (_selectedChassisId == 'mk2_monsoon'
                                            ? 'MK-II Monsoon'
                                            : 'MK-III Singularity'),
                                  style: const TextStyle(
                                    color: VoidTheme.plasmaCyanLight,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const Text(
                                  'FLAGSHIP • HANGAR',
                                  style: TextStyle(
                                    color: VoidTheme.solarGold,
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right,
                            color: VoidTheme.plasmaCyan,
                            size: 16.0,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Sector List
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16.0),
              itemCount: _sectors.length,
              separatorBuilder: (context, index) =>
                  const SizedBox(height: 12.0),
              itemBuilder: (context, index) {
                final s = _sectors[index];
                return _buildSectorCard(s);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectorCard(CampaignSector sector) {
    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          color: sector.isUnlocked
              ? VoidTheme.cardSurface
              : VoidTheme.deepSpaceVoid,
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(
            color: sector.isUnlocked
                ? (sector.difficultyTier == 2
                      ? VoidTheme.crimsonFlare
                      : VoidTheme.solarGold)
                : VoidTheme.textMuted.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        child: ListTile(
          onTap: () => _showSectorBriefing(sector),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16.0,
            vertical: 8.0,
          ),
          leading: CircleAvatar(
            backgroundColor: sector.isUnlocked
                ? VoidTheme.solarGold
                : VoidTheme.textMuted,
            child: Icon(
              sector.isUnlocked ? Icons.shield : Icons.lock,
              color: VoidTheme.obsidianBlack,
              size: 20.0,
            ),
          ),
          title: Text(
            sector.name,
            style: TextStyle(
              color: sector.isUnlocked
                  ? VoidTheme.textPrimary
                  : VoidTheme.textMuted,
              fontWeight: FontWeight.bold,
              fontSize: 15.0,
            ),
          ),
          subtitle: Row(
            children: [
              Text(
                '${sector.region.toUpperCase()} • TIER ${sector.difficultyTier + 1}',
                style: TextStyle(
                  color: sector.isUnlocked
                      ? VoidTheme.plasmaCyan
                      : VoidTheme.textMuted,
                  fontSize: 11.0,
                  letterSpacing: 0.5,
                ),
              ),
              if (sector.isUnlocked && sector.starsEarned > 0) ...[
                const SizedBox(width: 8.0),
                Row(
                  children: List.generate(
                    sector.starsEarned,
                    (i) => const Icon(
                      Icons.star,
                      size: 12.0,
                      color: VoidTheme.solarGold,
                    ),
                  ),
                ),
              ],
            ],
          ),
          trailing: sector.isUnlocked
              ? ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: VoidTheme.solarGold,
                    foregroundColor: VoidTheme.obsidianBlack,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8.0,
                    ),
                  ),
                  onPressed: () => _launchSector(sector),
                  child: const Text(
                    'ENGAGE',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                )
              : const Text(
                  'LOCKED',
                  style: TextStyle(color: VoidTheme.textMuted, fontSize: 12.0),
                ),
        ),
      ),
    );
  }
}
