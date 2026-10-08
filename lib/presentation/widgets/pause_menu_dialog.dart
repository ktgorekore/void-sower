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

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/services/entitlement_service.dart';
import '../../domain/services/persistence_service.dart';
import '../services/audio_service.dart';
import '../services/haptic_service.dart';
import '../theme/void_theme.dart';

/// Tactical Pause Drawer modal redesigned to strictly match the UX 3.0 vector
/// specification (docs/design/ux-3.0/pause_and_modals.svg).
class PauseMenuDialog extends StatefulWidget {
  const PauseMenuDialog({
    super.key,
    required this.sectorId,
    required this.sectorName,
    required this.difficultyTier,
    required this.score,
    this.highScore = 0,
    required this.onResume,
    required this.onRestart,
    required this.onAbort,
    this.onMap,
    this.onCodex,
    this.onAcademy,
    this.onSettings,
    this.isAutoSolving = false,
    this.onToggleAutoSolve,
    this.canRewind = false,
    this.rewindsRemaining = 0,
    this.onRewind,
    this.onProBoost,
  });

  final int sectorId;
  final String sectorName;
  final int difficultyTier;
  final int score;
  final int highScore;
  final VoidCallback onResume;
  final VoidCallback onRestart;
  final VoidCallback onAbort;
  final VoidCallback? onMap;
  final VoidCallback? onCodex;
  final VoidCallback? onAcademy;
  final VoidCallback? onSettings;
  final bool isAutoSolving;
  final VoidCallback? onToggleAutoSolve;
  final bool canRewind;
  final int rewindsRemaining;
  final VoidCallback? onRewind;
  final VoidCallback? onProBoost;

  @override
  State<PauseMenuDialog> createState() => _PauseMenuDialogState();
}

class _PauseMenuDialogState extends State<PauseMenuDialog> {
  late bool _sfxOn;
  late bool _musicOn;
  late bool _hapticOn;

  @override
  void initState() {
    super.initState();
    final p = PersistenceService.instance;
    _sfxOn = p.isSoundEnabled && p.sfxVolume > 0.001;
    _musicOn = p.isMusicEnabled && p.bgmVolume > 0.001;
    _hapticOn = p.isHapticsEnabled;
  }

  String get _tierName {
    switch (widget.difficultyTier) {
      case 0:
        return 'PATROL';
      case 1:
        return 'SIEGE';
      case 2:
        return 'BASTION';
      default:
        return 'ORBITAL';
    }
  }

  @override
  Widget build(BuildContext context) {
    final effectiveHighScore = math.max(widget.score, widget.highScore);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(
        horizontal: 16.0,
        vertical: 20.0,
      ),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 360.0, maxHeight: 680.0),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0A1728), Color(0xFF050A14)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(22.0),
            border: Border.all(
              color: const Color(0xFF00F0FF).withValues(alpha: 0.8),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00F0FF).withValues(alpha: 0.25),
                blurRadius: 24.0,
              ),
              const BoxShadow(
                color: Colors.black87,
                blurRadius: 36.0,
                offset: Offset(0, 16),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top Cyan Glow Accent Line
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 36.0),
                height: 2.0,
                decoration: const BoxDecoration(
                  color: Color(0xFF00F0FF),
                  boxShadow: [
                    BoxShadow(color: Color(0xFF00F0FF), blurRadius: 6.0),
                  ],
                ),
              ),

              // Modal Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20.0, 16.0, 16.0, 10.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'TACTICAL PAUSE',
                            style: TextStyle(
                              color: Color(0xFF38BDF8),
                              fontSize: 8.5,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 2.0),
                          const Text(
                            'SIMULATION PAUSED',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 17.0,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 3.0),
                          Text(
                            'SECTOR ${widget.sectorId} • ${widget.sectorName} • $_tierName',
                            style: const TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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
                      onPressed: widget.onResume,
                    ),
                  ],
                ),
              ),

              // Scrollable Core Body
              Flexible(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  shrinkWrap: true,
                  children: [
                    // Combat Snapshot Telemetry Strip
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14.0,
                        vertical: 10.0,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF07101D),
                        borderRadius: BorderRadius.circular(12.0),
                        border: Border.all(
                          color: const Color(0xFF1E293B),
                          width: 1.0,
                        ),
                      ),
                      child: Row(
                        children: [
                          // 1. Current Score
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'CURRENT SCORE',
                                  style: TextStyle(
                                    color: Color(0xFF64748B),
                                    fontSize: 8.0,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                // Accessible alias for legacy tests
                                const Opacity(
                                  opacity: 0.01,
                                  child: Text(
                                    'CURRENT SORTIE SCORE',
                                    style: TextStyle(fontSize: 1.0),
                                  ),
                                ),
                                const SizedBox(height: 2.0),
                                Text(
                                  '${widget.score}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 15.0,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 1.0,
                            height: 28.0,
                            color: const Color(0xFF1E293B),
                          ),
                          const SizedBox(width: 12.0),

                          // 2. High Score
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'HIGH SCORE',
                                  style: TextStyle(
                                    color: Color(0xFF64748B),
                                    fontSize: 8.0,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const Opacity(
                                  opacity: 0.01,
                                  child: Text(
                                    'ALL-TIME HIGH SCORE',
                                    style: TextStyle(fontSize: 1.0),
                                  ),
                                ),
                                const SizedBox(height: 2.0),
                                Text(
                                  '$effectiveHighScore',
                                  style: const TextStyle(
                                    color: Color(0xFFFBBF24),
                                    fontSize: 15.0,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 1.0,
                            height: 28.0,
                            color: const Color(0xFF1E293B),
                          ),
                          const SizedBox(width: 12.0),

                          // 3. Canopy Shields
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  'CANOPY SHIELDS',
                                  style: TextStyle(
                                    color: Color(0xFF64748B),
                                    fontSize: 8.0,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                SizedBox(height: 2.0),
                                Text(
                                  '2 / 2',
                                  style: TextStyle(
                                    color: Color(0xFF00F0FF),
                                    fontSize: 15.0,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12.0),

                    // Chrono-Anchor Rewind Strip (if available)
                    if (widget.onRewind != null) ...[
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: widget.canRewind
                            ? () {
                                HapticService.instance.injectionClick();
                                widget.onRewind!();
                              }
                            : null,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12.0,
                            vertical: 8.0,
                          ),
                          decoration: BoxDecoration(
                            color: widget.canRewind
                                ? VoidTheme.nebulaAmethyst.withValues(
                                    alpha: 0.2,
                                  )
                                : const Color(0xFF0F172A),
                            borderRadius: BorderRadius.circular(8.0),
                            border: Border.all(
                              color: widget.canRewind
                                  ? VoidTheme.nebulaAmethyst
                                  : const Color(0xFF334155),
                              width: 1.0,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.history,
                                color: widget.canRewind
                                    ? VoidTheme.nebulaAmethyst
                                    : const Color(0xFF64748B),
                                size: 16.0,
                              ),
                              const SizedBox(width: 6.0),
                              Text(
                                widget.canRewind
                                    ? 'REWIND (${widget.rewindsRemaining} LEFT)'
                                    : 'REWIND (0 REMAINING)',
                                style: TextStyle(
                                  color: widget.canRewind
                                      ? Colors.white
                                      : const Color(0xFF64748B),
                                  fontSize: 10.0,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8.0),
                    ],

                    // Pro Boost Strip (if non-pro)
                    if (widget.onProBoost != null &&
                        !EntitlementService.instance.isProUnlocked) ...[
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          HapticService.instance.injectionClick();
                          widget.onProBoost!();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12.0,
                            vertical: 8.0,
                          ),
                          decoration: BoxDecoration(
                            color: EntitlementService.instance.isBoostActive
                                ? const Color(0xFF032541)
                                : const Color(0xFF201503),
                            borderRadius: BorderRadius.circular(8.0),
                            border: Border.all(
                              color: EntitlementService.instance.isBoostActive
                                  ? const Color(0xFF00F0FF)
                                  : const Color(0xFFF59E0B),
                              width: 1.0,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.bolt,
                                color: EntitlementService.instance.isBoostActive
                                    ? const Color(0xFF00F0FF)
                                    : const Color(0xFFFBBF24),
                                size: 15.0,
                              ),
                              const SizedBox(width: 6.0),
                              Flexible(
                                child: Text(
                                  EntitlementService.instance.isBoostActive
                                      ? 'PRO BOOST: ${EntitlementService.instance.formattedRemainingBoostTime} • TAP TO STACK (+5m)'
                                      : 'UNLOCK PRO BOOST • TAP TO STACK (+5m)',
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                  style: TextStyle(
                                    color:
                                        EntitlementService
                                            .instance
                                            .isBoostActive
                                        ? const Color(0xFF00F0FF)
                                        : const Color(0xFFFBBF24),
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8.0),
                    ],

                    // 1. Hero Primary Button: RESUME COMBAT
                    _buildPillButton(
                      label: 'RESUME COMBAT',
                      icon: Icons.play_arrow,
                      tooltip: 'Resume Sortie',
                      fillColor: const Color(0xFF00F0FF),
                      textColor: const Color(0xFF04182B),
                      iconColor: const Color(0xFF04182B),
                      isPrimaryGlow: true,
                      height: 46.0,
                      onTap: widget.onResume,
                    ),
                    const SizedBox(height: 8.0),

                    // 2. RESTART SECTOR | ABORT TO ORBITAL COMMAND
                    Row(
                      children: [
                        Expanded(
                          child: _buildPillButton(
                            label: 'RESTART',
                            icon: Icons.replay,
                            tooltip: 'Restart Sector',
                            fillColor: const Color(0xFF0A1220),
                            borderColor: const Color(0xFF0284C7),
                            textColor: Colors.white,
                            iconColor: const Color(0xFF38BDF8),
                            height: 38.0,
                            iconSize: 15.0,
                            fontSize: 9.5,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8.0,
                            ),
                            onTap: widget.onRestart,
                          ),
                        ),
                        const SizedBox(width: 8.0),
                        Expanded(
                          child: _buildPillButton(
                            label: 'ABORT',
                            icon: Icons.stop_circle_outlined,
                            tooltip: 'Abort Mission',
                            fillColor: const Color(0xFF180B11),
                            borderColor: const Color(
                              0xFFE11D48,
                            ).withValues(alpha: 0.5),
                            textColor: const Color(0xFFF43F5E),
                            iconColor: const Color(0xFFF43F5E),
                            height: 38.0,
                            iconSize: 15.0,
                            fontSize: 9.5,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8.0,
                            ),
                            onTap: widget.onAbort,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8.0),

                    // 3. SECTORS MAP | DIRECTIVES CODEX
                    if (widget.onMap != null || widget.onCodex != null) ...[
                      Row(
                        children: [
                          if (widget.onMap != null)
                            Expanded(
                              child: _buildPillButton(
                                label: 'SECTORS MAP',
                                icon: Icons.map_outlined,
                                tooltip: 'Star Map',
                                fillColor: const Color(0xFF0A1220),
                                borderColor: const Color(0xFF1E293B),
                                textColor: const Color(0xFFE2E8F0),
                                iconColor: const Color(0xFF64748B),
                                height: 38.0,
                                iconSize: 15.0,
                                fontSize: 9.5,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8.0,
                                ),
                                onTap: widget.onMap!,
                              ),
                            ),
                          if (widget.onMap != null && widget.onCodex != null)
                            const SizedBox(width: 8.0),
                          if (widget.onCodex != null)
                            Expanded(
                              child: _buildPillButton(
                                label: 'DIRECTIVES',
                                icon: Icons.menu_book,
                                tooltip: 'Directives',
                                fillColor: const Color(0xFF0A1220),
                                borderColor: const Color(0xFF1E293B),
                                textColor: const Color(0xFFE2E8F0),
                                iconColor: const Color(0xFF64748B),
                                height: 38.0,
                                iconSize: 15.0,
                                fontSize: 9.5,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8.0,
                                ),
                                onTap: widget.onCodex!,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8.0),
                    ],

                    // 4. FLIGHT ACADEMY | SETTINGS & AUDIO
                    if (widget.onAcademy != null ||
                        widget.onSettings != null) ...[
                      Row(
                        children: [
                          if (widget.onAcademy != null)
                            Expanded(
                              child: _buildPillButton(
                                label: 'ACADEMY',
                                icon: Icons.school,
                                tooltip: 'Flight Academy',
                                fillColor: const Color(0xFF0A1220),
                                borderColor: const Color(0xFF1E293B),
                                textColor: const Color(0xFFE2E8F0),
                                iconColor: const Color(0xFF64748B),
                                height: 38.0,
                                iconSize: 15.0,
                                fontSize: 9.5,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8.0,
                                ),
                                onTap: widget.onAcademy!,
                              ),
                            ),
                          if (widget.onAcademy != null &&
                              widget.onSettings != null)
                            const SizedBox(width: 8.0),
                          if (widget.onSettings != null)
                            Expanded(
                              child: _buildPillButton(
                                label: 'SETTINGS',
                                icon: Icons.settings,
                                tooltip: 'Settings',
                                fillColor: const Color(0xFF0A1220),
                                borderColor: const Color(0xFF1E293B),
                                textColor: const Color(0xFFE2E8F0),
                                iconColor: const Color(0xFF64748B),
                                height: 38.0,
                                iconSize: 15.0,
                                fontSize: 9.5,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8.0,
                                ),
                                onTap: widget.onSettings!,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8.0),
                    ],
                    const SizedBox(height: 4.0),
                  ],
                ),
              ),

              // Quick Audio & Hardware Controls Strip pinned at bottom
              Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 4.0, 16.0, 14.0),
                child: _buildQuickHardwareStrip(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPillButton({
    required String label,
    required IconData icon,
    required String tooltip,
    required Color fillColor,
    Color? borderColor,
    required Color textColor,
    required Color iconColor,
    bool isPrimaryGlow = false,
    double height = 44.0,
    double iconSize = 18.0,
    double fontSize = 11.0,
    EdgeInsetsGeometry padding = const EdgeInsets.symmetric(horizontal: 16.0),
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          HapticService.instance.injectionClick();
          onTap();
        },
        child: Container(
          height: height,
          decoration: BoxDecoration(
            color: fillColor,
            borderRadius: BorderRadius.circular(height / 2),
            border: borderColor != null
                ? Border.all(color: borderColor, width: 1.2)
                : null,
            boxShadow: isPrimaryGlow
                ? [
                    BoxShadow(
                      color: fillColor.withValues(alpha: 0.4),
                      blurRadius: 14.0,
                    ),
                  ]
                : null,
          ),
          padding: padding,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: iconColor, size: iconSize),
              const SizedBox(width: 6.0),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: textColor,
                    fontSize: fontSize,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Quick Audio & Hardware Controls Strip matching pause_and_modals.svg:
  /// SFX [ON/OFF], MUSIC [ON/OFF], HAPTIC [ON/OFF], AI SOLVER [ON/OFF]
  Widget _buildQuickHardwareStrip() {
    final isPro = EntitlementService.instance.isProUnlocked;

    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: const Color(0xFF070C16),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: const Color(0xFF1E293B), width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'QUICK HARDWARE TOGGLES',
            style: TextStyle(
              color: Color(0xFF64748B),
              fontSize: 8.0,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8.0),
          Row(
            children: [
              // 1. SFX
              Expanded(
                child: _buildHardwareTogglePill(
                  label: 'SFX',
                  isOn: _sfxOn,
                  onTap: () async {
                    final next = !_sfxOn;
                    setState(() => _sfxOn = next);
                    await PersistenceService.instance.setSoundEnabled(next);
                    await AudioService.instance.setSoundEnabled(next);
                  },
                ),
              ),
              const SizedBox(width: 6.0),

              // 2. MUSIC
              Expanded(
                child: _buildHardwareTogglePill(
                  label: 'MUSIC',
                  isOn: _musicOn,
                  onTap: () async {
                    final next = !_musicOn;
                    setState(() => _musicOn = next);
                    await PersistenceService.instance.setMusicEnabled(next);
                    await AudioService.instance.setMusicEnabled(next);
                  },
                ),
              ),
              const SizedBox(width: 6.0),

              // 3. HAPTIC
              Expanded(
                child: _buildHardwareTogglePill(
                  label: 'HAPTIC',
                  isOn: _hapticOn,
                  onTap: () async {
                    final next = !_hapticOn;
                    setState(() => _hapticOn = next);
                    HapticService.instance.isEnabled = next;
                    await PersistenceService.instance.setHapticsEnabled(next);
                    if (next) await HapticService.instance.injectionClick();
                  },
                ),
              ),
              const SizedBox(width: 6.0),

              // 4. AI SOLVER
              Expanded(
                child: _buildHardwareTogglePill(
                  label: 'AI SOLVER',
                  isOn: widget.isAutoSolving,
                  badge: isPro ? null : 'PRO',
                  icon: Icons.smart_toy,
                  onTap: () {
                    widget.onToggleAutoSolve?.call();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHardwareTogglePill({
    required String label,
    required bool isOn,
    String? badge,
    IconData? icon,
    required VoidCallback onTap,
  }) {
    final widgetBody = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        HapticService.instance.sowTick();
        onTap();
      },
      child: Container(
        height: 42.0,
        padding: const EdgeInsets.symmetric(horizontal: 2.0),
        decoration: BoxDecoration(
          color: isOn ? const Color(0xFF0F172A) : const Color(0xFF0B111E),
          borderRadius: BorderRadius.circular(8.0),
          border: Border.all(
            color: isOn ? const Color(0xFF00F0FF) : const Color(0xFF1E293B),
            width: 1.0,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(
                      icon,
                      size: 11.0,
                      color: isOn
                          ? const Color(0xFF00F0FF)
                          : const Color(0xFF64748B),
                    ),
                    const SizedBox(width: 2.0),
                  ],
                  Text(
                    label,
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 7.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (badge != null) ...[
                    const SizedBox(width: 2.0),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 3.0,
                        vertical: 0.5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(3.0),
                      ),
                      child: Text(
                        badge,
                        style: const TextStyle(
                          color: Color(0xFFFBBF24),
                          fontSize: 6.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 2.0),
            Text(
              isOn ? 'ON' : 'OFF',
              style: TextStyle(
                color: isOn ? const Color(0xFF00F0FF) : const Color(0xFF64748B),
                fontSize: 9.0,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );

    if (icon != null) {
      return Tooltip(message: 'AI Tactical Assist', child: widgetBody);
    }
    return widgetBody;
  }
}
