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

#include <atomic>
#include <cmath>
#include <thread>
#include <vector>

#include "void_sower.h"

namespace void_sower::tests {

TEST(FfiBoundaryTest, LifecycleAndStateExport) {
  void_sower_init(20, 0.2f);

  VoidSowerDreadnoughtFFI dread{};
  void_sower_get_dreadnought_state(&dread);
  EXPECT_EQ(dread.reserve_cores, 20);
  EXPECT_EQ(dread.cores_used, 0);

  // Generate a wave via FFI
  VoidSowerWaveConfigFFI cfg{
      .difficulty = 0,
      .reserved = {0, 0, 0},
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
            static_cast<uint8_t>((bays[0].charge_units + 1) & 0x0F));

  void_sower_reset();
  void_sower_free();
}

TEST(FfiBoundaryTest, ContinuousSimulationStressLeakTest) {
  void_sower_init(30, 0.2f);

  VoidSowerWaveConfigFFI cfg{
      .difficulty = 1,
      .reserved = {0, 0, 0},
      .random_seed = 9999,
      .core_budget = 20,
      .initial_velocity_y = 0.01f,
  };
  EXPECT_EQ(void_sower_generate_wave(&cfg), 1);

  // Run 5,000 steps of simulation with continuous injection
  for (int step = 0; step < 5000; ++step) {
    void_sower_step_simulation(0.01666f);
    if ((step & 0x3F) == 0) {
      void_sower_inject_core(static_cast<uint8_t>((step / 64) & 0x0F), 1);
    }
  }

  void_sower_free();
}

TEST(FfiBoundaryTest, NullPointerAndUninitializedEngineSafety) {
  // Ensure engine is freed first to test uninitialized engine safety
  void_sower_free();

  // Null output pointers should not crash
  void_sower_predict_sow(0, 1, nullptr);
  void_sower_get_bays(nullptr, 16);
  void_sower_get_enemies(nullptr, 16);
  void_sower_get_lances(nullptr, 16);
  void_sower_get_flaks(nullptr, 16);
  void_sower_get_dreadnought_state(nullptr);
  EXPECT_EQ(void_sower_solve_tactical_step(nullptr, nullptr, nullptr, nullptr),
            0);
  uint8_t out_bay = 0;
  int8_t out_dir = 0;
  float out_conf = 0.0f;
  float out_dmg = 0.0f;
  EXPECT_EQ(
      void_sower_solve_tactical_step(&out_bay, &out_dir, nullptr, &out_dmg), 0);
  EXPECT_EQ(
      void_sower_solve_tactical_step(&out_bay, &out_dir, &out_conf, nullptr),
      0);
  EXPECT_EQ(void_sower_generate_wave(nullptr), 0);
  void_sower_restore_snapshot(nullptr, 0, 10, 500);

  // Test lance alpha validation
  void_sower_set_lance_alpha(NAN);
  void_sower_set_lance_alpha(-1.0f);

  // Reading when g_engine is null should safely return empty/default values
  std::array<VoidSowerBayFFI, 16> bays{};
  void_sower_get_bays(bays.data(), 16);
  EXPECT_EQ(void_sower_get_enemies(nullptr, 0), 0);
  EXPECT_EQ(void_sower_get_lances(nullptr, 0), 0);
  EXPECT_EQ(void_sower_get_flaks(nullptr, 0), 0);

  // Re-initialize cleanly
  void_sower_init(24, 0.2f);
  void_sower_free();
}

TEST(FfiBoundaryTest, NaturallyAlignedStructMemoryLayout) {
  // Static compile-time assertions for 4-byte natural alignment
  static_assert(sizeof(VoidSowerBayFFI) == 16, "VoidSowerBayFFI size mismatch");
  static_assert(alignof(VoidSowerBayFFI) == 4,
                "VoidSowerBayFFI alignment mismatch");

  static_assert(sizeof(VoidSowerEnemyFFI) == 60,
                "VoidSowerEnemyFFI size mismatch");
  static_assert(alignof(VoidSowerEnemyFFI) == 4,
                "VoidSowerEnemyFFI alignment mismatch");

  static_assert(sizeof(VoidSowerLanceFFI) == 32,
                "VoidSowerLanceFFI size mismatch");
  static_assert(alignof(VoidSowerLanceFFI) == 4,
                "VoidSowerLanceFFI alignment mismatch");

  static_assert(sizeof(VoidSowerFlakFFI) == 28,
                "VoidSowerFlakFFI size mismatch");
  static_assert(alignof(VoidSowerFlakFFI) == 4,
                "VoidSowerFlakFFI alignment mismatch");

  static_assert(sizeof(VoidSowerDreadnoughtFFI) == 44,
                "VoidSowerDreadnoughtFFI size mismatch");
  static_assert(alignof(VoidSowerDreadnoughtFFI) == 4,
                "VoidSowerDreadnoughtFFI alignment mismatch");

  static_assert(sizeof(VoidSowerPredictionFFI) == 16,
                "VoidSowerPredictionFFI size mismatch");
  static_assert(alignof(VoidSowerPredictionFFI) == 4,
                "VoidSowerPredictionFFI alignment mismatch");

  static_assert(sizeof(VoidSowerWaveConfigFFI) == 16,
                "VoidSowerWaveConfigFFI size mismatch");
  static_assert(alignof(VoidSowerWaveConfigFFI) == 4,
                "VoidSowerWaveConfigFFI alignment mismatch");
}

TEST(FfiBoundaryTest, RestoreSnapshotBoundsRejection) {
  void_sower_init(20, 0.2f);

  // Null pointer rejection
  void_sower_restore_snapshot(nullptr, 0, 10, 100);

  // Truncated array safely clamped
  std::array<uint32_t, 4> short_charges = {5, 5, 5, 5};
  void_sower_restore_snapshot(short_charges.data(), short_charges.size(), 15,
                              200);

  VoidSowerDreadnoughtFFI dread{};
  void_sower_get_dreadnought_state(&dread);
  EXPECT_EQ(dread.reserve_cores, 15);
  EXPECT_EQ(dread.total_score, 200);

  void_sower_reset();
  void_sower_free();
}

TEST(FfiBoundaryTest, ConcurrentMultiThreadedReaders) {
  void_sower_init(32, 0.2f);

  VoidSowerWaveConfigFFI cfg{
      .difficulty = 1,
      .reserved = {0, 0, 0},
      .random_seed = 42,
      .core_budget = 24,
      .initial_velocity_y = 0.015f,
  };
  EXPECT_EQ(void_sower_generate_wave(&cfg), 1);

  std::atomic<bool> running{true};
  std::atomic<uint64_t> read_ops{0};

  // Launch 4 concurrent reader threads
  std::vector<std::thread> readers;
  for (int t = 0; t < 4; ++t) {
    readers.emplace_back([&running, &read_ops, t]() {
      std::array<VoidSowerBayFFI, 16> bays{};
      std::array<VoidSowerEnemyFFI, 32> enemies{};
      VoidSowerDreadnoughtFFI dread{};
      VoidSowerPredictionFFI pred{};

      while (running.load(std::memory_order_relaxed)) {
        void_sower_get_bays(bays.data(), 16);
        void_sower_get_enemies(enemies.data(), 32);
        void_sower_get_dreadnought_state(&dread);
        void_sower_predict_sow(static_cast<uint8_t>(t * 4), 1, &pred);

        uint8_t bay = 0;
        int8_t dir = 1;
        float conf = 0.0f;
        float dmg = 0.0f;
        void_sower_solve_tactical_step(&bay, &dir, &conf, &dmg);

        read_ops.fetch_add(1, std::memory_order_relaxed);
      }
    });
  }

  // Simulation thread executing updates and core injections
  for (int step = 0; step < 200; ++step) {
    void_sower_step_simulation(0.01666f);
    if ((step & 0x0F) == 0) {
      void_sower_inject_core(static_cast<uint8_t>((step / 16) & 0x0F), 1);
    }
    std::this_thread::sleep_for(std::chrono::microseconds(100));
  }

  running.store(false, std::memory_order_relaxed);
  for (auto &r : readers) {
    r.join();
  }

  EXPECT_GT(read_ops.load(), 500u);
  void_sower_free();
}

TEST(FfiBoundaryTest, AfricanStrategicFfiEndpoints) {
  void_sower_init(16, 0.2f);
  void_sower_set_dreadnought_target(0.3125f, 0.35f);
  EXPECT_EQ(void_sower_spawn_enemy(2, 0.50f, 0.01f, 50.0f, 150.0f, 1), 1);

  // Direct bay discharge on frontline bay 10 (Corridor 2)
  EXPECT_EQ(void_sower_discharge_bay(10, 1.5f), 1);
  // Invalid inner bay rejected
  EXPECT_EQ(void_sower_discharge_bay(2, 1.0f), 0);

  // Respawn target for Fanorona and Yoté endpoints
  EXPECT_EQ(void_sower_spawn_enemy(2, 0.45f, 0.01f, 50.0f, 400.0f, 1), 1);
  EXPECT_EQ(void_sower_trigger_fanorona_strike(1), 1);
  EXPECT_EQ(void_sower_trigger_fanorona_strike(0), 1);
  EXPECT_EQ(void_sower_cull_enemy(0), 1);

  void_sower_free();
}

TEST(FfiBoundaryTest, InitBoundaryYSanitizationAndStepDeltaClamping) {
  VoidSowerDreadnoughtFFI dread{};

  // NaN boundary_y falls back to 0.15f
  void_sower_init(16, NAN);
  void_sower_get_dreadnought_state(&dread);
  EXPECT_FLOAT_EQ(dread.boundary_line_y, 0.15f);
  void_sower_free();

  // +Infinity boundary_y falls back to 0.15f
  void_sower_init(16, INFINITY);
  void_sower_get_dreadnought_state(&dread);
  EXPECT_FLOAT_EQ(dread.boundary_line_y, 0.15f);
  void_sower_free();

  // Negative boundary_y falls back to 0.15f
  void_sower_init(16, -5.0f);
  void_sower_get_dreadnought_state(&dread);
  EXPECT_FLOAT_EQ(dread.boundary_line_y, 0.15f);
  void_sower_free();

  // Zero boundary_y falls back to 0.15f
  void_sower_init(16, 0.0f);
  void_sower_get_dreadnought_state(&dread);
  EXPECT_FLOAT_EQ(dread.boundary_line_y, 0.15f);
  void_sower_free();

  // Normalized > 0.55f clamps to 0.55f
  void_sower_init(16, 0.95f);
  void_sower_get_dreadnought_state(&dread);
  EXPECT_FLOAT_EQ(dread.boundary_line_y, 0.55f);
  void_sower_free();

  // Legacy pixel scale (> 1.0f, e.g. 220.0f) normalizes to 0.22f
  void_sower_init(16, 220.0f);
  void_sower_get_dreadnought_state(&dread);
  EXPECT_NEAR(dread.boundary_line_y, 0.22f, 1e-4f);

  // Spawn an enemy at Y = 0.80 with velocity_y = 0.10
  EXPECT_EQ(void_sower_spawn_enemy(3, 0.80f, 0.10f, 50.0f, 100.0f, 0), 1);
  std::array<VoidSowerEnemyFFI, 8> enemies{};
  ASSERT_EQ(void_sower_get_enemies(enemies.data(), enemies.size()), 1u);
  const float initial_y = enemies[0].world_pos_y;

  // NaN, Infinity, and negative delta_time are rejected without mutating state
  void_sower_step_simulation(NAN);
  void_sower_step_simulation(INFINITY);
  void_sower_step_simulation(-1.0f);
  ASSERT_EQ(void_sower_get_enemies(enemies.data(), enemies.size()), 1u);
  EXPECT_FLOAT_EQ(enemies[0].world_pos_y, initial_y);

  // Huge delta_time (10.0f) is clamped to 0.25f max step
  void_sower_step_simulation(10.0f);
  ASSERT_EQ(void_sower_get_enemies(enemies.data(), enemies.size()), 1u);
  EXPECT_TRUE(std::isfinite(enemies[0].world_pos_y));
  EXPECT_GT(enemies[0].world_pos_y, 0.50f);

  void_sower_free();
}

TEST(FfiBoundaryTest, InputSanitizationAndEnumBoundsValidation) {
  void_sower_init(20, 0.20f);

  // Invalid wave difficulty (> 2) and non-finite velocity rejected
  VoidSowerWaveConfigFFI bad_diff{
      .difficulty = 99,
      .reserved = {0, 0, 0},
      .random_seed = 42,
      .core_budget = 12,
      .initial_velocity_y = 0.02f,
  };
  EXPECT_EQ(void_sower_generate_wave(&bad_diff), 0);

  VoidSowerWaveConfigFFI nan_vel{
      .difficulty = 1,
      .reserved = {0, 0, 0},
      .random_seed = 42,
      .core_budget = 12,
      .initial_velocity_y = NAN,
  };
  EXPECT_EQ(void_sower_generate_wave(&nan_vel), 0);

  // Discharge bay rejects non-finite or non-positive damage_multiplier
  EXPECT_EQ(void_sower_discharge_bay(10, NAN), 0);
  EXPECT_EQ(void_sower_discharge_bay(10, INFINITY), 0);
  EXPECT_EQ(void_sower_discharge_bay(10, 0.0f), 0);
  EXPECT_EQ(void_sower_discharge_bay(10, -2.0f), 0);

  // Dreadnought slide & 2D target ignore non-finite coordinates
  void_sower_set_dreadnought_target(0.4f, 0.3f);
  void_sower_slide_dreadnought(NAN);
  void_sower_slide_dreadnought(INFINITY);
  void_sower_set_dreadnought_target(NAN, 0.4f);
  void_sower_set_dreadnought_target(0.4f, -INFINITY);
  VoidSowerDreadnoughtFFI dread{};
  void_sower_get_dreadnought_state(&dread);
  EXPECT_FLOAT_EQ(dread.target_position_x, 0.4f);
  EXPECT_FLOAT_EQ(dread.target_position_y, 0.3f);

  // Quest update ignores non-finite progress and status > 3
  void_sower_set_active_quest(1);
  void_sower_update_quest(0.5f, 1);
  void_sower_update_quest(NAN, 1);
  void_sower_update_quest(0.9f, 99);
  void_sower_get_dreadnought_state(&dread);
  EXPECT_FLOAT_EQ(dread.quest_progress, 0.5f);
  EXPECT_EQ(dread.quest_status, 1);

  // Spawn enemy rejects invalid vessel_type (> 2) and non-finite parameters
  EXPECT_EQ(void_sower_spawn_enemy(0, 0.8f, 0.02f, 20.0f, 100.0f, 5), 0);
  EXPECT_EQ(void_sower_spawn_enemy(0, NAN, 0.02f, 20.0f, 100.0f, 0), 0);
  EXPECT_EQ(void_sower_spawn_enemy(0, 0.8f, INFINITY, 20.0f, 100.0f, 0), 0);
  EXPECT_EQ(void_sower_spawn_enemy(0, 0.8f, 0.02f, -10.0f, 100.0f, 0), 0);
  EXPECT_EQ(void_sower_spawn_enemy(0, 0.8f, 0.02f, 20.0f, 0.0f, 0), 0);

  // Lance alpha handles +Inf and -Inf safely
  void_sower_set_lance_alpha(INFINITY);
  void_sower_set_lance_alpha(-INFINITY);

  void_sower_free();
}

TEST(FfiBoundaryTest, SolveTacticalStepAllowsNullOptionalPointers) {
  void_sower_init(24, 0.15f);
  EXPECT_EQ(void_sower_spawn_enemy(3, 0.65f, 0.02f, 25.0f, 100.0f, 0), 1);

  uint8_t bay = 255;
  int8_t dir = 0;
  float conf = -1.0f;
  float dmg = -1.0f;

  // Both optional pointers nullptr
  EXPECT_EQ(void_sower_solve_tactical_step(&bay, &dir, nullptr, nullptr), 1);
  EXPECT_LT(bay, 16u);
  EXPECT_TRUE(dir == 1 || dir == -1);

  // Only out_confidence provided
  EXPECT_EQ(void_sower_solve_tactical_step(&bay, &dir, &conf, nullptr), 1);
  EXPECT_GE(conf, 0.0f);
  EXPECT_LE(conf, 1.0f);

  // Only out_predicted_damage provided
  EXPECT_EQ(void_sower_solve_tactical_step(&bay, &dir, nullptr, &dmg), 1);
  EXPECT_GE(dmg, 0.0f);

  // Required pointers nullptr must return 0
  EXPECT_EQ(void_sower_solve_tactical_step(nullptr, &dir, nullptr, nullptr), 0);
  EXPECT_EQ(void_sower_solve_tactical_step(&bay, nullptr, nullptr, nullptr), 0);

  void_sower_free();
}

TEST(FfiBoundaryTest, RetainAndReleaseMultiClientLeaseSafety) {
  // Ensure clean state
  void_sower_free();

  // Client 1 retains and initializes
  void_sower_retain();
  void_sower_init(42, 0.20f);

  // Client 2 retains (e.g. secondary FfiVoidSowerEngine instance)
  void_sower_retain();

  // Client 2 releases its lease; Client 1 must remain intact
  void_sower_release();

  VoidSowerDreadnoughtFFI dread{};
  void_sower_get_dreadnought_state(&dread);
  EXPECT_EQ(dread.reserve_cores, 42u);
  EXPECT_FLOAT_EQ(dread.boundary_line_y, 0.20f);

  // Client 1 releases final lease; engine is destroyed
  void_sower_release();

  VoidSowerDreadnoughtFFI after_release{};
  void_sower_get_dreadnought_state(&after_release);
  EXPECT_EQ(after_release.reserve_cores, 0u);
}

}  // namespace void_sower::tests
