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

#include "void_sower.h"

#include <absl/log/globals.h>
#include <absl/log/log.h>
#include <absl/types/span.h>

#include <algorithm>
#include <exception>
#include <memory>
#include <mutex>
#include <shared_mutex>

#include "ecs/components.h"
#include "ecs/engine.h"

// Static layout assertions guaranteeing zero-copy safety
static_assert(sizeof(VoidSowerBayFFI) ==
                  sizeof(void_sower::ecs::BatteryComponent),
              "VoidSowerBayFFI and BatteryComponent size mismatch");
static_assert(sizeof(VoidSowerEnemyFFI) ==
                  sizeof(void_sower::ecs::EnemyVesselComponent),
              "VoidSowerEnemyFFI and EnemyVesselComponent size mismatch");
static_assert(sizeof(VoidSowerLanceFFI) ==
                  sizeof(void_sower::ecs::ParticleLanceComponent),
              "VoidSowerLanceFFI and ParticleLanceComponent size mismatch");
static_assert(sizeof(VoidSowerFlakFFI) ==
                  sizeof(void_sower::ecs::FlakBurstComponent),
              "VoidSowerFlakFFI and FlakBurstComponent size mismatch");
static_assert(
    sizeof(VoidSowerDreadnoughtFFI) ==
        sizeof(void_sower::ecs::DreadnoughtStateComponent),
    "VoidSowerDreadnoughtFFI and DreadnoughtStateComponent size mismatch");

namespace {

std::unique_ptr<void_sower::ecs::Engine> g_engine = nullptr;
std::shared_mutex g_engine_mutex;

void_sower::ecs::Engine& GetOrCreateEngine() {
  if (!g_engine) {
    g_engine = std::make_unique<void_sower::ecs::Engine>();
  }
  return *g_engine;
}

}  // namespace

extern "C" {

void void_sower_set_vlog_level(int32_t level) noexcept {
  try {
    absl::SetGlobalVLogLevel(level);
    LOG(INFO) << "[VoidSower Native] Abseil Global VLOG Level set to: "
              << level;
  } catch (const std::exception& e) {
    LOG(ERROR) << "Exception in void_sower_set_vlog_level: " << e.what();
  } catch (...) {
    LOG(ERROR) << "Unknown exception in void_sower_set_vlog_level";
  }
}

void void_sower_init(uint32_t starting_cores, float boundary_y) noexcept {
  try {
    std::unique_lock<std::shared_mutex> lock(g_engine_mutex);
    GetOrCreateEngine().Initialize(starting_cores, boundary_y);
  } catch (const std::exception& e) {
    LOG(ERROR) << "Exception in void_sower_init: " << e.what();
  } catch (...) {
    LOG(ERROR) << "Unknown exception in void_sower_init";
  }
}

int32_t void_sower_generate_wave(
    const VoidSowerWaveConfigFFI* config) noexcept {
  if (!config) return 0;
  try {
    std::unique_lock<std::shared_mutex> lock(g_engine_mutex);
    void_sower::ecs::WaveGeneratorConfig cfg{
        .difficulty = static_cast<void_sower::ecs::EncounterDifficulty>(
            config->difficulty),
        .random_seed = config->random_seed,
        .core_budget = config->core_budget,
        .initial_velocity_y = config->initial_velocity_y,
        .target_corridors_mask = 0xFF,
    };
    return GetOrCreateEngine().GenerateWave(cfg) ? 1 : 0;
  } catch (const std::exception& e) {
    LOG(ERROR) << "Exception in void_sower_generate_wave: " << e.what();
    return 0;
  } catch (...) {
    LOG(ERROR) << "Unknown exception in void_sower_generate_wave";
    return 0;
  }
}

int32_t void_sower_inject_core(uint8_t bay_index, int8_t direction) noexcept {
  try {
    std::unique_lock<std::shared_mutex> lock(g_engine_mutex);
    return GetOrCreateEngine().InjectCore(bay_index, direction) ? 1 : 0;
  } catch (const std::exception& e) {
    LOG(ERROR) << "Exception in void_sower_inject_core: " << e.what();
    return 0;
  } catch (...) {
    LOG(ERROR) << "Unknown exception in void_sower_inject_core";
    return 0;
  }
}

void void_sower_slide_dreadnought(float target_x) noexcept {
  try {
    std::unique_lock<std::shared_mutex> lock(g_engine_mutex);
    GetOrCreateEngine().SetTargetPositionX(target_x);
  } catch (const std::exception& e) {
    LOG(ERROR) << "Exception in void_sower_slide_dreadnought: " << e.what();
  } catch (...) {
    LOG(ERROR) << "Unknown exception in void_sower_slide_dreadnought";
  }
}

void void_sower_step_simulation(float delta_time) noexcept {
  try {
    std::unique_lock<std::shared_mutex> lock(g_engine_mutex);
    GetOrCreateEngine().Update(delta_time);
  } catch (const std::exception& e) {
    LOG(ERROR) << "Exception in void_sower_step_simulation: " << e.what();
  } catch (...) {
    LOG(ERROR) << "Unknown exception in void_sower_step_simulation";
  }
}

void void_sower_damage_conduit(uint8_t bay_index) noexcept {
  try {
    std::unique_lock<std::shared_mutex> lock(g_engine_mutex);
    GetOrCreateEngine().DamageConduit(bay_index);
  } catch (const std::exception& e) {
    LOG(ERROR) << "Exception in void_sower_damage_conduit: " << e.what();
  } catch (...) {
    LOG(ERROR) << "Unknown exception in void_sower_damage_conduit";
  }
}

void void_sower_damage_atmosphere(uint32_t penalty) noexcept {
  try {
    std::unique_lock<std::shared_mutex> lock(g_engine_mutex);
    GetOrCreateEngine().DamageAtmosphere(penalty);
  } catch (const std::exception& e) {
    LOG(ERROR) << "Exception in void_sower_damage_atmosphere: " << e.what();
  } catch (...) {
    LOG(ERROR) << "Unknown exception in void_sower_damage_atmosphere";
  }
}

void void_sower_predict_sow(uint8_t start_bay, int8_t direction,
                            VoidSowerPredictionFFI* out_prediction) noexcept {
  if (!out_prediction) return;
  try {
    std::shared_lock<std::shared_mutex> lock(g_engine_mutex);
    auto res = GetOrCreateEngine().PredictSow(start_bay, direction);
    out_prediction->terminal_bay = res.terminal_bay;
    out_prediction->terminal_corridor = res.terminal_corridor;
    out_prediction->final_mass = res.final_mass;
    out_prediction->predicted_damage = res.predicted_damage;
    out_prediction->total_cascade_laps = res.total_cascade_laps;
    out_prediction->triggers_lance = res.triggers_lance ? 1 : 0;
    out_prediction->triggers_relay = res.triggers_relay ? 1 : 0;
  } catch (const std::exception& e) {
    LOG(ERROR) << "Exception in void_sower_predict_sow: " << e.what();
  } catch (...) {
    LOG(ERROR) << "Unknown exception in void_sower_predict_sow";
  }
}

void void_sower_get_bays(VoidSowerBayFFI* out_bays,
                         uint32_t max_count) noexcept {
  if (!out_bays || max_count == 0) return;
  try {
    std::shared_lock<std::shared_mutex> lock(g_engine_mutex);
    const uint32_t count =
        std::min(max_count, static_cast<uint32_t>(void_sower::ecs::kTotalBays));
    auto span = absl::MakeSpan(
        reinterpret_cast<void_sower::ecs::BatteryComponent*>(out_bays), count);
    GetOrCreateEngine().GetBays(span);
  } catch (const std::exception& e) {
    LOG(ERROR) << "Exception in void_sower_get_bays: " << e.what();
  } catch (...) {
    LOG(ERROR) << "Unknown exception in void_sower_get_bays";
  }
}

uint32_t void_sower_get_enemies(VoidSowerEnemyFFI* out_enemies,
                                uint32_t max_count) noexcept {
  if (!out_enemies || max_count == 0) return 0;
  try {
    std::shared_lock<std::shared_mutex> lock(g_engine_mutex);
    auto span = absl::MakeSpan(
        reinterpret_cast<void_sower::ecs::EnemyVesselComponent*>(out_enemies),
        max_count);
    return GetOrCreateEngine().GetEnemies(span);
  } catch (const std::exception& e) {
    LOG(ERROR) << "Exception in void_sower_get_enemies: " << e.what();
    return 0;
  } catch (...) {
    LOG(ERROR) << "Unknown exception in void_sower_get_enemies";
    return 0;
  }
}

uint32_t void_sower_get_lances(VoidSowerLanceFFI* out_lances,
                               uint32_t max_count) noexcept {
  if (!out_lances || max_count == 0) return 0;
  try {
    std::shared_lock<std::shared_mutex> lock(g_engine_mutex);
    auto span = absl::MakeSpan(
        reinterpret_cast<void_sower::ecs::ParticleLanceComponent*>(out_lances),
        max_count);
    return GetOrCreateEngine().GetParticleLances(span);
  } catch (const std::exception& e) {
    LOG(ERROR) << "Exception in void_sower_get_lances: " << e.what();
    return 0;
  } catch (...) {
    LOG(ERROR) << "Unknown exception in void_sower_get_lances";
    return 0;
  }
}

uint32_t void_sower_get_flaks(VoidSowerFlakFFI* out_flaks,
                              uint32_t max_count) noexcept {
  if (!out_flaks || max_count == 0) return 0;
  try {
    std::shared_lock<std::shared_mutex> lock(g_engine_mutex);
    auto span = absl::MakeSpan(
        reinterpret_cast<void_sower::ecs::FlakBurstComponent*>(out_flaks),
        max_count);
    return GetOrCreateEngine().GetFlakBursts(span);
  } catch (const std::exception& e) {
    LOG(ERROR) << "Exception in void_sower_get_flaks: " << e.what();
    return 0;
  } catch (...) {
    LOG(ERROR) << "Unknown exception in void_sower_get_flaks";
    return 0;
  }
}

void void_sower_get_dreadnought_state(
    VoidSowerDreadnoughtFFI* out_state) noexcept {
  if (!out_state) return;
  try {
    std::shared_lock<std::shared_mutex> lock(g_engine_mutex);
    auto dread = GetOrCreateEngine().GetDreadnoughtState();
    out_state->orbital_position_x = dread.orbital_position_x;
    out_state->target_position_x = dread.target_position_x;
    out_state->reserve_cores = dread.reserve_cores;
    out_state->boundary_line_y = dread.boundary_line_y;
    out_state->is_cascading = dread.is_cascading;
    out_state->total_score = dread.total_score;
    out_state->current_sim_state = dread.current_sim_state;
    out_state->cores_used = dread.cores_used;
  } catch (const std::exception& e) {
    LOG(ERROR) << "Exception in void_sower_get_dreadnought_state: " << e.what();
  } catch (...) {
    LOG(ERROR) << "Unknown exception in void_sower_get_dreadnought_state";
  }
}

void void_sower_reset(void) noexcept {
  try {
    std::unique_lock<std::shared_mutex> lock(g_engine_mutex);
    GetOrCreateEngine().Reset();
  } catch (const std::exception& e) {
    LOG(ERROR) << "Exception in void_sower_reset: " << e.what();
  } catch (...) {
    LOG(ERROR) << "Unknown exception in void_sower_reset";
  }
}

void void_sower_free(void) noexcept {
  try {
    std::unique_lock<std::shared_mutex> lock(g_engine_mutex);
    g_engine.reset();
  } catch (const std::exception& e) {
    LOG(ERROR) << "Exception in void_sower_free: " << e.what();
  } catch (...) {
    LOG(ERROR) << "Unknown exception in void_sower_free";
  }
}

}  // extern "C"
