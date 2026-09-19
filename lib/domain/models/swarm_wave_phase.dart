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

/// State machine phases for the Void Swarm multi-wave reinforcement horde.
enum SwarmWavePhase {
  /// Initial flight of assault craft descending through the atmospheric ceiling.
  initialAssault,

  /// Active reinforcement phase: destroyed invaders drop replacement craft at Y=0.95
  /// and siphon energy cores back to the dreadnought reactor.
  reinforcementWaves,

  /// Reinforcement quota depleted; surviving invaders represent the final defensive barrier.
  finalStand,

  /// All invaders and reinforcement pools neutralized. Planetary orbit secured.
  secured,
}
