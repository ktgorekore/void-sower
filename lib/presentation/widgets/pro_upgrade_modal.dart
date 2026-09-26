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

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../domain/models/pro_feature.dart';
import '../../domain/services/entitlement_service.dart';
import '../../domain/services/iap_service.dart';
import '../../domain/services/persistence_service.dart';
import '../services/haptic_service.dart';
import '../theme/void_theme.dart';
import 'tactile_button.dart';

/// Afrofuturistic glassmorphic showcase modal for the $1.29 Pro Lifetime purchase
/// and rewarded ad temporary access pass.
class ProUpgradeModal extends StatefulWidget {
  const ProUpgradeModal({super.key, this.highlightedFeature, this.onUnlocked});

  final ProFeature? highlightedFeature;
  final VoidCallback? onUnlocked;

  @override
  State<ProUpgradeModal> createState() => _ProUpgradeModalState();
}

class _ProUpgradeModalState extends State<ProUpgradeModal> {
  bool _isProcessing = false;
  late ProFeature _selectedFeature;

  @override
  void initState() {
    super.initState();
    _selectedFeature = widget.highlightedFeature ?? ProFeature.aiTacticalSolver;
  }

  Future<void> _handlePurchase() async {
    HapticService.instance.injectionClick();
    setState(() => _isProcessing = true);

    final outcome = await EntitlementService.instance.purchaseProLifetime();

    if (mounted) {
      setState(() => _isProcessing = false);
      if (outcome.isSuccess) {
        widget.onUnlocked?.call();
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
            duration: Duration(seconds: 2),
          ),
        );
        Navigator.of(context).pop();
      } else if (outcome.isCanceled) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'TRANSMISSION CANCELLED: Purchase was not completed.',
              style: TextStyle(fontFamily: 'monospace'),
            ),
            backgroundColor: VoidTheme.cardSurface,
            duration: Duration(seconds: 2),
          ),
        );
      } else if (outcome.isError) {
        if (kDebugMode &&
            (!IapService.instance.isAvailable ||
                outcome.errorMessage?.contains('unavailable') == true ||
                outcome.errorMessage?.contains('not found') == true)) {
          final simulate = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              backgroundColor: VoidTheme.obsidianBlack,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: VoidTheme.solarGold, width: 1.5),
              ),
              title: const Row(
                children: [
                  Icon(
                    Icons.developer_mode,
                    color: VoidTheme.solarGold,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'DEBUG EMULATOR SANDBOX',
                    style: TextStyle(
                      color: VoidTheme.solarGold,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Google Play Billing is unavailable on this emulator or test device (no Google account signed in).\n\nWould you like to simulate a successful Pro Commander purchase for testing?',
                    style: TextStyle(
                      color: VoidTheme.textPrimary,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: VoidTheme.cardSurface,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: VoidTheme.solarGold.withValues(alpha: 0.5),
                        width: 0.8,
                      ),
                    ),
                    child: const Text(
                      'SKU: void_sower_pro_lifetime (\$1.29 USD)',
                      style: TextStyle(
                        color: VoidTheme.plasmaCyan,
                        fontSize: 10.5,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: const Text(
                    'CANCEL',
                    style: TextStyle(color: VoidTheme.textSecondary),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: VoidTheme.solarGold,
                    foregroundColor: VoidTheme.obsidianBlack,
                  ),
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: const Text(
                    'SIMULATE PURCHASE',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          );

          if (!mounted) return;
          if (simulate == true) {
            await PersistenceService.instance.setProUnlocked(true);
            EntitlementService.instance.notifyEntitlementChanged();
            if (!mounted) return;
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
                duration: Duration(seconds: 2),
              ),
            );
            return;
          }
        } else {
          await showDialog<void>(
            context: context,
            builder: (ctx) => AlertDialog(
              backgroundColor: VoidTheme.obsidianBlack,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(
                  color: VoidTheme.crimsonFlare,
                  width: 1.5,
                ),
              ),
              title: const Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    color: VoidTheme.crimsonFlare,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'STORE BILLING UNAVAILABLE',
                    style: TextStyle(
                      color: VoidTheme.crimsonFlare,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
              content: Text(
                outcome.errorMessage ??
                    'Google Play Store billing is currently unavailable on this device. Please verify that Google Play Store is installed and signed into an active Google account.',
                style: const TextStyle(
                  color: VoidTheme.textPrimary,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text(
                    'DISMISS',
                    style: TextStyle(color: VoidTheme.plasmaCyan),
                  ),
                ),
              ],
            ),
          );
        }
      }
    }
  }

  Future<void> _handleWatchAd([ProFeature? feature]) async {
    final targetFeature =
        feature ?? widget.highlightedFeature ?? _selectedFeature;
    HapticService.instance.injectionClick();
    setState(() => _isProcessing = true);

    final success = await EntitlementService.instance.unlockWithRewardedAd(
      targetFeature,
    );

    if (mounted) {
      setState(() => _isProcessing = false);
      if (success) {
        widget.onUnlocked?.call();
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'FREE PASS GRANTED: ${ProFeatureMeta.registry[targetFeature]?.title ?? 'Feature'} unlocked for session!',
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
              'Ad unavailable. Please try again shortly.',
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
        if (!IapService.instance.isAvailable) {
          await showDialog<void>(
            context: context,
            builder: (ctx) => AlertDialog(
              backgroundColor: VoidTheme.obsidianBlack,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(
                  color: VoidTheme.crimsonFlare,
                  width: 1.5,
                ),
              ),
              title: const Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    color: VoidTheme.crimsonFlare,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'STORE BILLING UNAVAILABLE',
                    style: TextStyle(
                      color: VoidTheme.crimsonFlare,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
              content: const Text(
                'Google Play Store billing is currently unavailable on this device or emulator. Please verify Google Play Store is installed and signed into an active Google account.',
                style: TextStyle(
                  color: VoidTheme.textPrimary,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text(
                    'DISMISS',
                    style: TextStyle(color: VoidTheme.plasmaCyan),
                  ),
                ),
              ],
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
  }

  @override
  Widget build(BuildContext context) {
    final highlighted = widget.highlightedFeature ?? _selectedFeature;
    final targetFeature = highlighted;

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
                    TactileButton(
                      label: 'WATCH AD (FREE PASS)',
                      icon: Icons.ondemand_video,
                      accentColor: VoidTheme.plasmaCyan,
                      height: 42.0,
                      onPressed: () => _handleWatchAd(targetFeature),
                    ),
                    const SizedBox(height: 8.0),

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
    final isSelected = isHighlighted || (_selectedFeature == feature);
    final borderColor = isSelected
        ? VoidTheme.solarGold
        : VoidTheme.cardSurface.withValues(alpha: 0.7);

    return GestureDetector(
      onTap: () {
        HapticService.instance.sowTick();
        setState(() => _selectedFeature = feature);
      },
      child: Container(
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: isSelected
              ? VoidTheme.solarGold.withValues(alpha: 0.12)
              : VoidTheme.cardSurface.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(10.0),
          border: Border.all(color: borderColor, width: isSelected ? 1.5 : 1.0),
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
      ),
    );
  }
}
