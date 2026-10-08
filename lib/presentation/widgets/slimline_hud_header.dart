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

/// Ultra-compact 38px Slimline HUD Header matching the UX 3.0 specification.
///
/// Lays out five self-contained glassmorphic telemetry capsules in a single
/// horizontal row:
/// 1. Sector Badge & Score capsule (e.g. "S1 • ZANZIBAR", "034,820").
/// 2. Pro Status / Boost Countdown capsule (e.g. "PRO BOOST 14:28", "★ PRO", "🔒 PRO").
/// 3. Reactor Cores stored gauge (e.g. "⚡ 36 CORES").
/// 4. Canopy Shield / Hostiles counter (e.g. "🛡️ 2/2").
/// 5. Single-tap tactical pause toggle button.
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
  final VoidCallback? onRestartTap;
  final VoidCallback? onStopTap;
  final VoidCallback? onCodexTap;
  final VoidCallback? onTutorialTap;
  final VoidCallback? onEmergencyFlareTap;
  final VoidCallback? onProTap;

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

  String get sectorBadgeText {
    if (sectorId >= 19) return 'SWARM • S$sectorId';
    if (sectorId >= 10) return 'DRIFT • S$sectorId';
    if (sectorId == 1) return 'S1 • ZANZIBAR';
    return 'S$sectorId • $tierName';
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
      height: 38.0,
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (onMapTap != null) ...[
            _buildBackButton(),
            const SizedBox(width: 5.0),
          ],

          // 1. Sector Badge & Score Pill (flex: 28)
          Expanded(flex: 28, child: _buildSectorScorePill()),
          const SizedBox(width: 5.0),

          // 2. Pro Status / Countdown Timer Badge (flex: 24)
          Expanded(flex: 24, child: _buildProPill()),
          const SizedBox(width: 5.0),

          // 3. Reactor Cores Stored (flex: 20)
          Expanded(flex: 20, child: _buildCoresPill()),
          const SizedBox(width: 5.0),

          // 4. Canopy Shield / Hostiles (flex: 15)
          Expanded(flex: 15, child: _buildShieldPill()),
          const SizedBox(width: 5.0),

          // 5. Pause Button (flex: 13)
          Expanded(flex: 13, child: _buildPauseButton()),
        ],
      ),
    );
  }

  Widget _buildBackButton() {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onMapTap,
      child: Container(
        width: 34.0,
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A).withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(10.0),
          border: Border.all(color: const Color(0xFF1E293B), width: 1.0),
        ),
        alignment: Alignment.center,
        child: const Icon(
          Icons.arrow_back_ios_new,
          color: Color(0xFF38BDF8),
          size: 13.0,
        ),
      ),
    );
  }

  Widget _buildSectorScorePill() {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onProfileTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A).withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(10.0),
          border: Border.all(color: const Color(0xFF1E293B), width: 1.0),
        ),
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.center,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  sectorBadgeText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF38BDF8),
                    fontSize: 7.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 1.0),
                Text(
                  formatScore(score),
                  maxLines: 1,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11.0,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.3,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProPill() {
    return _ProSlimlinePill(isPro: isPro, onTap: onProTap);
  }

  Widget _buildCoresPill() {
    final bool unlimited = isUnlimitedCores || reserveCores >= 9000;
    final bool isCritical = reserveCores <= 3 && !unlimited;
    final coreColor = unlimited
        ? VoidTheme.solarGold
        : (isCritical ? VoidTheme.crimsonFlare : const Color(0xFFFBBF24));

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: isCritical ? onEmergencyFlareTap : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A).withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(10.0),
          border: Border.all(
            color: const Color(0xFFD97706).withValues(alpha: 0.45),
            width: 1.0,
          ),
        ),
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 6.0,
                      height: 6.0,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const RadialGradient(
                          colors: [Color(0xFFFDE68A), Color(0xFFD97706)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFFF59E0B,
                            ).withValues(alpha: 0.8),
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
                  ],
                ),
                const SizedBox(height: 1.0),
                const Text(
                  'CORES',
                  style: TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 7.0,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildShieldPill() {
    final remaining = invadersRemaining ?? 0;
    final total = totalInvaders ?? 0;
    final label = total > 0
        ? '$remaining/$total'
        : (invadersRemaining != null ? '$remaining' : '2/2');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(
          color: const Color(0xFF0284C7).withValues(alpha: 0.45),
          width: 1.0,
        ),
      ),
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.shield,
                    size: 10.0,
                    color: Color(0xFF38BDF8),
                  ),
                  const SizedBox(width: 3.0),
                  Text(
                    label,
                    style: const TextStyle(
                      color: Color(0xFFE0F2FE),
                      fontSize: 10.0,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 1.0),
              const Text(
                'SHIELDS',
                style: TextStyle(
                  color: Color(0xFF38BDF8),
                  fontSize: 7.0,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.4,
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
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A).withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(10.0),
          border: Border.all(
            color: isPaused ? VoidTheme.emeraldShield : const Color(0xFF1E293B),
            width: 1.0,
          ),
        ),
        child: Icon(
          isPaused ? Icons.play_arrow : Icons.pause,
          size: 16.0,
          color: isPaused ? VoidTheme.emeraldShield : const Color(0xFF94A3B8),
        ),
      ),
    );
  }
}

class _ProSlimlinePill extends StatefulWidget {
  const _ProSlimlinePill({required this.isPro, required this.onTap});

  final bool isPro;
  final VoidCallback? onTap;

  @override
  State<_ProSlimlinePill> createState() => _ProSlimlinePillState();
}

class _ProSlimlinePillState extends State<_ProSlimlinePill> {
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _syncTimer();
    EntitlementService.instance.addListener(_handleEntitlementChanged);
  }

  @override
  void didUpdateWidget(covariant _ProSlimlinePill oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncTimer();
  }

  @override
  void dispose() {
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
    if (isBoost) {
      _countdownTimer ??= Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        if (!EntitlementService.instance.isBoostActive) {
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
    final ent = EntitlementService.instance;
    final isLifetime = widget.isPro || ent.isProUnlocked;
    final isBoost = !isLifetime && ent.isBoostActive;

    if (isBoost) {
      final timerStr = ent.formattedRemainingBoostTime;

      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6.0),
          decoration: BoxDecoration(
            color: const Color(0xFF201503).withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(10.0),
            border: Border.all(color: const Color(0xFFF59E0B), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.35),
                blurRadius: 6.0,
              ),
            ],
          ),
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.center,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 10.0,
                    height: 10.0,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFFF59E0B),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.bolt,
                        size: 8.0,
                        color: Color(0xFF05070F),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4.0),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'PRO BOOST',
                        style: TextStyle(
                          color: Color(0xFFFBBF24),
                          fontSize: 7.0,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.3,
                        ),
                      ),
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
                ],
              ),
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
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          decoration: BoxDecoration(
            color: const Color(0xFF201503).withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(10.0),
            border: Border.all(color: const Color(0xFFF59E0B), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.25),
                blurRadius: 4.0,
              ),
            ],
          ),
          child: const Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.center,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(
                    Icons.workspace_premium,
                    size: 12.0,
                    color: Color(0xFFF59E0B),
                  ),
                  SizedBox(width: 4.0),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'PRO PILOT',
                        style: TextStyle(
                          color: Color(0xFFFBBF24),
                          fontSize: 7.0,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.3,
                        ),
                      ),
                      Text(
                        'ACTIVE ★',
                        style: TextStyle(
                          color: Color(0xFFFEF3C7),
                          fontSize: 9.0,
                          fontWeight: FontWeight.w900,
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
    }

    // Non-pro user: compact subtle pill with lock icon
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A).withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(10.0),
          border: Border.all(
            color: const Color(0xFFF59E0B).withValues(alpha: 0.5),
            width: 1.0,
          ),
        ),
        child: const Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.center,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(Icons.lock_outline, size: 11.0, color: Color(0xFFF59E0B)),
                SizedBox(width: 4.0),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'PRO',
                      style: TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 7.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      'UNLOCK ⚡',
                      style: TextStyle(
                        color: Color(0xFFF59E0B),
                        fontSize: 9.0,
                        fontWeight: FontWeight.w900,
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
  }
}
