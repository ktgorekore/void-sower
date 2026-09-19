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
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:void_sower/domain/models/prediction_result.dart';
import 'package:void_sower/domain/models/user_profile.dart';
import 'package:void_sower/domain/services/campaign_service.dart';
import 'package:void_sower/domain/services/persistence_service.dart';
import 'package:void_sower/engine/mock_void_sower_engine.dart';
import 'package:void_sower/presentation/controllers/combat_coordinator.dart';
import 'package:void_sower/presentation/screens/stats_dashboard_screen.dart';
import 'package:void_sower/presentation/widgets/profile_modal.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await PersistenceService.instance.initialize();
    await PersistenceService.instance.wipeAllData();
  });

  group('UserProfile Telemetry & Derived Metrics Tests', () {
    test('default telemetry properties initialize cleanly', () {
      const profile = UserProfile();
      expect(profile.missionsPlayed, 0);
      expect(profile.victories, 0);
      expect(profile.defeats, 0);
      expect(profile.flawlessVictories, 0);
      expect(profile.totalSeedsSown, 0);
      expect(profile.flakBurstsTriggered, 0);
      expect(profile.totalCoresSaved, 0);
      expect(profile.currentStreak, 0);
      expect(profile.longestStreak, 0);
      expect(profile.lastPlayedDate, isNull);
      expect(profile.totalFlightTimeSeconds, 0);
      expect(profile.chassisSorties, isEmpty);
      expect(profile.campaignSorties, isEmpty);
      expect(profile.winRate, 0.0);
      expect(profile.averageScore, 0);
      expect(profile.combatEfficiency, 0.0);
      expect(profile.flawlessRate, 0.0);
      expect(profile.favoriteChassisId, 'mk1_bastion');
      expect(profile.favoriteChassisName, 'MK-I Bastion Standard');
      expect(profile.formattedFlightTime, '0s');
    });

    test('derived metrics calculate accurately', () {
      const profile = UserProfile(
        lifetimeScore: 50000,
        enemiesDestroyed: 60,
        lancesFired: 20,
        missionsPlayed: 10,
        victories: 8,
        defeats: 2,
        flawlessVictories: 4,
        totalFlightTimeSeconds: 3725, // 1h 2m 5s
        chassisSorties: {'mk1_bastion': 2, 'mk2_monsoon': 8},
      );

      expect(profile.winRate, 80.0);
      expect(profile.averageScore, 5000);
      expect(profile.combatEfficiency, 3.0);
      expect(profile.flawlessRate, 50.0);
      expect(profile.favoriteChassisId, 'mk2_monsoon');
      expect(profile.favoriteChassisName, 'MK-II Monsoon Vanguard');
      expect(profile.formattedFlightTime, '1h 2m');
    });

    test('flight time formatting handles edge cases', () {
      expect(
        const UserProfile(totalFlightTimeSeconds: 45).formattedFlightTime,
        '45s',
      );
      expect(
        const UserProfile(totalFlightTimeSeconds: 135).formattedFlightTime,
        '2m 15s',
      );
      expect(
        const UserProfile(totalFlightTimeSeconds: 3600).formattedFlightTime,
        '1h 0m',
      );
    });

    test('favorite chassis name maps all 4 variants', () {
      expect(
        const UserProfile(
          chassisSorties: {'mk1_bastion': 5},
        ).favoriteChassisName,
        'MK-I Bastion Standard',
      );
      expect(
        const UserProfile(
          chassisSorties: {'mk2_monsoon': 5},
        ).favoriteChassisName,
        'MK-II Monsoon Vanguard',
      );
      expect(
        const UserProfile(
          chassisSorties: {'mk3_singularity': 5},
        ).favoriteChassisName,
        'MK-III Singularity Sovereign',
      );
      expect(
        const UserProfile(
          chassisSorties: {'mk4_golden_sovereign': 5},
        ).favoriteChassisName,
        'MK-IV Golden Sovereign',
      );
    });

    test('toJson and fromJson round-trip preserves all telemetry', () {
      const original = UserProfile(
        id: 'pilot_phoenix',
        callsign: 'Phoenix-9',
        insignia: PilotInsignia.shonaStar,
        lifetimeScore: 12500,
        enemiesDestroyed: 44,
        lancesFired: 18,
        maxCascadeLaps: 5,
        missionsPlayed: 6,
        victories: 5,
        defeats: 1,
        flawlessVictories: 3,
        totalSeedsSown: 88,
        flakBurstsTriggered: 7,
        totalCoresSaved: 92,
        currentStreak: 4,
        longestStreak: 12,
        lastPlayedDate: '2026-09-19',
        totalFlightTimeSeconds: 840,
        chassisSorties: {'mk1_bastion': 2, 'mk2_monsoon': 4},
        campaignSorties: {'kilwa_basin': 4, 'phantom_drift': 2},
      );

      final json = original.toJson();
      final restored = UserProfile.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.callsign, original.callsign);
      expect(restored.insignia, original.insignia);
      expect(restored.lifetimeScore, original.lifetimeScore);
      expect(restored.enemiesDestroyed, original.enemiesDestroyed);
      expect(restored.lancesFired, original.lancesFired);
      expect(restored.maxCascadeLaps, original.maxCascadeLaps);
      expect(restored.missionsPlayed, original.missionsPlayed);
      expect(restored.victories, original.victories);
      expect(restored.defeats, original.defeats);
      expect(restored.flawlessVictories, original.flawlessVictories);
      expect(restored.totalSeedsSown, original.totalSeedsSown);
      expect(restored.flakBurstsTriggered, original.flakBurstsTriggered);
      expect(restored.totalCoresSaved, original.totalCoresSaved);
      expect(restored.currentStreak, original.currentStreak);
      expect(restored.longestStreak, original.longestStreak);
      expect(restored.lastPlayedDate, original.lastPlayedDate);
      expect(restored.totalFlightTimeSeconds, original.totalFlightTimeSeconds);
      expect(restored.chassisSorties, original.chassisSorties);
      expect(restored.campaignSorties, original.campaignSorties);
    });
  });

  group('PersistenceService Telemetry Tracking Tests', () {
    test('recordSectorVictory updates all telemetry fields', () async {
      final p = PersistenceService.instance;
      expect(p.userProfile.missionsPlayed, 0);

      await p.recordSectorVictory(
        sectorId: 1,
        score: 3500,
        coresRemaining: 18,
        enemiesNeutralized: 4,
        lancesFired: 6,
        flakBursts: 2,
        seedsSown: 12,
        maxCascadeLaps: 3,
        flightTimeSeconds: 75,
        chassisId: 'mk2_monsoon',
        campaignId: 'kilwa_basin',
      );

      final profile = p.userProfile;
      expect(profile.missionsPlayed, 1);
      expect(profile.victories, 1);
      expect(profile.defeats, 0);
      expect(profile.flawlessVictories, 1); // coresRemaining >= 16
      expect(profile.lifetimeScore, 3500);
      expect(profile.enemiesDestroyed, 4);
      expect(profile.lancesFired, 6);
      expect(profile.flakBurstsTriggered, 2);
      expect(profile.totalSeedsSown, 12);
      expect(profile.totalCoresSaved, 18);
      expect(profile.maxCascadeLaps, 3);
      expect(profile.totalFlightTimeSeconds, 75);
      expect(profile.currentStreak, 1);
      expect(profile.longestStreak, 1);
      expect(profile.lastPlayedDate, isNotNull);
      expect(profile.chassisSorties['mk2_monsoon'], 1);
      expect(profile.campaignSorties['kilwa_basin'], 1);
    });

    test('recordSectorDefeat records loss, streak, and flight time', () async {
      final p = PersistenceService.instance;

      await p.recordSectorDefeat(
        sectorId: 2,
        score: 1200,
        lancesFired: 4,
        flakBursts: 1,
        seedsSown: 8,
        maxCascadeLaps: 2,
        flightTimeSeconds: 40,
        chassisId: 'mk1_bastion',
        campaignId: 'kilwa_basin',
      );

      final profile = p.userProfile;
      expect(profile.missionsPlayed, 1);
      expect(profile.victories, 0);
      expect(profile.defeats, 1);
      expect(profile.flawlessVictories, 0);
      expect(profile.lifetimeScore, 1200);
      expect(profile.lancesFired, 4);
      expect(profile.flakBurstsTriggered, 1);
      expect(profile.totalSeedsSown, 8);
      expect(profile.totalFlightTimeSeconds, 40);
      expect(profile.chassisSorties['mk1_bastion'], 1);
      expect(profile.currentStreak, 1);
    });

    test('selectedChassisId persists and exports/imports cleanly', () async {
      final p = PersistenceService.instance;
      expect(p.selectedChassisId, 'mk1_bastion');

      await p.setSelectedChassisId('mk3_singularity');
      expect(p.selectedChassisId, 'mk3_singularity');

      final exportStr = p.exportSaveJson();
      await p.wipeAllData();
      expect(p.selectedChassisId, 'mk1_bastion');

      final imported = await p.importSaveJson(exportStr);
      expect(imported, isTrue);
      expect(p.selectedChassisId, 'mk3_singularity');
    });

    test('CampaignService star and liberated sector aggregators', () {
      final cs = CampaignService.instance;
      expect(cs.getTotalStarsEarned(), isNonNegative);
      expect(cs.getTotalLiberatedSectors(), isNonNegative);
      expect(cs.getStarsEarnedForCampaign('kilwa_basin'), isNonNegative);
      expect(cs.getLiberatedCountForCampaign('kilwa_basin'), isNonNegative);
    });
  });

  group('CombatCoordinator Session Telemetry Collection Tests', () {
    test('session telemetry initializes and accumulates correctly', () {
      final coordinator = CombatCoordinator(engine: MockVoidSowerEngine());
      coordinator.initialize(difficulty: 1);

      expect(coordinator.sessionLancesFired, 0);
      expect(coordinator.sessionFlakBursts, 0);
      expect(coordinator.sessionSeedsSown, 0);
      expect(coordinator.sessionMaxCascade, 0);
      expect(coordinator.sessionFlightTimeSeconds, isNonNegative);

      // Sowing actions accumulate seeds
      coordinator.injectCore(8, 1);
      expect(coordinator.sessionSeedsSown, 1);

      // Prediction updates max cascade
      coordinator.prediction = const PredictionResult(
        terminalBay: 9,
        terminalCorridor: 1,
        finalMass: 4,
        predictedDamage: 100.0,
        totalCascadeLaps: 4,
        triggersLance: true,
        triggersRelay: false,
      );
      expect(coordinator.sessionMaxCascade, 4);

      // Re-initialization resets session metrics
      coordinator.initialize();
      expect(coordinator.sessionSeedsSown, 0);
      expect(coordinator.sessionMaxCascade, 0);
    });
  });

  group('StatsDashboardScreen UI Widget Tests', () {
    testWidgets('renders all 7 tactical telemetry cards and data controls', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(480, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      // Prime persistent profile with rich telemetry
      final p = PersistenceService.instance;
      await p.recordSectorVictory(
        sectorId: 1,
        score: 4200,
        coresRemaining: 18,
        enemiesNeutralized: 4,
        lancesFired: 8,
        flakBursts: 3,
        seedsSown: 16,
        maxCascadeLaps: 4,
        flightTimeSeconds: 120,
        chassisId: 'mk2_monsoon',
        campaignId: 'kilwa_basin',
      );

      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: StatsDashboardScreen())),
      );
      await tester.pumpAndSettle();

      // App Bar
      expect(find.text('FLEET TELEMETRY'), findsOneWidget);

      // Card 1: Pilot Dossier
      expect(find.text('VANGUARD-01'), findsOneWidget);
      expect(find.text('RECRUIT PILOT'), findsOneWidget);
      expect(find.textContaining('RANK:'), findsOneWidget);

      // Card 2: Deployment Readiness & Habit
      expect(find.text('DEPLOYMENT READINESS & HABIT'), findsOneWidget);
      expect(find.text('1 DAYS ACTIVE'), findsOneWidget);
      expect(find.text('LONGEST STREAK'), findsOneWidget);
      expect(find.text('FLIGHT TIME'), findsOneWidget);

      // Card 3: Mission Outcomes & Win Rate
      expect(find.text('MISSION OUTCOMES & WIN RATE'), findsOneWidget);
      expect(find.text('100%'), findsOneWidget); // 1 victory, 0 defeat
      expect(find.text('SORTIES'), findsOneWidget);
      expect(find.text('VICTORIES'), findsOneWidget);
      expect(find.text('DEFEATS'), findsOneWidget);
      expect(find.text('FLAWLESS'), findsOneWidget);

      // Card 4: Tactical Sensor Log & Metrics
      expect(find.text('TACTICAL SENSOR LOG & COMBAT METRICS'), findsOneWidget);
      expect(find.text('HIGHEST COMBAT SCORE'), findsOneWidget);
      expect(find.text('ENEMIES DESTROYED'), findsOneWidget);
      expect(find.text('LANCES DISCHARGED'), findsOneWidget);
      expect(find.text('PLASMA CORES SOWN'), findsOneWidget);
      expect(find.text('CORES PRESERVED'), findsOneWidget);
      expect(find.text('MAX CASCADE COMBO'), findsOneWidget);

      // Card 5: Multi-Theater Campaign Mastery
      await tester.scrollUntilVisible(
        find.text('CAMPAIGN THEATER MASTERY'),
        200.0,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('CAMPAIGN THEATER MASTERY'), findsOneWidget);
      expect(find.text('KILWA BASIN'), findsOneWidget);
      expect(find.text('PHANTOM DRIFT'), findsOneWidget);
      expect(find.text('VOID SWARM'), findsOneWidget);

      // Card 6: Fleet Chassis Deployment
      await tester.scrollUntilVisible(
        find.text('FLEET CHASSIS DEPLOYMENT'),
        200.0,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('FLEET CHASSIS DEPLOYMENT'), findsOneWidget);
      expect(find.text('MK-I Bastion Standard'), findsOneWidget);
      expect(find.text('MK-II Monsoon Vanguard'), findsOneWidget);

      // Card 7: Data Management & GDPR
      await tester.scrollUntilVisible(
        find.text('EXPORT SAVE'),
        200.0,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('EXPORT SAVE'), findsOneWidget);
      expect(find.text('IMPORT SAVE'), findsOneWidget);
      expect(find.text('ERASE GUEST DATA (GDPR)'), findsOneWidget);
    });

    testWidgets('GDPR confirmation modal cancels safely without erasing data', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(480, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final p = PersistenceService.instance;
      await p.setHighScore(9999);

      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: StatsDashboardScreen())),
      );
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('ERASE GUEST DATA (GDPR)'),
        200.0,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('ERASE GUEST DATA (GDPR)'));
      await tester.pumpAndSettle();

      expect(find.text('ERASE GUEST TELEMETRY?'), findsOneWidget);
      await tester.tap(find.text('CANCEL'));
      await tester.pumpAndSettle();

      expect(p.highScore, 9999);
    });

    testWidgets('GDPR confirmation modal purges guest data on confirm', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(480, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final p = PersistenceService.instance;
      await p.setHighScore(9999);

      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: StatsDashboardScreen())),
      );
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('ERASE GUEST DATA (GDPR)'),
        200.0,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('ERASE GUEST DATA (GDPR)'));
      await tester.pumpAndSettle();

      expect(find.text('CONFIRM PURGE'), findsOneWidget);
      await tester.tap(find.text('CONFIRM PURGE'));
      await tester.pumpAndSettle();

      expect(p.highScore, 0);
      expect(find.text('All local guest data erased.'), findsOneWidget);
    });
  });

  group('ProfileModal Telemetry & Navigation Tests', () {
    testWidgets(
      'ProfileModal renders expanded telemetry and navigation button',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(480, 1000));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(
          const MaterialApp(home: Scaffold(body: ProfileModal())),
        );
        await tester.pumpAndSettle();

        await tester.scrollUntilVisible(
          find.text('LIFETIME COMBAT TELEMETRY'),
          150.0,
          scrollable: find.byType(Scrollable).first,
        );
        expect(find.text('LIFETIME COMBAT TELEMETRY'), findsOneWidget);

        await tester.scrollUntilVisible(
          find.text('Sorties / Win Rate'),
          150.0,
          scrollable: find.byType(Scrollable).first,
        );
        expect(find.text('Sorties / Win Rate'), findsOneWidget);

        await tester.scrollUntilVisible(
          find.text('VIEW FULL FLEET TELEMETRY'),
          150.0,
          scrollable: find.byType(Scrollable).first,
        );
        expect(find.text('VIEW FULL FLEET TELEMETRY'), findsOneWidget);
      },
    );
  });
}
