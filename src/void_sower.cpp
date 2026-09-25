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

void void_sower_grant_cores(uint32_t count) noexcept {
  try {
    std::unique_lock<std::shared_mutex> lock(g_engine_mutex);
    GetOrCreateEngine().GrantCores(count);
  } catch (const std::exception& e) {
    LOG(ERROR) << "Exception in void_sower_grant_cores: " << e.what();
  } catch (...) {
    LOG(ERROR) << "Unknown exception in void_sower_grant_cores";
  }
}

void void_sower_set_lateral_drift(uint8_t enabled) noexcept {
  try {
    std::unique_lock<std::shared_mutex> lock(g_engine_mutex);
    GetOrCreateEngine().SetLateralDrift(enabled != 0);
  } catch (const std::exception& e) {
    LOG(ERROR) << "Exception in void_sower_set_lateral_drift: " << e.what();
  } catch (...) {
    LOG(ERROR) << "Unknown exception in void_sower_set_lateral_drift";
  }
}

int32_t void_sower_spawn_enemy(uint16_t corridor, float world_pos_y,
                               float velocity_y, float shields, float hull,
                               uint8_t vessel_type) noexcept {
  try {
    std::unique_lock<std::shared_mutex> lock(g_engine_mutex);
    return GetOrCreateEngine().SpawnEnemy(corridor, world_pos_y, velocity_y,
                                          shields, hull, vessel_type)
               ? 1
               : 0;
  } catch (const std::exception& e) {
    LOG(ERROR) << "Exception in void_sower_spawn_enemy: " << e.what();
    return 0;
  } catch (...) {
    LOG(ERROR) << "Unknown exception in void_sower_spawn_enemy";
    return 0;
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
    const auto& reg = GetOrCreateEngine().GetRegistry();
    auto view = reg.view<const void_sower::ecs::BatteryComponent>();
    uint32_t written = 0;
    for (auto entity : view) {
      if (written >= max_count) break;
      const auto& bay =
          view.get<const void_sower::ecs::BatteryComponent>(entity);
      if (bay.bay_index < max_count) {
        out_bays[bay.bay_index].bay_index = bay.bay_index;
        out_bays[bay.bay_index].tier = bay.tier;
        out_bays[bay.bay_index].grid_column = bay.grid_column;
        out_bays[bay.bay_index].charge_units = bay.charge_units;
        out_bays[bay.bay_index].radial_position_rad = bay.radial_position_rad;
        out_bays[bay.bay_index].is_frontline = bay.is_frontline;
        out_bays[bay.bay_index].is_nyumba = bay.is_nyumba;
        out_bays[bay.bay_index].is_kichwa = bay.is_kichwa;
        out_bays[bay.bay_index].is_kimbi = bay.is_kimbi;
        written++;
      }
    }
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
    const auto& reg = GetOrCreateEngine().GetRegistry();
    auto view = reg.view<const void_sower::ecs::EnemyVesselComponent>();
    uint32_t count = 0;
    for (auto entity : view) {
      if (count >= max_count) break;
      const auto& enemy =
          view.get<const void_sower::ecs::EnemyVesselComponent>(entity);
      out_enemies[count].entity_id = enemy.entity_id;
      out_enemies[count].assigned_corridor = enemy.assigned_corridor;
      out_enemies[count].world_pos_x = enemy.world_pos_x;
      out_enemies[count].world_pos_y = enemy.world_pos_y;
      out_enemies[count].velocity_y = enemy.velocity_y;
      out_enemies[count].current_shields = enemy.current_shields;
      out_enemies[count].max_shields = enemy.max_shields;
      out_enemies[count].current_hull = enemy.current_hull;
      out_enemies[count].max_hull = enemy.max_hull;
      out_enemies[count].vessel_type = enemy.vessel_type;
      out_enemies[count].is_destroyed = enemy.is_destroyed;
      count++;
    }
    return count;
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
    const auto& reg = GetOrCreateEngine().GetRegistry();
    auto view = reg.view<const void_sower::ecs::ParticleLanceComponent>();
    uint32_t count = 0;
    for (auto entity : view) {
      if (count >= max_count) break;
      const auto& lance =
          view.get<const void_sower::ecs::ParticleLanceComponent>(entity);
      if (lance.active != 0) {
        out_lances[count].firing_bay_index = lance.firing_bay_index;
        out_lances[count].origin_x = lance.origin_x;
        out_lances[count].origin_y = lance.origin_y;
        out_lances[count].beam_width = lance.beam_width;
        out_lances[count].sustained_duration = lance.sustained_duration;
        out_lances[count].remaining_duration = lance.remaining_duration;
        out_lances[count].total_damage = lance.total_damage;
        out_lances[count].active = lance.active;
        count++;
      }
    }
    return count;
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
    const auto& reg = GetOrCreateEngine().GetRegistry();
    auto view = reg.view<const void_sower::ecs::FlakBurstComponent>();
    uint32_t count = 0;
    for (auto entity : view) {
      if (count >= max_count) break;
      const auto& flak =
          view.get<const void_sower::ecs::FlakBurstComponent>(entity);
      if (flak.active != 0) {
        out_flaks[count].world_pos_x = flak.world_pos_x;
        out_flaks[count].world_pos_y = flak.world_pos_y;
        out_flaks[count].blast_radius = flak.blast_radius;
        out_flaks[count].area_damage = flak.area_damage;
        out_flaks[count].lifetime = flak.lifetime;
        out_flaks[count].remaining_lifetime = flak.remaining_lifetime;
        out_flaks[count].active = flak.active;
        count++;
      }
    }
    return count;
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

void void_sower_set_lance_alpha(float alpha_multiplier) noexcept {
  try {
    std::unique_lock<std::shared_mutex> lock(g_engine_mutex);
    GetOrCreateEngine().SetLanceAlphaMultiplier(alpha_multiplier);
  } catch (const std::exception& e) {
    LOG(ERROR) << "Exception in void_sower_set_lance_alpha: " << e.what();
  } catch (...) {
    LOG(ERROR) << "Unknown exception in void_sower_set_lance_alpha";
  }
}

void void_sower_restore_snapshot(const uint32_t* bay_charges,
                                 uint32_t reserve_cores,
                                 uint32_t total_score) noexcept {
  if (!bay_charges) return;
  try {
    std::unique_lock<std::shared_mutex> lock(g_engine_mutex);
    absl::Span<const uint32_t> charges_span(bay_charges,
                                            void_sower::ecs::kTotalBays);
    std::array<uint32_t, void_sower::ecs::kTotalBays> arr{};
    for (size_t i = 0; i < void_sower::ecs::kTotalBays; ++i) {
      arr[i] = charges_span[i];
    }
    GetOrCreateEngine().RestoreSnapshot(arr, reserve_cores, total_score);
  } catch (const std::exception& e) {
    LOG(ERROR) << "Exception in void_sower_restore_snapshot: " << e.what();
  } catch (...) {
    LOG(ERROR) << "Unknown exception in void_sower_restore_snapshot";
  }
}

int32_t void_sower_solve_tactical_step(uint8_t* out_bay, int8_t* out_direction,
                                       float* out_confidence,
                                       float* out_predicted_damage) noexcept {
  if (!out_bay || !out_direction) return 0;
  try {
    std::shared_lock<std::shared_mutex> lock(g_engine_mutex);
    return GetOrCreateEngine().SolveTacticalStep(
        out_bay, out_direction, out_confidence, out_predicted_damage);
  } catch (const std::exception& e) {
    LOG(ERROR) << "Exception in void_sower_solve_tactical_step: " << e.what();
    return 0;
  } catch (...) {
    LOG(ERROR) << "Unknown exception in void_sower_solve_tactical_step";
    return 0;
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
