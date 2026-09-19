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

import '../models/bay_state.dart';
import '../models/dreadnought_state.dart';
import '../models/enemy_craft.dart';
import '../models/flak_burst.dart';
import '../models/lance_beam.dart';
import '../models/prediction_result.dart';

/// Abstract contract for the Void Sower game simulation engine.
/// Implemented by FfiVoidSowerEngine (C++ native) and MockVoidSowerEngine (Dart).
abstract class IVoidSowerEngine {
  /// Initializes simulation parameters and core allocations.
  void initialize({int startingCores = 32, double boundaryY = 800.0});

  /// Procedurally generates a solvable wave using backward-play program inversion.
  int generateWave({
    int difficulty = 0,
    int randomSeed = 42,
    int coreBudget = 16,
    double initialVelocityY = 15.0,
  });

  /// Injects a plasma core from the central reactor into the chosen bay (namua).
  /// [direction]: +1 for Clockwise (CW), -1 for Counter-Clockwise (CCW).
  int injectCore(int bayIndex, int direction);

  /// Smoothly pans the dreadnought laterally along the orbital horizon.
  void slideDreadnought(double targetX);

  /// Advances the deterministic 60 Hz combat simulation by [deltaTime] seconds.
  void stepSimulation(double deltaTime);

  /// Applies conduit direct hit breach: drains 1 reserve core and discharges active bay.
  void damageConduit(int bayIndex);

  /// Applies atmospheric breach penalty.
  void damageAtmosphere(int penalty);

  /// Grants reserve plasma cores directly to the dreadnought reactor.
  void grantCores(int count);

  /// Computes dry-run predictive targeting telemetry without mutating game state.
  PredictionResult predictSow(int startBay, int direction);

  /// Retrieves current snapshot of all 16 capacitor bays.
  List<BayState> getBays();

  /// Retrieves snapshot of all active enemy assault craft.
  List<EnemyCraft> getEnemies();

  /// Retrieves snapshot of active particle lance beams.
  List<LanceBeam> getLances();

  /// Retrieves snapshot of active secondary flak bursts.
  List<FlakBurst> getFlaks();

  /// Retrieves current dreadnought flagship state and simulation FSM status.
  DreadnoughtState getDreadnoughtState();

  /// Resets the combat field and clears all entities.
  void reset();

  /// Releases native memory allocations and teardowns engine state.
  void dispose();
}
