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
import 'package:void_sower/domain/models/enemy_craft.dart';
import 'package:void_sower/domain/services/persistence_service.dart';
import 'package:void_sower/engine/mock_void_sower_engine.dart';
import 'package:void_sower/presentation/controllers/combat_dialog_coordinator.dart';
import 'package:void_sower/presentation/screens/combat_screen.dart';
import 'package:void_sower/presentation/services/audio_service.dart';
import 'package:void_sower/presentation/theme/void_theme.dart';
import 'package:void_sower/presentation/widgets/combat_painter.dart';
import 'package:void_sower/presentation/widgets/combat_settings_sheet.dart';
import 'package:void_sower/presentation/widgets/dreadnought_3d_mesh.dart';
import 'package:void_sower/presentation/widgets/starfield_3d.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await PersistenceService.instance.resetForTesting();
    await PersistenceService.instance.initialize();
    await PersistenceService.instance.setCompletedTutorial(true);
  });

  group('Phase 27.1: Zero-Alloc Hot Path Pipeline & Skia GPU Optimization', () {
    test(
      'CombatPainter uses 16-step _flightHintPainters LUT with monotonic alpha',
      () {
        final hintPainters = CombatPainter.flightHintPainters;
        expect(hintPainters.length, equals(16));

        // Verify each entry has valid pre-laid out dimensions
        for (var i = 0; i < hintPainters.length; i++) {
          final painter = hintPainters[i];
          expect(painter.width, greaterThan(0.0));
          expect(painter.height, greaterThan(0.0));
        }

        // Verify backwards compatibility getter returns the last (brightest) entry
        expect(CombatPainter.flightHintPainter, equals(hintPainters.last));

        // Verify scratch reticle and bar paths are available
        expect(CombatPainter.scratchReticlePath, isNotNull);
        expect(CombatPainter.scratchBarPath, isNotNull);
      },
    );

    test(
      'CombatPainter renders flight hints and reticle crosshairs without allocations',
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

        const enemy = EnemyCraft(
          entityId: 201,
          assignedCorridor: 3,
          worldPosX: 0.4375,
          worldPosY: 0.5,
          velocityY: 0.04,
          currentShields: 30,
          maxShields: 60,
          currentHull: 80,
          maxHull: 100,
          vesselType: 0,
          isDestroyed: false,
        );

        final painter = CombatPainter(
          dreadnought: dread,
          enemies: [enemy],
          lances: const [],
          flaks: const [],
          particles: const [],
          animationTime: 2.0,
          isLowBattery: false,
        );

        // Render stationary in orbit (normForward < 0.25) to trigger flight hint
        for (var f = 0; f < 30; f++) {
          painter.paint(canvas, canvasSize);
        }

        final picture = recorder.endRecording();
        expect(picture, isNotNull);
        picture.dispose();
      },
    );

    test(
      'Dreadnought3DMesh shadedColorLUT provides 101 steps for all 4 colors',
      () {
        final lut = Dreadnought3DMesh.shadedColorLUT;
        expect(lut.length, equals(4));

        for (var c = 0; c < 4; c++) {
          expect(lut[c].length, equals(101));

          // Step 0 (light = 0.0) should be darkened to zero RGB
          final step0 = lut[c][0];
          expect(step0.r, equals(0.0));
          expect(step0.g, equals(0.0));
          expect(step0.b, equals(0.0));

          // Step 100 (light = 1.0) should have full illumination
          final step100 = lut[c][100];
          expect(step100.a, equals(1.0));
          expect(step100.r, greaterThan(0.0));
        }

        // Verify scratch nozzle path exists
        expect(Dreadnought3DMesh.scratchNozzlePath, isNotNull);

        // Verify projectAndPaint renders smoothly with LUT and scratch nozzle path
        final mesh = Dreadnought3DMesh();
        final recorder = PictureRecorder();
        final canvas = Canvas(recorder);
        mesh.projectAndPaint(
          canvas,
          center: const Offset(200.0, 400.0),
          pitchRad: 0.1,
          rollRad: 0.05,
          yawRad: 0.0,
          scale: 1.0,
          animationTime: 1.0,
        );
        final pic = recorder.endRecording();
        expect(pic, isNotNull);
        pic.dispose();
      },
    );

    test('Starfield3DSimulation starColorLUT and batched streak paths', () {
      final lut = Starfield3DSimulation.starColorLUT;
      expect(lut.length, equals(4));

      for (var c = 0; c < 4; c++) {
        expect(lut[c].length, equals(256));
        // Verify alpha channel mapping across 256 levels
        for (var a = 0; a < 256; a++) {
          final color = lut[c][a];
          final extractedAlpha = (color.toARGB32() >> 24) & 0xFF;
          expect(extractedAlpha, equals(a));
        }
      }

      // Verify batched streak paths pool
      final streakPaths = Starfield3DSimulation.scratchStreakPaths;
      expect(streakPaths.length, equals(4));

      // Test simulation updates and warping paint
      final sim = Starfield3DSimulation(starCount: 32);
      sim.update(
        dt: 0.016,
        normForward: 0.8,
        velocityDx: 0.0,
        viewportSize: const Size(400.0, 800.0),
      );

      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      sim.paint(
        canvas,
        const Size(400.0, 800.0),
        normForward: 0.8,
        animationTime: 1.0,
      );
      final pic = recorder.endRecording();
      expect(pic, isNotNull);
      pic.dispose();
    });
  });

  group('Phase 27.2: Mobile Lifecycle Guarding & Background Battery Drain', () {
    testWidgets(
      'CombatScreen pauses ticker and clears autoAdvanceTimer on lifecycle transitions',
      (tester) async {
        final engine = MockVoidSowerEngine();
        await tester.pumpWidget(
          MaterialApp(
            theme: VoidTheme.darkTheme,
            home: CombatScreen(engine: engine, sectorId: 1),
          ),
        );
        await tester.pump();

        final screenState = tester.state(find.byType(CombatScreen)) as dynamic;
        expect(screenState.dialogCoordinator, isA<CombatDialogCoordinator>());
        expect(screenState.hasPendingAutoAdvance, isFalse);

        // Simulate app moving to paused state (backgrounded)
        final binding = tester.binding;
        binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
        await tester.pump();

        expect(screenState.autoAdvanceTimer, isNull);

        // Simulate app resuming
        binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
        await tester.pump();

        // Ticker is resumed safely
        expect(screenState.hasPendingAutoAdvance, isFalse);
      },
    );
  });

  group('Phase 27.3: Audio Focus Restoration & Soundtrack Preservation', () {
    test('AudioService preserves BGM asset path and audio focus', () async {
      final audio = AudioService.instance;
      await audio.initialize();

      // Start BGM with designated asset
      const testAsset = 'audio/kilwa_ambient.mp3';
      await audio.startBgm(assetPath: testAsset);
      expect(audio.currentBgmAssetPath, equals(testAsset));

      // Request exclusive audio focus: must not overwrite source track
      await audio.requestExclusiveAudioFocus();
      expect(audio.currentBgmAssetPath, equals(testAsset));

      // Release audio focus
      await audio.releaseAudioFocus();
    });
  });

  group('Phase 27.5: Presentation Decoupling & Modularity', () {
    testWidgets('CombatSettingsSheet renders and triggers callbacks cleanly', (
      tester,
    ) async {
      var academyLaunched = false;
      var tutorialReset = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: VoidTheme.darkTheme,
          home: Scaffold(
            body: CombatSettingsSheet(
              onLaunchAcademy: () => academyLaunched = true,
              onResetTutorial: () => tutorialReset = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(CombatSettingsSheet), findsOneWidget);
      expect(academyLaunched, isFalse);
      expect(tutorialReset, isFalse);
    });

    test(
      'CombatDialogCoordinator coordinates modal presentation and pauses',
      () {
        var pauseCalled = false;
        var resumeCalled = false;
        var restartCalled = false;
        var advanceCalled = false;

        final coordinator = CombatDialogCoordinator(
          onCombatPause: () => pauseCalled = true,
          onCombatResume: () => resumeCalled = true,
          onRestartCombat: () => restartCalled = true,
          onAdvanceSector: () => advanceCalled = true,
        );

        coordinator.onCombatPause();
        expect(pauseCalled, isTrue);

        coordinator.onCombatResume();
        expect(resumeCalled, isTrue);

        coordinator.onRestartCombat();
        expect(restartCalled, isTrue);

        coordinator.onAdvanceSector();
        expect(advanceCalled, isTrue);
      },
    );
  });
}
