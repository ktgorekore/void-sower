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

#ifndef VOID_SOWER_ECS_COMPONENTS_H_
#define VOID_SOWER_ECS_COMPONENTS_H_

#include <cstddef>
#include <cstdint>

namespace void_sower::ecs {

/// Total number of capacitor bays around the dreadnought hull ring buffer.
inline constexpr uint8_t kTotalBays = 16;

/// Number of bays in the inner reservoir ring (Bays 0 to 7).
inline constexpr uint8_t kInnerBaysCount = 8;

/// Number of bays in the outer frontline battery ring (Bays 8 to 15).
inline constexpr uint8_t kOuterBaysCount = 8;

/// Number of vertical attack corridors matching the frontline batteries.
inline constexpr uint8_t kCorridorCount = 8;

/// Baseline focal damage coefficient (alpha) for quadratic particle lance
/// calculation: D = alpha * M^2.
inline constexpr float kAlphaLanceDamage = 100.0f;

/// Baseline flak dispersion coefficient (beta) for radial flak bursts: D_flak =
/// beta * sqrt(M').
inline constexpr float kBetaFlakDamage = 25.0f;

/// Fixed simulation step frequency (60 Hz).
inline constexpr float kFixedTimeStep = 1.0f / 60.0f;

/// Maximum entities allowed per spatial grid corridor bucket.
inline constexpr uint16_t kMaxBucketOccupants = 32;

/// Maximum active lances rendered concurrently.
inline constexpr uint16_t kMaxConcurrentLances = 8;

/// Maximum active flak bursts rendered concurrently.
inline constexpr uint16_t kMaxConcurrentFlaks = 32;

/// Maximum enemy combatants on screen simultaneously.
inline constexpr uint16_t kMaxEnemiesOnScreen = 64;

/// Dreadnought battery chamber tier classification.
enum class BatteryTier : uint8_t {
  InnerReservoir =
      0,  ///< Bays 0 - 7: High-capacity storage and internal relay routing.
  OuterFrontline = 1  ///< Bays 8 - 15: Direct corridor alignment and particle
                      ///< lance emission.
};

/// Deterministic 60 Hz Finite State Machine states.
enum class SimulationState : uint8_t {
  OrbitalIdle = 0,
  CoreInjection = 1,
  SowingTraversal = 2,
  EvaluateDestination = 3,
  CrossDischarge = 4,
  RelayOverload = 5,
  CleanupCheck = 6,
  Victory = 7,
  GameOver = 8
};

/// Enemy assault craft classification.
enum class VesselType : uint8_t {
  Escort = 0,   ///< Light fighter / drone screen vulnerable to flak.
  Cruiser = 1,  ///< Armored vessel requiring mid-to-high mass lances.
  Flagship = 2  ///< Sector boss with multi-corridor kinetic barriers.
};

#pragma pack(push, 1)

/**
 * @brief Identifies and configures individual capacitor bays on the dreadnought
 * hull.
 */
struct BatteryComponent {
  uint8_t bay_index;      ///< 0 to 15.
  uint8_t tier;           ///< 0: Inner Reservoir, 1: Outer Frontline.
  uint16_t grid_column;   ///< Assigned screen corridor (0..7 for frontline).
  uint32_t charge_units;  ///< Accumulated plasma mass (M).
  float
      radial_position_rad;  ///< Geometric angle along the dreadnought chassis.
  uint8_t
      is_frontline;   ///< 1 if capable of direct cross-discharge, 0 otherwise.
  uint8_t is_nyumba;  ///< 1 for Bays 3 & 4 (House / Super-Capacitor).
  uint8_t is_kichwa;  ///< 1 for Bays 8 & 15 (Head / Vector Conduit).
  uint8_t is_kimbi;   ///< 1 for Bays 9 & 14 (Flank / Deflection Chamber).
};

/**
 * @brief Tracks active sowing traversals and multi-lap cascade state.
 */
struct SowingStateComponent {
  uint8_t origin_bay;        ///< Sowing commencement bay.
  uint8_t current_bay;       ///< Dynamic position of distribution head.
  uint32_t remaining_units;  ///< Plasma units remaining to sow.
  int8_t step_direction;     ///< +1 for Clockwise, -1 for Counter-Clockwise.
  float step_accumulator;    ///< Interpolation accumulator for frame pacing.
  uint16_t cascade_depth;    ///< Relay lap tracking counter.
  uint8_t flak_triggered;    ///< 1 if current step discharged flak.
};

/**
 * @brief Encapsulates descending enemy assault craft.
 */
struct EnemyVesselComponent {
  uint32_t entity_id;  ///< Unique combatant handle.
  uint16_t
      assigned_corridor;  ///< Attack corridor matching frontline bay (0..7).
  float world_pos_x;      ///< Spatial coordinate X (normalized 0.0 to 1.0).
  float world_pos_y;  ///< Spatial coordinate Y (descending 1.0 down to 0.0).
  float velocity_y;   ///< Advance speed toward atmospheric boundary.
  float current_shields;  ///< Quadratic damage mitigation buffer.
  float max_shields;      ///< Base barrier capacity.
  float current_hull;     ///< Structural integrity points.
  float max_hull;         ///< Base hull capacity.
  uint8_t vessel_type;    ///< VesselType (0: Escort, 1: Cruiser, 2: Flagship).
  uint8_t is_destroyed;   ///< 1 if marked for removal.
};

/**
 * @brief Configures active high-energy particle lance discharges.
 */
struct ParticleLanceComponent {
  uint8_t firing_bay_index;  ///< Originating frontline battery.
  float origin_x;            ///< Beam origin X.
  float origin_y;            ///< Beam origin Y.
  float beam_width;          ///< Dynamic visual width based on mass.
  float sustained_duration;  ///< Total firing duration in seconds.
  float remaining_duration;  ///< Life timer countdown.
  float total_damage;        ///< Quadratic damage value (alpha * M^2).
  uint8_t active;            ///< 1 if active, 0 if expired.
};

/**
 * @brief Represents secondary radial flak detonations.
 */
struct FlakBurstComponent {
  float world_pos_x;         ///< Detonation coordinate X.
  float world_pos_y;         ///< Detonation coordinate Y.
  float blast_radius;        ///< Effective sub-munition dispersion radius.
  float area_damage;         ///< Secondary damage value (beta * sqrt(M')).
  float lifetime;            ///< Total fadeout duration in seconds.
  float remaining_lifetime;  ///< Remaining life countdown.
  uint8_t active;            ///< 1 if active, 0 if expired.
};

/**
 * @brief Global single-instance state tracking dreadnought systems.
 */
struct DreadnoughtStateComponent {
  float orbital_position_x;  ///< Platform position along defense shelf (0.0
                             ///< to 1.0).
  float target_position_x;   ///< Smoothed interpolation target.
  uint32_t reserve_cores;    ///< Unplaced core inventory.
  float boundary_line_y;     ///< Critical planetary atmospheric threshold (e.g.
                             ///< 0.2).
  uint8_t is_cascading;  ///< Input lock flag during active relays (1 = locked).
  uint32_t total_score;  ///< Cumulative score.
  uint8_t current_sim_state;  ///< SimulationState.
  uint32_t cores_used;        ///< Total cores injected so far.
};

/**
 * @brief Fixed-size bucket for 2D corridor spatial partitioning queries.
 */
struct SpatialGridBucket {
  uint32_t entity_ids[kMaxBucketOccupants];
  uint16_t count;
};

#pragma pack(pop)

}  // namespace void_sower::ecs

#endif  // VOID_SOWER_ECS_COMPONENTS_H_
