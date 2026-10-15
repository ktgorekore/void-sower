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
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

import '../../domain/models/dreadnought_state.dart';
import '../../domain/models/enemy_bullet.dart';
import '../../domain/models/enemy_craft.dart';
import '../../domain/models/flak_burst.dart';
import '../../domain/models/floating_damage_number.dart';
import '../../domain/models/lance_beam.dart';
import '../../domain/models/space_anomaly.dart';
import '../services/particle_service.dart';
import '../theme/void_theme.dart';
import 'combat_camera_3d.dart';
import 'dreadnought_3d_mesh.dart';
import 'invader_3d_mesh.dart';

/// Retained Skia 3D perspective background layer rendering a clean, clutter-free
/// wide-field 3D deep-space nebula expanse and bottom defense perimeter line.
class CombatBackgroundPainter extends CustomPainter {
  const CombatBackgroundPainter({
    this.isLowBattery = false,
    this.camera = const CombatCamera3D(),
  });

  final bool isLowBattery;
  final CombatCamera3D camera;

  // Pre-allocated buffers for smooth Gouraud-shaded 3D deep-space horizon plane
  static const int _deckLanes = 8;
  static const int _deckZSegs = 4;
  static const int _deckQuadCount = _deckLanes * _deckZSegs;
  static const List<double> _deckZStops = [0.0, 0.32, 0.68, 1.05, 1.85];
  static final Float32List _deckPositions = Float32List(_deckQuadCount * 4 * 2);
  static final Int32List _deckColors = Int32List(_deckQuadCount * 4);
  static final Uint16List _deckIndices = _buildDeckIndices();

  static Uint16List _buildDeckIndices() {
    final indices = Uint16List(_deckQuadCount * 6);
    for (var q = 0; q < _deckQuadCount; q++) {
      final vBase = q * 4;
      final iBase = q * 6;
      indices[iBase] = vBase;
      indices[iBase + 1] = vBase + 1;
      indices[iBase + 2] = vBase + 2;
      indices[iBase + 3] = vBase;
      indices[iBase + 4] = vBase + 2;
      indices[iBase + 5] = vBase + 3;
    }
    return indices;
  }

  static final Paint _deckVerticesPaint = Paint()..style = PaintingStyle.fill;

  static final Paint _nebulaTealPaint = Paint()
    ..color = const Color(0xFF0EA5E9).withValues(alpha: 0.07)
    ..style = PaintingStyle.fill;

  static final Paint _nebulaAmethystPaint = Paint()
    ..color = const Color(0xFF7C3AED).withValues(alpha: 0.08)
    ..style = PaintingStyle.fill;

  static final Paint _nebulaGoldPaint = Paint()
    ..color = const Color(0xFFF59E0B).withValues(alpha: 0.06)
    ..style = PaintingStyle.fill;

  static final Paint _boundaryPaint = Paint()
    ..color = VoidTheme.crimsonFlare.withValues(alpha: 0.48)
    ..strokeWidth = 1.4
    ..style = PaintingStyle.stroke;

  static final Paint _railPaint = Paint()
    ..color = VoidTheme.solarGold.withValues(alpha: 0.35)
    ..strokeWidth = 1.4
    ..style = PaintingStyle.stroke;

  static final TextPainter _apogeePainter = TextPainter(
    text: TextSpan(
      text: 'APOGEE HORIZON  Z: +40km',
      style: TextStyle(
        color: VoidTheme.plasmaCyan.withValues(alpha: 0.54),
        fontSize: 6.8,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
        fontFamily: 'monospace',
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();

  static final TextPainter _midCombatPainter = TextPainter(
    text: TextSpan(
      text: 'MID-COMBAT HORIZON  Z: +20km',
      style: TextStyle(
        color: VoidTheme.plasmaCyan.withValues(alpha: 0.54),
        fontSize: 6.8,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
        fontFamily: 'monospace',
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();

  static final TextPainter _forwardEngagePainter = TextPainter(
    text: TextSpan(
      text: 'FORWARD ENGAGE HORIZON  Z: +10km',
      style: TextStyle(
        color: VoidTheme.plasmaCyan.withValues(alpha: 0.54),
        fontSize: 6.8,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
        fontFamily: 'monospace',
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();

  /// Static pre-laid out painter for atmospheric threshold label.
  @visibleForTesting
  static TextPainter get thresholdPainter => _thresholdPainter;

  @visibleForTesting
  static TextPainter get apogeePainter => _apogeePainter;

  @visibleForTesting
  static TextPainter get midCombatPainter => _midCombatPainter;

  @visibleForTesting
  static TextPainter get forwardEngagePainter => _forwardEngagePainter;

  static final TextPainter _thresholdPainter = TextPainter(
    text: TextSpan(
      text: '▲ DEFENDER PERIMETER • DRAG SHIP FORWARD TO CONQUER STAR ▲',
      style: TextStyle(
        color: VoidTheme.plasmaCyan.withValues(alpha: 0.90),
        fontSize: 7.4,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.0,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();

  /// Renders a seamless, lineless 3D deep-space nebula & cosmic horizon field
  /// using Gouraud-shaded hardware vertices without rigid lane grid outlines.
  void _drawDeepSpaceNebulaExpanse(Canvas canvas, Size size) {
    if (!isLowBattery) {
      final shiftX = -camera.followX * 36.0;
      final shiftY = camera.followZ * 28.0;
      canvas.drawCircle(
        Offset(size.width * 0.24 + shiftX, size.height * 0.34 + shiftY),
        size.width * 0.36,
        _nebulaTealPaint,
      );
      canvas.drawCircle(
        Offset(size.width * 0.76 + shiftX * 0.8, size.height * 0.42 + shiftY),
        size.width * 0.38,
        _nebulaAmethystPaint,
      );
      canvas.drawCircle(
        Offset(size.width * 0.50 + shiftX * 0.5, size.height * 0.22 + shiftY),
        size.width * 0.30,
        _nebulaGoldPaint,
      );
    }

    // Subtle Gouraud-shaded 3D orbital plane gradient (no hard lane stripes)
    const centerPalette = [
      0xB8071124, // Z=0.00: Deep obsidian-navy perimeter
      0x9E0A1934, // Z=0.32: Mid-near cosmic indigo
      0x850E2246, // Z=0.68: Mid-far sapphire nebula
      0x6B122B58, // Z=1.05: Apogee horizon glow
      0x381D427A, // Z=1.85: Deep-space stellar fade
    ];
    const flankPalette = [
      0xA8050C1A, // Z=0.00: Dark flank perimeter
      0x8C071226, // Z=0.32: Mid-near flank
      0x700A1934, // Z=0.68: Mid-far flank
      0x520D2042, // Z=1.05: Apogee flank
      0x24142E5C, // Z=1.85: Deep-space flank fade
    ];

    var quadIdx = 0;
    for (var s = 0; s < _deckZSegs; s++) {
      final z0 = _deckZStops[s];
      final z1 = _deckZStops[s + 1];
      for (var c = 0; c < _deckLanes; c++) {
        final leftX = c / 8.0;
        final rightX = (c + 1) / 8.0;

        final nL = camera.project(size, normX: leftX, normZ: z0).groundOffset;
        final nR = camera.project(size, normX: rightX, normZ: z0).groundOffset;
        final fR = camera.project(size, normX: rightX, normZ: z1).groundOffset;
        final fL = camera.project(size, normX: leftX, normZ: z1).groundOffset;

        final vBase = quadIdx * 4;
        final pBase = vBase * 2;
        _deckPositions[pBase] = nL.dx;
        _deckPositions[pBase + 1] = nL.dy;
        _deckPositions[pBase + 2] = nR.dx;
        _deckPositions[pBase + 3] = nR.dy;
        _deckPositions[pBase + 4] = fR.dx;
        _deckPositions[pBase + 5] = fR.dy;
        _deckPositions[pBase + 6] = fL.dx;
        _deckPositions[pBase + 7] = fL.dy;

        final isCenter = c >= 2 && c <= 5;
        final nearCol = isCenter ? centerPalette[s] : flankPalette[s];
        final farCol = isCenter ? centerPalette[s + 1] : flankPalette[s + 1];
        _deckColors[vBase] = nearCol;
        _deckColors[vBase + 1] = nearCol;
        _deckColors[vBase + 2] = farCol;
        _deckColors[vBase + 3] = farCol;

        quadIdx++;
      }
    }

    final vertices = ui.Vertices.raw(
      ui.VertexMode.triangles,
      _deckPositions,
      colors: _deckColors,
      indices: _deckIndices,
    );
    canvas.drawVertices(vertices, BlendMode.dst, _deckVerticesPaint);
  }

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Seamless 3D Deep-Space Nebula & Cosmic Horizon Field (no target star, emitter docks, or text clutter!)
    _drawDeepSpaceNebulaExpanse(canvas, size);

    // 2. Subtle Bottom 3D Defender Perimeter Threshold Line at normZ = 0.0
    final threshLeft = camera.project(size, normX: 0.02, normZ: 0.0);
    final threshRight = camera.project(size, normX: 0.98, normZ: 0.0);
    canvas.drawLine(
      threshLeft.groundOffset,
      threshRight.groundOffset,
      _boundaryPaint,
    );

    // 3. Planetary Defense Base Rail
    canvas.drawLine(
      Offset(0, size.height - 1.5),
      Offset(size.width, size.height - 1.5),
      _railPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CombatBackgroundPainter oldDelegate) =>
      oldDelegate.isLowBattery != isLowBattery || oldDelegate.camera != camera;
}

/// 60/120 FPS dynamic CustomPainter rendering particle lances, secondary flak bursts,
/// enemy vessels, enemy projectiles, visual particles, and the player's flagship dreadnought.
///
/// Employs zero-allocation object pools for all [Paint], [Path], and [TextPainter] geometry,
/// completely eliminating heap churn and Scudo allocator lock contention.
class CombatPainter extends CustomPainter {
  CombatPainter({
    required this.dreadnought,
    required this.enemies,
    required this.lances,
    required this.flaks,
    required this.particles,
    this.anomalies = const [],
    this.damageNumbers = const [],
    this.enemyBullets = const [],
    this.millTriadBays = const <int>{},
    this.predictedDamage,
    required this.animationTime,
    this.isLowBattery = false,
    this.camera = const CombatCamera3D(),
    super.repaint,
  });

  final DreadnoughtState dreadnought;
  final List<EnemyCraft> enemies;
  final List<LanceBeam> lances;
  final List<FlakBurst> flaks;
  final List<VisualParticle> particles;
  final List<SpaceAnomaly> anomalies;
  final List<FloatingDamageNumber> damageNumbers;
  final List<EnemyBullet> enemyBullets;
  final Set<int> millTriadBays;
  final double? predictedDamage;
  final double animationTime;
  final bool isLowBattery;
  final CombatCamera3D camera;

  static final Dreadnought3DMesh _dreadMesh = Dreadnought3DMesh();
  static final Invader3DMesh _invaderMesh = Invader3DMesh();
  static final Paint _millCorridorPaint = Paint()
    ..color = VoidTheme.solarGold.withValues(alpha: 0.10)
    ..style = PaintingStyle.fill;
  static final Paint _millBorderPaint = Paint()
    ..color = VoidTheme.solarGold.withValues(alpha: 0.55)
    ..strokeWidth = 1.4
    ..style = PaintingStyle.stroke;

  // ---------------------------------------------------------------------------
  // Reusable Path Scratchpads & Pre-compiled Static Geometry
  // ---------------------------------------------------------------------------
  static final Path _scratchVolumetricLancePath = Path();
  static final Path _scratchLeftFlamePath = Path();
  static final Path _scratchRightFlamePath = Path();
  static final Path _scratchReticlePath = Path();
  static final Path _scratchBarPath = Path();

  // ---------------------------------------------------------------------------
  // Pre-allocated Static Paint Pools (Zero Allocations & Zero MaskFilter Blurs)
  // ---------------------------------------------------------------------------
  static final Paint _lanceCorePaint = Paint()
    ..color = Colors.white
    ..strokeCap = StrokeCap.round;

  static final Shader _staticLanceGlowShader = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [
      Colors.transparent,
      VoidTheme.plasmaCyan.withValues(alpha: 0.50),
      Colors.white.withValues(alpha: 0.85),
      VoidTheme.plasmaCyan.withValues(alpha: 0.50),
      Colors.transparent,
    ],
  ).createShader(const Rect.fromLTWH(-1.0, 0, 2.0, 1.0));

  static final Paint _lanceGlowPaint = Paint()
    ..style = PaintingStyle.fill
    ..shader = _staticLanceGlowShader;

  static final Paint _muzzlePaint = Paint()..color = Colors.white;
  static final Paint _muzzleGlowPaint = Paint()
    ..color = VoidTheme.plasmaCyan.withValues(alpha: 0.45)
    ..style = PaintingStyle.fill;

  static final Paint _muzzleSpikePaint = Paint()
    ..color = VoidTheme.solarGold
    ..strokeWidth = 2.5;

  static final Paint _impactPaint = Paint()
    ..color = VoidTheme.plasmaCyan.withValues(alpha: 0.85)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3.0;

  static final Paint _flakPaint = Paint()..style = PaintingStyle.stroke;

  static final Paint _enemyShadowFillPaint = Paint()
    ..color = Colors.black.withValues(alpha: 0.45)
    ..style = PaintingStyle.fill;

  static final Paint _enemyShadowRingPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.1;

  static final Paint _warpSingularityPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.0;

  static final Paint _healthBgPaint = Paint()..color = Colors.black54;
  static final Paint _healthHullPaint = Paint()..color = Colors.redAccent;
  static final Paint _healthShieldPaint = Paint()..color = VoidTheme.plasmaCyan;

  static final Paint _bulletTailPaint = Paint()..style = PaintingStyle.stroke;
  static final Paint _bulletGlowPaint = Paint()..style = PaintingStyle.fill;
  static final Paint _bulletOrbPaint = Paint()..style = PaintingStyle.fill;
  static final Paint _bulletCenterPaint = Paint()
    ..color = Colors.white
    ..style = PaintingStyle.fill;

  static final Paint _particlePaint = Paint()..style = PaintingStyle.fill;

  static final Paint _highlightPaint = Paint()
    ..color = VoidTheme.plasmaCyan.withValues(alpha: 0.08)
    ..style = PaintingStyle.fill;

  static final Paint _aimGlowPaint = Paint()
    ..strokeWidth = 4.5
    ..style = PaintingStyle.stroke;

  static final Paint _aimPaint = Paint()
    ..strokeWidth = 1.8
    ..style = PaintingStyle.stroke;

  static final Paint _corridorBorderPaint = Paint()
    ..strokeWidth = 1.0
    ..style = PaintingStyle.stroke;

  static final Paint _lockPaint = Paint()
    ..color = VoidTheme.solarGold.withValues(alpha: 0.85)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.8;

  static final Paint _lockCrosshairPaint = Paint()
    ..color = VoidTheme.crimsonFlare
    ..strokeWidth = 1.4
    ..style = PaintingStyle.stroke;

  static final Paint _flamePaint = Paint()
    ..color = VoidTheme.plasmaCyan.withValues(alpha: 0.75)
    ..style = PaintingStyle.fill;

  static final Paint _shieldArcPaint = Paint()
    ..color = VoidTheme.plasmaCyan
    ..strokeWidth = 2.4
    ..style = PaintingStyle.stroke;

  static final Paint _shieldGlowPaint = Paint()
    ..color = VoidTheme.plasmaCyan.withValues(alpha: 0.35)
    ..strokeWidth = 5.0
    ..style = PaintingStyle.stroke;

  static final Paint _damageTagBgPaint = Paint()
    ..color = VoidTheme.obsidianBlack.withValues(alpha: 0.92)
    ..style = PaintingStyle.fill;

  static final Paint _damageTagBorderPaint = Paint()
    ..color = VoidTheme.plasmaCyan
    ..strokeWidth = 1.0
    ..style = PaintingStyle.stroke;

  static final Map<int, TextPainter> _damageTagPainters = {
    for (final dmg in [16, 32, 64, 128, 256, 512, 1024])
      dmg: _createDamageTagPainter(dmg),
  };

  static TextPainter _createDamageTagPainter(int dmg) {
    return TextPainter(
      text: TextSpan(
        text: '⚡ ${dmg}x DMG',
        style: const TextStyle(
          color: VoidTheme.plasmaCyan,
          fontSize: 9.5,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
  }

  static TextPainter _getDamageTagPainter(int dmgValue) {
    var painter = _damageTagPainters[dmgValue];
    if (painter == null) {
      if (_damageTagPainters.length >= 32) {
        _damageTagPainters.removeWhere(
          (k, _) => ![16, 32, 64, 128, 256, 512, 1024].contains(k),
        );
      }
      painter = _createDamageTagPainter(dmgValue);
      _damageTagPainters[dmgValue] = painter;
    }
    return painter;
  }

  /// Pre-allocated lookup table for proximity tiers (+10%, +20%, +30%, +40%, +50%, +60%).
  static final List<TextPainter> _vanguardTagPainters = List.generate(7, (i) {
    final bonus = (i == 0 ? 10 : i * 10);
    return TextPainter(
      text: TextSpan(
        text: '⚡ VANGUARD +$bonus% LANCE',
        style: const TextStyle(
          color: VoidTheme.solarGold,
          fontSize: 8.5,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.8,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
  });

  // Pre-computed flight hint text painters across 16 discrete opacity tiers
  static final List<TextPainter> _flightHintPainters = List.generate(16, (i) {
    final alpha = (0.20 + (i / 15.0) * (0.95 - 0.20)).clamp(0.0, 1.0);
    final painter = TextPainter(
      text: TextSpan(
        text: '▲   ▲   ▲',
        style: TextStyle(
          color: VoidTheme.plasmaCyan.withValues(alpha: alpha),
          fontSize: 9.5,
          fontWeight: FontWeight.w900,
          letterSpacing: 2.0,
          shadows: [
            Shadow(
              color: Colors.black.withValues(alpha: alpha),
              blurRadius: 4.0,
            ),
            Shadow(
              color: VoidTheme.plasmaCyan.withValues(alpha: alpha),
              blurRadius: 8.0,
            ),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    return painter;
  });

  @visibleForTesting
  static List<TextPainter> get vanguardTagPainters => _vanguardTagPainters;

  @visibleForTesting
  static Map<int, TextPainter> get damageTagPainters => _damageTagPainters;

  @visibleForTesting
  static TextPainter get flightHintPainter => _flightHintPainters.last;

  @visibleForTesting
  static List<TextPainter> get flightHintPainters => _flightHintPainters;

  @visibleForTesting
  static Path get scratchReticlePath => _scratchReticlePath;

  @visibleForTesting
  static Path get scratchBarPath => _scratchBarPath;

  // ---------------------------------------------------------------------------
  // 3D Space Motion & Kinetic Cues Static Paints
  // ---------------------------------------------------------------------------
  static final Paint _bowShockPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.2;

  static final Paint _anchorRingPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.2
    ..color = VoidTheme.plasmaCyan.withValues(alpha: 0.45);

  static final Paint _anchorTetherPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.0;

  @visibleForTesting
  static Paint get anchorRingPaint => _anchorRingPaint;

  @visibleForTesting
  static Paint get anchorTetherPaint => _anchorTetherPaint;

  static final Paint _bowShockGlowPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 6.0;

  static final Paint _contrailPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.4
    ..strokeCap = StrokeCap.round;

  static final Paint _powerFeedGlowPaint = Paint()
    ..color = VoidTheme.solarGold.withValues(alpha: 0.38)
    ..strokeWidth = 5.0
    ..strokeCap = StrokeCap.round
    ..style = PaintingStyle.stroke;

  static final Paint _powerFeedCorePaint = Paint()
    ..color = VoidTheme.solarGold
    ..strokeWidth = 2.0
    ..strokeCap = StrokeCap.round
    ..style = PaintingStyle.stroke;

  static final Paint _flightTrackPaint = Paint()
    ..color = VoidTheme.plasmaCyan.withValues(alpha: 0.32)
    ..strokeWidth = 1.6
    ..style = PaintingStyle.stroke;

  static final Paint _steerChevronPaint = Paint()
    ..color = VoidTheme.solarGold.withValues(alpha: 0.88)
    ..strokeWidth = 2.0
    ..strokeCap = StrokeCap.round
    ..style = PaintingStyle.stroke;

  static final Paint _scrollSleeperPaint = Paint()..style = PaintingStyle.fill;

  static final Paint _scrollPylonPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.6;

  static final Int32List _enemySortOrder = Int32List(64);

  /// Renders floating 3D astral lane buoys and active-corridor chevrons
  /// streaming through 3D space without cluttering the viewport with wing-pylons
  /// or emitter dock ovals.
  void _drawInfiniteScrollingHighway3D(
    Canvas canvas,
    Size size,
    CombatCamera3D cam,
    double normForward,
    int activeCorridor,
  ) {
    final scrollSpeed = 0.36 + normForward * 1.15;
    final phase = (animationTime * scrollSpeed) % 1.0;

    // 1. Identify which corridors currently have an enemy swaying through them
    var occupiedMask = 0;
    for (var i = 0; i < enemies.length; i++) {
      final e = enemies[i];
      if (!e.isDestroyed) {
        final c = e.assignedCorridor.clamp(0, 7);
        occupiedMask |= (1 << c);
      }
    }

    // 2. Scrolling 3D Astral Waypoint Buoys along each lane center
    const totalBuoyRows = 6;
    for (var s = 0; s < totalBuoyRows; s++) {
      final u = ((s + phase) / totalBuoyRows).clamp(0.02, 0.98);
      final normZ = math.pow(1.0 - u, 1.35).toDouble() * 1.22 + 0.06;

      // Floating 3D Astral Lane Buoys for each of the 8 corridors (C1..C8)
      for (var c = 0; c < 8; c++) {
        final centerX = (c + 0.5) / 8.0;
        final buoyPt = cam.project(
          size,
          normX: centerX,
          normZ: normZ,
          elevationY: 0.02,
        );
        final pScale = buoyPt.perspectiveScale;
        final isActive = c == activeCorridor;
        final isOccupied = (occupiedMask & (1 << c)) != 0;
        final isMill = millTriadBays.contains(c + 8);

        if (isActive) {
          // Active Defender corridor: forward-flowing 3D holographic chevrons (▲)
          final chevTip = cam.project(
            size,
            normX: centerX,
            normZ: math.min(1.35, normZ + 0.045),
            elevationY: 0.02,
          );
          final halfW = (size.width * 0.96 / 8.0) * 0.22 * pScale;
          _scratchReticlePath
            ..reset()
            ..moveTo(
              buoyPt.screenOffset.dx - halfW,
              buoyPt.screenOffset.dy + 2.0 * pScale,
            )
            ..lineTo(chevTip.screenOffset.dx, chevTip.screenOffset.dy)
            ..lineTo(
              buoyPt.screenOffset.dx + halfW,
              buoyPt.screenOffset.dy + 2.0 * pScale,
            );
          _scrollPylonPaint
            ..color =
                (normForward > 0.15
                        ? VoidTheme.solarGoldLight
                        : VoidTheme.plasmaCyan)
                    .withValues(alpha: (u * 0.65 + 0.18).clamp(0.18, 0.78))
            ..strokeWidth = (1.8 * pScale).clamp(0.9, 2.2);
          canvas.drawPath(_scratchReticlePath, _scrollPylonPaint);
        } else {
          // Diegetic 3D diamond/pearl astral buoy marking lane center without lines
          final Color buoyColor;
          final double buoyAlpha;
          final double r;
          if (isOccupied) {
            buoyColor = VoidTheme.crimsonFlare;
            buoyAlpha = (u * 0.55 + 0.20).clamp(0.20, 0.72);
            r = (3.0 * pScale).clamp(1.4, 3.4);
          } else if (isMill) {
            buoyColor = VoidTheme.solarGold;
            buoyAlpha = (u * 0.55 + 0.22).clamp(0.22, 0.75);
            r = (3.0 * pScale).clamp(1.4, 3.4);
          } else {
            buoyColor = VoidTheme.plasmaCyan;
            buoyAlpha = (u * 0.20 + 0.06).clamp(0.06, 0.24);
            r = (1.9 * pScale).clamp(1.0, 2.2);
          }
          _scrollSleeperPaint.color = buoyColor.withValues(alpha: buoyAlpha);
          canvas.drawCircle(buoyPt.screenOffset, r, _scrollSleeperPaint);
        }
      }
    }
  }

  /// Renders discoverable 3D space anomalies (Plasma Core Caches, Ancient Bao
  /// Relics, and Ion Nebula Surges) drifting through 3D space.
  void _drawSpaceAnomalies3D(Canvas canvas, Size size, CombatCamera3D cam) {
    for (var i = 0; i < anomalies.length; i++) {
      final anomaly = anomalies[i];
      if (!anomaly.active) continue;

      final normX = anomaly.normX.clamp(0.04, 0.96);
      final normZ = anomaly.normZ.clamp(0.0, 1.0);
      final bobElev =
          anomaly.elevationY +
          0.022 * math.sin(animationTime * 3.2 + anomaly.id);
      final proj = cam.project(
        size,
        normX: normX,
        normZ: normZ,
        elevationY: bobElev,
      );
      final pScale = proj.perspectiveScale;
      final cx = proj.screenOffset.dx;
      final cy = proj.screenOffset.dy;

      final Color primaryColor;
      final Color coreColor;
      switch (anomaly.type) {
        case SpaceAnomalyType.coreCache:
          primaryColor = VoidTheme.solarGold;
          coreColor = VoidTheme.solarGoldLight;
        case SpaceAnomalyType.ancientRelic:
          primaryColor = const Color(0xFFA855F7);
          coreColor = const Color(0xFFE9D5FF);
        case SpaceAnomalyType.ionNebulaSurge:
          primaryColor = VoidTheme.plasmaCyan;
          coreColor = Colors.white;
      }

      // 1. Subtle 3D ground projection tether & ring
      final groundW = 22.0 * pScale;
      final groundH = 7.5 * pScale;
      _scrollPylonPaint
        ..color = primaryColor.withValues(alpha: 0.32)
        ..strokeWidth = 1.0;
      canvas.drawOval(
        Rect.fromCenter(
          center: proj.groundOffset,
          width: groundW,
          height: groundH,
        ),
        _scrollPylonPaint,
      );
      canvas.drawLine(proj.groundOffset, proj.screenOffset, _scrollPylonPaint);

      // 2. Rotating 3D orbital energy ring around the anomaly crystal
      final radius = (15.0 * pScale).clamp(7.0, 19.0);
      final spin = anomaly.rotationRad + animationTime * 1.8;
      canvas.save();
      canvas.translate(cx, cy);
      canvas.rotate(math.sin(spin) * 0.42);
      _scrollPylonPaint
        ..color = primaryColor.withValues(alpha: 0.72)
        ..strokeWidth = (1.6 * pScale).clamp(0.9, 2.0);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset.zero,
          width: radius * 2.3,
          height: radius * 0.9,
        ),
        _scrollPylonPaint,
      );
      canvas.restore();

      // 3. 3D Octahedral Crystal Facets
      final waistX =
          radius * 0.78 * math.cos(spin * 0.7).abs().clamp(0.35, 1.0);
      _scratchReticlePath
        ..reset()
        ..moveTo(cx, cy - radius)
        ..lineTo(cx + waistX, cy)
        ..lineTo(cx, cy + radius)
        ..lineTo(cx - waistX, cy)
        ..close();
      _scrollSleeperPaint.color = primaryColor.withValues(alpha: 0.45);
      canvas.drawPath(_scratchReticlePath, _scrollSleeperPaint);

      _scrollPylonPaint
        ..color = coreColor.withValues(alpha: 0.92)
        ..strokeWidth = (1.5 * pScale).clamp(0.9, 1.8);
      canvas.drawPath(_scratchReticlePath, _scrollPylonPaint);

      // Internal 3D crystal ridge lines
      canvas.drawLine(
        Offset(cx, cy - radius),
        Offset(cx, cy + radius),
        _scrollPylonPaint,
      );
      _scrollSleeperPaint.color = coreColor;
      canvas.drawCircle(
        Offset(cx, cy),
        (3.4 * pScale).clamp(1.8, 4.4),
        _scrollSleeperPaint,
      );
    }
  }

  /// Converts simulation `worldPosY` (`1.0` = far horizon spawn, `0.15` = near threshold)
  /// or pixel Y into normalized 3D trench depth `normZ` (`1.0` = top Warp Gate, `0.0` = bottom Defense Line).
  static double _worldYToTrenchNormZ(
    double worldPosY,
    double topMargin,
    double boundaryY,
  ) {
    if (worldPosY <= 1.5) {
      return ((worldPosY - 0.15) / 0.85).clamp(0.0, 1.05);
    }
    return ((boundaryY - worldPosY) / math.max(boundaryY - topMargin, 1.0))
        .clamp(0.0, 1.05);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final topMargin = size.height * 0.06;
    final boundaryY = size.height - 18.0;

    final dreadNormX =
        (dreadnought.orbitalPositionX > 0.0 &&
            dreadnought.orbitalPositionX <= 1.0)
        ? dreadnought.orbitalPositionX
        : 0.4375;
    final cam = camera;

    final forwardDepth =
        (dreadnought.orbitalPositionY - dreadnought.boundaryLineY).clamp(
          0.0,
          0.45,
        );
    final normForward = (forwardDepth / 0.45).clamp(0.0, 1.0);
    // Keep the 3D Defender anchored in the bottom Defense Perimeter zone (normZ = 0.02..0.14)
    // so enemies ALWAYS descend from the top Warp Gate (normZ = 1.0) toward the Defender.
    final dreadNormZ = 0.02 + normForward * 0.12;
    final dreadElevation = 0.12 + normForward * 0.08;
    final activeCorridor = (dreadNormX * 8.0).floor().clamp(0, 7);

    // -1. Render Floating 3D Astral Lane Buoys & Discoverable 3D Space Anomalies
    _drawInfiniteScrollingHighway3D(
      canvas,
      size,
      cam,
      normForward,
      activeCorridor,
    );
    _drawSpaceAnomalies3D(canvas, size, cam);

    final shipProj = cam.project(
      size,
      normX: dreadNormX,
      normZ: dreadNormZ,
      elevationY: dreadElevation,
    );
    final baseLaneWidth = size.width * 0.96 / 8.0;
    final shipScale =
        ((baseLaneWidth * 1.45 / 108.0) * shipProj.perspectiveScale).clamp(
          0.54,
          0.84,
        );
    final shipProwOffset = Offset(
      shipProj.screenOffset.dx,
      shipProj.screenOffset.dy - 36.0 * shipScale,
    );

    // 0. Draw Morabaraba 3-Bay Mill Triad 3D Emitter Dock Resonance Halos
    if (millTriadBays.isNotEmpty) {
      for (final bay in millTriadBays) {
        final c = (bay - 8).clamp(0, 7);
        final dockCenter = cam.project(
          size,
          normX: (c + 0.5) / 8.0,
          normZ: 0.028,
          elevationY: 0.028,
        );
        final haloRect = Rect.fromCenter(
          center: dockCenter.screenOffset,
          width: 38.0,
          height: 15.0,
        );
        canvas.drawOval(haloRect, _millCorridorPaint);
        canvas.drawOval(haloRect, _millBorderPaint);
      }
    }

    // 1. Draw Active Particle Lances in 3D Perspective Space (Muzzle-to-Target!)
    final isMultiBeamBarrage = lances.length > 1;
    for (var i = 0; i < lances.length; i++) {
      final lance = lances[i];
      if (!lance.active) continue;
      final corridor = (lance.firingBayIndex >= 8)
          ? (lance.firingBayIndex - 8)
          : lance.firingBayIndex;
      final laneNormX = (lance.originX > 0.0 && lance.originX <= 1.0)
          ? lance.originX
          : (corridor + 0.5) / 8.0;

      // Find frontmost living enemy in this corridor so the lance visibly impacts the target!
      double? targetEnemyNormZ;
      double targetEnemyElev = dreadElevation;
      for (var eIdx = 0; eIdx < enemies.length; eIdx++) {
        final e = enemies[eIdx];
        if (!e.isDestroyed && e.assignedCorridor == corridor) {
          final ez = _worldYToTrenchNormZ(e.worldPosY, topMargin, boundaryY);
          if (targetEnemyNormZ == null || ez < targetEnemyNormZ) {
            targetEnemyNormZ = ez;
            targetEnemyElev = e.vesselType == 2
                ? 0.28
                : (e.vesselType == 1 ? 0.22 : 0.17);
          }
        }
      }

      final nearLaneProj = cam.project(
        size,
        normX: laneNormX,
        normZ: dreadNormZ,
        elevationY: dreadElevation,
      );
      // Connect single-corridor lance directly to the Defender's Forward Nose Cannon!
      final muzzleOrigin = (!isMultiBeamBarrage)
          ? shipProwOffset
          : nearLaneProj.screenOffset;

      // Draw Power Feed from bottom C1..C8 Dock Pad (normZ = 0.0) into the firing turret
      final dockPadProj = cam.project(
        size,
        normX: (corridor + 0.5) / 8.0,
        normZ: 0.0,
      );
      canvas.drawLine(
        dockPadProj.groundOffset,
        muzzleOrigin,
        _powerFeedGlowPaint,
      );
      canvas.drawLine(
        dockPadProj.groundOffset,
        muzzleOrigin,
        _powerFeedCorePaint,
      );
      if (isMultiBeamBarrage) {
        // Connect Defender Prow to flanking Morabaraba Triad beams
        canvas.drawLine(shipProwOffset, muzzleOrigin, _powerFeedGlowPaint);
        canvas.drawLine(shipProwOffset, muzzleOrigin, _powerFeedCorePaint);
      }

      final farBeam = cam.project(
        size,
        normX: laneNormX,
        normZ: 1.0,
        elevationY: targetEnemyElev,
      );
      final impactZ =
          (targetEnemyNormZ != null && targetEnemyNormZ > dreadNormZ)
          ? targetEnemyNormZ
          : 1.0;
      final impactBeam = cam.project(
        size,
        normX: laneNormX,
        normZ: impactZ,
        elevationY: targetEnemyElev,
      );

      final rawWidth = lance.beamWidth <= 1.0
          ? (lance.beamWidth * size.width)
          : lance.beamWidth;
      final beamW = math.max(rawWidth, 16.0);
      final prowW = beamW * 1.40 * nearLaneProj.perspectiveScale;
      final deepSpaceW = beamW * 1.15 * farBeam.perspectiveScale;

      _scratchVolumetricLancePath.reset();
      _scratchVolumetricLancePath.moveTo(
        muzzleOrigin.dx - prowW * 0.5,
        muzzleOrigin.dy,
      );
      _scratchVolumetricLancePath.lineTo(
        farBeam.screenOffset.dx - deepSpaceW * 0.5,
        farBeam.screenOffset.dy,
      );
      _scratchVolumetricLancePath.lineTo(
        farBeam.screenOffset.dx + deepSpaceW * 0.5,
        farBeam.screenOffset.dy,
      );
      _scratchVolumetricLancePath.lineTo(
        muzzleOrigin.dx + prowW * 0.5,
        muzzleOrigin.dy,
      );
      _scratchVolumetricLancePath.close();

      canvas.drawPath(_scratchVolumetricLancePath, _lanceGlowPaint);

      // Primary high-intensity axial laser core from Defender Nose Cannon to Enemy Target
      _lanceCorePaint
        ..color = isMultiBeamBarrage ? VoidTheme.solarGoldLight : Colors.white
        ..strokeWidth = math.max(
          beamW * 0.40 * nearLaneProj.perspectiveScale,
          4.2,
        );
      canvas.drawLine(muzzleOrigin, impactBeam.screenOffset, _lanceCorePaint);

      // Secondary over-penetration beam continuing from target to Warp Horizon
      if (impactZ < 0.99) {
        _lanceCorePaint
          ..color = VoidTheme.plasmaCyan.withValues(alpha: 0.55)
          ..strokeWidth = 2.2;
        canvas.drawLine(
          impactBeam.screenOffset,
          farBeam.screenOffset,
          _lanceCorePaint,
        );
      }

      // Animated Upward-Traveling Plasma Tracer Chevrons from Muzzle to Target
      for (var b = 0; b < 3; b++) {
        final t = ((animationTime * 6.5) + (b / 3.0)) % 1.0;
        final bx =
            muzzleOrigin.dx +
            (impactBeam.screenOffset.dx - muzzleOrigin.dx) * t;
        final by =
            muzzleOrigin.dy +
            (impactBeam.screenOffset.dy - muzzleOrigin.dy) * t;
        final cw = (10.0 * (1.0 - t * 0.45)).clamp(4.0, 12.0);
        _scratchReticlePath.reset();
        _scratchReticlePath.moveTo(bx - cw, by + cw * 0.7);
        _scratchReticlePath.lineTo(bx, by - cw * 0.9);
        _scratchReticlePath.lineTo(bx + cw, by + cw * 0.7);
        canvas.drawPath(_scratchReticlePath, _muzzleSpikePaint);
      }

      // Muzzle Flare at 3D Defender Nose Cannon Origin
      canvas.drawCircle(
        muzzleOrigin,
        beamW * 1.55 * nearLaneProj.perspectiveScale,
        _muzzleGlowPaint,
      );
      canvas.drawCircle(
        muzzleOrigin,
        beamW * 0.80 * nearLaneProj.perspectiveScale,
        _muzzlePaint,
      );
      canvas.drawLine(
        Offset(
          muzzleOrigin.dx - beamW * 2.2 * nearLaneProj.perspectiveScale,
          muzzleOrigin.dy,
        ),
        Offset(
          muzzleOrigin.dx + beamW * 2.2 * nearLaneProj.perspectiveScale,
          muzzleOrigin.dy,
        ),
        _muzzleSpikePaint,
      );

      // Target Impact Shockwave & Crosshair Flare directly on the Enemy Hit
      final impR = beamW * 1.65 * impactBeam.perspectiveScale;
      canvas.drawCircle(impactBeam.screenOffset, impR * 1.25, _muzzleGlowPaint);
      canvas.drawCircle(impactBeam.screenOffset, impR, _impactPaint);
      canvas.drawLine(
        Offset(
          impactBeam.screenOffset.dx - impR * 1.4,
          impactBeam.screenOffset.dy,
        ),
        Offset(
          impactBeam.screenOffset.dx + impR * 1.4,
          impactBeam.screenOffset.dy,
        ),
        _muzzleSpikePaint,
      );
    }

    // 2. Draw Active Secondary Flak Bursts in 3D Perspective
    for (var i = 0; i < flaks.length; i++) {
      final flak = flaks[i];
      if (!flak.active) continue;
      final progress =
          1.0 - (flak.remainingLifetime / math.max(flak.lifetime, 0.01));
      final rawRadius = flak.blastRadius <= 1.0
          ? (flak.blastRadius * size.width)
          : flak.blastRadius;
      final alpha = (1.0 - progress).clamp(0.0, 1.0);

      final normX = flak.worldPosX <= 1.0
          ? flak.worldPosX
          : (flak.worldPosX / size.width).clamp(0.0, 1.0);
      final normZ = _worldYToTrenchNormZ(flak.worldPosY, topMargin, boundaryY);

      final flakProj = cam.project(
        size,
        normX: normX,
        normZ: normZ,
        elevationY: 0.18,
      );
      final radius = rawRadius * progress * flakProj.perspectiveScale;

      _flakPaint
        ..color = VoidTheme.solarGold.withValues(alpha: alpha * 0.85)
        ..strokeWidth = 3.0 * (1.0 - progress);

      canvas.drawOval(
        Rect.fromCenter(
          center: flakProj.screenOffset,
          width: radius * 2.0,
          height: radius * 1.15,
        ),
        _flakPaint,
      );
    }

    // 3. Draw Solid 3D Enemy Assault Craft in strict Far-to-Near Painter's Order
    var activeEnemyCount = 0;
    for (var i = 0; i < enemies.length && activeEnemyCount < 64; i++) {
      if (!enemies[i].isDestroyed) {
        _enemySortOrder[activeEnemyCount++] = i;
      }
    }
    for (var i = 1; i < activeEnemyCount; i++) {
      final keyIdx = _enemySortOrder[i];
      final keyY = enemies[keyIdx].worldPosY;
      var j = i - 1;
      while (j >= 0 && enemies[_enemySortOrder[j]].worldPosY < keyY) {
        _enemySortOrder[j + 1] = _enemySortOrder[j];
        j--;
      }
      _enemySortOrder[j + 1] = keyIdx;
    }

    for (var s = 0; s < activeEnemyCount; s++) {
      final enemy = enemies[_enemySortOrder[s]];
      final normX = (enemy.worldPosX > 0.0 && enemy.worldPosX <= 1.0)
          ? enemy.worldPosX
          : (enemy.assignedCorridor + 0.5) / 8.0;
      final normZ = _worldYToTrenchNormZ(enemy.worldPosY, topMargin, boundaryY);

      _drawEnemyVessel3D(
        canvas,
        size,
        cam,
        normX: normX,
        normZ: normZ,
        enemy: enemy,
      );
    }

    // 4. Draw Descending Enemy Plasma Bullets in 3D Perspective Corridors
    for (var i = 0; i < enemyBullets.length; i++) {
      _drawEnemyBullet(
        canvas,
        size,
        cam,
        enemyBullets[i],
        topMargin,
        boundaryY,
      );
    }

    // 5. Draw Visual Particles
    for (var i = 0; i < particles.length; i++) {
      final p = particles[i];
      _particlePaint.color = p.color.withValues(alpha: p.alpha);
      canvas.drawCircle(Offset(p.x, p.y), p.radius, _particlePaint);
    }

    // 6. Draw 3D Dreadnought Flagship at the Bottom Defense Perimeter
    _drawDreadnoughtPlatform(canvas, size, cam, boundaryY);

    // 7. Draw Floating Arcade Damage Numbers (Pre-Laid Out Text Painters)
    for (var i = 0; i < damageNumbers.length; i++) {
      final num = damageNumbers[i];
      if (num.remainingLifetime <= 0.0) continue;
      final px = (num.x <= 1.0 && num.x > 0.0) ? num.x * size.width : num.x;
      final py = (num.y <= 1.0 && num.y > 0.0) ? num.y * size.height : num.y;
      if (py < 40.0) continue;
      num.textPainter.paint(
        canvas,
        Offset(px - (num.textPainter.width / 2), py),
      );
    }
  }

  /// Renders a descending enemy plasma projectile projected along its 3D corridor.
  void _drawEnemyBullet(
    Canvas canvas,
    Size size,
    CombatCamera3D cam,
    EnemyBullet bullet,
    double topMargin,
    double boundaryY,
  ) {
    final normX = (bullet.assignedCorridor >= 0 && bullet.assignedCorridor < 8)
        ? (bullet.assignedCorridor + 0.5) / 8.0
        : (bullet.x / math.max(size.width, 1.0)).clamp(0.0, 1.0);
    final normZ =
        ((boundaryY - bullet.y) / math.max(boundaryY - topMargin, 1.0)).clamp(
          0.0,
          1.0,
        );
    final proj = cam.project(
      size,
      normX: normX,
      normZ: normZ,
      elevationY: 0.16,
    );

    canvas.save();
    canvas.translate(proj.screenOffset.dx, proj.screenOffset.dy);

    final glowColor = Color(
      (89 << 24) | (bullet.color.toARGB32() & 0x00FFFFFF),
    );
    final r = bullet.radius * (0.65 + 0.45 * proj.perspectiveScale);

    _bulletTailPaint
      ..color = glowColor
      ..strokeWidth = 3.0 * proj.perspectiveScale
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset.zero,
      Offset(0.0, -16.0 * proj.perspectiveScale),
      _bulletTailPaint,
    );

    _bulletGlowPaint.color = glowColor;
    canvas.drawCircle(Offset.zero, r * 1.8, _bulletGlowPaint);

    _bulletOrbPaint.color = bullet.color;
    canvas.drawCircle(Offset.zero, r, _bulletOrbPaint);

    canvas.drawCircle(Offset.zero, r * 0.45, _bulletCenterPaint);

    canvas.restore();
  }

  /// Renders a solid 3D enemy assault craft in true 3D perspective using [Invader3DMesh],
  /// scaled strictly to fit within its 3D corridor width at depth [normZ].
  void _drawEnemyVessel3D(
    Canvas canvas,
    Size size,
    CombatCamera3D cam, {
    required double normX,
    required double normZ,
    required EnemyCraft enemy,
  }) {
    // 3D flight altitude above the orbital trench floor
    final baseElevation = enemy.vesselType == 2
        ? 0.22
        : (enemy.vesselType == 1 ? 0.18 : 0.14);
    final hoverBob = 0.018 * math.sin(animationTime * 2.8 + enemy.entityId);
    final elevationY = baseElevation + hoverBob;

    final proj = cam.project(
      size,
      normX: normX,
      normZ: normZ,
      elevationY: elevationY,
    );
    final x = proj.screenOffset.dx;
    final y = proj.screenOffset.dy;
    final gx = proj.groundOffset.dx;
    final gy = proj.groundOffset.dy;
    final pScale = proj.perspectiveScale;

    if (y < -60.0 || y > size.height + 40.0) return;

    // Scale enemy proportional to the wide-field 3D lane at its depth Z
    // so every enemy is crisp and proportional without overcrowding.
    final corridorSpanW = (size.width * 0.96 / 8.0) * pScale;
    final double meshScale;
    if (enemy.vesselType == 2) {
      // Flagship model width = 84 units
      meshScale = (corridorSpanW * 0.72 / 84.0).clamp(0.16, 0.56);
    } else if (enemy.vesselType == 1) {
      // Cruiser model width = 62 units
      meshScale = (corridorSpanW * 0.60 / 62.0).clamp(0.16, 0.50);
    } else {
      // Drone model width = 42 units
      meshScale = (corridorSpanW * 0.48 / 42.0).clamp(0.16, 0.46);
    }
    final warpProgress = enemy.warpInProgress.clamp(0.0, 1.0);

    // 1. 3D Ground Shadow Ring & Swaying Vector Chevron on Orbital Plane
    final shadowW = (corridorSpanW * 0.46).clamp(8.0, 28.0);
    final shadowH = shadowW * 0.34 * math.sin(cam.pitchRad).clamp(0.28, 0.85);
    final shadowRect = Rect.fromCenter(
      center: Offset(gx, gy),
      width: shadowW,
      height: shadowH,
    );
    canvas.drawOval(shadowRect, _enemyShadowFillPaint);

    final accentColor = enemy.vesselType == 2
        ? VoidTheme.crimsonFlare
        : (enemy.vesselType == 1
              ? VoidTheme.plasmaCyan
              : VoidTheme.nebulaAmethystLight);
    _enemyShadowRingPaint.color = accentColor.withValues(
      alpha: 0.52 * warpProgress,
    );
    canvas.drawOval(shadowRect, _enemyShadowRingPaint);

    // Forward/lateral attack vector chevron on the orbital plane ahead of the swaying enemy
    final swayLeadDx = (-enemy.bankAngleRad * 0.045).clamp(-0.035, 0.035);
    final leadProj = cam.project(
      size,
      normX: (normX + swayLeadDx).clamp(0.02, 0.98),
      normZ: (normZ - 0.045).clamp(0.0, 1.0),
    );
    final chevW = 5.0 * pScale;
    _scratchReticlePath.reset();
    _scratchReticlePath.moveTo(
      leadProj.groundOffset.dx - chevW,
      leadProj.groundOffset.dy - 3.2 * pScale,
    );
    _scratchReticlePath.lineTo(
      leadProj.groundOffset.dx,
      leadProj.groundOffset.dy + 2.4 * pScale,
    );
    _scratchReticlePath.lineTo(
      leadProj.groundOffset.dx + chevW,
      leadProj.groundOffset.dy - 3.2 * pScale,
    );
    canvas.drawPath(_scratchReticlePath, _enemyShadowRingPaint);

    // Vertical 3D altitude tether connecting floor shadow to 3D ship hull
    _anchorTetherPaint.color = accentColor.withValues(
      alpha: 0.28 * warpProgress,
    );
    canvas.drawLine(
      Offset(gx, gy),
      Offset(x, y + 6.0 * meshScale),
      _anchorTetherPaint,
    );

    // 2. Collapsing Warp Singularity Ring (if vessel is still warping in)
    if (warpProgress < 0.95) {
      final invProgress = (1.0 - warpProgress).clamp(0.0, 1.0);
      final ringRadius = (28.0 * meshScale) * (0.25 + 0.75 * invProgress);
      _warpSingularityPaint
        ..color = VoidTheme.plasmaCyan.withValues(alpha: invProgress * 0.8)
        ..strokeWidth = 1.8 * pScale;
      canvas.drawCircle(Offset(x, y), ringRadius, _warpSingularityPaint);
    }

    // 3. Render Solid 3D Gouraud-Shaded Ship Model with pronounced 3D corridor-swaying roll & yaw
    final swayBank = (enemy.bankAngleRad * 1.15).clamp(-0.65, 0.65);
    final effectivePitch =
        enemy.pitchAngleRad +
        cam.meshPitchBiasRad +
        0.10 * math.cos(animationTime * 2.0 + enemy.entityId);
    final effectiveRoll =
        swayBank +
        cam.yawRad * 0.35 +
        0.14 * math.sin(animationTime * 1.9 + enemy.entityId);
    final effectiveYaw =
        cam.meshYawBiasRad -
        swayBank * 0.42 +
        0.10 * math.sin(animationTime * 1.8 + enemy.entityId);

    _invaderMesh.projectAndPaint(
      canvas,
      center: Offset(x, y),
      vesselType: enemy.vesselType,
      pitchRad: effectivePitch,
      rollRad: effectiveRoll,
      yawRad: effectiveYaw,
      scale: meshScale,
      warpInProgress: warpProgress,
      animationTime: animationTime,
      isLowBattery: isLowBattery,
    );

    // 4. Render Segmented Boss Shield Arc for Flagships (vesselType == 2)
    final hh = 22.0 * meshScale;
    if (enemy.vesselType == 2 && enemy.currentShields > 0) {
      final shieldRatio = (enemy.currentShields / math.max(enemy.maxShields, 1))
          .clamp(0.0, 1.0);
      _shieldGlowPaint.color = VoidTheme.plasmaCyan.withValues(
        alpha: 0.28 * shieldRatio,
      );
      _shieldArcPaint.color = VoidTheme.plasmaCyan.withValues(
        alpha: 0.88 * shieldRatio,
      );
      for (var seg = -1; seg <= 1; seg++) {
        final segX = x + seg * (corridorSpanW * 0.28);
        final segY = y + hh * 0.45;
        final segRect = Rect.fromCenter(
          center: Offset(segX, segY),
          width: corridorSpanW * 0.26,
          height: hh * 0.85,
        );
        canvas.drawArc(
          segRect,
          0.15 * math.pi,
          0.70 * math.pi,
          false,
          _shieldGlowPaint,
        );
        canvas.drawArc(
          segRect,
          0.15 * math.pi,
          0.70 * math.pi,
          false,
          _shieldArcPaint,
        );
      }
    }

    // 5. Health / Shield Gauges & Live Corridor Lock Badge ([C1]..[C8]) above 3D Hull
    final barW = (corridorSpanW * 0.56).clamp(11.0, 32.0);
    const barH = 2.8;
    final barY = y - hh - 7.5;
    final barLeft = x - barW / 2;

    final hullFraction = (enemy.currentHull / math.max(enemy.maxHull, 1.0))
        .clamp(0.0, 1.0);
    _scratchBarPath.reset();
    _scratchBarPath.moveTo(barLeft, barY);
    _scratchBarPath.lineTo(barLeft + barW, barY);
    _scratchBarPath.lineTo(barLeft + barW, barY + barH);
    _scratchBarPath.lineTo(barLeft, barY + barH);
    _scratchBarPath.close();
    canvas.drawPath(_scratchBarPath, _healthBgPaint);

    if (hullFraction > 0.0) {
      _scratchBarPath.reset();
      _scratchBarPath.moveTo(barLeft, barY);
      _scratchBarPath.lineTo(barLeft + barW * hullFraction, barY);
      _scratchBarPath.lineTo(barLeft + barW * hullFraction, barY + barH);
      _scratchBarPath.lineTo(barLeft, barY + barH);
      _scratchBarPath.close();
      canvas.drawPath(_scratchBarPath, _healthHullPaint);
    }

    if (enemy.maxShields > 0) {
      final shieldFraction = (enemy.currentShields / enemy.maxShields).clamp(
        0.0,
        1.0,
      );
      final sBarY = barY - 4.0;
      _scratchBarPath.reset();
      _scratchBarPath.moveTo(barLeft, sBarY);
      _scratchBarPath.lineTo(barLeft + barW, sBarY);
      _scratchBarPath.lineTo(barLeft + barW, sBarY + barH);
      _scratchBarPath.lineTo(barLeft, sBarY + barH);
      _scratchBarPath.close();
      canvas.drawPath(_scratchBarPath, _healthBgPaint);

      if (shieldFraction > 0.0) {
        _scratchBarPath.reset();
        _scratchBarPath.moveTo(barLeft, sBarY);
        _scratchBarPath.lineTo(barLeft + barW * shieldFraction, sBarY);
        _scratchBarPath.lineTo(barLeft + barW * shieldFraction, sBarY + barH);
        _scratchBarPath.lineTo(barLeft, sBarY + barH);
        _scratchBarPath.close();
        canvas.drawPath(_scratchBarPath, _healthShieldPaint);
      }
    }
  }

  /// Renders the 3D flagship dreadnought at the Bottom Defense Perimeter,
  /// soft 3D prow volumetric spotlight cone (without corridor border lines),
  /// power feed tether, and target lock reticles.
  void _drawDreadnoughtPlatform(
    Canvas canvas,
    Size size,
    CombatCamera3D cam,
    double boundaryY,
  ) {
    final topMargin = size.height * 0.06;
    final dreadNormX =
        (dreadnought.orbitalPositionX > 0.0 &&
            dreadnought.orbitalPositionX <= 1.0)
        ? dreadnought.orbitalPositionX
        : 0.4375;

    final forwardDepth =
        (dreadnought.orbitalPositionY - dreadnought.boundaryLineY).clamp(
          0.0,
          0.45,
        );
    final normForward = (forwardDepth / 0.45).clamp(0.0, 1.0);
    final dreadNormZ = 0.02 + normForward * 0.12;
    final dreadElevation = 0.12 + normForward * 0.08;

    final shipProj = cam.project(
      size,
      normX: dreadNormX,
      normZ: dreadNormZ,
      elevationY: dreadElevation,
    );
    final centerX = shipProj.screenOffset.dx;
    final shipY = shipProj.screenOffset.dy;
    final groundX = shipProj.groundOffset.dx;
    final groundY = shipProj.groundOffset.dy;
    final baseLaneWidth = size.width * 0.96 / 8.0;
    final scale = ((baseLaneWidth * 1.32 / 108.0) * shipProj.perspectiveScale)
        .clamp(0.50, 0.78);
    final prowY = shipY - 36.0 * scale;

    // 1. Soft Lineless 3D Prow Sensor Spotlight Cone (no full-screen corridor border lines!)
    final activeCorridor = (dreadNormX * 8.0).floor().clamp(0, 7);
    final activeCenterX = (activeCorridor + 0.5) / 8.0;
    final coneNearL = cam.project(
      size,
      normX: (activeCenterX - 0.025).clamp(0.0, 1.0),
      normZ: dreadNormZ,
    );
    final coneNearR = cam.project(
      size,
      normX: (activeCenterX + 0.025).clamp(0.0, 1.0),
      normZ: dreadNormZ,
    );
    final coneFarL = cam.project(
      size,
      normX: activeCorridor / 8.0,
      normZ: dreadNormZ + 0.34,
    );
    final coneFarR = cam.project(
      size,
      normX: (activeCorridor + 1) / 8.0,
      normZ: dreadNormZ + 0.34,
    );

    _scratchVolumetricLancePath
      ..reset()
      ..moveTo(coneFarL.groundOffset.dx, coneFarL.groundOffset.dy)
      ..lineTo(coneFarR.groundOffset.dx, coneFarR.groundOffset.dy)
      ..lineTo(coneNearR.groundOffset.dx, coneNearR.groundOffset.dy)
      ..lineTo(coneNearL.groundOffset.dx, coneNearL.groundOffset.dy)
      ..close();

    _highlightPaint.color = VoidTheme.plasmaCyan.withValues(alpha: 0.09);
    canvas.drawPath(_scratchVolumetricLancePath, _highlightPaint);

    // Subtle 3D sensor arc at the forward tip of the prow cone
    _corridorBorderPaint.color = VoidTheme.plasmaCyan.withValues(alpha: 0.28);
    canvas.drawLine(
      coneFarL.groundOffset,
      coneFarR.groundOffset,
      _corridorBorderPaint,
    );

    // 2. 3D Lateral Defender Flight Track across the Bottom Defense Perimeter
    final trackLeft = cam.project(size, normX: 0.0, normZ: dreadNormZ);
    final trackRight = cam.project(size, normX: 1.0, normZ: dreadNormZ);
    canvas.drawLine(
      trackLeft.groundOffset,
      trackRight.groundOffset,
      _flightTrackPaint,
    );

    // 3. Glowing Plasma Power Tether from Active Dock Pad to Defender Reactor
    final activeDockPad = cam.project(
      size,
      normX: (activeCorridor + 0.5) / 8.0,
      normZ: 0.0,
    );
    canvas.drawLine(
      activeDockPad.groundOffset,
      Offset(centerX, shipY + 16.0 * scale),
      _powerFeedGlowPaint,
    );
    canvas.drawLine(
      activeDockPad.groundOffset,
      Offset(centerX, shipY + 16.0 * scale),
      _powerFeedCorePaint,
    );

    // 4. 3D Perspective Targeting Laser Sight from Dreadnought Nose Cannon to Nearest Enemy / Horizon
    double aimTargetZ = 1.0;
    double aimTargetElev = dreadElevation;
    for (var i = 0; i < enemies.length; i++) {
      final enemy = enemies[i];
      if (!enemy.isDestroyed && enemy.assignedCorridor == activeCorridor) {
        final ez = _worldYToTrenchNormZ(enemy.worldPosY, topMargin, boundaryY);
        if (ez < aimTargetZ) {
          aimTargetZ = ez;
          aimTargetElev = enemy.vesselType == 2
              ? 0.28
              : (enemy.vesselType == 1 ? 0.22 : 0.17);
        }
      }
    }

    final farAim = cam.project(
      size,
      normX: (activeCorridor + 0.5) / 8.0,
      normZ: aimTargetZ,
      elevationY: aimTargetElev,
    );
    final aimPulse = 0.45 + 0.25 * math.sin(animationTime * 10.0);
    _aimGlowPaint.color = VoidTheme.plasmaCyan.withValues(
      alpha: aimPulse * 0.50,
    );
    canvas.drawLine(Offset(centerX, prowY), farAim.screenOffset, _aimGlowPaint);

    _aimPaint.color = Colors.white.withValues(alpha: aimPulse * 0.92);
    _aimPaint.strokeWidth = 1.8;
    canvas.drawLine(Offset(centerX, prowY), farAim.screenOffset, _aimPaint);

    // 5. Holographic 3D Lock-On Reticles on Enemies in Active Corridor
    for (var i = 0; i < enemies.length; i++) {
      final enemy = enemies[i];
      if (!enemy.isDestroyed && enemy.assignedCorridor == activeCorridor) {
        final eNormX = (enemy.worldPosX > 0.0 && enemy.worldPosX <= 1.0)
            ? enemy.worldPosX
            : (enemy.assignedCorridor + 0.5) / 8.0;
        final eNormZ = _worldYToTrenchNormZ(
          enemy.worldPosY,
          topMargin,
          boundaryY,
        );
        final eElev = enemy.vesselType == 2
            ? 0.28
            : (enemy.vesselType == 1 ? 0.22 : 0.17);
        final eProj = cam.project(
          size,
          normX: eNormX,
          normZ: eNormZ,
          elevationY: eElev,
        );
        final enemyX = eProj.screenOffset.dx;
        final ey = eProj.screenOffset.dy;
        final lockSize =
            (16.0 + 2.0 * math.sin(animationTime * 8.0)) *
            (0.65 + 0.45 * eProj.perspectiveScale);
        final cornerLen = lockSize * 0.45;

        _scratchReticlePath.reset();
        _scratchReticlePath.moveTo(
          enemyX - lockSize + cornerLen,
          ey - lockSize,
        );
        _scratchReticlePath.lineTo(enemyX - lockSize, ey - lockSize);
        _scratchReticlePath.lineTo(
          enemyX - lockSize,
          ey - lockSize + cornerLen,
        );
        _scratchReticlePath.moveTo(
          enemyX + lockSize - cornerLen,
          ey - lockSize,
        );
        _scratchReticlePath.lineTo(enemyX + lockSize, ey - lockSize);
        _scratchReticlePath.lineTo(
          enemyX + lockSize,
          ey - lockSize + cornerLen,
        );
        _scratchReticlePath.moveTo(
          enemyX - lockSize + cornerLen,
          ey + lockSize,
        );
        _scratchReticlePath.lineTo(enemyX - lockSize, ey + lockSize);
        _scratchReticlePath.lineTo(
          enemyX - lockSize,
          ey + lockSize - cornerLen,
        );
        _scratchReticlePath.moveTo(
          enemyX + lockSize - cornerLen,
          ey + lockSize,
        );
        _scratchReticlePath.lineTo(enemyX + lockSize, ey + lockSize);
        _scratchReticlePath.lineTo(
          enemyX + lockSize,
          ey + lockSize - cornerLen,
        );
        canvas.drawPath(_scratchReticlePath, _lockPaint);

        _scratchReticlePath.reset();
        _scratchReticlePath.moveTo(enemyX - 3.5, ey);
        _scratchReticlePath.lineTo(enemyX + 3.5, ey);
        _scratchReticlePath.moveTo(enemyX, ey - 3.5);
        _scratchReticlePath.lineTo(enemyX, ey + 3.5);
        canvas.drawPath(_scratchReticlePath, _lockCrosshairPaint);

        final dmgValue = (predictedDamage != null && predictedDamage! > 0)
            ? predictedDamage!.toInt()
            : 16;
        final tagPainter = _getDamageTagPainter(dmgValue);

        final tagWidth = tagPainter.width + 10.0;
        const tagHeight = 18.0;
        final tagX = (enemyX + lockSize + 4.0 + tagWidth > size.width)
            ? enemyX - lockSize - 4.0 - tagWidth
            : enemyX + lockSize + 4.0;
        final tagY = ey - tagHeight * 0.5;

        final tagRRect = RRect.fromLTRBR(
          tagX,
          tagY,
          tagX + tagWidth,
          tagY + tagHeight,
          const Radius.circular(4.0),
        );
        canvas.drawRRect(tagRRect, _damageTagBgPaint);
        canvas.drawRRect(tagRRect, _damageTagBorderPaint);

        tagPainter.paint(
          canvas,
          Offset(tagX + 5.0, tagY + (tagHeight - tagPainter.height) * 0.5),
        );
      }
    }

    // 6. 3D Ground Projection Anchor Ring & Vertical Altitude Tether on Trench Floor
    final anchorW = 54.0 * shipProj.perspectiveScale;
    final anchorH =
        18.0 *
        shipProj.perspectiveScale *
        math.sin(cam.pitchRad).clamp(0.28, 0.85);
    final anchorRect = Rect.fromLTWH(
      groundX - anchorW * 0.5,
      groundY - anchorH * 0.5,
      anchorW,
      anchorH,
    );
    canvas.drawOval(anchorRect, _anchorRingPaint);

    final tetherAlpha = (0.32 + 0.35 * normForward).clamp(0.0, 0.70);
    _anchorTetherPaint.color = VoidTheme.plasmaCyan.withValues(
      alpha: tetherAlpha,
    );
    canvas.drawLine(
      Offset(groundX, groundY),
      Offset(centerX, shipY + 14.0 * scale),
      _anchorTetherPaint,
    );

    // Lateral Steering Chevrons (◄ ►) flanking the Defender so control is obvious
    final chevOffset = 52.0 * scale;
    final chevH = 7.0 * scale;
    _scratchReticlePath.reset();
    // Port (left) steering chevron ◄
    _scratchReticlePath.moveTo(centerX - chevOffset + 6.0, shipY - chevH);
    _scratchReticlePath.lineTo(centerX - chevOffset, shipY);
    _scratchReticlePath.lineTo(centerX - chevOffset + 6.0, shipY + chevH);
    // Starboard (right) steering chevron ►
    _scratchReticlePath.moveTo(centerX + chevOffset - 6.0, shipY - chevH);
    _scratchReticlePath.lineTo(centerX + chevOffset, shipY);
    _scratchReticlePath.lineTo(centerX + chevOffset - 6.0, shipY + chevH);
    canvas.drawPath(_scratchReticlePath, _steerChevronPaint);

    // 7. 3D Spatial Attitude Angles & Perspective Dreadnought Mesh Projection
    final lateralDisplacement =
        (dreadnought.targetPositionX - dreadnought.orbitalPositionX).clamp(
          -0.25,
          0.25,
        );
    final rollRad =
        lateralDisplacement * 24.0 * (math.pi / 180.0) - cam.yawRad * 0.38;
    final pitchRad = -normForward * 0.26 - cam.meshPitchBiasRad * 0.72;
    final yawRad = lateralDisplacement * 0.14 + cam.meshYawBiasRad * 0.65;

    _dreadMesh.projectAndPaint(
      canvas,
      center: Offset(centerX, shipY),
      pitchRad: pitchRad,
      rollRad: rollRad,
      yawRad: yawRad,
      scale: scale,
      animationTime: animationTime,
      isLowBattery: isLowBattery,
    );

    // 8. 3D Aligned Twin Plasma Engine Exhaust Flames
    final thrustScale = (1.0 + 1.2 * normForward) * scale;
    final flameHeight =
        (20.0 + math.sin(animationTime * 20.0) * 5.0) * thrustScale;
    final leftBellX = _dreadMesh.projX[Dreadnought3DMesh.vPortEngineBell];
    final leftBellY = _dreadMesh.projY[Dreadnought3DMesh.vPortEngineBell];
    final rightBellX = _dreadMesh.projX[Dreadnought3DMesh.vStbdEngineBell];
    final rightBellY = _dreadMesh.projY[Dreadnought3DMesh.vStbdEngineBell];

    _scratchLeftFlamePath.reset();
    _scratchLeftFlamePath.moveTo(leftBellX - 5.0 * scale, leftBellY);
    _scratchLeftFlamePath.lineTo(leftBellX, leftBellY + flameHeight);
    _scratchLeftFlamePath.lineTo(leftBellX + 5.0 * scale, leftBellY);
    _scratchLeftFlamePath.close();
    canvas.drawPath(_scratchLeftFlamePath, _flamePaint);

    _scratchRightFlamePath.reset();
    _scratchRightFlamePath.moveTo(rightBellX - 5.0 * scale, rightBellY);
    _scratchRightFlamePath.lineTo(rightBellX, rightBellY + flameHeight);
    _scratchRightFlamePath.lineTo(rightBellX + 5.0 * scale, rightBellY);
    _scratchRightFlamePath.close();
    canvas.drawPath(_scratchRightFlamePath, _flamePaint);

    // 9. Trailing Ion Contrails during deep space forward flight
    if (normForward > 0.05) {
      final contrailLen = (25.0 + 35.0 * normForward) * scale;
      final contrailAlpha = (0.2 + 0.5 * normForward).clamp(0.0, 0.7);
      _contrailPaint.color = VoidTheme.plasmaCyan.withValues(
        alpha: contrailAlpha,
      );
      canvas.drawLine(
        Offset(leftBellX, leftBellY + flameHeight * 0.7),
        Offset(leftBellX, leftBellY + flameHeight + contrailLen),
        _contrailPaint,
      );
      canvas.drawLine(
        Offset(rightBellX, rightBellY + flameHeight * 0.7),
        Offset(rightBellX, rightBellY + flameHeight + contrailLen),
        _contrailPaint,
      );
    }

    // 10. Deep Space Energetic Bow Shock Ripple Ahead of 3D Prow
    final prowTipX = _dreadMesh.projX[Dreadnought3DMesh.vProwTip];
    final prowTipY = _dreadMesh.projY[Dreadnought3DMesh.vProwTip];
    if (normForward > 0.06) {
      final shockAlpha = (normForward * 0.85).clamp(0.0, 0.85);
      final shockW =
          104.0 * scale * (1.15 + 0.25 * math.sin(animationTime * 18.0));
      final shockH = 24.0 * scale;
      final shockCenterY = prowTipY - 8.0 * scale;
      _bowShockGlowPaint.color = VoidTheme.plasmaCyan.withValues(
        alpha: shockAlpha * 0.45,
      );
      _bowShockPaint.color = Colors.white.withValues(alpha: shockAlpha * 0.90);
      final shockRect = Rect.fromLTWH(
        prowTipX - shockW * 0.5,
        shockCenterY - shockH * 0.5,
        shockW,
        shockH,
      );
      canvas.drawArc(
        shockRect,
        math.pi * 1.15,
        math.pi * 0.7,
        false,
        _bowShockGlowPaint,
      );
      canvas.drawArc(
        shockRect,
        math.pi * 1.15,
        math.pi * 0.7,
        false,
        _bowShockPaint,
      );
    }

    // 11. Forward Kinetic Energy Canopy Shield Arc
    final shieldW = 104.0 * scale * 1.15;
    final shieldH = 48.0 * scale;
    final shieldCenterY = shipY - 10.0 * scale;
    final shieldRect = Rect.fromLTWH(
      centerX - shieldW * 0.5,
      shieldCenterY - shieldH * 0.5,
      shieldW,
      shieldH,
    );
    canvas.drawArc(
      shieldRect,
      math.pi * 1.15,
      math.pi * 0.7,
      false,
      _shieldGlowPaint,
    );
    canvas.drawArc(
      shieldRect,
      math.pi * 1.15,
      math.pi * 0.7,
      false,
      _shieldArcPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CombatPainter oldDelegate) => true;
}
