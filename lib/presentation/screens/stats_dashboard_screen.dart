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
import 'package:flutter/services.dart';

import '../../domain/models/user_profile.dart';
import '../../domain/services/campaign_service.dart';
import '../../domain/services/persistence_service.dart';
import '../services/haptic_service.dart';
import '../theme/void_theme.dart';
import '../widgets/tactile_button.dart';

/// Comprehensive player profile and lifetime combat telemetry dashboard.
class StatsDashboardScreen extends StatefulWidget {
  const StatsDashboardScreen({super.key});

  @override
  State<StatsDashboardScreen> createState() => _StatsDashboardScreenState();
}

class _StatsDashboardScreenState extends State<StatsDashboardScreen> {
  final PersistenceService _persistence = PersistenceService.instance;
  final CampaignService _campaignService = CampaignService.instance;

  void _refresh() {
    if (mounted) setState(() {});
  }

  Future<void> _exportSave() async {
    HapticService.instance.sowTick();
    final data = _persistence.exportSaveJson();
    await Clipboard.setData(ClipboardData(text: data));
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Save telemetry data copied to clipboard.'),
        duration: Duration(seconds: 3),
      ),
    );
  }

  Future<void> _importSave() async {
    HapticService.instance.sowTick();
    final controller = TextEditingController();
    String? errorText;

    try {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => StatefulBuilder(
          builder: (ctx, setModalState) => AlertDialog(
            backgroundColor: VoidTheme.cardSurface,
            title: const Text(
              'RESTORE TELEMETRY SAVE',
              style: TextStyle(
                color: VoidTheme.solarGold,
                fontSize: 14.0,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Paste your base64 encoded save string with embedded checksum verification.',
                  style: TextStyle(
                    color: VoidTheme.textSecondary,
                    fontSize: 12.0,
                  ),
                ),
                const SizedBox(height: 12.0),
                TextField(
                  controller: controller,
                  maxLines: 4,
                  style: const TextStyle(color: Colors.white, fontSize: 12.0),
                  decoration: InputDecoration(
                    hintText: 'Paste export payload...',
                    hintStyle: const TextStyle(color: VoidTheme.textMuted),
                    errorText: errorText,
                    filled: true,
                    fillColor: VoidTheme.deepSpaceVoid,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                      borderSide: const BorderSide(color: VoidTheme.plasmaCyan),
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                child: const Text(
                  'CANCEL',
                  style: TextStyle(color: VoidTheme.textMuted),
                ),
                onPressed: () => Navigator.of(dialogContext).pop(),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: VoidTheme.solarGold,
                  foregroundColor: Colors.black,
                ),
                child: const Text('RESTORE'),
                onPressed: () async {
                  final success = await _persistence.importSaveJson(
                    controller.text,
                  );
                  if (success) {
                    if (dialogContext.mounted) {
                      Navigator.of(dialogContext).pop();
                    }
                    _refresh();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Save telemetry successfully restored.',
                          ),
                        ),
                      );
                    }
                  } else {
                    setModalState(() {
                      errorText = 'Invalid or corrupted save payload';
                    });
                  }
                },
              ),
            ],
          ),
        ),
      );
    } finally {
      controller.dispose();
    }
  }

  Future<void> _confirmEraseData() async {
    HapticService.instance.sowTick();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: VoidTheme.cardSurface,
        title: const Text(
          'ERASE GUEST TELEMETRY?',
          style: TextStyle(
            color: VoidTheme.crimsonFlare,
            fontSize: 14.0,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
        content: const Text(
          'This will permanently reset all campaign stars, personal scores, streaks, and unlocked chassis. This action cannot be undone under GDPR privacy mandates.',
          style: TextStyle(color: VoidTheme.textSecondary, fontSize: 13.0),
        ),
        actions: [
          TextButton(
            child: const Text(
              'CANCEL',
              style: TextStyle(color: VoidTheme.textMuted),
            ),
            onPressed: () => Navigator.of(dialogContext).pop(false),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: VoidTheme.crimsonFlare,
              foregroundColor: Colors.white,
            ),
            child: const Text('CONFIRM PURGE'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _persistence.wipeAllData();
      _refresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All local guest data erased.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = _persistence.userProfile;
    final isPro = _persistence.isProUnlocked;

    return Scaffold(
      backgroundColor: VoidTheme.obsidianBlack,
      appBar: AppBar(
        backgroundColor: VoidTheme.obsidianBlack,
        elevation: 0,
        iconTheme: const IconThemeData(color: VoidTheme.solarGold),
        title: const Text(
          'FLEET TELEMETRY',
          style: TextStyle(
            color: VoidTheme.solarGold,
            letterSpacing: 2.0,
            fontSize: 16.0,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 640.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildPilotDossierCard(profile, isPro),
                  const SizedBox(height: 14.0),
                  _buildDeploymentStreaksCard(profile),
                  const SizedBox(height: 14.0),
                  _buildMissionOutcomesCard(profile),
                  const SizedBox(height: 14.0),
                  _buildTacticalGridCard(profile),
                  const SizedBox(height: 14.0),
                  _buildCampaignMasteryCard(),
                  const SizedBox(height: 14.0),
                  _buildChassisDeploymentCard(profile),
                  const SizedBox(height: 16.0),
                  _buildDataManagementCard(),
                  const SizedBox(height: 24.0),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- Card 1: Pilot Dossier & Rank Card ---
  Widget _buildPilotDossierCard(UserProfile profile, bool isPro) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: VoidTheme.cardSurface,
        borderRadius: BorderRadius.circular(14.0),
        border: Border.all(
          color: VoidTheme.solarGold.withValues(alpha: 0.3),
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48.0,
                height: 48.0,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: VoidTheme.deepSpaceVoid,
                  border: Border.all(color: VoidTheme.solarGold, width: 1.5),
                ),
                child: Icon(
                  profile.insignia.iconData,
                  color: VoidTheme.solarGold,
                  size: 26.0,
                ),
              ),
              const SizedBox(width: 12.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.callsign.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16.0,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 2.0),
                    Text(
                      profile.insignia.displayName,
                      style: const TextStyle(
                        color: VoidTheme.textSecondary,
                        fontSize: 11.0,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10.0,
                  vertical: 4.0,
                ),
                decoration: BoxDecoration(
                  color: isPro
                      ? VoidTheme.solarGold.withValues(alpha: 0.15)
                      : VoidTheme.plasmaCyan.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20.0),
                  border: Border.all(
                    color: isPro ? VoidTheme.solarGold : VoidTheme.plasmaCyan,
                    width: 1.0,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isPro ? Icons.workspace_premium : Icons.shield_outlined,
                      color: isPro ? VoidTheme.solarGold : VoidTheme.plasmaCyan,
                      size: 14.0,
                    ),
                    const SizedBox(width: 4.0),
                    Text(
                      isPro ? 'PRO COMMANDER' : 'RECRUIT PILOT',
                      style: TextStyle(
                        color: isPro
                            ? VoidTheme.solarGold
                            : VoidTheme.plasmaCyan,
                        fontSize: 10.0,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'RANK: ${profile.rank.title.toUpperCase()}',
                style: const TextStyle(
                  color: VoidTheme.solarGold,
                  fontSize: 12.0,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
              Text(
                '${(profile.rankProgress * 100).toInt()}% TO ADVANCE',
                style: const TextStyle(
                  color: VoidTheme.textSecondary,
                  fontSize: 11.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6.0),
          ClipRRect(
            borderRadius: BorderRadius.circular(4.0),
            child: LinearProgressIndicator(
              value: profile.rankProgress,
              minHeight: 6.0,
              backgroundColor: VoidTheme.obsidianBlack,
              valueColor: const AlwaysStoppedAnimation<Color>(
                VoidTheme.solarGold,
              ),
            ),
          ),
          const SizedBox(height: 6.0),
          Text(
            '${profile.lifetimeScore} / ${profile.rank.maxScore} PTS',
            style: const TextStyle(color: VoidTheme.textMuted, fontSize: 10.0),
          ),
        ],
      ),
    );
  }

  // --- Card 2: Deployment Readiness & Daily Streaks Card ---
  Widget _buildDeploymentStreaksCard(UserProfile profile) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: VoidTheme.cardSurface,
        borderRadius: BorderRadius.circular(14.0),
        border: Border.all(color: VoidTheme.plasmaCyan.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8.0,
            runSpacing: 6.0,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(
                    Icons.local_fire_department,
                    color: Colors.deepOrangeAccent,
                    size: 20.0,
                  ),
                  SizedBox(width: 6.0),
                  Text(
                    'DEPLOYMENT READINESS & HABIT',
                    style: TextStyle(
                      color: VoidTheme.plasmaCyan,
                      fontSize: 12.0,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8.0,
                  vertical: 3.0,
                ),
                decoration: BoxDecoration(
                  color: Colors.deepOrangeAccent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12.0),
                  border: Border.all(color: Colors.deepOrangeAccent),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.bolt,
                      color: Colors.deepOrangeAccent,
                      size: 13.0,
                    ),
                    const SizedBox(width: 3.0),
                    Text(
                      '${profile.currentStreak} DAYS ACTIVE',
                      style: const TextStyle(
                        color: Colors.deepOrangeAccent,
                        fontSize: 10.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14.0),
          Row(
            children: [
              Expanded(
                child: _buildStreakStatPill(
                  label: 'LONGEST STREAK',
                  value: '${profile.longestStreak} Days',
                  icon: Icons.trending_up,
                  accentColor: VoidTheme.solarGold,
                ),
              ),
              const SizedBox(width: 8.0),
              Expanded(
                child: _buildStreakStatPill(
                  label: 'FLIGHT TIME',
                  value: profile.formattedFlightTime,
                  icon: Icons.timer_outlined,
                  accentColor: VoidTheme.plasmaCyan,
                ),
              ),
              const SizedBox(width: 8.0),
              Expanded(
                child: _buildStreakStatPill(
                  label: 'LAST SORTIE',
                  value: profile.lastPlayedDate ?? 'No Sorties',
                  icon: Icons.calendar_today_outlined,
                  accentColor: Colors.white70,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStreakStatPill({
    required String label,
    required String value,
    required IconData icon,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 10.0),
      decoration: BoxDecoration(
        color: VoidTheme.deepSpaceVoid,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: accentColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 12.0, color: accentColor),
              const SizedBox(width: 4.0),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: VoidTheme.textMuted,
                    fontSize: 9.0,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4.0),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: accentColor,
              fontSize: 12.0,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // --- Card 3: Mission Outcomes & Win Rate Summary ---
  Widget _buildMissionOutcomesCard(UserProfile profile) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: VoidTheme.cardSurface,
        borderRadius: BorderRadius.circular(14.0),
        border: Border.all(color: VoidTheme.textMuted.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'MISSION OUTCOMES & WIN RATE',
            style: TextStyle(
              color: VoidTheme.solarGold,
              fontSize: 12.0,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 14.0),
          Row(
            children: [
              // Circular win rate gauge
              Container(
                width: 76.0,
                height: 76.0,
                padding: const EdgeInsets.all(4.0),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 68.0,
                      height: 68.0,
                      child: CircularProgressIndicator(
                        value: (profile.winRate / 100.0).clamp(0.0, 1.0),
                        strokeWidth: 7.0,
                        backgroundColor: VoidTheme.obsidianBlack,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          VoidTheme.plasmaCyan,
                        ),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${profile.winRate.toStringAsFixed(0)}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text(
                          'WIN RATE',
                          style: TextStyle(
                            color: VoidTheme.textMuted,
                            fontSize: 7.5,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14.0),
              // 4 Tactical Pills
              Expanded(
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildOutcomePill(
                            label: 'SORTIES',
                            value: '${profile.missionsPlayed}',
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8.0),
                        Expanded(
                          child: _buildOutcomePill(
                            label: 'VICTORIES',
                            value: '${profile.victories}',
                            color: VoidTheme.plasmaCyan,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8.0),
                    Row(
                      children: [
                        Expanded(
                          child: _buildOutcomePill(
                            label: 'DEFEATS',
                            value: '${profile.defeats}',
                            color: VoidTheme.crimsonFlare,
                          ),
                        ),
                        const SizedBox(width: 8.0),
                        Expanded(
                          child: _buildOutcomePill(
                            label: 'FLAWLESS',
                            value: '${profile.flawlessVictories}',
                            color: VoidTheme.solarGold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOutcomePill({
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
      decoration: BoxDecoration(
        color: VoidTheme.deepSpaceVoid,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: VoidTheme.textMuted,
              fontSize: 10.0,
              letterSpacing: 0.5,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 13.0,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // --- Card 4: Tactical Weaponry & Combat Telemetry Grid ---
  Widget _buildTacticalGridCard(UserProfile profile) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: VoidTheme.cardSurface,
        borderRadius: BorderRadius.circular(14.0),
        border: Border.all(color: VoidTheme.textMuted.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'TACTICAL SENSOR LOG & COMBAT METRICS',
            style: TextStyle(
              color: VoidTheme.plasmaCyan,
              fontSize: 12.0,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 12.0),
          Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildMetricTile(
                      label: 'HIGHEST COMBAT SCORE',
                      value: '${_persistence.highScore}',
                      icon: Icons.military_tech,
                      color: VoidTheme.solarGold,
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  Expanded(
                    child: _buildMetricTile(
                      label: 'AVERAGE SCORE',
                      value: '${profile.averageScore}',
                      icon: Icons.analytics_outlined,
                      color: VoidTheme.plasmaCyan,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8.0),
              Row(
                children: [
                  Expanded(
                    child: _buildMetricTile(
                      label: 'ENEMIES DESTROYED',
                      value: '${profile.enemiesDestroyed}',
                      icon: Icons.track_changes,
                      color: VoidTheme.plasmaCyan,
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  Expanded(
                    child: _buildMetricTile(
                      label: 'LANCES DISCHARGED',
                      value: '${profile.lancesFired}',
                      icon: Icons.bolt,
                      color: VoidTheme.solarGold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8.0),
              Row(
                children: [
                  Expanded(
                    child: _buildMetricTile(
                      label: 'FLAK DETONATIONS',
                      value: '${profile.flakBurstsTriggered}',
                      icon: Icons.shield,
                      color: VoidTheme.plasmaCyan,
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  Expanded(
                    child: _buildMetricTile(
                      label: 'PLASMA CORES SOWN',
                      value: '${profile.totalSeedsSown}',
                      icon: Icons.grain,
                      color: VoidTheme.solarGold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8.0),
              Row(
                children: [
                  Expanded(
                    child: _buildMetricTile(
                      label: 'CORES PRESERVED',
                      value: '${profile.totalCoresSaved}',
                      icon: Icons.battery_charging_full,
                      color: VoidTheme.emeraldShield,
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  Expanded(
                    child: _buildMetricTile(
                      label: 'MAX CASCADE COMBO',
                      value: '${profile.maxCascadeLaps} LAPS',
                      icon: Icons.all_inclusive,
                      color: VoidTheme.solarGold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: VoidTheme.deepSpaceVoid,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20.0),
          const SizedBox(width: 8.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: VoidTheme.textMuted,
                    fontSize: 9.0,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2.0),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: color,
                    fontSize: 14.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Card 5: Multi-Theater Campaign Mastery Card ---
  Widget _buildCampaignMasteryCard() {
    final totalLib = _campaignService.getTotalLiberatedSectors();
    final totalStars = _campaignService.getTotalStarsEarned();

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: VoidTheme.cardSurface,
        borderRadius: BorderRadius.circular(14.0),
        border: Border.all(color: VoidTheme.textMuted.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8.0,
            runSpacing: 4.0,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Text(
                'CAMPAIGN THEATER MASTERY',
                style: TextStyle(
                  color: VoidTheme.solarGold,
                  fontSize: 12.0,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
              Text(
                '$totalLib / 27 SECTORS • $totalStars / 81 ★',
                style: const TextStyle(
                  color: VoidTheme.solarGold,
                  fontSize: 11.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12.0),
          _buildTheaterTile(
            campaignId: 'kilwa_basin',
            title: 'KILWA BASIN',
            doctrine: 'STANDARD ORBITAL',
            color: VoidTheme.plasmaCyan,
          ),
          const SizedBox(height: 8.0),
          _buildTheaterTile(
            campaignId: 'phantom_drift',
            title: 'PHANTOM DRIFT',
            doctrine: 'LATERAL EVASIVE',
            color: VoidTheme.nebulaAmethyst,
          ),
          const SizedBox(height: 8.0),
          _buildTheaterTile(
            campaignId: 'void_swarm',
            title: 'VOID SWARM',
            doctrine: 'HORDE & CORE SIPHON',
            color: VoidTheme.solarGold,
          ),
        ],
      ),
    );
  }

  Widget _buildTheaterTile({
    required String campaignId,
    required String title,
    required String doctrine,
    required Color color,
  }) {
    final liberated = _campaignService.getLiberatedCountForCampaign(campaignId);
    final stars = _campaignService.getStarsEarnedForCampaign(campaignId);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
      decoration: BoxDecoration(
        color: VoidTheme.deepSpaceVoid,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            width: 8.0,
            height: 32.0,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4.0),
            ),
          ),
          const SizedBox(width: 10.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12.0,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 2.0),
                Text(
                  doctrine,
                  style: TextStyle(
                    color: color.withValues(alpha: 0.8),
                    fontSize: 9.5,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$liberated / 9 LIBERATED',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2.0),
              Text(
                '$stars / 27 ★',
                style: const TextStyle(
                  color: VoidTheme.solarGold,
                  fontSize: 10.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- Card 6: Fleet Chassis Deployment Card ---
  Widget _buildChassisDeploymentCard(UserProfile profile) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: VoidTheme.cardSurface,
        borderRadius: BorderRadius.circular(14.0),
        border: Border.all(color: VoidTheme.textMuted.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8.0,
            runSpacing: 4.0,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Text(
                'FLEET CHASSIS DEPLOYMENT',
                style: TextStyle(
                  color: VoidTheme.plasmaCyan,
                  fontSize: 12.0,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
              Text(
                'FAVORITE: ${profile.favoriteChassisName.split(' ')[0]}',
                style: const TextStyle(
                  color: VoidTheme.solarGold,
                  fontSize: 10.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12.0),
          _buildChassisSortieRow(
            chassisName: 'MK-I Bastion Standard',
            chassisId: 'mk1_bastion',
            sorties: profile.chassisSorties['mk1_bastion'] ?? 0,
            totalSorties: profile.missionsPlayed,
            color: VoidTheme.plasmaCyan,
          ),
          const SizedBox(height: 8.0),
          _buildChassisSortieRow(
            chassisName: 'MK-II Monsoon Vanguard',
            chassisId: 'mk2_monsoon',
            sorties: profile.chassisSorties['mk2_monsoon'] ?? 0,
            totalSorties: profile.missionsPlayed,
            color: VoidTheme.solarGold,
          ),
          const SizedBox(height: 8.0),
          _buildChassisSortieRow(
            chassisName: 'MK-III Singularity Sovereign',
            chassisId: 'mk3_singularity',
            sorties: profile.chassisSorties['mk3_singularity'] ?? 0,
            totalSorties: profile.missionsPlayed,
            color: VoidTheme.nebulaAmethyst,
          ),
          const SizedBox(height: 8.0),
          _buildChassisSortieRow(
            chassisName: 'MK-IV Golden Sovereign',
            chassisId: 'mk4_golden_sovereign',
            sorties: profile.chassisSorties['mk4_golden_sovereign'] ?? 0,
            totalSorties: profile.missionsPlayed,
            color: VoidTheme.solarGoldLight,
          ),
        ],
      ),
    );
  }

  Widget _buildChassisSortieRow({
    required String chassisName,
    required String chassisId,
    required int sorties,
    required int totalSorties,
    required Color color,
  }) {
    final fraction = totalSorties > 0 ? (sorties / totalSorties) : 0.0;
    final isEquipped = _persistence.selectedChassisId == chassisId;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: VoidTheme.deepSpaceVoid,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(
          color: isEquipped ? color : color.withValues(alpha: 0.15),
          width: isEquipped ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.rocket_launch, size: 14.0, color: color),
              const SizedBox(width: 6.0),
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        chassisName,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isEquipped ? color : Colors.white,
                          fontSize: 11.5,
                          fontWeight: isEquipped
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                    if (isEquipped) ...[
                      const SizedBox(width: 6.0),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5.0,
                          vertical: 1.0,
                        ),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4.0),
                        ),
                        child: const Text(
                          'ACTIVE',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 8.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8.0),
              Text(
                '$sorties Sorties',
                style: TextStyle(
                  color: color,
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6.0),
          ClipRRect(
            borderRadius: BorderRadius.circular(2.0),
            child: LinearProgressIndicator(
              value: fraction.clamp(0.0, 1.0),
              minHeight: 4.0,
              backgroundColor: VoidTheme.obsidianBlack,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }

  // --- Card 7: Data Management & GDPR Card ---
  Widget _buildDataManagementCard() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TactileButton(
                label: 'EXPORT SAVE',
                icon: Icons.download,
                accentColor: VoidTheme.plasmaCyan,
                height: 42.0,
                onPressed: _exportSave,
              ),
            ),
            const SizedBox(width: 10.0),
            Expanded(
              child: TactileButton(
                label: 'IMPORT SAVE',
                icon: Icons.upload,
                accentColor: VoidTheme.solarGold,
                height: 42.0,
                onPressed: _importSave,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12.0),
        OutlinedButton.icon(
          icon: const Icon(
            Icons.delete_outline,
            color: VoidTheme.crimsonFlare,
            size: 18.0,
          ),
          label: const Text(
            'ERASE GUEST DATA (GDPR)',
            style: TextStyle(
              color: VoidTheme.crimsonFlare,
              fontSize: 12.0,
              letterSpacing: 0.8,
            ),
          ),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: VoidTheme.crimsonFlare),
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 12.0,
            ),
          ),
          onPressed: _confirmEraseData,
        ),
      ],
    );
  }
}
