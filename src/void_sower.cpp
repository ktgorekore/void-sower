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
#include <cmath>
#include <exception>
#include <memory>
#include <mutex>
#include <shared_mutex>

#include "ecs/components.h"
#include "ecs/engine.h"

namespace {

std::unique_ptr<void_sower::ecs::Engine> g_engine = nullptr;
std::shared_mutex g_engine_mutex;
int32_t g_client_leases = 0;
int32_t g_init_leases = 0;

float SanitizeBoundaryY(float boundary_y) noexcept {
  if (!std::isfinite(boundary_y) || boundary_y <= 0.0f) {
    return 0.15f;
  }
  if (boundary_y > 1.0f) {
    boundary_y = boundary_y / 1000.0f;
  }
  return std::clamp(boundary_y, 0.05f, 0.55f);
}

// Must be called with a unique_lock holding g_engine_mutex.
void_sower::ecs::Engine &GetOrCreateEngineLocked() {
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
  } catch (const std::exception &e) {
    LOG(ERROR) << "Exception in void_sower_set_vlog_level: " << e.what();
  } catch (...) {
    LOG(ERROR) << "Unknown exception in void_sower_set_vlog_level";
  }
}

void void_sower_init(uint32_t starting_cores, float boundary_y) noexcept {
  const float safe_boundary_y = SanitizeBoundaryY(boundary_y);
  try {
    std::unique_lock<std::shared_mutex> lock(g_engine_mutex);
    if (g_client_leases == 0) {
      ++g_init_leases;
    }
    GetOrCreateEngineLocked().Initialize(starting_cores, safe_boundary_y);
  } catch (const std::exception &e) {
    LOG(ERROR) << "Exception in void_sower_init: " << e.what();
  } catch (...) {
    LOG(ERROR) << "Unknown exception in void_sower_init";
  }
}

int32_t void_sower_generate_wave(
    const VoidSowerWaveConfigFFI *config) noexcept {
  if (!config) return 0;
  if (config->difficulty > 2 || !std::isfinite(config->initial_velocity_y)) {
    return 0;
  }
  try {
    std::unique_lock<std::shared_mutex> lock(g_engine_mutex);
    void_sower::ecs::WaveGeneratorConfig cfg{
        .difficulty = static_cast<void_sower::ecs::EncounterDifficulty>(
            config->difficulty),
        .random_seed = config->random_seed,
        .core_budget = config->core_budget,
        .initial_velocity_y =
            std::clamp(std::abs(config->initial_velocity_y), 0.0f, 100.0f),
        .target_corridors_mask = 0xFF,
    };
    return GetOrCreateEngineLocked().GenerateWave(cfg) ? 1 : 0;
  } catch (const std::exception &e) {
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
    return GetOrCreateEngineLocked().InjectCore(bay_index, direction) ? 1 : 0;
  } catch (const std::exception &e) {
    LOG(ERROR) << "Exception in void_sower_inject_core: " << e.what();
    return 0;
  } catch (...) {
    LOG(ERROR) << "Unknown exception in void_sower_inject_core";
    return 0;
  }
}

int32_t void_sower_discharge_bay(uint8_t bay_index,
                                 float damage_multiplier) noexcept {
  if (!std::isfinite(damage_multiplier) || damage_multiplier <= 0.0f) {
    return 0;
  }
  damage_multiplier = std::clamp(damage_multiplier, 0.01f, 100.0f);
  try {
    std::unique_lock<std::shared_mutex> lock(g_engine_mutex);
    return GetOrCreateEngineLocked().DischargeBay(bay_index, damage_multiplier)
               ? 1
               : 0;
  } catch (const std::exception &e) {
    LOG(ERROR) << "Exception in void_sower_discharge_bay: " << e.what();
    return 0;
  } catch (...) {
    LOG(ERROR) << "Unknown exception in void_sower_discharge_bay";
    return 0;
  }
}

int32_t void_sower_trigger_fanorona_strike(uint8_t is_approach) noexcept {
  try {
    std::unique_lock<std::shared_mutex> lock(g_engine_mutex);
    return GetOrCreateEngineLocked().TriggerFanoronaStrike(is_approach != 0)
               ? 1
               : 0;
  } catch (const std::exception &e) {
    LOG(ERROR) << "Exception in void_sower_trigger_fanorona_strike: "
               << e.what();
    return 0;
  } catch (...) {
    LOG(ERROR) << "Unknown exception in void_sower_trigger_fanorona_strike";
    return 0;
  }
}

int32_t void_sower_cull_enemy(uint32_t entity_id) noexcept {
  try {
    std::unique_lock<std::shared_mutex> lock(g_engine_mutex);
    return GetOrCreateEngineLocked().CullEnemy(entity_id) ? 1 : 0;
  } catch (const std::exception &e) {
    LOG(ERROR) << "Exception in void_sower_cull_enemy: " << e.what();
    return 0;
  } catch (...) {
    LOG(ERROR) << "Unknown exception in void_sower_cull_enemy";
    return 0;
  }
}

void void_sower_slide_dreadnought(float target_x) noexcept {
  if (!std::isfinite(target_x)) return;
  target_x = std::clamp(target_x, 0.0f, 1.0f);
  try {
    std::unique_lock<std::shared_mutex> lock(g_engine_mutex);
    GetOrCreateEngineLocked().SetTargetPositionX(target_x);
  } catch (const std::exception &e) {
    LOG(ERROR) << "Exception in void_sower_slide_dreadnought: " << e.what();
  } catch (...) {
    LOG(ERROR) << "Unknown exception in void_sower_slide_dreadnought";
  }
}

void void_sower_set_dreadnought_target(float target_x,
                                       float target_y) noexcept {
  if (!std::isfinite(target_x) || !std::isfinite(target_y)) return;
  target_x = std::clamp(target_x, 0.0f, 1.0f);
  target_y = std::clamp(target_y, 0.05f, 0.65f);
  try {
    std::unique_lock<std::shared_mutex> lock(g_engine_mutex);
    GetOrCreateEngineLocked().SetTargetPosition(target_x, target_y);
  } catch (const std::exception &e) {
    LOG(ERROR) << "Exception in void_sower_set_dreadnought_target: "
               << e.what();
  } catch (...) {
    LOG(ERROR) << "Unknown exception in void_sower_set_dreadnought_target";
  }
}

void void_sower_set_active_quest(uint8_t quest_type) noexcept {
  try {
    std::unique_lock<std::shared_mutex> lock(g_engine_mutex);
    GetOrCreateEngineLocked().SetActiveQuest(quest_type);
  } catch (const std::exception &e) {
    LOG(ERROR) << "Exception in void_sower_set_active_quest: " << e.what();
  } catch (...) {
    LOG(ERROR) << "Unknown exception in void_sower_set_active_quest";
  }
}

void void_sower_update_quest(float progress, uint8_t status) noexcept {
  if (!std::isfinite(progress) || status > 3) return;
  progress = std::clamp(progress, 0.0f, 1.0f);
  try {
    std::unique_lock<std::shared_mutex> lock(g_engine_mutex);
    GetOrCreateEngineLocked().UpdateQuest(progress, status);
  } catch (const std::exception &e) {
    LOG(ERROR) << "Exception in void_sower_update_quest: " << e.what();
  } catch (...) {
    LOG(ERROR) << "Unknown exception in void_sower_update_quest";
  }
}

void void_sower_step_simulation(float delta_time) noexcept {
  if (!std::isfinite(delta_time) || delta_time < 0.0f) return;
  delta_time = std::clamp(delta_time, 0.0f, 0.25f);
  try {
    std::unique_lock<std::shared_mutex> lock(g_engine_mutex);
    GetOrCreateEngineLocked().Update(delta_time);
  } catch (const std::exception &e) {
    LOG(ERROR) << "Exception in void_sower_step_simulation: " << e.what();
  } catch (...) {
    LOG(ERROR) << "Unknown exception in void_sower_step_simulation";
  }
}

void void_sower_damage_conduit(uint8_t bay_index) noexcept {
  try {
    std::unique_lock<std::shared_mutex> lock(g_engine_mutex);
    GetOrCreateEngineLocked().DamageConduit(bay_index);
  } catch (const std::exception &e) {
    LOG(ERROR) << "Exception in void_sower_damage_conduit: " << e.what();
  } catch (...) {
    LOG(ERROR) << "Unknown exception in void_sower_damage_conduit";
  }
}

void void_sower_damage_atmosphere(uint32_t penalty) noexcept {
  try {
    std::unique_lock<std::shared_mutex> lock(g_engine_mutex);
    GetOrCreateEngineLocked().DamageAtmosphere(penalty);
  } catch (const std::exception &e) {
    LOG(ERROR) << "Exception in void_sower_damage_atmosphere: " << e.what();
  } catch (...) {
    LOG(ERROR) << "Unknown exception in void_sower_damage_atmosphere";
  }
}

void void_sower_grant_cores(uint32_t count) noexcept {
  try {
    std::unique_lock<std::shared_mutex> lock(g_engine_mutex);
    GetOrCreateEngineLocked().GrantCores(count);
  } catch (const std::exception &e) {
    LOG(ERROR) << "Exception in void_sower_grant_cores: " << e.what();
  } catch (...) {
    LOG(ERROR) << "Unknown exception in void_sower_grant_cores";
  }
}

void void_sower_set_lateral_drift(uint8_t enabled) noexcept {
  try {
    std::unique_lock<std::shared_mutex> lock(g_engine_mutex);
    GetOrCreateEngineLocked().SetLateralDrift(enabled != 0);
  } catch (const std::exception &e) {
    LOG(ERROR) << "Exception in void_sower_set_lateral_drift: " << e.what();
  } catch (...) {
    LOG(ERROR) << "Unknown exception in void_sower_set_lateral_drift";
  }
}

int32_t void_sower_spawn_enemy(uint16_t corridor, float world_pos_y,
                               float velocity_y, float shields, float hull,
                               uint8_t vessel_type) noexcept {
  if (vessel_type > 2 || !std::isfinite(world_pos_y) ||
      !std::isfinite(velocity_y) || !std::isfinite(shields) ||
      !std::isfinite(hull) || shields < 0.0f || hull <= 0.0f) {
    return 0;
  }
  try {
    std::unique_lock<std::shared_mutex> lock(g_engine_mutex);
    return GetOrCreateEngineLocked().SpawnEnemy(
               corridor, world_pos_y, velocity_y, shields, hull, vessel_type)
               ? 1
               : 0;
  } catch (const std::exception &e) {
    LOG(ERROR) << "Exception in void_sower_spawn_enemy: " << e.what();
    return 0;
  } catch (...) {
    LOG(ERROR) << "Unknown exception in void_sower_spawn_enemy";
    return 0;
  }
}

void void_sower_predict_sow(uint8_t start_bay, int8_t direction,
                            VoidSowerPredictionFFI *out_prediction) noexcept {
  if (!out_prediction) return;
  try {
    std::shared_lock<std::shared_mutex> lock(g_engine_mutex);
    if (!g_engine) return;
    auto res = g_engine->PredictSow(start_bay, direction);
    out_prediction->terminal_bay = res.terminal_bay;
    out_prediction->terminal_corridor = res.terminal_corridor;
    out_prediction->triggers_lance = res.triggers_lance ? 1 : 0;
    out_prediction->triggers_relay = res.triggers_relay ? 1 : 0;
    out_prediction->final_mass = res.final_mass;
    out_prediction->predicted_damage = res.predicted_damage;
    out_prediction->total_cascade_laps = res.total_cascade_laps;
    out_prediction->reserved[0] = 0;
    out_prediction->reserved[1] = 0;
  } catch (const std::exception &e) {
    LOG(ERROR) << "Exception in void_sower_predict_sow: " << e.what();
  } catch (...) {
    LOG(ERROR) << "Unknown exception in void_sower_predict_sow";
  }
}

void void_sower_get_bays(VoidSowerBayFFI *out_bays,
                         uint32_t max_count) noexcept {
  if (!out_bays || max_count == 0) return;
  try {
    std::shared_lock<std::shared_mutex> lock(g_engine_mutex);
    if (!g_engine) return;
    const auto &reg = g_engine->GetRegistry();
    auto view = reg.view<const void_sower::ecs::BatteryComponent>();
    for (auto entity : view) {
      const auto &bay =
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
      }
    }
  } catch (const std::exception &e) {
    LOG(ERROR) << "Exception in void_sower_get_bays: " << e.what();
  } catch (...) {
    LOG(ERROR) << "Unknown exception in void_sower_get_bays";
  }
}

uint32_t void_sower_get_enemies(VoidSowerEnemyFFI *out_enemies,
                                uint32_t max_count) noexcept {
  if (!out_enemies || max_count == 0) return 0;
  try {
    std::shared_lock<std::shared_mutex> lock(g_engine_mutex);
    if (!g_engine) return 0;
    const auto &reg = g_engine->GetRegistry();
    auto view = reg.view<const void_sower::ecs::EnemyVesselComponent>();
    uint32_t count = 0;
    // Pass 1: Prioritize living active enemies so combat telemetry never
    // starves living craft
    for (auto entity : view) {
      if (count >= max_count) break;
      const auto &enemy =
          view.get<const void_sower::ecs::EnemyVesselComponent>(entity);
      if (enemy.is_destroyed != 0) continue;
      out_enemies[count].entity_id = enemy.entity_id;
      out_enemies[count].assigned_corridor = enemy.assigned_corridor;
      out_enemies[count].reserved1 = 0;
      out_enemies[count].world_pos_x = enemy.world_pos_x;
      out_enemies[count].world_pos_y = enemy.world_pos_y;
      out_enemies[count].velocity_y = enemy.velocity_y;
      out_enemies[count].current_shields = enemy.current_shields;
      out_enemies[count].max_shields = enemy.max_shields;
      out_enemies[count].current_hull = enemy.current_hull;
      out_enemies[count].max_hull = enemy.max_hull;
      out_enemies[count].vessel_type = enemy.vessel_type;
      out_enemies[count].is_destroyed = 0;
      out_enemies[count].reserved2 = 0;
      out_enemies[count].world_pos_z = enemy.world_pos_z;
      out_enemies[count].bank_angle_rad = enemy.bank_angle_rad;
      out_enemies[count].pitch_angle_rad = enemy.pitch_angle_rad;
      out_enemies[count].warp_in_progress = enemy.warp_in_progress;
      out_enemies[count].behavior_mode = enemy.behavior_mode;
      out_enemies[count].reserved3[0] = 0;
      out_enemies[count].reserved3[1] = 0;
      out_enemies[count].reserved3[2] = 0;
      count++;
    }
    // Pass 2: Append recently destroyed enemies for particle detonation and
    // tactical siphon
    for (auto entity : view) {
      if (count >= max_count) break;
      const auto &enemy =
          view.get<const void_sower::ecs::EnemyVesselComponent>(entity);
      if (enemy.is_destroyed == 0) continue;
      out_enemies[count].entity_id = enemy.entity_id;
      out_enemies[count].assigned_corridor = enemy.assigned_corridor;
      out_enemies[count].reserved1 = 0;
      out_enemies[count].world_pos_x = enemy.world_pos_x;
      out_enemies[count].world_pos_y = enemy.world_pos_y;
      out_enemies[count].velocity_y = enemy.velocity_y;
      out_enemies[count].current_shields = enemy.current_shields;
      out_enemies[count].max_shields = enemy.max_shields;
      out_enemies[count].current_hull = enemy.current_hull;
      out_enemies[count].max_hull = enemy.max_hull;
      out_enemies[count].vessel_type = enemy.vessel_type;
      out_enemies[count].is_destroyed = 1;
      out_enemies[count].reserved2 = 0;
      out_enemies[count].world_pos_z = enemy.world_pos_z;
      out_enemies[count].bank_angle_rad = enemy.bank_angle_rad;
      out_enemies[count].pitch_angle_rad = enemy.pitch_angle_rad;
      out_enemies[count].warp_in_progress = enemy.warp_in_progress;
      out_enemies[count].behavior_mode = enemy.behavior_mode;
      out_enemies[count].reserved3[0] = 0;
      out_enemies[count].reserved3[1] = 0;
      out_enemies[count].reserved3[2] = 0;
      count++;
    }
    return count;
  } catch (const std::exception &e) {
    LOG(ERROR) << "Exception in void_sower_get_enemies: " << e.what();
    return 0;
  } catch (...) {
    LOG(ERROR) << "Unknown exception in void_sower_get_enemies";
    return 0;
  }
}

uint32_t void_sower_get_lances(VoidSowerLanceFFI *out_lances,
                               uint32_t max_count) noexcept {
  if (!out_lances || max_count == 0) return 0;
  try {
    std::shared_lock<std::shared_mutex> lock(g_engine_mutex);
    if (!g_engine) return 0;
    const auto &reg = g_engine->GetRegistry();
    auto view = reg.view<const void_sower::ecs::ParticleLanceComponent>();
    uint32_t count = 0;
    for (auto entity : view) {
      if (count >= max_count) break;
      const auto &lance =
          view.get<const void_sower::ecs::ParticleLanceComponent>(entity);
      if (lance.active != 0) {
        out_lances[count].firing_bay_index = lance.firing_bay_index;
        out_lances[count].reserved1[0] = 0;
        out_lances[count].reserved1[1] = 0;
        out_lances[count].reserved1[2] = 0;
        out_lances[count].origin_x = lance.origin_x;
        out_lances[count].origin_y = lance.origin_y;
        out_lances[count].beam_width = lance.beam_width;
        out_lances[count].sustained_duration = lance.sustained_duration;
        out_lances[count].remaining_duration = lance.remaining_duration;
        out_lances[count].total_damage = lance.total_damage;
        out_lances[count].active = lance.active;
        out_lances[count].reserved2[0] = 0;
        out_lances[count].reserved2[1] = 0;
        out_lances[count].reserved2[2] = 0;
        count++;
      }
    }
    return count;
  } catch (const std::exception &e) {
    LOG(ERROR) << "Exception in void_sower_get_lances: " << e.what();
    return 0;
  } catch (...) {
    LOG(ERROR) << "Unknown exception in void_sower_get_lances";
    return 0;
  }
}

uint32_t void_sower_get_flaks(VoidSowerFlakFFI *out_flaks,
                              uint32_t max_count) noexcept {
  if (!out_flaks || max_count == 0) return 0;
  try {
    std::shared_lock<std::shared_mutex> lock(g_engine_mutex);
    if (!g_engine) return 0;
    const auto &reg = g_engine->GetRegistry();
    auto view = reg.view<const void_sower::ecs::FlakBurstComponent>();
    uint32_t count = 0;
    for (auto entity : view) {
      if (count >= max_count) break;
      const auto &flak =
          view.get<const void_sower::ecs::FlakBurstComponent>(entity);
      if (flak.active != 0) {
        out_flaks[count].world_pos_x = flak.world_pos_x;
        out_flaks[count].world_pos_y = flak.world_pos_y;
        out_flaks[count].blast_radius = flak.blast_radius;
        out_flaks[count].area_damage = flak.area_damage;
        out_flaks[count].lifetime = flak.lifetime;
        out_flaks[count].remaining_lifetime = flak.remaining_lifetime;
        out_flaks[count].active = flak.active;
        out_flaks[count].reserved[0] = 0;
        out_flaks[count].reserved[1] = 0;
        out_flaks[count].reserved[2] = 0;
        count++;
      }
    }
    return count;
  } catch (const std::exception &e) {
    LOG(ERROR) << "Exception in void_sower_get_flaks: " << e.what();
    return 0;
  } catch (...) {
    LOG(ERROR) << "Unknown exception in void_sower_get_flaks";
    return 0;
  }
}

void void_sower_get_dreadnought_state(
    VoidSowerDreadnoughtFFI *out_state) noexcept {
  if (!out_state) return;
  try {
    std::shared_lock<std::shared_mutex> lock(g_engine_mutex);
    if (!g_engine) return;
    auto dread = g_engine->GetDreadnoughtState();
    out_state->orbital_position_x = dread.orbital_position_x;
    out_state->target_position_x = dread.target_position_x;
    out_state->orbital_position_y = dread.orbital_position_y;
    out_state->target_position_y = dread.target_position_y;
    out_state->boundary_line_y = dread.boundary_line_y;
    out_state->proximity_multiplier = dread.proximity_multiplier;
    out_state->reserve_cores = dread.reserve_cores;
    out_state->total_score = dread.total_score;
    out_state->cores_used = dread.cores_used;
    out_state->quest_progress = dread.quest_progress;
    out_state->is_cascading = dread.is_cascading;
    out_state->current_sim_state = dread.current_sim_state;
    out_state->active_quest_type = dread.active_quest_type;
    out_state->quest_status = dread.quest_status;
  } catch (const std::exception &e) {
    LOG(ERROR) << "Exception in void_sower_get_dreadnought_state: " << e.what();
  } catch (...) {
    LOG(ERROR) << "Unknown exception in void_sower_get_dreadnought_state";
  }
}

void void_sower_set_lance_alpha(float alpha_multiplier) noexcept {
  if (!std::isfinite(alpha_multiplier) || alpha_multiplier < 0.0f) {
    alpha_multiplier = 1.0f;
  }
  alpha_multiplier = std::clamp(alpha_multiplier, 0.0f, 10.0f);
  try {
    std::unique_lock<std::shared_mutex> lock(g_engine_mutex);
    GetOrCreateEngineLocked().SetLanceAlphaMultiplier(alpha_multiplier);
  } catch (const std::exception &e) {
    LOG(ERROR) << "Exception in void_sower_set_lance_alpha: " << e.what();
  } catch (...) {
    LOG(ERROR) << "Unknown exception in void_sower_set_lance_alpha";
  }
}

void void_sower_restore_snapshot(const uint32_t *bay_charges,
                                 size_t charges_length, uint32_t reserve_cores,
                                 uint32_t total_score) noexcept {
  if (!bay_charges || charges_length == 0) {
    LOG(WARNING)
        << "void_sower_restore_snapshot rejected null/empty bay_charges";
    return;
  }
  try {
    std::unique_lock<std::shared_mutex> lock(g_engine_mutex);
    const size_t copy_count = std::min(
        charges_length, static_cast<size_t>(void_sower::ecs::kTotalBays));
    std::array<uint32_t, void_sower::ecs::kTotalBays> arr{};
    for (size_t i = 0; i < copy_count; ++i) {
      arr[i] = bay_charges[i];
    }
    GetOrCreateEngineLocked().RestoreSnapshot(arr, reserve_cores, total_score);
  } catch (const std::exception &e) {
    LOG(ERROR) << "Exception in void_sower_restore_snapshot: " << e.what();
  } catch (...) {
    LOG(ERROR) << "Unknown exception in void_sower_restore_snapshot";
  }
}

int32_t void_sower_solve_tactical_step(uint8_t *out_bay, int8_t *out_direction,
                                       float *out_confidence,
                                       float *out_predicted_damage) noexcept {
  if (!out_bay || !out_direction) return 0;
  try {
    std::shared_lock<std::shared_mutex> lock(g_engine_mutex);
    if (!g_engine) return 0;
    return g_engine->SolveTacticalStep(out_bay, out_direction, out_confidence,
                                       out_predicted_damage);
  } catch (const std::exception &e) {
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
    if (g_engine) {
      g_engine->Reset();
    } else {
      g_engine = std::make_unique<void_sower::ecs::Engine>();
    }
  } catch (const std::exception &e) {
    LOG(ERROR) << "Exception in void_sower_reset: " << e.what();
  } catch (...) {
    LOG(ERROR) << "Unknown exception in void_sower_reset";
  }
}

void void_sower_retain(void) noexcept {
  try {
    std::unique_lock<std::shared_mutex> lock(g_engine_mutex);
    ++g_client_leases;
    (void)GetOrCreateEngineLocked();
  } catch (const std::exception &e) {
    LOG(ERROR) << "Exception in void_sower_retain: " << e.what();
  } catch (...) {
    LOG(ERROR) << "Unknown exception in void_sower_retain";
  }
}

void void_sower_release(void) noexcept {
  try {
    std::unique_lock<std::shared_mutex> lock(g_engine_mutex);
    if (g_client_leases > 0) {
      --g_client_leases;
    } else if (g_init_leases > 0) {
      --g_init_leases;
    }
    if (g_client_leases == 0 && g_init_leases == 0) {
      g_engine.reset();
    }
  } catch (const std::exception &e) {
    LOG(ERROR) << "Exception in void_sower_release: " << e.what();
  } catch (...) {
    LOG(ERROR) << "Unknown exception in void_sower_release";
  }
}

void void_sower_free(void) noexcept {
  try {
    std::unique_lock<std::shared_mutex> lock(g_engine_mutex);
    if (g_init_leases > 0) {
      --g_init_leases;
    } else if (g_client_leases > 0) {
      --g_client_leases;
    }
    if (g_client_leases == 0 && g_init_leases == 0) {
      g_engine.reset();
    }
  } catch (const std::exception &e) {
    LOG(ERROR) << "Exception in void_sower_free: " << e.what();
  } catch (...) {
    LOG(ERROR) << "Unknown exception in void_sower_free";
  }
}

}  // extern "C"
