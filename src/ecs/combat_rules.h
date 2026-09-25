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

#ifndef VOID_SOWER_ECS_COMBAT_RULES_H_
#define VOID_SOWER_ECS_COMBAT_RULES_H_

#include <cmath>
#include <cstdint>

#include "components.h"
#include "systems/ring_buffer.h"

namespace void_sower::ecs {

/**
 * @brief Computes quadratic particle lance damage from concentrated mass:
 * D(M) = alpha * M^2.
 */
inline float ComputeLanceDamage(uint32_t mass,
                                float alpha = kAlphaLanceDamage) {
  return alpha * static_cast<float>(mass * mass);
}

/**
 * @brief Computes secondary flak burst damage from combined relay mass:
 * D_flak = beta * sqrt(M').
 */
inline float ComputeFlakDamage(uint32_t mass, float beta = kBetaFlakDamage) {
  return beta * std::sqrt(static_cast<float>(mass));
}

/**
 * @brief Categorizes topological roles of individual capacitor bays in Bao la
 * Kiswahili rules.
 */
enum class BayRole : uint8_t {
  StandardInner = 0,          ///< Bays 0..2, 5..7: Reservoir storage.
  StandardFrontline = 1,      ///< Bays 10..13: Direct corridor discharge.
  NyumbaSuperCapacitor = 2,   ///< Bays 3 & 4: Super-Capacitor (House).
  KichwaVectorConduit = 3,    ///< Bays 8 & 15: Vector Conduit (Head).
  KimbiDeflectionChamber = 4  ///< Bays 9 & 14: Flank Deflection Chamber.
};

/**
 * @brief Determines the topological role for a given bay index.
 */
inline constexpr BayRole GetBayRole(uint8_t bay_index) {
  if (bay_index == 3 || bay_index == 4) {
    return BayRole::NyumbaSuperCapacitor;
  }
  if (bay_index == 8 || bay_index == 15) {
    return BayRole::KichwaVectorConduit;
  }
  if (bay_index == 9 || bay_index == 14) {
    return BayRole::KimbiDeflectionChamber;
  }
  return IsFrontlineBay(bay_index) ? BayRole::StandardFrontline
                                   : BayRole::StandardInner;
}

/**
 * @brief Resolves the effective sowing direction for a bay, honoring the Kichwa
 * Vector Conduit rule: frontline boundary bays 8 & 15 enforce inward momentum
 * along the frontline battery deck: Bay 15 sows counter-clockwise/left (-1),
 * Bay 8 sows clockwise/right (+1).
 *
 * @param bay_index Capacitor bay index (0..15).
 * @param desired_direction Requested direction (+1 or -1).
 * @return Resolved direction (+1 or -1).
 */
inline constexpr int8_t ResolveSowDirection(uint8_t bay_index,
                                            int8_t desired_direction) {
  if (bay_index == 15 && desired_direction == 1) {
    return -1;
  }
  if (bay_index == 8 && desired_direction == -1) {
    return 1;
  }
  return desired_direction;
}

}  // namespace void_sower::ecs

#endif  // VOID_SOWER_ECS_COMBAT_RULES_H_
