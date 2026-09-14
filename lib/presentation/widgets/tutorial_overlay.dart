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

import '../services/haptic_service.dart';
import '../theme/void_theme.dart';
import 'tactile_button.dart';

/// Step-by-step interactive Flight Academy onboarding overlay teaching Bao orbital mechanics.
class TutorialOverlay extends StatefulWidget {
  const TutorialOverlay({super.key, required this.onDismiss});

  final VoidCallback onDismiss;

  @override
  State<TutorialOverlay> createState() => _TutorialOverlayState();
}

class _TutorialOverlayState extends State<TutorialOverlay> {
  int _currentStep = 0;

  final List<_TutorialStepData> _steps = const [
    _TutorialStepData(
      title: '1. CORE INJECTION (NAMUA)',
      subtitle: '28-Core Economy & Zero-Bay Sowing',
      body:
          'Your dreadnought reactor holds a finite pool of 28 Reserve Cores for each sector.\n\n'
          '• SOWING FROM ZERO: Sowing from any bay (even with 0 charge) draws 1 core from your reserves (Bao "Namua" rule) to initiate the cascade. Energy is never created from nothing!\n'
          '• REACTOR DEPLETION: If reserves hit 0, empty bays cannot be sown—you can only circulate existing energy already on the ship.',
      icon: Icons.electric_bolt,
      accentColor: VoidTheme.solarGold,
      tipText:
          'Watch the top-left REACTOR gauge. Each Namua injection spends 1 core!',
    ),
    _TutorialStepData(
      title: '2. SOWING TRAVERSAL',
      subtitle: 'Count-and-Capture Energy Circulation',
      body:
          'Swipe across any bay to pick up its plasma cores and sow them sequentially along the 16-bay orbital ring.\n\n'
          '• CLOCKWISE (+1): Swipe RIGHT across the bay.\n'
          '• COUNTER-CLOCKWISE (-1): Swipe LEFT across the bay (or tap SOW CCW).\n'
          '• BAO CASCADE RELAY: When your last seed lands in an already-occupied bay, it scoops those cores and keeps cascading without spending extra fuel!',
      icon: Icons.sync,
      accentColor: VoidTheme.plasmaCyan,
      tipText:
          'Sowing existing cores redistributes fuel for FREE without burning reserves.',
    ),
    _TutorialStepData(
      title: '3. QUADRATIC LANCE DISCHARGE',
      subtitle: 'Single-Taps vs. High-Mass Destruction',
      body:
          'When your sowing cascade finishes in a frontline bay (Bays 8–15 facing an enemy corridor), the Particle Lance automatically fires!\n\n'
          '• QUADRATIC FORMULA: D = 100 · M² (Scales with mass squared).\n'
          '• SINGLE TAP (M = 1): Deals only 100 DMG (good for scout drones).\n'
          '• SOWN MASS (M = 6 to 10): Unleashes 3,600 to 10,000 DMG—piercing through heavy assault craft and boss armors in one shot!',
      icon: Icons.vertical_align_top,
      accentColor: VoidTheme.crimsonFlare,
      tipText:
          'Single shots will drain your fuel! Build high mass (M) to vaporize capital ships.',
    ),
    _TutorialStepData(
      title: '4. ORBITAL PLATFORM ALIGNMENT',
      subtitle: 'Two Ways to Fire & Corridor Aiming',
      body:
          'Drag the bottom slider (or drag anywhere on the combat canvas) to reposition your dreadnought across the 8 combat corridors.\n\n'
          '• METHOD 1 (QUICK ACTION): Slide under an enemy and tap glowing cyan "DISCHARGE C►" to inject and fire an emergency single shot.\n'
          '• METHOD 2 (TACTICAL SOW): Swipe a loaded bay to cascade high mass into the target corridor for massive quadratic destruction.',
      icon: Icons.drag_handle,
      accentColor: VoidTheme.emeraldShield,
      tipText:
          'Sliding the ship auto-locks onto that corridor\'s frontline emitter bay!',
    ),
    _TutorialStepData(
      title: '5. BOMB EVASION & BREACH',
      subtitle: 'Conduit Shielding & Bomb Deflection',
      body:
          'Invaders drop plasma bombs down all 8 corridors simultaneously:\n\n'
          '• CONDUIT DEFLECTION: If a frontline bay has stored cores, its magnetic field deflects bombs (+50 bonus points)!\n'
          '• CONDUIT BREACH: If a bomb hits an empty conduit, it causes an EMP breach (-1 core penalty).\n'
          '• INTERCEPTION: Particle Lances and Flak Bursts vaporize falling bombs mid-air.',
      icon: Icons.shield,
      accentColor: VoidTheme.crimsonFlare,
      tipText:
          'Keep your frontline bays charged to shield your conduits from falling bombs!',
    ),
  ];

  void _nextStep() {
    HapticService.instance.sowTick();
    if (_currentStep < _steps.length - 1) {
      setState(() => _currentStep++);
    } else {
      widget.onDismiss();
    }
  }

  void _prevStep() {
    HapticService.instance.sowTick();
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  @override
  Widget build(BuildContext context) {
    final step = _steps[_currentStep];

    return Container(
      color: VoidTheme.obsidianBlack.withValues(alpha: 0.82),
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      child: SingleChildScrollView(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 420.0),
          padding: const EdgeInsets.all(18.0),
          decoration: VoidTheme.glassmorphic(
            borderColor: step.accentColor,
            borderWidth: 2.0,
            borderRadius: 16.0,
            extraShadows: [
              BoxShadow(
                color: step.accentColor.withValues(alpha: 0.25),
                blurRadius: 20.0,
                spreadRadius: 2.0,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Academy Header & Step Indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(step.icon, color: step.accentColor, size: 22.0),
                      const SizedBox(width: 8.0),
                      Text(
                        'FLIGHT ACADEMY',
                        style: TextStyle(
                          color: step.accentColor,
                          fontSize: 12.0,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '${_currentStep + 1} / ${_steps.length}',
                    style: const TextStyle(
                      color: VoidTheme.textSecondary,
                      fontSize: 12.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const Divider(color: VoidTheme.cardSurface, height: 20.0),

              // Step Title & Subtitle
              Text(
                step.title,
                style: const TextStyle(
                  color: VoidTheme.textPrimary,
                  fontSize: 16.0,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 4.0),
              Text(
                step.subtitle,
                style: TextStyle(
                  color: step.accentColor.withValues(alpha: 0.9),
                  fontSize: 12.0,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 14.0),

              // Step Body Description
              Text(
                step.body,
                style: const TextStyle(
                  color: VoidTheme.textSecondary,
                  fontSize: 13.0,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 16.0),

              // Pro Tip Box
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12.0,
                  vertical: 10.0,
                ),
                decoration: BoxDecoration(
                  color: VoidTheme.obsidianBlack.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(
                    color: step.accentColor.withValues(alpha: 0.4),
                    width: 1.0,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.lightbulb_outline,
                      color: VoidTheme.solarGold,
                      size: 16.0,
                    ),
                    const SizedBox(width: 8.0),
                    Expanded(
                      child: Text(
                        step.tipText,
                        style: const TextStyle(
                          color: VoidTheme.solarGoldLight,
                          fontSize: 11.0,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22.0),

              // Navigation Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_currentStep > 0)
                    TactileButton(
                      label: 'PREV',
                      onPressed: _prevStep,
                      accentColor: VoidTheme.textSecondary,
                      minWidth: 80.0,
                      height: 42.0,
                      isPrimary: false,
                    )
                  else
                    TextButton(
                      onPressed: widget.onDismiss,
                      child: const Text(
                        'SKIP TUTORIAL',
                        style: TextStyle(
                          color: VoidTheme.textMuted,
                          fontSize: 11.0,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  TactileButton(
                    label: _currentStep == _steps.length - 1
                        ? 'LAUNCH!'
                        : 'NEXT',
                    onPressed: _nextStep,
                    accentColor: step.accentColor,
                    minWidth: 110.0,
                    height: 42.0,
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

class _TutorialStepData {
  const _TutorialStepData({
    required this.title,
    required this.subtitle,
    required this.body,
    required this.icon,
    required this.accentColor,
    required this.tipText,
  });

  final String title;
  final String subtitle;
  final String body;
  final IconData icon;
  final Color accentColor;
  final String tipText;
}
