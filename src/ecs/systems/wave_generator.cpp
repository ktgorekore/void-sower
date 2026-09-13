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

#include "wave_generator.h"

#include <random>
#include <vector>

#include "combat_system.h"
#include "ring_buffer.h"

namespace void_sower::ecs {

WaveGenerator::WaveGenerator(entt::registry& registry) : registry_(registry) {}

bool WaveGenerator::GenerateWave(const WaveGeneratorConfig& config) {
  // Clear any existing enemy entities
  auto view = registry_.view<EnemyVesselComponent>();
  for (auto entity : view) {
    registry_.destroy(entity);
  }

  // Setup PRNG
  std::mt19937 rng(config.random_seed != 0 ? config.random_seed : 42);

  // Number of inversion iterations based on difficulty
  uint32_t moves_to_invert = 2;
  switch (config.difficulty) {
    case EncounterDifficulty::SectorPatrol:
      moves_to_invert = 2;
      break;
    case EncounterDifficulty::PlanetarySiege:
      moves_to_invert = 4;
      break;
    case EncounterDifficulty::FlagshipBastion:
      moves_to_invert = 6;
      break;
  }

  // 1. Terminal Victory State:
  // All enemies destroyed, bay charges zeroed
  std::array<uint32_t, kTotalBays> simulated_bays{};
  uint32_t injected_cores = 0;

  // Track enemies generated via inverse lances
  struct PlannedEnemy {
    uint8_t corridor;
    float health;
    VesselType type;
  };
  std::vector<PlannedEnemy> planned_enemies;

  // 2. Perform Backward-Play Program Inversion
  for (uint32_t m = 0; m < moves_to_invert; ++m) {
    // Select an outer frontline bay to receive an inverse lance
    std::uniform_int_distribution<int> corr_dist(0, kCorridorCount - 1);
    uint8_t corridor = static_cast<uint8_t>(corr_dist(rng));
    uint8_t frontline_bay = FrontlineBayForCorridor(corridor);

    // Pick terminal mass M that was discharged
    std::uniform_int_distribution<int> mass_dist(
        2, config.difficulty == EncounterDifficulty::FlagshipBastion ? 5 : 3);
    uint32_t terminal_mass = static_cast<uint32_t>(mass_dist(rng));

    // Inverse cross-discharge:
    // Beam destroyed an enemy with health matching quadratic damage D = alpha *
    // M^2
    float total_health = ComputeLanceDamage(terminal_mass);
    VesselType type = VesselType::Escort;
    if (config.difficulty == EncounterDifficulty::FlagshipBastion &&
        m == moves_to_invert - 1) {
      type = VesselType::Flagship;
    } else if (terminal_mass >= 3) {
      type = VesselType::Cruiser;
    }

    planned_enemies.push_back(PlannedEnemy{
        .corridor = corridor,
        .health = total_health,
        .type = type,
    });

    // Firing bay charge is restored from zero to terminal_mass
    simulated_bays[frontline_bay] = terminal_mass;

    // Inverse sowing (gathering):
    // Choose angular direction
    std::uniform_int_distribution<int> dir_dist(0, 1);
    int8_t forward_dir = (dir_dist(rng) == 0) ? 1 : -1;
    int8_t inverse_dir = static_cast<int8_t>(-forward_dir);

    // Gather seeds backward
    uint8_t current_bay = frontline_bay;
    uint32_t gathered_units = 0;

    for (uint32_t step = 0; step < terminal_mass; ++step) {
      // Step backward
      current_bay = StepBayIndex(current_bay, inverse_dir);
      // In forward play, this bay received 1 unit from origin
      // In backward play, we gather 1 unit from this bay into origin
      gathered_units += 1;
    }

    // Inverse injection (un-namua):
    // The origin bay was injected with +1 core
    injected_cores += 1;
    simulated_bays[current_bay] +=
        (gathered_units > 1 ? gathered_units - 1 : 0);
  }

  // 3. Apply simulated initial charges back to registry batteries
  auto bay_view = registry_.view<BatteryComponent>();
  for (auto entity : bay_view) {
    auto& bay = bay_view.get<BatteryComponent>(entity);
    bay.charge_units = simulated_bays[bay.bay_index];
  }

  // 4. Instantiate planned enemies in their corridors
  float base_y = 0.90f;
  uint32_t next_id = 1000;
  for (const auto& enemy_info : planned_enemies) {
    auto enemy_entity = registry_.create();
    const float corridor_x = (static_cast<float>(enemy_info.corridor) + 0.5f) /
                             static_cast<float>(kCorridorCount);
    const float half_health = enemy_info.health * 0.5f;

    registry_.emplace<EnemyVesselComponent>(
        enemy_entity,
        EnemyVesselComponent{
            .entity_id = next_id++,
            .assigned_corridor = enemy_info.corridor,
            .world_pos_x = corridor_x,
            .world_pos_y = base_y,
            .velocity_y = config.initial_velocity_y,
            .current_shields =
                (enemy_info.type != VesselType::Escort) ? half_health : 0.0f,
            .max_shields =
                (enemy_info.type != VesselType::Escort) ? half_health : 0.0f,
            .current_hull = (enemy_info.type != VesselType::Escort)
                                ? half_health
                                : enemy_info.health,
            .max_hull = (enemy_info.type != VesselType::Escort)
                            ? half_health
                            : enemy_info.health,
            .vessel_type = static_cast<uint8_t>(enemy_info.type),
            .is_destroyed = 0,
        });

    base_y = std::max(0.60f, base_y - 0.08f);
  }

  return true;
}

}  // namespace void_sower::ecs
