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

#include <array>

#include "void_sower.h"

namespace void_sower::benchmarks {

static void BM_FFI_GetBays_FieldCopy(benchmark::State& state) {
  void_sower_init(32, 0.2f);
  std::array<VoidSowerBayFFI, 16> bays{};

  for (auto _ : state) {
    void_sower_get_bays(bays.data(), 16);
    benchmark::DoNotOptimize(bays.data());
  }
}
BENCHMARK(BM_FFI_GetBays_FieldCopy);

static void BM_FFI_GetEnemies_FieldCopy(benchmark::State& state) {
  void_sower_init(32, 0.2f);
  VoidSowerWaveConfigFFI cfg{
      .difficulty = 0,
      .random_seed = 42,
      .core_budget = 64,
      .initial_velocity_y = 0.02f,
  };
  void_sower_generate_wave(&cfg);

  std::array<VoidSowerEnemyFFI, 64> enemies{};
  for (auto _ : state) {
    uint32_t count = void_sower_get_enemies(enemies.data(), 64);
    benchmark::DoNotOptimize(count);
    benchmark::DoNotOptimize(enemies.data());
  }
}
BENCHMARK(BM_FFI_GetEnemies_FieldCopy);

static void BM_FFI_GetFullStateSnapshot(benchmark::State& state) {
  void_sower_init(32, 0.2f);
  VoidSowerWaveConfigFFI cfg{
      .difficulty = 0,
      .random_seed = 42,
      .core_budget = 64,
      .initial_velocity_y = 0.02f,
  };
  void_sower_generate_wave(&cfg);
  void_sower_inject_core(7, 1);
  void_sower_step_simulation(0.01666f);

  std::array<VoidSowerBayFFI, 16> bays{};
  std::array<VoidSowerEnemyFFI, 64> enemies{};
  std::array<VoidSowerLanceFFI, 16> lances{};
  std::array<VoidSowerFlakFFI, 32> flaks{};
  VoidSowerDreadnoughtFFI dread{};

  for (auto _ : state) {
    void_sower_get_bays(bays.data(), 16);
    uint32_t enemy_count = void_sower_get_enemies(enemies.data(), 64);
    uint32_t lance_count = void_sower_get_lances(lances.data(), 16);
    uint32_t flak_count = void_sower_get_flaks(flaks.data(), 32);
    void_sower_get_dreadnought_state(&dread);

    benchmark::DoNotOptimize(bays.data());
    benchmark::DoNotOptimize(enemy_count);
    benchmark::DoNotOptimize(lance_count);
    benchmark::DoNotOptimize(flak_count);
    benchmark::DoNotOptimize(dread);
  }
}
BENCHMARK(BM_FFI_GetFullStateSnapshot);

}  // namespace void_sower::benchmarks
