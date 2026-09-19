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

/// Formal combat doctrine defining enemy behavior and planetary defense rules.
enum SectorCombatDoctrine {
  /// Sectors 1-9: Classical Bao count-and-capture orbital defense with static corridor alignment.
  standardOrbital,

  /// Sectors 10-18: Invaders engage lateral thrusters, drifting and oscillating across corridors.
  phantomDrift,

  /// Sectors 19-27: Multi-wave reinforcement hordes with Tactical Core Siphon (+1..3 cores per kill).
  voidSwarm,
}
