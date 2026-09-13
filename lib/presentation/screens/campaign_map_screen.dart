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
import '../services/haptic_service.dart';
import '../theme/void_theme.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VoidTheme.obsidianBlack,
      appBar: AppBar(
        backgroundColor: VoidTheme.obsidianBlack,
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
            icon: const Icon(Icons.bar_chart, color: VoidTheme.plasmaCyan),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (context) => const StatsDashboardScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16.0),
        itemCount: _sectors.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12.0),
        itemBuilder: (context, index) {
          final s = _sectors[index];
          return _buildSectorCard(s);
        },
      ),
    );
  }

  Widget _buildSectorCard(CampaignSector sector) {
    return Container(
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
        subtitle: Text(
          '${sector.region.toUpperCase()} • TIER ${sector.difficultyTier + 1}',
          style: TextStyle(
            color: sector.isUnlocked
                ? VoidTheme.plasmaCyan
                : VoidTheme.textMuted,
            fontSize: 11.0,
            letterSpacing: 0.5,
          ),
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
    );
  }
}
