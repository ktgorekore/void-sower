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

#include "movement_system.h"

#include <algorithm>

#include "../components.h"

namespace void_sower::ecs {

void MovementSystem::UpdateDreadnought(entt::registry& registry,
                                       entt::entity dreadnought_entity,
                                       float delta_time) {
  if (dreadnought_entity == entt::null || !registry.valid(dreadnought_entity)) {
    return;
  }

  auto& dread = registry.get<DreadnoughtStateComponent>(dreadnought_entity);
  constexpr float kSmoothFactor = 12.0f;
  dread.orbital_position_x =
      std::clamp(dread.orbital_position_x +
                     (dread.target_position_x - dread.orbital_position_x) *
                         std::min(1.0f, delta_time * kSmoothFactor),
                 0.0f, 1.0f);
  dread.orbital_position_y =
      std::clamp(dread.orbital_position_y +
                     (dread.target_position_y - dread.orbital_position_y) *
                         std::min(1.0f, delta_time * kSmoothFactor),
                 dread.boundary_line_y, 0.65f);

  // Proximity damage multiplier: 1.0 at baseline boundary_line_y (0.15),
  // scaling up to 1.6 at y=0.65.
  const float forward_depth =
      std::max(0.0f, dread.orbital_position_y - dread.boundary_line_y);
  constexpr float kMaxForwardSpan = 0.45f;
  const float norm_forward =
      std::clamp(forward_depth / kMaxForwardSpan, 0.0f, 1.0f);
  dread.proximity_multiplier = 1.0f + 0.6f * norm_forward;
}

void MovementSystem::AdvanceEnemies(entt::registry& registry, float delta_time,
                                    bool lateral_drift, float elapsed_time) {
  auto view = registry.view<EnemyVesselComponent>();
  for (auto entity : view) {
    auto& enemy = view.get<EnemyVesselComponent>(entity);
    if (enemy.is_destroyed != 0) continue;

    enemy.world_pos_y -= enemy.velocity_y * delta_time;

    if (lateral_drift) {
      const float phase = static_cast<float>(enemy.entity_id) * 1.57f;
      const float lateral_velocity =
          std::sin(elapsed_time * 2.8f + phase) * 0.28f;
      enemy.world_pos_x = std::clamp(
          enemy.world_pos_x + lateral_velocity * delta_time, 0.06f, 0.94f);
      enemy.assigned_corridor = static_cast<uint16_t>(
          std::clamp(static_cast<int>(enemy.world_pos_x * 8.0f), 0, 7));
    }
  }
}

}  // namespace void_sower::ecs
