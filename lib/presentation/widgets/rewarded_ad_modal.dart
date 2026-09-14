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

import '../../config/ad_config.dart';
import '../../domain/services/ad_service.dart';
import '../../domain/services/persistence_service.dart';
import '../services/haptic_service.dart';
import '../theme/void_theme.dart';
import 'tactile_button.dart';

/// Modal dialog prompting the pilot for an Emergency Reactor Charge (+8 Cores).
class RewardedAdModal extends StatefulWidget {
  const RewardedAdModal({super.key, required this.onCoresGranted});

  final void Function(int cores) onCoresGranted;

  @override
  State<RewardedAdModal> createState() => _RewardedAdModalState();
}

class _RewardedAdModalState extends State<RewardedAdModal> {
  bool _isLoading = false;

  Future<void> _claimEmergencyFlare() async {
    HapticService.instance.injectionClick();
    setState(() => _isLoading = true);

    final success = await AdService.instance.showRewardedAd();

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        widget.onCoresGranted(AdConfig.emergencyCoresReward);
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'EMERGENCY FLARE RECEIVED: +8 Plasma Cores Injected!',
              style: TextStyle(
                fontFamily: 'monospace',
                fontWeight: FontWeight.bold,
              ),
            ),
            backgroundColor: VoidTheme.solarGold,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Orbital transmission unavailable. Please try again shortly.',
              style: TextStyle(fontFamily: 'monospace'),
            ),
            backgroundColor: VoidTheme.crimsonFlare,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPro = PersistenceService.instance.isProUnlocked;
    final canRequest = AdService.instance.canRequestEmergencyFlare;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(
        horizontal: 16.0,
        vertical: 24.0,
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 440),
        padding: const EdgeInsets.all(20.0),
        decoration: VoidTheme.glassmorphic(
          borderColor: VoidTheme.crimsonFlare,
          borderWidth: 2.0,
          borderRadius: 16.0,
        ),
        child: Material(
          type: MaterialType.transparency,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8.0),
                    decoration: const BoxDecoration(
                      color: VoidTheme.crimsonFlare,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.warning_amber_rounded,
                      color: VoidTheme.starWhite,
                      size: 24.0,
                    ),
                  ),
                  const SizedBox(width: 12.0),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CRITICAL REACTOR DEPLETION',
                          style: TextStyle(
                            color: VoidTheme.crimsonFlare,
                            fontSize: 13.0,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                          ),
                        ),
                        Text(
                          'Emergency Orbital Flare Available',
                          style: TextStyle(
                            color: VoidTheme.solarGold,
                            fontSize: 11.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(
                color: VoidTheme.cardSurface,
                thickness: 1.0,
                height: 24.0,
              ),

              // Lore / Description
              Text(
                isPro
                    ? 'PRO COMMANDER PRIVILEGE: Summon an instantaneous +${AdConfig.emergencyCoresReward} plasma core relay from the Kilwa flagship without viewing transmissions.'
                    : 'Siphon auxiliary energy reserves from the orbital fleet. Sponsoring this emergency broadcast will immediately deliver +${AdConfig.emergencyCoresReward} plasma cores into your active capacitor ring.',
                style: const TextStyle(
                  color: VoidTheme.starWhite,
                  fontSize: 12.0,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 16.0),

              // Status Badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12.0,
                  vertical: 8.0,
                ),
                decoration: BoxDecoration(
                  color: VoidTheme.cardSurface,
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(
                    color: isPro ? VoidTheme.solarGold : VoidTheme.plasmaCyan,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        isPro
                            ? 'TIER: PRO COMMANDER'
                            : 'TRANSMISSION: REWARDED AD',
                        style: TextStyle(
                          color: isPro
                              ? VoidTheme.solarGold
                              : VoidTheme.plasmaCyan,
                          fontSize: 10.0,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8.0),
                    Text(
                      '+${AdConfig.emergencyCoresReward} CORES',
                      style: const TextStyle(
                        color: VoidTheme.solarGold,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20.0),

              // Actions
              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: CircularProgressIndicator(
                      color: VoidTheme.solarGold,
                    ),
                  ),
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: TactileButton(
                        label: 'DECLINE',
                        accentColor: VoidTheme.starWhite,
                        height: 44.0,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8.0,
                          vertical: 8.0,
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                    const SizedBox(width: 10.0),
                    Expanded(
                      child: TactileButton(
                        label: isPro ? 'SUMMON FLARE' : 'CHANNEL (+8)',
                        icon: isPro ? Icons.bolt : Icons.ondemand_video,
                        accentColor: canRequest
                            ? VoidTheme.solarGold
                            : VoidTheme.cardSurface,
                        height: 44.0,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8.0,
                          vertical: 8.0,
                        ),
                        onPressed: canRequest ? _claimEmergencyFlare : null,
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
