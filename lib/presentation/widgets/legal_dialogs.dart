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

import '../theme/void_theme.dart';
import 'tactile_button.dart';

/// Modal dialog rendering the Privacy Policy with Afrofuturist styling.
class PrivacyPolicyDialog extends StatelessWidget {
  const PrivacyPolicyDialog({super.key});

  static const String _kPrivacyContent = '''
EFFECTIVE DATE: January 1, 2026
LAST UPDATED: September 13, 2026

1. OVERVIEW
Void Sower ("the Application") is an offline-capable tactical arcade shooter developed by the Void Sower Authors. We respect your privacy and enforce a strict data minimization architecture: game state, progress, and settings remain stored on your local device.

2. INFORMATION COLLECTED
• Local Game Telemetry: High scores, liberated sectors, capacitor upgrades, and audio/graphics preferences are saved inside device-private sandbox storage.
• Anonymous Crash Traces: When permitted, anonymous operational crash logs help our team resolve native memory and rendering bugs.
• No Personal Identification: We do not collect names, emails, phone numbers, contact lists, or physical GPS coordinates.

3. ADVERTISING & IN-APP PURCHASES
• Rewarded Advertisements: Optional emergency core recharges may display Google AdMob rewarded videos conforming to Google User Messaging Platform (UMP) guidelines.
• In-App Billing: Purchases (Pro Lifetime unlock) are securely transacted through Google Play Billing v7. We never inspect or retain payment card credentials.

4. RIGHT TO BE FORGOTTEN (GDPR & CCPA)
You hold an absolute right to erase all telemetry and progress at any time. Tap "Data Erasure (GDPR)" in Consent Preferences to purge all stored local data.

5. CONTACT & INQUIRIES
For legal or privacy questions, contact:
voidsower-dev@googlegroups.com
''';

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(
        horizontal: 16.0,
        vertical: 24.0,
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 480.0, maxHeight: 620.0),
        padding: const EdgeInsets.all(20.0),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(20.0),
          border: Border.all(
            color: VoidTheme.plasmaCyan.withValues(alpha: 0.8),
            width: 1.5,
          ),
          boxShadow: [
            const BoxShadow(
              color: Color(0x66000000),
              blurRadius: 24.0,
              offset: Offset(0, 8),
            ),
            BoxShadow(
              color: VoidTheme.plasmaCyan.withValues(alpha: 0.2),
              blurRadius: 16.0,
              spreadRadius: -2,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 38.0,
                  height: 38.0,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: VoidTheme.plasmaCyan.withValues(alpha: 0.15),
                    border: Border.all(color: VoidTheme.plasmaCyan, width: 1.5),
                  ),
                  child: const Icon(
                    Icons.shield_outlined,
                    color: VoidTheme.plasmaCyan,
                    size: 20.0,
                  ),
                ),
                const SizedBox(width: 12.0),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'LEGAL DIRECTIVE // COMPLIANCE',
                        style: TextStyle(
                          color: Color(0xFF38BDF8),
                          fontSize: 9.0,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                        ),
                      ),
                      SizedBox(height: 2.0),
                      Text(
                        'PRIVACY POLICY',
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
                color: VoidTheme.plasmaCyan,
                borderRadius: BorderRadius.circular(1.5),
                boxShadow: [
                  BoxShadow(
                    color: VoidTheme.plasmaCyan.withValues(alpha: 0.5),
                    blurRadius: 6.0,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14.0),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(14.0),
                decoration: BoxDecoration(
                  color: const Color(0xFF070C18),
                  borderRadius: BorderRadius.circular(10.0),
                  border: Border.all(
                    color: const Color(0xFF1E293B),
                    width: 1.0,
                  ),
                ),
                child: const SingleChildScrollView(
                  child: Text(
                    _kPrivacyContent,
                    style: TextStyle(
                      color: Color(0xFFCBD5E1),
                      fontSize: 11.5,
                      height: 1.45,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16.0),
            TactileButton(
              label: 'ACKNOWLEDGE',
              icon: Icons.check,
              accentColor: VoidTheme.plasmaCyan,
              height: 44.0,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}

/// Modal dialog rendering the Terms of Service with Afrofuturist styling.
class TermsOfServiceDialog extends StatelessWidget {
  const TermsOfServiceDialog({super.key});

  static const String _kTermsContent = '''
EFFECTIVE DATE: January 1, 2026
LAST UPDATED: September 13, 2026

1. ACCEPTANCE OF TERMS
By installing, loading, or playing Void Sower ("the Application"), you agree to be bound by these Terms of Service and our Privacy Policy. If you do not agree, discontinue use immediately.

2. LICENSE GRANT
Void Sower Authors grant you a revocable, non-exclusive, non-transferable, personal license to download, install, and execute the game software for personal entertainment on compatible devices.

3. VIRTUAL ENTITLEMENTS & BILLING
• Pro Lifetime licenses (\$0.99) grant non-consumable digital access to ad-free reactor recharges and future cosmetic insignia perks.
• All transactions are managed under Google Play Store standard commerce terms.

4. DISCLAIMER OF WARRANTIES
THE APPLICATION IS PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED. TO THE MAXIMUM EXTENT PERMITTED BY LAW, VOID SOWER AUTHORS DISCLAIM ALL LIABILITY FOR DATA LOSS, DEVICE INCOMPATIBILITY, OR CONSEQUENTIAL DAMAGES.

5. GOVERNING LAW
These terms shall be governed and interpreted under applicable laws without regard to conflict of law principles.
''';

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(
        horizontal: 16.0,
        vertical: 24.0,
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 480.0, maxHeight: 620.0),
        padding: const EdgeInsets.all(20.0),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(20.0),
          border: Border.all(
            color: VoidTheme.solarGold.withValues(alpha: 0.8),
            width: 1.5,
          ),
          boxShadow: [
            const BoxShadow(
              color: Color(0x66000000),
              blurRadius: 24.0,
              offset: Offset(0, 8),
            ),
            BoxShadow(
              color: VoidTheme.solarGold.withValues(alpha: 0.2),
              blurRadius: 16.0,
              spreadRadius: -2,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 38.0,
                  height: 38.0,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: VoidTheme.solarGold.withValues(alpha: 0.15),
                    border: Border.all(color: VoidTheme.solarGold, width: 1.5),
                  ),
                  child: const Icon(
                    Icons.gavel,
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
                        'LEGAL DIRECTIVE // LICENSING',
                        style: TextStyle(
                          color: Color(0xFFF59E0B),
                          fontSize: 9.0,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                        ),
                      ),
                      SizedBox(height: 2.0),
                      Text(
                        'TERMS OF SERVICE',
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
                color: VoidTheme.solarGold,
                borderRadius: BorderRadius.circular(1.5),
                boxShadow: [
                  BoxShadow(
                    color: VoidTheme.solarGold.withValues(alpha: 0.5),
                    blurRadius: 6.0,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14.0),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(14.0),
                decoration: BoxDecoration(
                  color: const Color(0xFF070C18),
                  borderRadius: BorderRadius.circular(10.0),
                  border: Border.all(
                    color: const Color(0xFF1E293B),
                    width: 1.0,
                  ),
                ),
                child: const SingleChildScrollView(
                  child: Text(
                    _kTermsContent,
                    style: TextStyle(
                      color: Color(0xFFCBD5E1),
                      fontSize: 11.5,
                      height: 1.45,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16.0),
            TactileButton(
              label: 'AGREE',
              icon: Icons.check,
              accentColor: VoidTheme.solarGold,
              height: 44.0,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}
