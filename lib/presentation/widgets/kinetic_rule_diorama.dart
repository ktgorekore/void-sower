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
  /// Visualizes core injection (Namua) and clockwise distribution across the capacitor ring.
  sowingAndNamua,

  /// Visualizes the relay cascade (Kula) triggering an axial particle lance on frontline bays.
  relayAndCascade,

  /// Visualizes quadratic lance devastation (D = M²: 1 core vs 4 cores).
  quadraticDamage,

  /// Visualizes forward altitude thrust into the Vanguard zone (+60% damage bonus).
  vanguardAltitude,
}

/// Kinetic, 60 FPS animated micro-canvas that demonstrates core Bao orbital
/// combat mechanics visually ("Show, Don't Tell").
///
/// Designed to replace walls of instructional text with animated cybernetic
/// vignettes that are instantly intuitive to mobile players.
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
  // 1. Sowing & Namua (Circular Capacitor Sowing Loop)
  // ---------------------------------------------------------------------------
  void _paintSowingAndNamua(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.5, size.height * 0.5);
    final radius = math.min(size.width, size.height) * 0.36;

    // Outer faint track
    _trackPaint.color = VoidTheme.cosmicNavy;
    canvas.drawCircle(center, radius, _trackPaint);

    // 16 Bays around ring
    const totalBays = 16;
    final currentSowingBay = (progress * totalBays).floor() % totalBays;

    for (var i = 0; i < totalBays; i++) {
      final angle = -math.pi / 2 + (i * 2 * math.pi / totalBays);
      final bx = center.dx + radius * math.cos(angle);
      final by = center.dy + radius * math.sin(angle);

      final isCurrent = i == currentSowingBay;
      final isPast = i < currentSowingBay;

      _fillPaint.color = isCurrent
          ? VoidTheme.solarGold
          : (isPast
                ? VoidTheme.plasmaCyan.withValues(alpha: 0.8)
                : VoidTheme.cardSurface);

      canvas.drawCircle(Offset(bx, by), isCurrent ? 5.5 : 3.5, _fillPaint);

      if (isCurrent) {
        // Glow pulse
        _glowPaint.color = VoidTheme.solarGold.withValues(alpha: 0.45);
        canvas.drawCircle(Offset(bx, by), 10.0, _glowPaint);
      }
    }

    // Dropping core injection animation (Namua)
    if (progress < 0.25) {
      final dropProg = progress / 0.25;
      final dropY = (center.dy - radius - 20.0) + (dropProg * 20.0);
      _fillPaint.color = Colors.white;
      canvas.drawCircle(Offset(center.dx, dropY), 4.5, _fillPaint);
    }
  }

  // ---------------------------------------------------------------------------
  // 2. Relay & Cascade (Lance Discharge across Boundary)
  // ---------------------------------------------------------------------------
  void _paintRelayAndCascade(Canvas canvas, Size size) {
    final boundaryY = size.height * 0.65;
    final bayX = size.width * 0.5;

    // Atmospheric Boundary Line
    _trackPaint
      ..color = VoidTheme.cosmicNavy
      ..strokeWidth = 1.0;
    canvas.drawLine(
      Offset(20.0, boundaryY),
      Offset(size.width - 20.0, boundaryY),
      _trackPaint,
    );

    // Capacitor Bay at bottom
    final bayY = size.height * 0.82;
    _fillPaint.color = VoidTheme.solarGold;
    canvas.drawCircle(Offset(bayX, bayY), 8.0, _fillPaint);

    // Target invader in space
    final invaderY = size.height * 0.22;
    _fillPaint.color = VoidTheme.crimsonFlare;
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(bayX, invaderY),
        width: 18.0,
        height: 12.0,
      ),
      _fillPaint,
    );

    // Lance firing pulse
    final lancePhase = (progress * 2.0) % 1.0;
    if (lancePhase > 0.3) {
      final alpha = (1.0 - (lancePhase - 0.3) / 0.7).clamp(0.0, 1.0);
      // Axial beam
      _strokePaint
        ..color = Colors.white.withValues(alpha: alpha)
        ..strokeWidth = 4.0;
      canvas.drawLine(Offset(bayX, bayY), Offset(bayX, invaderY), _strokePaint);

      // Impact halo
      _glowPaint.color = VoidTheme.solarGold.withValues(alpha: alpha * 0.6);
      canvas.drawCircle(Offset(bayX, invaderY), 16.0 * lancePhase, _glowPaint);
    }
  }

  // ---------------------------------------------------------------------------
  // 3. Quadratic Lance Scaling (1 Core vs 4 Cores)
  // ---------------------------------------------------------------------------
  void _paintQuadraticDamage(Canvas canvas, Size size) {
    final isMassFour = (progress % 1.0) >= 0.5;
    final coresLabel = isMassFour ? '4 CORES' : '1 CORE';
    final beamWidth = isMassFour ? 20.0 : 4.0;
    final damageLabel = isMassFour ? '16x POWER (MASSIVE)' : '1x POWER (BASE)';

    final centerX = size.width * 0.35;
    final bottomY = size.height * 0.85;
    final topY = size.height * 0.15;

    // Laser Beam
    _strokePaint
      ..color = isMassFour ? VoidTheme.crimsonFlare : VoidTheme.plasmaCyan
      ..strokeWidth = beamWidth;
    canvas.drawLine(
      Offset(centerX, bottomY),
      Offset(centerX, topY),
      _strokePaint,
    );

    if (isMassFour) {
      // Hot-white core
      _strokePaint
        ..color = Colors.white
        ..strokeWidth = beamWidth * 0.45;
      canvas.drawLine(
        Offset(centerX, bottomY),
        Offset(centerX, topY),
        _strokePaint,
      );
    }

    // Devastation Gauge Text
    final tp = TextPainter(
      text: TextSpan(
        text: '$coresLabel\n$damageLabel',
        style: TextStyle(
          color: isMassFour
              ? VoidTheme.crimsonFlare
              : VoidTheme.plasmaCyanLight,
          fontSize: 12.0,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.8,
          height: 1.3,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    tp.paint(
      canvas,
      Offset(size.width * 0.52, (size.height - tp.height) * 0.5),
    );
  }

  // ---------------------------------------------------------------------------
  // 4. Vanguard Altitude (+60% Forward Damage)
  // ---------------------------------------------------------------------------
  void _paintVanguardAltitude(Canvas canvas, Size size) {
    final railX = size.width * 0.3;
    final topY = size.height * 0.18;
    final bottomY = size.height * 0.82;

    // Elevation Rail
    _trackPaint
      ..color = VoidTheme.cosmicNavy
      ..strokeWidth = 2.0;
    canvas.drawLine(Offset(railX, topY), Offset(railX, bottomY), _trackPaint);

    // Boundary Line & Vanguard Line
    final boundaryY = bottomY - (bottomY - topY) * 0.25;
    final vanguardY = topY + (bottomY - topY) * 0.15;

    _trackPaint
      ..color = VoidTheme.cardSurface
      ..strokeWidth = 1.0;
    canvas.drawLine(
      Offset(railX - 16.0, boundaryY),
      Offset(railX + 16.0, boundaryY),
      _trackPaint,
    );

    _trackPaint.color = VoidTheme.emeraldShield.withValues(alpha: 0.6);
    canvas.drawLine(
      Offset(railX - 20.0, vanguardY),
      Offset(railX + 20.0, vanguardY),
      _trackPaint,
    );

    // Sliding Dreadnought Flagship
    final slideProg = (math.sin(progress * 2 * math.pi) + 1.0) * 0.5;
    final shipY = boundaryY - slideProg * (boundaryY - vanguardY);

    _fillPaint.color = slideProg > 0.7
        ? VoidTheme.emeraldShield
        : VoidTheme.plasmaCyan;
    canvas.drawCircle(Offset(railX, shipY), 6.0, _fillPaint);

    // Bonus Tag
    final isVanguard = slideProg > 0.7;
    final tagText = isVanguard
        ? '+60% VANGUARD\nPROXIMITY BONUS'
        : 'STANDARD ALTITUDE';
    final tp = TextPainter(
      text: TextSpan(
        text: tagText,
        style: TextStyle(
          color: isVanguard ? VoidTheme.emeraldShield : VoidTheme.textSecondary,
          fontSize: 11.0,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.8,
          height: 1.3,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    tp.paint(canvas, Offset(railX + 32.0, (size.height - tp.height) * 0.5));
  }

  @override
  bool shouldRepaint(covariant _DioramaPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.type != type ||
        oldDelegate.accentColor != accentColor;
  }
}
