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

#ifndef VOID_SOWER_ECS_SYSTEMS_SPATIAL_GRID_H_
#define VOID_SOWER_ECS_SYSTEMS_SPATIAL_GRID_H_

#include <array>
#include <cstdint>

#include "../components.h"
#include "absl/types/span.h"

namespace void_sower::ecs {

/**
 * @brief 2D Uniform Spatial Grid partitioned across the 8 combat corridors.
 * Eliminates dynamic heap allocations during real-time combat loops.
 */
class SpatialGrid {
 public:
  SpatialGrid();
  ~SpatialGrid() = default;

  /// Clears all bucket occupants.
  void Clear();

  /// Registers an enemy entity ID into its assigned corridor bucket.
  bool RegisterEntity(uint8_t corridor, uint32_t entity_id);

  /// Returns the bucket occupants for a corridor.
  absl::Span<const uint32_t> GetCorridorOccupants(uint8_t corridor) const;

  /// Returns number of occupants in a corridor.
  uint16_t GetCorridorCount(uint8_t corridor) const;

 private:
  std::array<SpatialGridBucket, kCorridorCount> buckets_;
};

}  // namespace void_sower::ecs

#endif  // VOID_SOWER_ECS_SYSTEMS_SPATIAL_GRID_H_
