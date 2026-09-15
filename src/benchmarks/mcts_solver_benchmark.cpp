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

#include "ecs/engine.h"
#include "ecs/systems/mcts_solver.h"

namespace void_sower::benchmarks {

using namespace void_sower::ecs;

static void BM_MctsSolver_SingleRollout(benchmark::State& state) {
  Engine engine;
  engine.Initialize(20, 0.2f);
  WaveGeneratorConfig config{
      .difficulty = EncounterDifficulty::SectorPatrol,
      .random_seed = 42,
      .core_budget = 16,
      .initial_velocity_y = 0.02f,
      .target_corridors_mask = 0xFF,
  };
  engine.GenerateWave(config);

  MctsSolver solver(engine.GetRegistry());
  for (auto _ : state) {
    auto res = solver.EvaluateSolvability(1, 6);
    benchmark::DoNotOptimize(res.is_solvable);
    benchmark::DoNotOptimize(res.simulated_rollouts);
  }
}
BENCHMARK(BM_MctsSolver_SingleRollout);

static void BM_MctsSolver_FullSearch_400Rollouts(benchmark::State& state) {
  Engine engine;
  engine.Initialize(20, 0.2f);
  WaveGeneratorConfig config{
      .difficulty = EncounterDifficulty::SectorPatrol,
      .random_seed = 42,
      .core_budget = 16,
      .initial_velocity_y = 0.02f,
      .target_corridors_mask = 0xFF,
  };
  engine.GenerateWave(config);

  MctsSolver solver(engine.GetRegistry());
  for (auto _ : state) {
    auto res = solver.EvaluateSolvability(400, 6);
    benchmark::DoNotOptimize(res.is_solvable);
    benchmark::DoNotOptimize(res.simulated_rollouts);
  }
}
BENCHMARK(BM_MctsSolver_FullSearch_400Rollouts);

}  // namespace void_sower::benchmarks
