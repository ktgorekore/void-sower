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
import '../../domain/services/entitlement_service.dart';
import '../../domain/services/persistence_service.dart';
import '../services/haptic_service.dart';
import '../widgets/tactile_button.dart';

/// Comprehensive player profile and lifetime combat telemetry dashboard designed to UX 3.0 standards.
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
          builder: (ctx, setModalState) => Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 24.0,
            ),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 420.0),
              padding: const EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(18.0),
                border: Border.all(
                  color: const Color(0xFF00F0FF).withValues(alpha: 0.8),
                  width: 1.5,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x66000000),
                    blurRadius: 20.0,
                    offset: Offset(0, 6),
                  ),
                  BoxShadow(
                    color: Color(0x3300F0FF),
                    blurRadius: 16.0,
                    spreadRadius: -2,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 36.0,
                        height: 36.0,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0x2200F0FF),
                          border: Border.all(
                            color: const Color(0xFF00F0FF),
                            width: 1.5,
                          ),
                        ),
                        child: const Icon(
                          Icons.settings_backup_restore,
                          color: Color(0xFF00F0FF),
                          size: 20.0,
                        ),
                      ),
                      const SizedBox(width: 12.0),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'TELEMETRY INGESTION',
                              style: TextStyle(
                                color: Color(0xFF38BDF8),
                                fontSize: 9.0,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.2,
                              ),
                            ),
                            SizedBox(height: 2.0),
                            Text(
                              'RESTORE TELEMETRY SAVE',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14.0,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12.0),
                  // 4px neon track
                  Container(
                    height: 3.0,
                    decoration: BoxDecoration(
                      color: const Color(0xFF00F0FF),
                      borderRadius: BorderRadius.circular(1.5),
                      boxShadow: const [
                        BoxShadow(color: Color(0x8000F0FF), blurRadius: 6.0),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14.0),
                  const Text(
                    'Paste your base64 encoded save string with embedded checksum verification:',
                    style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12.0),
                  ),
                  const SizedBox(height: 10.0),
                  TextField(
                    controller: controller,
                    maxLines: 4,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11.5,
                      fontFamily: 'monospace',
                    ),
                    decoration: InputDecoration(
                      hintText: 'Paste export payload...',
                      hintStyle: const TextStyle(color: Color(0xFF475569)),
                      errorText: errorText,
                      filled: true,
                      fillColor: const Color(0xFF070C18),
                      contentPadding: const EdgeInsets.all(12.0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                        borderSide: const BorderSide(color: Color(0xFF1E293B)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                        borderSide: const BorderSide(color: Color(0xFF00F0FF)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18.0),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.of(dialogContext).pop(),
                          style: TextButton.styleFrom(
                            minimumSize: const Size(double.infinity, 42.0),
                            backgroundColor: const Color(
                              0xFF1E293B,
                            ).withValues(alpha: 0.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.0),
                              side: const BorderSide(
                                color: Color(0xFF334155),
                                width: 1.0,
                              ),
                            ),
                          ),
                          child: const Text(
                            'CANCEL',
                            style: TextStyle(
                              color: Color(0xFF94A3B8),
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10.0),
                      Expanded(
                        child: TactileButton(
                          label: 'RESTORE',
                          icon: Icons.cloud_download,
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
                          accentColor: const Color(0xFFF59E0B),
                          height: 42.0,
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
    } finally {
      controller.dispose();
    }
  }

  Future<void> _confirmEraseData() async {
    HapticService.instance.sowTick();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(
          horizontal: 16.0,
          vertical: 24.0,
        ),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 420.0),
          padding: const EdgeInsets.all(20.0),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(18.0),
            border: Border.all(color: const Color(0xFFEF4444), width: 1.5),
            boxShadow: const [
              BoxShadow(
                color: Color(0x66000000),
                blurRadius: 20.0,
                offset: Offset(0, 6),
              ),
              BoxShadow(
                color: Color(0x33EF4444),
                blurRadius: 16.0,
                spreadRadius: -2,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 36.0,
                    height: 36.0,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0x22EF4444),
                      border: Border.all(
                        color: const Color(0xFFEF4444),
                        width: 1.5,
                      ),
                    ),
                    child: const Icon(
                      Icons.warning_rounded,
                      color: Color(0xFFEF4444),
                      size: 20.0,
                    ),
                  ),
                  const SizedBox(width: 12.0),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'GDPR DATA PURGE',
                          style: TextStyle(
                            color: Color(0xFFEF4444),
                            fontSize: 9.0,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                          ),
                        ),
                        SizedBox(height: 2.0),
                        Text(
                          'ERASE GUEST TELEMETRY?',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14.0,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12.0),
              // 4px neon track
              Container(
                height: 3.0,
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444),
                  borderRadius: BorderRadius.circular(1.5),
                  boxShadow: const [
                    BoxShadow(color: Color(0x80EF4444), blurRadius: 6.0),
                  ],
                ),
              ),
              const SizedBox(height: 14.0),
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
                  'This will permanently reset all campaign stars, personal scores, streaks, and unlocked chassis. This action cannot be undone under GDPR privacy mandates.',
                  style: TextStyle(
                    color: Color(0xFFCBD5E1),
                    fontSize: 11.5,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 18.0),
              Row(
                children: [
                  Expanded(
                    child: TactileButton(
                      label: 'CANCEL',
                      onPressed: () => Navigator.of(dialogContext).pop(false),
                      accentColor: const Color(0xFF64748B),
                      height: 42.0,
                      isPrimary: false,
                    ),
                  ),
                  const SizedBox(width: 10.0),
                  Expanded(
                    child: TactileButton(
                      label: 'CONFIRM PURGE',
                      icon: Icons.delete_forever,
                      onPressed: () => Navigator.of(dialogContext).pop(true),
                      accentColor: const Color(0xFFEF4444),
                      height: 42.0,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
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
    final isPro =
        _persistence.isProUnlocked || EntitlementService.instance.hasActivePro;

    return PopScope(
      canPop: Navigator.of(context).canPop(),
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF05070F),
        body: SafeArea(
          child: Column(
            children: [
              // UX 3.0 Header Bar with tactile back button & glowing neon track
              _buildUx3Header(isPro),

              // Scrollable Telemetry Deck
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 12.0,
                  ),
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
                          const SizedBox(height: 18.0),
                          _buildDataManagementCard(),
                          const SizedBox(height: 28.0),
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
    );
  }

  /// UX 3.0 Cybernetic Header Bar with tactile back button and glowing 4px neon track.
  Widget _buildUx3Header(bool isPro) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16.0, 10.0, 16.0, 10.0),
      decoration: const BoxDecoration(
        color: Color(0xFF070C18),
        border: Border(
          bottom: BorderSide(color: Color(0xFF1E293B), width: 1.0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Tactile Back Button [ < ]
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  HapticService.instance.sowTick();
                  Navigator.of(context).pop();
                },
                child: Container(
                  width: 44.0,
                  height: 44.0,
                  alignment: Alignment.center,
                  margin: const EdgeInsets.only(right: 8.0),
                  child: Container(
                    width: 38.0,
                    height: 38.0,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(19.0),
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

              // Title and Eyebrow Block
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'VOID SOWER // TELEMETRY',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Color(0xFF38BDF8),
                        fontSize: 8.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                    SizedBox(height: 2.0),
                    Text(
                      'FLEET TELEMETRY',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17.0,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8.0),

              // Pro Status Pill
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10.0,
                  vertical: 4.5,
                ),
                decoration: BoxDecoration(
                  color: isPro
                      ? const Color(0xFF201503)
                      : const Color(0xFF03202A),
                  borderRadius: BorderRadius.circular(13.0),
                  border: Border.all(
                    color: isPro
                        ? const Color(0xFFF59E0B)
                        : const Color(0xFF00F0FF),
                    width: 1.0,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isPro ? Icons.workspace_premium : Icons.shield_outlined,
                      color: isPro
                          ? const Color(0xFFFBBF24)
                          : const Color(0xFF38BDF8),
                      size: 13.0,
                    ),
                    const SizedBox(width: 4.0),
                    Text(
                      isPro ? 'PRO COMMANDER' : 'STANDARD CADET',
                      style: TextStyle(
                        color: isPro
                            ? const Color(0xFFFEF3C7)
                            : const Color(0xFFBAE6FD),
                        fontSize: 8.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 8.0),

          // 4px Glowing Neon Track
          Stack(
            children: [
              Container(
                height: 4.0,
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(2.0),
                ),
              ),
              Container(
                height: 4.0,
                width: 140.0,
                decoration: BoxDecoration(
                  color: const Color(0xFF00F0FF),
                  borderRadius: BorderRadius.circular(2.0),
                  boxShadow: const [
                    BoxShadow(color: Color(0xFF00F0FF), blurRadius: 6.0),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- Card 1: Pilot Dossier & Rank Card ---
  Widget _buildPilotDossierCard(UserProfile profile, bool isPro) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(
          color: const Color(0xFF00F0FF).withValues(alpha: 0.35),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00F0FF).withValues(alpha: 0.08),
            blurRadius: 16.0,
          ),
        ],
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
                  color: const Color(0xFF080D1A),
                  border: Border.all(
                    color: const Color(0xFFF59E0B),
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  profile.insignia.iconData,
                  color: const Color(0xFFFBBF24),
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
                        color: Color(0xFF94A3B8),
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
                      ? const Color(0xFF201503)
                      : const Color(0xFF03202A),
                  borderRadius: BorderRadius.circular(20.0),
                  border: Border.all(
                    color: isPro
                        ? const Color(0xFFF59E0B)
                        : const Color(0xFF00F0FF),
                    width: 1.0,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isPro ? Icons.workspace_premium : Icons.shield_outlined,
                      color: isPro
                          ? const Color(0xFFFBBF24)
                          : const Color(0xFF38BDF8),
                      size: 13.0,
                    ),
                    const SizedBox(width: 4.0),
                    Text(
                      isPro ? 'PRO COMMANDER' : 'RECRUIT PILOT',
                      style: TextStyle(
                        color: isPro
                            ? const Color(0xFFFEF3C7)
                            : const Color(0xFFBAE6FD),
                        fontSize: 9.0,
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
                  color: Color(0xFFFBBF24),
                  fontSize: 12.0,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
              Text(
                '${(profile.rankProgress * 100).toInt()}% TO ADVANCE',
                style: const TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 11.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6.0),
          // 4px Glowing Gold Track
          ClipRRect(
            borderRadius: BorderRadius.circular(2.0),
            child: LinearProgressIndicator(
              value: profile.rankProgress,
              minHeight: 4.0,
              backgroundColor: const Color(0xFF1E293B),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFFFBBF24),
              ),
            ),
          ),
          const SizedBox(height: 6.0),
          Text(
            '${profile.lifetimeScore} / ${profile.rank.maxScore} PTS',
            style: const TextStyle(color: Color(0xFF64748B), fontSize: 10.0),
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
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: const Color(0xFF1E293B)),
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
                      color: Color(0xFF38BDF8),
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
                  accentColor: const Color(0xFFFBBF24),
                ),
              ),
              const SizedBox(width: 8.0),
              Expanded(
                child: _buildStreakStatPill(
                  label: 'FLIGHT TIME',
                  value: profile.formattedFlightTime,
                  icon: Icons.timer_outlined,
                  accentColor: const Color(0xFF00F0FF),
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
        color: const Color(0xFF070C18),
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(color: accentColor.withValues(alpha: 0.25)),
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
                    color: Color(0xFF64748B),
                    fontSize: 8.5,
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
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'MISSION OUTCOMES & WIN RATE',
            style: TextStyle(
              color: Color(0xFFFBBF24),
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
                        strokeWidth: 6.0,
                        backgroundColor: const Color(0xFF1E293B),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFF00F0FF),
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
                            color: Color(0xFF64748B),
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
                            color: const Color(0xFF00F0FF),
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
                            color: const Color(0xFFEF4444),
                          ),
                        ),
                        const SizedBox(width: 8.0),
                        Expanded(
                          child: _buildOutcomePill(
                            label: 'FLAWLESS',
                            value: '${profile.flawlessVictories}',
                            color: const Color(0xFFFBBF24),
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
        color: const Color(0xFF070C18),
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 9.5,
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
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'TACTICAL SENSOR LOG & COMBAT METRICS',
            style: TextStyle(
              color: Color(0xFF38BDF8),
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
                      color: const Color(0xFFFBBF24),
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  Expanded(
                    child: _buildMetricTile(
                      label: 'AVERAGE SCORE',
                      value: '${profile.averageScore}',
                      icon: Icons.analytics_outlined,
                      color: const Color(0xFF00F0FF),
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
                      color: const Color(0xFF00F0FF),
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  Expanded(
                    child: _buildMetricTile(
                      label: 'LANCES DISCHARGED',
                      value: '${profile.lancesFired}',
                      icon: Icons.bolt,
                      color: const Color(0xFFFBBF24),
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
                      color: const Color(0xFF00F0FF),
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  Expanded(
                    child: _buildMetricTile(
                      label: 'PLASMA CORES SOWN',
                      value: '${profile.totalSeedsSown}',
                      icon: Icons.grain,
                      color: const Color(0xFFFBBF24),
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
                      color: const Color(0xFF10B981),
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  Expanded(
                    child: _buildMetricTile(
                      label: 'MAX CASCADE COMBO',
                      value: '${profile.maxCascadeLaps} LAPS',
                      icon: Icons.all_inclusive,
                      color: const Color(0xFFFBBF24),
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
        color: const Color(0xFF070C18),
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(color: color.withValues(alpha: 0.25)),
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
                    color: Color(0xFF64748B),
                    fontSize: 8.5,
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
                    fontSize: 13.5,
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
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: const Color(0xFF1E293B)),
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
                  color: Color(0xFFFBBF24),
                  fontSize: 12.0,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
              Text(
                '$totalLib / 27 SECTORS • $totalStars / 81 ★',
                style: const TextStyle(
                  color: Color(0xFFFBBF24),
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
            color: const Color(0xFF00F0FF),
          ),
          const SizedBox(height: 8.0),
          _buildTheaterTile(
            campaignId: 'phantom_drift',
            title: 'PHANTOM DRIFT',
            doctrine: 'LATERAL EVASIVE',
            color: const Color(0xFFA855F7),
          ),
          const SizedBox(height: 8.0),
          _buildTheaterTile(
            campaignId: 'void_swarm',
            title: 'VOID SWARM',
            doctrine: 'HORDE & CORE SIPHON',
            color: const Color(0xFFFBBF24),
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
        color: const Color(0xFF070C18),
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            width: 6.0,
            height: 32.0,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(3.0),
              boxShadow: [
                BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 4.0),
              ],
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
                    color: color.withValues(alpha: 0.85),
                    fontSize: 9.0,
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
                style: TextStyle(
                  color: color,
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
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: const Color(0xFF1E293B)),
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
                  color: Color(0xFF38BDF8),
                  fontSize: 12.0,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
              Text(
                'FAVORITE: ${profile.favoriteChassisName.split(' ')[0]}',
                style: const TextStyle(
                  color: Color(0xFFFBBF24),
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
            color: const Color(0xFF00F0FF),
          ),
          const SizedBox(height: 8.0),
          _buildChassisSortieRow(
            chassisName: 'MK-II Monsoon Vanguard',
            chassisId: 'mk2_monsoon',
            sorties: profile.chassisSorties['mk2_monsoon'] ?? 0,
            totalSorties: profile.missionsPlayed,
            color: const Color(0xFFFBBF24),
          ),
          const SizedBox(height: 8.0),
          _buildChassisSortieRow(
            chassisName: 'MK-III Singularity Sovereign',
            chassisId: 'mk3_singularity',
            sorties: profile.chassisSorties['mk3_singularity'] ?? 0,
            totalSorties: profile.missionsPlayed,
            color: const Color(0xFFA855F7),
          ),
          const SizedBox(height: 8.0),
          _buildChassisSortieRow(
            chassisName: 'MK-IV Golden Sovereign',
            chassisId: 'mk4_golden_sovereign',
            sorties: profile.chassisSorties['mk4_golden_sovereign'] ?? 0,
            totalSorties: profile.missionsPlayed,
            color: const Color(0xFFFBBF24),
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
        color: const Color(0xFF070C18),
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(
          color: isEquipped ? color : color.withValues(alpha: 0.18),
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
              backgroundColor: const Color(0xFF1E293B),
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
                accentColor: const Color(0xFF00F0FF),
                height: 42.0,
                onPressed: _exportSave,
              ),
            ),
            const SizedBox(width: 10.0),
            Expanded(
              child: TactileButton(
                label: 'IMPORT SAVE',
                icon: Icons.upload,
                accentColor: const Color(0xFFFBBF24),
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
            color: Color(0xFFEF4444),
            size: 18.0,
          ),
          label: const Text(
            'ERASE GUEST DATA (GDPR)',
            style: TextStyle(
              color: Color(0xFFEF4444),
              fontSize: 12.0,
              letterSpacing: 0.8,
            ),
          ),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Color(0xFFEF4444)),
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 12.0,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
          ),
          onPressed: _confirmEraseData,
        ),
      ],
    );
  }
}
