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

/**
 * @brief Configures Abseil global VLOG verbosity level.
 * @param level Verbosity level integer (0 to disable, higher for verbose).
 */
FFI_PLUGIN_EXPORT void void_sower_set_vlog_level(int32_t level)
    VOID_SOWER_NOEXCEPT;

/**
 * @brief Initializes the native simulation engine and clears entity state.
 * @param starting_cores Initial count of reserve reactor cores.
 * @param boundary_y Normalized Y coordinate for the atmospheric breach boundary
 * line.
 */
FFI_PLUGIN_EXPORT void void_sower_init(uint32_t starting_cores,
                                       float boundary_y) VOID_SOWER_NOEXCEPT;

/**
 * @brief Procedurally generates an assault wave based on difficulty and seed.
 * @param config Pointer to wave generation parameters.
 * @return 1 on successful wave generation, 0 on failure or null config.
 */
FFI_PLUGIN_EXPORT int32_t void_sower_generate_wave(
    const VoidSowerWaveConfigFFI* config) VOID_SOWER_NOEXCEPT;

/**
 * @brief Injects a core from the reactor into a bay and executes the sowing
 * cascade.
 * @param bay_index Origin bay index (0 to 15).
 * @param direction Step direction (+1 for CW, -1 for CCW).
 * @return 1 if sowing cycle was initiated, 0 on invalid bay or empty reactor.
 */
FFI_PLUGIN_EXPORT int32_t
void_sower_inject_core(uint8_t bay_index, int8_t direction) VOID_SOWER_NOEXCEPT;

/**
 * @brief Sets the target lateral slide position of the dreadnought flagship.
 * @param target_x Normalized X coordinate along the orbital horizon [0.0, 1.0].
 */
FFI_PLUGIN_EXPORT void void_sower_slide_dreadnought(float target_x)
    VOID_SOWER_NOEXCEPT;

/**
 * @brief Advances the deterministic physics, spatial grid, and combat
 * simulation.
 * @param delta_time Elapsed step time in seconds (e.g. 1/60s).
 */
FFI_PLUGIN_EXPORT void void_sower_step_simulation(float delta_time)
    VOID_SOWER_NOEXCEPT;

/**
 * @brief Damages a specific capacitor conduit, deducting 1 core and discharging
 * energy.
 * @param bay_index Damaged capacitor bay index (0 to 15).
 */
FFI_PLUGIN_EXPORT void void_sower_damage_conduit(uint8_t bay_index)
    VOID_SOWER_NOEXCEPT;

/**
 * @brief Damages planetary atmosphere when hostile ordnance breaches the
 * perimeter.
 * @param penalty Core deduction penalty applied directly to the reactor.
 */
FFI_PLUGIN_EXPORT void void_sower_damage_atmosphere(uint32_t penalty)
    VOID_SOWER_NOEXCEPT;

/**
 * @brief Grants bonus reserve cores directly to the reactor core bank.
 * @param count Number of plasma cores to add to reactor reserve.
 */
FFI_PLUGIN_EXPORT void void_sower_grant_cores(uint32_t count)
    VOID_SOWER_NOEXCEPT;

/**
 * @brief Enables or disables evasive lateral drift behavior on descending
 * craft.
 * @param enabled 1 to activate lateral drift evasion, 0 to disable.
 */
FFI_PLUGIN_EXPORT void void_sower_set_lateral_drift(uint8_t enabled)
    VOID_SOWER_NOEXCEPT;

/**
 * @brief Deploys a single reinforcement hostile craft into an active corridor.
 * @param corridor Tactical grid corridor (0 to 7).
 * @param world_pos_y Initial vertical position along corridor.
 * @param velocity_y Descent speed in units per second.
 * @param shields Initial kinetic shield capacity.
 * @param hull Initial hull integrity points.
 * @param vessel_type Craft classification (0: Scout, 1: Raider, 2: Flagship).
 * @return 1 on successful deployment, 0 on capacity exhaustion.
 */
FFI_PLUGIN_EXPORT int32_t void_sower_spawn_enemy(
    uint16_t corridor, float world_pos_y, float velocity_y, float shields,
    float hull, uint8_t vessel_type) VOID_SOWER_NOEXCEPT;

/**
 * @brief Simulates a dry-run trajectory projection without mutating live match
 * state.
 * @param start_bay Origin capacitor bay index (0 to 15).
 * @param direction Sowing direction (+1 for CW, -1 for CCW).
 * @param out_prediction Pointer to output telemetry prediction struct.
 */
FFI_PLUGIN_EXPORT void void_sower_predict_sow(
    uint8_t start_bay, int8_t direction,
    VoidSowerPredictionFFI* out_prediction) VOID_SOWER_NOEXCEPT;

/**
 * @brief Exports current battery ring charges and role states into
 * pre-allocated memory.
 * @param out_bays Pointer to contiguous array of VoidSowerBayFFI structures.
 * @param max_count Maximum number of bay structures to write.
 */
FFI_PLUGIN_EXPORT void void_sower_get_bays(
    VoidSowerBayFFI* out_bays, uint32_t max_count) VOID_SOWER_NOEXCEPT;

/**
 * @brief Exports active enemy craft into pre-allocated memory buffer.
 * @param out_enemies Pointer to contiguous array of VoidSowerEnemyFFI
 * structures.
 * @param max_count Maximum buffer capacity for craft entries.
 * @return Total number of active enemy craft written to out_enemies.
 */
FFI_PLUGIN_EXPORT uint32_t void_sower_get_enemies(
    VoidSowerEnemyFFI* out_enemies, uint32_t max_count) VOID_SOWER_NOEXCEPT;

/**
 * @brief Exports active particle lance beam vectors into pre-allocated buffer.
 * @param out_lances Pointer to contiguous array of VoidSowerLanceFFI
 * structures.
 * @param max_count Maximum buffer capacity for lance entries.
 * @return Total number of active lances written to out_lances.
 */
FFI_PLUGIN_EXPORT uint32_t void_sower_get_lances(
    VoidSowerLanceFFI* out_lances, uint32_t max_count) VOID_SOWER_NOEXCEPT;

/**
 * @brief Exports active secondary flak burst zones into pre-allocated buffer.
 * @param out_flaks Pointer to contiguous array of VoidSowerFlakFFI structures.
 * @param max_count Maximum buffer capacity for flak entries.
 * @return Total number of active flaks written to out_flaks.
 */
FFI_PLUGIN_EXPORT uint32_t void_sower_get_flaks(
    VoidSowerFlakFFI* out_flaks, uint32_t max_count) VOID_SOWER_NOEXCEPT;

/**
 * @brief Exports overall dreadnought state, reserve cores, and simulation FSM
 * status.
 * @param out_state Pointer to output VoidSowerDreadnoughtFFI struct.
 */
FFI_PLUGIN_EXPORT void void_sower_get_dreadnought_state(
    VoidSowerDreadnoughtFFI* out_state) VOID_SOWER_NOEXCEPT;

/**
 * @brief Sets the chassis particle lance alpha multiplier for fleet damage
 * scaling.
 * @param alpha_multiplier Scaling factor applied to quadratic lance output.
 */
FFI_PLUGIN_EXPORT void void_sower_set_lance_alpha(float alpha_multiplier)
    VOID_SOWER_NOEXCEPT;

/**
 * @brief Restores combat simulation state from an archived turn snapshot.
 * @param bay_charges Pointer to 16-element array of bay charge values.
 * @param reserve_cores Restored reserve plasma core count.
 * @param total_score Restored match score.
 */
FFI_PLUGIN_EXPORT void void_sower_restore_snapshot(
    const uint32_t* bay_charges, uint32_t reserve_cores,
    uint32_t total_score) VOID_SOWER_NOEXCEPT;

/**
 * @brief Solves the optimal tactical move using native Monte Carlo Tree Search
 * lookahead.
 * @param out_bay Output pointer for recommended bay index (0 to 15).
 * @param out_direction Output pointer for recommended direction (+1 for CW, -1
 * for CCW).
 * @param out_confidence Output pointer for search confidence (0.0 to 1.0), or
 * nullptr.
 * @param out_predicted_damage Output pointer for estimated damage, or nullptr.
 * @return 1 on successful tactical solution found, 0 on failure or null
 * parameters.
 */
FFI_PLUGIN_EXPORT int32_t void_sower_solve_tactical_step(
    uint8_t* out_bay, int8_t* out_direction, float* out_confidence,
    float* out_predicted_damage) VOID_SOWER_NOEXCEPT;

/**
 * @brief Reinitializes the simulation engine with default baseline
 * configuration.
 */
FFI_PLUGIN_EXPORT void void_sower_reset(void) VOID_SOWER_NOEXCEPT;

/**
 * @brief Releases the global native simulation engine instance and frees
 * memory.
 */
FFI_PLUGIN_EXPORT void void_sower_free(void) VOID_SOWER_NOEXCEPT;

#ifdef __cplusplus
}
#endif

#endif  // VOID_SOWER_H_
