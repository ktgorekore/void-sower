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

#include "match_lifecycle_system.h"

#include "../components.h"

namespace void_sower::ecs {

void MatchLifecycleSystem::CheckVictoryLossConditions(
    entt::registry& registry, entt::entity dreadnought_entity,
    const std::array<entt::entity, kTotalBays>& bay_entities) {
  if (dreadnought_entity == entt::null || !registry.valid(dreadnought_entity)) {
    return;
  }
  (void)bay_entities;

  auto& dread = registry.get<DreadnoughtStateComponent>(dreadnought_entity);
  if (dread.current_sim_state ==
          static_cast<uint8_t>(SimulationState::Victory) ||
      dread.current_sim_state ==
          static_cast<uint8_t>(SimulationState::GameOver)) {
    return;
  }

  // 1. Defeat check: Enemy breached atmospheric boundary
  auto view = registry.view<EnemyVesselComponent>();
  bool any_alive = false;
  for (auto entity : view) {
    const auto& enemy = view.get<EnemyVesselComponent>(entity);
    if (enemy.is_destroyed == 0) {
      any_alive = true;
      if (enemy.world_pos_y <= dread.boundary_line_y) {
        dread.current_sim_state =
            static_cast<uint8_t>(SimulationState::GameOver);
        return;
      }
    }
  }

  // 2. Victory check: All enemies eliminated
  if (!any_alive && view.begin() != view.end()) {
    dread.current_sim_state = static_cast<uint8_t>(SimulationState::Victory);
    return;
  }

  // 3. Defeat check: Core reserves exhausted, no active lances, and not
  // currently cascading
  if (dread.reserve_cores == 0 && dread.is_cascading == 0 && any_alive) {
    bool has_active_lances = false;
    auto lance_view = registry.view<ParticleLanceComponent>();
    for (auto entity : lance_view) {
      if (lance_view.get<ParticleLanceComponent>(entity).active != 0) {
        has_active_lances = true;
        break;
      }
    }
    if (!has_active_lances) {
      dread.current_sim_state = static_cast<uint8_t>(SimulationState::GameOver);
    }
  }
}

void MatchLifecycleSystem::DamageConduit(
    entt::registry& registry, entt::entity dreadnought_entity,
    const std::array<entt::entity, kTotalBays>& bay_entities,
    uint8_t bay_index) {
  if (dreadnought_entity == entt::null || !registry.valid(dreadnought_entity)) {
    return;
  }

  auto& dread = registry.get<DreadnoughtStateComponent>(dreadnought_entity);
  if (dread.reserve_cores > 0) {
    dread.reserve_cores -= 1;
  }
  if (bay_index < kTotalBays && bay_entities[bay_index] != entt::null &&
      registry.valid(bay_entities[bay_index])) {
    auto& bay = registry.get<BatteryComponent>(bay_entities[bay_index]);
    bay.charge_units = 0;  // EMP discharge: clears accumulated plasma!
  }
  CheckVictoryLossConditions(registry, dreadnought_entity, bay_entities);
}

void MatchLifecycleSystem::DamageAtmosphere(entt::registry& registry,
                                            entt::entity dreadnought_entity,
                                            uint32_t penalty) {
  if (dreadnought_entity == entt::null || !registry.valid(dreadnought_entity)) {
    return;
  }

  auto& dread = registry.get<DreadnoughtStateComponent>(dreadnought_entity);
  if (dread.total_score >= penalty) {
    dread.total_score -= penalty;
  } else {
    dread.total_score = 0;
  }
}

}  // namespace void_sower::ecs
