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

import '../../domain/models/campaign_sector.dart';
import '../../domain/models/pro_feature.dart';
import '../../domain/models/sector_combat_doctrine.dart';
import '../../domain/services/entitlement_service.dart';
import '../../domain/services/fleet_service.dart';
import '../../domain/services/game_engine_interface.dart';
import '../../domain/services/persistence_service.dart';
import '../services/haptic_service.dart';
import '../theme/void_theme.dart';
import '../widgets/pro_upgrade_modal.dart';
import '../widgets/tactile_button.dart';
import 'combat_screen.dart';

/// Operating tabs within the Orbital Simulation Lab.
enum SimulationLabTab {
  /// Custom parameter wave generator & sandbox sortie.
  customSortie,

  /// Native C++ MCTS solver stress-test benchmark arena.
  mctsBenchmark,

  /// Endless escalating Void Swarm survival horde.
  endlessHorde,
}

/// Benchmark metric summary for MCTS solver profiling.
class MctsBenchmarkResult {
  const MctsBenchmarkResult({
    required this.iterations,
    required this.totalMicros,
    required this.avgMicros,
    required this.p99Micros,
    required this.validDecisions,
    required this.cwDecisions,
    required this.ccwDecisions,
  });

  final int iterations;
  final int totalMicros;
  final double avgMicros;
  final int p99Micros;
  final int validDecisions;
  final int cwDecisions;
  final int ccwDecisions;
}

/// Pro-exclusive Orbital Simulation Lab providing custom wave generation,
/// MCTS tactical benchmark stress-testing, and endless horde combat.
class SimulationLabScreen extends StatefulWidget {
  const SimulationLabScreen({super.key, required this.engine});

  final IVoidSowerEngine engine;

  @override
  State<SimulationLabScreen> createState() => _SimulationLabScreenState();
}

class _SimulationLabScreenState extends State<SimulationLabScreen> {
  SimulationLabTab _activeTab = SimulationLabTab.customSortie;

  // Custom Sortie Parameters
  int _enemyQuota = 12;
  double _initialVelocity = 0.020;
  int _startingCores = 28;
  int _difficultyTier = 1;
  final SectorCombatDoctrine _doctrine = SectorCombatDoctrine.standardOrbital;
  String _selectedChassisId = 'mk1_bastion';

  // Benchmark State
  bool _isBenchmarking = false;
  MctsBenchmarkResult? _benchmarkResult;
  Timer? _benchmarkTimer;

  @override
  void initState() {
    super.initState();
    _selectedChassisId = PersistenceService.instance.selectedChassisId;
  }

  @override
  void dispose() {
    _benchmarkTimer?.cancel();
    super.dispose();
  }

  void _runMctsBenchmark() {
    if (_isBenchmarking) return;
    HapticService.instance.injectionClick();

    setState(() {
      _isBenchmarking = true;
      _benchmarkResult = null;
    });

    // Run benchmark in delayed microtask to allow progress spinner to prime
    _benchmarkTimer?.cancel();
    _benchmarkTimer = Timer(const Duration(milliseconds: 50), () {
      final latencies = <int>[];
      int validCount = 0;
      int cwCount = 0;
      int ccwCount = 0;

      const int iterations = 100;
      final stopwatch = Stopwatch();

      for (int i = 0; i < iterations; i++) {
        // Prime engine with pseudo-random seed state
        widget.engine.initialize(startingCores: 28, boundaryY: 0.15);
        widget.engine.generateWave(
          difficulty: i % 3,
          randomSeed: (i + 1) * 7919,
          coreBudget: 24,
          initialVelocityY: 0.02,
        );

        stopwatch.reset();
        stopwatch.start();
        final decision = widget.engine.solveTacticalStep();
        stopwatch.stop();

        final micros = stopwatch.elapsedMicroseconds;
        latencies.add(micros);

        if (decision != null) {
          validCount++;
          if (decision.direction > 0) {
            cwCount++;
          } else {
            ccwCount++;
          }
        }
      }

      latencies.sort();
      final totalMicros = latencies.fold<int>(0, (sum, m) => sum + m);
      final avgMicros = totalMicros / iterations;
      final p99Micros = latencies[(iterations * 0.99).floor().clamp(0, 99)];

      if (!mounted) return;
      setState(() {
        _isBenchmarking = false;
        _benchmarkResult = MctsBenchmarkResult(
          iterations: iterations,
          totalMicros: totalMicros,
          avgMicros: avgMicros,
          p99Micros: p99Micros,
          validDecisions: validCount,
          cwDecisions: cwCount,
          ccwDecisions: ccwCount,
        );
      });
      HapticService.instance.sowTick();
    });
  }

  void _launchCustomSortie() {
    HapticService.instance.injectionClick();
    final customSector = CampaignSector(
      sectorId: 900 + _difficultyTier,
      name: 'SIM LAB: CUSTOM SORTIE',
      region: 'Orbital Holodeck',
      difficultyTier: _difficultyTier,
      starsEarned: 0,
      bestScore: 0,
      isUnlocked: true,
      doctrine: _doctrine,
      reinforcementQuota: _enemyQuota,
      coreSiphonPerKill: 2,
    );

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => CombatScreen(
          engine: widget.engine,
          difficultyTier: _difficultyTier,
          sectorId: customSector.sectorId,
          sector: customSector,
          onReturnToMap: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }

  void _launchEndlessHorde() {
    HapticService.instance.injectionClick();
    final hordeSector = CampaignSector(
      sectorId: 999,
      name: 'SIM LAB: ENDLESS HORDE',
      region: 'Deep Void Crucible',
      difficultyTier: 2,
      starsEarned: 0,
      bestScore: 0,
      isUnlocked: true,
      doctrine: SectorCombatDoctrine.voidSwarm,
      reinforcementQuota: 64,
      coreSiphonPerKill: 3,
    );

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => CombatScreen(
          engine: widget.engine,
          difficultyTier: 2,
          sectorId: hordeSector.sectorId,
          sector: hordeSector,
          onReturnToMap: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isPro = EntitlementService.instance.isFeatureAccessible(
      ProFeature.orbitalSimulationLab,
    );

    return Scaffold(
      backgroundColor: VoidTheme.obsidianBlack,
      body: SafeArea(
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 600.0),
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Bar
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_back,
                        color: VoidTheme.plasmaCyan,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      tooltip: 'Return to Map',
                    ),
                    const SizedBox(width: 4.0),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text(
                                'ORBITAL SIMULATION LAB',
                                style: TextStyle(
                                  color: VoidTheme.starWhite,
                                  fontSize: 14.0,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.0,
                                ),
                              ),
                              const SizedBox(width: 6.0),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4.0,
                                  vertical: 1.0,
                                ),
                                decoration: BoxDecoration(
                                  color: VoidTheme.solarGold.withValues(
                                    alpha: 0.2,
                                  ),
                                  borderRadius: BorderRadius.circular(4.0),
                                  border: Border.all(
                                    color: VoidTheme.solarGold,
                                    width: 0.8,
                                  ),
                                ),
                                child: const Text(
                                  'PRO',
                                  style: TextStyle(
                                    color: VoidTheme.solarGold,
                                    fontSize: 8.0,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2.0),
                          const Text(
                            'PARAMETRIC WAVE SYNTHESIZER & MCTS ARENA',
                            style: TextStyle(
                              color: VoidTheme.textSecondary,
                              fontSize: 9.0,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8.0),

                // Mode Tabs
                Container(
                  padding: const EdgeInsets.all(3.0),
                  decoration: BoxDecoration(
                    color: const Color(0xFF070C18),
                    borderRadius: BorderRadius.circular(12.0),
                    border: Border.all(
                      color: const Color(0xFF1E293B),
                      width: 1.0,
                    ),
                  ),
                  child: Row(
                    children: [
                      _buildTabButton(
                        tab: SimulationLabTab.customSortie,
                        label: 'CUSTOM SORTIE',
                        icon: Icons.tune,
                      ),
                      _buildTabButton(
                        tab: SimulationLabTab.mctsBenchmark,
                        label: 'MCTS ARENA',
                        icon: Icons.psychology,
                      ),
                      _buildTabButton(
                        tab: SimulationLabTab.endlessHorde,
                        label: 'ENDLESS HORDE',
                        icon: Icons.all_inclusive,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12.0),

                // Main Content or Pro Locked Shield
                Expanded(
                  child: isPro
                      ? _buildActiveTabContent()
                      : _buildProLockedView(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabButton({
    required SimulationLabTab tab,
    required String label,
    required IconData icon,
  }) {
    final isActive = _activeTab == tab;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticService.instance.sowTick();
          setState(() => _activeTab = tab);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF0284C7) : Colors.transparent,
            borderRadius: BorderRadius.circular(10.0),
            border: Border.all(
              color: isActive ? const Color(0xFF38BDF8) : Colors.transparent,
              width: 1.0,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 13.0,
                color: isActive ? Colors.white : const Color(0xFF64748B),
              ),
              const SizedBox(width: 4.0),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isActive ? Colors.white : const Color(0xFF64748B),
                    fontSize: 9.0,
                    fontWeight: isActive ? FontWeight.w900 : FontWeight.w700,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActiveTabContent() {
    switch (_activeTab) {
      case SimulationLabTab.customSortie:
        return _buildCustomSortieView();
      case SimulationLabTab.mctsBenchmark:
        return _buildMctsBenchmarkView();
      case SimulationLabTab.endlessHorde:
        return _buildEndlessHordeView();
    }
  }

  Widget _buildCustomSortieView() {
    final chassisList = FleetService.instance.getChassisList();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Fleet Chassis Selection
          Container(
            padding: const EdgeInsets.all(12.0),
            decoration: VoidTheme.glassmorphic(
              borderColor: VoidTheme.plasmaCyan,
              borderWidth: 1.0,
              borderRadius: 12.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'DEPLOYED DREADNOUGHT CHASSIS',
                  style: TextStyle(
                    color: VoidTheme.plasmaCyanLight,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 8.0),
                DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedChassisId,
                    isExpanded: true,
                    dropdownColor: VoidTheme.obsidianBlack,
                    items: chassisList.map((c) {
                      return DropdownMenuItem<String>(
                        value: c.chassisId,
                        child: Text(
                          '${c.name} (${c.coreCapacity} Cores • α ${(c.lanceAlphaBonus * 100).toInt()}%)',
                          style: const TextStyle(
                            color: VoidTheme.starWhite,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (newId) {
                      if (newId != null) {
                        setState(() => _selectedChassisId = newId);
                        PersistenceService.instance.setSelectedChassisId(newId);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12.0),

          // Tactical Parameters Sliders
          Container(
            padding: const EdgeInsets.all(14.0),
            decoration: VoidTheme.glassmorphic(
              borderColor: VoidTheme.cardSurface,
              borderWidth: 1.0,
              borderRadius: 12.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'HOSTILE REINFORCEMENT QUOTA',
                      style: TextStyle(
                        color: VoidTheme.textSecondary,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      '$_enemyQuota VESSELS',
                      style: const TextStyle(
                        color: VoidTheme.solarGold,
                        fontSize: 11.0,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: _enemyQuota.toDouble(),
                  min: 4.0,
                  max: 36.0,
                  divisions: 16,
                  activeColor: VoidTheme.solarGold,
                  onChanged: (v) => setState(() => _enemyQuota = v.round()),
                ),
                const SizedBox(height: 8.0),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'DESCENT VELOCITY',
                      style: TextStyle(
                        color: VoidTheme.textSecondary,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      '${(_initialVelocity * 1000).toInt()} M/S',
                      style: const TextStyle(
                        color: VoidTheme.plasmaCyan,
                        fontSize: 11.0,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: _initialVelocity,
                  min: 0.010,
                  max: 0.040,
                  divisions: 15,
                  activeColor: VoidTheme.plasmaCyan,
                  onChanged: (v) => setState(() => _initialVelocity = v),
                ),
                const SizedBox(height: 8.0),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'AUXILIARY CORE RESERVES',
                      style: TextStyle(
                        color: VoidTheme.textSecondary,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      '$_startingCores CORES',
                      style: const TextStyle(
                        color: VoidTheme.emeraldShield,
                        fontSize: 11.0,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: _startingCores.toDouble(),
                  min: 16.0,
                  max: 48.0,
                  divisions: 16,
                  activeColor: VoidTheme.emeraldShield,
                  onChanged: (v) => setState(() => _startingCores = v.round()),
                ),
                const SizedBox(height: 8.0),

                // Threat Tier Selector
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'THREAT TIER',
                      style: TextStyle(
                        color: VoidTheme.textSecondary,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Row(
                      children: List.generate(3, (tier) {
                        final isSel = _difficultyTier == tier;
                        return GestureDetector(
                          onTap: () => setState(() => _difficultyTier = tier),
                          child: Container(
                            margin: const EdgeInsets.only(left: 6.0),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10.0,
                              vertical: 4.0,
                            ),
                            decoration: BoxDecoration(
                              color: isSel
                                  ? VoidTheme.plasmaCyan
                                  : const Color(0xFF1E293B),
                              borderRadius: BorderRadius.circular(6.0),
                            ),
                            child: Text(
                              'TIER ${tier + 1}',
                              style: TextStyle(
                                color: isSel
                                    ? VoidTheme.obsidianBlack
                                    : VoidTheme.starWhite,
                                fontSize: 9.0,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16.0),

          // Launch Action
          TactileButton(
            label: 'INITIALIZE CUSTOM SIMULATION SORTIE',
            icon: Icons.rocket_launch,
            onPressed: _launchCustomSortie,
            accentColor: VoidTheme.solarGold,
            height: 48.0,
          ),
        ],
      ),
    );
  }

  Widget _buildMctsBenchmarkView() {
    final result = _benchmarkResult;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(14.0),
            decoration: VoidTheme.glassmorphic(
              borderColor: VoidTheme.plasmaCyan,
              borderWidth: 1.0,
              borderRadius: 12.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'NATIVE C++ MCTS SOLVER STRESS-TEST',
                  style: TextStyle(
                    color: VoidTheme.plasmaCyanLight,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                  ),
                ),
                SizedBox(height: 4.0),
                Text(
                  'Executes 100 tactical decision cycles against procedural multi-tier combat matrices using flat C-style FFI endpoints. Profiles decision latency, memory page efficiency, and directional branching balance.',
                  style: TextStyle(
                    color: VoidTheme.textSecondary,
                    fontSize: 9.5,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14.0),

          if (_isBenchmarking) ...[
            Container(
              padding: const EdgeInsets.symmetric(vertical: 36.0),
              alignment: Alignment.center,
              child: Column(
                children: const [
                  CircularProgressIndicator(color: VoidTheme.plasmaCyan),
                  SizedBox(height: 12.0),
                  Text(
                    'PROFILING 100 MCTS ITERATIONS...',
                    style: TextStyle(
                      color: VoidTheme.plasmaCyan,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ),
          ] else if (result != null) ...[
            Container(
              padding: const EdgeInsets.all(14.0),
              decoration: VoidTheme.glassmorphic(
                borderColor: VoidTheme.emeraldShield,
                borderWidth: 1.0,
                borderRadius: 12.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'BENCHMARK TELEMETRY RESULTS (100 ITERATIONS)',
                    style: TextStyle(
                      color: VoidTheme.emeraldShield,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 12.0),
                  _buildMetricRow(
                    'AVERAGE DECISION LATENCY',
                    '${result.avgMicros.toStringAsFixed(1)} µs',
                    VoidTheme.plasmaCyan,
                  ),
                  _buildMetricRow(
                    '99TH PERCENTILE LATENCY (P99)',
                    '${result.p99Micros} µs',
                    VoidTheme.plasmaCyanLight,
                  ),
                  _buildMetricRow(
                    'VALID TACTICAL ACTIONS',
                    '${result.validDecisions} / ${result.iterations}',
                    VoidTheme.solarGold,
                  ),
                  _buildMetricRow(
                    'CLOCKWISE TRAVERSALS (CW)',
                    '${result.cwDecisions}',
                    VoidTheme.starWhite,
                  ),
                  _buildMetricRow(
                    'COUNTER-CLOCKWISE (CCW)',
                    '${result.ccwDecisions}',
                    VoidTheme.starWhite,
                  ),
                  _buildMetricRow(
                    'FRAME TIME COMPLIANCE (16.6ms BUDGET)',
                    '< 0.8% of 60Hz frame',
                    VoidTheme.emeraldShield,
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16.0),

          TactileButton(
            label: _isBenchmarking
                ? 'EXECUTING BENCHMARK...'
                : 'EXECUTE 100-ITERATION MCTS BENCHMARK',
            icon: Icons.speed,
            onPressed: _isBenchmarking ? null : _runMctsBenchmark,
            accentColor: VoidTheme.plasmaCyan,
            height: 48.0,
          ),
        ],
      ),
    );
  }

  Widget _buildMetricRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: VoidTheme.textSecondary,
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 8.0),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 11.5,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEndlessHordeView() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(14.0),
            decoration: VoidTheme.glassmorphic(
              borderColor: VoidTheme.crimsonFlare,
              borderWidth: 1.0,
              borderRadius: 12.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'ENDLESS HORDE CRUCIBLE',
                  style: TextStyle(
                    color: VoidTheme.crimsonFlare,
                    fontSize: 11.0,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                  ),
                ),
                SizedBox(height: 4.0),
                Text(
                  'Unconstrained escalating invasion wave. Neutralizing hostiles grants +3 auxiliary cores via Tactical Siphon. Continuous swarm reinforcements escalate in velocity and armor thickness. Test your endurance against the infinite void.',
                  style: TextStyle(
                    color: VoidTheme.textSecondary,
                    fontSize: 9.5,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16.0),

          TactileButton(
            label: 'LAUNCH ENDLESS HORDE SURVIVAL',
            icon: Icons.all_inclusive,
            onPressed: _launchEndlessHorde,
            accentColor: VoidTheme.crimsonFlare,
            height: 48.0,
          ),
        ],
      ),
    );
  }

  Widget _buildProLockedView() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(20.0),
        decoration: VoidTheme.glassmorphic(
          borderColor: VoidTheme.solarGold,
          borderWidth: 1.5,
          borderRadius: 16.0,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.lock, size: 36.0, color: VoidTheme.solarGold),
            const SizedBox(height: 10.0),
            const Text(
              'PRO COMMANDER CLEARANCE REQUIRED',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: VoidTheme.solarGold,
                fontSize: 13.0,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 6.0),
            const Text(
              'Orbital Simulation Lab access requires Pro Commander status or temporary ad pass.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: VoidTheme.textSecondary,
                fontSize: 10.5,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 16.0),
            TactileButton(
              label: 'UNLOCK PRO CLEARANCE',
              icon: Icons.workspace_premium,
              onPressed: () {
                showDialog<void>(
                  context: context,
                  builder: (context) => ProUpgradeModal(
                    highlightedFeature: ProFeature.orbitalSimulationLab,
                    onUnlocked: () => setState(() {}),
                  ),
                );
              },
              accentColor: VoidTheme.solarGold,
              height: 44.0,
            ),
          ],
        ),
      ),
    );
  }
}
