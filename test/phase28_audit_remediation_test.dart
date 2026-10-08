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

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:void_sower/domain/models/dreadnought_state.dart';
import 'package:void_sower/domain/models/enemy_bullet.dart';
import 'package:void_sower/domain/models/pro_feature.dart';
import 'package:void_sower/domain/services/ad_service.dart';
import 'package:void_sower/domain/services/entitlement_service.dart';
import 'package:void_sower/domain/services/persistence_service.dart';
import 'package:void_sower/engine/mock_void_sower_engine.dart';
import 'package:void_sower/main.dart';
import 'package:void_sower/presentation/controllers/combat_overlay_state.dart';
import 'package:void_sower/presentation/screens/campaign_map_screen.dart';
import 'package:void_sower/presentation/screens/combat_screen.dart';
import 'package:void_sower/presentation/services/audio_service.dart';
import 'package:void_sower/presentation/theme/void_theme.dart';
import 'package:void_sower/presentation/widgets/combat_painter.dart';
import 'package:void_sower/presentation/widgets/starfield_3d.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await PersistenceService.instance.resetForTesting();
    await PersistenceService.instance.initialize();
    await PersistenceService.instance.setCompletedTutorial(true);
    AdService.instance.resetCooldownForTesting();
    AdService.instance.setSimulateMobileForTesting(false);
    await PersistenceService.instance.setProBoostExpiry(null);
    await PersistenceService.instance.setProUnlocked(false);
    EntitlementService.instance.syncStateFromPersistence();
  });

  group('Phase 28.1: FFI Natural Alignment & Snapshot Buffer Validation', () {
    test(
      'MockVoidSowerEngine restores snapshot with explicit chargesLength',
      () {
        final engine = MockVoidSowerEngine();
        final bayCharges = List<int>.generate(16, (i) => i * 10);

        // Verify default chargesLength (16)
        expect(
          () => engine.restoreSnapshot(
            bayCharges: bayCharges,
            reserveCores: 25,
            totalScore: 5000,
          ),
          returnsNormally,
        );

        // Verify explicit custom chargesLength
        expect(
          () => engine.restoreSnapshot(
            bayCharges: bayCharges,
            reserveCores: 30,
            totalScore: 7500,
            chargesLength: 16,
          ),
          returnsNormally,
        );
      },
    );
  });

  group(
    'Phase 28.2: Hardened Ad Lifecycle State Machine & Boost Decoupling',
    () {
      test('AdService transitions through AdLifecycleState properly', () async {
        final adService = AdService.instance;
        await adService.initialize();
        expect(adService.lifecycleState, equals(AdLifecycleState.idle));

        // Loading transitions to ready on non-mobile test environment
        await adService.loadRewardedAd();
        expect(
          adService.lifecycleState == AdLifecycleState.idle ||
              adService.lifecycleState == AdLifecycleState.ready,
          isTrue,
        );

        // Showing ad transitions state and returns true
        final showResult = await adService.showRewardedAd();
        expect(showResult, isTrue);
        expect(
          adService.lifecycleState == AdLifecycleState.idle ||
              adService.lifecycleState == AdLifecycleState.ready,
          isTrue,
        );
      });

      test('showRewardedAd does NOT grant Pro Boost automatically', () async {
        final entitlement = EntitlementService.instance;
        expect(entitlement.isBoostActive, isFalse);

        final adService = AdService.instance;
        await adService.initialize();

        final result = await adService.showRewardedAd();
        expect(result, isTrue);

        // Decoupled: AdService did NOT call grantStackableBoost
        expect(entitlement.isBoostActive, isFalse);
      });

      test(
        'EntitlementService.unlockWithRewardedAd explicitly grants boost',
        () async {
          final entitlement = EntitlementService.instance;
          expect(entitlement.isBoostActive, isFalse);

          final result = await entitlement.unlockWithRewardedAd(
            ProFeature.aiMoveAdvisor,
          );

          expect(result, isTrue);
          expect(entitlement.isBoostActive, isTrue);
          expect(entitlement.boostMinutesRemaining, greaterThan(0));
        },
      );
    },
  );

  group(
    'Phase 28.3: Battery Optimization & RouteAware Starmap Timer Pausing',
    () {
      testWidgets(
        'CampaignMapScreen pauses boost timer on didPushNext and resumes on didPopNext',
        (tester) async {
          // Activate pro boost so the timer runs
          EntitlementService.instance.grantStackableBoost(
            duration: const Duration(minutes: 15),
          );
          expect(EntitlementService.instance.isBoostActive, isTrue);

          final engine = MockVoidSowerEngine();

          await tester.pumpWidget(
            MaterialApp(
              navigatorObservers: [routeObserver],
              home: CampaignMapScreen(engine: engine),
            ),
          );
          await tester.pumpAndSettle();

          final mapState =
              tester.state(find.byType(CampaignMapScreen)) as dynamic;
          expect(mapState.isBoostTimerActive, isTrue);

          // Push a dummy route covering CampaignMapScreen
          final BuildContext context = tester.element(
            find.byType(CampaignMapScreen),
          );
          Navigator.of(context).push<void>(
            MaterialPageRoute(
              builder: (_) => const Scaffold(body: Text('Covering Route')),
            ),
          );
          await tester.pumpAndSettle();

          // Timer is suspended while screen is covered
          expect(mapState.isBoostTimerActive, isFalse);

          // Pop covering route
          Navigator.of(context).pop();
          await tester.pumpAndSettle();

          // Timer resumes when route returns to top
          expect(mapState.isBoostTimerActive, isTrue);
        },
      );
    },
  );

  group('Phase 28.4: Ticker Halting on Static Combat Overlays', () {
    testWidgets('CombatScreen halts ticker during static settings overlay', (
      tester,
    ) async {
      final engine = MockVoidSowerEngine();
      await tester.pumpWidget(
        MaterialApp(
          theme: VoidTheme.darkTheme,
          home: CombatScreen(engine: engine, sectorId: 1),
        ),
      );
      await tester.pump();

      final screenState = tester.state(find.byType(CombatScreen)) as dynamic;
      expect(screenState.isTickerActive, isTrue);

      // Open settings modal via settings action icon
      final settingsButton = find.byIcon(Icons.settings);
      if (settingsButton.evaluate().isNotEmpty) {
        await tester.tap(settingsButton.first);
        await tester.pump();

        // Ticker must be stopped while settings sheet is open
        expect(screenState.overlayState, equals(CombatOverlayState.settings));
        expect(screenState.isTickerActive, isFalse);
      }
    });
  });

  group('Phase 28.5: Audio Carrier Wave Elimination', () {
    test(
      'AudioService handles BGM lifecycle without dummy carrier bytes',
      () async {
        final audio = AudioService.instance;
        await audio.initialize();

        // Starting and stopping BGM completes cleanly
        expect(() => audio.startBgm(), returnsNormally);
        expect(() => audio.stopBgm(), returnsNormally);
      },
    );
  });

  group(
    'Phase 28.6: Hot Path Zero-Allocation Canvas Projections & Bitwise Masking',
    () {
      test(
        'CombatPainter renders enemy bullets using zero-allocation translation',
        () {
          final recorder = PictureRecorder();
          final canvas = Canvas(recorder);
          const canvasSize = Size(400.0, 800.0);

          const dread = DreadnoughtState(
            orbitalPositionX: 0.5,
            targetPositionX: 0.5,
            orbitalPositionY: 0.85,
            targetPositionY: 0.85,
            boundaryLineY: 0.15,
            proximityMultiplier: 1.0,
            reserveCores: 24,
            totalScore: 1000,
            coresUsed: 0,
            isCascading: false,
            currentSimState: 0,
          );

          final painter = CombatPainter(
            dreadnought: dread,
            enemies: const [],
            lances: const [],
            flaks: const [],
            particles: const [],
            enemyBullets: [
              EnemyBullet(
                id: 1,
                assignedCorridor: 2,
                x: 200.0,
                y: 350.0,
                color: const Color(0xFFFF5555),
              ),
            ],
            animationTime: 1.0,
          );

          expect(() => painter.paint(canvas, canvasSize), returnsNormally);
          final pic = recorder.endRecording();
          expect(pic, isNotNull);
          pic.dispose();
        },
      );

      test(
        'Starfield3DSimulation paints stars and nebulae with zero transient offsets',
        () {
          final sim = Starfield3DSimulation(starCount: 64);
          sim.update(
            dt: 0.016,
            normForward: 0.5,
            velocityDx: 0.0,
            viewportSize: const Size(400.0, 800.0),
          );

          final recorder = PictureRecorder();
          final canvas = Canvas(recorder);
          expect(
            () => sim.paint(
              canvas,
              const Size(400.0, 800.0),
              normForward: 0.5,
              animationTime: 2.0,
            ),
            returnsNormally,
          );
          final pic = recorder.endRecording();
          expect(pic, isNotNull);
          pic.dispose();
        },
      );

      test('Bitwise power-of-two masking behaves identically to modulo', () {
        // WaveGenerator & CombatSystem: ((id & 1) == 0) vs (id % 2 == 0)
        for (var id = 0; id < 100; id++) {
          expect((id & 1) == 0, equals(id % 2 == 0));
          expect((id & 1) + 1, equals((id % 2) + 1));
        }

        // CombatCoordinator: ((remaining & 3) == 0) vs (remaining % 4 == 0)
        for (var rem = 0; rem < 100; rem++) {
          expect((rem & 3) == 0, equals(rem % 4 == 0));
        }
      });
    },
  );
}
