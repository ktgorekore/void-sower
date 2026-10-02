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

import 'dart:ffi' as ffi;
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:void_sower/domain/models/dreadnought_state.dart';
import 'package:void_sower/domain/models/enemy_bullet.dart';
import 'package:void_sower/domain/models/enemy_craft.dart';
import 'package:void_sower/domain/services/persistence_service.dart';
import 'package:void_sower/engine/ffi_void_sower_engine.dart';
import 'package:void_sower/engine/mock_void_sower_engine.dart';
import 'package:void_sower/presentation/screens/combat_screen.dart';
import 'package:void_sower/presentation/services/audio_service.dart';
import 'package:void_sower/presentation/theme/void_theme.dart';
import 'package:void_sower/presentation/widgets/combat_painter.dart';
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

  group(
    'Phase 23.1: Zero-Allocation Skia Hot-Paths & TextPainter Pre-Layout',
    () {
      test('Static TextPainters are pre-laid out with valid dimensions', () {
        // Flight hint painter must have positive layout dimensions
        final flightHint = CombatPainter.flightHintPainter;
        expect(flightHint.width, greaterThan(0.0));
        expect(flightHint.height, greaterThan(0.0));

        // Atmospheric threshold painter in CombatBackgroundPainter
        final threshold = CombatBackgroundPainter.thresholdPainter;
        expect(threshold.width, greaterThan(0.0));
        expect(threshold.height, greaterThan(0.0));

        // Proximity tag painters lookup table: 7 pre-allocated entries (0..6)
        final vanguardTags = CombatPainter.vanguardTagPainters;
        expect(vanguardTags.length, equals(7));
        for (var i = 0; i < vanguardTags.length; i++) {
          expect(
            vanguardTags[i].width,
            greaterThan(0.0),
            reason: 'Vanguard tag tier $i must be pre-laid out',
          );
          expect(vanguardTags[i].height, greaterThan(0.0));
        }

        // Damage multiplier tag painters cache
        final dmgTags = CombatPainter.damageTagPainters;
        expect(dmgTags.containsKey(16), isTrue);
        expect(dmgTags.containsKey(32), isTrue);
        expect(dmgTags.containsKey(64), isTrue);
        for (final entry in dmgTags.entries) {
          expect(entry.value.width, greaterThan(0.0));
          expect(entry.value.height, greaterThan(0.0));
        }
      });

      test(
        'CombatBackgroundPainter shouldRepaint tracks isLowBattery changes',
        () {
          const normalPainter = CombatBackgroundPainter(isLowBattery: false);
          const normalPainterCopy = CombatBackgroundPainter(
            isLowBattery: false,
          );
          const lowBatPainter = CombatBackgroundPainter(isLowBattery: true);

          expect(normalPainter.shouldRepaint(normalPainterCopy), isFalse);
          expect(normalPainter.shouldRepaint(lowBatPainter), isTrue);
          expect(lowBatPainter.shouldRepaint(normalPainter), isTrue);
        },
      );

      test(
        'CombatPainter renders dynamic entities with bitwise ARGB & LTWH primitives',
        () {
          final recorder = PictureRecorder();
          final canvas = Canvas(recorder);
          const canvasSize = Size(400.0, 800.0);

          const dread = DreadnoughtState(
            orbitalPositionX: 0.5,
            targetPositionX: 0.5,
            orbitalPositionY: 0.4,
            targetPositionY: 0.4,
            boundaryLineY: 0.15,
            proximityMultiplier: 1.3,
            reserveCores: 24,
            totalScore: 500,
            coresUsed: 0,
            isCascading: false,
            currentSimState: 0,
          );

          final bullet = EnemyBullet(
            id: 1,
            assignedCorridor: 3,
            x: 200.0,
            y: 350.0,
            color: VoidTheme.crimsonFlare,
          );

          const enemy = EnemyCraft(
            entityId: 101,
            assignedCorridor: 3,
            worldPosX: 0.5,
            worldPosY: 0.5,
            velocityY: 0.05,
            currentShields: 20,
            maxShields: 50,
            currentHull: 80,
            maxHull: 100,
            vesselType: 1,
            isDestroyed: false,
          );

          final painter = CombatPainter(
            dreadnought: dread,
            enemies: [enemy],
            lances: const [],
            flaks: const [],
            particles: const [],
            enemyBullets: [bullet],
            damageNumbers: const [],
            animationTime: 1.5,
            isLowBattery: false,
          );

          // Verify painting runs smoothly across 60 frames without exceptions
          for (var f = 0; f < 60; f++) {
            painter.paint(canvas, canvasSize);
          }

          final picture = recorder.endRecording();
          expect(picture, isNotNull);
          picture.dispose();
        },
      );
    },
  );

  group('Phase 23.2: 3D Spatial Geometry & Starfield Zero-Allocation Hardening', () {
    test(
      'Dreadnought3DMesh clamps near-plane geometry divide under extreme pitch',
      () {
        final mesh = Dreadnought3DMesh();
        final recorder = PictureRecorder();
        final canvas = Canvas(recorder);
        const center = Offset(200.0, 400.0);

        // Extreme pitch angles that would cause cameraZ + rz <= 0 without clamping
        final extremeAngles = [
          -math.pi / 2,
          math.pi / 2,
          -math.pi * 0.75,
          math.pi,
        ];

        for (final pitch in extremeAngles) {
          mesh.projectAndPaint(
            canvas,
            center: center,
            pitchRad: pitch,
            rollRad: 0.5,
            yawRad: 0.2,
            scale: 1.5,
            animationTime: 0.0,
          );

          for (var i = 0; i < Dreadnought3DMesh.vertexCount; i++) {
            expect(
              mesh.projX[i].isFinite,
              isTrue,
              reason: 'projX[$i] must be finite at pitch $pitch',
            );
            expect(
              mesh.projY[i].isFinite,
              isTrue,
              reason: 'projY[$i] must be finite at pitch $pitch',
            );
            expect(
              mesh.camZ[i].isFinite,
              isTrue,
              reason: 'camZ[$i] must be finite at pitch $pitch',
            );
          }
        }

        final picture = recorder.endRecording();
        picture.dispose();
      },
    );

    test('Dreadnought3DMesh handles low battery rendering without error', () {
      final mesh = Dreadnought3DMesh();
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      const center = Offset(200.0, 400.0);

      // Verify painting with isLowBattery = true
      mesh.projectAndPaint(
        canvas,
        center: center,
        pitchRad: 0.0,
        rollRad: 0.0,
        yawRad: 0.0,
        scale: 1.0,
        animationTime: 1.0,
        isLowBattery: true,
      );

      final picture = recorder.endRecording();
      picture.dispose();
    });

    test(
      'Starfield3DSimulation isolates amethyst streak paint from cyan paint',
      () {
        final amethystPaint = Starfield3DSimulation.streakAmethystPaint;
        final cyanPaint = Starfield3DSimulation.streakCyanPaint;

        // Must be two distinct Paint instances in memory
        expect(identical(amethystPaint, cyanPaint), isFalse);

        // Mutating amethyst paint properties must not affect cyan paint
        final originalCyanColor = cyanPaint.color;
        amethystPaint.color = const Color(0xFF9933FF);
        expect(cyanPaint.color, equals(originalCyanColor));
      },
    );

    test(
      'Starfield3DSimulation smoothly handles low battery toggling without NaN',
      () {
        final sim = Starfield3DSimulation();
        const viewport = Size(400.0, 800.0);

        // 1. Run in low-battery mode
        for (var f = 0; f < 10; f++) {
          sim.update(
            dt: 0.016,
            normForward: 0.5,
            velocityDx: 0.1,
            viewportSize: viewport,
            isLowBattery: true,
          );
        }

        // 2. Switch back to full mode: smooth re-spreading for stars 32..63
        for (var f = 0; f < 10; f++) {
          sim.update(
            dt: 0.016,
            normForward: 0.5,
            velocityDx: 0.1,
            viewportSize: viewport,
            isLowBattery: false,
          );
        }

        // Verify all stars remain valid and bounded
        for (var i = 0; i < sim.starCount; i++) {
          expect(sim.posX[i].isFinite, isTrue);
          expect(sim.posY[i].isFinite, isTrue);
          expect(sim.posZ[i].isFinite, isTrue);
          expect(sim.posZ[i], greaterThan(0.0));
          expect(sim.posZ[i], lessThanOrEqualTo(1.0));
        }
      },
    );
  });

  group(
    'Phase 23.3: CombatScreen Sortie Directive Decoupling & Lifecycle Focus',
    () {
      testWidgets(
        'Sortie Directive rebuild count remains decoupled from 60 Hz ticker',
        (tester) async {
          final mockEngine = MockVoidSowerEngine();

          await tester.pumpWidget(
            MaterialApp(home: CombatScreen(engine: mockEngine)),
          );
          await tester.pump(const Duration(milliseconds: 50));

          final dynamic combatState = tester.state(find.byType(CombatScreen));
          final initialDirectiveRebuilds = combatState.directiveNotifier.value;

          // Pump 30 frames of combat rendering
          for (var i = 0; i < 30; i++) {
            await tester.pump(const Duration(milliseconds: 16));
          }

          // Since quest state has not changed, directiveNotifier must not fire repeatedly
          expect(
            combatState.directiveNotifier.value,
            equals(initialDirectiveRebuilds),
            reason:
                'Sortie Directive banner must decouple from per-frame ticker renders',
          );
        },
      );

      testWidgets('App lifecycle pause releases audio focus and pauses BGM', (
        tester,
      ) async {
        final mockEngine = MockVoidSowerEngine();
        final audio = AudioService.instance;
        await audio.initialize();

        await tester.pumpWidget(
          MaterialApp(home: CombatScreen(engine: mockEngine)),
        );
        await tester.pump(const Duration(milliseconds: 50));

        // Simulate app transitioning to background (paused / hidden)
        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
        await tester.pump(const Duration(milliseconds: 50));

        expect(audio.isBgmPaused, isTrue);
        expect(audio.isAudioFocusReleased, isTrue);

        // Simulate app resuming to foreground
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
        await tester.pump(const Duration(milliseconds: 50));

        expect(audio.isBgmPaused, isFalse);
        expect(audio.isAudioFocusReleased, isFalse);
      });
    },
  );

  group('Phase 23.4: Power-of-Two Audio Ring Buffer & Bitwise Wraparound', () {
    test(
      'AudioService advances pool index via single-cycle bitwise mask & 7',
      () {
        final audio = AudioService.instance;
        audio.setPoolIndexForTesting(0);
        expect(audio.poolIndex, equals(0));

        // Verify sequence across 24 calls (3 full cycles of 8 slots)
        final expectedSequence = List.generate(24, (i) => i % 8);
        final actualSequence = <int>[];

        for (var i = 0; i < 24; i++) {
          actualSequence.add(audio.poolIndex);
          audio.getNextPlayerForTesting();
        }

        expect(actualSequence, equals(expectedSequence));

        // Explicit wrap test: slot 7 -> slot 0
        audio.setPoolIndexForTesting(7);
        expect(audio.poolIndex, equals(7));
        audio.getNextPlayerForTesting();
        expect(audio.poolIndex, equals(0));
      },
    );

    test(
      'AudioService pauseBgm and resumeBgm update isBgmPaused state',
      () async {
        final audio = AudioService.instance;
        await audio.initialize();

        await audio.pauseBgm();
        expect(audio.isBgmPaused, isTrue);

        await audio.resumeBgm();
        expect(audio.isBgmPaused, isFalse);
      },
    );
  });

  group('Phase 23.5: C++ ECS & Dart FFI State Hygiene & Default Parameters', () {
    test(
      'FfiVoidSowerEngine restoreSnapshot zero-fills trailing buffer slots',
      () {
        final engine = FfiVoidSowerEngine();

        // Pre-dirty all 16 slots with non-zero garbage
        final chargesPtr = engine.cachedSnapshotChargesPtr;
        for (var i = 0; i < FfiVoidSowerEngine.kMaxBays; i++) {
          chargesPtr[i] = 0xDEADBEEF;
        }

        // Restore snapshot with 4 active bay charges
        engine.restoreSnapshot(
          bayCharges: [12, 24, 36, 48],
          reserveCores: 16,
          totalScore: 1000,
        );

        // Verify leading 4 slots match
        expect(chargesPtr[0], equals(12));
        expect(chargesPtr[1], equals(24));
        expect(chargesPtr[2], equals(36));
        expect(chargesPtr[3], equals(48));

        // Verify trailing 12 slots (4..15) are zero-filled
        for (var i = 4; i < FfiVoidSowerEngine.kMaxBays; i++) {
          expect(
            chargesPtr[i],
            equals(0),
            reason:
                'Slot $i must be zero-filled to prevent stale state corruption',
          );
        }

        engine.dispose();
      },
    );

    test('IVoidSowerEngine default parameter boundaryY is 0.15', () {
      final engine = MockVoidSowerEngine();
      // Calling initialize() with default parameters should succeed and apply boundaryY = 0.15
      engine.initialize();
      final dread = engine.getDreadnoughtState();
      expect(dread.boundaryLineY, equals(0.15));
      engine.dispose();
    });
  });
}
