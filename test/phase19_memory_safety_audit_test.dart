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
import 'package:void_sower/domain/models/enemy_craft.dart';
import 'package:void_sower/domain/services/analytics_service.dart';
import 'package:void_sower/domain/services/persistence_service.dart';
import 'package:void_sower/domain/services/privacy_service.dart';
import 'package:void_sower/engine/mock_void_sower_engine.dart';
import 'package:void_sower/presentation/controllers/invader_bullet_manager.dart';
import 'package:void_sower/presentation/screens/simulation_lab_screen.dart';
import 'package:void_sower/presentation/screens/stats_dashboard_screen.dart';
import 'package:void_sower/presentation/services/particle_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Phase 19: Memory Safety & Lifecycle Hardening Tests', () {
    late MockVoidSowerEngine mockEngine;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await PersistenceService.instance.initialize();
      mockEngine = MockVoidSowerEngine();
    });

    tearDown(() {
      mockEngine.dispose();
    });

    testWidgets(
      'StatsDashboardScreen _importSave safely creates and disposes controller upon dismiss',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(480, 1000));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(
          const MaterialApp(home: Scaffold(body: StatsDashboardScreen())),
        );
        await tester.pumpAndSettle();

        // Scroll to IMPORT SAVE button
        await tester.scrollUntilVisible(
          find.text('IMPORT SAVE'),
          200.0,
          scrollable: find.byType(Scrollable).first,
        );
        expect(find.text('IMPORT SAVE'), findsOneWidget);

        await tester.tap(find.text('IMPORT SAVE'));
        await tester.pumpAndSettle();

        // Verify the dialog is presented with input field
        expect(find.text('RESTORE TELEMETRY SAVE'), findsOneWidget);
        expect(find.byType(TextField), findsOneWidget);

        // Cancel dialog - safely closes and disposes controller via finally block
        final cancelButtonFinder = find.widgetWithText(TextButton, 'CANCEL');
        expect(cancelButtonFinder, findsOneWidget);
        await tester.tap(cancelButtonFinder);
        await tester.pumpAndSettle();

        // Dialog should be dismissed
        expect(find.text('RESTORE TELEMETRY SAVE'), findsNothing);
      },
    );

    testWidgets(
      'SimulationLabScreen cancels benchmark timer upon disposal without post-unmount throws',
      (tester) async {
        await PersistenceService.instance.setProUnlocked(true);
        await tester.pumpWidget(
          MaterialApp(home: SimulationLabScreen(engine: mockEngine)),
        );
        await tester.pumpAndSettle();

        // Switch to MCTS ARENA tab
        final benchmarkTabFinder = find.text('MCTS ARENA');
        expect(benchmarkTabFinder, findsOneWidget);
        await tester.tap(benchmarkTabFinder);
        await tester.pumpAndSettle();

        // Trigger benchmark
        final runButtonFinder = find.text(
          'EXECUTE 100-ITERATION MCTS BENCHMARK',
        );
        expect(runButtonFinder, findsOneWidget);
        await tester.tap(runButtonFinder);
        await tester.pump(); // Start the 50ms timer

        // Immediately unmount by pushing replacement widget before timer fires
        await tester.pumpWidget(
          const MaterialApp(home: Scaffold(body: Text('REPLACED'))),
        );
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pumpAndSettle();

        // Successfully unmounted without throwing unmounted setState exception
        expect(find.text('REPLACED'), findsOneWidget);
      },
    );

    test(
      'PrivacyService correctly evaluates ConsentStatus transitions and ad request gating',
      () async {
        final privacy = PrivacyService.instance;
        expect(privacy.status, ConsentStatus.notRequired);
        expect(privacy.canRequestAds, isTrue);

        await privacy.requestConsent();
        expect(privacy.status, ConsentStatus.obtained);
        expect(privacy.canRequestAds, isTrue);
      },
    );

    test('AnalyticsService safely logs events without throwing', () {
      final analytics = AnalyticsService.instance;
      analytics.logEvent('test_event', {'key': 'value'});
      analytics.logCombatStart(1, 0);
      analytics.logCombatVictory(1, 15000, 12);
      analytics.logCombatDefeat(1, 4500);
    });

    test(
      'ParticleService zero-allocation pool update and clearing lifecycle',
      () {
        final particles = ParticleService(maxParticles: 32);
        expect(particles.hasActiveParticles, isFalse);

        particles.spawnFlakBurst(0.5, 0.5, Colors.cyan, count: 10);
        // Active list is populated upon update step
        particles.update(0.016);
        expect(particles.hasActiveParticles, isTrue);
        expect(particles.activeParticles.length, lessThanOrEqualTo(32));

        particles.clear();
        expect(particles.hasActiveParticles, isFalse);
        expect(particles.activeParticles, isEmpty);
      },
    );

    test(
      'InvaderBulletManager updates and clears active projectiles safely',
      () {
        bool conduitHit = false;
        bool atmosphereHit = false;
        bool bulletDeflected = false;

        final bulletManager = InvaderBulletManager(
          particleService: ParticleService(maxParticles: 16),
          damageNumbers: [],
          onConduitBreached: (corridor, x, y) {
            conduitHit = true;
          },
          onAtmosphereBreached: (x, y) {
            atmosphereHit = true;
          },
          onBulletDeflected: (x, y, color) {
            bulletDeflected = true;
          },
        );

        final enemies = [
          const EnemyCraft(
            entityId: 1,
            assignedCorridor: 3,
            worldPosX: 0.4375,
            worldPosY: 0.75,
            velocityY: 0.02,
            currentShields: 50,
            maxShields: 50,
            currentHull: 100,
            maxHull: 100,
            vesselType: 0,
            isDestroyed: false,
          ),
        ];

        // Step dt to trigger enemy bullet spawn
        bulletManager.update(
          dt: 1.2,
          viewportSize: const Size(400, 800),
          boundaryY: 700.0,
          dreadX: 0.4375,
          enemies: enemies,
          lances: const [],
          flaks: const [],
        );
        expect(bulletManager.bullets, isNotEmpty);

        // Clear resets bullets and cooldowns
        bulletManager.clear();
        expect(bulletManager.bullets, isEmpty);
        expect(conduitHit, isFalse);
        expect(atmosphereHit, isFalse);
        expect(bulletDeflected, isFalse);
      },
    );
  });
}
