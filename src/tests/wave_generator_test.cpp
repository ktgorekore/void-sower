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

#include "ecs/systems/wave_generator.h"

#include <gtest/gtest.h>

#include "ecs/engine.h"

namespace void_sower::ecs {

TEST(WaveGeneratorTest, ProceduralGenerationAcrossTiers) {
  Engine engine;

  // 1. Sector Patrol (Tier 1)
  WaveGeneratorConfig tier1_cfg{
      .difficulty = EncounterDifficulty::SectorPatrol,
      .random_seed = 12345,
      .core_budget = 12,
  };
  EXPECT_TRUE(engine.GenerateWave(tier1_cfg));

  std::array<EnemyVesselComponent, 16> enemies{};
  uint32_t count1 =
      engine.GetEnemies(absl::MakeSpan(enemies.data(), enemies.size()));
  EXPECT_GT(count1, 0);

  // 2. Planetary Siege (Tier 2)
  WaveGeneratorConfig tier2_cfg{
      .difficulty = EncounterDifficulty::PlanetarySiege,
      .random_seed = 67890,
      .core_budget = 16,
  };
  EXPECT_TRUE(engine.GenerateWave(tier2_cfg));
  uint32_t count2 =
      engine.GetEnemies(absl::MakeSpan(enemies.data(), enemies.size()));
  EXPECT_GT(count2, 0);

  // 3. Flagship Bastion (Tier 3)
  WaveGeneratorConfig tier3_cfg{
      .difficulty = EncounterDifficulty::FlagshipBastion,
      .random_seed = 99999,
      .core_budget = 24,
  };
  EXPECT_TRUE(engine.GenerateWave(tier3_cfg));
  uint32_t count3 =
      engine.GetEnemies(absl::MakeSpan(enemies.data(), enemies.size()));
  EXPECT_GT(count3, 0);

  // Check that at least one enemy in Tier 3 is a Flagship
  bool has_flagship = false;
  for (uint32_t i = 0; i < count3; ++i) {
    if (enemies[i].vessel_type == static_cast<uint8_t>(VesselType::Flagship)) {
      has_flagship = true;
      break;
    }
  }
  EXPECT_TRUE(has_flagship);
}

TEST(WaveGeneratorTest, DeterministicSeedInvariance) {
  Engine engine1;
  Engine engine2;

  WaveGeneratorConfig cfg{
      .difficulty = EncounterDifficulty::PlanetarySiege,
      .random_seed = 424242,
      .core_budget = 16,
  };

  engine1.GenerateWave(cfg);
  engine2.GenerateWave(cfg);

  std::array<EnemyVesselComponent, 16> enemies1{};
  std::array<EnemyVesselComponent, 16> enemies2{};
  uint32_t count1 =
      engine1.GetEnemies(absl::MakeSpan(enemies1.data(), enemies1.size()));
  uint32_t count2 =
      engine2.GetEnemies(absl::MakeSpan(enemies2.data(), enemies2.size()));

  ASSERT_EQ(count1, count2);
  for (uint32_t i = 0; i < count1; ++i) {
    EXPECT_EQ(enemies1[i].assigned_corridor, enemies2[i].assigned_corridor);
    EXPECT_FLOAT_EQ(enemies1[i].current_hull, enemies2[i].current_hull);
    EXPECT_FLOAT_EQ(enemies1[i].current_shields, enemies2[i].current_shields);
    EXPECT_EQ(enemies1[i].vessel_type, enemies2[i].vessel_type);
  }
}

}  // namespace void_sower::ecs
