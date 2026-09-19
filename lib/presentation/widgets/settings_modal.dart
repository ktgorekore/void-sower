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

import '../../domain/services/persistence_service.dart';
import '../services/audio_service.dart';
import '../services/haptic_service.dart';
import '../theme/void_theme.dart';
import 'consent_preferences_dialog.dart';
import 'legal_dialogs.dart';
import 'tactile_button.dart';

/// Centralized settings and preferences modal with Afrofuturistic styling.
class SettingsModal extends StatefulWidget {
  const SettingsModal({
    super.key,
    this.onResetTutorial,
    this.onDataWiped,
    this.onLaunchAcademy,
  });

  final VoidCallback? onResetTutorial;
  final VoidCallback? onDataWiped;
  final VoidCallback? onLaunchAcademy;

  @override
  State<SettingsModal> createState() => _SettingsModalState();
}

class _SettingsModalState extends State<SettingsModal>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Audio State
  late double _sfxVolume;
  late double _bgmVolume;
  late bool _isSfxMuted;
  late bool _isBgmMuted;
  late bool _isHapticsEnabled;

  // Graphics State
  late bool _highShadersEnabled;
  late int _targetFps;
  late bool _lowBatteryMode;

  // Diagnostics State
  late int _vlogLevel;
  late bool _showFpsCounter;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    final p = PersistenceService.instance;

    _sfxVolume = p.sfxVolume;
    _bgmVolume = p.bgmVolume;
    _isSfxMuted = p.isSfxMuted;
    _isBgmMuted = p.isBgmMuted;
    _isHapticsEnabled = p.isHapticsEnabled;

    _highShadersEnabled = p.highShadersEnabled;
    _targetFps = p.targetFps;
    _lowBatteryMode = p.lowBatteryMode;

    _vlogLevel = p.vlogLevel;
    _showFpsCounter = p.showFpsCounter;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _openLicenses(BuildContext context) {
    showLicensePage(
      context: context,
      applicationName: 'Void Sower: Bao Orbital Batteries',
      applicationVersion: 'v0.2.13+15 (Production Release)',
      applicationIcon: const Padding(
        padding: EdgeInsets.all(8.0),
        child: Icon(Icons.shield, color: VoidTheme.solarGold, size: 36),
      ),
      applicationLegalese:
          'Copyright 2026 Void Sower Authors. Apache 2.0 Licensed.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(
        horizontal: 14.0,
        vertical: 20.0,
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 540, maxHeight: 680),
        decoration: VoidTheme.glassmorphic(
          borderColor: VoidTheme.solarGold,
          borderWidth: 1.5,
          borderRadius: 18.0,
        ),
        child: Material(
          type: MaterialType.transparency,
          child: Column(
            children: [
              // Modal Header
              Padding(
                padding: const EdgeInsets.fromLTRB(18.0, 16.0, 12.0, 10.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.tune,
                          color: VoidTheme.solarGold,
                          size: 22.0,
                        ),
                        SizedBox(width: 8.0),
                        Text(
                          'FLEET SYSTEM CONFIG',
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

              // Tab Bar
              Container(
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: VoidTheme.cardSurface,
                      width: 1.0,
                    ),
                  ),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicatorColor: VoidTheme.plasmaCyan,
                  indicatorWeight: 2.5,
                  labelColor: VoidTheme.plasmaCyan,
                  unselectedLabelColor: VoidTheme.starWhite.withValues(
                    alpha: 0.6,
                  ),
                  labelStyle: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                  ),
                  isScrollable: true,
                  tabs: const [
                    Tab(text: 'AUDIO & HAPTICS'),
                    Tab(text: 'GRAPHICS'),
                    Tab(text: 'DIAGNOSTICS'),
                    Tab(text: 'LEGAL & ABOUT'),
                  ],
                ),
              ),

              // Tab Content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildAudioTab(),
                    _buildGraphicsTab(),
                    _buildDiagnosticsTab(),
                    _buildLegalTab(context),
                  ],
                ),
              ),

              // Footer
              Padding(
                padding: const EdgeInsets.all(14.0),
                child: TactileButton(
                  label: 'RETURN TO COCKPIT',
                  icon: Icons.check,
                  accentColor: VoidTheme.solarGold,
                  height: 44.0,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAudioTab() {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // SFX Controls
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'SOUND EFFECTS (SFX)',
              style: TextStyle(
                color: VoidTheme.plasmaCyan,
                fontSize: 12.0,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
            Row(
              children: [
                Text(
                  _isSfxMuted ? 'MUTED' : '${(_sfxVolume * 100).round()}%',
                  style: const TextStyle(
                    color: VoidTheme.starWhite,
                    fontSize: 11.0,
                    fontFamily: 'monospace',
                  ),
                ),
                const SizedBox(width: 8.0),
                IconButton(
                  icon: Icon(
                    _isSfxMuted ? Icons.volume_off : Icons.volume_up,
                    color: _isSfxMuted
                        ? VoidTheme.crimsonFlare
                        : VoidTheme.plasmaCyan,
                    size: 20.0,
                  ),
                  onPressed: () async {
                    final newMuted = !_isSfxMuted;
                    setState(() => _isSfxMuted = newMuted);
                    await AudioService.instance.setSfxMuted(newMuted);
                  },
                ),
              ],
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: VoidTheme.plasmaCyan,
            thumbColor: VoidTheme.plasmaCyan,
            inactiveTrackColor: VoidTheme.cardSurface,
          ),
          child: Slider(
            value: _sfxVolume,
            min: 0.0,
            max: 1.0,
            onChanged: (val) {
              setState(() => _sfxVolume = val);
              AudioService.instance.setSfxVolume(val);
            },
          ),
        ),
        TactileButton(
          label: 'TEST SFX DISCHARGE',
          icon: Icons.play_arrow,
          accentColor: VoidTheme.plasmaCyan,
          height: 36.0,
          onPressed: () {
            AudioService.instance.playLanceFire();
          },
        ),

        const SizedBox(height: 20.0),
        const Divider(color: VoidTheme.cardSurface),
        const SizedBox(height: 10.0),

        // BGM Controls
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'BACKGROUND MUSIC (BGM)',
              style: TextStyle(
                color: VoidTheme.solarGold,
                fontSize: 12.0,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
            Row(
              children: [
                Text(
                  _isBgmMuted ? 'MUTED' : '${(_bgmVolume * 100).round()}%',
                  style: const TextStyle(
                    color: VoidTheme.starWhite,
                    fontSize: 11.0,
                    fontFamily: 'monospace',
                  ),
                ),
                const SizedBox(width: 8.0),
                IconButton(
                  icon: Icon(
                    _isBgmMuted ? Icons.music_off : Icons.music_note,
                    color: _isBgmMuted
                        ? VoidTheme.crimsonFlare
                        : VoidTheme.solarGold,
                    size: 20.0,
                  ),
                  onPressed: () async {
                    final newMuted = !_isBgmMuted;
                    setState(() => _isBgmMuted = newMuted);
                    await AudioService.instance.setBgmMuted(newMuted);
                  },
                ),
              ],
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: VoidTheme.solarGold,
            thumbColor: VoidTheme.solarGold,
            inactiveTrackColor: VoidTheme.cardSurface,
          ),
          child: Slider(
            value: _bgmVolume,
            min: 0.0,
            max: 1.0,
            onChanged: (val) {
              setState(() => _bgmVolume = val);
              AudioService.instance.setBgmVolume(val);
            },
          ),
        ),

        const SizedBox(height: 16.0),
        const Divider(color: VoidTheme.cardSurface),
        const SizedBox(height: 10.0),

        // Haptic Feedback Controls
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          activeThumbColor: VoidTheme.solarGold,
          title: const Text(
            'Haptic Vibration Feedback',
            style: TextStyle(
              color: VoidTheme.starWhite,
              fontSize: 13.0,
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: const Text(
            'Tactile physical clicks during core injections and lance discharges.',
            style: TextStyle(color: VoidTheme.starWhite, fontSize: 11.0),
          ),
          value: _isHapticsEnabled,
          onChanged: (val) async {
            setState(() => _isHapticsEnabled = val);
            await PersistenceService.instance.setHapticsEnabled(val);
            if (val) HapticService.instance.injectionClick();
          },
        ),
      ],
    );
  }

  Widget _buildGraphicsTab() {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          activeThumbColor: VoidTheme.plasmaCyan,
          title: const Text(
            'GLSL High Fidelity Shaders',
            style: TextStyle(
              color: VoidTheme.starWhite,
              fontSize: 13.0,
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: const Text(
            'Enables runtime GPU fragment shaders for lance glow and atmospheric siphon.',
            style: TextStyle(color: VoidTheme.starWhite, fontSize: 11.0),
          ),
          value: _highShadersEnabled,
          onChanged: (val) async {
            setState(() => _highShadersEnabled = val);
            await PersistenceService.instance.setHighShadersEnabled(val);
          },
        ),
        const SizedBox(height: 16.0),
        const Divider(color: VoidTheme.cardSurface),
        const SizedBox(height: 12.0),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Target Simulation Refresh Rate',
                  style: TextStyle(
                    color: VoidTheme.starWhite,
                    fontSize: 13.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4.0),
                Text(
                  'Refresh rate for the Flutter render loop.',
                  style: TextStyle(color: VoidTheme.starWhite, fontSize: 11.0),
                ),
              ],
            ),
            SegmentedButton<int>(
              segments: const [
                ButtonSegment<int>(value: 60, label: Text('60 FPS')),
                ButtonSegment<int>(value: 120, label: Text('120 FPS')),
              ],
              selected: {_targetFps},
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.resolveWith<Color>((
                  states,
                ) {
                  if (states.contains(WidgetState.selected)) {
                    return VoidTheme.plasmaCyan.withValues(alpha: 0.3);
                  }
                  return VoidTheme.cardSurface;
                }),
              ),
              onSelectionChanged: (newSelection) async {
                final fps = newSelection.first;
                setState(() => _targetFps = fps);
                await PersistenceService.instance.setTargetFps(fps);
              },
            ),
          ],
        ),

        const SizedBox(height: 16.0),
        const Divider(color: VoidTheme.cardSurface),
        const SizedBox(height: 12.0),

        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          activeThumbColor: VoidTheme.solarGold,
          title: const Text(
            'Low Battery Mode',
            style: TextStyle(
              color: VoidTheme.starWhite,
              fontSize: 13.0,
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: const Text(
            'Caps animations and minimizes background particle effects to save power.',
            style: TextStyle(color: VoidTheme.starWhite, fontSize: 11.0),
          ),
          value: _lowBatteryMode,
          onChanged: (val) async {
            setState(() => _lowBatteryMode = val);
            await PersistenceService.instance.setLowBatteryMode(val);
          },
        ),
      ],
    );
  }

  Widget _buildDiagnosticsTab() {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'ABSEIL NATIVE VLOG LEVEL',
              style: TextStyle(
                color: VoidTheme.plasmaCyan,
                fontSize: 12.0,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
            Text(
              'Level $_vlogLevel',
              style: const TextStyle(
                color: VoidTheme.starWhite,
                fontSize: 12.0,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: VoidTheme.plasmaCyan,
            thumbColor: VoidTheme.plasmaCyan,
            inactiveTrackColor: VoidTheme.cardSurface,
          ),
          child: Slider(
            value: _vlogLevel.toDouble(),
            min: 0,
            max: 6,
            divisions: 6,
            onChanged: (val) async {
              final level = val.round();
              setState(() => _vlogLevel = level);
              await PersistenceService.instance.setVlogLevel(level);
            },
          ),
        ),

        const SizedBox(height: 12.0),
        const Divider(color: VoidTheme.cardSurface),
        const SizedBox(height: 12.0),

        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          activeThumbColor: VoidTheme.plasmaCyan,
          title: const Text(
            'In-Game FPS Counter',
            style: TextStyle(
              color: VoidTheme.starWhite,
              fontSize: 13.0,
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: const Text(
            'Displays live 60 Hz frame delta readout in tactical combat HUD.',
            style: TextStyle(color: VoidTheme.starWhite, fontSize: 11.0),
          ),
          value: _showFpsCounter,
          onChanged: (val) async {
            setState(() => _showFpsCounter = val);
            await PersistenceService.instance.setShowFpsCounter(val);
          },
        ),

        const SizedBox(height: 16.0),
        const Divider(color: VoidTheme.cardSurface),
        const SizedBox(height: 12.0),

        if (widget.onLaunchAcademy != null) ...[
          TactileButton(
            label: 'FLIGHT ACADEMY',
            icon: Icons.school,
            accentColor: VoidTheme.solarGold,
            isPrimary: true,
            height: 40.0,
            onPressed: () {
              Navigator.of(context).pop();
              widget.onLaunchAcademy?.call();
            },
          ),
          const SizedBox(height: 8.0),
        ],

        TactileButton(
          label: 'RESET FLIGHT ACADEMY TUTORIAL',
          icon: Icons.restart_alt,
          accentColor: VoidTheme.textSecondary,
          isPrimary: false,
          height: 38.0,
          onPressed: () async {
            await PersistenceService.instance.setCompletedTutorial(false);
            widget.onResetTutorial?.call();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Flight Academy Tutorial reset for next launch.',
                  ),
                  backgroundColor: VoidTheme.cardSurface,
                ),
              );
            }
          },
        ),
      ],
    );
  }

  Widget _buildLegalTab(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        TactileButton(
          label: 'IN-APP PRIVACY POLICY',
          icon: Icons.privacy_tip,
          accentColor: VoidTheme.plasmaCyan,
          height: 40.0,
          onPressed: () {
            showDialog<void>(
              context: context,
              builder: (context) => const PrivacyPolicyDialog(),
            );
          },
        ),
        const SizedBox(height: 10.0),
        TactileButton(
          label: 'TERMS OF SERVICE',
          icon: Icons.gavel,
          accentColor: VoidTheme.solarGold,
          height: 40.0,
          onPressed: () {
            showDialog<void>(
              context: context,
              builder: (context) => const TermsOfServiceDialog(),
            );
          },
        ),
        const SizedBox(height: 10.0),
        TactileButton(
          label: 'CONSENT PREFERENCES & GDPR',
          icon: Icons.security,
          accentColor: VoidTheme.starWhite,
          height: 40.0,
          onPressed: () {
            showDialog<void>(
              context: context,
              builder: (context) =>
                  ConsentPreferencesDialog(onDataWiped: widget.onDataWiped),
            );
          },
        ),
        const SizedBox(height: 10.0),
        TactileButton(
          label: 'OPEN SOURCE LICENSES',
          icon: Icons.code,
          accentColor: VoidTheme.plasmaCyanLight,
          height: 40.0,
          onPressed: () => _openLicenses(context),
        ),

        const SizedBox(height: 20.0),
        const Divider(color: VoidTheme.cardSurface),
        const SizedBox(height: 10.0),

        const Center(
          child: Column(
            children: [
              Text(
                'VOID SOWER: BAO ORBITAL BATTERIES',
                style: TextStyle(
                  color: VoidTheme.solarGold,
                  fontSize: 11.0,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
              SizedBox(height: 4.0),
              Text(
                'Engine v0.2.2+4 (EnTT v3.13.2 + Abseil C++17)',
                style: TextStyle(
                  color: VoidTheme.starWhite,
                  fontSize: 10.0,
                  fontFamily: 'monospace',
                ),
              ),
              SizedBox(height: 2.0),
              Text(
                '16 KB Page Aligned • Flat C ABI • Apache 2.0',
                style: TextStyle(
                  color: VoidTheme.starWhite,
                  fontSize: 9.5,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
