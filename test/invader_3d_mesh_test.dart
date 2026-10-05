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

import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_sower/presentation/widgets/invader_3d_mesh.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Invader3DMesh 3D Spatial Geometry Tests', () {
    test('Initializes vertex buffers with maxVertices capacity', () {
      final mesh = Invader3DMesh();
      expect(Invader3DMesh.maxVertices, equals(24));
      expect(mesh.projX.length, equals(24));
      expect(mesh.projY.length, equals(24));
    });

    test('Projects Drone (type 0) centered with nose facing player', () {
      final mesh = Invader3DMesh();
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);

      const center = Offset(180.0, 300.0);
      mesh.projectAndPaint(
        canvas,
        center: center,
        vesselType: 0,
        pitchRad: 0.0,
        rollRad: 0.0,
        yawRad: 0.0,
        scale: 1.0,
        warpInProgress: 1.0,
        animationTime: 0.0,
      );

      // Verify drone nose points forward (greater Y relative to center in screen coordinates)
      expect(mesh.projX[Invader3DMesh.droneNose], closeTo(center.dx, 0.5));
      expect(mesh.projY[Invader3DMesh.droneNose], greaterThan(center.dy));

      // Verify port and starboard wingtip symmetry
      final portDx = (mesh.projX[Invader3DMesh.dronePortWingtip] - center.dx)
          .abs();
      final stbdDx = (mesh.projX[Invader3DMesh.droneStbdWingtip] - center.dx)
          .abs();
      expect(portDx, closeTo(stbdDx, 0.5));

      // Verify all coordinates are finite
      for (var i = 0; i < 10; i++) {
        expect(mesh.projX[i].isFinite, isTrue);
        expect(mesh.projY[i].isFinite, isTrue);
      }
    });

    test(
      'Projects Cruiser (type 1) and Flagship (type 2) with valid finite coordinates',
      () {
        final mesh = Invader3DMesh();
        final recorder = PictureRecorder();
        final canvas = Canvas(recorder);

        const center = Offset(200.0, 250.0);

        // Cruiser
        mesh.projectAndPaint(
          canvas,
          center: center,
          vesselType: 1,
          pitchRad: 0.1,
          rollRad: -0.15,
          yawRad: 0.05,
          scale: 1.2,
          warpInProgress: 1.0,
          animationTime: 1.0,
        );
        for (var i = 0; i < 16; i++) {
          expect(mesh.projX[i].isFinite, isTrue);
          expect(mesh.projY[i].isFinite, isTrue);
        }

        // Flagship
        mesh.projectAndPaint(
          canvas,
          center: center,
          vesselType: 2,
          pitchRad: -0.08,
          rollRad: 0.2,
          yawRad: -0.1,
          scale: 1.5,
          warpInProgress: 1.0,
          animationTime: 1.5,
        );
        for (var i = 0; i < 20; i++) {
          expect(mesh.projX[i].isFinite, isTrue);
          expect(mesh.projY[i].isFinite, isTrue);
        }
      },
    );

    test(
      '3D Banking Roll shifts wingtip coordinates vertically and horizontally',
      () {
        final mesh = Invader3DMesh();
        final recorder = PictureRecorder();
        final canvas = Canvas(recorder);

        const center = Offset(200.0, 300.0);

        // 1. Level attitude
        mesh.projectAndPaint(
          canvas,
          center: center,
          vesselType: 0,
          pitchRad: 0.0,
          rollRad: 0.0,
          yawRad: 0.0,
          scale: 1.0,
          warpInProgress: 1.0,
          animationTime: 0.0,
        );
        final levelPortWingY = mesh.projY[Invader3DMesh.dronePortWingtip];
        final levelStbdWingY = mesh.projY[Invader3DMesh.droneStbdWingtip];
        expect(levelPortWingY, closeTo(levelStbdWingY, 0.5));

        // 2. Bank 30 degrees starboard
        mesh.projectAndPaint(
          canvas,
          center: center,
          vesselType: 0,
          pitchRad: 0.0,
          rollRad: 30.0 * (math.pi / 180.0),
          yawRad: 0.0,
          scale: 1.0,
          warpInProgress: 1.0,
          animationTime: 0.0,
        );
        final bankedPortWingY = mesh.projY[Invader3DMesh.dronePortWingtip];
        final bankedStbdWingY = mesh.projY[Invader3DMesh.droneStbdWingtip];
        // In a starboard roll, starboard wing drops and port wing rises
        expect(bankedPortWingY, isNot(closeTo(bankedStbdWingY, 1.0)));
      },
    );

    test(
      'Renders warp-in singularity progression cleanly without exception',
      () {
        final mesh = Invader3DMesh();
        final recorder = PictureRecorder();
        final canvas = Canvas(recorder);

        const center = Offset(150.0, 200.0);

        // Test across multiple stages of warp progression
        for (final progress in [0.0, 0.25, 0.5, 0.75, 1.0]) {
          for (var vesselType = 0; vesselType <= 2; vesselType++) {
            expect(
              () => mesh.projectAndPaint(
                canvas,
                center: center,
                vesselType: vesselType,
                pitchRad: 0.0,
                rollRad: 0.0,
                yawRad: 0.0,
                scale: 1.0,
                warpInProgress: progress,
                animationTime: 0.5,
                isLowBattery: false,
              ),
              returnsNormally,
            );
          }
        }
      },
    );

    test('Low battery mode and extreme scales execute safely', () {
      final mesh = Invader3DMesh();
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);

      const center = Offset(100.0, 100.0);
      expect(
        () => mesh.projectAndPaint(
          canvas,
          center: center,
          vesselType: 0,
          pitchRad: 0.5,
          rollRad: -0.5,
          yawRad: 0.2,
          scale: 0.1,
          warpInProgress: 0.5,
          animationTime: 10.0,
          isLowBattery: true,
        ),
        returnsNormally,
      );
    });
  });
}
