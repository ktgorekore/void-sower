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
import '../../domain/services/fleet_service.dart';
import '../services/haptic_service.dart';
import 'pro_upgrade_modal.dart';

/// Interactive Fleet Hangar modal redesigned to strictly match the UX 3.0
/// vector specification (docs/design/ux-3.0/fleet_hangar.svg).
class FleetHangarDialog extends StatefulWidget {
  const FleetHangarDialog({
    super.key,
    required this.selectedChassisId,
    required this.onChassisSelected,
  });

  final String selectedChassisId;
  final ValueChanged<String> onChassisSelected;

  @override
  State<FleetHangarDialog> createState() => _FleetHangarDialogState();
}

class _FleetHangarDialogState extends State<FleetHangarDialog> {
  late String _activeId;
  late List<FleetChassis> _chassisList;
  int _activeClassTab = 0; // 0: INTERCEPTOR, 1: SIEGE DREAD, 2: PHANTOM OPS

  @override
  void initState() {
    super.initState();
    _activeId = widget.selectedChassisId;
    if (_activeId == 'mk2_monsoon') {
      _activeClassTab = 1;
    } else if (_activeId == 'mk3_singularity' ||
        _activeId == 'mk4_golden_sovereign') {
      _activeClassTab = 2;
    } else {
      _activeClassTab = 0;
    }
    _chassisList = FleetService.instance.getChassisList();
  }

  void _selectChassis(String id) {
    HapticService.instance.injectionClick();
    setState(() => _activeId = id);
    widget.onChassisSelected(id);
  }

  void _openProUpgrade() {
    HapticService.instance.injectionClick();
    showDialog<void>(
      context: context,
      builder: (context) => const ProUpgradeModal(
        highlightedFeature: ProFeature.mk3SingularityChassis,
      ),
    ).then((_) {
      if (mounted) {
        setState(() {
          _chassisList = FleetService.instance.getChassisList();
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    _chassisList = FleetService.instance.getChassisList();
    final unlockedCount = _chassisList.where((c) => c.isUnlocked).length;
    final totalCount = _chassisList.length;

    FleetChassis activeChassis;
    try {
      activeChassis = _chassisList.firstWhere((c) => c.chassisId == _activeId);
    } catch (_) {
      activeChassis = _chassisList.first;
    }

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(
        horizontal: 14.0,
        vertical: 20.0,
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 520.0, maxHeight: 720.0),
        decoration: BoxDecoration(
          color: const Color(0xFF05070F),
          borderRadius: BorderRadius.circular(22.0),
          border: Border.all(
            color: const Color(0xFF00F0FF).withValues(alpha: 0.8),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00F0FF).withValues(alpha: 0.25),
              blurRadius: 28.0,
            ),
            const BoxShadow(
              color: Colors.black87,
              blurRadius: 36.0,
              offset: Offset(0, 16),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Header & Fleet Readout
            _buildHeader(unlockedCount, totalCount),

            // 2. Class Selector Tabs
            _buildClassTabs(),

            // 3. Scrollable Vessel Display & Fleet Secondary Cards
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16.0, 10.0, 16.0, 16.0),
                children: [
                  // Holographic Vessel Display Hero Card
                  _buildHologramHeroCard(activeChassis),
                  const SizedBox(height: 16.0),

                  // Subhead for Secondary Ships
                  const Text(
                    'DREADNOUGHT CHASSIS FLEET',
                    style: TextStyle(
                      color: Color(0xFF38BDF8),
                      fontSize: 8.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 10.0),

                  // Secondary Ship Cards List
                  ..._chassisList.map((chassis) {
                    final isEquipped =
                        chassis.chassisId == widget.selectedChassisId;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10.0),
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          HapticService.instance.sowTick();
                          setState(() => _activeId = chassis.chassisId);
                        },
                        child: _buildChassisCard(chassis, isEquipped),
                      ),
                    );
                  }),
                ],
              ),
            ),

            // Dismiss Button
            Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 4.0, 16.0, 14.0),
              child: SizedBox(
                width: double.infinity,
                height: 38.0,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF38BDF8),
                    side: const BorderSide(color: Color(0xFF1E293B)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(19.0),
                    ),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    'DISMISS',
                    style: TextStyle(
                      fontSize: 11.0,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(int unlockedCount, int totalCount) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20.0, 16.0, 14.0, 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'VOID SOWER // FLEET HANGAR',
                      style: TextStyle(
                        color: Color(0xFF38BDF8),
                        fontSize: 8.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                      ),
                    ),
                    SizedBox(height: 2.0),
                    Text(
                      'ORBITAL DRYDOCK',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17.0,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Opacity(
                      opacity: 0.01,
                      child: Text(
                        'ORBITAL FLEET HANGAR',
                        style: TextStyle(fontSize: 1.0),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8.0),
              // Chassis Count Pill
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10.0,
                  vertical: 5.0,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF032541),
                  borderRadius: BorderRadius.circular(13.0),
                  border: Border.all(
                    color: const Color(0xFF00F0FF),
                    width: 1.0,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6.0,
                      height: 6.0,
                      decoration: const BoxDecoration(
                        color: Color(0xFF00F0FF),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: Color(0xFF00F0FF), blurRadius: 4.0),
                        ],
                      ),
                    ),
                    const SizedBox(width: 5.0),
                    Text(
                      'CHASSIS $unlockedCount/$totalCount',
                      style: const TextStyle(
                        color: Color(0xFFE0F2FE),
                        fontSize: 9.0,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                padding: const EdgeInsets.all(4.0),
                constraints: const BoxConstraints(),
                icon: const Icon(
                  Icons.close,
                  color: Color(0xFF94A3B8),
                  size: 20.0,
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 8.0),
          // 4px Glowing Track
          Stack(
            children: [
              Container(
                height: 4.0,
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(2.0),
                ),
              ),
              Container(
                width: 180.0,
                height: 4.0,
                decoration: BoxDecoration(
                  color: const Color(0xFF00F0FF),
                  borderRadius: BorderRadius.circular(2.0),
                  boxShadow: const [
                    BoxShadow(color: Color(0xFF00F0FF), blurRadius: 8.0),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildClassTabs() {
    final tabs = ['INTERCEPTOR', 'SIEGE DREAD', 'PHANTOM OPS'];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: Row(
        children: List.generate(tabs.length, (i) {
          final isActive = _activeClassTab == i;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: i < tabs.length - 1 ? 6.0 : 0.0),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  HapticService.instance.sowTick();
                  setState(() {
                    _activeClassTab = i;
                    if (i == 0) {
                      _activeId = 'mk1_bastion';
                    } else if (i == 1) {
                      _activeId = 'mk2_monsoon';
                    } else if (i == 2) {
                      _activeId = 'mk3_singularity';
                    }
                  });
                },
                child: Container(
                  height: 32.0,
                  decoration: BoxDecoration(
                    color: isActive
                        ? const Color(0xFF0284C7)
                        : const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(16.0),
                    border: Border.all(
                      color: isActive
                          ? const Color(0xFF00F0FF)
                          : const Color(0xFF1E293B),
                      width: 1.0,
                    ),
                    boxShadow: isActive
                        ? [
                            BoxShadow(
                              color: const Color(
                                0xFF00F0FF,
                              ).withValues(alpha: 0.3),
                              blurRadius: 8.0,
                            ),
                          ]
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    tabs[i],
                    style: TextStyle(
                      color: isActive ? Colors.white : const Color(0xFF94A3B8),
                      fontSize: 9.5,
                      fontWeight: isActive ? FontWeight.w900 : FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildHologramHeroCard(FleetChassis chassis) {
    Color classAccent;
    IconData classIcon;
    String classRole;
    String classCode;

    switch (chassis.chassisId) {
      case 'mk1_bastion':
        classAccent = const Color(0xFF00F0FF);
        classIcon = Icons.rocket_launch;
        classRole = 'Light Lateral Interceptor • Class A Flagship';
        classCode = 'INTERCEPTOR';
        break;
      case 'mk2_monsoon':
        classAccent = const Color(0xFFF59E0B);
        classIcon = Icons.shield_outlined;
        classRole = 'Heavy Orbital Siege-Dreadnought • Fortified Armor';
        classCode = 'SIEGE DREAD';
        break;
      case 'mk3_singularity':
        classAccent = const Color(0xFFA855F7);
        classIcon = Icons.auto_awesome;
        classRole = 'Classified Graviton Flagship • Pro Black-Ops Chassis';
        classCode = 'PHANTOM OPS';
        break;
      case 'mk4_golden_sovereign':
      default:
        classAccent = const Color(0xFFFBBF24);
        classIcon = Icons.military_tech;
        classRole = 'Gilded Solar Lattice Flagship • Radiant Antimatter Trails';
        classCode = 'DIVINE SOVEREIGN';
        break;
    }

    final isEquipped = chassis.chassisId == widget.selectedChassisId;

    return Container(
      padding: const EdgeInsets.all(18.0),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0C233C), Color(0xFF071322)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18.0),
        border: Border.all(color: classAccent, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: classAccent.withValues(alpha: 0.2),
            blurRadius: 20.0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Holographic Stage Viewer
          SizedBox(
            height: 140.0,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(280.0, 130.0),
                  painter: _HologramRingsPainter(),
                ),
                // Center Vessel Hologram Wireframe
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      classIcon,
                      color: classAccent,
                      size: 48.0,
                      shadows: [Shadow(color: classAccent, blurRadius: 16.0)],
                    ),
                    const SizedBox(height: 4.0),
                    Container(
                      width: 40.0,
                      height: 4.0,
                      decoration: BoxDecoration(
                        color: classAccent,
                        borderRadius: BorderRadius.circular(2.0),
                        boxShadow: [
                          BoxShadow(color: classAccent, blurRadius: 8.0),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10.0),

          // Metadata Row matching fleet_hangar.svg
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10.0,
                  vertical: 3.5,
                ),
                decoration: BoxDecoration(
                  color: isEquipped
                      ? const Color(0xFF0284C7)
                      : const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(9.0),
                  border: Border.all(
                    color: isEquipped
                        ? const Color(0xFF00F0FF)
                        : const Color(0xFF1E293B),
                    width: 1.0,
                  ),
                ),
                child: Text(
                  isEquipped ? 'ACTIVE VESSEL' : 'INSPECTION VIEW',
                  style: TextStyle(
                    color: isEquipped ? Colors.white : const Color(0xFF94A3B8),
                    fontSize: 8.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10.0,
                  vertical: 3.5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF032541),
                  borderRadius: BorderRadius.circular(9.0),
                  border: Border.all(color: classAccent, width: 1.0),
                ),
                child: Text(
                  classCode,
                  style: TextStyle(
                    color: classAccent,
                    fontSize: 8.0,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8.0),
          Text(
            chassis.name.toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17.0,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 2.0),
          Text(
            classRole,
            style: const TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 10.0,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14.0),

          // Tactical Stat Readouts
          Row(
            children: [
              Expanded(
                child: _buildStatMeter(
                  label: 'CAPACITOR',
                  value: '${chassis.coreCapacity} BAYS',
                  fraction: (chassis.coreCapacity / 48.0).clamp(0.0, 1.0),
                  meterColor: classAccent,
                ),
              ),
              const SizedBox(width: 8.0),
              Expanded(
                child: _buildStatMeter(
                  label: 'LANCE COEF',
                  value: 'α = ${chassis.lanceAlphaBonus.toStringAsFixed(2)}',
                  fraction: ((chassis.lanceAlphaBonus - 0.8) / 0.7).clamp(
                    0.0,
                    1.0,
                  ),
                  meterColor: const Color(0xFFF59E0B),
                ),
              ),
              const SizedBox(width: 8.0),
              Expanded(
                child: _buildStatMeter(
                  label: 'NYUMBA',
                  value: 'DUAL DOCK',
                  fraction: 1.0,
                  meterColor: const Color(0xFFD97706),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatMeter({
    required String label,
    required String value,
    required double fraction,
    required Color meterColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF64748B),
            fontSize: 7.5,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2.0),
        Text(
          value,
          style: TextStyle(
            color: meterColor,
            fontSize: 11.0,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4.0),
        Stack(
          children: [
            Container(
              height: 3.0,
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(1.5),
              ),
            ),
            FractionallySizedBox(
              widthFactor: fraction,
              child: Container(
                height: 3.0,
                decoration: BoxDecoration(
                  color: meterColor,
                  borderRadius: BorderRadius.circular(1.5),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildChassisCard(FleetChassis chassis, bool isEquipped) {
    final isPro = !chassis.isUnlocked && chassis.chassisId.contains('mk3');

    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: const Color(0xFF0A101D),
        borderRadius: BorderRadius.circular(14.0),
        border: Border.all(
          color: isEquipped
              ? const Color(0xFF00F0FF)
              : isPro
              ? const Color(0xFFF59E0B).withValues(alpha: 0.5)
              : const Color(0xFF1E293B),
          width: isEquipped ? 1.5 : 1.0,
        ),
        boxShadow: isEquipped
            ? [
                BoxShadow(
                  color: const Color(0xFF00F0FF).withValues(alpha: 0.2),
                  blurRadius: 10.0,
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          Container(
            width: 38.0,
            height: 38.0,
            decoration: BoxDecoration(
              color: isEquipped
                  ? const Color(0xFF071B2E)
                  : const Color(0xFF0F172A),
              shape: BoxShape.circle,
              border: Border.all(
                color: isEquipped
                    ? const Color(0xFF00F0FF)
                    : const Color(0xFF334155),
                width: 1.0,
              ),
            ),
            child: Icon(
              Icons.rocket,
              color: isEquipped
                  ? const Color(0xFF00F0FF)
                  : isPro
                  ? const Color(0xFFFBBF24)
                  : const Color(0xFF94A3B8),
              size: 20.0,
            ),
          ),
          const SizedBox(width: 12.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        chassis.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isPro) ...[
                      const SizedBox(width: 4.0),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4.0,
                          vertical: 1.0,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(3.0),
                        ),
                        child: const Text(
                          'PRO',
                          style: TextStyle(
                            color: Color(0xFFFBBF24),
                            fontSize: 7.5,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2.0),
                Text(
                  chassis.description,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 9.0,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4.0),
                Text(
                  '${chassis.coreCapacity} CORES • ${(chassis.lanceAlphaBonus * 100).toInt()}% LANCE ALPHA',
                  style: const TextStyle(
                    color: Color(0xFF38BDF8),
                    fontSize: 8.0,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10.0),

          // Action Button: EQUIPPED, EQUIP, UNLOCK PRO
          if (isEquipped)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12.0,
                vertical: 6.0,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF00F0FF).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14.0),
                border: Border.all(color: const Color(0xFF00F0FF), width: 1.0),
              ),
              child: const Text(
                'EQUIPPED',
                style: TextStyle(
                  color: Color(0xFF00F0FF),
                  fontSize: 9.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
            )
          else if (chassis.isUnlocked)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _selectChassis(chassis.chassisId),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14.0,
                  vertical: 6.0,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(14.0),
                  border: Border.all(
                    color: const Color(0xFF00F0FF),
                    width: 1.0,
                  ),
                ),
                child: const Text(
                  'EQUIP',
                  style: TextStyle(
                    color: Color(0xFF00F0FF),
                    fontSize: 9.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            )
          else
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _openProUpgrade,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10.0,
                  vertical: 6.0,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B),
                  borderRadius: BorderRadius.circular(14.0),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.4),
                      blurRadius: 8.0,
                    ),
                  ],
                ),
                child: const Text(
                  'UNLOCK PRO',
                  style: TextStyle(
                    color: Color(0xFF1C0F01),
                    fontSize: 9.0,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _HologramRingsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.65);

    final outerPaint = Paint()
      ..color = const Color(0xFF1E293B).withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final midPaint = Paint()
      ..color = const Color(0xFF00F0FF).withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final innerPaint = Paint()
      ..color = const Color(0xFF00F0FF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawOval(
      Rect.fromCenter(center: center, width: size.width * 0.9, height: 44.0),
      outerPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(center: center, width: size.width * 0.6, height: 30.0),
      midPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(center: center, width: size.width * 0.3, height: 16.0),
      innerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
