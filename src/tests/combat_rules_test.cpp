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

#include "ecs/combat_rules.h"

#include <gtest/gtest.h>

namespace void_sower::ecs {

TEST(CombatRulesTest, QuadraticLanceDamage) {
  EXPECT_FLOAT_EQ(ComputeLanceDamage(0), 0.0f);
  EXPECT_FLOAT_EQ(ComputeLanceDamage(1), 100.0f);
  EXPECT_FLOAT_EQ(ComputeLanceDamage(2), 400.0f);
  EXPECT_FLOAT_EQ(ComputeLanceDamage(3), 900.0f);
  EXPECT_FLOAT_EQ(ComputeLanceDamage(4), 1600.0f);
}

TEST(CombatRulesTest, FlakBurstDamage) {
  EXPECT_FLOAT_EQ(ComputeFlakDamage(0), 0.0f);
  EXPECT_FLOAT_EQ(ComputeFlakDamage(1), 25.0f);
  EXPECT_FLOAT_EQ(ComputeFlakDamage(4), 50.0f);
  EXPECT_FLOAT_EQ(ComputeFlakDamage(16), 100.0f);
}

TEST(CombatRulesTest, FrontlineAndCorridorMapping) {
  for (uint8_t i = 0; i < 8; ++i) {
    EXPECT_FALSE(IsFrontlineBay(i));
    EXPECT_EQ(CorridorForFrontlineBay(i), -1);
  }
  for (uint8_t i = 8; i < 16; ++i) {
    EXPECT_TRUE(IsFrontlineBay(i));
    EXPECT_EQ(CorridorForFrontlineBay(i), static_cast<int8_t>(i - 8));
  }
  for (uint8_t c = 0; c < 8; ++c) {
    EXPECT_EQ(FrontlineBayForCorridor(c), static_cast<uint8_t>(8 + c));
  }
}

TEST(CombatRulesTest, BayRoleTopologicalClassification) {
  // Nyumba (House)
  EXPECT_EQ(GetBayRole(3), BayRole::NyumbaSuperCapacitor);
  EXPECT_EQ(GetBayRole(4), BayRole::NyumbaSuperCapacitor);

  // Kichwa (Head)
  EXPECT_EQ(GetBayRole(8), BayRole::KichwaVectorConduit);
  EXPECT_EQ(GetBayRole(15), BayRole::KichwaVectorConduit);

  // Kimbi (Flank)
  EXPECT_EQ(GetBayRole(9), BayRole::KimbiDeflectionChamber);
  EXPECT_EQ(GetBayRole(14), BayRole::KimbiDeflectionChamber);

  // Standard Frontline
  EXPECT_EQ(GetBayRole(10), BayRole::StandardFrontline);
  EXPECT_EQ(GetBayRole(11), BayRole::StandardFrontline);
  EXPECT_EQ(GetBayRole(12), BayRole::StandardFrontline);
  EXPECT_EQ(GetBayRole(13), BayRole::StandardFrontline);

  // Standard Inner
  EXPECT_EQ(GetBayRole(0), BayRole::StandardInner);
  EXPECT_EQ(GetBayRole(1), BayRole::StandardInner);
  EXPECT_EQ(GetBayRole(2), BayRole::StandardInner);
  EXPECT_EQ(GetBayRole(5), BayRole::StandardInner);
  EXPECT_EQ(GetBayRole(6), BayRole::StandardInner);
  EXPECT_EQ(GetBayRole(7), BayRole::StandardInner);
}

}  // namespace void_sower::ecs
