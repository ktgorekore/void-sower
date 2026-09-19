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

/// Single visual particle instance with position, velocity, and lifetime.
class VisualParticle {
  VisualParticle({
    this.x = 0.0,
    this.y = 0.0,
    this.vx = 0.0,
    this.vy = 0.0,
    this.radius = 2.0,
    this.color = Colors.white,
    this.life = 0.0,
    this.maxLife = 1.0,
    this.active = false,
  });

  double x;
  double y;
  double vx;
  double vy;
  double radius;
  Color color;
  double life;
  double maxLife;
  bool active;

  double get progress => life / maxLife;
  double get alpha => (1.0 - progress).clamp(0.0, 1.0);
}

/// Bounded dynamic particle burst service with pre-allocated object pool.
/// Operates with zero runtime heap allocation during active combat.
class ParticleService {
  ParticleService({this.maxParticles = 300}) {
    _pool = List<VisualParticle>.generate(
      maxParticles,
      (_) => VisualParticle(),
      growable: false,
    );
  }

  final int maxParticles;
  late final List<VisualParticle> _pool;
  final List<VisualParticle> _activeList = <VisualParticle>[];
  final math.Random _rng = math.Random(1337);

  List<VisualParticle> get activeParticles => _activeList;

  bool get hasActiveParticles => _activeList.isNotEmpty;

  void spawnFlakBurst(double x, double y, Color color, {int count = 24}) {
    var spawned = 0;
    for (final p in _pool) {
      if (!p.active) {
        final angle = _rng.nextDouble() * 2 * math.pi;
        final speed = 80.0 + (_rng.nextDouble() * 160.0);
        p.x = x;
        p.y = y;
        p.vx = math.cos(angle) * speed;
        p.vy = math.sin(angle) * speed;
        p.radius = 2.0 + (_rng.nextDouble() * 3.5);
        p.color = color;
        p.life = 0.0;
        p.maxLife = 0.3 + (_rng.nextDouble() * 0.4);
        p.active = true;

        spawned++;
        if (spawned >= count) break;
      }
    }
  }

  void spawnLanceSparks(double x, double y, Color color, {int count = 12}) {
    var spawned = 0;
    for (final p in _pool) {
      if (!p.active) {
        final angle = -math.pi / 2 + ((_rng.nextDouble() - 0.5) * 0.6);
        final speed = 120.0 + (_rng.nextDouble() * 180.0);
        p.x = x + ((_rng.nextDouble() - 0.5) * 16.0);
        p.y = y;
        p.vx = math.cos(angle) * speed;
        p.vy = math.sin(angle) * speed;
        p.radius = 1.5 + (_rng.nextDouble() * 2.0);
        p.color = color;
        p.life = 0.0;
        p.maxLife = 0.2 + (_rng.nextDouble() * 0.3);
        p.active = true;

        spawned++;
        if (spawned >= count) break;
      }
    }
  }

  void spawnSowTrail(double x, double y, Color color, {int count = 4}) {
    var spawned = 0;
    for (final p in _pool) {
      if (!p.active) {
        p.x = x + ((_rng.nextDouble() - 0.5) * 10.0);
        p.y = y + ((_rng.nextDouble() - 0.5) * 10.0);
        p.vx = (_rng.nextDouble() - 0.5) * 30.0;
        p.vy = (_rng.nextDouble() - 0.5) * 30.0;
        p.radius = 1.5 + (_rng.nextDouble() * 2.0);
        p.color = color;
        p.life = 0.0;
        p.maxLife = 0.25;
        p.active = true;

        spawned++;
        if (spawned >= count) break;
      }
    }
  }

  void update(double dt) {
    _activeList.clear();
    for (final p in _pool) {
      if (p.active) {
        p.life += dt;
        if (p.life >= p.maxLife) {
          p.active = false;
        } else {
          p.x += p.vx * dt;
          p.y += p.vy * dt;
          _activeList.add(p);
        }
      }
    }
  }

  void clear() {
    for (final p in _pool) {
      p.active = false;
    }
    _activeList.clear();
  }
}
