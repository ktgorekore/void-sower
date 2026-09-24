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
import '../../domain/services/fleet_service.dart';
import '../services/haptic_service.dart';
import '../theme/void_theme.dart';
import 'pro_upgrade_modal.dart';
import 'tactile_button.dart';

/// Interactive Fleet Hangar modal showcasing unlockable dreadnought chassis and stats.
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
  late final List<FleetChassis> _chassisList;

  @override
  void initState() {
    super.initState();
    _activeId = widget.selectedChassisId;
    _chassisList = FleetService.instance.getChassisList();
  }

  void _selectChassis(String id) {
    HapticService.instance.injectionClick();
    setState(() => _activeId = id);
    widget.onChassisSelected(id);
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
        constraints: const BoxConstraints(maxWidth: 480.0, maxHeight: 620.0),
        padding: const EdgeInsets.all(20.0),
        decoration: VoidTheme.glassmorphic(
          borderColor: VoidTheme.plasmaCyan,
          borderWidth: 1.5,
          borderRadius: 16.0,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              children: [
                const Icon(
                  Icons.rocket_launch,
                  color: VoidTheme.plasmaCyan,
                  size: 24.0,
                ),
                const SizedBox(width: 10.0),
                const Expanded(
                  child: Text(
                    'ORBITAL FLEET HANGAR',
                    style: TextStyle(
                      color: VoidTheme.plasmaCyan,
                      fontSize: 16.0,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: VoidTheme.textSecondary),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const Divider(color: VoidTheme.cardSurface, height: 16.0),

            // Chassis List
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.only(bottom: 24.0),
                itemCount: _chassisList.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12.0),
                itemBuilder: (context, index) {
                  final chassis = _chassisList[index];
                  final isEquipped = chassis.chassisId == _activeId;
                  return _buildChassisCard(chassis, isEquipped);
                },
              ),
            ),
            const SizedBox(height: 16.0),

            // Dismiss Button
            TactileButton(
              label: 'CLOSE HANGAR',
              onPressed: () => Navigator.of(context).pop(),
              accentColor: VoidTheme.plasmaCyan,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChassisCard(FleetChassis chassis, bool isEquipped) {
    final borderColor = isEquipped
        ? VoidTheme.plasmaCyan
        : VoidTheme.cardSurface.withValues(alpha: 0.8);

    return Container(
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        color: isEquipped
            ? VoidTheme.plasmaCyan.withValues(alpha: 0.12)
            : VoidTheme.cardSurface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: borderColor, width: isEquipped ? 2.0 : 1.0),
        boxShadow: isEquipped
            ? [
                BoxShadow(
                  color: VoidTheme.plasmaCyan.withValues(alpha: 0.25),
                  blurRadius: 10.0,
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6.0),
                decoration: BoxDecoration(
                  color: VoidTheme.obsidianBlack,
                  borderRadius: BorderRadius.circular(6.0),
                  border: Border.all(
                    color: isEquipped
                        ? VoidTheme.plasmaCyan
                        : VoidTheme.cardSurface,
                  ),
                ),
                child: Icon(
                  Icons.rocket_launch,
                  size: 16.0,
                  color: isEquipped
                      ? VoidTheme.plasmaCyan
                      : VoidTheme.textSecondary,
                ),
              ),
              const SizedBox(width: 8.0),
              Expanded(
                child: Text(
                  chassis.name,
                  style: TextStyle(
                    color: isEquipped
                        ? VoidTheme.plasmaCyan
                        : VoidTheme.textPrimary,
                    fontSize: 14.0,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(width: 8.0),
              if (isEquipped)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8.0,
                    vertical: 2.0,
                  ),
                  decoration: BoxDecoration(
                    color: VoidTheme.plasmaCyan.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(6.0),
                    border: Border.all(color: VoidTheme.plasmaCyan, width: 1.0),
                  ),
                  child: const Text(
                    'EQUIPPED',
                    style: TextStyle(
                      color: VoidTheme.plasmaCyan,
                      fontSize: 10.0,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6.0),
          Text(
            chassis.description,
            style: const TextStyle(
              color: VoidTheme.textSecondary,
              fontSize: 11.5,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12.0),

          // Stat Bars
          _buildStatRow(
            label: 'CORE CAPACITY',
            valueText: '${chassis.coreCapacity} Cores',
            fillFraction: (chassis.coreCapacity / 48.0).clamp(0.0, 1.0),
            color: VoidTheme.solarGold,
          ),
          const SizedBox(height: 6.0),
          _buildStatRow(
            label: 'LANCE ALPHA',
            valueText: '${(chassis.lanceAlphaBonus * 100).toInt()}%',
            fillFraction: ((chassis.lanceAlphaBonus - 0.8) / 0.7).clamp(
              0.0,
              1.0,
            ),
            color: VoidTheme.crimsonFlare,
          ),
          const SizedBox(height: 12.0),

          if (!isEquipped) ...[
            if (chassis.isUnlocked ||
                EntitlementService.instance.isFeatureAccessible(
                  ProFeature.mk3SingularityChassis,
                ))
              TactileButton(
                label: 'EQUIP SHIP',
                onPressed: () => _selectChassis(chassis.chassisId),
                accentColor: VoidTheme.solarGold,
                height: 38.0,
              )
            else
              TactileButton(
                label: 'LOCKED • UNLOCK PRO / AD PASS',
                icon: Icons.lock_outline,
                onPressed: () => _promptProChassis(chassis),
                accentColor: VoidTheme.crimsonFlare,
                height: 38.0,
              ),
          ],
        ],
      ),
    );
  }

  void _promptProChassis(FleetChassis chassis) {
    showDialog<void>(
      context: context,
      builder: (context) => ProUpgradeModal(
        highlightedFeature: ProFeature.mk3SingularityChassis,
        onUnlocked: () {
          setState(() {});
          _selectChassis(chassis.chassisId);
        },
      ),
    );
  }

  Widget _buildStatRow({
    required String label,
    required String valueText,
    required double fillFraction,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: VoidTheme.textMuted,
                fontSize: 10.0,
                letterSpacing: 0.8,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              valueText,
              style: TextStyle(
                color: color,
                fontSize: 10.5,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4.0),
        ClipRRect(
          borderRadius: BorderRadius.circular(4.0),
          child: LinearProgressIndicator(
            value: fillFraction,
            backgroundColor: VoidTheme.obsidianBlack,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 6.0,
          ),
        ),
      ],
    );
  }
}
