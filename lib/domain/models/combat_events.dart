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

import 'package:flutter/material.dart';

/// Sealed base class for discrete domain simulation events.
sealed class CombatSimulationEvent {
  const CombatSimulationEvent();
}

/// Emitted when an upward Particle Lance discharges into a corridor.
class LanceFiredEvent extends CombatSimulationEvent {
  const LanceFiredEvent({
    required this.corridor,
    required this.firingBay,
    required this.damage,
  });

  final int corridor;
  final int firingBay;
  final double damage;
}

/// Emitted when a multi-lap relay flak detonation triggers.
class FlakBurstTriggeredEvent extends CombatSimulationEvent {
  const FlakBurstTriggeredEvent({
    required this.x,
    required this.y,
    required this.radius,
    required this.damage,
  });

  final double x;
  final double y;
  final double radius;
  final double damage;
}

/// Emitted when an enemy bomb strikes the flagship conduit.
class ConduitBreachedEvent extends CombatSimulationEvent {
  const ConduitBreachedEvent({
    required this.corridor,
    required this.hitX,
    required this.hitY,
  });

  final int corridor;
  final double hitX;
  final double hitY;
}

/// Emitted when an enemy bomb penetrates past the flagship into the atmosphere.
class AtmosphericBreachedEvent extends CombatSimulationEvent {
  const AtmosphericBreachedEvent({
    required this.hitX,
    required this.hitY,
    required this.penalty,
  });

  final double hitX;
  final double hitY;
  final int penalty;
}

/// Emitted on each discrete hop of a mancala sowing distribution.
class SowHopStepEvent extends CombatSimulationEvent {
  const SowHopStepEvent({
    required this.bayIndex,
    required this.cascadeDepth,
    required this.remainingUnits,
  });

  final int bayIndex;
  final int cascadeDepth;
  final int remainingUnits;
}

/// Emitted when a core is injected into a bay.
class CoreInjectedEvent extends CombatSimulationEvent {
  const CoreInjectedEvent({required this.bayIndex, required this.direction});

  final int bayIndex;
  final int direction;
}

/// Emitted when a projectile is deflected by a particle lance beam.
class BulletDeflectedEvent extends CombatSimulationEvent {
  const BulletDeflectedEvent({
    required this.x,
    required this.y,
    required this.color,
  });

  final double x;
  final double y;
  final Color color;
}
