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

#include "spatial_grid.h"

namespace void_sower::ecs {

SpatialGrid::SpatialGrid() { Clear(); }

void SpatialGrid::Clear() {
  for (auto& bucket : buckets_) {
    bucket.count = 0;
  }
}

bool SpatialGrid::RegisterEntity(uint8_t corridor, uint32_t entity_id) {
  if (corridor >= kCorridorCount) {
    return false;
  }
  auto& bucket = buckets_[corridor];
  if (bucket.count < kMaxBucketOccupants) {
    bucket.entity_ids[bucket.count++] = entity_id;
    return true;
  }
  return false;
}

absl::Span<const uint32_t> SpatialGrid::GetCorridorOccupants(
    uint8_t corridor) const {
  if (corridor >= kCorridorCount) {
    return {};
  }
  const auto& bucket = buckets_[corridor];
  return absl::MakeConstSpan(bucket.entity_ids, bucket.count);
}

uint16_t SpatialGrid::GetCorridorCount(uint8_t corridor) const {
  if (corridor >= kCorridorCount) {
    return 0;
  }
  return buckets_[corridor].count;
}

}  // namespace void_sower::ecs
