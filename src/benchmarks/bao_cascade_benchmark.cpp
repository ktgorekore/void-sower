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
#include "ecs/engine.h"

namespace void_sower::benchmarks {

using namespace void_sower::ecs;

static void BM_BaoSingleSowHop(benchmark::State& state) {
  uint8_t current_bay = 0;
  int8_t dir = 1;
  uint32_t charge_units = 10;
  for (auto _ : state) {
    current_bay = static_cast<uint8_t>((current_bay + dir + 16) & 0x0F);
    charge_units += 1;
    benchmark::DoNotOptimize(current_bay);
    benchmark::DoNotOptimize(charge_units);
  }
}
BENCHMARK(BM_BaoSingleSowHop);

static void BM_BaoCascadeRelay_FullChain(benchmark::State& state) {
  Engine engine;
  for (auto _ : state) {
    state.PauseTiming();
    engine.Initialize(64, 0.2f);
    auto& reg = engine.GetRegistry();
    auto view = reg.view<BatteryComponent>();
    for (auto entity : view) {
      auto& bay = view.get<BatteryComponent>(entity);
      if (bay.bay_index == 4) bay.charge_units = 8;
      if (bay.bay_index == 8) bay.charge_units = 6;
      if (bay.bay_index == 9) bay.charge_units = 4;
    }
    state.ResumeTiming();

    engine.InjectCore(3, 1);
    for (int step = 0; step < 30; ++step) {
      engine.Update(kFixedTimeStep);
      if (engine.GetSimulationState() == SimulationState::OrbitalIdle) break;
    }
  }
}
BENCHMARK(BM_BaoCascadeRelay_FullChain);

static void BM_BaoPredictSow_Throughput(benchmark::State& state) {
  Engine engine;
  engine.Initialize(32, 0.2f);
  auto& reg = engine.GetRegistry();
  auto view = reg.view<BatteryComponent>();
  for (auto entity : view) {
    auto& bay = view.get<BatteryComponent>(entity);
    bay.charge_units = (bay.bay_index * 3) % 11;
  }

  for (auto _ : state) {
    for (uint8_t bay = 0; bay < kTotalBays; ++bay) {
      auto pred_cw = engine.PredictSow(bay, 1);
      auto pred_ccw = engine.PredictSow(bay, -1);
      benchmark::DoNotOptimize(pred_cw);
      benchmark::DoNotOptimize(pred_ccw);
    }
  }
}
BENCHMARK(BM_BaoPredictSow_Throughput);

}  // namespace void_sower::benchmarks
