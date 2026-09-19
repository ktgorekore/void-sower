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

#ifndef VOID_SOWER_ECS_SYSTEMS_MOVEMENT_SYSTEM_H_
#define VOID_SOWER_ECS_SYSTEMS_MOVEMENT_SYSTEM_H_

#include <entt/entt.hpp>

namespace void_sower::ecs {

/**
 * @brief Handles spatial movement, spring smoothing, and descent physics for
 * all mobile combatants.
 */
class MovementSystem {
 public:
  MovementSystem() = default;
  ~MovementSystem() = default;

  /**
   * @brief Applies critically damped spring smoothing to the dreadnought's
   * lateral position.
   *
   * @param registry ECS registry containing dreadnought state.
   * @param dreadnought_entity Entity handle for the dreadnought flagship.
   * @param delta_time Elapsed frame time in seconds.
   */
  void UpdateDreadnought(entt::registry& registry,
                         entt::entity dreadnought_entity, float delta_time);

  /**
   * @brief Advances descending enemy assault craft toward the planetary
   * defense line, optionally executing lateral evasive drift maneuvers.
   *
   * @param registry ECS registry containing enemy craft.
   * @param delta_time Elapsed frame time in seconds.
   * @param lateral_drift Whether lateral corridor shifting is active.
   * @param elapsed_time Cumulative combat time for harmonic oscillation.
   */
  void AdvanceEnemies(entt::registry& registry, float delta_time,
                      bool lateral_drift = false, float elapsed_time = 0.0f);
};

}  // namespace void_sower::ecs

#endif  // VOID_SOWER_ECS_SYSTEMS_MOVEMENT_SYSTEM_H_
