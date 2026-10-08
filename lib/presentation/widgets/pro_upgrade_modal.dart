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
                  border: Border.all(color: VoidTheme.solarGold, width: 1.5),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x66000000),
                      blurRadius: 20.0,
                      offset: Offset(0, 6),
                    ),
                    BoxShadow(
                      color: Color(0x33F59E0B),
                      blurRadius: 16.0,
                      spreadRadius: -2,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 36.0,
                          height: 36.0,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: VoidTheme.solarGold.withValues(alpha: 0.15),
                            border: Border.all(
                              color: VoidTheme.solarGold,
                              width: 1.5,
                            ),
                          ),
                          child: const Icon(
                            Icons.developer_mode,
                            color: VoidTheme.solarGold,
                            size: 20.0,
                          ),
                        ),
                        const SizedBox(width: 12.0),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'SIMULATION ENVIRONMENT',
                                style: TextStyle(
                                  color: VoidTheme.solarGold,
                                  fontSize: 9.0,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              SizedBox(height: 2.0),
                              Text(
                                'DEBUG EMULATOR SANDBOX',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13.0,
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
                    Container(
                      height: 3.0,
                      decoration: BoxDecoration(
                        color: VoidTheme.solarGold,
                        borderRadius: BorderRadius.circular(1.5),
                        boxShadow: const [
                          BoxShadow(color: Color(0x80F59E0B), blurRadius: 6.0),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14.0),
                    const Text(
                      'Google Play Billing is unavailable on this emulator or test device (no Google account signed in).\n\nWould you like to simulate a successful Pro Commander purchase for testing?',
                      style: TextStyle(
                        color: Color(0xFFCBD5E1),
                        fontSize: 12.0,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 12.0),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10.0,
                        vertical: 8.0,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF070C18),
                        borderRadius: BorderRadius.circular(8.0),
                        border: Border.all(
                          color: VoidTheme.solarGold.withValues(alpha: 0.5),
                          width: 1.0,
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
                    const SizedBox(height: 18.0),
                    Row(
                      children: [
                        Expanded(
                          child: TactileButton(
                            label: 'CANCEL',
                            onPressed: () => Navigator.of(ctx).pop(false),
                            accentColor: const Color(0xFF64748B),
                            height: 42.0,
                            isPrimary: false,
                          ),
                        ),
                        const SizedBox(width: 10.0),
                        Expanded(
                          flex: 2,
                          child: TactileButton(
                            label: 'SIMULATE PURCHASE',
                            icon: Icons.check_circle_outline,
                            accentColor: VoidTheme.solarGold,
                            height: 42.0,
                            onPressed: () => Navigator.of(ctx).pop(true),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
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
                  border: Border.all(color: VoidTheme.crimsonFlare, width: 1.5),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x66000000),
                      blurRadius: 20.0,
                      offset: Offset(0, 6),
                    ),
                    BoxShadow(
                      color: Color(0x33EF4444),
                      blurRadius: 16.0,
                      spreadRadius: -2,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 36.0,
                          height: 36.0,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: VoidTheme.crimsonFlare.withValues(
                              alpha: 0.15,
                            ),
                            border: Border.all(
                              color: VoidTheme.crimsonFlare,
                              width: 1.5,
                            ),
                          ),
                          child: const Icon(
                            Icons.error_outline,
                            color: VoidTheme.crimsonFlare,
                            size: 20.0,
                          ),
                        ),
                        const SizedBox(width: 12.0),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'TRANSACTION FAILURE',
                                style: TextStyle(
                                  color: VoidTheme.crimsonFlare,
                                  fontSize: 9.0,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              SizedBox(height: 2.0),
                              Text(
                                'STORE BILLING UNAVAILABLE',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13.0,
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
                    Container(
                      height: 3.0,
                      decoration: BoxDecoration(
                        color: VoidTheme.crimsonFlare,
                        borderRadius: BorderRadius.circular(1.5),
                        boxShadow: const [
                          BoxShadow(color: Color(0x80EF4444), blurRadius: 6.0),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14.0),
                    Text(
                      outcome.errorMessage ??
                          'Google Play Store billing is currently unavailable on this device. Please verify that Google Play Store is installed and signed into an active Google account.',
                      style: const TextStyle(
                        color: Color(0xFFCBD5E1),
                        fontSize: 12.0,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 18.0),
                    TactileButton(
                      label: 'DISMISS',
                      onPressed: () => Navigator.of(ctx).pop(),
                      accentColor: VoidTheme.plasmaCyan,
                      height: 42.0,
                      isPrimary: false,
                    ),
                  ],
                ),
              ),
            ),
          );
        }
      }
    }
  }

  Future<void> _handleWatchAd() async {
    HapticService.instance.injectionClick();
    setState(() => _isProcessing = true);

    final success = await EntitlementService.instance.unlockWithRewardedAd();

    if (mounted) {
      setState(() => _isProcessing = false);
      if (success) {
        widget.onUnlocked?.call();
        final mins = EntitlementService.instance.boostMinutesRemaining;
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '⚡ +5 MIN PRO OVERCHARGE ACTIVE! ($mins/60m Stacked • All Pro Features Unlocked)',
              style: const TextStyle(
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
              'Holo-transmission unavailable. Please try again shortly.',
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
                  border: Border.all(color: VoidTheme.crimsonFlare, width: 1.5),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x66000000),
                      blurRadius: 20.0,
                      offset: Offset(0, 6),
                    ),
                    BoxShadow(
                      color: Color(0x33EF4444),
                      blurRadius: 16.0,
                      spreadRadius: -2,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 36.0,
                          height: 36.0,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: VoidTheme.crimsonFlare.withValues(
                              alpha: 0.15,
                            ),
                            border: Border.all(
                              color: VoidTheme.crimsonFlare,
                              width: 1.5,
                            ),
                          ),
                          child: const Icon(
                            Icons.error_outline,
                            color: VoidTheme.crimsonFlare,
                            size: 20.0,
                          ),
                        ),
                        const SizedBox(width: 12.0),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'TRANSACTION FAILURE',
                                style: TextStyle(
                                  color: VoidTheme.crimsonFlare,
                                  fontSize: 9.0,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              SizedBox(height: 2.0),
                              Text(
                                'STORE BILLING UNAVAILABLE',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13.0,
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
                    Container(
                      height: 3.0,
                      decoration: BoxDecoration(
                        color: VoidTheme.crimsonFlare,
                        borderRadius: BorderRadius.circular(1.5),
                        boxShadow: const [
                          BoxShadow(color: Color(0x80EF4444), blurRadius: 6.0),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14.0),
                    const Text(
                      'Google Play Store billing is currently unavailable on this device or emulator. Please verify Google Play Store is installed and signed into an active Google account.',
                      style: TextStyle(
                        color: Color(0xFFCBD5E1),
                        fontSize: 12.0,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 18.0),
                    TactileButton(
                      label: 'DISMISS',
                      onPressed: () => Navigator.of(ctx).pop(),
                      accentColor: VoidTheme.plasmaCyan,
                      height: 42.0,
                      isPrimary: false,
                    ),
                  ],
                ),
              ),
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
              // Header matching UX 3.0
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'VOID SOWER // PRO FLEET CLEARANCE',
                        style: TextStyle(
                          color: Color(0xFF38BDF8),
                          fontSize: 8.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5,
                        ),
                      ),
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: const Icon(
                          Icons.close,
                          color: VoidTheme.textSecondary,
                          size: 20.0,
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'PRO COMMANDER FLEET',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18.0,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 2.0),
                            Text(
                              'Lifetime License • \$1.29 One-Time',
                              style: TextStyle(
                                color: Color(0xFF94A3B8),
                                fontSize: 10.0,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        height: 26.0,
                        padding: const EdgeInsets.symmetric(horizontal: 10.0),
                        decoration: BoxDecoration(
                          color: const Color(0xFF201503),
                          borderRadius: BorderRadius.circular(13.0),
                          border: Border.all(
                            color: const Color(0xFFF59E0B),
                            width: 1.0,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8.0,
                              height: 8.0,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFFFBBF24),
                                boxShadow: [
                                  BoxShadow(
                                    color: Color(0x99FBBF24),
                                    blurRadius: 4.0,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 6.0),
                            const Text(
                              '\$1.29 LIFETIME',
                              style: TextStyle(
                                color: Color(0xFFFEF3C7),
                                fontSize: 8.5,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8.0),
                  // 4px Progress Track
                  Container(
                    height: 4.0,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(2.0),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: EntitlementService.instance.isProUnlocked
                          ? 1.0
                          : 0.75,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFFBBF24),
                          borderRadius: BorderRadius.circular(2.0),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x99FBBF24),
                              blurRadius: 6.0,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12.0),

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
              else if (EntitlementService.instance.isProUnlocked)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14.0,
                        vertical: 12.0,
                      ),
                      decoration: BoxDecoration(
                        color: VoidTheme.solarGold.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10.0),
                        border: Border.all(
                          color: VoidTheme.solarGold,
                          width: 1.0,
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.workspace_premium,
                            color: VoidTheme.solarGold,
                            size: 18.0,
                          ),
                          SizedBox(width: 8.0),
                          Text(
                            'PRO COMMANDER LIFETIME ACTIVE',
                            style: TextStyle(
                              color: VoidTheme.solarGold,
                              fontSize: 11.0,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12.0),
                    TactileButton(
                      label: 'CLOSE',
                      accentColor: VoidTheme.solarGold,
                      height: 44.0,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Stackable Pro Boost Gauge (Voluntary Rewarded Ad)
                    _buildBoostGauge(),
                    const SizedBox(height: 10.0),

                    // Voluntary Rewarded Ad CTA (Stackable +5m up to 60m)
                    TactileButton(
                      label: EntitlementService.instance.isMaxBoostReached
                          ? 'BOOST FULL (60m)'
                          : 'WATCH AD (+5m PRO)',
                      icon: Icons.play_circle_filled,
                      accentColor: VoidTheme.emeraldShield,
                      height: 44.0,
                      onPressed: EntitlementService.instance.isMaxBoostReached
                          ? null
                          : _handleWatchAd,
                    ),
                    const SizedBox(height: 10.0),

                    // Primary 1-Time Purchase CTA
                    TactileButton(
                      label: 'UNLOCK PRO — \$1.29',
                      icon: Icons.lock_open,
                      accentColor: VoidTheme.solarGold,
                      height: 46.0,
                      onPressed: _handlePurchase,
                    ),
                    const SizedBox(height: 6.0),

                    // Restore Purchases
                    TextButton(
                      onPressed: _handleRestore,
                      child: const Text(
                        'RESTORE PURCHASES',
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

  Widget _buildBoostGauge() {
    final ent = EntitlementService.instance;
    final litSegments = ent.boostSegmentsLit;
    final mins = ent.boostMinutesRemaining;
    final isMax = ent.isMaxBoostReached;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
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
                  Icon(Icons.bolt, color: VoidTheme.solarGold, size: 14.0),
                  SizedBox(width: 4.0),
                  Text(
                    'PRO TEMPORAL OVERCHARGE',
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
                  color: isMax ? VoidTheme.emeraldShield : VoidTheme.plasmaCyan,
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
                  margin: EdgeInsets.only(right: index < 11 ? 2.5 : 0.0),
                  decoration: BoxDecoration(
                    color: isLit
                        ? VoidTheme.solarGold
                        : const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(2.0),
                    boxShadow: isLit
                        ? [
                            BoxShadow(
                              color: VoidTheme.solarGold.withValues(alpha: 0.6),
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
    );
  }

  Widget _buildFeatureCard(ProFeature feature, {bool isHighlighted = false}) {
    final meta = ProFeatureMeta.registry[feature]!;
    final isSelected = isHighlighted || (_selectedFeature == feature);

    return GestureDetector(
      onTap: () {
        HapticService.instance.sowTick();
        setState(() => _selectedFeature = feature);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 11.0),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF0C233C), Color(0xFF071322)],
                )
              : null,
          color: isSelected ? null : const Color(0xFF0A101D),
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF00F0FF)
                : const Color(0xFF1E293B),
            width: isSelected ? 1.5 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF00F0FF).withValues(alpha: 0.2),
                    blurRadius: 10.0,
                    spreadRadius: 1.0,
                  ),
                ]
              : null,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32.0,
              height: 32.0,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected
                    ? const Color(0xFF071B2E)
                    : const Color(0xFF0F172A),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF00F0FF)
                      : const Color(0xFF334155),
                  width: 1.0,
                ),
              ),
              child: Icon(
                meta.icon,
                color: isSelected
                    ? const Color(0xFF00F0FF)
                    : const Color(0xFF38BDF8),
                size: 16.0,
              ),
            ),
            const SizedBox(width: 12.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          meta.title,
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : VoidTheme.starWhite,
                            fontSize: 12.0,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                      if (isHighlighted)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6.0,
                            vertical: 1.5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0284C7),
                            borderRadius: BorderRadius.circular(4.0),
                          ),
                          child: const Text(
                            'HIGHLIGHT',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 7.5,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 3.0),
                  Text(
                    meta.shortDescription,
                    style: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 10.0,
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
