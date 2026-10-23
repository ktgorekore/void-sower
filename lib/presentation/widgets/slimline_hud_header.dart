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

import 'dart:async';

import 'package:flutter/material.dart';

import '../../domain/models/user_profile.dart';
import '../../domain/services/entitlement_service.dart';
import '../theme/void_theme.dart';

/// Unified single-bar 38px Slimline HUD Header.
///
/// Consolidates all essential combat telemetry and controls into a single
/// glassmorphic top bar without separate floating tiles or verbose multi-line
/// sub-labels:
/// 1. Gmail-style circular Pilot Profile avatar button (`hud_profile_avatar`).
/// 2. Prominent glowing Star Map navigation button (`hud_map_button` / `hud_back_button`).
/// 3. Direct Special Ops shortcut button (`hud_special_ops_button`).
/// 4. Compact Sector ID & 6-digit Score display (or `AI SIM` when AI-assisted).
/// 5. Compact Pro / Boost / AI Auto status badge.
/// 6. Reactor Cores & Hostiles/Shields inline counters.
/// 7. Single-tap tactical pause toggle button.
class SlimlineHudHeader extends StatelessWidget {
  const SlimlineHudHeader({
    super.key,
    required this.reserveCores,
    required this.score,
    this.highScore = 0,
    this.isPro = false,
    this.isUnlimitedCores = false,
    required this.difficultyTier,
    this.sectorId = 1,
    this.sectorName = 'Zanzibar Reef Gate',
    this.userProfile,
    this.onProfileTap,
    this.invadersRemaining,
    this.totalInvaders,
    this.isPaused = false,
    this.onTogglePause,
    this.isAutoSolving = false,
    this.isAiAssisted = false,
    this.onToggleAutoSolve,
    this.isSecured = false,
    this.onNextSectorTap,
    this.onSettingsTap,
    this.onMapTap,
    this.onSpecialOpsTap,
    this.onRestartTap,
    this.onStopTap,
    this.onCodexTap,
    this.onTutorialTap,
    this.onEmergencyFlareTap,
    this.onProTap,
  });

  final int reserveCores;
  final int score;
  final int highScore;
  final bool isPro;
  final bool isUnlimitedCores;
  final int difficultyTier;
  final int sectorId;
  final String sectorName;
  final UserProfile? userProfile;
  final VoidCallback? onProfileTap;
  final int? invadersRemaining;
  final int? totalInvaders;
  final bool isPaused;
  final VoidCallback? onTogglePause;
  final bool isAutoSolving;
  final bool isAiAssisted;
  final VoidCallback? onToggleAutoSolve;
  final bool isSecured;
  final VoidCallback? onNextSectorTap;

  final VoidCallback? onSettingsTap;
  final VoidCallback? onMapTap;
  final VoidCallback? onSpecialOpsTap;
  final VoidCallback? onRestartTap;
  final VoidCallback? onStopTap;
  final VoidCallback? onCodexTap;
  final VoidCallback? onTutorialTap;
  final VoidCallback? onEmergencyFlareTap;
  final VoidCallback? onProTap;

  /// Human-readable tier label for the current difficulty.
  String get tierName {
    switch (difficultyTier) {
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

  /// Compact sector identifier badge displayed in the unified top bar.
  String get sectorBadgeText {
    if (sectorId >= 19) return 'SWARM • S$sectorId';
    if (sectorId >= 10) return 'DRIFT • S$sectorId';
    return 'S$sectorId';
  }

  /// Extracts the uppercase initial for the Gmail-style pilot avatar badge.
  String get pilotInitial {
    final profile = userProfile;
    if (profile != null) {
      final googleName = profile.googleDisplayName?.trim();
      if (profile.isGoogleLinked &&
          googleName != null &&
          googleName.isNotEmpty) {
        return googleName.substring(0, 1).toUpperCase();
      }
      final callsign = profile.callsign.trim();
      if (callsign.isNotEmpty) {
        return callsign.substring(0, 1).toUpperCase();
      }
    }
    return 'V';
  }

  /// Formats raw score into 6-digit grouped typography (e.g. 034,820).
  static String formatScore(int score) {
    final clamped = score.clamp(0, 999999);
    final str = clamped.toString().padLeft(6, '0');
    return '${str.substring(0, 3)},${str.substring(3)}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('unified_top_hud_bar'),
      height: 38.0,
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3.0),
      padding: const EdgeInsets.symmetric(horizontal: 6.0),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withValues(alpha: 0.90),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: const Color(0xFF1E293B), width: 1.0),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 1. Gmail-style Pilot Profile Avatar Icon (leftmost control)
          _buildProfileAvatarButton(),
          _buildDivider(),

          // 2. Prominent Glowing Star Map Button & Direct Special Ops Shortcut
          if (onMapTap != null) ...[
            _buildStarMapButton(),
            const SizedBox(width: 4.0),
          ],
          if (onSpecialOpsTap != null || onMapTap != null) ...[
            _buildSpecialOpsButton(),
            _buildDivider(),
          ],

          // 3. Compact Sector & Score Display
          Expanded(flex: 32, child: _buildSectorScoreSection()),
          _buildDivider(),

          // 4. Compact Pro / Boost / AI Auto Status Badge
          Flexible(flex: 20, child: _buildProPill()),
          _buildDivider(),

          // 5. Cores & Shields Inline Telemetry
          Expanded(flex: 28, child: _buildCoresAndShieldsSection()),
          _buildDivider(),

          // 6. Tactical Pause / Resume Button
          _buildPauseButton(),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1.0,
      height: 18.0,
      margin: const EdgeInsets.symmetric(horizontal: 4.0),
      color: const Color(0xFF1E293B),
    );
  }

  Widget _buildProfileAvatarButton() {
    final isLinked = userProfile?.isGoogleLinked ?? false;
    return GestureDetector(
      key: const Key('hud_profile_avatar'),
      behavior: HitTestBehavior.opaque,
      onTap: onProfileTap,
      child: Tooltip(
        message: 'Pilot Profile',
        child: SizedBox(
          width: 28.0,
          height: 36.0,
          child: Center(
            child: Container(
              width: 24.0,
              height: 24.0,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isLinked
                      ? const [Color(0xFF0284C7), Color(0xFF1D4ED8)]
                      : const [Color(0xFF0E7490), Color(0xFF1E293B)],
                ),
                border: Border.all(
                  color: isLinked
                      ? VoidTheme.solarGold
                      : const Color(0xFF38BDF8).withValues(alpha: 0.85),
                  width: 1.2,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                pilotInitial,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11.0,
                  fontWeight: FontWeight.w900,
                  height: 1.0,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStarMapButton() {
    return GestureDetector(
      key: const Key('hud_map_button'),
      behavior: HitTestBehavior.opaque,
      onTap: onMapTap,
      child: Tooltip(
        message: 'Star Map',
        child: SizedBox(
          key: const Key('hud_back_button'),
          width: 28.0,
          height: 36.0,
          child: Center(
            child: Container(
              width: 24.0,
              height: 24.0,
              decoration: BoxDecoration(
                color: const Color(0xFF032541),
                borderRadius: BorderRadius.circular(7.0),
                border: Border.all(color: const Color(0xFF00F0FF), width: 1.1),
                boxShadow: const [
                  BoxShadow(color: Color(0x4400F0FF), blurRadius: 5.0),
                ],
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.public,
                color: Color(0xFF00F0FF),
                size: 14.0,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSpecialOpsButton() {
    return GestureDetector(
      key: const Key('hud_special_ops_button'),
      behavior: HitTestBehavior.opaque,
      onTap: onSpecialOpsTap ?? onMapTap,
      child: Tooltip(
        message: 'Special Ops',
        child: SizedBox(
          width: 28.0,
          height: 36.0,
          child: Center(
            child: Container(
              width: 24.0,
              height: 24.0,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF4C1D95), Color(0xFF7C3AED)],
                ),
                borderRadius: BorderRadius.circular(7.0),
                border: Border.all(
                  color: VoidTheme.solarGold.withValues(alpha: 0.85),
                  width: 1.1,
                ),
                boxShadow: const [
                  BoxShadow(color: Color(0x557C3AED), blurRadius: 5.0),
                ],
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.bolt,
                color: VoidTheme.solarGold,
                size: 14.0,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectorScoreSection() {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onProfileTap,
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 5.0,
                  vertical: 2.0,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(5.0),
                ),
                child: Text(
                  sectorBadgeText,
                  maxLines: 1,
                  style: TextStyle(
                    color: isAutoSolving
                        ? VoidTheme.crimsonFlare
                        : const Color(0xFF38BDF8),
                    fontSize: 9.0,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              const SizedBox(width: 6.0),
              Text(
                isAiAssisted ? 'AI SIM' : formatScore(score),
                maxLines: 1,
                style: TextStyle(
                  color: isAiAssisted ? VoidTheme.crimsonFlare : Colors.white,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.3,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProPill() {
    return _ProSlimlinePill(
      isPro: isPro,
      isAutoSolving: isAutoSolving,
      isPaused: isPaused,
      onTap: isAutoSolving ? (onToggleAutoSolve ?? onProTap) : onProTap,
    );
  }

  Widget _buildCoresAndShieldsSection() {
    final bool unlimited = isUnlimitedCores || reserveCores >= 9000;
    final bool isCritical = reserveCores <= 3 && !unlimited;
    final coreColor = unlimited
        ? VoidTheme.solarGold
        : (isCritical ? VoidTheme.crimsonFlare : const Color(0xFFFBBF24));

    final remaining = invadersRemaining ?? 0;
    final total = totalInvaders ?? 0;
    final shieldLabel = total > 0
        ? '$remaining/$total'
        : (invadersRemaining != null ? '$remaining' : '2/2');

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: isCritical ? onEmergencyFlareTap : null,
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Cores indicator (dot + value)
              Container(
                width: 6.5,
                height: 6.5,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const RadialGradient(
                    colors: [Color(0xFFFDE68A), Color(0xFFD97706)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.8),
                      blurRadius: 3.0,
                      spreadRadius: 0.5,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4.0),
              Text(
                unlimited ? '∞' : '$reserveCores',
                style: TextStyle(
                  color: coreColor,
                  fontSize: 11.0,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: 8.0),
              // Hostiles / Shields indicator (icon + value)
              const Icon(Icons.shield, size: 11.0, color: Color(0xFF38BDF8)),
              const SizedBox(width: 3.0),
              Text(
                shieldLabel,
                style: const TextStyle(
                  color: Color(0xFFE0F2FE),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPauseButton() {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTogglePause,
      child: SizedBox(
        width: 28.0,
        height: 36.0,
        child: Center(
          child: Icon(
            isPaused ? Icons.play_arrow : Icons.pause,
            size: 17.0,
            color: isPaused ? VoidTheme.emeraldShield : const Color(0xFF94A3B8),
          ),
        ),
      ),
    );
  }
}

class _ProSlimlinePill extends StatefulWidget {
  const _ProSlimlinePill({
    required this.isPro,
    this.isAutoSolving = false,
    this.isPaused = false,
    required this.onTap,
  });

  final bool isPro;
  final bool isAutoSolving;
  final bool isPaused;
  final VoidCallback? onTap;

  @override
  State<_ProSlimlinePill> createState() => _ProSlimlinePillState();
}

class _ProSlimlinePillState extends State<_ProSlimlinePill>
    with WidgetsBindingObserver {
  Timer? _countdownTimer;
  bool _isAppResumed = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _syncTimer();
    EntitlementService.instance.addListener(_handleEntitlementChanged);
  }

  @override
  void didUpdateWidget(covariant _ProSlimlinePill oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncTimer();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _isAppResumed = state == AppLifecycleState.resumed;
    _syncTimer();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _countdownTimer?.cancel();
    EntitlementService.instance.removeListener(_handleEntitlementChanged);
    super.dispose();
  }

  void _handleEntitlementChanged() {
    if (mounted) {
      _syncTimer();
      setState(() {});
    }
  }

  void _syncTimer() {
    final isBoost = EntitlementService.instance.isBoostActive;
    if (isBoost && !widget.isPaused && _isAppResumed) {
      _countdownTimer ??= Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        if (!EntitlementService.instance.isBoostActive ||
            widget.isPaused ||
            !_isAppResumed) {
          _countdownTimer?.cancel();
          _countdownTimer = null;
        }
        setState(() {});
      });
    } else {
      _countdownTimer?.cancel();
      _countdownTimer = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isAutoSolving) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 3.0),
          decoration: BoxDecoration(
            color: const Color(0xFF280A14).withValues(alpha: 0.90),
            borderRadius: BorderRadius.circular(7.0),
            border: Border.all(color: VoidTheme.crimsonFlare, width: 1.0),
          ),
          child: const FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.smart_toy,
                  size: 11.0,
                  color: VoidTheme.crimsonFlare,
                ),
                SizedBox(width: 3.0),
                Text(
                  'AI AUTO',
                  style: TextStyle(
                    color: VoidTheme.crimsonFlare,
                    fontSize: 8.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final ent = EntitlementService.instance;
    final isLifetime = widget.isPro || ent.isProUnlocked;
    final isBoost = !isLifetime && ent.isBoostActive;

    if (isBoost) {
      final timerStr = ent.formattedRemainingBoostTime;

      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 3.0),
          decoration: BoxDecoration(
            color: const Color(0xFF201503).withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(7.0),
            border: Border.all(color: const Color(0xFFF59E0B), width: 1.0),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.bolt, size: 11.0, color: Color(0xFFF59E0B)),
                const SizedBox(width: 2.0),
                Text(
                  timerStr,
                  style: const TextStyle(
                    color: Color(0xFFFEF3C7),
                    fontSize: 9.0,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (isLifetime) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 3.0),
          decoration: BoxDecoration(
            color: const Color(0xFF201503).withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(7.0),
            border: Border.all(color: const Color(0xFFF59E0B), width: 1.0),
          ),
          child: const FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.workspace_premium,
                  size: 11.0,
                  color: Color(0xFFF59E0B),
                ),
                SizedBox(width: 3.0),
                Text(
                  'PRO',
                  style: TextStyle(
                    color: Color(0xFFFBBF24),
                    fontSize: 8.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Non-pro user: compact single-line badge with lock icon
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 3.0),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B).withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(7.0),
          border: Border.all(
            color: const Color(0xFFF59E0B).withValues(alpha: 0.5),
            width: 1.0,
          ),
        ),
        child: const FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock_outline, size: 10.0, color: Color(0xFFF59E0B)),
              SizedBox(width: 3.0),
              Text(
                'PRO',
                style: TextStyle(
                  color: Color(0xFFF59E0B),
                  fontSize: 8.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
