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

/**
 * @brief Identifies and configures individual capacitor bays on the dreadnought
 * hull. Cache-line aligned to 64 bytes to eliminate false sharing during
 * high-frequency traversals.
 */
struct alignas(64) BatteryComponent {
  uint32_t charge_units{0};  ///< Accumulated plasma mass (M) [offset 0]
  float radial_position_rad{
      0.0f};  ///< Geometric angle along dreadnought chassis [offset 4]
  uint16_t grid_column{
      0};  ///< Screen corridor index (0..7 for frontline) [offset 8]
  uint8_t bay_index{0};  ///< Bay index (0 to 15) [offset 10]
  uint8_t tier{0};       ///< 0: Inner Reservoir, 1: Outer Frontline [offset 11]
  uint8_t is_frontline{0};  ///< 1 if outer frontline, 0 if inner [offset 12]
  uint8_t is_nyumba{
      0};  ///< 1 for Bays 3 & 4 (House / Super-Capacitor) [offset 13]
  uint8_t is_kichwa{
      0};  ///< 1 for Bays 8 & 15 (Head / Vector Conduit) [offset 14]
  uint8_t is_kimbi{
      0};  ///< 1 for Bays 9 & 14 (Flank / Deflection Chamber) [offset 15]
  uint8_t _padding[48]{
      0};  ///< Explicit padding to guarantee 64-byte size [offset 16..63]
};
static_assert(sizeof(BatteryComponent) == 64,
              "BatteryComponent must be exactly 64 bytes (1 cache line)");
static_assert(alignof(BatteryComponent) == 64,
              "BatteryComponent must be 64-byte cache-line aligned");

/**
 * @brief Tracks active sowing traversals and multi-lap cascade state.
 */
struct SowingStateComponent {
  uint8_t origin_bay{0};        ///< Sowing commencement bay.
  uint8_t current_bay{0};       ///< Dynamic position of distribution head.
  uint32_t remaining_units{0};  ///< Plasma units remaining to sow.
  int8_t step_direction{0};     ///< +1 for Clockwise, -1 for Counter-Clockwise.
  float step_accumulator{
      0.0f};                  ///< Interpolation accumulator for frame pacing.
  uint16_t cascade_depth{0};  ///< Relay lap tracking counter.
  uint8_t flak_triggered{0};  ///< 1 if current step discharged flak.
};

/**
 * @brief Encapsulates descending enemy assault craft.
 */
struct EnemyVesselComponent {
  uint32_t entity_id{0};  ///< Unique combatant handle.
  uint16_t assigned_corridor{
      0};                   ///< Attack corridor matching frontline bay (0..7).
  float world_pos_x{0.0f};  ///< Spatial coordinate X (normalized 0.0 to 1.0).
  float world_pos_y{
      0.0f};  ///< Spatial coordinate Y (descending 1.0 down to 0.0).
  float velocity_y{0.0f};       ///< Advance speed toward atmospheric boundary.
  float current_shields{0.0f};  ///< Quadratic damage mitigation buffer.
  float max_shields{0.0f};      ///< Base barrier capacity.
  float current_hull{0.0f};     ///< Structural integrity points.
  float max_hull{0.0f};         ///< Base hull capacity.
  uint8_t vessel_type{0};  ///< VesselType (0: Escort, 1: Cruiser, 2: Flagship).
  uint8_t is_destroyed{0};  ///< 1 if marked for removal.
};

/**
 * @brief Configures active high-energy particle lance discharges.
 */
struct ParticleLanceComponent {
  uint8_t firing_bay_index{0};     ///< Originating frontline battery.
  float origin_x{0.0f};            ///< Beam origin X.
  float origin_y{0.0f};            ///< Beam origin Y.
  float beam_width{0.0f};          ///< Dynamic visual width based on mass.
  float sustained_duration{0.0f};  ///< Total firing duration in seconds.
  float remaining_duration{0.0f};  ///< Life timer countdown.
  float total_damage{0.0f};        ///< Quadratic damage value (alpha * M^2).
  uint8_t active{0};               ///< 1 if active, 0 if expired.
};

/**
 * @brief Represents secondary radial flak detonations.
 */
struct FlakBurstComponent {
  float world_pos_x{0.0f};   ///< Detonation coordinate X.
  float world_pos_y{0.0f};   ///< Detonation coordinate Y.
  float blast_radius{0.0f};  ///< Effective sub-munition dispersion radius.
  float area_damage{0.0f};   ///< Secondary damage value (beta * sqrt(M')).
  float lifetime{0.0f};      ///< Total fadeout duration in seconds.
  float remaining_lifetime{0.0f};  ///< Remaining life countdown.
  uint8_t active{0};               ///< 1 if active, 0 if expired.
};

/**
 * @brief Global single-instance state tracking dreadnought systems.
 * Cache-line aligned to 64 bytes.
 */
struct alignas(64) DreadnoughtStateComponent {
  float orbital_position_x{
      0.5f};                      ///< Platform position (0.0 to 1.0) [offset 0]
  float target_position_x{0.5f};  ///< Smoothed interpolation target [offset 4]
  float boundary_line_y{0.2f};    ///< Atmospheric threshold line [offset 8]
  uint32_t reserve_cores{0};      ///< Unplaced core inventory [offset 12]
  uint32_t total_score{0};        ///< Cumulative score [offset 16]
  uint32_t cores_used{0};         ///< Total cores injected so far [offset 20]
  uint8_t is_cascading{
      0};  ///< Input lock flag during active relays [offset 24]
  uint8_t current_sim_state{0};  ///< SimulationState [offset 25]
  uint8_t _padding[38]{
      0};  ///< Explicit padding to guarantee 64-byte size [offset 26..63]
};
static_assert(
    sizeof(DreadnoughtStateComponent) == 64,
    "DreadnoughtStateComponent must be exactly 64 bytes (1 cache line)");
static_assert(alignof(DreadnoughtStateComponent) == 64,
              "DreadnoughtStateComponent must be 64-byte cache-line aligned");

/**
 * @brief Fixed-size bucket for 2D corridor spatial partitioning queries.
 * Cache-line aligned to 64 bytes, totaling 192 bytes (3 cache lines).
 */
struct alignas(64) SpatialGridBucket {
  uint32_t entity_ids[kMaxBucketOccupants]{
      0};                   ///< 32 * 4 = 128 bytes [offset 0..127]
  uint16_t count{0};        ///< Active occupant count [offset 128..129]
  uint8_t _padding[62]{0};  ///< Explicit padding to 192 bytes [offset 130..191]
};
static_assert(sizeof(SpatialGridBucket) == 192,
              "SpatialGridBucket must be exactly 192 bytes (3 cache lines)");
static_assert(alignof(SpatialGridBucket) == 64,
              "SpatialGridBucket must be 64-byte cache-line aligned");

}  // namespace void_sower::ecs

#endif  // VOID_SOWER_ECS_COMPONENTS_H_
