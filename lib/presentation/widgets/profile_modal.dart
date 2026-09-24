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
import '../../domain/services/auth_service.dart';
import '../../domain/services/persistence_service.dart';
import '../screens/stats_dashboard_screen.dart';
import '../services/haptic_service.dart';
import '../theme/void_theme.dart';
import 'tactile_button.dart';

/// Modal dialog presenting pilot identity, insignia selector, Google Play auth, multi-profile roster, and save mobility.
class ProfileModal extends StatefulWidget {
  const ProfileModal({super.key, this.onProfileUpdated});

  final VoidCallback? onProfileUpdated;

  @override
  State<ProfileModal> createState() => _ProfileModalState();
}

class _ProfileModalState extends State<ProfileModal> {
  late UserProfile _profile;
  late TextEditingController _callsignController;
  final TextEditingController _newProfileController = TextEditingController();
  bool _isEditingCallsign = false;
  bool _isCreatingNewProfile = false;
  bool _isAuthLoading = false;
  String? _callsignError;
  String? _newProfileError;
  String? _authError;

  @override
  void initState() {
    super.initState();
    _profile = PersistenceService.instance.userProfile;
    _callsignController = TextEditingController(text: _profile.callsign);
  }

  @override
  void dispose() {
    _callsignController.dispose();
    _newProfileController.dispose();
    super.dispose();
  }

  Future<void> _saveCallsign() async {
    final text = _callsignController.text.trim();
    if (text.isEmpty || text.length > 16) {
      setState(() => _callsignError = '1-16 alphanumeric/hyphen chars');
      return;
    }
    final regex = RegExp(r'^[a-zA-Z0-9\-]+$');
    if (!regex.hasMatch(text)) {
      setState(() => _callsignError = 'Alphanumeric and - only');
      return;
    }

    HapticService.instance.sowTick();
    final updated = _profile.copyWith(callsign: text);
    setState(() {
      _profile = updated;
      _isEditingCallsign = false;
      _callsignError = null;
    });
    await PersistenceService.instance.saveUserProfile(updated);
    widget.onProfileUpdated?.call();
  }

  Future<void> _selectInsignia(PilotInsignia insignia) async {
    HapticService.instance.injectionClick();
    final updated = _profile.copyWith(insignia: insignia);
    setState(() => _profile = updated);
    await PersistenceService.instance.saveUserProfile(updated);
    widget.onProfileUpdated?.call();
  }

  Future<void> _linkGoogleAccount() async {
    setState(() {
      _isAuthLoading = true;
      _authError = null;
    });
    HapticService.instance.sowTick();

    final success = await AuthService.instance.linkWithGoogle();
    if (!mounted) return;

    if (!success) {
      final err = AuthService.instance.lastError;
      setState(() {
        _isAuthLoading = false;
        _authError = err;
      });
    } else {
      final updated = PersistenceService.instance.userProfile;
      setState(() {
        _profile = updated;
        _callsignController.text = updated.callsign;
        _isAuthLoading = false;
        _authError = null;
      });
      widget.onProfileUpdated?.call();
    }
  }

  Future<void> _linkSimulatedGoogleAccount() async {
    setState(() {
      _isAuthLoading = true;
      _authError = null;
    });
    HapticService.instance.sowTick();

    await AuthService.instance.linkWithSimulatedGoogleAccount();
    if (!mounted) return;

    final updated = PersistenceService.instance.userProfile;
    setState(() {
      _profile = updated;
      _callsignController.text = updated.callsign;
      _isAuthLoading = false;
      _authError = null;
    });
    widget.onProfileUpdated?.call();
  }

  Future<void> _unlinkGoogleAccount() async {
    HapticService.instance.sowTick();
    await AuthService.instance.signOut();
    if (!mounted) return;

    final updated = PersistenceService.instance.userProfile;
    setState(() {
      _profile = updated;
      _authError = null;
    });
    widget.onProfileUpdated?.call();
  }

  Future<void> _submitNewProfile() async {
    final text = _newProfileController.text.trim();
    if (text.isEmpty || text.length > 16) {
      setState(() => _newProfileError = '1-16 chars required');
      return;
    }
    final regex = RegExp(r'^[a-zA-Z0-9\-]+$');
    if (!regex.hasMatch(text)) {
      setState(() => _newProfileError = 'Alphanumeric and - only');
      return;
    }

    final success = await PersistenceService.instance.createProfile(text);
    if (!mounted) return;

    if (success) {
      HapticService.instance.injectionClick();
      final updated = PersistenceService.instance.userProfile;
      setState(() {
        _profile = updated;
        _callsignController.text = updated.callsign;
        _isCreatingNewProfile = false;
        _newProfileError = null;
        _newProfileController.clear();
      });
      widget.onProfileUpdated?.call();
    } else {
      setState(() => _newProfileError = 'Callsign already registered');
    }
  }

  Future<void> _switchProfile(String profileId) async {
    HapticService.instance.sowTick();
    await PersistenceService.instance.switchProfile(profileId);
    if (!mounted) return;

    final updated = PersistenceService.instance.userProfile;
    setState(() {
      _profile = updated;
      _callsignController.text = updated.callsign;
      _isCreatingNewProfile = false;
      _newProfileError = null;
    });
    widget.onProfileUpdated?.call();
  }

  Future<void> _deleteProfile(String profileId) async {
    HapticService.instance.sowTick();
    final success = await PersistenceService.instance.deleteProfile(profileId);
    if (!mounted) return;

    if (success) {
      final updated = PersistenceService.instance.userProfile;
      setState(() {
        _profile = updated;
        _callsignController.text = updated.callsign;
      });
      widget.onProfileUpdated?.call();
    }
  }

  void _exportSave() {
    HapticService.instance.sowTick();
    final base64Save = PersistenceService.instance.exportSaveJson();

    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: VoidTheme.obsidianBlack,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
            side: const BorderSide(color: VoidTheme.plasmaCyan, width: 1.5),
          ),
          title: const Text(
            'EXPORT SAVE TELEMETRY',
            style: TextStyle(
              color: VoidTheme.solarGold,
              fontSize: 14.0,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Copy this encoded telemetry payload to backup or transfer your progress to another device:',
                style: TextStyle(color: VoidTheme.starWhite, fontSize: 11.5),
              ),
              const SizedBox(height: 12.0),
              Container(
                padding: const EdgeInsets.all(10.0),
                decoration: BoxDecoration(
                  color: VoidTheme.cardSurface,
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: SelectableText(
                  base64Save,
                  style: const TextStyle(
                    color: VoidTheme.plasmaCyan,
                    fontSize: 10.0,
                    fontFamily: 'monospace',
                  ),
                  maxLines: 4,
                ),
              ),
            ],
          ),
          actions: [
            TactileButton(
              label: 'COPY TO CLIPBOARD',
              icon: Icons.copy,
              accentColor: VoidTheme.plasmaCyan,
              height: 38.0,
              onPressed: () {
                Clipboard.setData(ClipboardData(text: base64Save));
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Save telemetry copied to clipboard.'),
                    backgroundColor: VoidTheme.cardSurface,
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  void _importSave() {
    HapticService.instance.sowTick();
    final importController = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: VoidTheme.obsidianBlack,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
            side: const BorderSide(color: VoidTheme.solarGold, width: 1.5),
          ),
          title: const Text(
            'IMPORT SAVE TELEMETRY',
            style: TextStyle(
              color: VoidTheme.solarGold,
              fontSize: 14.0,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Paste your base64 save telemetry string below. This will overwrite local sector progress and settings.',
                style: TextStyle(color: VoidTheme.starWhite, fontSize: 11.5),
              ),
              const SizedBox(height: 12.0),
              TextField(
                controller: importController,
                maxLines: 4,
                style: const TextStyle(
                  color: VoidTheme.plasmaCyan,
                  fontSize: 11.0,
                  fontFamily: 'monospace',
                ),
                decoration: InputDecoration(
                  hintText: 'Paste void_sower_save_v1 payload...',
                  hintStyle: TextStyle(
                    color: VoidTheme.starWhite.withValues(alpha: 0.4),
                  ),
                  filled: true,
                  fillColor: VoidTheme.cardSurface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                    borderSide: const BorderSide(color: VoidTheme.cardSurface),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'CANCEL',
                style: TextStyle(color: VoidTheme.starWhite),
              ),
            ),
            TactileButton(
              label: 'RESTORE DATA',
              icon: Icons.upload,
              accentColor: VoidTheme.solarGold,
              height: 38.0,
              onPressed: () async {
                final success = await PersistenceService.instance
                    .importSaveJson(importController.text);
                if (context.mounted) {
                  Navigator.of(context).pop();
                  if (success) {
                    setState(() {
                      _profile = PersistenceService.instance.userProfile;
                      _callsignController.text = _profile.callsign;
                    });
                    widget.onProfileUpdated?.call();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Save telemetry successfully restored!'),
                        backgroundColor: VoidTheme.solarGold,
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Failed to restore: Invalid or corrupted payload.',
                        ),
                        backgroundColor: VoidTheme.crimsonFlare,
                      ),
                    );
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final rank = _profile.rank;
    final progress = _profile.rankProgress;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(
        horizontal: 14.0,
        vertical: 20.0,
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 720),
        decoration: VoidTheme.glassmorphic(
          borderColor: VoidTheme.plasmaCyan,
          borderWidth: 1.5,
          borderRadius: 18.0,
        ),
        child: Material(
          type: MaterialType.transparency,
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(18.0, 16.0, 12.0, 10.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.account_circle,
                          color: VoidTheme.plasmaCyan,
                          size: 22.0,
                        ),
                        SizedBox(width: 8.0),
                        Text(
                          'PILOT FLIGHT DOSSIER',
                          style: TextStyle(
                            color: VoidTheme.solarGold,
                            fontSize: 15.0,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2.0,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: VoidTheme.starWhite,
                        size: 22.0,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              const Divider(color: VoidTheme.cardSurface, height: 1.0),

              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 48.0),
                  children: [
                    // Active Pilot Holographic ID Card
                    Container(
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            VoidTheme.cardSurface,
                            VoidTheme.obsidianBlack.withValues(alpha: 0.8),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12.0),
                        border: Border.all(
                          color: VoidTheme.solarGold.withValues(alpha: 0.6),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12.0),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: VoidTheme.obsidianBlack,
                                  border: Border.all(
                                    color: VoidTheme.solarGold,
                                    width: 2.0,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.person,
                                  color: VoidTheme.solarGold,
                                  size: 28.0,
                                ),
                              ),
                              const SizedBox(width: 14.0),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (!_isEditingCallsign)
                                      Row(
                                        children: [
                                          Flexible(
                                            child: Text(
                                              _profile.callsign,
                                              style: const TextStyle(
                                                color: VoidTheme.starWhite,
                                                fontSize: 16.0,
                                                fontWeight: FontWeight.w900,
                                                letterSpacing: 1.2,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          if (PersistenceService
                                              .instance
                                              .isProUnlocked) ...[
                                            const SizedBox(width: 8.0),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 6.0,
                                                    vertical: 2.0,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: VoidTheme.solarGold
                                                    .withValues(alpha: 0.22),
                                                borderRadius:
                                                    BorderRadius.circular(4.0),
                                                border: Border.all(
                                                  color: VoidTheme.solarGold
                                                      .withValues(alpha: 0.85),
                                                  width: 1.0,
                                                ),
                                              ),
                                              child: const Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    Icons.workspace_premium,
                                                    color: VoidTheme.solarGold,
                                                    size: 11.0,
                                                  ),
                                                  SizedBox(width: 3.0),
                                                  Text(
                                                    'PRO',
                                                    style: TextStyle(
                                                      color:
                                                          VoidTheme.solarGold,
                                                      fontSize: 8.5,
                                                      fontWeight:
                                                          FontWeight.w900,
                                                      letterSpacing: 0.8,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                          IconButton(
                                            icon: const Icon(
                                              Icons.edit,
                                              color: VoidTheme.plasmaCyan,
                                              size: 16.0,
                                            ),
                                            onPressed: () => setState(
                                              () => _isEditingCallsign = true,
                                            ),
                                          ),
                                        ],
                                      )
                                    else
                                      Row(
                                        children: [
                                          Expanded(
                                            child: TextField(
                                              controller: _callsignController,
                                              style: const TextStyle(
                                                color: VoidTheme.solarGold,
                                                fontSize: 14.0,
                                                fontFamily: 'monospace',
                                              ),
                                              decoration: InputDecoration(
                                                isDense: true,
                                                errorText: _callsignError,
                                                contentPadding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 8.0,
                                                      vertical: 8.0,
                                                    ),
                                              ),
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.check,
                                              color: VoidTheme.solarGold,
                                              size: 18.0,
                                            ),
                                            onPressed: _saveCallsign,
                                          ),
                                        ],
                                      ),
                                    Wrap(
                                      spacing: 8.0,
                                      runSpacing: 4.0,
                                      crossAxisAlignment:
                                          WrapCrossAlignment.center,
                                      children: [
                                        Text(
                                          'RANK: ${rank.title.toUpperCase()}',
                                          style: const TextStyle(
                                            color: VoidTheme.plasmaCyan,
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 1.0,
                                          ),
                                        ),
                                        const SizedBox(width: 8.0),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 5.0,
                                            vertical: 1.5,
                                          ),
                                          decoration: BoxDecoration(
                                            color: _profile.isGoogleLinked
                                                ? VoidTheme.plasmaCyan
                                                      .withValues(alpha: 0.2)
                                                : VoidTheme.emeraldShield
                                                      .withValues(alpha: 0.2),
                                            borderRadius: BorderRadius.circular(
                                              4.0,
                                            ),
                                            border: Border.all(
                                              color: _profile.isGoogleLinked
                                                  ? VoidTheme.plasmaCyan
                                                  : VoidTheme.emeraldShield,
                                              width: 0.8,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                _profile.isGoogleLinked
                                                    ? Icons.g_mobiledata
                                                    : Icons.account_circle,
                                                color: _profile.isGoogleLinked
                                                    ? VoidTheme.plasmaCyan
                                                    : VoidTheme.emeraldShield,
                                                size: 12.0,
                                              ),
                                              const SizedBox(width: 2.0),
                                              Text(
                                                _profile.isGoogleLinked
                                                    ? 'GOOGLE'
                                                    : 'LOCAL GUEST',
                                                style: TextStyle(
                                                  color: _profile.isGoogleLinked
                                                      ? VoidTheme.plasmaCyan
                                                      : VoidTheme.emeraldShield,
                                                  fontSize: 9.0,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14.0),

                          // Rank Progression Bar
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'PROGRESS TO ${rank == PilotRank.voidAscendant ? "ASCENDANCE" : "NEXT RANK"}',
                                style: TextStyle(
                                  color: VoidTheme.starWhite.withValues(
                                    alpha: 0.7,
                                  ),
                                  fontSize: 10.0,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '${(progress * 100).round()}%',
                                style: const TextStyle(
                                  color: VoidTheme.solarGold,
                                  fontSize: 10.5,
                                  fontFamily: 'monospace',
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6.0),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4.0),
                            child: LinearProgressIndicator(
                              value: progress,
                              minHeight: 6.0,
                              backgroundColor: VoidTheme.obsidianBlack,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                VoidTheme.solarGold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16.0),

                    // Cloud Account & Google Sign-In Card
                    _buildCloudAccountCard(),

                    const SizedBox(height: 16.0),

                    // Squadron Roster (Multi-Profile Management)
                    _buildSquadronRoster(),

                    const SizedBox(height: 16.0),

                    // Insignia Selector Grid
                    const Text(
                      'SQUADRON CULTURAL INSIGNIA',
                      style: TextStyle(
                        color: VoidTheme.plasmaCyan,
                        fontSize: 12.0,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 8.0,
                            mainAxisSpacing: 8.0,
                            childAspectRatio: 1.6,
                          ),
                      itemCount: PilotInsignia.values.length,
                      itemBuilder: (context, index) {
                        final ins = PilotInsignia.values[index];
                        final isSelected = ins == _profile.insignia;

                        return GestureDetector(
                          onTap: () => _selectInsignia(ins),
                          child: Container(
                            padding: const EdgeInsets.all(6.0),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? VoidTheme.plasmaCyan.withValues(alpha: 0.2)
                                  : VoidTheme.cardSurface,
                              borderRadius: BorderRadius.circular(8.0),
                              border: Border.all(
                                color: isSelected
                                    ? VoidTheme.plasmaCyan
                                    : VoidTheme.cardSurface,
                                width: 1.5,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  ins.iconData,
                                  color: isSelected
                                      ? VoidTheme.plasmaCyan
                                      : VoidTheme.starWhite,
                                  size: 20.0,
                                ),
                                const SizedBox(height: 4.0),
                                Text(
                                  ins.displayName,
                                  style: TextStyle(
                                    color: isSelected
                                        ? VoidTheme.plasmaCyan
                                        : VoidTheme.starWhite,
                                    fontSize: 9.0,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 16.0),

                    // Lifetime Combat Readout
                    const Text(
                      'LIFETIME COMBAT TELEMETRY',
                      style: TextStyle(
                        color: VoidTheme.solarGold,
                        fontSize: 12.0,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    Container(
                      padding: const EdgeInsets.all(12.0),
                      decoration: BoxDecoration(
                        color: VoidTheme.cardSurface,
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: Column(
                        children: [
                          _metricRow(
                            'Lifetime Score',
                            '${_profile.lifetimeScore}',
                          ),
                          const Divider(
                            color: VoidTheme.obsidianBlack,
                            height: 12.0,
                          ),
                          _metricRow(
                            'Sorties / Win Rate',
                            '${_profile.missionsPlayed} (${_profile.winRate.toStringAsFixed(0)}%)',
                          ),
                          const Divider(
                            color: VoidTheme.obsidianBlack,
                            height: 12.0,
                          ),
                          _metricRow(
                            'Flawless Defenses',
                            '${_profile.flawlessVictories}',
                          ),
                          const Divider(
                            color: VoidTheme.obsidianBlack,
                            height: 12.0,
                          ),
                          _metricRow(
                            'Enemies Neutralized',
                            '${_profile.enemiesDestroyed}',
                          ),
                          const Divider(
                            color: VoidTheme.obsidianBlack,
                            height: 12.0,
                          ),
                          _metricRow('Lances Fired', '${_profile.lancesFired}'),
                          const Divider(
                            color: VoidTheme.obsidianBlack,
                            height: 12.0,
                          ),
                          _metricRow(
                            'Surplus Cores Saved',
                            '${_profile.totalCoresSaved}',
                          ),
                          const Divider(
                            color: VoidTheme.obsidianBlack,
                            height: 12.0,
                          ),
                          _metricRow(
                            'Max Cascade Laps',
                            '${_profile.maxCascadeLaps}',
                          ),
                          const Divider(
                            color: VoidTheme.obsidianBlack,
                            height: 12.0,
                          ),
                          _metricRow(
                            'Flight Time',
                            _profile.formattedFlightTime,
                          ),
                          const Divider(
                            color: VoidTheme.obsidianBlack,
                            height: 12.0,
                          ),
                          _metricRow(
                            'Deployment Streak',
                            '${_profile.currentStreak} Days (Record: ${_profile.longestStreak})',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    TactileButton(
                      label: 'VIEW FULL FLEET TELEMETRY',
                      icon: Icons.analytics_outlined,
                      accentColor: VoidTheme.solarGold,
                      height: 38.0,
                      fontSize: 11.0,
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (context) => const StatsDashboardScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16.0),

                    // Save Mobility (Export / Import)
                    Row(
                      children: [
                        Expanded(
                          child: TactileButton(
                            label: 'EXPORT SAVE',
                            icon: Icons.download,
                            accentColor: VoidTheme.plasmaCyan,
                            height: 40.0,
                            onPressed: _exportSave,
                          ),
                        ),
                        const SizedBox(width: 10.0),
                        Expanded(
                          child: TactileButton(
                            label: 'IMPORT SAVE',
                            icon: Icons.upload,
                            accentColor: VoidTheme.solarGold,
                            height: 40.0,
                            onPressed: _importSave,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCloudAccountCard() {
    final isLinked = _profile.isGoogleLinked;

    return Container(
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        color: VoidTheme.cardSurface,
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(
          color: isLinked
              ? VoidTheme.plasmaCyan.withValues(alpha: 0.6)
              : VoidTheme.cardSurface,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isLinked ? Icons.g_mobiledata : Icons.cloud_queue,
                color: isLinked ? VoidTheme.solarGold : VoidTheme.plasmaCyan,
                size: 22.0,
              ),
              const SizedBox(width: 8.0),
              Expanded(
                child: Text(
                  isLinked
                      ? 'GOOGLE PLAY CLOUD IDENTITY'
                      : 'PILOT CLOUD ACCOUNT',
                  style: const TextStyle(
                    color: VoidTheme.starWhite,
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              if (isLinked)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6.0,
                    vertical: 2.0,
                  ),
                  decoration: BoxDecoration(
                    color: VoidTheme.plasmaCyan.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4.0),
                    border: Border.all(color: VoidTheme.plasmaCyan),
                  ),
                  child: const Text(
                    'SYNCED',
                    style: TextStyle(
                      color: VoidTheme.plasmaCyan,
                      fontSize: 9.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6.0),
          Text(
            isLinked
                ? 'Linked with ${_profile.googleEmail ?? _profile.callsign}. Combat scores and sector achievements are backed up.'
                : 'Link your pilot profile with Google Play to enable cloud backup, verified leaderboards, and seamless device mobility.',
            style: TextStyle(
              color: VoidTheme.starWhite.withValues(alpha: 0.7),
              fontSize: 11.0,
            ),
          ),
          if (_authError != null) ...[
            const SizedBox(height: 6.0),
            Text(
              _authError!,
              style: const TextStyle(
                color: VoidTheme.crimsonFlare,
                fontSize: 10.5,
              ),
            ),
          ],
          const SizedBox(height: 10.0),
          if (!isLinked) ...[
            if (_isAuthLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: CircularProgressIndicator(
                    strokeWidth: 2.0,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      VoidTheme.plasmaCyan,
                    ),
                  ),
                ),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: TactileButton(
                      label: 'SIGN IN WITH GOOGLE',
                      icon: Icons.login,
                      accentColor: VoidTheme.plasmaCyan,
                      height: 38.0,
                      onPressed: _linkGoogleAccount,
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  IconButton(
                    onPressed: _linkSimulatedGoogleAccount,
                    tooltip: 'Simulate Google Account (Dev/Offline)',
                    icon: const Icon(
                      Icons.science_outlined,
                      color: VoidTheme.solarGold,
                      size: 20.0,
                    ),
                  ),
                ],
              ),
          ] else ...[
            TactileButton(
              label: 'DISCONNECT CLOUD IDENTITY',
              icon: Icons.logout,
              accentColor: VoidTheme.crimsonFlare,
              height: 36.0,
              onPressed: _unlinkGoogleAccount,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSquadronRoster() {
    final allProfiles = PersistenceService.instance.profiles;

    return Container(
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        color: VoidTheme.cardSurface,
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'SQUADRON ROSTER (PROFILES)',
                  style: TextStyle(
                    color: VoidTheme.plasmaCyan,
                    fontSize: 12.0,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _isCreatingNewProfile = !_isCreatingNewProfile;
                    _newProfileError = null;
                  });
                },
                icon: Icon(
                  _isCreatingNewProfile ? Icons.list : Icons.person_add_alt_1,
                  size: 15.0,
                  color: VoidTheme.solarGold,
                ),
                label: Text(
                  _isCreatingNewProfile ? 'ROSTER' : '+ NEW PILOT',
                  style: const TextStyle(
                    color: VoidTheme.solarGold,
                    fontSize: 11.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6.0),

          if (_isCreatingNewProfile) ...[
            Container(
              padding: const EdgeInsets.all(10.0),
              decoration: BoxDecoration(
                color: VoidTheme.obsidianBlack,
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(
                  color: VoidTheme.plasmaCyan.withValues(alpha: 0.5),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Register new pilot callsign:',
                    style: TextStyle(
                      color: VoidTheme.starWhite,
                      fontSize: 11.0,
                    ),
                  ),
                  const SizedBox(height: 6.0),
                  TextField(
                    controller: _newProfileController,
                    style: const TextStyle(
                      color: VoidTheme.solarGold,
                      fontSize: 13.0,
                      fontFamily: 'monospace',
                    ),
                    decoration: InputDecoration(
                      hintText: 'e.g. Sentinel-99',
                      hintStyle: TextStyle(
                        color: VoidTheme.starWhite.withValues(alpha: 0.4),
                      ),
                      isDense: true,
                      errorText: _newProfileError,
                      filled: true,
                      fillColor: VoidTheme.cardSurface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6.0),
                      ),
                    ),
                    onSubmitted: (_) => _submitNewProfile(),
                  ),
                  const SizedBox(height: 8.0),
                  TactileButton(
                    label: 'CREATE PILOT',
                    icon: Icons.check,
                    accentColor: VoidTheme.plasmaCyan,
                    height: 36.0,
                    onPressed: _submitNewProfile,
                  ),
                ],
              ),
            ),
          ] else ...[
            Column(
              children: allProfiles.map((p) {
                final isActive = p.id == _profile.id;

                return Container(
                  margin: const EdgeInsets.only(bottom: 6.0),
                  decoration: BoxDecoration(
                    color: isActive
                        ? VoidTheme.plasmaCyan.withValues(alpha: 0.15)
                        : VoidTheme.obsidianBlack.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(8.0),
                    border: Border.all(
                      color: isActive
                          ? VoidTheme.plasmaCyan
                          : Colors.transparent,
                      width: 1.2,
                    ),
                  ),
                  child: ListTile(
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 10.0,
                      vertical: 0.0,
                    ),
                    leading: CircleAvatar(
                      backgroundColor: VoidTheme.obsidianBlack,
                      radius: 14.0,
                      child: Icon(
                        p.insignia.iconData,
                        color: isActive
                            ? VoidTheme.solarGold
                            : VoidTheme.starWhite,
                        size: 16.0,
                      ),
                    ),
                    title: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.person,
                          size: 13.0,
                          color: isActive
                              ? VoidTheme.solarGold
                              : VoidTheme.textMuted,
                        ),
                        const SizedBox(width: 4.0),
                        Flexible(
                          child: Text(
                            p.callsign,
                            style: TextStyle(
                              color: isActive
                                  ? VoidTheme.solarGold
                                  : VoidTheme.starWhite,
                              fontSize: 12.5,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (PersistenceService.instance.isProUnlocked) ...[
                          const SizedBox(width: 6.0),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4.0,
                              vertical: 0.5,
                            ),
                            decoration: BoxDecoration(
                              color: VoidTheme.solarGold.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(3.0),
                              border: Border.all(
                                color: VoidTheme.solarGold.withValues(
                                  alpha: 0.8,
                                ),
                                width: 0.6,
                              ),
                            ),
                            child: const Text(
                              'PRO',
                              style: TextStyle(
                                color: VoidTheme.solarGold,
                                fontSize: 7.0,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    subtitle: Text(
                      '${p.rank.title} • Score: ${p.lifetimeScore}',
                      style: TextStyle(
                        color: VoidTheme.starWhite.withValues(alpha: 0.6),
                        fontSize: 10.0,
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isActive)
                          const Icon(
                            Icons.check_circle,
                            color: VoidTheme.plasmaCyan,
                            size: 18.0,
                          )
                        else
                          TextButton(
                            onPressed: () => _switchProfile(p.id),
                            child: const Text(
                              'SWITCH',
                              style: TextStyle(
                                color: VoidTheme.plasmaCyan,
                                fontSize: 11.0,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        if (allProfiles.length > 1 && !isActive)
                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              color: VoidTheme.crimsonFlare,
                              size: 16.0,
                            ),
                            onPressed: () => _deleteProfile(p.id),
                          ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _metricRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: VoidTheme.starWhite.withValues(alpha: 0.8),
              fontSize: 11.5,
            ),
          ),
        ),
        const SizedBox(width: 8.0),
        Text(
          value,
          style: const TextStyle(
            color: VoidTheme.starWhite,
            fontSize: 12.0,
            fontFamily: 'monospace',
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
