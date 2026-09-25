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

#include "engine.h"

#include <absl/log/log.h>

#include <algorithm>

#include "systems/mcts_solver.h"

namespace void_sower::ecs {

Engine::Engine() {
  combat_system_ = std::make_unique<CombatSystem>(registry_);
  wave_generator_ = std::make_unique<WaveGenerator>(registry_);
  Initialize();
}

void Engine::Initialize(uint32_t starting_cores, float boundary_y) {
  VLOG(6) << "Engine::Initialize: starting_cores=" << starting_cores
          << ", boundary_y=" << boundary_y;
  registry_.clear();
  combat_system_->InitializeDreadnought(starting_cores, boundary_y);
}

bool Engine::GenerateWave(const WaveGeneratorConfig& config) {
  VLOG(6) << "Engine::GenerateWave: difficulty="
          << static_cast<int>(config.difficulty)
          << ", seed=" << config.random_seed
          << ", budget=" << config.core_budget;
  const bool success = wave_generator_->GenerateWave(config);
  if (success) {
    combat_system_->RebuildSpatialGrid();
  }
  return success;
}

bool Engine::InjectCore(uint8_t bay_index, int8_t direction) {
  VLOG(6) << "Engine::InjectCore: bay=" << static_cast<int>(bay_index)
          << ", direction=" << static_cast<int>(direction);
  return combat_system_->InjectCore(bay_index, direction);
}

void Engine::SetTargetPositionX(float target_x) {
  VLOG(10) << "Engine::SetTargetPositionX: target_x=" << target_x;
  combat_system_->SetTargetPositionX(target_x);
}

void Engine::Update(float delta_time) {
  VLOG(10) << "Engine::Update: delta_time=" << delta_time;
  combat_system_->Update(delta_time);
}

void Engine::DamageConduit(uint8_t bay_index) {
  VLOG(6) << "Engine::DamageConduit: bay_index=" << static_cast<int>(bay_index);
  combat_system_->DamageConduit(bay_index);
}

void Engine::DamageAtmosphere(uint32_t penalty) {
  VLOG(6) << "Engine::DamageAtmosphere: penalty=" << penalty;
  combat_system_->DamageAtmosphere(penalty);
}

void Engine::GrantCores(uint32_t count) {
  VLOG(6) << "Engine::GrantCores: count=" << count;
  if (combat_system_) {
    combat_system_->GrantCores(count);
  }
}

void Engine::SetLateralDrift(bool enabled) {
  VLOG(6) << "Engine::SetLateralDrift: enabled=" << enabled;
  if (combat_system_) {
    combat_system_->SetLateralDrift(enabled);
  }
}

bool Engine::SpawnEnemy(uint16_t corridor, float world_pos_y, float velocity_y,
                        float shields, float hull, uint8_t vessel_type) {
  VLOG(6) << "Engine::SpawnEnemy: corridor=" << corridor
          << ", y=" << world_pos_y
          << ", type=" << static_cast<int>(vessel_type);
  if (combat_system_) {
    return combat_system_->SpawnEnemy(corridor, world_pos_y, velocity_y,
                                      shields, hull, vessel_type);
  }
  return false;
}

CombatSystem::PredictionResult Engine::PredictSow(uint8_t start_bay,
                                                  int8_t direction) const {
  VLOG(10) << "Engine::PredictSow: start_bay=" << static_cast<int>(start_bay)
           << ", direction=" << static_cast<int>(direction);
  return combat_system_->PredictSow(start_bay, direction);
}

void Engine::GetBays(absl::Span<BatteryComponent> out_bays) const {
  auto view = registry_.view<const BatteryComponent>();
  for (auto entity : view) {
    const auto& bay = view.get<const BatteryComponent>(entity);
    if (bay.bay_index < out_bays.size()) {
      out_bays[bay.bay_index] = bay;
    }
  }
}

uint32_t Engine::GetEnemies(
    absl::Span<EnemyVesselComponent> out_enemies) const {
  auto view = registry_.view<const EnemyVesselComponent>();
  uint32_t count = 0;
  for (auto entity : view) {
    if (count >= out_enemies.size()) break;
    const auto& enemy = view.get<const EnemyVesselComponent>(entity);
    out_enemies[count++] = enemy;
  }
  return count;
}

uint32_t Engine::GetParticleLances(
    absl::Span<ParticleLanceComponent> out_lances) const {
  auto view = registry_.view<const ParticleLanceComponent>();
  uint32_t count = 0;
  for (auto entity : view) {
    if (count >= out_lances.size()) break;
    const auto& lance = view.get<const ParticleLanceComponent>(entity);
    if (lance.active != 0) {
      out_lances[count++] = lance;
    }
  }
  return count;
}

uint32_t Engine::GetFlakBursts(absl::Span<FlakBurstComponent> out_flaks) const {
  auto view = registry_.view<const FlakBurstComponent>();
  uint32_t count = 0;
  for (auto entity : view) {
    if (count >= out_flaks.size()) break;
    const auto& flak = view.get<const FlakBurstComponent>(entity);
    if (flak.active != 0) {
      out_flaks[count++] = flak;
    }
  }
  return count;
}

DreadnoughtStateComponent Engine::GetDreadnoughtState() const {
  auto view = registry_.view<const DreadnoughtStateComponent>();
  for (auto entity : view) {
    return view.get<const DreadnoughtStateComponent>(entity);
  }
  return DreadnoughtStateComponent{};
}

SimulationState Engine::GetSimulationState() const {
  return combat_system_->GetSimulationState();
}

void Engine::SetLanceAlphaMultiplier(float multiplier) {
  combat_system_->SetLanceAlphaMultiplier(multiplier);
}

void Engine::RestoreSnapshot(
    const std::array<uint32_t, kTotalBays>& bay_charges, uint32_t reserve_cores,
    uint32_t total_score) {
  combat_system_->RestoreSnapshot(bay_charges, reserve_cores, total_score);
}

int32_t Engine::SolveTacticalStep(uint8_t* out_bay, int8_t* out_direction,
                                  float* out_confidence,
                                  float* out_predicted_damage) {
  MctsSolver solver(registry_);
  return solver.SolveTacticalStep(out_bay, out_direction, out_confidence,
                                  out_predicted_damage);
}

void Engine::Reset() { Initialize(); }

}  // namespace void_sower::ecs
