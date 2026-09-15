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

import '../services/haptic_service.dart';
import '../theme/void_theme.dart';
import 'bao_codex_dialog.dart';
import 'tactile_button.dart';

/// Interactive hands-on Flight Academy onboarding overlay teaching Bao orbital mechanics.
class TutorialOverlay extends StatefulWidget {
  const TutorialOverlay({super.key, required this.onDismiss, this.onOpenCodex});

  final VoidCallback onDismiss;
  final VoidCallback? onOpenCodex;

  @override
  State<TutorialOverlay> createState() => _TutorialOverlayState();
}

class _TutorialOverlayState extends State<TutorialOverlay> {
  int _currentStep = 0;

  // Interactive step state
  int _demoCores = 28;
  int _demoBayCharge = 0;
  int _demoActiveBay = 11;
  int _demoMass = 3;
  bool _lanceFired = false;
  int _demoCorridor = 3; // 0..7 (C4)
  bool _bombDeflected = false;

  void _nextStep() {
    if (_currentStep < 4) {
      HapticService.instance.sowTick();
      setState(() => _currentStep++);
    } else {
      HapticService.instance.injectionClick();
      widget.onDismiss();
    }
  }

  void _prevStep() {
    HapticService.instance.sowTick();
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  void _openCodex() {
    if (widget.onOpenCodex != null) {
      widget.onOpenCodex!();
    } else {
      showDialog<void>(
        context: context,
        builder: (context) => const BaoCodexDialog(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: VoidTheme.obsidianBlack.withValues(alpha: 0.85),
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 14.0),
      child: SingleChildScrollView(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 420.0),
          padding: const EdgeInsets.all(18.0),
          decoration: VoidTheme.glassmorphic(
            borderColor: _getStepAccent(),
            borderWidth: 2.0,
            borderRadius: 16.0,
            extraShadows: [
              BoxShadow(
                color: _getStepAccent().withValues(alpha: 0.25),
                blurRadius: 20.0,
                spreadRadius: 2.0,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header: Title & Step Counter
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(_getStepIcon(), color: _getStepAccent(), size: 20.0),
                      const SizedBox(width: 8.0),
                      Text(
                        'FLIGHT ACADEMY',
                        style: TextStyle(
                          color: _getStepAccent(),
                          fontSize: 12.0,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '${_currentStep + 1} / 5',
                    style: const TextStyle(
                      color: VoidTheme.textSecondary,
                      fontSize: 12.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6.0),

              // Tactical Briefing Badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8.0,
                  vertical: 3.0,
                ),
                decoration: BoxDecoration(
                  color: VoidTheme.emeraldShield.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4.0),
                  border: Border.all(
                    color: VoidTheme.emeraldShield.withValues(alpha: 0.4),
                    width: 0.8,
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.touch_app,
                      color: VoidTheme.emeraldShield,
                      size: 13.0,
                    ),
                    SizedBox(width: 5.0),
                    Flexible(
                      child: Text(
                        'INTERACTIVE TUTORIAL • TAP CONTROLS TO PRACTICE',
                        style: TextStyle(
                          color: VoidTheme.emeraldShield,
                          fontSize: 8.5,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.4,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(color: VoidTheme.cardSurface, height: 16.0),

              // Step Title & Body
              Text(
                _getStepTitle(),
                style: const TextStyle(
                  color: VoidTheme.textPrimary,
                  fontSize: 15.0,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 4.0),
              Text(
                _getStepSubtitle(),
                style: TextStyle(
                  color: _getStepAccent().withValues(alpha: 0.9),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10.0),
              Text(
                _getStepBody(),
                style: const TextStyle(
                  color: VoidTheme.textSecondary,
                  fontSize: 12.5,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 14.0),

              // Interactive Hands-On Simulation Widget
              _buildInteractiveWidget(),
              const SizedBox(height: 14.0),

              // Pro Tip Box
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10.0,
                  vertical: 8.0,
                ),
                decoration: BoxDecoration(
                  color: VoidTheme.obsidianBlack.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(
                    color: _getStepAccent().withValues(alpha: 0.35),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.lightbulb_outline,
                      color: VoidTheme.solarGold,
                      size: 15.0,
                    ),
                    const SizedBox(width: 6.0),
                    Expanded(
                      child: Text(
                        _getStepTip(),
                        style: const TextStyle(
                          color: VoidTheme.solarGoldLight,
                          fontSize: 10.5,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18.0),

              // Navigation Controls
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_currentStep > 0)
                    TactileButton(
                      label: 'PREV',
                      onPressed: _prevStep,
                      accentColor: VoidTheme.textSecondary,
                      minWidth: 70.0,
                      height: 38.0,
                      isPrimary: false,
                    )
                  else
                    TextButton(
                      onPressed: widget.onDismiss,
                      child: const Text(
                        'SKIP',
                        style: TextStyle(
                          color: VoidTheme.textMuted,
                          fontSize: 11.0,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextButton.icon(
                        onPressed: _openCodex,
                        icon: const Icon(
                          Icons.menu_book,
                          size: 13.0,
                          color: VoidTheme.plasmaCyan,
                        ),
                        label: const Text(
                          'CODEX',
                          style: TextStyle(
                            color: VoidTheme.plasmaCyan,
                            fontSize: 10.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6.0),
                      TactileButton(
                        label: _currentStep == 4 ? 'LAUNCH!' : 'NEXT',
                        onPressed: _nextStep,
                        accentColor: _getStepAccent(),
                        minWidth: 95.0,
                        height: 38.0,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Step Content Getters ---

  String _getStepTitle() {
    switch (_currentStep) {
      case 0:
        return '1. CORE INJECTION (NAMUA)';
      case 1:
        return '2. SOWING TRAVERSAL';
      case 2:
        return '3. QUADRATIC LANCE DISCHARGE';
      case 3:
        return '4. ORBITAL PLATFORM ALIGNMENT';
      case 4:
      default:
        return '5. BOMB EVASION & BREACH';
    }
  }

  String _getStepSubtitle() {
    switch (_currentStep) {
      case 0:
        return '28-Core Fuel Pool & Namua Rule';
      case 1:
        return 'Count-and-Capture Energy Flow';
      case 2:
        return 'High-Mass Destructive Yield (D = 100 · M²)';
      case 3:
        return 'Corridor Targeting & Slider Navigation';
      case 4:
      default:
        return 'Shield Deflection vs. EMP Breaches';
    }
  }

  String _getStepBody() {
    switch (_currentStep) {
      case 0:
        return 'Your dreadnought carries 28 Reserve Cores per sector. Sowing from any bay draws 1 core from reserves (Bao "Namua" rule) to seed the capacitors. Energy is finite!';
      case 1:
        return 'Pick up plasma from a bay and sow it pit-to-pit along the 16-bay orbital ring. Landing in an already-occupied bay triggers a Bao Cascade Relay—circulating energy for free!';
      case 2:
        return 'When sowing finishes in a frontline bay, it unleashes an axial Particle Lance! Damage scales quadratically with mass (D = 100 · M²). Single taps deal 100 DMG; M=6 deals 3,600 DMG!';
      case 3:
        return 'Slide the orbital platform (or tap C1–C8 notches) to align your dreadnought prow with descending invaders. Aligning locks that corridor\'s emitter bay automatically.';
      case 4:
      default:
        return 'Invaders drop plasma bombs. Bays with stored plasma deflect bombs (+50 PTS). If a bomb strikes an empty conduit, it causes an EMP breach (-1 core penalty).';
    }
  }

  String _getStepTip() {
    switch (_currentStep) {
      case 0:
        return 'Watch your core reserves! If reserves hit 0 and no shots are left, the match ends immediately.';
      case 1:
        return 'Sowing existing cores redistributes plasma for FREE without burning reactor reserves.';
      case 2:
        return 'Single shots drain ammunition fast. Build mass along the backline to vaporize capital ships!';
      case 3:
        return 'Slide under enemy clusters to pierce multiple craft in a single axial corridor.';
      case 4:
      default:
        return 'Keep frontline batteries charged to shield your conduits against bombardment!';
    }
  }

  Color _getStepAccent() {
    switch (_currentStep) {
      case 0:
        return VoidTheme.solarGold;
      case 1:
        return VoidTheme.plasmaCyan;
      case 2:
        return VoidTheme.crimsonFlare;
      case 3:
        return VoidTheme.emeraldShield;
      case 4:
      default:
        return VoidTheme.solarGold;
    }
  }

  IconData _getStepIcon() {
    switch (_currentStep) {
      case 0:
        return Icons.electric_bolt;
      case 1:
        return Icons.sync;
      case 2:
        return Icons.vertical_align_top;
      case 3:
        return Icons.drag_handle;
      case 4:
      default:
        return Icons.shield;
    }
  }

  // --- Interactive Step Simulation Widgets ---

  Widget _buildInteractiveWidget() {
    switch (_currentStep) {
      case 0:
        return _buildStep0InjectionWidget();
      case 1:
        return _buildStep1SowingWidget();
      case 2:
        return _buildStep2LanceWidget();
      case 3:
        return _buildStep3AlignmentWidget();
      case 4:
      default:
        return _buildStep4DeflectionWidget();
    }
  }

  Widget _buildStep0InjectionWidget() {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: VoidTheme.cardSurface,
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(
          color: VoidTheme.solarGold.withValues(alpha: 0.5),
          width: 1.0,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.bolt,
                    color: VoidTheme.solarGold,
                    size: 14.0,
                  ),
                  const SizedBox(width: 3.0),
                  Text(
                    '$_demoCores CORES',
                    style: const TextStyle(
                      color: VoidTheme.solarGold,
                      fontSize: 10.0,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              Text(
                'BAY 11: $_demoBayCharge CHARGE',
                style: const TextStyle(
                  color: VoidTheme.plasmaCyan,
                  fontSize: 10.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10.0),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: VoidTheme.solarGold,
              foregroundColor: VoidTheme.obsidianBlack,
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
            ),
            onPressed: () {
              if (_demoCores > 0) {
                HapticService.instance.injectionClick();
                setState(() {
                  _demoCores--;
                  _demoBayCharge++;
                });
              }
            },
            icon: const Icon(Icons.add, size: 14.0),
            label: const Text(
              'INJECT 1 CORE (NAMUA)',
              style: TextStyle(fontSize: 10.0, fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep1SowingWidget() {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: VoidTheme.cardSurface,
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(
          color: VoidTheme.plasmaCyan.withValues(alpha: 0.5),
          width: 1.0,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: List.generate(8, (i) {
              final bay = i + 8;
              final isActive = _demoActiveBay == bay;
              return Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 1.5),
                  height: 26.0,
                  decoration: BoxDecoration(
                    color: isActive
                        ? VoidTheme.plasmaCyan
                        : VoidTheme.obsidianBlack,
                    borderRadius: BorderRadius.circular(4.0),
                    border: Border.all(
                      color: isActive
                          ? VoidTheme.plasmaCyanLight
                          : VoidTheme.textMuted.withValues(alpha: 0.4),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'B$bay',
                    style: TextStyle(
                      color: isActive
                          ? VoidTheme.obsidianBlack
                          : VoidTheme.textSecondary,
                      fontSize: 8.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 10.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: VoidTheme.cardSurface,
                  foregroundColor: VoidTheme.solarGold,
                  side: const BorderSide(color: VoidTheme.solarGold),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12.0,
                    vertical: 6.0,
                  ),
                ),
                onPressed: () {
                  HapticService.instance.sowTick();
                  setState(() {
                    _demoActiveBay = (_demoActiveBay - 1 < 8)
                        ? 15
                        : _demoActiveBay - 1;
                  });
                },
                icon: const Icon(Icons.arrow_back, size: 12.0),
                label: const Text(
                  '◄ SOW CCW',
                  style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 12.0),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: VoidTheme.cardSurface,
                  foregroundColor: VoidTheme.plasmaCyan,
                  side: const BorderSide(color: VoidTheme.plasmaCyan),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12.0,
                    vertical: 6.0,
                  ),
                ),
                onPressed: () {
                  HapticService.instance.sowTick();
                  setState(() {
                    _demoActiveBay = (_demoActiveBay + 1 > 15)
                        ? 8
                        : _demoActiveBay + 1;
                  });
                },
                icon: const Icon(Icons.arrow_forward, size: 12.0),
                label: const Text(
                  'SOW CW ►',
                  style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStep2LanceWidget() {
    final damage = 100 * _demoMass * _demoMass;

    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: VoidTheme.cardSurface,
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(
          color: VoidTheme.crimsonFlare.withValues(alpha: 0.5),
          width: 1.0,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'MASS (M): $_demoMass CORES',
                  style: const TextStyle(
                    color: VoidTheme.solarGold,
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                'LANCE YIELD: $damage DMG',
                style: const TextStyle(
                  color: VoidTheme.crimsonFlare,
                  fontSize: 11.0,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          Slider(
            value: _demoMass.toDouble(),
            min: 1,
            max: 6,
            divisions: 5,
            activeColor: VoidTheme.crimsonFlare,
            inactiveColor: VoidTheme.obsidianBlack,
            onChanged: (val) {
              setState(() => _demoMass = val.round());
            },
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: VoidTheme.crimsonFlare,
              foregroundColor: VoidTheme.obsidianBlack,
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
            ),
            onPressed: () {
              HapticService.instance.injectionClick();
              setState(() => _lanceFired = true);
              Timer(const Duration(milliseconds: 900), () {
                if (mounted) setState(() => _lanceFired = false);
              });
            },
            icon: const Icon(Icons.bolt, size: 15.0),
            label: Text(
              _lanceFired
                  ? '⚡ DIRECT HIT! $damage DMG'
                  : 'TEST FIRE AXIAL LANCE',
              style: const TextStyle(
                fontSize: 10.0,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep3AlignmentWidget() {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: VoidTheme.cardSurface,
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(
          color: VoidTheme.emeraldShield.withValues(alpha: 0.5),
          width: 1.0,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: List.generate(8, (i) {
              final isSelected = _demoCorridor == i;
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    HapticService.instance.sowTick();
                    setState(() => _demoCorridor = i);
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 1.5),
                    height: 26.0,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? VoidTheme.emeraldShield
                          : VoidTheme.obsidianBlack,
                      borderRadius: BorderRadius.circular(4.0),
                      border: Border.all(
                        color: isSelected
                            ? VoidTheme.emeraldShield
                            : VoidTheme.textMuted.withValues(alpha: 0.3),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'C${i + 1}',
                      style: TextStyle(
                        color: isSelected
                            ? VoidTheme.obsidianBlack
                            : VoidTheme.textSecondary,
                        fontSize: 8.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 8.0),
          Text(
            'LOCKED: CORRIDOR ${_demoCorridor + 1} (FRONTLINE BAY ${_demoCorridor + 8})',
            style: const TextStyle(
              color: VoidTheme.emeraldShield,
              fontSize: 10.0,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep4DeflectionWidget() {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: VoidTheme.cardSurface,
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(
          color: VoidTheme.solarGold.withValues(alpha: 0.5),
          width: 1.0,
        ),
      ),
      child: Column(
        children: [
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _bombDeflected ? Icons.shield : Icons.shield_outlined,
                  color: _bombDeflected
                      ? VoidTheme.emeraldShield
                      : VoidTheme.solarGold,
                  size: 20.0,
                ),
                const SizedBox(width: 6.0),
                Text(
                  _bombDeflected ? 'DEFLECTED! +50 PTS' : 'CONDUIT SHIELDING',
                  style: TextStyle(
                    color: _bombDeflected
                        ? VoidTheme.emeraldShield
                        : VoidTheme.solarGold,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8.0),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: VoidTheme.solarGold,
              foregroundColor: VoidTheme.obsidianBlack,
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
            ),
            onPressed: () {
              HapticService.instance.injectionClick();
              setState(() => _bombDeflected = true);
              Timer(const Duration(milliseconds: 1200), () {
                if (mounted) setState(() => _bombDeflected = false);
              });
            },
            icon: const Icon(Icons.sports_baseball, size: 14.0),
            label: const Text(
              'TEST ENEMY BOMB DROP',
              style: TextStyle(fontSize: 10.0, fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }
}
