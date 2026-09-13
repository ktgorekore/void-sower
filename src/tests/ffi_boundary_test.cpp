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

#include <gtest/gtest.h>

#include "void_sower.h"

namespace void_sower {

TEST(FfiBoundaryTest, LifecycleAndStateExport) {
  void_sower_init(20, 0.2f);

  VoidSowerDreadnoughtFFI dread{};
  void_sower_get_dreadnought_state(&dread);
  EXPECT_EQ(dread.reserve_cores, 20);
  EXPECT_EQ(dread.cores_used, 0);

  // Generate a wave via FFI
  VoidSowerWaveConfigFFI cfg{
      .difficulty = 0,
      .random_seed = 1234,
      .core_budget = 15,
      .initial_velocity_y = 0.02f,
  };
  EXPECT_EQ(void_sower_generate_wave(&cfg), 1);

  std::array<VoidSowerEnemyFFI, 16> enemies{};
  uint32_t count = void_sower_get_enemies(enemies.data(), enemies.size());
  EXPECT_GT(count, 0);

  std::array<VoidSowerBayFFI, 16> bays{};
  void_sower_get_bays(bays.data(), bays.size());
  for (uint8_t i = 0; i < 16; ++i) {
    EXPECT_EQ(bays[i].bay_index, i);
  }

  // Test predictive telemetry dry-run (start from bay 0 clockwise)
  VoidSowerPredictionFFI pred{};
  void_sower_predict_sow(0, 1, &pred);
  EXPECT_EQ(pred.terminal_bay,
            static_cast<uint8_t>((bays[0].charge_units + 1) % 16));

  void_sower_reset();
  void_sower_free();
}

TEST(FfiBoundaryTest, ContinuousSimulationStressLeakTest) {
  void_sower_init(30, 0.2f);

  VoidSowerWaveConfigFFI cfg{
      .difficulty = 1,
      .random_seed = 9999,
      .core_budget = 20,
      .initial_velocity_y = 0.01f,
  };
  EXPECT_EQ(void_sower_generate_wave(&cfg), 1);

  // Run 5,000 steps of simulation with continuous injection
  for (int step = 0; step < 5000; ++step) {
    void_sower_step_simulation(0.01666f);
    if (step % 100 == 0) {
      void_sower_inject_core(static_cast<uint8_t>((step / 100) % 16), 1);
    }
  }

  void_sower_free();
}

}  // namespace void_sower
