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

#include <memory>
#include <mutex>
#include <shared_mutex>

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

void void_sower_set_vlog_level(int32_t level) {
  absl::SetGlobalVLogLevel(level);
  LOG(INFO) << "[VoidSower Native] Abseil Global VLOG Level set to: " << level;
}

void void_sower_init(uint32_t starting_cores, float boundary_y) {
  std::unique_lock<std::shared_mutex> lock(g_engine_mutex);
  GetOrCreateEngine().Initialize(starting_cores, boundary_y);
}

int32_t void_sower_generate_wave(const VoidSowerWaveConfigFFI* config) {
  if (!config) return 0;
  std::unique_lock<std::shared_mutex> lock(g_engine_mutex);
  void_sower::ecs::WaveGeneratorConfig cfg{
      .difficulty =
          static_cast<void_sower::ecs::EncounterDifficulty>(config->difficulty),
      .random_seed = config->random_seed,
      .core_budget = config->core_budget,
      .initial_velocity_y = config->initial_velocity_y,
      .target_corridors_mask = 0xFF,
  };
  return GetOrCreateEngine().GenerateWave(cfg) ? 1 : 0;
}

int32_t void_sower_inject_core(uint8_t bay_index, int8_t direction) {
  std::unique_lock<std::shared_mutex> lock(g_engine_mutex);
  return GetOrCreateEngine().InjectCore(bay_index, direction) ? 1 : 0;
}

void void_sower_slide_dreadnought(float target_x) {
  std::unique_lock<std::shared_mutex> lock(g_engine_mutex);
  GetOrCreateEngine().SetTargetPositionX(target_x);
}

void void_sower_step_simulation(float delta_time) {
  std::unique_lock<std::shared_mutex> lock(g_engine_mutex);
  GetOrCreateEngine().Update(delta_time);
}

void void_sower_predict_sow(uint8_t start_bay, int8_t direction,
                            VoidSowerPredictionFFI* out_prediction) {
  if (!out_prediction) return;
  std::shared_lock<std::shared_mutex> lock(g_engine_mutex);
  auto res = GetOrCreateEngine().PredictSow(start_bay, direction);
  out_prediction->terminal_bay = res.terminal_bay;
  out_prediction->terminal_corridor = res.terminal_corridor;
  out_prediction->final_mass = res.final_mass;
  out_prediction->predicted_damage = res.predicted_damage;
  out_prediction->total_cascade_laps = res.total_cascade_laps;
  out_prediction->triggers_lance = res.triggers_lance ? 1 : 0;
  out_prediction->triggers_relay = res.triggers_relay ? 1 : 0;
}

void void_sower_get_bays(VoidSowerBayFFI* out_bays, uint32_t max_count) {
  if (!out_bays || max_count == 0) return;
  std::shared_lock<std::shared_mutex> lock(g_engine_mutex);
  const uint32_t count =
      std::min(max_count, static_cast<uint32_t>(void_sower::ecs::kTotalBays));
  std::array<void_sower::ecs::BatteryComponent, void_sower::ecs::kTotalBays>
      bays{};
  GetOrCreateEngine().GetBays(absl::MakeSpan(bays.data(), count));

  for (uint32_t i = 0; i < count; ++i) {
    out_bays[i] = VoidSowerBayFFI{
        .bay_index = bays[i].bay_index,
        .tier = bays[i].tier,
        .grid_column = bays[i].grid_column,
        .charge_units = bays[i].charge_units,
        .radial_position_rad = bays[i].radial_position_rad,
        .is_frontline = bays[i].is_frontline,
        .is_nyumba = bays[i].is_nyumba,
        .is_kichwa = bays[i].is_kichwa,
        .is_kimbi = bays[i].is_kimbi,
    };
  }
}

uint32_t void_sower_get_enemies(VoidSowerEnemyFFI* out_enemies,
                                uint32_t max_count) {
  if (!out_enemies || max_count == 0) return 0;
  std::shared_lock<std::shared_mutex> lock(g_engine_mutex);
  std::vector<void_sower::ecs::EnemyVesselComponent> enemies(max_count);
  uint32_t count =
      GetOrCreateEngine().GetEnemies(absl::MakeSpan(enemies.data(), max_count));

  for (uint32_t i = 0; i < count; ++i) {
    out_enemies[i] = VoidSowerEnemyFFI{
        .entity_id = enemies[i].entity_id,
        .assigned_corridor = enemies[i].assigned_corridor,
        .world_pos_x = enemies[i].world_pos_x,
        .world_pos_y = enemies[i].world_pos_y,
        .velocity_y = enemies[i].velocity_y,
        .current_shields = enemies[i].current_shields,
        .max_shields = enemies[i].max_shields,
        .current_hull = enemies[i].current_hull,
        .max_hull = enemies[i].max_hull,
        .vessel_type = enemies[i].vessel_type,
        .is_destroyed = enemies[i].is_destroyed,
    };
  }
  return count;
}

uint32_t void_sower_get_lances(VoidSowerLanceFFI* out_lances,
                               uint32_t max_count) {
  if (!out_lances || max_count == 0) return 0;
  std::shared_lock<std::shared_mutex> lock(g_engine_mutex);
  std::vector<void_sower::ecs::ParticleLanceComponent> lances(max_count);
  uint32_t count = GetOrCreateEngine().GetParticleLances(
      absl::MakeSpan(lances.data(), max_count));

  for (uint32_t i = 0; i < count; ++i) {
    out_lances[i] = VoidSowerLanceFFI{
        .firing_bay_index = lances[i].firing_bay_index,
        .origin_x = lances[i].origin_x,
        .origin_y = lances[i].origin_y,
        .beam_width = lances[i].beam_width,
        .sustained_duration = lances[i].sustained_duration,
        .remaining_duration = lances[i].remaining_duration,
        .total_damage = lances[i].total_damage,
        .active = lances[i].active,
    };
  }
  return count;
}

uint32_t void_sower_get_flaks(VoidSowerFlakFFI* out_flaks, uint32_t max_count) {
  if (!out_flaks || max_count == 0) return 0;
  std::shared_lock<std::shared_mutex> lock(g_engine_mutex);
  std::vector<void_sower::ecs::FlakBurstComponent> flaks(max_count);
  uint32_t count = GetOrCreateEngine().GetFlakBursts(
      absl::MakeSpan(flaks.data(), max_count));

  for (uint32_t i = 0; i < count; ++i) {
    out_flaks[i] = VoidSowerFlakFFI{
        .world_pos_x = flaks[i].world_pos_x,
        .world_pos_y = flaks[i].world_pos_y,
        .blast_radius = flaks[i].blast_radius,
        .area_damage = flaks[i].area_damage,
        .lifetime = flaks[i].lifetime,
        .remaining_lifetime = flaks[i].remaining_lifetime,
        .active = flaks[i].active,
    };
  }
  return count;
}

void void_sower_get_dreadnought_state(VoidSowerDreadnoughtFFI* out_state) {
  if (!out_state) return;
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
}

void void_sower_reset(void) {
  std::unique_lock<std::shared_mutex> lock(g_engine_mutex);
  GetOrCreateEngine().Reset();
}

void void_sower_free(void) {
  std::unique_lock<std::shared_mutex> lock(g_engine_mutex);
  g_engine.reset();
}
}
