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

#include "discharge_system.h"

#include <absl/log/log.h>

#include <cmath>

#include "../combat_rules.h"
#include "../components.h"

namespace void_sower::ecs {

void DischargeSystem::ExecuteCrossDischarge(
    entt::registry& registry, entt::entity dreadnought_entity,
    std::array<entt::entity, kTotalBays>& bay_entities,
    const SpatialGrid& spatial_grid, uint8_t firing_bay, uint32_t mass) {
  VLOG(6) << "DischargeSystem::ExecuteCrossDischarge: firing_bay="
          << static_cast<int>(firing_bay) << ", mass=" << mass;
  auto& bay = registry.get<BatteryComponent>(bay_entities[firing_bay]);
  bay.charge_units = 0;

  if (dreadnought_entity == entt::null || !registry.valid(dreadnought_entity)) {
    return;
  }

  const auto& dread =
      registry.get<DreadnoughtStateComponent>(dreadnought_entity);

  // Axial alignment: Beam origin is pinned directly to the Dreadnought's prow.
  const float lance_origin_x = dread.orbital_position_x;
  const float lance_origin_y = dread.boundary_line_y;
  const int8_t target_corridor = static_cast<int8_t>(
      std::clamp(static_cast<int>(dread.orbital_position_x *
                                  static_cast<float>(kCorridorCount)),
                 0, kCorridorCount - 1));

  const float damage = ComputeLanceDamage(mass);

  // Spawn ParticleLance entity originating axially from dreadnought prow
  auto lance_entity = registry.create();
  registry.emplace<ParticleLanceComponent>(
      lance_entity, ParticleLanceComponent{
                        .firing_bay_index = firing_bay,
                        .origin_x = lance_origin_x,
                        .origin_y = lance_origin_y,
                        .beam_width = 0.04f + 0.015f * static_cast<float>(mass),
                        .sustained_duration = 0.35f,
                        .remaining_duration = 0.35f,
                        .total_damage = damage,
                        .active = 1,
                    });

  // Raycast through enemies in the Dreadnought's aligned active corridor
  auto occupants = spatial_grid.GetCorridorOccupants(target_corridor);
  if (occupants.empty()) {
    const int8_t bay_corridor = CorridorForFrontlineBay(firing_bay);
    if (bay_corridor >= 0 && bay_corridor != target_corridor) {
      occupants = spatial_grid.GetCorridorOccupants(bay_corridor);
    }
  }
  float remaining_damage = damage;

  for (uint32_t entity_id : occupants) {
    auto enemy_entity = static_cast<entt::entity>(entity_id);
    if (!registry.valid(enemy_entity) ||
        !registry.all_of<EnemyVesselComponent>(enemy_entity)) {
      continue;
    }

    auto& vessel = registry.get<EnemyVesselComponent>(enemy_entity);
    if (vessel.is_destroyed != 0) continue;

    // Apply damage to shields first
    if (vessel.current_shields > 0.0f) {
      if (remaining_damage <= vessel.current_shields) {
        vessel.current_shields -= remaining_damage;
        remaining_damage = 0.0f;
      } else {
        remaining_damage -= vessel.current_shields;
        vessel.current_shields = 0.0f;
      }
    }

    // Apply remaining damage to hull
    if (remaining_damage > 0.0f) {
      if (remaining_damage >= vessel.current_hull) {
        vessel.current_hull = 0.0f;
        vessel.is_destroyed = 1;
        auto& d = registry.get<DreadnoughtStateComponent>(dreadnought_entity);
        d.total_score += 100 * (vessel.vessel_type + 1);
      } else {
        vessel.current_hull -= remaining_damage;
        remaining_damage = 0.0f;
      }
    }

    if (remaining_damage <= 0.0f) {
      break;
    }
  }
}

void DischargeSystem::ExecuteFlakDetonation(entt::registry& registry,
                                            entt::entity dreadnought_entity,
                                            float pos_x, float pos_y,
                                            uint32_t mass) {
  VLOG(6) << "DischargeSystem::ExecuteFlakDetonation: x=" << pos_x
          << ", y=" << pos_y << ", mass=" << mass;
  const float area_damage = ComputeFlakDamage(mass);
  const float blast_radius = 0.15f + 0.02f * static_cast<float>(mass);

  auto flak_entity = registry.create();
  registry.emplace<FlakBurstComponent>(flak_entity,
                                       FlakBurstComponent{
                                           .world_pos_x = pos_x,
                                           .world_pos_y = pos_y,
                                           .blast_radius = blast_radius,
                                           .area_damage = area_damage,
                                           .lifetime = 0.25f,
                                           .remaining_lifetime = 0.25f,
                                           .active = 1,
                                       });

  auto view = registry.view<EnemyVesselComponent>();
  for (auto entity : view) {
    auto& enemy = view.get<EnemyVesselComponent>(entity);
    if (enemy.is_destroyed != 0) continue;

    const float dx = enemy.world_pos_x - pos_x;
    const float dy = enemy.world_pos_y - pos_y;
    const float dist = std::sqrt(dx * dx + dy * dy);

    if (dist <= blast_radius) {
      float dmg = area_damage * (1.0f - (dist / blast_radius));
      if (enemy.current_shields > 0.0f) {
        if (dmg <= enemy.current_shields) {
          enemy.current_shields -= dmg;
          dmg = 0.0f;
        } else {
          dmg -= enemy.current_shields;
          enemy.current_shields = 0.0f;
        }
      }

      if (dmg > 0.0f) {
        if (dmg >= enemy.current_hull) {
          enemy.current_hull = 0.0f;
          enemy.is_destroyed = 1;
          auto& d = registry.get<DreadnoughtStateComponent>(dreadnought_entity);
          d.total_score += 50 * (enemy.vessel_type + 1);
        } else {
          enemy.current_hull -= dmg;
        }
      }
    }
  }
}

void DischargeSystem::ProcessParticleLances(entt::registry& registry,
                                            float delta_time) {
  auto view = registry.view<ParticleLanceComponent>();
  for (auto entity : view) {
    auto& lance = view.get<ParticleLanceComponent>(entity);
    if (lance.active != 0) {
      lance.remaining_duration -= delta_time;
      if (lance.remaining_duration <= 0.0f) {
        lance.active = 0;
        registry.destroy(entity);
      }
    }
  }
}

void DischargeSystem::ProcessFlakBursts(entt::registry& registry,
                                        float delta_time) {
  auto view = registry.view<FlakBurstComponent>();
  for (auto entity : view) {
    auto& flak = view.get<FlakBurstComponent>(entity);
    if (flak.active != 0) {
      flak.remaining_lifetime -= delta_time;
      if (flak.remaining_lifetime <= 0.0f) {
        flak.active = 0;
        registry.destroy(entity);
      }
    }
  }
}

bool DischargeSystem::HasActiveLances(const entt::registry& registry) const {
  auto view = registry.view<ParticleLanceComponent>();
  for (auto entity : view) {
    const auto& lance = view.get<ParticleLanceComponent>(entity);
    if (lance.active != 0) return true;
  }
  return false;
}

}  // namespace void_sower::ecs
