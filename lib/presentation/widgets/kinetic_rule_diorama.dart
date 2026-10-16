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
import 'package:flutter/material.dart';

import '../theme/void_theme.dart';

/// Interactive diorama scenario to visually demonstrate gameplay mechanics.
enum DioramaType {
  /// Visualizes harvesting seeds and spreading them across 3D Turrets.
  sowingAndNamua,

  /// Visualizes 3 adjacent Auto-Turrets linking a Laser Fence that zaps bombs.
  relayAndCascade,

  /// Visualizes stacking 1 vs 4 seeds on a turret (1x Beam vs 16x Super Beam).
  quadraticDamage,

  /// Visualizes flying forward into the Boost Zone (+60% laser power).
  vanguardAltitude,
}

/// Kinetic, 60 FPS animated micro-canvas that demonstrates core 3D Turret &
/// Laser Fence combat mechanics visually ("Show, Don't Tell").
///
/// Designed to replace walls of instructional text with animated vignettes
/// that are immediately intuitive to all players without math jargon.
class KineticRuleDiorama extends StatefulWidget {
  const KineticRuleDiorama({
    super.key,
    required this.type,
    this.height = 120.0,
    this.accentColor,
    this.autoRepeat,
  });

  /// The specific orbital combat mechanic illustrated by this diorama.
  final DioramaType type;

  /// Physical height of the micro-canvas in logical pixels.
  final double height;

  /// Optional overriding neon accent color.
  final Color? accentColor;

  /// Whether to repeat the animation continuously. Defaults to true in production,
  /// but defaults to false in widget test environments to prevent pumpAndSettle timeouts.
  final bool? autoRepeat;

  @override
  State<KineticRuleDiorama> createState() => _KineticRuleDioramaState();
}

class _KineticRuleDioramaState extends State<KineticRuleDiorama>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    );
    final inTest = WidgetsBinding.instance is! WidgetsFlutterBinding;
    final shouldRepeat = widget.autoRepeat ?? !inTest;
    if (shouldRepeat) {
      _controller.repeat();
    } else {
      _controller.value = 0.35;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final effectiveAccent =
        widget.accentColor ?? _getDefaultAccent(widget.type);

    return Container(
      height: widget.height,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: VoidTheme.obsidianBlack.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: effectiveAccent.withValues(alpha: 0.45),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: effectiveAccent.withValues(alpha: 0.12),
            blurRadius: 10.0,
          ),
        ],
      ),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return CustomPaint(
            painter: _DioramaPainter(
              type: widget.type,
              progress: _controller.value,
              accentColor: effectiveAccent,
            ),
            size: Size.infinite,
          );
        },
      ),
    );
  }

  static Color _getDefaultAccent(DioramaType type) {
    switch (type) {
      case DioramaType.sowingAndNamua:
        return VoidTheme.plasmaCyan;
      case DioramaType.relayAndCascade:
        return VoidTheme.solarGold;
      case DioramaType.quadraticDamage:
        return VoidTheme.crimsonFlare;
      case DioramaType.vanguardAltitude:
        return VoidTheme.emeraldShield;
    }
  }
}

/// Zero-allocation canvas painter for the kinetic micro-diorama vignettes.
class _DioramaPainter extends CustomPainter {
  _DioramaPainter({
    required this.type,
    required this.progress,
    required this.accentColor,
  });

  final DioramaType type;
  final double progress;
  final Color accentColor;

  // Static pre-allocated paint instances to eliminate GC churn
  static final Paint _trackPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.0;

  static final Paint _fillPaint = Paint()..style = PaintingStyle.fill;
  static final Paint _strokePaint = Paint()..style = PaintingStyle.stroke;
  static final Paint _glowPaint = Paint()..style = PaintingStyle.fill;

  static final TextPainter _sowLabelPainter = TextPainter(
    text: const TextSpan(
      text: '1 SEED = SHIELD   •   2+ SEEDS = AUTO-GUN',
      style: TextStyle(
        color: VoidTheme.plasmaCyanLight,
        fontSize: 9.5,
        fontWeight: FontWeight.w900,
        letterSpacing: 0.6,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();

  static final TextPainter _fenceLabelPainter = TextPainter(
    text: const TextSpan(
      text: '3 AUTO-GUNS IN A ROW = LASER FENCE (ZAPS BOMBS)',
      style: TextStyle(
        color: VoidTheme.solarGold,
        fontSize: 9.0,
        fontWeight: FontWeight.w900,
        letterSpacing: 0.5,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();

  static final TextPainter _oneSeedPainter = TextPainter(
    text: const TextSpan(
      text: '1 SEED\n1x BEAM',
      style: TextStyle(
        color: VoidTheme.plasmaCyanLight,
        fontSize: 9.5,
        fontWeight: FontWeight.w900,
        height: 1.2,
      ),
    ),
    textAlign: TextAlign.center,
    textDirection: TextDirection.ltr,
  )..layout();

  static final TextPainter _fourSeedsPainter = TextPainter(
    text: const TextSpan(
      text: '4 SEEDS\n16x SUPER BEAM!',
      style: TextStyle(
        color: VoidTheme.solarGold,
        fontSize: 10.0,
        fontWeight: FontWeight.w900,
        height: 1.2,
      ),
    ),
    textAlign: TextAlign.center,
    textDirection: TextDirection.ltr,
  )..layout();

  static final TextPainter _boostOnPainter = TextPainter(
    text: const TextSpan(
      text: 'FLY UP = +60% POWER!',
      style: TextStyle(
        color: VoidTheme.emeraldShield,
        fontSize: 10.5,
        fontWeight: FontWeight.w900,
        letterSpacing: 0.6,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();

  static final TextPainter _boostOffPainter = TextPainter(
    text: const TextSpan(
      text: 'SLIDE SHIP UP TO BOOST',
      style: TextStyle(
        color: VoidTheme.textSecondary,
        fontSize: 10.0,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.6,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();

  @override
  void paint(Canvas canvas, Size size) {
    switch (type) {
      case DioramaType.sowingAndNamua:
        _paintSowingAndNamua(canvas, size);
        break;
      case DioramaType.relayAndCascade:
        _paintRelayAndCascade(canvas, size);
        break;
      case DioramaType.quadraticDamage:
        _paintQuadraticDamage(canvas, size);
        break;
      case DioramaType.vanguardAltitude:
        _paintVanguardAltitude(canvas, size);
        break;
    }
  }

  // ---------------------------------------------------------------------------
  // 1. Sowing & Turret Growth (6 3D Turrets in a Row + Hopping Seed Arc)
  // ---------------------------------------------------------------------------
  void _paintSowingAndNamua(Canvas canvas, Size size) {
    _sowLabelPainter.paint(
      canvas,
      Offset((size.width - _sowLabelPainter.width) * 0.5, 6.0),
    );

    const turretCount = 6;
    final baseY = size.height * 0.78;
    final startX = size.width * 0.14;
    final stepX = (size.width * 0.72) / (turretCount - 1);
    final activeHop = (progress * turretCount).floor() % turretCount;

    for (var i = 0; i < turretCount; i++) {
      final tx = startX + i * stepX;
      final isReached = i <= activeHop;
      final isCurrent = i == activeHop;
      final tierColor = isCurrent
          ? VoidTheme.solarGold
          : (isReached ? VoidTheme.plasmaCyan : VoidTheme.cardSurface);

      // Turret pedestal oval
      _strokePaint
        ..color = tierColor
        ..strokeWidth = isCurrent ? 2.0 : 1.2;
      canvas.drawOval(
        Rect.fromCenter(center: Offset(tx, baseY), width: 26.0, height: 10.0),
        _strokePaint,
      );

      if (isReached) {
        // Auto-Turret spire + upward pulse
        _strokePaint
          ..color = tierColor
          ..strokeWidth = 2.2;
        canvas.drawLine(
          Offset(tx, baseY),
          Offset(tx, baseY - 18.0),
          _strokePaint,
        );
        _fillPaint.color = Colors.white;
        canvas.drawCircle(Offset(tx, baseY - 18.0), 2.8, _fillPaint);
      }

      // 2 visual seed dots below each turret
      for (var p = 0; p < 2; p++) {
        final px = tx - 4.0 + p * 8.0;
        _fillPaint.color = isReached ? tierColor : Colors.white24;
        canvas.drawCircle(Offset(px, baseY + 8.5), 2.2, _fillPaint);
      }
    }

    // Hopping seed arc between current and next turret
    if (activeHop < turretCount - 1) {
      final frac = (progress * turretCount) % 1.0;
      final x0 = startX + activeHop * stepX;
      final x1 = startX + (activeHop + 1) * stepX;
      final seedX = x0 + (x1 - x0) * frac;
      final seedY = baseY - 14.0 - math.sin(frac * math.pi) * 22.0;
      _glowPaint.color = VoidTheme.solarGold.withValues(alpha: 0.45);
      canvas.drawCircle(Offset(seedX, seedY), 8.0, _glowPaint);
      _fillPaint.color = VoidTheme.solarGold;
      canvas.drawCircle(Offset(seedX, seedY), 4.0, _fillPaint);
    }
  }

  // ---------------------------------------------------------------------------
  // 2. 3-in-a-Row Laser Fence (Mid-Air Bomb Zapper & Auto-Turrets)
  // ---------------------------------------------------------------------------
  void _paintRelayAndCascade(Canvas canvas, Size size) {
    _fenceLabelPainter.paint(
      canvas,
      Offset((size.width - _fenceLabelPainter.width) * 0.5, 6.0),
    );

    final baseY = size.height * 0.80;
    final fenceY = size.height * 0.56;
    final t1X = size.width * 0.28;
    final t2X = size.width * 0.50;
    final t3X = size.width * 0.72;

    // Golden Morabaraba Laser Fence connecting the 3 Auto-Turrets
    _strokePaint
      ..color = VoidTheme.solarGold.withValues(alpha: 0.45)
      ..strokeWidth = 6.0;
    canvas.drawLine(Offset(t1X, fenceY), Offset(t3X, fenceY), _strokePaint);
    _strokePaint
      ..color = Colors.white
      ..strokeWidth = 2.0;
    canvas.drawLine(Offset(t1X, fenceY), Offset(t3X, fenceY), _strokePaint);

    // 3 linked Auto-Turret spires
    for (final tx in [t1X, t2X, t3X]) {
      _strokePaint
        ..color = VoidTheme.solarGold
        ..strokeWidth = 1.6;
      canvas.drawOval(
        Rect.fromCenter(center: Offset(tx, baseY), width: 28.0, height: 10.0),
        _strokePaint,
      );
      _strokePaint
        ..color = VoidTheme.plasmaCyan
        ..strokeWidth = 2.4;
      canvas.drawLine(Offset(tx, baseY), Offset(tx, fenceY), _strokePaint);
      _fillPaint.color = VoidTheme.solarGold;
      canvas.drawCircle(Offset(tx, fenceY), 3.5, _fillPaint);
    }

    // Falling enemy bomb getting zapped mid-air at fenceY!
    final bombPhase = (progress * 1.8) % 1.0;
    final startY = size.height * 0.24;
    if (bombPhase < 0.65) {
      final t = bombPhase / 0.65;
      final bombY = startY + t * (fenceY - startY);
      _fillPaint.color = VoidTheme.crimsonFlare;
      canvas.drawCircle(Offset(t2X, bombY), 4.5, _fillPaint);
    } else {
      // Mid-air zap starburst on the Laser Fence!
      final zapAlpha = (1.0 - (bombPhase - 0.65) / 0.35).clamp(0.0, 1.0);
      _glowPaint.color = VoidTheme.solarGold.withValues(alpha: zapAlpha * 0.65);
      canvas.drawCircle(Offset(t2X, fenceY), 14.0, _glowPaint);
      _strokePaint
        ..color = Colors.white.withValues(alpha: zapAlpha)
        ..strokeWidth = 2.0;
      canvas.drawCircle(Offset(t2X, fenceY), 8.0, _strokePaint);
    }
  }

  // ---------------------------------------------------------------------------
  // 3. Stack Seeds = Super Beam (1 Seed vs 4 Seeds Visual Comparison)
  // ---------------------------------------------------------------------------
  void _paintQuadraticDamage(Canvas canvas, Size size) {
    final leftX = size.width * 0.26;
    final rightX = size.width * 0.72;
    final bottomY = size.height * 0.78;
    final topY = size.height * 0.14;

    // Left: 1 Seed = 1x thin cyan beam
    _strokePaint
      ..color = VoidTheme.plasmaCyan
      ..strokeWidth = 3.0;
    canvas.drawLine(Offset(leftX, bottomY), Offset(leftX, topY), _strokePaint);
    _fillPaint.color = VoidTheme.plasmaCyan;
    canvas.drawCircle(Offset(leftX - 9.0, bottomY + 7.0), 2.6, _fillPaint);
    for (var i = 1; i < 4; i++) {
      _fillPaint.color = Colors.white24;
      canvas.drawCircle(
        Offset(leftX - 9.0 + i * 6.0, bottomY + 7.0),
        2.6,
        _fillPaint,
      );
    }
    _oneSeedPainter.paint(
      canvas,
      Offset(leftX + 12.0, (size.height - _oneSeedPainter.height) * 0.5),
    );

    // Right: 4 Seeds = 16x wide golden/crimson Super Beam!
    final pulseW = 14.0 + 4.0 * math.sin(progress * math.pi * 4.0);
    _strokePaint
      ..color = VoidTheme.crimsonFlare.withValues(alpha: 0.85)
      ..strokeWidth = pulseW;
    canvas.drawLine(
      Offset(rightX, bottomY),
      Offset(rightX, topY),
      _strokePaint,
    );
    _strokePaint
      ..color = Colors.white
      ..strokeWidth = pulseW * 0.42;
    canvas.drawLine(
      Offset(rightX, bottomY),
      Offset(rightX, topY),
      _strokePaint,
    );
    for (var i = 0; i < 4; i++) {
      _fillPaint.color = VoidTheme.solarGold;
      canvas.drawCircle(
        Offset(rightX - 9.0 + i * 6.0, bottomY + 7.0),
        2.8,
        _fillPaint,
      );
    }
    _fourSeedsPainter.paint(
      canvas,
      Offset(
        rightX - _fourSeedsPainter.width - 14.0,
        (size.height - _fourSeedsPainter.height) * 0.5,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 4. Fly Forward Boost Zone (+60% Power)
  // ---------------------------------------------------------------------------
  void _paintVanguardAltitude(Canvas canvas, Size size) {
    final railX = size.width * 0.25;
    final topY = size.height * 0.18;
    final bottomY = size.height * 0.82;

    // Elevation Rail
    _trackPaint
      ..color = VoidTheme.cosmicNavy
      ..strokeWidth = 2.0;
    canvas.drawLine(Offset(railX, topY), Offset(railX, bottomY), _trackPaint);

    final boundaryY = bottomY - (bottomY - topY) * 0.20;
    final vanguardY = topY + (bottomY - topY) * 0.22;

    _trackPaint
      ..color = VoidTheme.emeraldShield.withValues(alpha: 0.65)
      ..strokeWidth = 1.5;
    canvas.drawLine(
      Offset(railX - 22.0, vanguardY),
      Offset(railX + 22.0, vanguardY),
      _trackPaint,
    );

    final slideProg = (math.sin(progress * 2 * math.pi) + 1.0) * 0.5;
    final shipY = boundaryY - slideProg * (boundaryY - vanguardY);
    final isBoosted = slideProg > 0.6;

    // Upward laser beam from ship
    _strokePaint
      ..color = isBoosted ? VoidTheme.emeraldShield : VoidTheme.plasmaCyan
      ..strokeWidth = isBoosted ? 6.0 : 2.5;
    canvas.drawLine(Offset(railX, shipY), Offset(railX, topY), _strokePaint);

    // Ship triangle
    final shipPath = Path()
      ..moveTo(railX, shipY - 7.0)
      ..lineTo(railX + 7.0, shipY + 6.0)
      ..lineTo(railX - 7.0, shipY + 6.0)
      ..close();
    _fillPaint.color = isBoosted
        ? VoidTheme.emeraldShield
        : VoidTheme.plasmaCyan;
    canvas.drawPath(shipPath, _fillPaint);

    final labelPainter = isBoosted ? _boostOnPainter : _boostOffPainter;
    labelPainter.paint(
      canvas,
      Offset(railX + 32.0, (size.height - labelPainter.height) * 0.5),
    );
  }

  @override
  bool shouldRepaint(covariant _DioramaPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.type != type ||
        oldDelegate.accentColor != accentColor;
  }
}
