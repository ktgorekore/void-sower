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

#ifndef VOID_SOWER_H_
#define VOID_SOWER_H_

#include <stdint.h>

#if defined(_WIN32)
#define FFI_PLUGIN_EXPORT __declspec(dllexport)
#else
#define FFI_PLUGIN_EXPORT __attribute__((visibility("default")))
#endif

#ifdef __cplusplus
extern "C" {
#endif

#pragma pack(push, 1)

/**
 * @brief Flat C representation of a single capacitor bay.
 */
typedef struct {
  uint8_t bay_index;          ///< 0 to 15
  uint8_t tier;               ///< 0: Inner, 1: Outer
  uint16_t grid_column;       ///< 0 to 7
  uint32_t charge_units;      ///< Accumulated plasma mass (M)
  float radial_position_rad;  ///< Radial angle along hull ring
  uint8_t is_frontline;       ///< 1 if outer frontline, 0 if inner
  uint8_t is_nyumba;          ///< 1 if Nyumba super-capacitor
  uint8_t is_kichwa;          ///< 1 if Kichwa vector conduit
  uint8_t is_kimbi;           ///< 1 if Kimbi deflection chamber
} VoidSowerBayFFI;

/**
 * @brief Flat C representation of an enemy assault craft.
 */
typedef struct {
  uint32_t entity_id;
  uint16_t assigned_corridor;
  float world_pos_x;
  float world_pos_y;
  float velocity_y;
  float current_shields;
  float max_shields;
  float current_hull;
  float max_hull;
  uint8_t vessel_type;
  uint8_t is_destroyed;
} VoidSowerEnemyFFI;

/**
 * @brief Flat C representation of an active particle lance beam.
 */
typedef struct {
  uint8_t firing_bay_index;
  float origin_x;
  float origin_y;
  float beam_width;
  float sustained_duration;
  float remaining_duration;
  float total_damage;
  uint8_t active;
} VoidSowerLanceFFI;

/**
 * @brief Flat C representation of a secondary radial flak burst.
 */
typedef struct {
  float world_pos_x;
  float world_pos_y;
  float blast_radius;
  float area_damage;
  float lifetime;
  float remaining_lifetime;
  uint8_t active;
} VoidSowerFlakFFI;

/**
 * @brief Flat C representation of dreadnought state.
 */
typedef struct {
  float orbital_position_x;
  float target_position_x;
  uint32_t reserve_cores;
  float boundary_line_y;
  uint8_t is_cascading;
  uint32_t total_score;
  uint8_t current_sim_state;
  uint32_t cores_used;
} VoidSowerDreadnoughtFFI;

/**
 * @brief Flat C representation of predictive targeting telemetry.
 */
typedef struct {
  uint8_t terminal_bay;
  int8_t terminal_corridor;
  uint32_t final_mass;
  float predicted_damage;
  uint16_t total_cascade_laps;
  uint8_t triggers_lance;
  uint8_t triggers_relay;
} VoidSowerPredictionFFI;

/**
 * @brief Flat C configuration for procedural wave generation.
 */
typedef struct {
  uint8_t
      difficulty;  ///< 0: SectorPatrol, 1: PlanetarySiege, 2: FlagshipBastion
  uint32_t random_seed;
  uint32_t core_budget;
  float initial_velocity_y;
} VoidSowerWaveConfigFFI;

#pragma pack(pop)

#ifdef __cplusplus
#define VOID_SOWER_NOEXCEPT noexcept
#else
#define VOID_SOWER_NOEXCEPT
#endif

FFI_PLUGIN_EXPORT void void_sower_set_vlog_level(int32_t level)
    VOID_SOWER_NOEXCEPT;
FFI_PLUGIN_EXPORT void void_sower_init(uint32_t starting_cores,
                                       float boundary_y) VOID_SOWER_NOEXCEPT;
FFI_PLUGIN_EXPORT int32_t void_sower_generate_wave(
    const VoidSowerWaveConfigFFI* config) VOID_SOWER_NOEXCEPT;
FFI_PLUGIN_EXPORT int32_t
void_sower_inject_core(uint8_t bay_index, int8_t direction) VOID_SOWER_NOEXCEPT;
FFI_PLUGIN_EXPORT void void_sower_slide_dreadnought(float target_x)
    VOID_SOWER_NOEXCEPT;
FFI_PLUGIN_EXPORT void void_sower_step_simulation(float delta_time)
    VOID_SOWER_NOEXCEPT;
FFI_PLUGIN_EXPORT void void_sower_damage_conduit(uint8_t bay_index)
    VOID_SOWER_NOEXCEPT;
FFI_PLUGIN_EXPORT void void_sower_damage_atmosphere(uint32_t penalty)
    VOID_SOWER_NOEXCEPT;
FFI_PLUGIN_EXPORT void void_sower_predict_sow(
    uint8_t start_bay, int8_t direction,
    VoidSowerPredictionFFI* out_prediction) VOID_SOWER_NOEXCEPT;
FFI_PLUGIN_EXPORT void void_sower_get_bays(
    VoidSowerBayFFI* out_bays, uint32_t max_count) VOID_SOWER_NOEXCEPT;
FFI_PLUGIN_EXPORT uint32_t void_sower_get_enemies(
    VoidSowerEnemyFFI* out_enemies, uint32_t max_count) VOID_SOWER_NOEXCEPT;
FFI_PLUGIN_EXPORT uint32_t void_sower_get_lances(
    VoidSowerLanceFFI* out_lances, uint32_t max_count) VOID_SOWER_NOEXCEPT;
FFI_PLUGIN_EXPORT uint32_t void_sower_get_flaks(
    VoidSowerFlakFFI* out_flaks, uint32_t max_count) VOID_SOWER_NOEXCEPT;
FFI_PLUGIN_EXPORT void void_sower_get_dreadnought_state(
    VoidSowerDreadnoughtFFI* out_state) VOID_SOWER_NOEXCEPT;
FFI_PLUGIN_EXPORT void void_sower_reset(void) VOID_SOWER_NOEXCEPT;
FFI_PLUGIN_EXPORT void void_sower_free(void) VOID_SOWER_NOEXCEPT;

#ifdef __cplusplus
}
#endif

#endif  // VOID_SOWER_H_
