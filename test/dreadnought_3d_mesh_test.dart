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
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_sower/presentation/widgets/dreadnought_3d_mesh.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Dreadnought3DMesh 3D Spatial Geometry Tests', () {
    test('Initializes 16 vertices in valid local model bounds', () {
      final mesh = Dreadnought3DMesh();
      expect(Dreadnought3DMesh.vertexCount, equals(16));

      // Verify projected buffers are instantiated
      expect(mesh.projX.length, equals(16));
      expect(mesh.projY.length, equals(16));
      expect(mesh.camZ.length, equals(16));
    });

    test(
      'Projects vertices centered at specified offset in neutral attitude',
      () {
        final mesh = Dreadnought3DMesh();
        final recorder = PictureRecorder();
        final canvas = Canvas(recorder);

        const center = Offset(200.0, 400.0);
        mesh.projectAndPaint(
          canvas,
          center: center,
          pitchRad: 0.0,
          rollRad: 0.0,
          yawRad: 0.0,
          scale: 1.0,
          animationTime: 1.0,
        );

        // Verify prow tip is centered horizontally and forward (negative Y relative to center)
        expect(mesh.projX[Dreadnought3DMesh.vProwTip], closeTo(center.dx, 0.5));
        expect(mesh.projY[Dreadnought3DMesh.vProwTip], lessThan(center.dy));

        // Verify symmetry in port and starboard wingtips
        final portWingtipDx =
            (mesh.projX[Dreadnought3DMesh.vPortWingtip] - center.dx).abs();
        final stbdWingtipDx =
            (mesh.projX[Dreadnought3DMesh.vStbdWingtip] - center.dx).abs();
        expect(portWingtipDx, closeTo(stbdWingtipDx, 0.5));

        // Verify all projected coordinates are finite real numbers
        for (var i = 0; i < Dreadnought3DMesh.vertexCount; i++) {
          expect(mesh.projX[i].isFinite, isTrue);
          expect(mesh.projY[i].isFinite, isTrue);
          expect(mesh.camZ[i].isFinite, isTrue);
        }
      },
    );

    test('3D Pitch: Nosing down during deep space forward thrust', () {
      final mesh = Dreadnought3DMesh();
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);

      const center = Offset(200.0, 400.0);

      // 1. Level attitude
      mesh.projectAndPaint(
        canvas,
        center: center,
        pitchRad: 0.0,
        rollRad: 0.0,
        yawRad: 0.0,
        scale: 1.0,
        animationTime: 0.0,
      );
      final levelProwY = mesh.projY[Dreadnought3DMesh.vProwTip];

      // 2. Pitch down (-15 deg into deep space flight vector)
      mesh.projectAndPaint(
        canvas,
        center: center,
        pitchRad: -15.0 * (math.pi / 180.0),
        rollRad: 0.0,
        yawRad: 0.0,
        scale: 1.0,
        animationTime: 0.0,
      );
      final pitchedProwY = mesh.projY[Dreadnought3DMesh.vProwTip];

      // Nosing down into screen space rotates prow downward towards camera plane
      expect(pitchedProwY, greaterThan(levelProwY));
    });

    test(
      '3D Roll: Banking cants port and starboard wings in opposite vertical directions',
      () {
        final mesh = Dreadnought3DMesh();
        final recorder = PictureRecorder();
        final canvas = Canvas(recorder);

        const center = Offset(200.0, 400.0);

        // Starboard bank (+20 deg)
        mesh.projectAndPaint(
          canvas,
          center: center,
          pitchRad: 0.0,
          rollRad: 20.0 * (math.pi / 180.0),
          yawRad: 0.0,
          scale: 1.0,
          animationTime: 0.0,
        );

        final portY = mesh.projY[Dreadnought3DMesh.vPortWingtip];
        final stbdY = mesh.projY[Dreadnought3DMesh.vStbdWingtip];

        // Starboard wingtip drops lower on screen (greater Y), Port wingtip rises (smaller Y)
        expect(stbdY, greaterThan(portY));
      },
    );

    test('3D Yaw: Heading rotation displaces lateral vertices', () {
      final mesh = Dreadnought3DMesh();
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);

      const center = Offset(200.0, 400.0);

      // Starboard yaw (+15 deg)
      mesh.projectAndPaint(
        canvas,
        center: center,
        pitchRad: 0.0,
        rollRad: 0.0,
        yawRad: 15.0 * (math.pi / 180.0),
        scale: 1.0,
        animationTime: 0.0,
      );

      // Prow should yaw towards positive X (starboard)
      expect(mesh.projX[Dreadnought3DMesh.vProwTip], greaterThan(center.dx));
    });

    testWidgets(
      'Renders cleanly on CustomPaint with isLowBattery true and false',
      (tester) async {
        final mesh = Dreadnought3DMesh();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: CustomPaint(
                  size: const Size(300, 300),
                  painter: _TestMeshPainter(mesh: mesh, isLowBattery: false),
                ),
              ),
            ),
          ),
        );

        expect(find.byType(CustomPaint), findsWidgets);

        // Low battery mode
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: CustomPaint(
                  size: const Size(300, 300),
                  painter: _TestMeshPainter(mesh: mesh, isLowBattery: true),
                ),
              ),
            ),
          ),
        );

        expect(find.byType(CustomPaint), findsWidgets);
      },
    );
  });
}

class _TestMeshPainter extends CustomPainter {
  _TestMeshPainter({required this.mesh, required this.isLowBattery});

  final Dreadnought3DMesh mesh;
  final bool isLowBattery;

  @override
  void paint(Canvas canvas, Size size) {
    mesh.projectAndPaint(
      canvas,
      center: Offset(size.width / 2, size.height / 2),
      pitchRad: -0.25,
      rollRad: 0.15,
      yawRad: -0.10,
      scale: 1.0,
      animationTime: 2.5,
      isLowBattery: isLowBattery,
    );
  }

  @override
  bool shouldRepaint(covariant _TestMeshPainter oldDelegate) => true;
}
