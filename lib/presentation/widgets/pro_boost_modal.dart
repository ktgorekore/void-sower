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

import '../../domain/services/entitlement_service.dart';
import '../services/haptic_service.dart';
import '../theme/void_theme.dart';
import 'tactile_button.dart';

/// Modal dialog displaying active Pro Boost countdown, 12-segment stackable
/// battery gauge, and rapid voluntary rewarded ad CTA to stack +5m up to 60m.
class ProBoostModal extends StatefulWidget {
  const ProBoostModal({super.key, this.onBoostUpdated});

  final VoidCallback? onBoostUpdated;

  @override
  State<ProBoostModal> createState() => _ProBoostModalState();
}

class _ProBoostModalState extends State<ProBoostModal> {
  Timer? _countdownTimer;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
    EntitlementService.instance.addListener(_onEntitlementChanged);
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    EntitlementService.instance.removeListener(_onEntitlementChanged);
    super.dispose();
  }

  void _onEntitlementChanged() {
    if (mounted) {
      _startTimer();
      setState(() {});
    }
  }

  void _startTimer() {
    if (EntitlementService.instance.isBoostActive) {
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

  Future<void> _handleWatchAd() async {
    HapticService.instance.injectionClick();
    setState(() => _isLoading = true);

    final success = await EntitlementService.instance.unlockWithRewardedAd();

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        widget.onBoostUpdated?.call();
        final mins = EntitlementService.instance.boostMinutesRemaining;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '⚡ +5 MIN PRO OVERCHARGE ACTIVE! ($mins/60m Stacked • Unlimited Incursion Cores)',
              style: const TextStyle(
                fontFamily: 'monospace',
                fontWeight: FontWeight.bold,
              ),
            ),
            backgroundColor: VoidTheme.solarGold,
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Holo-transmission unavailable. Please try again shortly.',
              style: TextStyle(fontFamily: 'monospace'),
            ),
            backgroundColor: VoidTheme.crimsonFlare,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _handlePurchaseLifetime() async {
    HapticService.instance.injectionClick();
    setState(() => _isLoading = true);

    final outcome = await EntitlementService.instance.purchaseProLifetime();

    if (mounted) {
      setState(() => _isLoading = false);
      if (outcome.isSuccess) {
        widget.onBoostUpdated?.call();
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'PRO COMMANDER UNLOCKED: Lifetime unlimited access & zero ads!',
              style: TextStyle(
                fontFamily: 'monospace',
                fontWeight: FontWeight.bold,
              ),
            ),
            backgroundColor: VoidTheme.solarGold,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ent = EntitlementService.instance;
    final isLifetime = ent.isProUnlocked;
    final isBoost = ent.isBoostActive;
    final litSegments = ent.boostSegmentsLit;
    final mins = ent.boostMinutesRemaining;
    final isMax = ent.isMaxBoostReached;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(
        horizontal: 16.0,
        vertical: 24.0,
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(20.0),
        decoration: VoidTheme.glassmorphic(
          borderColor: isLifetime
              ? VoidTheme.solarGold
              : (isBoost ? VoidTheme.plasmaCyan : VoidTheme.solarGold),
          borderWidth: 1.8,
          borderRadius: 16.0,
        ),
        child: Material(
          type: MaterialType.transparency,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Row
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8.0),
                    decoration: BoxDecoration(
                      color: isLifetime
                          ? VoidTheme.solarGold
                          : (isBoost
                                ? VoidTheme.plasmaCyan
                                : VoidTheme.solarGold),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isLifetime ? Icons.workspace_premium : Icons.bolt,
                      color: VoidTheme.obsidianBlack,
                      size: 22.0,
                    ),
                  ),
                  const SizedBox(width: 12.0),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'PRO TEMPORAL OVERCHARGE',
                          style: TextStyle(
                            color: VoidTheme.solarGold,
                            fontSize: 13.0,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.0,
                          ),
                        ),
                        Text(
                          isLifetime
                              ? 'Permanent Lifetime License Active'
                              : isBoost
                              ? 'Active Boost: ${ent.formattedRemainingBoostTime}'
                              : 'Boost Inactive — Stack up to 60 Mins',
                          style: TextStyle(
                            color: isLifetime
                                ? VoidTheme.solarGold
                                : (isBoost
                                      ? VoidTheme.plasmaCyan
                                      : VoidTheme.textSecondary),
                            fontSize: 11.0,
                            fontWeight: FontWeight.bold,
                            fontFamily: isBoost ? 'monospace' : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: VoidTheme.textMuted,
                      size: 20,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const Divider(
                color: VoidTheme.cardSurface,
                thickness: 1.0,
                height: 22.0,
              ),

              // Battery Gauge Section
              if (!isLifetime) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14.0,
                    vertical: 10.0,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF070E1E),
                    borderRadius: BorderRadius.circular(10.0),
                    border: Border.all(
                      color: VoidTheme.plasmaCyan.withValues(alpha: 0.4),
                      width: 1.0,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(
                                Icons.battery_charging_full,
                                color: VoidTheme.solarGold,
                                size: 14.0,
                              ),
                              SizedBox(width: 4.0),
                              Text(
                                'OVERCHARGE BATTERY',
                                style: TextStyle(
                                  color: VoidTheme.starWhite,
                                  fontSize: 10.0,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            isMax ? 'MAX (60m)' : '$mins / 60 MIN',
                            style: TextStyle(
                              color: isMax
                                  ? VoidTheme.emeraldShield
                                  : VoidTheme.plasmaCyan,
                              fontSize: 10.0,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8.0),
                      // 12-segment battery pips
                      Row(
                        children: List.generate(12, (index) {
                          final isLit = index < litSegments;
                          return Expanded(
                            child: Container(
                              height: 6.0,
                              margin: EdgeInsets.only(
                                right: index < 11 ? 2.5 : 0.0,
                              ),
                              decoration: BoxDecoration(
                                color: isLit
                                    ? VoidTheme.solarGold
                                    : const Color(0xFF1E293B),
                                borderRadius: BorderRadius.circular(2.0),
                                boxShadow: isLit
                                    ? [
                                        BoxShadow(
                                          color: VoidTheme.solarGold.withValues(
                                            alpha: 0.6,
                                          ),
                                          blurRadius: 4.0,
                                        ),
                                      ]
                                    : null,
                              ),
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12.0),
              ],

              // Explanatory Lore
              Text(
                isLifetime
                    ? 'All Pro privileges are permanently unlocked on your vessel: unlimited cores in Void Incursion, MCTS tactical advisor, Chrono-Anchor rewinds, and zero ads.'
                    : 'Pro Boost unlocks full Pro Commander privileges: UNLIMITED CORES in Void Incursion mode, MCTS AI move advisory, and advanced tactical rewinds. Each holo-transmission adds +5 minutes, stackable up to 60 minutes.',
                style: const TextStyle(
                  color: VoidTheme.starWhite,
                  fontSize: 11.5,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 16.0),

              // Actions
              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(12.0),
                    child: CircularProgressIndicator(
                      color: VoidTheme.solarGold,
                    ),
                  ),
                )
              else if (!isLifetime) ...[
                TactileButton(
                  label: isMax ? 'BOOST FULL (60m)' : 'WATCH AD (+5m BOOST)',
                  icon: Icons.play_circle_filled,
                  accentColor: isMax
                      ? VoidTheme.cardSurface
                      : VoidTheme.emeraldShield,
                  height: 44.0,
                  onPressed: isMax ? null : _handleWatchAd,
                ),
                const SizedBox(height: 8.0),
                TactileButton(
                  label: 'UNLOCK LIFETIME PRO — \$1.29',
                  icon: Icons.workspace_premium,
                  accentColor: VoidTheme.solarGold,
                  height: 44.0,
                  onPressed: _handlePurchaseLifetime,
                ),
              ] else ...[
                TactileButton(
                  label: 'CLOSE',
                  accentColor: VoidTheme.solarGold,
                  height: 44.0,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
