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

#ifndef VOID_SOWER_ECS_SYSTEMS_BAO_CASCADE_SYSTEM_H_
#define VOID_SOWER_ECS_SYSTEMS_BAO_CASCADE_SYSTEM_H_

#include <array>
#include <cstdint>
#include <entt/entt.hpp>

#include "../combat_rules.h"
#include "../components.h"
#include "discharge_system.h"
#include "match_lifecycle_system.h"
#include "spatial_grid.h"

namespace void_sower::ecs {

/**
 * @brief Manages core injection validation, ring buffer sowing traversal,
 * cascade relays, and forward trajectory prediction under Bao rules.
 */
class BaoCascadeSystem {
 public:
  BaoCascadeSystem() = default;
  ~BaoCascadeSystem() = default;

  /**
   * @brief Injects a plasma core into the target bay and initiates sowing
   * traversal along the ring buffer.
   */
  bool InjectCore(entt::registry& registry, entt::entity dreadnought_entity,
                  std::array<entt::entity, kTotalBays>& bay_entities,
                  uint8_t target_bay, int8_t direction);

  /**
   * @brief Advances the deterministic 60 Hz simulation FSM.
   */
  void StepFSM(entt::registry& registry, entt::entity dreadnought_entity,
               std::array<entt::entity, kTotalBays>& bay_entities,
               const SpatialGrid& spatial_grid,
               DischargeSystem& discharge_system,
               MatchLifecycleSystem& match_lifecycle_system, float delta_time);

  /**
   * @brief Dry-run forward simulation predicting terminal destination and
   * damage.
   */
  struct PredictionResult {
    uint8_t terminal_bay;
    int8_t terminal_corridor;
    uint32_t final_mass;
    float predicted_damage;
    uint16_t total_cascade_laps;
    bool triggers_lance;
    bool triggers_relay;
  };

  PredictionResult PredictSow(
      const entt::registry& registry,
      const std::array<entt::entity, kTotalBays>& bay_entities,
      const SpatialGrid& spatial_grid, uint8_t start_bay,
      int8_t direction) const;

  /**
   * @brief Sets the active lance alpha multiplier (chassis bonus).
   */
  void SetLanceAlphaMultiplier(float multiplier) {
    lance_alpha_multiplier_ = (multiplier > 0.0f) ? multiplier : 1.0f;
  }

 private:
  float lance_alpha_multiplier_{1.0f};
};

}  // namespace void_sower::ecs

#endif  // VOID_SOWER_ECS_SYSTEMS_BAO_CASCADE_SYSTEM_H_
