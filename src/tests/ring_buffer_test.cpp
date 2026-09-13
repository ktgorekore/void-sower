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

#include "ecs/systems/ring_buffer.h"

#include <gtest/gtest.h>

#include "ecs/components.h"

namespace void_sower::ecs {

TEST(RingBufferTest, ClockwiseStepWraparound) {
  for (uint8_t i = 0; i < 15; ++i) {
    EXPECT_EQ(StepBayIndex(i, 1), i + 1);
  }
  // Wrap around from 15 to 0
  EXPECT_EQ(StepBayIndex(15, 1), 0);
}

TEST(RingBufferTest, CounterClockwiseStepWraparound) {
  // Negative wrap-around: 0 - 1 -> 15
  EXPECT_EQ(StepBayIndex(0, -1), 15);
  for (uint8_t i = 15; i > 0; --i) {
    EXPECT_EQ(StepBayIndex(i, -1), i - 1);
  }
}

TEST(RingBufferTest, MultiStepEvaluation) {
  EXPECT_EQ(StepBayMulti(0, 1, 0), 0);
  EXPECT_EQ(StepBayMulti(0, 1, 5), 5);
  EXPECT_EQ(StepBayMulti(0, 1, 16), 0);
  EXPECT_EQ(StepBayMulti(0, 1, 17), 1);
  EXPECT_EQ(StepBayMulti(0, 1, 33), 1);

  EXPECT_EQ(StepBayMulti(0, -1, 1), 15);
  EXPECT_EQ(StepBayMulti(0, -1, 16), 0);
  EXPECT_EQ(StepBayMulti(0, -1, 17), 15);
  EXPECT_EQ(StepBayMulti(4, -1, 5), 15);
}

TEST(RingBufferTest, PowerOfTwoMaskInvariant) {
  EXPECT_EQ(kTotalBays, 16);
  EXPECT_EQ(kRingBufferMask, 0x0F);
  // Verify bitwise equivalence to modulo arithmetic
  for (int32_t current = 0; current < 16; ++current) {
    for (int8_t dir : {-1, 1}) {
      uint8_t bitwise_res = StepBayIndex(static_cast<uint8_t>(current), dir);
      uint8_t modulo_res = static_cast<uint8_t>((current + dir + 16) % 16);
      EXPECT_EQ(bitwise_res, modulo_res);
    }
  }
}

TEST(RingBufferTest, FrontlineAndReservoirTiers) {
  for (uint8_t i = 0; i < 8; ++i) {
    EXPECT_FALSE(IsFrontlineBay(i));
    EXPECT_EQ(CorridorForFrontlineBay(i), -1);
  }
  for (uint8_t i = 8; i < 16; ++i) {
    EXPECT_TRUE(IsFrontlineBay(i));
    EXPECT_EQ(CorridorForFrontlineBay(i), i - 8);
    EXPECT_EQ(FrontlineBayForCorridor(i - 8), i);
  }
}

TEST(RingBufferTest, SpecialBaysClassification) {
  // Nyumba (House pits): Bays 3 & 4
  EXPECT_TRUE(IsNyumbaBay(3));
  EXPECT_TRUE(IsNyumbaBay(4));
  EXPECT_FALSE(IsNyumbaBay(2));
  EXPECT_FALSE(IsNyumbaBay(5));

  // Kichwa (Head pits): Bays 8 & 15
  EXPECT_TRUE(IsKichwaBay(8));
  EXPECT_TRUE(IsKichwaBay(15));
  EXPECT_FALSE(IsKichwaBay(7));
  EXPECT_FALSE(IsKichwaBay(9));

  // Kimbi (Flank pits): Bays 9 & 14
  EXPECT_TRUE(IsKimbiBay(9));
  EXPECT_TRUE(IsKimbiBay(14));
  EXPECT_FALSE(IsKimbiBay(8));
  EXPECT_FALSE(IsKimbiBay(15));
}

}  // namespace void_sower::ecs
