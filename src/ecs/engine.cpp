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

#include <algorithm>

namespace void_sower::ecs {

Engine::Engine() {
  combat_system_ = std::make_unique<CombatSystem>(registry_);
  wave_generator_ = std::make_unique<WaveGenerator>(registry_);
  Initialize();
}

void Engine::Initialize(uint32_t starting_cores, float boundary_y) {
  registry_.clear();
  combat_system_->InitializeDreadnought(starting_cores, boundary_y);
}

bool Engine::GenerateWave(const WaveGeneratorConfig& config) {
  return wave_generator_->GenerateWave(config);
}

bool Engine::InjectCore(uint8_t bay_index, int8_t direction) {
  return combat_system_->InjectCore(bay_index, direction);
}

void Engine::SetTargetPositionX(float target_x) {
  combat_system_->SetTargetPositionX(target_x);
}

void Engine::Update(float delta_time) { combat_system_->Update(delta_time); }

CombatSystem::PredictionResult Engine::PredictSow(uint8_t start_bay,
                                                  int8_t direction) const {
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
    if (enemy.is_destroyed == 0) {
      out_enemies[count++] = enemy;
    }
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

void Engine::Reset() { Initialize(); }

}  // namespace void_sower::ecs
