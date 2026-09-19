/*
 * Copyright 2026 Void Sower Authors.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#ifndef VOID_SOWER_ECS_SYSTEMS_COMBAT_SYSTEM_H_
#define VOID_SOWER_ECS_SYSTEMS_COMBAT_SYSTEM_H_

#include <array>
#include <cmath>
#include <cstdint>
#include <entt/entt.hpp>

#include "../combat_rules.h"
#include "../components.h"
#include "absl/types/span.h"
#include "bao_cascade_system.h"
#include "discharge_system.h"
#include "match_lifecycle_system.h"
#include "movement_system.h"
#include "ring_buffer.h"
#include "spatial_grid.h"

namespace void_sower::ecs {

/**
 * @brief Coordinates the primary 60 Hz combat loop, composing movement,
 * cascading, discharge, and lifecycle subsystems.
 */
class CombatSystem {
 public:
  explicit CombatSystem(entt::registry& registry);
  ~CombatSystem() = default;

  /// Initializes the 16 dreadnought capacitor bays and global state.
  void InitializeDreadnought(uint32_t starting_cores = 24,
                             float boundary_y = 0.2f);

  /// Injects a plasma core from the reactor into target bay and begins
  /// traversal.
  bool InjectCore(uint8_t target_bay, int8_t direction);

  /// Steps the 60 Hz simulation loop by delta_time.
  void Update(float delta_time);

  /// Performs an instantaneous dry-run forward simulation of injecting a core
  /// to predict damage/corridor.
  using PredictionResult = BaoCascadeSystem::PredictionResult;
  PredictionResult PredictSow(uint8_t start_bay, int8_t direction) const;

  /// Updates dreadnought horizontal target position.
  void SetTargetPositionX(float target_x);

  /// Applies conduit direct hit breach: drains 1 reserve core and discharges
  /// active bay.
  void DamageConduit(uint8_t bay_index);

  /// Applies atmospheric breach penalty.
  void DamageAtmosphere(uint32_t penalty);

  /// Grants reserve energy cores to the dreadnought reactor.
  void GrantCores(uint32_t count);

  /// Returns the current simulation state.
  SimulationState GetSimulationState() const;

  /// Returns spatial grid.
  const SpatialGrid& GetSpatialGrid() const { return spatial_grid_; }

  /// Rebuilds spatial grid indexing enemy vessels by corridor.
  void RebuildSpatialGrid();

 private:
  entt::registry& registry_;
  SpatialGrid spatial_grid_;
  MovementSystem movement_system_;
  DischargeSystem discharge_system_;
  MatchLifecycleSystem match_lifecycle_system_;
  BaoCascadeSystem bao_cascade_system_;
  entt::entity dreadnought_entity_{entt::null};
  std::array<entt::entity, kTotalBays> bay_entities_{};
};

}  // namespace void_sower::ecs

#endif  // VOID_SOWER_ECS_SYSTEMS_COMBAT_SYSTEM_H_
