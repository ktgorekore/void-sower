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

#include <cmath>
#include <cstdint>
#include <entt/entt.hpp>

#include "../components.h"
#include "absl/types/span.h"
#include "ring_buffer.h"
#include "spatial_grid.h"

namespace void_sower::ecs {

/**
 * @brief Computes quadratic particle lance damage from concentrated mass: D(M)
 * = alpha * M^2.
 */
inline float ComputeLanceDamage(uint32_t mass,
                                float alpha = kAlphaLanceDamage) {
  return alpha * static_cast<float>(mass * mass);
}

/**
 * @brief Computes secondary flak burst damage from combined relay mass: D_flak
 * = beta * sqrt(M').
 */
inline float ComputeFlakDamage(uint32_t mass, float beta = kBetaFlakDamage) {
  return beta * std::sqrt(static_cast<float>(mass));
}

/**
 * @brief Executes combat simulation, FSM updates, and damage calculations.
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
  struct PredictionResult {
    uint8_t terminal_bay;
    int8_t terminal_corridor;  ///< 0..7 if frontline, -1 if inner reservoir.
    uint32_t final_mass;
    float predicted_damage;
    uint16_t total_cascade_laps;
    bool triggers_lance;
    bool triggers_relay;
  };
  PredictionResult PredictSow(uint8_t start_bay, int8_t direction) const;

  /// Updates dreadnought horizontal target position.
  void SetTargetPositionX(float target_x);

  /// Returns the current simulation state.
  SimulationState GetSimulationState() const;

  /// Returns spatial grid.
  const SpatialGrid& GetSpatialGrid() const { return spatial_grid_; }

 private:
  void StepFSM(float delta_time);
  void AdvanceEnemies(float delta_time);
  void RebuildSpatialGrid();
  void ExecuteCrossDischarge(uint8_t firing_bay, uint32_t mass);
  void ExecuteFlakDetonation(float pos_x, float pos_y, uint32_t mass);
  void ProcessParticleLances(float delta_time);
  void ProcessFlakBursts(float delta_time);
  void CheckVictoryLossConditions();

  entt::registry& registry_;
  SpatialGrid spatial_grid_;
  entt::entity dreadnought_entity_{entt::null};
  std::array<entt::entity, kTotalBays> bay_entities_{};
};

}  // namespace void_sower::ecs

#endif  // VOID_SOWER_ECS_SYSTEMS_COMBAT_SYSTEM_H_
