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
        constraints: const BoxConstraints(maxWidth: 480.0),
        padding: const EdgeInsets.all(20.0),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(20.0),
          border: Border.all(
            color: const Color(0xFF00F0FF).withValues(alpha: 0.8),
            width: 1.5,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x66000000),
              blurRadius: 24.0,
              offset: Offset(0, 8),
            ),
            BoxShadow(
              color: Color(0x2B00F0FF),
              blurRadius: 16.0,
              spreadRadius: -2,
            ),
          ],
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
                    width: 38.0,
                    height: 38.0,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0x2200F0FF),
                      border: Border.all(
                        color: const Color(0xFF00F0FF),
                        width: 1.5,
                      ),
                    ),
                    child: const Icon(
                      Icons.shield_outlined,
                      color: Color(0xFF00F0FF),
                      size: 20.0,
                    ),
                  ),
                  const SizedBox(width: 12.0),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'GDPR // PRIVACY COMPLIANCE',
                          style: TextStyle(
                            color: Color(0xFF38BDF8),
                            fontSize: 9.0,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                          ),
                        ),
                        SizedBox(height: 2.0),
                        Text(
                          'CONSENT PREFERENCES',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14.0,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: Color(0xFF94A3B8),
                      size: 20.0,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 12.0),
              // 4px neon track
              Container(
                height: 3.0,
                decoration: BoxDecoration(
                  color: const Color(0xFF00F0FF),
                  borderRadius: BorderRadius.circular(1.5),
                  boxShadow: const [
                    BoxShadow(color: Color(0x8000F0FF), blurRadius: 6.0),
                  ],
                ),
              ),
              const SizedBox(height: 16.0),

              // Personalized Ads Option Card
              Container(
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: const Color(0xFF070C18),
                  borderRadius: BorderRadius.circular(12.0),
                  border: Border.all(
                    color: _personalizedAds
                        ? const Color(0x6600F0FF)
                        : const Color(0xFF1E293B),
                    width: 1.0,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Icon(
                                Icons.ads_click,
                                color: _personalizedAds
                                    ? const Color(0xFF00F0FF)
                                    : const Color(0xFF64748B),
                                size: 16.0,
                              ),
                              const SizedBox(width: 8.0),
                              const Expanded(
                                child: Text(
                                  'Personalized Advertising',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 13.0,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: _personalizedAds,
                          activeThumbColor: const Color(0xFF00F0FF),
                          activeTrackColor: const Color(0x5500F0FF),
                          inactiveThumbColor: const Color(0xFF64748B),
                          inactiveTrackColor: const Color(0xFF1E293B),
                          onChanged: (val) {
                            HapticService.instance.sowTick();
                            setState(() => _personalizedAds = val);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 4.0),
                    const Text(
                      'Allow Google AdMob UMP to tailor rewarded emergency flare ads using ad identifiers.',
                      style: TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 11.0,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10.0),

              // Crash Reporting Option Card
              Container(
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: const Color(0xFF070C18),
                  borderRadius: BorderRadius.circular(12.0),
                  border: Border.all(
                    color: _crashReporting
                        ? const Color(0x6600F0FF)
                        : const Color(0xFF1E293B),
                    width: 1.0,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Icon(
                                Icons.bug_report_outlined,
                                color: _crashReporting
                                    ? const Color(0xFF00F0FF)
                                    : const Color(0xFF64748B),
                                size: 16.0,
                              ),
                              const SizedBox(width: 8.0),
                              const Expanded(
                                child: Text(
                                  'Anonymous Crash Telemetry',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 13.0,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: _crashReporting,
                          activeThumbColor: const Color(0xFF00F0FF),
                          activeTrackColor: const Color(0x5500F0FF),
                          inactiveThumbColor: const Color(0xFF64748B),
                          inactiveTrackColor: const Color(0xFF1E293B),
                          onChanged: (val) {
                            HapticService.instance.sowTick();
                            setState(() => _crashReporting = val);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 4.0),
                    const Text(
                      'Send non-identifiable stack traces and FPS telemetry to diagnose C++ engine performance.',
                      style: TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 11.0,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16.0),

              // Right-to-be-forgotten GDPR Wipe
              if (!_confirmingErase)
                TactileButton(
                  label: 'ERASE DATA',
                  icon: Icons.delete_forever,
                  accentColor: VoidTheme.crimsonFlare,
                  height: 40.0,
                  isPrimary: false,
                  onPressed: () {
                    HapticService.instance.lanceDischarge();
                    setState(() => _confirmingErase = true);
                  },
                )
              else
                Container(
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: const Color(0x22F43F5E),
                    borderRadius: BorderRadius.circular(10.0),
                    border: Border.all(
                      color: VoidTheme.crimsonFlare,
                      width: 1.2,
                    ),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'WARNING: Permanently erase high scores, liberated sectors, and pilot identity?',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFFF43F5E),
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10.0),
                      Row(
                        children: [
                          Expanded(
                            child: TactileButton(
                              label: 'CANCEL',
                              accentColor: const Color(0xFF64748B),
                              height: 38.0,
                              isPrimary: false,
                              onPressed: () =>
                                  setState(() => _confirmingErase = false),
                            ),
                          ),
                          const SizedBox(width: 8.0),
                          Expanded(
                            child: TactileButton(
                              label: 'WIPE DATA',
                              icon: Icons.warning,
                              accentColor: VoidTheme.crimsonFlare,
                              height: 38.0,
                              onPressed: _executeDataWipe,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 14.0),

              TactileButton(
                label: 'SAVE',
                icon: Icons.save_alt,
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
