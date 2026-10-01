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
import 'dart:typed_data';
import 'package:flutter/material.dart';

import '../theme/void_theme.dart';

/// Pre-allocated high-performance 3D perspective warp starfield simulation.
///
/// Features:
/// - True pseudo-3D perspective projection with depth coordinate $z \in [0.08, 1.0]$.
/// - Dynamic warp acceleration and motion blur streak elongation scaling with forward flight depth.
/// - Lateral parallax drift reflecting dreadnought conduit translation.
/// - Zero dynamic runtime heap allocations during combat ticks using contiguous [Float32List] memory.
class Starfield3DSimulation {
  /// Initializes the 3D starfield simulation with a pre-allocated pool of [starCount] stars.
  Starfield3DSimulation({this.starCount = 160}) {
    _posX = Float32List(starCount);
    _posY = Float32List(starCount);
    _posZ = Float32List(starCount);
    _prevScreenX = Float32List(starCount);
    _prevScreenY = Float32List(starCount);
    _speed = Float32List(starCount);
    _baseRadius = Float32List(starCount);
    _baseAlpha = Float32List(starCount);
    _colorType = Uint8List(starCount);

    _initStarPool();
  }

  /// Total number of active stars managed in typed memory pools.
  final int starCount;

  late final Float32List _posX;
  late final Float32List _posY;
  late final Float32List _posZ;
  late final Float32List _prevScreenX;
  late final Float32List _prevScreenY;
  late final Float32List _speed;
  late final Float32List _baseRadius;
  late final Float32List _baseAlpha;
  late final Uint8List _colorType;

  /// Read-only test inspection view of star X coordinates.
  @visibleForTesting
  Float32List get posX => _posX;

  /// Read-only test inspection view of star Y coordinates.
  @visibleForTesting
  Float32List get posY => _posY;

  /// Read-only test inspection view of star Z coordinates.
  @visibleForTesting
  Float32List get posZ => _posZ;

  final math.Random _rng = math.Random(42);

  // Pre-cached static paints to eliminate per-frame allocations
  static final Paint _whiteStarPaint = Paint()..style = PaintingStyle.fill;
  static final Paint _cyanStarPaint = Paint()..style = PaintingStyle.fill;
  static final Paint _goldStarPaint = Paint()..style = PaintingStyle.fill;
  static final Paint _amethystStarPaint = Paint()..style = PaintingStyle.fill;

  static final Paint _streakWhitePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;

  static final Paint _streakCyanPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;

  static final Paint _streakGoldPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;

  static final Paint _nebulaGlowPaint = Paint()..style = PaintingStyle.fill;

  // Drifting cosmic nebula anchor positions
  double _nebulaPhase = 0.0;

  void _initStarPool() {
    for (var i = 0; i < starCount; i++) {
      _recycleStar(i, initialSpread: true);
    }
  }

  void _recycleStar(int i, {bool initialSpread = false}) {
    // Spread evenly across field of view
    final angle = _rng.nextDouble() * 2 * math.pi;
    final dist = math.sqrt(_rng.nextDouble()) * 1.25;
    _posX[i] = math.cos(angle) * dist;
    _posY[i] = math.sin(angle) * dist;
    _posZ[i] = initialSpread ? (0.08 + _rng.nextDouble() * 0.92) : 1.0;

    _prevScreenX[i] = -9999.0;
    _prevScreenY[i] = -9999.0;

    _speed[i] = 0.25 + _rng.nextDouble() * 0.45;
    _baseRadius[i] = 0.8 + _rng.nextDouble() * 1.6;
    _baseAlpha[i] = 0.4 + _rng.nextDouble() * 0.6;

    // 0: pure white (70%), 1: plasma cyan (15%), 2: solar gold (10%), 3: amethyst (5%)
    final roll = _rng.nextDouble();
    if (roll < 0.70) {
      _colorType[i] = 0;
    } else if (roll < 0.85) {
      _colorType[i] = 1;
    } else if (roll < 0.95) {
      _colorType[i] = 2;
    } else {
      _colorType[i] = 3;
    }
  }

  /// Advances the 3D starfield simulation by [dt] seconds.
  ///
  /// [normForward]: Normalized deep space forward flight depth in $[0.0, 1.0]$.
  /// [velocityDx]: Instantaneous lateral conduit sliding velocity in units/second.
  /// [viewportSize]: Real-time tactical combat viewport dimensions.
  void update({
    required double dt,
    required double normForward,
    required double velocityDx,
    required Size viewportSize,
  }) {
    if (viewportSize.width <= 0 || viewportSize.height <= 0) return;

    final clampedDt = dt.clamp(0.001, 0.05);
    final warpMultiplier = 1.0 + (5.5 * normForward.clamp(0.0, 1.0));
    final centerX = viewportSize.width * 0.5;
    final centerY =
        viewportSize.height * 0.42; // Vanishing point in upper third
    final scaleX = viewportSize.width * 0.48;
    final scaleY = viewportSize.height * 0.48;

    _nebulaPhase += clampedDt * (0.05 + 0.15 * normForward);

    for (var i = 0; i < starCount; i++) {
      // 1. Advance depth along Z axis (stars move towards camera)
      final stepZ = _speed[i] * clampedDt * warpMultiplier;
      _posZ[i] -= stepZ;

      // 2. Lateral parallax drift inversely proportional to Z depth
      final parallaxFactor = (1.15 - _posZ[i]).clamp(0.15, 1.0);
      _posX[i] -= velocityDx * clampedDt * 0.35 * parallaxFactor;

      // Check for camera pass or boundary exit
      if (_posZ[i] <= 0.06) {
        _recycleStar(i);
        continue;
      }

      // Compute perspective projected coordinates
      final invZ = 1.0 / _posZ[i];
      final sx = centerX + (_posX[i] * invZ) * scaleX;
      final sy = centerY + (_posY[i] * invZ) * scaleY;

      // If out of viewport bounds, recycle to horizon
      if (sx < -40.0 ||
          sx > viewportSize.width + 40.0 ||
          sy < -40.0 ||
          sy > viewportSize.height + 40.0) {
        _recycleStar(i);
      }
    }
  }

  /// Renders the projected 3D stars, warp streaks, and cosmic nebulae onto [canvas].
  void paint(
    Canvas canvas,
    Size size, {
    required double normForward,
    required double animationTime,
  }) {
    if (size.width <= 0 || size.height <= 0) return;

    final centerX = size.width * 0.5;
    final centerY = size.height * 0.42;
    final scaleX = size.width * 0.48;
    final scaleY = size.height * 0.48;

    final isWarping = normForward > 0.08;
    final streakFactor = (normForward * 2.8).clamp(0.0, 2.5);

    // -------------------------------------------------------------------------
    // 1. Cosmic Nebulae Pass: Drifting Kilwa Basin Atmosphere
    // -------------------------------------------------------------------------
    _paintCosmicNebulae(canvas, size, normForward);

    // -------------------------------------------------------------------------
    // 2. 3D Stars & Warp Streaks Pass
    // -------------------------------------------------------------------------
    for (var i = 0; i < starCount; i++) {
      final z = _posZ[i];
      if (z <= 0.06) continue;

      final invZ = 1.0 / z;
      final sx = centerX + (_posX[i] * invZ) * scaleX;
      final sy = centerY + (_posY[i] * invZ) * scaleY;

      // Brightness and size scale inversely with distance
      final depthFactor = ((1.0 - z) / 0.94).clamp(0.0, 1.0);
      final alpha = (_baseAlpha[i] * (0.25 + 0.75 * depthFactor)).clamp(
        0.0,
        1.0,
      );
      final radius = (_baseRadius[i] * (0.6 + 1.2 * depthFactor)).clamp(
        0.5,
        4.0,
      );

      final colorType = _colorType[i];
      final Color starColor;
      switch (colorType) {
        case 1:
          starColor = VoidTheme.plasmaCyan;
          break;
        case 2:
          starColor = VoidTheme.solarGold;
          break;
        case 3:
          starColor = VoidTheme.nebulaAmethyst;
          break;
        case 0:
        default:
          starColor = Colors.white;
          break;
      }

      if (isWarping && _prevScreenX[i] > -9000.0) {
        // High-velocity warp streaks
        final dx = sx - centerX;
        final dy = sy - centerY;
        final dist = math.sqrt(dx * dx + dy * dy);
        final streakLen = math.min(dist * 0.28 * streakFactor, 38.0);
        final nx = dist > 0.001 ? (dx / dist) : 0.0;
        final ny = dist > 0.001 ? (dy / dist) : 1.0;

        final tailX = sx - (nx * streakLen);
        final tailY = sy - (ny * streakLen);

        final Paint streakPaint;
        switch (colorType) {
          case 1:
            streakPaint = _streakCyanPaint
              ..color = starColor.withValues(alpha: alpha)
              ..strokeWidth = math.max(radius * 0.75, 1.0);
            break;
          case 2:
            streakPaint = _streakGoldPaint
              ..color = starColor.withValues(alpha: alpha)
              ..strokeWidth = math.max(radius * 0.75, 1.0);
            break;
          case 0:
          case 3:
          default:
            streakPaint = _streakWhitePaint
              ..color = starColor.withValues(alpha: alpha)
              ..strokeWidth = math.max(radius * 0.75, 1.0);
            break;
        }

        canvas.drawLine(Offset(tailX, tailY), Offset(sx, sy), streakPaint);
      } else {
        // Standard ambient orbital star point
        final Paint starPaint;
        switch (colorType) {
          case 1:
            starPaint = _cyanStarPaint
              ..color = starColor.withValues(alpha: alpha);
            break;
          case 2:
            starPaint = _goldStarPaint
              ..color = starColor.withValues(alpha: alpha);
            break;
          case 3:
            starPaint = _amethystStarPaint
              ..color = starColor.withValues(alpha: alpha);
            break;
          case 0:
          default:
            starPaint = _whiteStarPaint
              ..color = starColor.withValues(alpha: alpha);
            break;
        }

        canvas.drawCircle(Offset(sx, sy), radius, starPaint);
      }

      _prevScreenX[i] = sx;
      _prevScreenY[i] = sy;
    }
  }

  void _paintCosmicNebulae(Canvas canvas, Size size, double normForward) {
    // Drifting luminous nebula clouds in the Kilwa cosmic basin
    final nebula1X =
        size.width * 0.25 + math.sin(_nebulaPhase * 0.8) * (size.width * 0.12);
    final nebula1Y =
        size.height * 0.30 +
        math.cos(_nebulaPhase * 0.6) * (size.height * 0.08);

    final nebula2X =
        size.width * 0.78 + math.cos(_nebulaPhase * 0.7) * (size.width * 0.10);
    final nebula2Y =
        size.height * 0.55 +
        math.sin(_nebulaPhase * 0.5) * (size.height * 0.10);

    // Cyan orbital ionization cloud
    final alpha1 = (0.04 + 0.03 * normForward).clamp(0.0, 0.12);
    _nebulaGlowPaint.color = VoidTheme.plasmaCyan.withValues(alpha: alpha1);
    canvas.drawCircle(
      Offset(nebula1X, nebula1Y),
      size.width * 0.42,
      _nebulaGlowPaint,
    );

    // Amethyst deep-space rift anomaly
    final alpha2 = (0.035 + 0.035 * normForward).clamp(0.0, 0.12);
    _nebulaGlowPaint.color = VoidTheme.nebulaAmethyst.withValues(alpha: alpha2);
    canvas.drawCircle(
      Offset(nebula2X, nebula2Y),
      size.width * 0.38,
      _nebulaGlowPaint,
    );
  }
}

/// Standalone Flutter widget rendering the dynamic 3D perspective warp starfield.
class Starfield3DWidget extends StatelessWidget {
  /// Creates a [Starfield3DWidget] with the given [simulation] and parameters.
  const Starfield3DWidget({
    super.key,
    required this.simulation,
    required this.normForward,
    required this.animationTime,
  });

  /// The active typed starfield simulation state.
  final Starfield3DSimulation simulation;

  /// Normalized deep space forward flight depth in $[0.0, 1.0]$.
  final double normForward;

  /// Global continuous animation clock in seconds.
  final double animationTime;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _Starfield3DPainter(
        simulation: simulation,
        normForward: normForward,
        animationTime: animationTime,
      ),
      isComplex: true,
      willChange: true,
    );
  }
}

class _Starfield3DPainter extends CustomPainter {
  const _Starfield3DPainter({
    required this.simulation,
    required this.normForward,
    required this.animationTime,
  });

  final Starfield3DSimulation simulation;
  final double normForward;
  final double animationTime;

  @override
  void paint(Canvas canvas, Size size) {
    simulation.paint(
      canvas,
      size,
      normForward: normForward,
      animationTime: animationTime,
    );
  }

  @override
  bool shouldRepaint(covariant _Starfield3DPainter oldDelegate) => true;
}
