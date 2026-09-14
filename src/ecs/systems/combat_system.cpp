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

#include "combat_system.h"

#include <absl/log/log.h>

#include <algorithm>
#include <cmath>

namespace void_sower::ecs {

CombatSystem::CombatSystem(entt::registry& registry) : registry_(registry) {}

void CombatSystem::InitializeDreadnought(uint32_t starting_cores,
                                         float boundary_y) {
  VLOG(6) << "CombatSystem::InitializeDreadnought: starting_cores="
          << starting_cores << ", boundary_y=" << boundary_y;
  // Create or retrieve Dreadnought singleton entity
  if (dreadnought_entity_ == entt::null ||
      !registry_.valid(dreadnought_entity_)) {
    dreadnought_entity_ = registry_.create();
  }

  registry_.emplace_or_replace<DreadnoughtStateComponent>(
      dreadnought_entity_, DreadnoughtStateComponent{
                               .orbital_position_x = 0.5f,
                               .target_position_x = 0.5f,
                               .reserve_cores = starting_cores,
                               .boundary_line_y = boundary_y,
                               .is_cascading = 0,
                               .total_score = 0,
                               .current_sim_state = static_cast<uint8_t>(
                                   SimulationState::OrbitalIdle),
                               .cores_used = 0,
                           });

  // Initialize the 16 plasma capacitor bays
  for (uint8_t i = 0; i < kTotalBays; ++i) {
    if (bay_entities_[i] == entt::null || !registry_.valid(bay_entities_[i])) {
      bay_entities_[i] = registry_.create();
    }

    const bool is_frontline = IsFrontlineBay(i);
    const uint8_t tier = is_frontline ? 1 : 0;
    const uint16_t grid_col = is_frontline ? static_cast<uint16_t>(i - 8) : 0;
    const float angle_rad =
        (static_cast<float>(i) / static_cast<float>(kTotalBays)) * 2.0f *
        3.14159265f;

    registry_.emplace_or_replace<BatteryComponent>(
        bay_entities_[i],
        BatteryComponent{
            .bay_index = i,
            .tier = tier,
            .grid_column = grid_col,
            .charge_units = 0,
            .radial_position_rad = angle_rad,
            .is_frontline = static_cast<uint8_t>(is_frontline ? 1 : 0),
            .is_nyumba = static_cast<uint8_t>(IsNyumbaBay(i) ? 1 : 0),
            .is_kichwa = static_cast<uint8_t>(IsKichwaBay(i) ? 1 : 0),
            .is_kimbi = static_cast<uint8_t>(IsKimbiBay(i) ? 1 : 0),
        });
  }

  spatial_grid_.Clear();
}

bool CombatSystem::InjectCore(uint8_t target_bay, int8_t direction) {
  VLOG(6) << "CombatSystem::InjectCore: target_bay="
          << static_cast<int>(target_bay)
          << ", direction=" << static_cast<int>(direction);
  if (target_bay >= kTotalBays || (direction != 1 && direction != -1)) {
    return false;
  }

  if (dreadnought_entity_ == entt::null ||
      !registry_.valid(dreadnought_entity_)) {
    return false;
  }

  auto& dread = registry_.get<DreadnoughtStateComponent>(dreadnought_entity_);
  if (dread.reserve_cores == 0 || dread.is_cascading != 0) {
    return false;
  }

  auto sim_state = static_cast<SimulationState>(dread.current_sim_state);
  if (sim_state != SimulationState::OrbitalIdle) {
    return false;
  }

  // Decrement reserve cores and increment cores used
  dread.reserve_cores--;
  dread.cores_used++;

  // Increment target bay mass by +1
  auto& bay = registry_.get<BatteryComponent>(bay_entities_[target_bay]);
  bay.charge_units += 1;

  // Namua placement scoops all contained plasma units from the chamber
  const uint32_t units_to_sow = bay.charge_units;
  bay.charge_units = 0;

  // Initialize SowingStateComponent on dreadnought entity
  registry_.emplace_or_replace<SowingStateComponent>(
      dreadnought_entity_, SowingStateComponent{
                               .origin_bay = target_bay,
                               .current_bay = target_bay,
                               .remaining_units = units_to_sow,
                               .step_direction = direction,
                               .step_accumulator = 0.0f,
                               .cascade_depth = 0,
                               .flak_triggered = 0,
                           });

  dread.is_cascading = 1;
  dread.current_sim_state =
      static_cast<uint8_t>(SimulationState::SowingTraversal);

  return true;
}

void CombatSystem::SetTargetPositionX(float target_x) {
  if (dreadnought_entity_ != entt::null &&
      registry_.valid(dreadnought_entity_)) {
    auto& dread = registry_.get<DreadnoughtStateComponent>(dreadnought_entity_);
    dread.target_position_x = std::clamp(target_x, 0.0f, 1.0f);
  }
}

SimulationState CombatSystem::GetSimulationState() const {
  if (dreadnought_entity_ != entt::null &&
      registry_.valid(dreadnought_entity_)) {
    const auto& dread =
        registry_.get<DreadnoughtStateComponent>(dreadnought_entity_);
    return static_cast<SimulationState>(dread.current_sim_state);
  }
  return SimulationState::OrbitalIdle;
}

void CombatSystem::Update(float delta_time) {
  if (dreadnought_entity_ == entt::null ||
      !registry_.valid(dreadnought_entity_)) {
    return;
  }

  auto& dread = registry_.get<DreadnoughtStateComponent>(dreadnought_entity_);

  // Critically damped spring smoothing for horizontal position
  const float smooth_factor = 12.0f;
  dread.orbital_position_x +=
      (dread.target_position_x - dread.orbital_position_x) *
      std::min(1.0f, delta_time * smooth_factor);

  // Update FSM
  StepFSM(delta_time);

  // Advance enemies if not game over / victory
  auto sim_state = static_cast<SimulationState>(dread.current_sim_state);
  if (sim_state == SimulationState::OrbitalIdle ||
      sim_state == SimulationState::SowingTraversal ||
      sim_state == SimulationState::CrossDischarge) {
    AdvanceEnemies(delta_time);
  }

  // Update active lances and flak timers
  ProcessParticleLances(delta_time);
  ProcessFlakBursts(delta_time);

  // Rebuild 2D spatial grid
  RebuildSpatialGrid();

  // Evaluate victory/defeat conditions
  CheckVictoryLossConditions();
}

void CombatSystem::StepFSM(float delta_time) {
  (void)delta_time;
  auto& dread = registry_.get<DreadnoughtStateComponent>(dreadnought_entity_);
  auto current_state = static_cast<SimulationState>(dread.current_sim_state);

  switch (current_state) {
    case SimulationState::SowingTraversal: {
      if (!registry_.all_of<SowingStateComponent>(dreadnought_entity_)) {
        dread.current_sim_state =
            static_cast<uint8_t>(SimulationState::CleanupCheck);
        break;
      }

      auto& sowing = registry_.get<SowingStateComponent>(dreadnought_entity_);
      if (sowing.remaining_units == 0) {
        dread.current_sim_state =
            static_cast<uint8_t>(SimulationState::EvaluateDestination);
        break;
      }

      // Step along ring buffer
      const uint8_t next_bay =
          StepBayIndex(sowing.current_bay, sowing.step_direction);
      sowing.current_bay = next_bay;

      // Deposit 1 plasma unit
      auto& bay = registry_.get<BatteryComponent>(bay_entities_[next_bay]);
      bay.charge_units += 1;
      sowing.remaining_units -= 1;

      // If this is an active relay cycle (> 0 laps), emit intermediate flak
      // trail
      if (sowing.cascade_depth > 0) {
        const float col_x = IsFrontlineBay(next_bay)
                                ? (static_cast<float>(next_bay - 8) + 0.5f) /
                                      static_cast<float>(kCorridorCount)
                                : dread.orbital_position_x;
        ExecuteFlakDetonation(col_x, dread.boundary_line_y + 0.05f,
                              bay.charge_units);
        sowing.flak_triggered = 1;
      }

      if (sowing.remaining_units == 0) {
        dread.current_sim_state =
            static_cast<uint8_t>(SimulationState::EvaluateDestination);
      }
      break;
    }

    case SimulationState::EvaluateDestination: {
      if (!registry_.all_of<SowingStateComponent>(dreadnought_entity_)) {
        dread.current_sim_state =
            static_cast<uint8_t>(SimulationState::CleanupCheck);
        break;
      }

      const auto& sowing =
          registry_.get<SowingStateComponent>(dreadnought_entity_);
      const uint8_t term_bay = sowing.current_bay;
      const auto& bay =
          registry_.get<BatteryComponent>(bay_entities_[term_bay]);
      const uint32_t final_mass = bay.charge_units;

      if (IsFrontlineBay(term_bay)) {
        const int8_t corridor = CorridorForFrontlineBay(term_bay);
        const bool corridor_has_enemies =
            (corridor >= 0 && spatial_grid_.GetCorridorCount(corridor) > 0);

        if (corridor_has_enemies && final_mass > 0) {
          // Frontline Cross-Discharge (Mtaji)
          dread.current_sim_state =
              static_cast<uint8_t>(SimulationState::CrossDischarge);
          ExecuteCrossDischarge(term_bay, final_mass);
        } else if (final_mass > 1 && !IsNyumbaBay(term_bay)) {
          // Destination already held charge -> Relay Overload
          dread.current_sim_state =
              static_cast<uint8_t>(SimulationState::RelayOverload);
        } else {
          // Empty bay landing or takata -> terminates
          dread.current_sim_state =
              static_cast<uint8_t>(SimulationState::CleanupCheck);
        }
      } else {
        // Inner Reservoir
        if (final_mass > 1 && !IsNyumbaBay(term_bay)) {
          // Inner bay relay overload
          dread.current_sim_state =
              static_cast<uint8_t>(SimulationState::RelayOverload);
        } else {
          // Takata charge redistribution
          dread.current_sim_state =
              static_cast<uint8_t>(SimulationState::CleanupCheck);
        }
      }
      break;
    }

    case SimulationState::CrossDischarge: {
      // Beam active duration is managed in ProcessParticleLances.
      // Once lances complete, transition to CleanupCheck.
      bool any_active_lances = false;
      auto view = registry_.view<ParticleLanceComponent>();
      for (auto entity : view) {
        if (view.get<ParticleLanceComponent>(entity).active != 0) {
          any_active_lances = true;
          break;
        }
      }

      if (!any_active_lances) {
        dread.current_sim_state =
            static_cast<uint8_t>(SimulationState::CleanupCheck);
      }
      break;
    }

    case SimulationState::RelayOverload: {
      if (!registry_.all_of<SowingStateComponent>(dreadnought_entity_)) {
        dread.current_sim_state =
            static_cast<uint8_t>(SimulationState::CleanupCheck);
        break;
      }

      auto& sowing = registry_.get<SowingStateComponent>(dreadnought_entity_);
      const uint8_t term_bay = sowing.current_bay;
      auto& bay = registry_.get<BatteryComponent>(bay_entities_[term_bay]);

      // Scoop entire mass from destination
      const uint32_t scooped_mass = bay.charge_units;
      bay.charge_units = 0;
      sowing.remaining_units = scooped_mass;
      sowing.cascade_depth++;

      // Emit radial flak burst from overload
      const float col_x = IsFrontlineBay(term_bay)
                              ? (static_cast<float>(term_bay - 8) + 0.5f) /
                                    static_cast<float>(kCorridorCount)
                              : dread.orbital_position_x;
      ExecuteFlakDetonation(col_x, dread.boundary_line_y + 0.05f, scooped_mass);

      // Re-enter sowing traversal
      dread.current_sim_state =
          static_cast<uint8_t>(SimulationState::SowingTraversal);
      break;
    }

    case SimulationState::CleanupCheck: {
      registry_.remove<SowingStateComponent>(dreadnought_entity_);
      dread.is_cascading = 0;

      // Check for victory or loss
      CheckVictoryLossConditions();

      if (dread.current_sim_state !=
              static_cast<uint8_t>(SimulationState::Victory) &&
          dread.current_sim_state !=
              static_cast<uint8_t>(SimulationState::GameOver)) {
        dread.current_sim_state =
            static_cast<uint8_t>(SimulationState::OrbitalIdle);
      }
      break;
    }

    default:
      break;
  }
}

void CombatSystem::ExecuteCrossDischarge(uint8_t firing_bay, uint32_t mass) {
  VLOG(6) << "CombatSystem::ExecuteCrossDischarge: firing_bay="
          << static_cast<int>(firing_bay) << ", mass=" << mass;
  auto& bay = registry_.get<BatteryComponent>(bay_entities_[firing_bay]);
  bay.charge_units = 0;  // Discharging completely empties the firing chamber

  const int8_t corridor = CorridorForFrontlineBay(firing_bay);
  if (corridor < 0) return;

  const float lance_origin_x = (static_cast<float>(corridor) + 0.5f) /
                               static_cast<float>(kCorridorCount);
  const auto& dread =
      registry_.get<DreadnoughtStateComponent>(dreadnought_entity_);
  const float lance_origin_y = dread.boundary_line_y;

  const float damage = ComputeLanceDamage(mass);

  // Spawn ParticleLance entity
  auto lance_entity = registry_.create();
  registry_.emplace<ParticleLanceComponent>(
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

  // Raycast through enemies in this specific corridor
  auto occupants = spatial_grid_.GetCorridorOccupants(corridor);
  float remaining_damage = damage;

  for (uint32_t entity_id : occupants) {
    auto enemy_entity = static_cast<entt::entity>(entity_id);
    if (!registry_.valid(enemy_entity) ||
        !registry_.all_of<EnemyVesselComponent>(enemy_entity)) {
      continue;
    }

    auto& vessel = registry_.get<EnemyVesselComponent>(enemy_entity);
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
        // Award score
        auto& d = registry_.get<DreadnoughtStateComponent>(dreadnought_entity_);
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

void CombatSystem::ExecuteFlakDetonation(float pos_x, float pos_y,
                                         uint32_t mass) {
  VLOG(6) << "CombatSystem::ExecuteFlakDetonation: x=" << pos_x
          << ", y=" << pos_y << ", mass=" << mass;
  const float area_damage = ComputeFlakDamage(mass);
  const float blast_radius = 0.15f + 0.02f * static_cast<float>(mass);

  auto flak_entity = registry_.create();
  registry_.emplace<FlakBurstComponent>(flak_entity,
                                        FlakBurstComponent{
                                            .world_pos_x = pos_x,
                                            .world_pos_y = pos_y,
                                            .blast_radius = blast_radius,
                                            .area_damage = area_damage,
                                            .lifetime = 0.25f,
                                            .remaining_lifetime = 0.25f,
                                            .active = 1,
                                        });

  // Query nearby enemies within blast radius
  auto view = registry_.view<EnemyVesselComponent>();
  for (auto entity : view) {
    auto& enemy = view.get<EnemyVesselComponent>(entity);
    if (enemy.is_destroyed != 0) continue;

    const float dx = enemy.world_pos_x - pos_x;
    const float dy = enemy.world_pos_y - pos_y;
    const float dist = std::sqrt(dx * dx + dy * dy);

    if (dist <= blast_radius) {
      // Flak deals area damage directly
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
          auto& d =
              registry_.get<DreadnoughtStateComponent>(dreadnought_entity_);
          d.total_score += 50 * (enemy.vessel_type + 1);
        } else {
          enemy.current_hull -= dmg;
        }
      }
    }
  }
}

void CombatSystem::ProcessParticleLances(float delta_time) {
  auto view = registry_.view<ParticleLanceComponent>();
  for (auto entity : view) {
    auto& lance = view.get<ParticleLanceComponent>(entity);
    if (lance.active != 0) {
      lance.remaining_duration -= delta_time;
      if (lance.remaining_duration <= 0.0f) {
        lance.active = 0;
        registry_.destroy(entity);
      }
    }
  }
}

void CombatSystem::ProcessFlakBursts(float delta_time) {
  auto view = registry_.view<FlakBurstComponent>();
  for (auto entity : view) {
    auto& flak = view.get<FlakBurstComponent>(entity);
    if (flak.active != 0) {
      flak.remaining_lifetime -= delta_time;
      if (flak.remaining_lifetime <= 0.0f) {
        flak.active = 0;
        registry_.destroy(entity);
      }
    }
  }
}

void CombatSystem::AdvanceEnemies(float delta_time) {
  auto view = registry_.view<EnemyVesselComponent>();
  for (auto entity : view) {
    auto& enemy = view.get<EnemyVesselComponent>(entity);
    if (enemy.is_destroyed != 0) continue;

    enemy.world_pos_y -= enemy.velocity_y * delta_time;
  }
}

void CombatSystem::RebuildSpatialGrid() {
  spatial_grid_.Clear();
  auto view = registry_.view<EnemyVesselComponent>();
  for (auto entity : view) {
    const auto& enemy = view.get<EnemyVesselComponent>(entity);
    if (enemy.is_destroyed == 0 && enemy.assigned_corridor < kCorridorCount) {
      spatial_grid_.RegisterEntity(
          static_cast<uint8_t>(enemy.assigned_corridor),
          static_cast<uint32_t>(entity));
    }
  }
}

void CombatSystem::CheckVictoryLossConditions() {
  auto& dread = registry_.get<DreadnoughtStateComponent>(dreadnought_entity_);
  if (dread.current_sim_state ==
          static_cast<uint8_t>(SimulationState::Victory) ||
      dread.current_sim_state ==
          static_cast<uint8_t>(SimulationState::GameOver)) {
    return;
  }

  // 1. Defeat check: Enemy breached atmospheric boundary
  auto view = registry_.view<EnemyVesselComponent>();
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

  // 3. Defeat check: Core reserves exhausted and not currently cascading
  if (dread.reserve_cores == 0 && dread.is_cascading == 0 && any_alive) {
    // Check if any bay has available mass to sow
    bool any_bay_has_plasma = false;
    for (uint8_t i = 0; i < kTotalBays; ++i) {
      if (registry_.get<BatteryComponent>(bay_entities_[i]).charge_units > 0) {
        any_bay_has_plasma = true;
        break;
      }
    }
    if (!any_bay_has_plasma) {
      dread.current_sim_state = static_cast<uint8_t>(SimulationState::GameOver);
    }
  }
}

void CombatSystem::DamageConduit(uint8_t bay_index) {
  if (dreadnought_entity_ == entt::null ||
      !registry_.valid(dreadnought_entity_)) {
    return;
  }
  auto& dread = registry_.get<DreadnoughtStateComponent>(dreadnought_entity_);
  if (dread.reserve_cores > 0) {
    dread.reserve_cores -= 1;
  }
  if (bay_index < kTotalBays && bay_entities_[bay_index] != entt::null &&
      registry_.valid(bay_entities_[bay_index])) {
    auto& bay = registry_.get<BatteryComponent>(bay_entities_[bay_index]);
    bay.charge_units = 0;  // EMP discharge: clears accumulated plasma!
  }
  CheckVictoryLossConditions();
}

void CombatSystem::DamageAtmosphere(uint32_t penalty) {
  if (dreadnought_entity_ == entt::null ||
      !registry_.valid(dreadnought_entity_)) {
    return;
  }
  auto& dread = registry_.get<DreadnoughtStateComponent>(dreadnought_entity_);
  if (dread.total_score >= penalty) {
    dread.total_score -= penalty;
  } else {
    dread.total_score = 0;
  }
}

CombatSystem::PredictionResult CombatSystem::PredictSow(
    uint8_t start_bay, int8_t direction) const {
  PredictionResult result{
      .terminal_bay = start_bay,
      .terminal_corridor = -1,
      .final_mass = 0,
      .predicted_damage = 0.0f,
      .total_cascade_laps = 0,
      .triggers_lance = false,
      .triggers_relay = false,
  };

  if (start_bay >= kTotalBays || (direction != 1 && direction != -1)) {
    return result;
  }

  // Simulate on a temporary bay array
  std::array<uint32_t, kTotalBays> temp_bays{};
  for (uint8_t i = 0; i < kTotalBays; ++i) {
    temp_bays[i] =
        registry_.get<BatteryComponent>(bay_entities_[i]).charge_units;
  }

  // Inject +1 into start_bay and scoop
  uint32_t hand = temp_bays[start_bay] + 1;
  temp_bays[start_bay] = 0;
  uint8_t cur_bay = start_bay;
  uint16_t laps = 0;

  while (hand > 0) {
    cur_bay = StepBayIndex(cur_bay, direction);
    temp_bays[cur_bay] += 1;
    hand -= 1;

    if (hand == 0) {
      const uint32_t term_mass = temp_bays[cur_bay];
      if (IsFrontlineBay(cur_bay)) {
        const int8_t corridor = CorridorForFrontlineBay(cur_bay);
        if (corridor >= 0 && spatial_grid_.GetCorridorCount(corridor) > 0 &&
            term_mass > 0) {
          result.triggers_lance = true;
          result.terminal_bay = cur_bay;
          result.terminal_corridor = corridor;
          result.final_mass = term_mass;
          result.predicted_damage = ComputeLanceDamage(term_mass);
          result.total_cascade_laps = laps;
          return result;
        }
      }

      // Check relay
      if (term_mass > 1 && !IsNyumbaBay(cur_bay) && laps < 10) {
        hand = term_mass;
        temp_bays[cur_bay] = 0;
        laps++;
        result.triggers_relay = true;
      } else {
        break;
      }
    }
  }

  result.terminal_bay = cur_bay;
  result.terminal_corridor = CorridorForFrontlineBay(cur_bay);
  result.final_mass = temp_bays[cur_bay];
  result.predicted_damage =
      IsFrontlineBay(cur_bay) ? ComputeLanceDamage(result.final_mass) : 0.0f;
  result.total_cascade_laps = laps;
  return result;
}

}  // namespace void_sower::ecs
