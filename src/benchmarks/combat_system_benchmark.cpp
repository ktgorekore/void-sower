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

#include <benchmark/benchmark.h>

#include "ecs/components.h"
#include "ecs/systems/combat_system.h"
#include "ecs/systems/discharge_system.h"
#include "ecs/systems/spatial_grid.h"

namespace void_sower::benchmarks {

using namespace void_sower::ecs;

static void BM_SpatialGrid_RegisterAndQuery(benchmark::State& state) {
  SpatialGrid grid;
  for (auto _ : state) {
    grid.Clear();
    for (uint32_t i = 0; i < 64; ++i) {
      grid.RegisterEntity(static_cast<uint8_t>(i % kCorridorCount), i + 1);
    }
    for (uint8_t c = 0; c < kCorridorCount; ++c) {
      auto occupants = grid.GetCorridorOccupants(c);
      benchmark::DoNotOptimize(occupants.data());
      benchmark::DoNotOptimize(occupants.size());
    }
  }
}
BENCHMARK(BM_SpatialGrid_RegisterAndQuery);

static void BM_Discharge_LanceRaycast_ZeroAlloc(benchmark::State& state) {
  entt::registry registry;
  auto dread = registry.create();
  registry.emplace<DreadnoughtStateComponent>(
      dread, DreadnoughtStateComponent{
                 .orbital_position_x = 0.5f,
                 .target_position_x = 0.5f,
                 .boundary_line_y = 0.2f,
                 .reserve_cores = 32,
                 .total_score = 0,
                 .cores_used = 0,
                 .is_cascading = 0,
                 .current_sim_state =
                     static_cast<uint8_t>(SimulationState::OrbitalIdle),
             });

  std::array<entt::entity, kTotalBays> bays{};
  for (size_t i = 0; i < kTotalBays; ++i) {
    bays[i] = registry.create();
    registry.emplace<BatteryComponent>(
        bays[i], BatteryComponent{
                     .charge_units = 5,
                     .radial_position_rad = static_cast<float>(i),
                     .grid_column = static_cast<uint16_t>(i >= 8 ? i - 8 : 0),
                     .bay_index = static_cast<uint8_t>(i),
                     .tier = static_cast<uint8_t>(i >= 8 ? 1 : 0),
                     .is_frontline = static_cast<uint8_t>(i >= 8 ? 1 : 0),
                 });
  }

  SpatialGrid grid;
  for (uint32_t i = 0; i < 64; ++i) {
    auto e = registry.create();
    uint16_t corridor = static_cast<uint16_t>(i % kCorridorCount);
    registry.emplace<EnemyVesselComponent>(
        e, EnemyVesselComponent{
               .entity_id = i + 100,
               .assigned_corridor = corridor,
               .world_pos_x = (corridor + 0.5f) / 8.0f,
               .world_pos_y = 0.5f + 0.005f * static_cast<float>(i / 8),
               .velocity_y = 0.05f,
               .current_shields = 50.0f,
               .max_shields = 50.0f,
               .current_hull = 100.0f,
               .max_hull = 100.0f,
               .vessel_type = static_cast<uint8_t>(i % 3),
               .is_destroyed = 0,
           });
    grid.RegisterEntity(static_cast<uint8_t>(corridor),
                        static_cast<uint32_t>(e));
  }

  DischargeSystem discharge;
  discharge.InitializePool(registry);

  uint8_t firing_bay = 11;
  for (auto _ : state) {
    discharge.ExecuteCrossDischarge(registry, dread, bays, grid, firing_bay, 4);
    discharge.ProcessParticleLances(registry, 0.4f);
  }
}
BENCHMARK(BM_Discharge_LanceRaycast_ZeroAlloc);

static void BM_Discharge_FlakDetonation_ZeroAlloc(benchmark::State& state) {
  entt::registry registry;
  auto dread = registry.create();
  registry.emplace<DreadnoughtStateComponent>(dread,
                                              DreadnoughtStateComponent{});

  for (uint32_t i = 0; i < 64; ++i) {
    auto e = registry.create();
    registry.emplace<EnemyVesselComponent>(
        e, EnemyVesselComponent{
               .entity_id = i + 100,
               .assigned_corridor = static_cast<uint16_t>(i % kCorridorCount),
               .world_pos_x = static_cast<float>(i % 8) / 8.0f + 0.05f,
               .world_pos_y = 0.3f + 0.005f * static_cast<float>(i / 8),
               .velocity_y = 0.05f,
               .current_shields = 50.0f,
               .max_shields = 50.0f,
               .current_hull = 100.0f,
               .max_hull = 100.0f,
               .vessel_type = 0,
               .is_destroyed = 0,
           });
  }

  DischargeSystem discharge;
  discharge.InitializePool(registry);

  for (auto _ : state) {
    discharge.ExecuteFlakDetonation(registry, dread, 0.5f, 0.4f, 3);
    discharge.ProcessFlakBursts(registry, 0.3f);
  }
}
BENCHMARK(BM_Discharge_FlakDetonation_ZeroAlloc);

static void BM_CombatSystem_60HzUpdate(benchmark::State& state) {
  entt::registry registry;
  CombatSystem combat(registry);
  combat.InitializeDreadnought(32, 0.2f);

  for (uint32_t i = 0; i < 64; ++i) {
    auto e = registry.create();
    uint16_t corridor = static_cast<uint16_t>(i % kCorridorCount);
    registry.emplace<EnemyVesselComponent>(
        e, EnemyVesselComponent{
               .entity_id = i + 1,
               .assigned_corridor = corridor,
               .world_pos_x = (corridor + 0.5f) / 8.0f,
               .world_pos_y = 0.8f,
               .velocity_y = 0.05f,
               .current_shields = 100.0f,
               .max_shields = 100.0f,
               .current_hull = 100.0f,
               .max_hull = 100.0f,
               .vessel_type = 1,
               .is_destroyed = 0,
           });
  }
  combat.RebuildSpatialGrid();
  combat.InjectCore(7, 1);

  for (auto _ : state) {
    combat.Update(kFixedTimeStep);
  }
}
BENCHMARK(BM_CombatSystem_60HzUpdate);

}  // namespace void_sower::benchmarks
