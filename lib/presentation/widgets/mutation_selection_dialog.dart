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

import '../../domain/models/sowing_mutation.dart';
import '../services/haptic_service.dart';
import '../theme/void_theme.dart';

/// Modal dialog presented between incursion waves enabling commanders
/// to select 1 of 3 randomized rogue-lite Sowing Mutations.
class MutationSelectionDialog extends StatelessWidget {
  const MutationSelectionDialog({
    super.key,
    required this.waveNumber,
    required this.mutations,
    required this.onSelected,
  });

  /// The wave number just completed.
  final int waveNumber;

  /// The 3 candidate mutations to choose from.
  final List<SowingMutation> mutations;

  /// Callback when a mutation is selected.
  final ValueChanged<SowingMutation> onSelected;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(
        horizontal: 16.0,
        vertical: 24.0,
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420.0),
        padding: const EdgeInsets.all(18.0),
        decoration: BoxDecoration(
          color: VoidTheme.obsidianBlack.withValues(alpha: 0.96),
          borderRadius: BorderRadius.circular(20.0),
          border: Border.all(
            color: VoidTheme.plasmaCyan.withValues(alpha: 0.8),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: VoidTheme.plasmaCyan.withValues(alpha: 0.25),
              blurRadius: 24.0,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Header: Holographic Insignia & Title
            Row(
              children: [
                Container(
                  width: 36.0,
                  height: 36.0,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: VoidTheme.plasmaCyan.withValues(alpha: 0.15),
                    border: Border.all(color: VoidTheme.plasmaCyan, width: 1.5),
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    color: VoidTheme.plasmaCyan,
                    size: 20.0,
                  ),
                ),
                const SizedBox(width: 10.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'WAVE $waveNumber SURVIVED',
                        style: const TextStyle(
                          color: VoidTheme.emeraldShield,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 2.0),
                      const Text(
                        'SELECT SOWING MUTATION',
                        style: TextStyle(
                          color: VoidTheme.starWhite,
                          fontSize: 14.0,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14.0),
            const Divider(color: VoidTheme.cardSurface, height: 1.0),
            const SizedBox(height: 14.0),

            // 3 Mutation Cards
            ...mutations.map(
              (mutation) => _buildMutationCard(context, mutation),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMutationCard(BuildContext context, SowingMutation mutation) {
    String rarityLabel;
    Color rarityColor;
    switch (mutation.rarity) {
      case MutationRarity.legendary:
        rarityLabel = 'LEGENDARY RELIC';
        rarityColor = VoidTheme.solarGold;
        break;
      case MutationRarity.rare:
        rarityLabel = 'RARE MUTATION';
        rarityColor = VoidTheme.plasmaCyanLight;
        break;
      case MutationRarity.common:
        rarityLabel = 'STANDARD MODIFIER';
        rarityColor = VoidTheme.emeraldShield;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14.0),
          onTap: () {
            HapticService.instance.injectionClick();
            onSelected(mutation);
          },
          child: Container(
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: VoidTheme.cardSurface.withValues(alpha: 0.65),
              borderRadius: BorderRadius.circular(14.0),
              border: Border.all(
                color: mutation.accentColor.withValues(alpha: 0.6),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: mutation.accentColor.withValues(alpha: 0.15),
                  blurRadius: 10.0,
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon Avatar
                Container(
                  width: 42.0,
                  height: 42.0,
                  decoration: BoxDecoration(
                    color: mutation.accentColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10.0),
                    border: Border.all(
                      color: mutation.accentColor.withValues(alpha: 0.8),
                      width: 1.2,
                    ),
                  ),
                  child: Icon(
                    mutation.icon,
                    color: mutation.accentColor,
                    size: 22.0,
                  ),
                ),
                const SizedBox(width: 12.0),
                // Text Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              mutation.title,
                              style: TextStyle(
                                color: mutation.accentColor,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.6,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6.0,
                              vertical: 2.0,
                            ),
                            decoration: BoxDecoration(
                              color: rarityColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4.0),
                              border: Border.all(
                                color: rarityColor.withValues(alpha: 0.5),
                                width: 0.8,
                              ),
                            ),
                            child: Text(
                              rarityLabel,
                              style: TextStyle(
                                color: rarityColor,
                                fontSize: 7.5,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2.0),
                      Text(
                        mutation.subtitle,
                        style: const TextStyle(
                          color: VoidTheme.textSecondary,
                          fontSize: 8.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.4,
                        ),
                      ),
                      const SizedBox(height: 5.0),
                      Text(
                        mutation.description,
                        style: const TextStyle(
                          color: VoidTheme.starWhite,
                          fontSize: 10.5,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
