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

#ifndef VOID_SOWER_ECS_SYSTEMS_DISCHARGE_SYSTEM_H_
#define VOID_SOWER_ECS_SYSTEMS_DISCHARGE_SYSTEM_H_

#include <array>
#include <cstdint>
#include <entt/entt.hpp>

#include "../combat_rules.h"
#include "../components.h"
#include "spatial_grid.h"

namespace void_sower::ecs {

/**
 * @brief Manages particle lance discharges, flak detonations, shield/hull
 * damage resolution, and active visual beam lifetimes.
 */
class DischargeSystem {
 public:
  DischargeSystem() = default;
  ~DischargeSystem() = default;

  /**
   * @brief Discharges concentrated plasma mass from a frontline battery as an
   * upward Particle Lance.
   */
  void ExecuteCrossDischarge(entt::registry& registry,
                             entt::entity dreadnought_entity,
                             std::array<entt::entity, kTotalBays>& bay_entities,
                             const SpatialGrid& spatial_grid,
                             uint8_t firing_bay, uint32_t mass);

  /**
   * @brief Detonates a secondary radial flak burst affecting all combatants
   * within dispersion radius.
   */
  void ExecuteFlakDetonation(entt::registry& registry,
                             entt::entity dreadnought_entity, float pos_x,
                             float pos_y, uint32_t mass);

  /**
   * @brief Advances lifetimes for active Particle Lances and despawns expired
   * beams.
   */
  void ProcessParticleLances(entt::registry& registry, float delta_time);

  /**
   * @brief Advances lifetimes for active Flak Bursts and despawns expired
   * bursts.
   */
  void ProcessFlakBursts(entt::registry& registry, float delta_time);

  /**
   * @brief Pre-allocates static entity pools for particle lances and flak
   * bursts.
   */
  void InitializePool(entt::registry& registry);

  /**
   * @brief Resets all lance and flak slots to inactive without destroying
   * entity handles.
   */
  void Reset(entt::registry& registry);

  bool HasActiveLances(const entt::registry& registry) const;

  /**
   * @brief Sets the active lance alpha multiplier (chassis bonus).
   */
  void SetLanceAlphaMultiplier(float multiplier) {
    lance_alpha_multiplier_ = (multiplier > 0.0f) ? multiplier : 1.0f;
  }

 private:
  std::array<entt::entity, kMaxConcurrentLances> lance_pool_{};
  std::array<entt::entity, kMaxConcurrentFlaks> flak_pool_{};
  float lance_alpha_multiplier_{1.0f};
};

}  // namespace void_sower::ecs

#endif  // VOID_SOWER_ECS_SYSTEMS_DISCHARGE_SYSTEM_H_
