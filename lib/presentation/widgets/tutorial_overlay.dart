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
      subtitle: 'Energize the Capacitor Ring',
      body:
          'Tap any capacitor bay (or flick upward) to inject a reserve plasma core. '
          'Each injected core charges the bay and prepares it for orbital sowing.',
      icon: Icons.electric_bolt,
      accentColor: VoidTheme.solarGold,
      tipText: 'Flick UP from thumb area or double-tap a bay to inject.',
    ),
    _TutorialStepData(
      title: '2. SOWING TRAVERSAL',
      subtitle: 'Count-and-Capture Distribution',
      body:
          'Swipe LEFT or RIGHT across a charged bay to sow its plasma units along '
          'the 16-bay orbital ring in circular cadence.',
      icon: Icons.sync,
      accentColor: VoidTheme.plasmaCyan,
      tipText:
          'Swipe RIGHT for Clockwise (+1), LEFT for Counter-Clockwise (-1).',
    ),
    _TutorialStepData(
      title: '3. QUADRATIC LANCE DISCHARGE',
      subtitle: 'Orbital Cross-Discharge Mechanics',
      body:
          'When your sowing sequence terminates in an occupied frontline bay (≥ 2 units), '
          'an axial Particle Lance fires straight up that corridor! Damage scales quadratically: D = α · M².',
      icon: Icons.vertical_align_top,
      accentColor: VoidTheme.crimsonFlare,
      tipText: 'Higher accumulated mass (M) creates devastating lance beams.',
    ),
    _TutorialStepData(
      title: '4. ORBITAL PLATFORM ALIGNMENT',
      subtitle: 'Corridor Defense & Aiming',
      body:
          'Drag the bottom slider laterally to reposition your dreadnought across the 8 combat corridors. '
          'Align your firing bay with descending enemy assault craft.',
      icon: Icons.drag_handle,
      accentColor: VoidTheme.emeraldShield,
      tipText: 'Watch the Projection Shelf for real-time aiming telemetry.',
    ),
    _TutorialStepData(
      title: '5. BOMB EVASION & BREACH',
      subtitle: 'Shield Protection & Interception',
      body:
          'Invaders drop plasma bombs. Slide laterally to evade!\n'
          '• DIRECT HIT: Drains 1 core & wipes corridor battery.\n'
          '• ATMOSPHERE PASS: -5 score penalty.\n'
          '• LANCES/FLAK: Destroy bombs mid-air for bonus score.',
      icon: Icons.shield,
      accentColor: VoidTheme.crimsonFlare,
      tipText: 'Evade descending bombs or blast them with Particle Lances!',
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
