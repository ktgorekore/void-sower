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
import '../theme/void_theme.dart';

/// Player profile and lifetime telemetry statistics dashboard.
class StatsDashboardScreen extends StatelessWidget {
  const StatsDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = PersistenceService.instance;

    return Scaffold(
      backgroundColor: VoidTheme.obsidianBlack,
      appBar: AppBar(
        backgroundColor: VoidTheme.obsidianBlack,
        title: const Text(
          'FLEET TELEMETRY',
          style: TextStyle(
            color: VoidTheme.solarGold,
            letterSpacing: 2.0,
            fontSize: 16.0,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600.0),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              _buildStatCard(
                'HIGHEST COMBAT SCORE',
                '${p.highScore}',
                VoidTheme.solarGold,
              ),
              const SizedBox(height: 12.0),
              _buildStatCard(
                'LIBERATED SECTORS',
                '${p.liberatedSectors} / 9',
                VoidTheme.plasmaCyan,
              ),
              const SizedBox(height: 12.0),
              _buildStatCard(
                'LICENSE STATUS',
                p.isProUnlocked ? 'PRO COMMANDER' : 'RECRUIT PILOT',
                Colors.white,
              ),
              const Spacer(),
              OutlinedButton.icon(
                icon: const Icon(
                  Icons.delete_outline,
                  color: VoidTheme.crimsonFlare,
                ),
                label: const Text(
                  'ERASE GUEST DATA (GDPR)',
                  style: TextStyle(color: VoidTheme.crimsonFlare),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: VoidTheme.crimsonFlare),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 12.0,
                  ),
                ),
                onPressed: () async {
                  await p.wipeAllData();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('All local guest data erased.'),
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: VoidTheme.cardSurface,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: VoidTheme.textMuted.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: VoidTheme.textMuted,
              fontSize: 11.0,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 6.0),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 20.0,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
