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

#ifndef VOID_SOWER_ECS_SYSTEMS_MATCH_LIFECYCLE_SYSTEM_H_
#define VOID_SOWER_ECS_SYSTEMS_MATCH_LIFECYCLE_SYSTEM_H_

#include <array>
#include <cstdint>
#include <entt/entt.hpp>

#include "../combat_rules.h"
#include "../components.h"

namespace void_sower::ecs {

/**
 * @brief Manages match outcome evaluation (Victory/GameOver), atmospheric
 * penalty deductions, and direct conduit EMP breaches.
 */
class MatchLifecycleSystem {
 public:
  MatchLifecycleSystem() = default;
  ~MatchLifecycleSystem() = default;

  /**
   * @brief Evaluates whether victory or defeat conditions have been fulfilled.
   */
  void CheckVictoryLossConditions(
      entt::registry& registry, entt::entity dreadnought_entity,
      const std::array<entt::entity, kTotalBays>& bay_entities);

  /**
   * @brief Applies a direct hit conduit breach: drains 1 reserve core and
   * resets the active corridor bay charge to 0.
   */
  void DamageConduit(entt::registry& registry, entt::entity dreadnought_entity,
                     const std::array<entt::entity, kTotalBays>& bay_entities,
                     uint8_t bay_index);

  /**
   * @brief Applies an atmospheric defense penalty directly to total score.
   */
  void DamageAtmosphere(entt::registry& registry,
                        entt::entity dreadnought_entity, uint32_t penalty);
};

}  // namespace void_sower::ecs

#endif  // VOID_SOWER_ECS_SYSTEMS_MATCH_LIFECYCLE_SYSTEM_H_
