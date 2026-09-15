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

import '../../domain/models/pro_feature.dart';
import '../../domain/services/entitlement_service.dart';
import '../services/haptic_service.dart';
import '../theme/void_theme.dart';
import 'tactile_button.dart';

/// Afrofuturistic glassmorphic showcase modal for the $1.29 Pro Lifetime purchase
/// and rewarded transmission temporary access pass.
class ProUpgradeModal extends StatefulWidget {
  const ProUpgradeModal({super.key, this.highlightedFeature, this.onUnlocked});

  final ProFeature? highlightedFeature;
  final VoidCallback? onUnlocked;

  @override
  State<ProUpgradeModal> createState() => _ProUpgradeModalState();
}

class _ProUpgradeModalState extends State<ProUpgradeModal> {
  bool _isProcessing = false;

  Future<void> _handlePurchase() async {
    HapticService.instance.injectionClick();
    setState(() => _isProcessing = true);

    final success = await EntitlementService.instance.purchaseProLifetime();

    if (mounted) {
      setState(() => _isProcessing = false);
      if (success) {
        widget.onUnlocked?.call();
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'PRO COMMANDER UNLOCKED: All features, flagships & ad-free access granted!',
              style: TextStyle(
                fontFamily: 'monospace',
                fontWeight: FontWeight.bold,
              ),
            ),
            backgroundColor: VoidTheme.solarGold,
          ),
        );
      }
    }
  }

  Future<void> _handleWatchAd() async {
    final feature = widget.highlightedFeature ?? ProFeature.aiTacticalSolver;
    HapticService.instance.injectionClick();
    setState(() => _isProcessing = true);

    final success = await EntitlementService.instance.unlockWithRewardedAd(
      feature,
    );

    if (mounted) {
      setState(() => _isProcessing = false);
      if (success) {
        widget.onUnlocked?.call();
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'TEMPORARY PASS GRANTED: ${ProFeatureMeta.registry[feature]?.title ?? 'Feature'} unlocked for session!',
              style: const TextStyle(
                fontFamily: 'monospace',
                fontWeight: FontWeight.bold,
              ),
            ),
            backgroundColor: VoidTheme.plasmaCyan,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Transmission unavailable. Please try again shortly.',
              style: TextStyle(fontFamily: 'monospace'),
            ),
            backgroundColor: VoidTheme.crimsonFlare,
          ),
        );
      }
    }
  }

  Future<void> _handleRestore() async {
    HapticService.instance.sowTick();
    setState(() => _isProcessing = true);
    await EntitlementService.instance.restorePurchases();
    if (mounted) {
      setState(() => _isProcessing = false);
      if (EntitlementService.instance.isProUnlocked) {
        widget.onUnlocked?.call();
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'PURCHASES RESTORED: Welcome back, Pro Commander.',
              style: TextStyle(fontFamily: 'monospace'),
            ),
            backgroundColor: VoidTheme.solarGold,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No previous Pro purchases found for this account.',
              style: TextStyle(fontFamily: 'monospace'),
            ),
            backgroundColor: VoidTheme.cardSurface,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final highlighted = widget.highlightedFeature;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(
        horizontal: 16.0,
        vertical: 20.0,
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 680),
        decoration: VoidTheme.glassmorphic(
          borderColor: VoidTheme.solarGold,
          borderWidth: 1.8,
          borderRadius: 20.0,
        ),
        padding: const EdgeInsets.all(20.0),
        child: Material(
          type: MaterialType.transparency,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8.0),
                    decoration: BoxDecoration(
                      color: VoidTheme.solarGold.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: VoidTheme.solarGold,
                        width: 1.5,
                      ),
                    ),
                    child: const Icon(
                      Icons.workspace_premium,
                      color: VoidTheme.solarGold,
                      size: 24.0,
                    ),
                  ),
                  const SizedBox(width: 12.0),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'PRO COMMANDER FLEET',
                          style: TextStyle(
                            color: VoidTheme.solarGold,
                            fontSize: 15.0,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                          ),
                        ),
                        Text(
                          'Lifetime License • \$1.29 One-Time',
                          style: TextStyle(
                            color: VoidTheme.plasmaCyan,
                            fontSize: 11.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: VoidTheme.textSecondary,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const Divider(color: VoidTheme.cardSurface, height: 20.0),

              // Feature List
              Expanded(
                child: ListView(
                  children: [
                    if (highlighted != null) ...[
                      _buildFeatureCard(highlighted, isHighlighted: true),
                      const SizedBox(height: 10.0),
                      const Center(
                        child: Text(
                          'ALL PRO FEATURES INCLUDED:',
                          style: TextStyle(
                            color: VoidTheme.textMuted,
                            fontSize: 9.5,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8.0),
                    ],
                    for (final feature in ProFeature.values)
                      if (feature != highlighted)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: _buildFeatureCard(feature),
                        ),
                  ],
                ),
              ),
              const SizedBox(height: 14.0),

              // Action Buttons
              if (_isProcessing)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(12.0),
                    child: CircularProgressIndicator(
                      color: VoidTheme.solarGold,
                    ),
                  ),
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Primary 1-Time Purchase CTA
                    TactileButton(
                      label: 'UNLOCK PRO COMMANDER — \$1.29',
                      icon: Icons.lock_open,
                      accentColor: VoidTheme.solarGold,
                      height: 46.0,
                      onPressed: _handlePurchase,
                    ),
                    const SizedBox(height: 8.0),

                    // Contextual Rewarded Ad Option
                    if (highlighted != null) ...[
                      TactileButton(
                        label: 'WATCH TRANSMISSION (FREE PASS)',
                        icon: Icons.ondemand_video,
                        accentColor: VoidTheme.plasmaCyan,
                        height: 42.0,
                        onPressed: _handleWatchAd,
                      ),
                      const SizedBox(height: 8.0),
                    ],

                    // Restore Purchases
                    TextButton(
                      onPressed: _handleRestore,
                      child: const Text(
                        'RESTORE PREVIOUS PURCHASES',
                        style: TextStyle(
                          color: VoidTheme.textMuted,
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
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

  Widget _buildFeatureCard(ProFeature feature, {bool isHighlighted = false}) {
    final meta = ProFeatureMeta.registry[feature]!;
    final borderColor = isHighlighted
        ? VoidTheme.solarGold
        : VoidTheme.cardSurface.withValues(alpha: 0.7);

    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: isHighlighted
            ? VoidTheme.solarGold.withValues(alpha: 0.12)
            : VoidTheme.cardSurface.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(
          color: borderColor,
          width: isHighlighted ? 1.5 : 1.0,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            meta.icon,
            color: isHighlighted ? VoidTheme.solarGold : VoidTheme.plasmaCyan,
            size: 20.0,
          ),
          const SizedBox(width: 10.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  meta.title,
                  style: TextStyle(
                    color: isHighlighted
                        ? VoidTheme.solarGold
                        : VoidTheme.textPrimary,
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 3.0),
                Text(
                  meta.shortDescription,
                  style: const TextStyle(
                    color: VoidTheme.textSecondary,
                    fontSize: 10.5,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
