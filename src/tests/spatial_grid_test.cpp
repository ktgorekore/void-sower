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

#include "ecs/systems/spatial_grid.h"

#include <gtest/gtest.h>

namespace void_sower::ecs {

TEST(SpatialGridTest, RegistrationAndQuery) {
  SpatialGrid grid;
  EXPECT_EQ(grid.GetCorridorCount(0), 0);

  EXPECT_TRUE(grid.RegisterEntity(0, 101));
  EXPECT_TRUE(grid.RegisterEntity(0, 102));
  EXPECT_TRUE(grid.RegisterEntity(3, 201));

  EXPECT_EQ(grid.GetCorridorCount(0), 2);
  EXPECT_EQ(grid.GetCorridorCount(3), 1);
  EXPECT_EQ(grid.GetCorridorCount(1), 0);

  auto occ0 = grid.GetCorridorOccupants(0);
  ASSERT_EQ(occ0.size(), 2);
  EXPECT_EQ(occ0[0], 101);
  EXPECT_EQ(occ0[1], 102);

  grid.Clear();
  EXPECT_EQ(grid.GetCorridorCount(0), 0);
  EXPECT_EQ(grid.GetCorridorCount(3), 0);
}

TEST(SpatialGridTest, InvalidCorridorBounds) {
  SpatialGrid grid;
  EXPECT_FALSE(grid.RegisterEntity(8, 999));
  EXPECT_EQ(grid.GetCorridorCount(8), 0);
  EXPECT_TRUE(grid.GetCorridorOccupants(8).empty());
}

}  // namespace void_sower::ecs
