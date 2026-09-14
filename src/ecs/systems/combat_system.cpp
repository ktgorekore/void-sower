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

namespace void_sower::ecs {

CombatSystem::CombatSystem(entt::registry& registry) : registry_(registry) {}

void CombatSystem::InitializeDreadnought(uint32_t starting_cores,
                                         float boundary_y) {
  VLOG(6) << "CombatSystem::InitializeDreadnought: starting_cores="
          << starting_cores << ", boundary_y=" << boundary_y;
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
  return bao_cascade_system_.InjectCore(registry_, dreadnought_entity_,
                                        bay_entities_, target_bay, direction);
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

  // 1. Damped spring platform smoothing
  movement_system_.UpdateDreadnought(registry_, dreadnought_entity_,
                                     delta_time);

  // 2. Step deterministic sowing FSM
  bao_cascade_system_.StepFSM(registry_, dreadnought_entity_, bay_entities_,
                              spatial_grid_, discharge_system_,
                              match_lifecycle_system_, delta_time);

  // 3. Advance enemies during active match phases
  auto& dread = registry_.get<DreadnoughtStateComponent>(dreadnought_entity_);
  auto sim_state = static_cast<SimulationState>(dread.current_sim_state);
  if (sim_state == SimulationState::OrbitalIdle ||
      sim_state == SimulationState::SowingTraversal ||
      sim_state == SimulationState::CrossDischarge) {
    movement_system_.AdvanceEnemies(registry_, delta_time);
  }

  // 4. Update particle lances and secondary flaks
  discharge_system_.ProcessParticleLances(registry_, delta_time);
  discharge_system_.ProcessFlakBursts(registry_, delta_time);

  // 5. Rebuild spatial grid for raycasting
  RebuildSpatialGrid();

  // 6. Check victory/loss conditions
  match_lifecycle_system_.CheckVictoryLossConditions(
      registry_, dreadnought_entity_, bay_entities_);
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

void CombatSystem::DamageConduit(uint8_t bay_index) {
  match_lifecycle_system_.DamageConduit(registry_, dreadnought_entity_,
                                        bay_entities_, bay_index);
}

void CombatSystem::DamageAtmosphere(uint32_t penalty) {
  match_lifecycle_system_.DamageAtmosphere(registry_, dreadnought_entity_,
                                           penalty);
}

CombatSystem::PredictionResult CombatSystem::PredictSow(
    uint8_t start_bay, int8_t direction) const {
  return bao_cascade_system_.PredictSow(registry_, bay_entities_, spatial_grid_,
                                        start_bay, direction);
}

}  // namespace void_sower::ecs
