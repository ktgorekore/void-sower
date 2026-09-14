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
import '../services/haptic_service.dart';
import '../theme/void_theme.dart';
import 'tactile_button.dart';

/// Modal dialog for managing GDPR, CCPA, and UMP consent preferences.
class ConsentPreferencesDialog extends StatefulWidget {
  const ConsentPreferencesDialog({super.key, this.onDataWiped});

  final VoidCallback? onDataWiped;

  @override
  State<ConsentPreferencesDialog> createState() =>
      _ConsentPreferencesDialogState();
}

class _ConsentPreferencesDialogState extends State<ConsentPreferencesDialog> {
  late bool _personalizedAds;
  late bool _crashReporting;
  bool _confirmingErase = false;

  @override
  void initState() {
    super.initState();
    final p = PersistenceService.instance;
    _personalizedAds = p.personalizedAdsConsent;
    _crashReporting = p.crashReportingConsent;
  }

  Future<void> _savePreferences() async {
    HapticService.instance.sowTick();
    final p = PersistenceService.instance;
    await p.setPersonalizedAdsConsent(_personalizedAds);
    await p.setCrashReportingConsent(_crashReporting);
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _executeDataWipe() async {
    HapticService.instance.injectionClick();
    await PersistenceService.instance.wipeAllData();
    if (mounted) {
      widget.onDataWiped?.call();
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'All local player data and telemetry erased successfully.',
            style: TextStyle(fontFamily: 'monospace'),
          ),
          backgroundColor: VoidTheme.crimsonFlare,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(
        horizontal: 16.0,
        vertical: 24.0,
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 480),
        padding: const EdgeInsets.all(20.0),
        decoration: VoidTheme.glassmorphic(
          borderColor: VoidTheme.plasmaCyan,
          borderWidth: 1.5,
          borderRadius: 16.0,
        ),
        child: Material(
          type: MaterialType.transparency,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.security,
                        color: VoidTheme.plasmaCyan,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'CONSENT PREFERENCES',
                        style: TextStyle(
                          color: VoidTheme.solarGold,
                          fontSize: 14.0,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: VoidTheme.starWhite,
                      size: 20,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const Divider(
                color: VoidTheme.cardSurface,
                thickness: 1.0,
                height: 20,
              ),

              // Personalized Ads Option
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                activeThumbColor: VoidTheme.plasmaCyan,
                title: const Text(
                  'Personalized Advertising',
                  style: TextStyle(
                    color: VoidTheme.starWhite,
                    fontSize: 13.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: const Text(
                  'Allow Google AdMob UMP to tailor rewarded emergency flare ads using ad identifiers.',
                  style: TextStyle(
                    color: VoidTheme.starWhite,
                    fontSize: 11.0,
                    height: 1.3,
                  ),
                ),
                value: _personalizedAds,
                onChanged: (val) {
                  HapticService.instance.sowTick();
                  setState(() => _personalizedAds = val);
                },
              ),

              const SizedBox(height: 10),

              // Crash Reporting Option
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                activeThumbColor: VoidTheme.plasmaCyan,
                title: const Text(
                  'Anonymous Crash Telemetry',
                  style: TextStyle(
                    color: VoidTheme.starWhite,
                    fontSize: 13.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: const Text(
                  'Send non-identifiable stack traces and FPS telemetry to diagnose C++ engine performance.',
                  style: TextStyle(
                    color: VoidTheme.starWhite,
                    fontSize: 11.0,
                    height: 1.3,
                  ),
                ),
                value: _crashReporting,
                onChanged: (val) {
                  HapticService.instance.sowTick();
                  setState(() => _crashReporting = val);
                },
              ),

              const SizedBox(height: 16),
              const Divider(color: VoidTheme.cardSurface, thickness: 1.0),
              const SizedBox(height: 8),

              // Right-to-be-forgotten GDPR Wipe
              if (!_confirmingErase)
                TactileButton(
                  label: 'DATA ERASURE (GDPR / CCPA)',
                  icon: Icons.delete_forever,
                  accentColor: VoidTheme.crimsonFlare,
                  height: 40.0,
                  onPressed: () {
                    HapticService.instance.lanceDischarge();
                    setState(() => _confirmingErase = true);
                  },
                )
              else
                Container(
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: VoidTheme.crimsonFlare.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8.0),
                    border: Border.all(color: VoidTheme.crimsonFlare),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'WARNING: Permanently erase high scores, liberated sectors, and pilot identity?',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: VoidTheme.crimsonFlare,
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: TactileButton(
                              label: 'CANCEL',
                              accentColor: VoidTheme.starWhite,
                              height: 36.0,
                              onPressed: () =>
                                  setState(() => _confirmingErase = false),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TactileButton(
                              label: 'CONFIRM WIPE',
                              icon: Icons.warning,
                              accentColor: VoidTheme.crimsonFlare,
                              height: 36.0,
                              onPressed: _executeDataWipe,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 16),

              TactileButton(
                label: 'SAVE PREFERENCES',
                icon: Icons.save,
                accentColor: VoidTheme.solarGold,
                height: 44.0,
                onPressed: _savePreferences,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
