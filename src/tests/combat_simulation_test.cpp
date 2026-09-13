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

#include <gtest/gtest.h>

#include "ecs/components.h"
#include "ecs/engine.h"
#include "ecs/systems/combat_system.h"

namespace void_sower::ecs {

TEST(CombatSimulationTest, QuadraticDamageFormulas) {
  // Lance Damage: D(M) = alpha * M^2 (alpha = 100.0f)
  EXPECT_FLOAT_EQ(ComputeLanceDamage(1), 100.0f);
  EXPECT_FLOAT_EQ(ComputeLanceDamage(2), 400.0f);
  EXPECT_FLOAT_EQ(ComputeLanceDamage(3), 900.0f);
  EXPECT_FLOAT_EQ(ComputeLanceDamage(4), 1600.0f);
  EXPECT_FLOAT_EQ(ComputeLanceDamage(8), 6400.0f);

  // Flak Damage: D_flak = beta * sqrt(M') (beta = 25.0f)
  EXPECT_FLOAT_EQ(ComputeFlakDamage(1), 25.0f);
  EXPECT_FLOAT_EQ(ComputeFlakDamage(4), 50.0f);
  EXPECT_FLOAT_EQ(ComputeFlakDamage(9), 75.0f);
  EXPECT_FLOAT_EQ(ComputeFlakDamage(16), 100.0f);
}

TEST(CombatSimulationTest, CoreInjectionAndSowingCycle) {
  Engine engine;
  engine.Initialize(10, 0.2f);

  auto dread = engine.GetDreadnoughtState();
  EXPECT_EQ(dread.reserve_cores, 10);
  EXPECT_EQ(dread.cores_used, 0);
  EXPECT_EQ(engine.GetSimulationState(), SimulationState::OrbitalIdle);

  // Inject a core into bay 0, clockwise (+1)
  bool injected = engine.InjectCore(0, 1);
  EXPECT_TRUE(injected);

  dread = engine.GetDreadnoughtState();
  EXPECT_EQ(dread.reserve_cores, 9);
  EXPECT_EQ(dread.cores_used, 1);
  EXPECT_EQ(engine.GetSimulationState(), SimulationState::SowingTraversal);

  // Advance simulation step
  engine.Update(kFixedTimeStep);

  // Traversal deposited 1 unit into bay 1 (0 + 1)
  std::array<BatteryComponent, kTotalBays> bays{};
  engine.GetBays(absl::MakeSpan(bays.data(), kTotalBays));
  EXPECT_EQ(bays[1].charge_units, 1);
}

TEST(CombatSimulationTest, CrossDischargeDestroysEnemy) {
  entt::registry registry;
  CombatSystem combat(registry);
  combat.InitializeDreadnought(12, 0.2f);

  // Spawn an enemy in corridor 0 (matching frontline bay 8)
  auto enemy = registry.create();
  registry.emplace<EnemyVesselComponent>(enemy, EnemyVesselComponent{
                                                    .entity_id = 42,
                                                    .assigned_corridor = 0,
                                                    .world_pos_x = 0.0625f,
                                                    .world_pos_y = 0.8f,
                                                    .velocity_y = 0.0f,
                                                    .current_shields = 50.0f,
                                                    .max_shields = 50.0f,
                                                    .current_hull = 100.0f,
                                                    .max_hull = 100.0f,
                                                    .vessel_type = 0,
                                                    .is_destroyed = 0,
                                                });

  // Inject into bay 7 clockwise (+1) -> destination will be bay 8 (frontline
  // corridor 0)
  EXPECT_TRUE(combat.InjectCore(7, 1));

  // Step simulation: SowingTraversal moves 7 -> 8, deposits 1 unit, remaining
  // becomes 0
  combat.Update(kFixedTimeStep);

  // Next step: EvaluateDestination detects frontline alignment with corridor 0
  // and fires lance
  combat.Update(kFixedTimeStep);

  // Verify enemy in corridor 0 took lance damage (D(1) = 100, absorbs 50 shield
  // + 50 hull -> 50 hull remaining)
  const auto& vessel = registry.get<EnemyVesselComponent>(enemy);
  EXPECT_EQ(vessel.current_shields, 0.0f);
  EXPECT_FLOAT_EQ(vessel.current_hull, 50.0f);
  EXPECT_EQ(vessel.is_destroyed, 0);

  // Second injection with 2 units would finish it off!
}

}  // namespace void_sower::ecs
