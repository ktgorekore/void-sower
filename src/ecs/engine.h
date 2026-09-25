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

#ifndef VOID_SOWER_ECS_ENGINE_H_
#define VOID_SOWER_ECS_ENGINE_H_

#include <entt/entt.hpp>
#include <memory>

#include "absl/types/span.h"
#include "components.h"
#include "systems/combat_system.h"
#include "systems/wave_generator.h"

namespace void_sower::ecs {

/**
 * @brief High-level orchestrator managing EnTT registry and ECS systems for
 * Void Sower.
 */
class Engine {
 public:
  Engine();
  ~Engine() = default;

  /// Initializes dreadnought with starting cores and atmospheric boundary.
  void Initialize(uint32_t starting_cores = 24, float boundary_y = 0.2f);

  /// Generates a mathematically solvable procedural wave.
  bool GenerateWave(const WaveGeneratorConfig& config);

  /// Injects a core from the reactor into a capacitor bay in the chosen
  /// direction.
  bool InjectCore(uint8_t bay_index, int8_t direction);

  /// Sets horizontal slider position for dreadnought.
  void SetTargetPositionX(float target_x);

  /// Steps the simulation by delta_time (defaults to 1/60s).
  void Update(float delta_time = kFixedTimeStep);

  /// Applies conduit direct hit breach: drains 1 reserve core and discharges
  /// active bay.
  void DamageConduit(uint8_t bay_index);

  /// Applies atmospheric breach penalty.
  void DamageAtmosphere(uint32_t penalty);

  /// Grants reserve energy cores to the dreadnought reactor.
  void GrantCores(uint32_t count);

  /// Enables or disables evasive lateral drift behavior for enemy craft.
  void SetLateralDrift(bool enabled);

  /// Spawns an enemy assault craft into the combat theater.
  bool SpawnEnemy(uint16_t corridor, float world_pos_y, float velocity_y,
                  float shields, float hull, uint8_t vessel_type);

  /// Dry-run predictive targeting telemetry.
  CombatSystem::PredictionResult PredictSow(uint8_t start_bay,
                                            int8_t direction) const;

  /// Copies 16 capacitor bay states into out_bays.
  void GetBays(absl::Span<BatteryComponent> out_bays) const;

  /// Copies active enemy craft into out_enemies buffer.
  uint32_t GetEnemies(absl::Span<EnemyVesselComponent> out_enemies) const;

  /// Copies active particle lances into out_lances buffer.
  uint32_t GetParticleLances(
      absl::Span<ParticleLanceComponent> out_lances) const;

  /// Copies active flak bursts into out_flaks buffer.
  uint32_t GetFlakBursts(absl::Span<FlakBurstComponent> out_flaks) const;

  /// Returns dreadnought state.
  DreadnoughtStateComponent GetDreadnoughtState() const;

  /// Returns simulation state.
  SimulationState GetSimulationState() const;

  /// Returns reference to registry (for MCTS / testing).
  entt::registry& GetRegistry() { return registry_; }
  const entt::registry& GetRegistry() const { return registry_; }

  /// Sets active lance alpha multiplier (chassis bonus).
  void SetLanceAlphaMultiplier(float multiplier);

  /// Restores bay charges, reserve cores, and score from prior turn snapshot.
  void RestoreSnapshot(const std::array<uint32_t, kTotalBays>& bay_charges,
                       uint32_t reserve_cores, uint32_t total_score);

  /// Solves single optimal tactical move using MCTS lookahead.
  int32_t SolveTacticalStep(uint8_t* out_bay, int8_t* out_direction,
                            float* out_confidence, float* out_predicted_damage);

  /// Resets the engine.
  void Reset();

 private:
  entt::registry registry_;
  std::unique_ptr<CombatSystem> combat_system_;
  std::unique_ptr<WaveGenerator> wave_generator_;
};

}  // namespace void_sower::ecs

#endif  // VOID_SOWER_ECS_ENGINE_H_
