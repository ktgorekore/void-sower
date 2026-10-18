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

#include "movement_system.h"

#include <absl/container/inlined_vector.h>

#include <algorithm>
#include <array>

#include "../components.h"
#include "ring_buffer.h"

namespace void_sower::ecs {

void MovementSystem::UpdateDreadnought(entt::registry& registry,
                                       entt::entity dreadnought_entity,
                                       float delta_time) {
  if (dreadnought_entity == entt::null || !registry.valid(dreadnought_entity)) {
    return;
  }

  auto& dread = registry.get<DreadnoughtStateComponent>(dreadnought_entity);
  constexpr float kSmoothFactor = 12.0f;
  dread.orbital_position_x =
      std::clamp(dread.orbital_position_x +
                     (dread.target_position_x - dread.orbital_position_x) *
                         std::min(1.0f, delta_time * kSmoothFactor),
                 0.0f, 1.0f);
  dread.orbital_position_y =
      std::clamp(dread.orbital_position_y +
                     (dread.target_position_y - dread.orbital_position_y) *
                         std::min(1.0f, delta_time * kSmoothFactor),
                 dread.boundary_line_y, 0.65f);

  // Proximity damage multiplier: 1.0 at baseline boundary_line_y (0.15),
  // scaling up to 1.6 at y=0.65.
  const float forward_depth =
      std::max(0.0f, dread.orbital_position_y - dread.boundary_line_y);
  constexpr float kMaxForwardSpan = 0.45f;
  const float norm_forward =
      std::clamp(forward_depth / kMaxForwardSpan, 0.0f, 1.0f);
  dread.proximity_multiplier = 1.0f + 0.6f * norm_forward;
}

void MovementSystem::AdvanceEnemies(entt::registry& registry, float delta_time,
                                    bool lateral_drift, float elapsed_time) {
  auto view = registry.view<EnemyVesselComponent>();
  absl::InlinedVector<entt::entity, 16> active_entities;

  // 0. Gather tactical battlefield telemetry (zero heap allocation):
  //    - Frontline bay charges (corridors 0..7 -> bays 8..15)
  //    - Dreadnought prow corridor & X coordinate
  //    - Damaged Cruiser/Flagship position for Escort screening
  std::array<uint32_t, 8> corridor_charges{};
  auto bay_view = registry.view<const BatteryComponent>();
  for (auto b_ent : bay_view) {
    const auto& bay = bay_view.get<const BatteryComponent>(b_ent);
    if (bay.bay_index >= 8 && bay.bay_index < 16) {
      corridor_charges[bay.bay_index - 8] = bay.charge_units;
    }
  }

  float dread_x = 0.4375f;
  int dread_corridor = 3;
  auto dread_view = registry.view<const DreadnoughtStateComponent>();
  for (auto d_ent : dread_view) {
    const auto& dread = dread_view.get<const DreadnoughtStateComponent>(d_ent);
    dread_x = dread.orbital_position_x;
    dread_corridor = std::clamp(static_cast<int>(dread_x * 8.0f), 0, 7);
    break;
  }

  bool has_damaged_capital = false;
  float damaged_capital_x = 0.5f;
  for (auto entity : view) {
    const auto& v = view.get<EnemyVesselComponent>(entity);
    if (v.is_destroyed == 0 && v.vessel_type >= 1 &&
        (v.current_hull < v.max_hull || v.current_shields < v.max_shields)) {
      has_damaged_capital = true;
      damaged_capital_x = v.world_pos_x;
      break;
    }
  }

  for (auto entity : view) {
    auto& enemy = view.get<EnemyVesselComponent>(entity);
    if (enemy.is_destroyed != 0) continue;

    // 1. Holographic warp-in distortion progress
    if (enemy.warp_in_progress < 1.0f) {
      enemy.warp_in_progress =
          std::min(1.0f, enemy.warp_in_progress + delta_time * 2.5f);
    }

    // 2. Behavioral flight patterns with multi-corridor lateral swaying
    float lateral_velocity = 0.0f;
    float target_bank = 0.0f;
    float target_pitch = 0.0f;
    const float phase = static_cast<float>(enemy.entity_id) * 1.57f;
    const float attitude_blend = std::min(1.0f, delta_time * 8.0f);

    switch (enemy.behavior_mode) {
      case 1: {
        // Swooper: Wide elliptical swoop arc crossing adjacent corridors
        const float swoop_speed = 1.65f;
        lateral_velocity = std::cos(elapsed_time * swoop_speed + phase) * 0.25f;
        target_pitch = std::sin(elapsed_time * swoop_speed + phase) * 0.32f;
        target_bank = std::clamp(lateral_velocity * 2.1f, -0.58f, 0.58f);
        enemy.pitch_angle_rad +=
            (target_pitch - enemy.pitch_angle_rad) * attitude_blend;
        enemy.bank_angle_rad +=
            (target_bank - enemy.bank_angle_rad) * attitude_blend;
        enemy.world_pos_y -=
            enemy.velocity_y *
            (1.0f + 0.3f * std::max(0.0f, enemy.pitch_angle_rad)) * delta_time;
        break;
      }
      case 2: {
        // Lane Weaver: Dynamic S-curve weaving across 2+ corridors
        const float weave_speed = 1.95f;
        lateral_velocity = std::sin(elapsed_time * weave_speed + phase) * 0.28f;
        target_bank = std::clamp(lateral_velocity * 1.9f, -0.55f, 0.55f);
        enemy.bank_angle_rad +=
            (target_bank - enemy.bank_angle_rad) * attitude_blend;
        enemy.pitch_angle_rad +=
            (0.0f - enemy.pitch_angle_rad) * attitude_blend;
        enemy.world_pos_y -= enemy.velocity_y * delta_time;
        break;
      }
      case 3: {
        // Kamikaze: Accelerates towards defense line when damaged + lateral
        // weave
        const bool is_damaged = (enemy.current_hull < enemy.max_hull ||
                                 enemy.current_shields < enemy.max_shields);
        const float speed_mult = is_damaged ? 1.55f : 1.0f;
        target_pitch = is_damaged ? 0.38f : 0.0f;
        enemy.pitch_angle_rad +=
            (target_pitch - enemy.pitch_angle_rad) * attitude_blend;
        if (lateral_drift) {
          lateral_velocity = std::sin(elapsed_time * 1.75f + phase) * 0.22f;
          target_bank = std::clamp(lateral_velocity * 1.8f, -0.52f, 0.52f);
        }
        enemy.bank_angle_rad +=
            (target_bank - enemy.bank_angle_rad) * attitude_blend;
        enemy.world_pos_y -= enemy.velocity_y * speed_mult * delta_time;
        break;
      }
      default: {
        // Standard flight
        if (lateral_drift) {
          lateral_velocity = std::sin(elapsed_time * 1.60f + phase) * 0.23f;
          target_bank = std::clamp(lateral_velocity * 1.9f, -0.55f, 0.55f);
        }
        enemy.bank_angle_rad +=
            (target_bank - enemy.bank_angle_rad) * attitude_blend;
        enemy.pitch_angle_rad +=
            (0.0f - enemy.pitch_angle_rad) * attitude_blend;
        enemy.world_pos_y -= enemy.velocity_y * delta_time;
        break;
      }
    }

    // 2b. Progressive Tactical AI Steering (Lance Evasion, Weak-Conduit
    // Flanking & Escort Screening) when lateral maneuvering is active:
    if (lateral_drift || enemy.behavior_mode > 0) {
      const int cur_c =
          std::clamp(static_cast<int>(enemy.assigned_corridor), 0, 7);
      const uint32_t cur_charge = corridor_charges[cur_c];
      const bool in_dread_sights =
          (cur_c == dread_corridor) ||
          (std::abs(enemy.world_pos_x - dread_x) < 0.085f);

      float tactical_steer = 0.0f;

      // A. Evade charged frontline bays (M >= 2) when a safer adjacent corridor
      // exists
      const uint32_t left_charge =
          (cur_c > 0) ? corridor_charges[cur_c - 1] : 99u;
      const uint32_t right_charge =
          (cur_c < 7) ? corridor_charges[cur_c + 1] : 99u;
      if ((cur_charge >= 2 || (in_dread_sights && enemy.vessel_type >= 1)) &&
          (left_charge < cur_charge || right_charge < cur_charge)) {
        const float evade_dir = (left_charge <= right_charge) ? -1.0f : 1.0f;
        const float urgency =
            (cur_charge >= 3 || enemy.vessel_type == 2) ? 0.24f : 0.18f;
        lateral_velocity = lateral_velocity * 0.25f + evade_dir * urgency;
      } else if (cur_charge > 0 && enemy.behavior_mode >= 1) {
        // B. Weak-Conduit Flanking: steer toward adjacent unshielded (M == 0)
        // corridor to breach exposed conduits
        if (cur_c > 0 && corridor_charges[cur_c - 1] == 0) {
          tactical_steer -= 0.12f;
        } else if (cur_c < 7 && corridor_charges[cur_c + 1] == 0) {
          tactical_steer += 0.12f;
        }
      }

      // C. Escort Screening: Escorts gravitate toward damaged
      // Cruisers/Flagships
      if (enemy.vessel_type == 0 && has_damaged_capital) {
        const float dx_cap = damaged_capital_x - enemy.world_pos_x;
        if (std::abs(dx_cap) > 0.04f && std::abs(dx_cap) < 0.32f) {
          tactical_steer += (dx_cap > 0.0f ? 0.06f : -0.06f);
        }
      }

      lateral_velocity =
          std::clamp(lateral_velocity + tactical_steer, -0.36f, 0.36f);
      target_bank = std::clamp(lateral_velocity * 2.0f, -0.60f, 0.60f);
      enemy.bank_angle_rad +=
          (target_bank - enemy.bank_angle_rad) * attitude_blend;
    }

    // 3. Integrate lateral position across corridors and update assigned
    // corridor
    enemy.velocity_x = lateral_velocity;
    if (lateral_velocity != 0.0f) {
      enemy.world_pos_x = std::clamp(
          enemy.world_pos_x + lateral_velocity * delta_time, 0.0625f, 0.9375f);
    }
    enemy.assigned_corridor = static_cast<uint16_t>(
        std::clamp(static_cast<int>(enemy.world_pos_x * 8.0f), 0, 7));
    enemy.world_pos_z = std::clamp(1.0f - enemy.world_pos_y, 0.0f, 1.0f);

    active_entities.push_back(entity);
  }

  // 4. Smooth continuous pairwise 2D spring separation so swaying ships
  // smoothly glide around each other without frame-to-frame snapping/stuttering
  if (active_entities.size() > 1) {
    std::sort(active_entities.begin(), active_entities.end(),
              [&view](entt::entity a, entt::entity b) {
                return view.get<EnemyVesselComponent>(a).world_pos_y <
                       view.get<EnemyVesselComponent>(b).world_pos_y;
              });

    constexpr float kMinGapX = 0.095f;
    constexpr float kMinGapY = 0.14f;
    constexpr float kSpringRateX = 0.28f;
    constexpr float kSpringRateY = 0.32f;
    for (size_t i = 0; i < active_entities.size(); ++i) {
      const auto& leader = view.get<EnemyVesselComponent>(active_entities[i]);
      for (size_t j = i + 1; j < active_entities.size(); ++j) {
        auto& trailer = view.get<EnemyVesselComponent>(active_entities[j]);
        const float dx = trailer.world_pos_x - leader.world_pos_x;
        const float dy = trailer.world_pos_y - leader.world_pos_y;
        const float abs_dx = std::abs(dx);
        if (abs_dx < kMinGapX && dy < kMinGapY) {
          const float overlap_x = (kMinGapX - abs_dx) / kMinGapX;
          const float overlap_y =
              std::clamp((kMinGapY - dy) / kMinGapY, 0.0f, 1.0f);
          const float weight = overlap_x * overlap_y;
          const float nudge_sign = (dx >= 0.0f) ? 1.0f : -1.0f;
          trailer.world_pos_x =
              std::clamp(trailer.world_pos_x +
                             nudge_sign * kSpringRateX * weight * delta_time,
                         0.0625f, 0.9375f);
          trailer.world_pos_y = std::min(
              0.98f, trailer.world_pos_y + kSpringRateY * weight * delta_time);
          trailer.world_pos_z =
              std::clamp(1.0f - trailer.world_pos_y, 0.0f, 1.0f);
          trailer.assigned_corridor = static_cast<uint16_t>(
              std::clamp(static_cast<int>(trailer.world_pos_x * 8.0f), 0, 7));
        }
      }
    }
  }
}

}  // namespace void_sower::ecs
