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

#include "bao_cascade_system.h"

#include <absl/log/log.h>

#include "ring_buffer.h"

namespace void_sower::ecs {

bool BaoCascadeSystem::InjectCore(
    entt::registry& registry, entt::entity dreadnought_entity,
    std::array<entt::entity, kTotalBays>& bay_entities, uint8_t target_bay,
    int8_t direction) {
  VLOG(6) << "BaoCascadeSystem::InjectCore: target_bay="
          << static_cast<int>(target_bay)
          << ", direction=" << static_cast<int>(direction);
  if (target_bay >= kTotalBays || (direction != 1 && direction != -1)) {
    return false;
  }

  if (dreadnought_entity == entt::null || !registry.valid(dreadnought_entity)) {
    return false;
  }

  auto& dread = registry.get<DreadnoughtStateComponent>(dreadnought_entity);
  if (dread.reserve_cores == 0 || dread.is_cascading != 0) {
    return false;
  }

  auto sim_state = static_cast<SimulationState>(dread.current_sim_state);
  if (sim_state == SimulationState::Victory) {
    dread.current_sim_state =
        static_cast<uint8_t>(SimulationState::OrbitalIdle);
    sim_state = SimulationState::OrbitalIdle;
  }
  if (sim_state != SimulationState::OrbitalIdle) {
    return false;
  }

  // Decrement reserve cores and increment cores used
  dread.reserve_cores--;
  dread.cores_used++;

  // Increment target bay mass by +1
  auto& bay = registry.get<BatteryComponent>(bay_entities[target_bay]);
  bay.charge_units += 1;

  // Namua placement scoops all contained plasma units from the chamber
  const uint32_t units_to_sow = bay.charge_units;
  bay.charge_units = 0;

  const int8_t resolved_direction = ResolveSowDirection(target_bay, direction);

  // Initialize SowingStateComponent on dreadnought entity
  registry.emplace_or_replace<SowingStateComponent>(
      dreadnought_entity, SowingStateComponent{
                              .origin_bay = target_bay,
                              .current_bay = target_bay,
                              .remaining_units = units_to_sow,
                              .step_direction = resolved_direction,
                              .step_accumulator = 0.0f,
                              .cascade_depth = 0,
                              .flak_triggered = 0,
                          });

  dread.is_cascading = 1;
  dread.current_sim_state =
      static_cast<uint8_t>(SimulationState::SowingTraversal);

  return true;
}

void BaoCascadeSystem::StepFSM(
    entt::registry& registry, entt::entity dreadnought_entity,
    std::array<entt::entity, kTotalBays>& bay_entities,
    const SpatialGrid& spatial_grid, DischargeSystem& discharge_system,
    MatchLifecycleSystem& match_lifecycle_system, float delta_time) {
  (void)delta_time;
  auto& dread = registry.get<DreadnoughtStateComponent>(dreadnought_entity);
  auto current_state = static_cast<SimulationState>(dread.current_sim_state);

  switch (current_state) {
    case SimulationState::SowingTraversal: {
      if (!registry.all_of<SowingStateComponent>(dreadnought_entity)) {
        dread.current_sim_state =
            static_cast<uint8_t>(SimulationState::CleanupCheck);
        break;
      }

      auto& sowing = registry.get<SowingStateComponent>(dreadnought_entity);
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
      auto& bay = registry.get<BatteryComponent>(bay_entities[next_bay]);
      bay.charge_units += 1;
      sowing.remaining_units -= 1;

      // Kichwa vector conduit reversal check:
      // If the wave entered a Kichwa conduit (bay 8 or 15) and still has
      // remaining plasma units, reverse angular momentum inward along the
      // frontline battery deck.
      if (sowing.remaining_units > 0 && IsKichwaBay(next_bay)) {
        if (next_bay == 15 && sowing.step_direction == 1) {
          sowing.step_direction = -1;
        } else if (next_bay == 8 && sowing.step_direction == -1) {
          sowing.step_direction = 1;
        }
      }

      // If this is an active relay cycle (> 0 laps), emit intermediate flak
      // trail
      if (sowing.cascade_depth > 0) {
        const float col_x = IsFrontlineBay(next_bay)
                                ? (static_cast<float>(next_bay - 8) + 0.5f) /
                                      static_cast<float>(kCorridorCount)
                                : dread.orbital_position_x;
        discharge_system.ExecuteFlakDetonation(
            registry, dreadnought_entity, col_x, dread.boundary_line_y + 0.05f,
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
      if (!registry.all_of<SowingStateComponent>(dreadnought_entity)) {
        dread.current_sim_state =
            static_cast<uint8_t>(SimulationState::CleanupCheck);
        break;
      }

      const auto& sowing =
          registry.get<SowingStateComponent>(dreadnought_entity);
      const uint8_t term_bay = sowing.current_bay;
      const auto& bay = registry.get<BatteryComponent>(bay_entities[term_bay]);
      const uint32_t final_mass = bay.charge_units;

      if (IsFrontlineBay(term_bay)) {
        const auto& dread_state =
            registry.get<DreadnoughtStateComponent>(dreadnought_entity);
        const int8_t dread_corridor = static_cast<int8_t>(
            std::clamp(static_cast<int>(dread_state.orbital_position_x *
                                        static_cast<float>(kCorridorCount)),
                       0, kCorridorCount - 1));
        const int8_t bay_corridor = CorridorForFrontlineBay(term_bay);
        const bool has_enemies =
            (spatial_grid.GetCorridorCount(dread_corridor) > 0 ||
             (bay_corridor >= 0 &&
              spatial_grid.GetCorridorCount(bay_corridor) > 0));

        if (final_mass > 0 && (has_enemies || final_mass == 1)) {
          dread.current_sim_state =
              static_cast<uint8_t>(SimulationState::CrossDischarge);
          discharge_system.ExecuteCrossDischarge(registry, dreadnought_entity,
                                                 bay_entities, spatial_grid,
                                                 term_bay, final_mass);
        } else if (final_mass > 1 && !IsNyumbaBay(term_bay)) {
          dread.current_sim_state =
              static_cast<uint8_t>(SimulationState::RelayOverload);
        } else {
          dread.current_sim_state =
              static_cast<uint8_t>(SimulationState::CrossDischarge);
          discharge_system.ExecuteCrossDischarge(registry, dreadnought_entity,
                                                 bay_entities, spatial_grid,
                                                 term_bay, final_mass);
        }
      } else {
        if (final_mass > 1 && !IsNyumbaBay(term_bay)) {
          dread.current_sim_state =
              static_cast<uint8_t>(SimulationState::RelayOverload);
        } else {
          dread.current_sim_state =
              static_cast<uint8_t>(SimulationState::CleanupCheck);
        }
      }
      break;
    }

    case SimulationState::CrossDischarge: {
      // Instant lance transition: Lance damage and beam creation were executed
      // immediately upon entry in ExecuteCrossDischarge. Transition immediately
      // to CleanupCheck so the dreadnought returns to OrbitalIdle and remains
      // responsive for subsequent tactical commands, while active lances render
      // and decay independently.
      dread.current_sim_state =
          static_cast<uint8_t>(SimulationState::CleanupCheck);
      break;
    }

    case SimulationState::RelayOverload: {
      if (!registry.all_of<SowingStateComponent>(dreadnought_entity)) {
        dread.current_sim_state =
            static_cast<uint8_t>(SimulationState::CleanupCheck);
        break;
      }

      auto& sowing = registry.get<SowingStateComponent>(dreadnought_entity);
      if (sowing.cascade_depth >= 10) {
        // Prevent infinite cascade loops by forcing discharge on 10th lap
        const uint8_t term_bay = sowing.current_bay;
        auto& bay = registry.get<BatteryComponent>(bay_entities[term_bay]);
        const uint32_t terminal_mass =
            bay.charge_units > 0 ? bay.charge_units : 1;
        dread.current_sim_state =
            static_cast<uint8_t>(SimulationState::CrossDischarge);
        discharge_system.ExecuteCrossDischarge(registry, dreadnought_entity,
                                               bay_entities, spatial_grid,
                                               term_bay, terminal_mass);
        break;
      }

      const uint8_t term_bay = sowing.current_bay;
      auto& bay = registry.get<BatteryComponent>(bay_entities[term_bay]);

      const uint32_t scooped_mass = bay.charge_units;
      bay.charge_units = 0;
      sowing.remaining_units = scooped_mass;
      sowing.cascade_depth++;
      sowing.step_direction =
          ResolveSowDirection(term_bay, sowing.step_direction);

      const float col_x = IsFrontlineBay(term_bay)
                              ? (static_cast<float>(term_bay - 8) + 0.5f) /
                                    static_cast<float>(kCorridorCount)
                              : dread.orbital_position_x;
      discharge_system.ExecuteFlakDetonation(
          registry, dreadnought_entity, col_x, dread.boundary_line_y + 0.05f,
          scooped_mass);

      dread.current_sim_state =
          static_cast<uint8_t>(SimulationState::SowingTraversal);
      break;
    }

    case SimulationState::CleanupCheck: {
      if (registry.all_of<SowingStateComponent>(dreadnought_entity)) {
        registry.remove<SowingStateComponent>(dreadnought_entity);
      }
      dread.is_cascading = 0;

      match_lifecycle_system.CheckVictoryLossConditions(
          registry, dreadnought_entity, bay_entities);

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

BaoCascadeSystem::PredictionResult BaoCascadeSystem::PredictSow(
    const entt::registry& registry,
    const std::array<entt::entity, kTotalBays>& bay_entities,
    const SpatialGrid& spatial_grid, uint8_t start_bay,
    int8_t direction) const {
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

  int8_t current_direction = ResolveSowDirection(start_bay, direction);

  std::array<uint32_t, kTotalBays> temp_bays{};
  for (uint8_t i = 0; i < kTotalBays; ++i) {
    temp_bays[i] = registry.get<BatteryComponent>(bay_entities[i]).charge_units;
  }

  uint32_t hand = temp_bays[start_bay] + 1;
  temp_bays[start_bay] = 0;
  uint8_t cur_bay = start_bay;
  uint16_t laps = 0;

  while (hand > 0) {
    cur_bay = StepBayIndex(cur_bay, current_direction);
    temp_bays[cur_bay] += 1;
    hand -= 1;

    // Mid-traversal Kichwa momentum reversal check
    if (hand > 0 && IsKichwaBay(cur_bay)) {
      if (cur_bay == 15 && current_direction == 1) {
        current_direction = -1;
      } else if (cur_bay == 8 && current_direction == -1) {
        current_direction = 1;
      }
    }

    if (hand == 0) {
      const uint32_t term_mass = temp_bays[cur_bay];
      if (IsFrontlineBay(cur_bay)) {
        const int8_t corridor = CorridorForFrontlineBay(cur_bay);
        if (corridor >= 0 &&
            (spatial_grid.GetCorridorCount(corridor) > 0 || term_mass == 1) &&
            term_mass > 0) {
          result.triggers_lance = true;
          result.terminal_bay = cur_bay;
          result.terminal_corridor = corridor;
          result.final_mass = term_mass;
          result.predicted_damage = ComputeLanceDamage(
              term_mass, kAlphaLanceDamage * lance_alpha_multiplier_);
          result.total_cascade_laps = laps;
          return result;
        }
      }

      if (term_mass > 1 && !IsNyumbaBay(cur_bay) && laps < 10) {
        hand = term_mass;
        temp_bays[cur_bay] = 0;
        laps++;
        result.triggers_relay = true;
        current_direction = ResolveSowDirection(cur_bay, current_direction);
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
  if (IsFrontlineBay(cur_bay) && result.final_mass > 0) {
    result.triggers_lance = true;
  }
  return result;
}

}  // namespace void_sower::ecs
