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

TEST(CombatSimulationTest, AxialLanceFiresFromDreadnoughtPosition) {
  entt::registry registry;
  CombatSystem combat(registry);
  combat.InitializeDreadnought(12, 0.2f);

  // Position dreadnought in Corridor 3 (X = 0.4375f)
  combat.SetTargetPositionX(0.4375f);
  for (int i = 0; i < 40; ++i) {
    combat.Update(kFixedTimeStep);
  }

  // Spawn enemy in Corridor 3
  auto enemy = registry.create();
  registry.emplace<EnemyVesselComponent>(enemy, EnemyVesselComponent{
                                                    .entity_id = 101,
                                                    .assigned_corridor = 3,
                                                    .world_pos_x = 0.4375f,
                                                    .world_pos_y = 0.7f,
                                                    .velocity_y = 0.0f,
                                                    .current_shields = 0.0f,
                                                    .max_shields = 0.0f,
                                                    .current_hull = 200.0f,
                                                    .max_hull = 200.0f,
                                                    .vessel_type = 1,
                                                    .is_destroyed = 0,
                                                });

  // Inject into bay 10 (+1) -> lands in bay 11
  EXPECT_TRUE(combat.InjectCore(10, 1));
  combat.Update(kFixedTimeStep);  // SowingTraversal
  combat.Update(kFixedTimeStep);  // EvaluateDestination -> CrossDischarge

  // Check that ParticleLance component was created with origin_x matching
  // dreadnought position
  bool found_lance = false;
  auto lance_view = registry.view<ParticleLanceComponent>();
  for (auto l_entity : lance_view) {
    const auto& lance = lance_view.get<ParticleLanceComponent>(l_entity);
    if (lance.active == 0) continue;
    EXPECT_NEAR(lance.origin_x, 0.4375f, 0.05f);
    EXPECT_EQ(lance.active, 1);
    found_lance = true;
  }
  EXPECT_TRUE(found_lance);

  // Verify enemy in Corridor 3 received lance damage (D(1) = 100 -> 100 hull
  // remaining)
  const auto& vessel = registry.get<EnemyVesselComponent>(enemy);
  EXPECT_FLOAT_EQ(vessel.current_hull, 100.0f);
}

TEST(CombatSimulationTest, TacticalCoreGranting) {
  Engine engine;
  engine.Initialize(12, 0.2f);

  auto dread = engine.GetDreadnoughtState();
  EXPECT_EQ(dread.reserve_cores, 12);

  // Grant 3 cores from tactical siphon
  engine.GrantCores(3);
  dread = engine.GetDreadnoughtState();
  EXPECT_EQ(dread.reserve_cores, 15);

  // Grant another 5 cores
  engine.GrantCores(5);
  dread = engine.GetDreadnoughtState();
  EXPECT_EQ(dread.reserve_cores, 20);
}

TEST(CombatSimulationTest, LateralDriftEvasion) {
  Engine engine;
  engine.Initialize(24, 0.2f);

  // Spawn an enemy in corridor 3 (center x ~ 0.4375)
  EXPECT_TRUE(engine.SpawnEnemy(3, 0.85f, 0.02f, 50.0f, 100.0f, 1));
  std::array<EnemyVesselComponent, 16> enemies{};
  uint32_t count = engine.GetEnemies(absl::MakeSpan(enemies));
  ASSERT_EQ(count, 1);
  const float initial_x = enemies[0].world_pos_x;

  // Step without drift: X should remain fixed
  engine.Update(0.1f);
  engine.GetEnemies(absl::MakeSpan(enemies));
  EXPECT_FLOAT_EQ(enemies[0].world_pos_x, initial_x);

  // Enable lateral drift and step: X should shift
  engine.SetLateralDrift(true);
  for (int i = 0; i < 10; ++i) {
    engine.Update(0.05f);
  }
  engine.GetEnemies(absl::MakeSpan(enemies));
  EXPECT_NE(enemies[0].world_pos_x, initial_x);
  EXPECT_GE(enemies[0].world_pos_x, 0.06f);
  EXPECT_LE(enemies[0].world_pos_x, 0.94f);
}

TEST(CombatSimulationTest, ReinforcementEnemySpawning) {
  Engine engine;
  engine.Initialize(24, 0.2f);

  std::array<EnemyVesselComponent, 16> enemies{};
  uint32_t count = engine.GetEnemies(absl::MakeSpan(enemies));
  EXPECT_EQ(count, 0);

  // Spawn 3 reinforcement enemies in different corridors
  EXPECT_TRUE(engine.SpawnEnemy(1, 0.95f, 0.03f, 0.0f, 50.0f, 0));
  EXPECT_TRUE(engine.SpawnEnemy(4, 0.92f, 0.02f, 100.0f, 150.0f, 1));
  EXPECT_TRUE(engine.SpawnEnemy(7, 0.90f, 0.015f, 200.0f, 300.0f, 2));

  count = engine.GetEnemies(absl::MakeSpan(enemies));
  EXPECT_EQ(count, 3);
  bool found_c1 = false;
  bool found_c4 = false;
  bool found_c7 = false;
  for (uint32_t i = 0; i < count; ++i) {
    if (enemies[i].assigned_corridor == 1 && enemies[i].vessel_type == 0) {
      found_c1 = true;
    }
    if (enemies[i].assigned_corridor == 4 && enemies[i].vessel_type == 1) {
      found_c4 = true;
    }
    if (enemies[i].assigned_corridor == 7 && enemies[i].vessel_type == 2) {
      found_c7 = true;
    }
  }
  EXPECT_TRUE(found_c1);
  EXPECT_TRUE(found_c4);
  EXPECT_TRUE(found_c7);
}

}  // namespace void_sower::ecs
