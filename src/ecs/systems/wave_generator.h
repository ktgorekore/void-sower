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

#ifndef VOID_SOWER_ECS_SYSTEMS_WAVE_GENERATOR_H_
#define VOID_SOWER_ECS_SYSTEMS_WAVE_GENERATOR_H_

#include <cstdint>
#include <entt/entt.hpp>

#include "../components.h"

namespace void_sower::ecs {

/// Difficulty classification for procedural encounters.
enum class EncounterDifficulty : uint8_t {
  SectorPatrol = 0,    ///< Tier 1: 1-2 moves, introductory / casual.
  PlanetarySiege = 1,  ///< Tier 2: 3-5 moves, requires relay setups.
  FlagshipBastion = 2  ///< Tier 3: 6+ moves, multi-lap cascades, flagship boss.
};

/**
 * @brief Configuration parameters for procedural encounter generation.
 */
struct WaveGeneratorConfig {
  EncounterDifficulty difficulty{EncounterDifficulty::SectorPatrol};
  uint32_t random_seed{0};
  uint32_t core_budget{12};
  float initial_velocity_y{0.03f};
  uint8_t target_corridors_mask{
      0xFF};  ///< Bitmask of allowed attack corridors.
};

/**
 * @brief Procedural Wave Generator implementing backward-play program
 * inversion. Guarantees that every generated wave is mathematically solvable.
 */
class WaveGenerator {
 public:
  explicit WaveGenerator(entt::registry& registry);
  ~WaveGenerator() = default;

  /// Generates a mathematically solvable wave using backward-play inversion.
  bool GenerateWave(const WaveGeneratorConfig& config);

 private:
  entt::registry& registry_;
};

}  // namespace void_sower::ecs

#endif  // VOID_SOWER_ECS_SYSTEMS_WAVE_GENERATOR_H_
