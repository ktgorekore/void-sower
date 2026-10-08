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

import '../../domain/services/entitlement_service.dart';
import '../../domain/services/iap_service.dart';
import '../../domain/services/persistence_service.dart';
import '../services/audio_service.dart';
import '../services/haptic_service.dart';
import '../theme/void_theme.dart';
import 'consent_preferences_dialog.dart';
import 'legal_dialogs.dart';
import 'pro_upgrade_modal.dart';
import 'tactical_directives_modal.dart';
import 'tactile_button.dart';

/// Centralized settings and preferences modal redesigned to strictly match
/// the UX 3.0 vector specification (docs/design/ux-3.0/settings.svg).
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
  late bool _isSoundEnabled;
  late bool _isMusicEnabled;
  late double _sfxVolume;
  late double _bgmVolume;
  late bool _isHapticsEnabled;
  int _hapticLevelIndex = 2; // 0: OFF, 1: SUBTLE, 2: CRISP, 3: HEAVY

  // Graphics & Display State
  late bool _highShadersEnabled;
  late int _targetFps;
  late bool _lowBatteryMode;
  bool _trajectoryReticlesEnabled = true;
  int _colorblindModeIndex =
      0; // 0: OFF, 1: PROTANOPIA, 2: DEUTERANOPIA, 3: TRITANOPIA

  // Diagnostics State
  late int _vlogLevel;
  late bool _showFpsCounter;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    final p = PersistenceService.instance;

    _isSoundEnabled = p.isSoundEnabled;
    _isMusicEnabled = p.isMusicEnabled;
    _sfxVolume = p.sfxVolume;
    _bgmVolume = p.bgmVolume;
    _isHapticsEnabled = p.isHapticsEnabled;
    _hapticLevelIndex = _isHapticsEnabled ? 2 : 0;

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
      applicationVersion: 'v0.3.0 (Production Release)',
      applicationIcon: const Padding(
        padding: EdgeInsets.all(8.0),
        child: Icon(Icons.shield, color: VoidTheme.solarGold, size: 36),
      ),
      applicationLegalese:
          'Copyright 2026 Void Sower Authors. Apache 2.0 Licensed.',
    );
  }

  void _openProUpgrade() {
    HapticService.instance.injectionClick();
    showDialog<void>(
      context: context,
      builder: (context) => const ProUpgradeModal(),
    ).then((_) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _restorePurchases() async {
    HapticService.instance.sowTick();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Contacting Google Play Store to restore purchases...'),
        backgroundColor: Color(0xFF0F172A),
      ),
    );
    await IapService.instance.restorePurchases();
    if (!mounted) return;
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Purchases sync request completed successfully.'),
        backgroundColor: Color(0xFF0284C7),
      ),
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
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 720),
        decoration: BoxDecoration(
          color: const Color(0xFF05070F),
          borderRadius: BorderRadius.circular(22.0),
          border: Border.all(
            color: const Color(0xFF00F0FF).withValues(alpha: 0.8),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00F0FF).withValues(alpha: 0.25),
              blurRadius: 28.0,
            ),
            const BoxShadow(
              color: Colors.black87,
              blurRadius: 40.0,
              offset: Offset(0, 20),
            ),
          ],
        ),
        child: Material(
          type: MaterialType.transparency,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Header & Version Readout matching settings.svg
              _buildHeader(),

              // 2. 3-Tab Selector Pills (AUDIO & HAPTIC, DISPLAY & FX, ACCOUNT & PRO)
              _buildTabBar(),

              // 3. Tab Content Deck
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildAudioAndHapticTab(),
                    _buildDisplayAndFxTab(),
                    _buildAccountAndProTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Header with Eyebrow, Title, Version Pill, and 4px Glowing Track.
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 12.0, 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'FLEET SYSTEM CONFIG',
                      style: TextStyle(
                        color: Color(0xFF38BDF8),
                        fontSize: 8.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                      ),
                    ),
                    SizedBox(height: 2.0),
                    Text(
                      'SYSTEM SETTINGS',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17.0,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8.0),
              // Engine Version Pill
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8.0,
                  vertical: 4.0,
                ),
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
                      width: 6.0,
                      height: 6.0,
                      decoration: const BoxDecoration(
                        color: Color(0xFF00F0FF),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: Color(0xFF00F0FF), blurRadius: 4.0),
                        ],
                      ),
                    ),
                    const SizedBox(width: 5.0),
                    const Text(
                      'ENGINE v0.3.0',
                      style: TextStyle(
                        color: Color(0xFFE0F2FE),
                        fontSize: 8.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                padding: const EdgeInsets.all(4.0),
                constraints: const BoxConstraints(),
                icon: const Icon(
                  Icons.close,
                  color: Color(0xFF94A3B8),
                  size: 20.0,
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 10.0),
          // 4px Glowing Track
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
                width: 120.0,
                height: 4.0,
                decoration: BoxDecoration(
                  color: const Color(0xFF00F0FF),
                  borderRadius: BorderRadius.circular(2.0),
                  boxShadow: const [
                    BoxShadow(color: Color(0xFF00F0FF), blurRadius: 8.0),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 3-Tab Pill Switcher matching settings.svg (32px height, rounded 16px).
  Widget _buildTabBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: AnimatedBuilder(
        animation: _tabController,
        builder: (context, _) {
          return Row(
            children: [
              _buildTabPill(
                index: 0,
                label: 'AUDIO & HAPTIC',
                isActive: _tabController.index == 0,
              ),
              const SizedBox(width: 8.0),
              _buildTabPill(
                index: 1,
                label: 'DISPLAY & FX',
                isActive: _tabController.index == 1,
              ),
              const SizedBox(width: 8.0),
              _buildTabPill(
                index: 2,
                label: 'ACCOUNT & PRO',
                isActive: _tabController.index == 2,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTabPill({
    required int index,
    required String label,
    required bool isActive,
  }) {
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          HapticService.instance.sowTick();
          _tabController.animateTo(index);
          setState(() {});
        },
        child: Container(
          height: 32.0,
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF0284C7) : const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(16.0),
            border: Border.all(
              color: isActive
                  ? const Color(0xFF00F0FF)
                  : const Color(0xFF1E293B),
              width: 1.0,
            ),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: const Color(0xFF00F0FF).withValues(alpha: 0.3),
                      blurRadius: 8.0,
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: isActive ? Colors.white : const Color(0xFF94A3B8),
              fontSize: 9.5,
              fontWeight: isActive ? FontWeight.w900 : FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }

  // ==============================================================
  // TAB 1: AUDIO & HAPTIC
  // ==============================================================
  Widget _buildAudioAndHapticTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16.0, 10.0, 16.0, 16.0),
      children: [
        // Hero Card: ACOUSTIC & KINETIC CALIBRATION
        Container(
          padding: const EdgeInsets.all(18.0),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0C233C), Color(0xFF071322)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18.0),
            border: Border.all(color: const Color(0xFF00F0FF), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00F0FF).withValues(alpha: 0.15),
                blurRadius: 16.0,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Card Subhead
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text(
                    'ACOUSTIC & KINETIC CALIBRATION',
                    style: TextStyle(
                      color: Color(0xFF38BDF8),
                      fontSize: 8.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0,
                    ),
                  ),
                  Text(
                    'SPATIAL 3D ACTIVE',
                    style: TextStyle(
                      color: Color(0xFF00F0FF),
                      fontSize: 8.0,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16.0),

              // Slider 1: Sound Effects (SFX)
              _buildNeonSliderRow(
                title: 'Combat Sound Effects (SFX)',
                subtitleTag: 'SOUND EFFECTS (SFX)',
                value: _sfxVolume,
                isMuted: !_isSoundEnabled || _sfxVolume <= 0.001,
                onToggleMute: () async {
                  final newSound = !_isSoundEnabled;
                  setState(() => _isSoundEnabled = newSound);
                  await PersistenceService.instance.setSoundEnabled(newSound);
                  await AudioService.instance.setSoundEnabled(newSound);
                },
                onChanged: (val) async {
                  setState(() {
                    _sfxVolume = val;
                    if (val > 0) _isSoundEnabled = true;
                  });
                  await PersistenceService.instance.setSfxVolume(val);
                  await AudioService.instance.setSfxVolume(val);
                },
              ),
              const SizedBox(height: 16.0),

              // Slider 2: Tactical Ambient Music (BGM)
              _buildNeonSliderRow(
                title: 'Afrofuturist Ambient Music',
                subtitleTag: 'BACKGROUND MUSIC (BGM)',
                value: _bgmVolume,
                isMuted: !_isMusicEnabled || _bgmVolume <= 0.001,
                onToggleMute: () async {
                  final newMusic = !_isMusicEnabled;
                  setState(() => _isMusicEnabled = newMusic);
                  await PersistenceService.instance.setMusicEnabled(newMusic);
                  await AudioService.instance.setMusicEnabled(newMusic);
                },
                onChanged: (val) async {
                  setState(() {
                    _bgmVolume = val;
                    if (val > 0) _isMusicEnabled = true;
                  });
                  await PersistenceService.instance.setBgmVolume(val);
                  await AudioService.instance.setBgmVolume(val);
                },
              ),
              const SizedBox(height: 18.0),

              // Haptic Feedback Selector Row
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Tactile Haptic Feedback',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        _isHapticsEnabled ? 'ACTIVE' : 'MUTED',
                        style: TextStyle(
                          color: _isHapticsEnabled
                              ? const Color(0xFF00F0FF)
                              : const Color(0xFF64748B),
                          fontSize: 9.0,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2.0),
                  const Text(
                    'Haptic Vibration Feedback',
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 8.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10.0),

                  // 4 Segment Buttons: OFF, SUBTLE, CRISP, HEAVY
                  Row(
                    children: [
                      _buildHapticSegment(0, 'OFF'),
                      const SizedBox(width: 6.0),
                      _buildHapticSegment(1, 'SUBTLE'),
                      const SizedBox(width: 6.0),
                      _buildHapticSegment(2, 'CRISP'),
                      const SizedBox(width: 6.0),
                      _buildHapticSegment(3, 'HEAVY'),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14.0),

        // Audio Focus Note
        Container(
          padding: const EdgeInsets.all(14.0),
          decoration: BoxDecoration(
            color: const Color(0xFF0A101D),
            borderRadius: BorderRadius.circular(12.0),
            border: Border.all(color: const Color(0xFF1E293B), width: 1.0),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Icon(Icons.info_outline, color: Color(0xFF38BDF8), size: 18.0),
              SizedBox(width: 10.0),
              Expanded(
                child: Text(
                  'Disabling sound/music or setting volume to 0% releases device audio focus so you can listen to external media (YouTube, Spotify, Podcasts) without interruption.',
                  style: TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 9.5,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNeonSliderRow({
    required String title,
    required String subtitleTag,
    required double value,
    required bool isMuted,
    required VoidCallback onToggleMute,
    required ValueChanged<double> onChanged,
  }) {
    final percent = (value * 100).toInt();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                HapticService.instance.sowTick();
                onToggleMute();
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    subtitleTag,
                    style: TextStyle(
                      color: isMuted
                          ? const Color(0xFFEF4444)
                          : const Color(0xFF38BDF8),
                      fontSize: 8.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                HapticService.instance.sowTick();
                onToggleMute();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8.0,
                  vertical: 3.0,
                ),
                decoration: BoxDecoration(
                  color: isMuted
                      ? const Color(0xFF1E1116)
                      : const Color(0xFF032541),
                  borderRadius: BorderRadius.circular(10.0),
                  border: Border.all(
                    color: isMuted
                        ? const Color(0xFFE11D48)
                        : const Color(0xFF00F0FF),
                    width: 1.0,
                  ),
                ),
                child: Text(
                  isMuted ? 'MUTED' : '$percent%',
                  style: TextStyle(
                    color: isMuted
                        ? const Color(0xFFF43F5E)
                        : const Color(0xFF00F0FF),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6.0),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 6.0,
            activeTrackColor: const Color(0xFF00F0FF),
            inactiveTrackColor: const Color(0xFF1E293B),
            thumbColor: Colors.white,
            thumbShape: const RoundSliderThumbShape(
              enabledThumbRadius: 8.0,
              elevation: 4.0,
            ),
            overlayColor: const Color(0xFF00F0FF).withValues(alpha: 0.2),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 16.0),
          ),
          child: Slider(
            value: isMuted ? 0.0 : value,
            min: 0.0,
            max: 1.0,
            onChanged: (newVal) {
              onChanged(newVal);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHapticSegment(int index, String label) {
    final isSelected = _hapticLevelIndex == index;

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () async {
          setState(() {
            _hapticLevelIndex = index;
            _isHapticsEnabled = index > 0;
            HapticService.instance.isEnabled = _isHapticsEnabled;
          });
          await PersistenceService.instance.setHapticsEnabled(
            _isHapticsEnabled,
          );
          if (index == 1) {
            await HapticService.instance.sowTick();
          } else if (index == 2) {
            await HapticService.instance.injectionClick();
          } else if (index == 3) {
            await HapticService.instance.lanceDischarge();
          }
        },
        child: Container(
          height: 34.0,
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF0284C7)
                : const Color(0xFF0A101D),
            borderRadius: BorderRadius.circular(8.0),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF00F0FF)
                  : const Color(0xFF1E293B),
              width: isSelected ? 1.4 : 1.0,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFF00F0FF).withValues(alpha: 0.4),
                      blurRadius: 8.0,
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : const Color(0xFF64748B),
              fontSize: 9.5,
              fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }

  // ==============================================================
  // TAB 2: DISPLAY & FX
  // ==============================================================
  Widget _buildDisplayAndFxTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16.0, 10.0, 16.0, 16.0),
      children: [
        const Text(
          'GRAPHICS & VISUAL ACCESSIBILITY',
          style: TextStyle(
            color: Color(0xFF38BDF8),
            fontSize: 9.0,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 10.0),

        // Option 1: 120 FPS High Refresh Combat
        _buildDisplayCard(
          icon: Icons.speed,
          title: '120 FPS High Refresh Combat',
          subtitle: 'Smoother corridor tracking & laser bloom',
          trailing: _buildCustomToggle(
            value: _targetFps == 120,
            onChanged: (val) async {
              final fps = val ? 120 : 60;
              setState(() => _targetFps = fps);
              await PersistenceService.instance.setTargetFps(fps);
            },
          ),
        ),
        const SizedBox(height: 8.0),

        // Option 2: Targeting Trajectory Reticles
        _buildDisplayCard(
          icon: Icons.track_changes,
          title: 'Targeting Trajectory Reticles',
          subtitle: 'High-visibility laser guides and impact boxes',
          trailing: _buildCustomToggle(
            value: _trajectoryReticlesEnabled,
            onChanged: (val) {
              setState(() => _trajectoryReticlesEnabled = val);
            },
          ),
        ),
        const SizedBox(height: 8.0),

        // Option 3: Colorblind Assistance Mode
        _buildDisplayCard(
          icon: Icons.remove_red_eye_outlined,
          title: 'Colorblind Assistance Mode',
          subtitle: 'Enhanced shape cues for cores and hostiles',
          trailing: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              HapticService.instance.sowTick();
              setState(() {
                _colorblindModeIndex = (_colorblindModeIndex + 1) % 4;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10.0,
                vertical: 6.0,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(13.0),
                border: Border.all(color: const Color(0xFF1E293B), width: 1.0),
              ),
              child: Text(
                _colorblindLabel,
                style: const TextStyle(
                  color: Color(0xFF38BDF8),
                  fontSize: 9.0,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8.0),

        // Option 4: High Fidelity Shaders
        _buildDisplayCard(
          icon: Icons.auto_awesome,
          title: 'GLSL High Fidelity Shaders',
          subtitle: 'Dynamic GPU fragment bloom, siphon and flares',
          trailing: _buildCustomToggle(
            value: _highShadersEnabled,
            onChanged: (val) async {
              setState(() => _highShadersEnabled = val);
              await PersistenceService.instance.setHighShadersEnabled(val);
            },
          ),
        ),
        const SizedBox(height: 8.0),

        // Option 5: In-Game FPS Counter
        _buildDisplayCard(
          icon: Icons.query_stats,
          title: 'In-Game FPS Counter',
          subtitle: 'Displays live frame delta readout in tactical combat HUD',
          trailing: _buildCustomToggle(
            value: _showFpsCounter,
            onChanged: (val) async {
              setState(() => _showFpsCounter = val);
              await PersistenceService.instance.setShowFpsCounter(val);
            },
          ),
        ),
        const SizedBox(height: 8.0),

        // Option 6: Native Vlog Level Slider
        Container(
          padding: const EdgeInsets.all(12.0),
          decoration: BoxDecoration(
            color: const Color(0xFF0A101D),
            borderRadius: BorderRadius.circular(14.0),
            border: Border.all(color: const Color(0xFF1E293B), width: 1.0),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'ABSEIL NATIVE VLOG LEVEL',
                    style: TextStyle(
                      color: Color(0xFF38BDF8),
                      fontSize: 10.0,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    'Level $_vlogLevel',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11.0,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4.0),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 4.0,
                  activeTrackColor: const Color(0xFF00F0FF),
                  inactiveTrackColor: const Color(0xFF1E293B),
                  thumbColor: const Color(0xFF00F0FF),
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 6.0,
                  ),
                ),
                child: Slider(
                  value: _vlogLevel.toDouble(),
                  min: 0,
                  max: 6,
                  divisions: 6,
                  onChanged: (val) async {
                    final lvl = val.round();
                    setState(() => _vlogLevel = lvl);
                    await PersistenceService.instance.setVlogLevel(lvl);
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8.0),

        // Option 7: Low Battery Mode
        _buildDisplayCard(
          icon: Icons.battery_saver,
          title: 'Low Battery Mode',
          subtitle: 'Caps particles & throttles GPU usage to extend battery',
          trailing: _buildCustomToggle(
            value: _lowBatteryMode,
            onChanged: (val) async {
              setState(() => _lowBatteryMode = val);
              await PersistenceService.instance.setLowBatteryMode(val);
            },
          ),
        ),
      ],
    );
  }

  String get _colorblindLabel {
    switch (_colorblindModeIndex) {
      case 1:
        return 'PROTANOPIA';
      case 2:
        return 'DEUTERANOPIA';
      case 3:
        return 'TRITANOPIA';
      default:
        return 'OFF (DEFAULT)';
    }
  }

  Widget _buildDisplayCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget trailing,
  }) {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: const Color(0xFF0A101D),
        borderRadius: BorderRadius.circular(14.0),
        border: Border.all(color: const Color(0xFF1E293B), width: 1.0),
      ),
      child: Row(
        children: [
          Container(
            width: 36.0,
            height: 36.0,
            decoration: BoxDecoration(
              color: const Color(0xFF071B2E),
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFF00F0FF).withValues(alpha: 0.5),
                width: 1.0,
              ),
            ),
            child: Icon(icon, color: const Color(0xFF00F0FF), size: 18.0),
          ),
          const SizedBox(width: 12.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12.0,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2.0),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 9.0,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8.0),
          trailing,
        ],
      ),
    );
  }

  Widget _buildCustomToggle({
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        HapticService.instance.sowTick();
        onChanged(!value);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 46.0,
        height: 24.0,
        padding: const EdgeInsets.all(3.0),
        decoration: BoxDecoration(
          color: value ? const Color(0xFF00F0FF) : const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(12.0),
          boxShadow: value
              ? [
                  BoxShadow(
                    color: const Color(0xFF00F0FF).withValues(alpha: 0.4),
                    blurRadius: 8.0,
                  ),
                ]
              : null,
        ),
        alignment: value ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          width: 18.0,
          height: 18.0,
          decoration: BoxDecoration(
            color: value ? const Color(0xFF04182B) : const Color(0xFF64748B),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }

  // ==============================================================
  // TAB 3: ACCOUNT & PRO
  // ==============================================================
  Widget _buildAccountAndProTab() {
    final isPro = EntitlementService.instance.isProUnlocked;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16.0, 10.0, 16.0, 16.0),
      children: [
        const Text(
          'ACCOUNT, PRO & DIRECTIVES',
          style: TextStyle(
            color: Color(0xFF38BDF8),
            fontSize: 9.0,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 10.0),

        // 1. Pro Status / Upgrade Hero Card
        Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF201503), Color(0xFF0A101D)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14.0),
            border: Border.all(color: const Color(0xFFF59E0B), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                blurRadius: 14.0,
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 40.0,
                height: 40.0,
                decoration: const BoxDecoration(
                  color: Color(0xFF3B2506),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.workspace_premium,
                  color: Color(0xFFFBBF24),
                  size: 22.0,
                ),
              ),
              const SizedBox(width: 12.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isPro
                          ? 'PRO COMMANDER CLEARANCE'
                          : 'VOID SOWER // PRO CLEARANCE',
                      style: const TextStyle(
                        color: Color(0xFFFBBF24),
                        fontSize: 12.0,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(height: 2.0),
                    Text(
                      isPro
                          ? 'All 8 Fleet Modules & AI Solver Active'
                          : '\$1.29 Lifetime Unlock • 8 Pro Modules',
                      style: const TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 9.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8.0),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _openProUpgrade,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14.0,
                    vertical: 8.0,
                  ),
                  decoration: BoxDecoration(
                    color: isPro
                        ? const Color(0xFF0F172A)
                        : const Color(0xFFF59E0B),
                    borderRadius: BorderRadius.circular(16.0),
                    border: Border.all(
                      color: const Color(0xFFFBBF24),
                      width: 1.0,
                    ),
                    boxShadow: !isPro
                        ? [
                            BoxShadow(
                              color: const Color(
                                0xFFF59E0B,
                              ).withValues(alpha: 0.4),
                              blurRadius: 10.0,
                            ),
                          ]
                        : null,
                  ),
                  child: Text(
                    isPro ? 'ACTIVE' : 'UPGRADE',
                    style: TextStyle(
                      color: isPro
                          ? const Color(0xFFFBBF24)
                          : const Color(0xFF1C0F01),
                      fontSize: 10.0,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10.0),

        // 2. Cloud Sync & Purchases Card
        _buildDisplayCard(
          icon: Icons.cloud_sync,
          title: 'Restore Pro Purchases & Sync',
          subtitle: 'Google Play Games cloud save verified',
          trailing: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _restorePurchases,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 14.0,
                vertical: 7.0,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(13.0),
                border: Border.all(color: const Color(0xFFF59E0B), width: 1.0),
              ),
              child: const Text(
                'RESTORE',
                style: TextStyle(
                  color: Color(0xFFFBBF24),
                  fontSize: 9.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10.0),

        // 3. Flight Academy & Directives Launcher
        _buildDisplayCard(
          icon: Icons.school,
          title: 'Tactical Directives & Codex',
          subtitle: '20-second visual combat directives & flight academy',
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  showDialog<void>(
                    context: context,
                    builder: (context) => TacticalDirectivesModal(
                      onLaunchAcademy: widget.onLaunchAcademy != null
                          ? () {
                              Navigator.of(context).pop();
                              widget.onLaunchAcademy?.call();
                            }
                          : null,
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10.0,
                    vertical: 7.0,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(13.0),
                    border: Border.all(
                      color: const Color(0xFF00F0FF),
                      width: 1.0,
                    ),
                  ),
                  child: const Text(
                    'CODEX',
                    style: TextStyle(
                      color: Color(0xFF00F0FF),
                      fontSize: 9.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              if (widget.onLaunchAcademy != null) ...[
                const SizedBox(width: 6.0),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    Navigator.of(context).pop();
                    widget.onLaunchAcademy?.call();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10.0,
                      vertical: 7.0,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0284C7),
                      borderRadius: BorderRadius.circular(13.0),
                      border: Border.all(
                        color: const Color(0xFF00F0FF),
                        width: 1.0,
                      ),
                    ),
                    child: const Text(
                      'ACADEMY',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12.0),

        // 4. Legal & Policies Strip
        const Text(
          'LEGAL, PRIVACY & LICENSES',
          style: TextStyle(
            color: Color(0xFF64748B),
            fontSize: 8.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 8.0),
        Wrap(
          spacing: 8.0,
          runSpacing: 8.0,
          children: [
            _buildLegalPill('PRIVACY POLICY', () {
              showDialog<void>(
                context: context,
                builder: (context) => const PrivacyPolicyDialog(),
              );
            }),
            _buildLegalPill('TERMS OF SERVICE', () {
              showDialog<void>(
                context: context,
                builder: (context) => const TermsOfServiceDialog(),
              );
            }),
            _buildLegalPill('PRIVACY CONSENT', () {
              showDialog<void>(
                context: context,
                builder: (context) =>
                    ConsentPreferencesDialog(onDataWiped: widget.onDataWiped),
              );
            }),
            _buildLegalPill(
              'OPEN SOURCE LICENSES',
              () => _openLicenses(context),
            ),
          ],
        ),
        const SizedBox(height: 16.0),

        // 5. Danger Zone: Tutorial Reset & Factory Wipe
        Container(
          padding: const EdgeInsets.all(14.0),
          decoration: BoxDecoration(
            color: const Color(0xFF14070B),
            borderRadius: BorderRadius.circular(14.0),
            border: Border.all(
              color: const Color(0xFFE11D48).withValues(alpha: 0.4),
              width: 1.0,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'DANGER ZONE // DATA RESET',
                style: TextStyle(
                  color: Color(0xFFF43F5E),
                  fontSize: 9.0,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 10.0),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF64748B)),
                        padding: const EdgeInsets.symmetric(vertical: 10.0),
                      ),
                      onPressed: () async {
                        await PersistenceService.instance.setCompletedTutorial(
                          false,
                        );
                        widget.onResetTutorial?.call();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Academy tutorial reset.'),
                              backgroundColor: Color(0xFF1E293B),
                            ),
                          );
                        }
                      },
                      child: const Text(
                        'RESET TUTORIAL',
                        style: TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 10.0,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFE11D48)),
                        padding: const EdgeInsets.symmetric(vertical: 10.0),
                      ),
                      onPressed: _confirmWipeData,
                      child: const Text(
                        'WIPE DATA',
                        style: TextStyle(
                          color: Color(0xFFF43F5E),
                          fontSize: 10.0,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLegalPill(String label, VoidCallback onTap) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        HapticService.instance.sowTick();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
        decoration: BoxDecoration(
          color: const Color(0xFF0A101D),
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(color: const Color(0xFF1E293B), width: 1.0),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Color(0xFF94A3B8),
            fontSize: 9.0,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  void _confirmWipeData() {
    HapticService.instance.sowTick();
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
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
            border: Border.all(color: const Color(0xFFF43F5E), width: 1.5),
            boxShadow: const [
              BoxShadow(
                color: Color(0x66000000),
                blurRadius: 20.0,
                offset: Offset(0, 6),
              ),
              BoxShadow(
                color: Color(0x33F43F5E),
                blurRadius: 16.0,
                spreadRadius: -2,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    width: 36.0,
                    height: 36.0,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0x22F43F5E),
                      border: Border.all(
                        color: const Color(0xFFF43F5E),
                        width: 1.5,
                      ),
                    ),
                    child: const Icon(
                      Icons.warning_amber_rounded,
                      color: Color(0xFFF43F5E),
                      size: 20.0,
                    ),
                  ),
                  const SizedBox(width: 12.0),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CRITICAL PURGE DIRECTIVE',
                          style: TextStyle(
                            color: Color(0xFFF43F5E),
                            fontSize: 9.0,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                          ),
                        ),
                        SizedBox(height: 2.0),
                        Text(
                          'WIPE ALL SAVED DATA?',
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
                  color: const Color(0xFFF43F5E),
                  borderRadius: BorderRadius.circular(1.5),
                  boxShadow: const [
                    BoxShadow(color: Color(0x80F43F5E), blurRadius: 6.0),
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
                  'This will permanently reset all campaign stars, liberated sectors, chassis unlocks, high scores, and local telemetry. This action cannot be undone.',
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
                      onPressed: () => Navigator.of(ctx).pop(),
                      accentColor: const Color(0xFF64748B),
                      height: 42.0,
                      isPrimary: false,
                    ),
                  ),
                  const SizedBox(width: 10.0),
                  Expanded(
                    child: TactileButton(
                      label: 'CONFIRM WIPE',
                      icon: Icons.delete_forever,
                      onPressed: () async {
                        HapticService.instance.injectionClick();
                        Navigator.of(ctx).pop();
                        await PersistenceService.instance.wipeAllData();
                        widget.onDataWiped?.call();
                        if (mounted) {
                          Navigator.of(context).pop();
                        }
                      },
                      accentColor: const Color(0xFFF43F5E),
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
  }
}
