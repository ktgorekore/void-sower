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

#ifndef VOID_SOWER_ECS_SYSTEMS_RING_BUFFER_H_
#define VOID_SOWER_ECS_SYSTEMS_RING_BUFFER_H_

#include <cstdint>

#include "../components.h"

namespace void_sower::ecs {

/// Power-of-two index bitmask for the 16-bay ring buffer (0x0F).
inline constexpr uint8_t kRingBufferMask = kTotalBays - 1;

/**
 * @brief Computes the next circular ring buffer bay index in constant time
 * O(1). Leverages power-of-two bitwise masking (& 0x0F) derived from
 * cognitas-trading low-latency primitives. Executes in a single CPU clock cycle
 * without branch misprediction or integer division.
 *
 * @param current_index Current bay index (0..15).
 * @param direction +1 for clockwise, -1 for counter-clockwise.
 * @return Next bay index in [0, 15].
 */
inline uint8_t StepBayIndex(uint8_t current_index, int8_t direction) {
  return static_cast<uint8_t>((current_index + direction + kTotalBays) &
                              kRingBufferMask);
}

/**
 * @brief Predicts the destination bay after k steps in constant time O(1).
 *
 * @param start_index Initial starting bay index.
 * @param direction +1 for clockwise, -1 for counter-clockwise.
 * @param steps Number of steps to advance.
 * @return Resulting bay index in [0, 15].
 */
inline uint8_t StepBayMulti(uint8_t start_index, int8_t direction,
                            uint32_t steps) {
  int32_t offset = (static_cast<int32_t>(direction) *
                    static_cast<int32_t>(steps & kRingBufferMask));
  return static_cast<uint8_t>((start_index + offset + kTotalBays) &
                              kRingBufferMask);
}

/**
 * @brief Returns whether a bay index belongs to the outer frontline ring (Bays
 * 8-15).
 *
 * @param bay_index Bay index (0..15).
 * @return true if frontline, false if inner reservoir.
 */
inline bool IsFrontlineBay(uint8_t bay_index) {
  return bay_index >= 8 && bay_index < kTotalBays;
}

/**
 * @brief Returns whether a bay index is Nyumba (Central Super-Capacitor, Bays 3
 * & 4).
 *
 * @param bay_index Bay index (0..15).
 * @return true if Nyumba, false otherwise.
 */
inline bool IsNyumbaBay(uint8_t bay_index) {
  return bay_index == 3 || bay_index == 4;
}

/**
 * @brief Returns whether a bay index is Kichwa (Vector Conduit, Bays 8 & 15).
 *
 * @param bay_index Bay index (0..15).
 * @return true if Kichwa, false otherwise.
 */
inline bool IsKichwaBay(uint8_t bay_index) {
  return bay_index == 8 || bay_index == 15;
}

/**
 * @brief Returns whether a bay index is Kimbi (Deflection Chamber, Bays 9 &
 * 14).
 *
 * @param bay_index Bay index (0..15).
 * @return true if Kimbi, false otherwise.
 */
inline bool IsKimbiBay(uint8_t bay_index) {
  return bay_index == 9 || bay_index == 14;
}

/**
 * @brief Maps an outer frontline bay index (8..15) to its corresponding attack
 * corridor (0..7).
 *
 * @param bay_index Bay index (0..15).
 * @return Corridor index in [0, 7], or -1 if the bay is in the inner reservoir.
 */
inline int8_t CorridorForFrontlineBay(uint8_t bay_index) {
  if (IsFrontlineBay(bay_index)) {
    return static_cast<int8_t>(bay_index - 8);
  }
  return -1;
}

/**
 * @brief Maps an attack corridor (0..7) to its corresponding outer frontline
 * bay index (8..15).
 *
 * @param corridor Corridor index (0..7).
 * @return Outer frontline bay index in [8, 15].
 */
inline uint8_t FrontlineBayForCorridor(uint8_t corridor) {
  return static_cast<uint8_t>(8 + (corridor & 0x07));
}

}  // namespace void_sower::ecs

#endif  // VOID_SOWER_ECS_SYSTEMS_RING_BUFFER_H_
