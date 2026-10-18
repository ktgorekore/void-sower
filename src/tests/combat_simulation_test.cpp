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

  // Position dreadnought in Corridor 0 (matching frontline bay 8)
  combat.SetTargetPositionX(0.0625f);
  for (int i = 0; i < 40; ++i) {
    combat.Update(kFixedTimeStep);
  }

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

  // Next step: EvaluateDestination settles in bay 8 WITHOUT auto-firing
  combat.Update(kFixedTimeStep);
  const auto &vessel = registry.get<EnemyVesselComponent>(enemy);
  EXPECT_FLOAT_EQ(vessel.current_shields, 50.0f);
  EXPECT_FLOAT_EQ(vessel.current_hull, 100.0f);

  // Now explicitly trigger weapon discharge on frontline bay 8
  EXPECT_TRUE(combat.DischargeBay(8, 1.0f));

  // Verify enemy in corridor 0 took lance damage (D(1) = 100, absorbs 50 shield
  // + 50 hull -> 50 hull remaining)
  EXPECT_EQ(vessel.current_shields, 0.0f);
  EXPECT_FLOAT_EQ(vessel.current_hull, 50.0f);
  EXPECT_EQ(vessel.is_destroyed, 0);
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

  // Inject into bay 10 (+1) -> lands in bay 11 and primes it without firing
  EXPECT_TRUE(combat.InjectCore(10, 1));
  combat.Update(kFixedTimeStep);  // SowingTraversal
  combat.Update(kFixedTimeStep);  // EvaluateDestination (settles in bay 11)

  const auto &vessel = registry.get<EnemyVesselComponent>(enemy);
  EXPECT_FLOAT_EQ(vessel.current_hull, 200.0f);

  // Explicitly fire bay 11
  EXPECT_TRUE(combat.DischargeBay(11, 1.0f));

  // Check that ParticleLance component was created with origin_x matching
  // dreadnought position
  bool found_lance = false;
  auto lance_view = registry.view<ParticleLanceComponent>();
  for (auto l_entity : lance_view) {
    const auto &lance = lance_view.get<ParticleLanceComponent>(l_entity);
    if (lance.active == 0) continue;
    EXPECT_NEAR(lance.origin_x, 0.4375f, 0.05f);
    EXPECT_EQ(lance.active, 1);
    found_lance = true;
  }
  EXPECT_TRUE(found_lance);

  // Verify enemy in Corridor 3 received lance damage (D(1) = 100 -> 100 hull
  // remaining)
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

TEST(CombatSimulationTest,
     ReinforcementSpawningRestoresVictoryStateAndAdvances) {
  Engine engine;
  engine.Initialize(24, 0.2f);

  // Spawn an initial enemy
  EXPECT_TRUE(engine.SpawnEnemy(2, 0.80f, 0.05f, 0.0f, 10.0f, 0));
  auto &registry = engine.GetRegistry();
  auto view = registry.view<EnemyVesselComponent>();
  ASSERT_NE(view.begin(), view.end());

  // Mark enemy destroyed
  for (auto entity : view) {
    registry.get<EnemyVesselComponent>(entity).is_destroyed = 1;
  }

  // Advance simulation: match should transition to Victory since all enemies
  // destroyed
  engine.Update(0.1f);
  auto dread = engine.GetDreadnoughtState();
  EXPECT_EQ(dread.current_sim_state,
            static_cast<uint8_t>(SimulationState::Victory));

  // Now spawn a reinforcement enemy into corridor 5
  EXPECT_TRUE(engine.SpawnEnemy(5, 0.95f, 0.05f, 50.0f, 100.0f, 1));

  // The dreadnought simulation state MUST be restored to OrbitalIdle!
  dread = engine.GetDreadnoughtState();
  EXPECT_EQ(dread.current_sim_state,
            static_cast<uint8_t>(SimulationState::OrbitalIdle));

  // Step simulation: the reinforcement enemy MUST advance downwards
  std::array<EnemyVesselComponent, 16> enemies{};
  uint32_t count = engine.GetEnemies(absl::MakeSpan(enemies));
  EXPECT_EQ(count, 2);  // 1 destroyed + 1 alive reinforcement

  float initial_reinforcement_y = 0.0f;
  for (uint32_t i = 0; i < count; ++i) {
    if (enemies[i].assigned_corridor == 5) {
      initial_reinforcement_y = enemies[i].world_pos_y;
      EXPECT_EQ(enemies[i].is_destroyed, 0);
    } else {
      EXPECT_EQ(enemies[i].is_destroyed, 1);
    }
  }

  engine.Update(0.2f);
  engine.GetEnemies(absl::MakeSpan(enemies));
  for (uint32_t i = 0; i < count; ++i) {
    if (enemies[i].assigned_corridor == 5) {
      EXPECT_LT(enemies[i].world_pos_y, initial_reinforcement_y);
    }
  }
}

TEST(CombatSimulationTest, Bay15KichwaLanceDischarge) {
  entt::registry registry;
  CombatSystem combat(registry);
  combat.InitializeDreadnought(12, 0.2f);

  // Position dreadnought in Corridor 6 (aligned with destination Bay 14)
  combat.SetTargetPositionX(0.8125f);
  for (int i = 0; i < 40; ++i) {
    combat.Update(kFixedTimeStep);
  }

  // Spawn enemy in Corridor 6 (aligned with Bay 14)
  auto enemy = registry.create();
  registry.emplace<EnemyVesselComponent>(enemy, EnemyVesselComponent{
                                                    .entity_id = 201,
                                                    .assigned_corridor = 6,
                                                    .world_pos_x = 0.8125f,
                                                    .world_pos_y = 0.7f,
                                                    .velocity_y = 0.0f,
                                                    .current_shields = 0.0f,
                                                    .max_shields = 0.0f,
                                                    .current_hull = 200.0f,
                                                    .max_hull = 200.0f,
                                                    .vessel_type = 0,
                                                    .is_destroyed = 0,
                                                });

  // Inject core into Bay 15 with desired direction +1 (clockwise).
  // Under Kichwa rule, direction MUST resolve inward to -1 (towards Bay 14).
  EXPECT_TRUE(combat.InjectCore(15, 1));
  combat.Update(kFixedTimeStep);  // SowingTraversal: steps 15 -> 14

  // Frontline Bay 14 must have received the deposited unit, NOT reservoir Bay 0
  auto bay_view = registry.view<BatteryComponent>();
  for (auto b_entity : bay_view) {
    const auto &b = bay_view.get<BatteryComponent>(b_entity);
    if (b.bay_index == 14) {
      EXPECT_EQ(b.charge_units, 1);
    } else if (b.bay_index == 0) {
      EXPECT_EQ(b.charge_units, 0);
    }
  }

  combat.Update(kFixedTimeStep);  // EvaluateDestination (settles in Bay 14)

  // Sowing alone must not auto-fire
  const auto &vessel = registry.get<EnemyVesselComponent>(enemy);
  EXPECT_FLOAT_EQ(vessel.current_hull, 200.0f);

  // Explicitly discharge primed Bay 14
  EXPECT_TRUE(combat.DischargeBay(14, 1.0f));

  // Verify particle lance fired strictly from dreadnought prow and damaged
  // enemy in Corridor 6
  bool found_lance = false;
  auto lance_view = registry.view<ParticleLanceComponent>();
  for (auto l_entity : lance_view) {
    const auto &lance = lance_view.get<ParticleLanceComponent>(l_entity);
    if (lance.active == 0) continue;
    EXPECT_NEAR(lance.origin_x, 0.8125f, 0.05f);
    found_lance = true;
  }
  EXPECT_TRUE(found_lance);

  EXPECT_FLOAT_EQ(vessel.current_hull, 100.0f);
}

TEST(CombatSimulationTest, Bay8KichwaLanceDischarge) {
  entt::registry registry;
  CombatSystem combat(registry);
  combat.InitializeDreadnought(12, 0.2f);

  // Position dreadnought in Corridor 1 (aligned with destination Bay 9)
  combat.SetTargetPositionX(0.1875f);
  for (int i = 0; i < 40; ++i) {
    combat.Update(kFixedTimeStep);
  }

  // Spawn enemy in Corridor 1 (aligned with Bay 9)
  auto enemy = registry.create();
  registry.emplace<EnemyVesselComponent>(enemy, EnemyVesselComponent{
                                                    .entity_id = 202,
                                                    .assigned_corridor = 1,
                                                    .world_pos_x = 0.1875f,
                                                    .world_pos_y = 0.7f,
                                                    .velocity_y = 0.0f,
                                                    .current_shields = 0.0f,
                                                    .max_shields = 0.0f,
                                                    .current_hull = 200.0f,
                                                    .max_hull = 200.0f,
                                                    .vessel_type = 0,
                                                    .is_destroyed = 0,
                                                });

  // Inject core into Bay 8 with desired direction -1 (counter-clockwise).
  // Under Kichwa rule, direction MUST resolve inward to +1 (towards Bay 9).
  EXPECT_TRUE(combat.InjectCore(8, -1));
  combat.Update(kFixedTimeStep);  // SowingTraversal: steps 8 -> 9

  // Frontline Bay 9 must have received the deposited unit, NOT reservoir Bay 7
  auto bay_view = registry.view<BatteryComponent>();
  for (auto b_entity : bay_view) {
    const auto &b = bay_view.get<BatteryComponent>(b_entity);
    if (b.bay_index == 9) {
      EXPECT_EQ(b.charge_units, 1);
    } else if (b.bay_index == 7) {
      EXPECT_EQ(b.charge_units, 0);
    }
  }

  combat.Update(kFixedTimeStep);  // EvaluateDestination (settles in Bay 9)
  const auto &vessel = registry.get<EnemyVesselComponent>(enemy);
  EXPECT_FLOAT_EQ(vessel.current_hull, 200.0f);

  // Explicitly discharge primed Bay 9
  EXPECT_TRUE(combat.DischargeBay(9, 1.0f));

  // Verify particle lance fired strictly from dreadnought prow and damaged
  // enemy in Corridor 1
  bool found_lance = false;
  auto lance_view = registry.view<ParticleLanceComponent>();
  for (auto l_entity : lance_view) {
    const auto &lance = lance_view.get<ParticleLanceComponent>(l_entity);
    if (lance.active == 0) continue;
    EXPECT_NEAR(lance.origin_x, 0.1875f, 0.05f);
    found_lance = true;
  }
  EXPECT_TRUE(found_lance);

  EXPECT_FLOAT_EQ(vessel.current_hull, 100.0f);
}

TEST(CombatSimulationTest, KichwaVectorConduitMomentumReversalInFlight) {
  entt::registry registry;
  CombatSystem combat(registry);
  combat.InitializeDreadnought(12, 0.2f);

  // Position dreadnought in Corridor 6 (aligned with Bay 14)
  combat.SetTargetPositionX(0.8125f);
  for (int i = 0; i < 40; ++i) {
    combat.Update(kFixedTimeStep);
  }

  // Spawn enemy in Corridor 6
  auto enemy = registry.create();
  registry.emplace<EnemyVesselComponent>(enemy, EnemyVesselComponent{
                                                    .entity_id = 203,
                                                    .assigned_corridor = 6,
                                                    .world_pos_x = 0.8125f,
                                                    .world_pos_y = 0.7f,
                                                    .velocity_y = 0.0f,
                                                    .current_shields = 0.0f,
                                                    .max_shields = 0.0f,
                                                    .current_hull = 500.0f,
                                                    .max_hull = 500.0f,
                                                    .vessel_type = 0,
                                                    .is_destroyed = 0,
                                                });
  combat.RebuildSpatialGrid();

  // Pre-charge Bay 13 with 2 units via RestoreSnapshot
  std::array<uint32_t, kTotalBays> charges{};
  charges[13] = 2;
  combat.RestoreSnapshot(charges, 12, 0);

  // Dry-run forward prediction:
  // From Bay 13 (+1), sows 3 units: 14 (+1) -> 15 (+1) [reverses to -1] -> 14
  // (-1). Lands on frontline Bay 14 with final_mass 2!
  auto pred = combat.PredictSow(13, 1);
  EXPECT_EQ(pred.terminal_bay, 14);
  EXPECT_EQ(pred.terminal_corridor, 6);
  EXPECT_TRUE(pred.triggers_lance);
  EXPECT_EQ(pred.final_mass, 2);

  // Inject core into Bay 13 (+1): Total units to sow = 2 + 1 = 3
  // Step 1: Bay 14 (remaining 2)
  // Step 2: Bay 15 (remaining 1). Reaches Kichwa! Direction inverts: +1 -> -1
  // Step 3: Bay 14 (remaining 0). Lands back on Bay 14!
  EXPECT_TRUE(combat.InjectCore(13, 1));
  combat.Update(kFixedTimeStep);  // Step 1 -> Bay 14
  combat.Update(kFixedTimeStep);  // Step 2 -> Bay 15 (reversal triggered)
  combat.Update(kFixedTimeStep);  // Step 3 -> Bay 14
  combat.Update(
      kFixedTimeStep);  // EvaluateDestination -> settles in Bay 14 with mass 2

  // Verify terminal bay distribution after sowing (before firing):
  // Bay 13: 0
  // Bay 14: 2 (accumulated charge waiting for player fire command)
  // Bay 15: 1 (deposited on step 2)
  // Bay 0:  0 (never entered inner reservoir)
  auto bay_view = registry.view<BatteryComponent>();
  for (auto b_entity : bay_view) {
    const auto &b = bay_view.get<BatteryComponent>(b_entity);
    if (b.bay_index == 13) {
      EXPECT_EQ(b.charge_units, 0);
    } else if (b.bay_index == 14) {
      EXPECT_EQ(b.charge_units, 2);
    } else if (b.bay_index == 15) {
      EXPECT_EQ(b.charge_units, 1);
    } else if (b.bay_index == 0) {
      EXPECT_EQ(b.charge_units, 0);
    }
  }

  // Now explicitly discharge Bay 14
  EXPECT_TRUE(combat.DischargeBay(14, 1.0f));

  // Verify enemy in Corridor 6 took damage from 2-unit lance: D(2) = 400.0f
  const auto &vessel = registry.get<EnemyVesselComponent>(enemy);
  EXPECT_FLOAT_EQ(vessel.current_hull, 100.0f);
}

TEST(CombatSimulationTest, SowingDoesNotAutoFireUntilExplicitlyDischarged) {
  entt::registry registry;
  CombatSystem combat(registry);
  combat.InitializeDreadnought(12, 0.2f);

  // Position dreadnought in Corridor 2 (X = 0.3125f)
  combat.SetTargetPositionX(0.3125f);
  for (int i = 0; i < 40; ++i) {
    combat.Update(kFixedTimeStep);
  }

  // Spawn enemy in Corridor 5 (Bay 13)
  auto enemy_c5 = registry.create();
  registry.emplace<EnemyVesselComponent>(enemy_c5, EnemyVesselComponent{
                                                       .entity_id = 505,
                                                       .assigned_corridor = 5,
                                                       .world_pos_x = 0.6875f,
                                                       .world_pos_y = 0.7f,
                                                       .velocity_y = 0.0f,
                                                       .current_shields = 0.0f,
                                                       .max_shields = 0.0f,
                                                       .current_hull = 500.0f,
                                                       .max_hull = 500.0f,
                                                       .vessel_type = 1,
                                                       .is_destroyed = 0,
                                                   });
  combat.RebuildSpatialGrid();

  std::array<uint32_t, kTotalBays> charges{};
  charges[13] = 2;
  combat.RestoreSnapshot(charges, 12, 0);

  // Inject into bay 12 (+1) -> destination is bay 13
  EXPECT_TRUE(combat.InjectCore(12, 1));
  combat.Update(kFixedTimeStep);  // SowingTraversal: steps 12 -> 13
  combat.Update(kFixedTimeStep);  // EvaluateDestination: settles in bay 13

  // Verify no active lance was auto-spawned during sowing
  auto lance_view = registry.view<ParticleLanceComponent>();
  for (auto l_entity : lance_view) {
    const auto &lance = lance_view.get<ParticleLanceComponent>(l_entity);
    EXPECT_EQ(lance.active, 0);
  }

  // Enemy must be completely untouched during sowing
  const auto &vessel_c5 = registry.get<EnemyVesselComponent>(enemy_c5);
  EXPECT_FLOAT_EQ(vessel_c5.current_hull, 500.0f);
}

TEST(CombatSimulationTest, ReinforcementIdResetsOnInitializeDreadnought) {
  entt::registry registry;
  CombatSystem combat(registry);
  combat.InitializeDreadnought();

  // Spawn an enemy
  EXPECT_TRUE(combat.SpawnEnemy(0, 0.8f, 10.0f, 0.0f, 100.0f, 0));
  auto view1 = registry.view<EnemyVesselComponent>();
  uint32_t first_id = 0;
  for (auto entity : view1) {
    first_id = view1.get<EnemyVesselComponent>(entity).entity_id;
  }
  EXPECT_EQ(first_id, 10000u);

  // Spawn a second enemy
  EXPECT_TRUE(combat.SpawnEnemy(1, 0.8f, 10.0f, 0.0f, 100.0f, 0));

  // Re-initialize dreadnought
  combat.InitializeDreadnought();
  registry.clear();

  // Spawn an enemy after re-initialization
  EXPECT_TRUE(combat.SpawnEnemy(2, 0.8f, 10.0f, 0.0f, 100.0f, 0));
  auto view2 = registry.view<EnemyVesselComponent>();
  uint32_t reset_id = 0;
  for (auto entity : view2) {
    reset_id = view2.get<EnemyVesselComponent>(entity).entity_id;
  }
  EXPECT_EQ(reset_id, 10000u);
}

TEST(CombatSimulationTest, DefaultBoundaryLineIsFifteenHundredths) {
  Engine engine;
  engine.Initialize();
  auto dread = engine.GetDreadnoughtState();
  EXPECT_FLOAT_EQ(dread.boundary_line_y, 0.15f);
  EXPECT_FLOAT_EQ(dread.orbital_position_y, 0.15f);

  entt::registry registry;
  CombatSystem combat(registry);
  combat.InitializeDreadnought();
  auto view = registry.view<DreadnoughtStateComponent>();
  for (auto entity : view) {
    const auto &state = view.get<DreadnoughtStateComponent>(entity);
    EXPECT_FLOAT_EQ(state.boundary_line_y, 0.15f);
    EXPECT_FLOAT_EQ(state.orbital_position_y, 0.15f);
  }
}

TEST(CombatSimulationTest, Invader3DTelemetryAndFlightBehaviors) {
  entt::registry registry;
  CombatSystem combat(registry);
  combat.InitializeDreadnought();

  // 1. Spawn a Swooper Drone
  EXPECT_TRUE(combat.SpawnEnemy(2, 0.85f, 0.05f, 50.0f, 100.0f, 0));
  auto view = registry.view<EnemyVesselComponent>();
  entt::entity swooper_entity = *view.begin();
  auto &swooper = registry.get<EnemyVesselComponent>(swooper_entity);
  swooper.behavior_mode = 1;  // Swooper
  swooper.warp_in_progress = 0.0f;

  // 2. Advance simulation multiple frames
  for (int f = 0; f < 30; ++f) {
    combat.Update(kFixedTimeStep);
  }

  // 3. Verify warp-in materialized and 3D telemetry calculated
  EXPECT_GT(swooper.warp_in_progress, 0.5f);
  EXPECT_FLOAT_EQ(swooper.world_pos_z, 1.0f - swooper.world_pos_y);
  EXPECT_NE(swooper.bank_angle_rad, 0.0f);
  EXPECT_NE(swooper.pitch_angle_rad, 0.0f);
  EXPECT_GE(swooper.assigned_corridor, 0);
  EXPECT_LE(swooper.assigned_corridor, 7);
}

TEST(CombatSimulationTest, StepFSMInvalidEntityHandle) {
  entt::registry registry;
  DischargeSystem discharge_system;
  MatchLifecycleSystem match_lifecycle_system;
  SpatialGrid spatial_grid;
  BaoCascadeSystem bao_cascade_system;
  std::array<entt::entity, kTotalBays> bay_entities{};
  bay_entities.fill(entt::null);

  // Calling StepFSM with an invalid (null) dreadnought entity should not crash
  bao_cascade_system.StepFSM(registry, entt::null, bay_entities, spatial_grid,
                             discharge_system, match_lifecycle_system, 0.016f);
}

TEST(CombatSimulationTest, InjectCoreSelfHealsTransitionalStates) {
  Engine engine;
  engine.Initialize(10, 0.15f);

  auto &registry = engine.GetRegistry();
  auto dread_view = registry.view<DreadnoughtStateComponent>();
  ASSERT_NE(dread_view.begin(), dread_view.end());
  auto dread_entity = *dread_view.begin();
  auto &dread = registry.get<DreadnoughtStateComponent>(dread_entity);

  // 1. Manually set state to CrossDischarge (post-lance discharge transitional
  // state)
  dread.current_sim_state =
      static_cast<uint8_t>(SimulationState::CrossDischarge);

  // InjectCore should self-heal the transitional state and succeed
  EXPECT_TRUE(engine.InjectCore(8, 1));
  EXPECT_EQ(dread.reserve_cores, 9u);

  // 2. Set to CleanupCheck
  dread.current_sim_state = static_cast<uint8_t>(SimulationState::CleanupCheck);
  EXPECT_TRUE(engine.InjectCore(9, 1));
  EXPECT_EQ(dread.reserve_cores, 8u);

  // 3. Set GameOver while reserve cores > 0
  dread.current_sim_state = static_cast<uint8_t>(SimulationState::GameOver);
  EXPECT_TRUE(engine.InjectCore(10, 1));
  EXPECT_EQ(dread.reserve_cores, 7u);
}

TEST(CombatSimulationTest, ReapDestroyedEnemiesAfterTenTicks) {
  Engine engine;
  engine.Initialize(10, 0.15f);

  // Spawn an enemy
  EXPECT_TRUE(engine.SpawnEnemy(2, 0.8f, 0.02f, 0.0f, 50.0f, 0));
  auto &registry = engine.GetRegistry();
  auto view = registry.view<EnemyVesselComponent>();
  ASSERT_NE(view.begin(), view.end());

  // Mark enemy as destroyed
  auto enemy_entity = *view.begin();
  registry.get<EnemyVesselComponent>(enemy_entity).is_destroyed = 1;

  // Run 9 ticks - enemy should still exist for FFI polling
  for (int i = 0; i < 9; ++i) {
    engine.Update(0.016f);
    EXPECT_TRUE(registry.valid(enemy_entity));
  }

  // 10th tick should reap the destroyed enemy
  engine.Update(0.016f);
  EXPECT_FALSE(registry.valid(enemy_entity));
}

TEST(CombatSimulationTest,
     InjectCoreDuringActiveSowingTraversalSelfHealsAndInjects) {
  Engine engine;
  engine.Initialize(10, 0.15f);

  auto &registry = engine.GetRegistry();
  auto dread_view = registry.view<DreadnoughtStateComponent>();
  ASSERT_NE(dread_view.begin(), dread_view.end());
  auto dread_entity = *dread_view.begin();
  auto &dread = registry.get<DreadnoughtStateComponent>(dread_entity);

  // 1. First injection starts sowing traversal
  EXPECT_TRUE(engine.InjectCore(8, 1));
  EXPECT_EQ(dread.reserve_cores, 9u);
  EXPECT_EQ(dread.current_sim_state,
            static_cast<uint8_t>(SimulationState::SowingTraversal));
  EXPECT_EQ(dread.is_cascading, 1);
  EXPECT_TRUE(registry.all_of<SowingStateComponent>(dread_entity));

  // 2. Second rapid injection while mid-traversal should self-heal and inject
  // immediately
  EXPECT_TRUE(engine.InjectCore(8, 1));
  EXPECT_EQ(dread.reserve_cores, 8u);
  EXPECT_EQ(dread.current_sim_state,
            static_cast<uint8_t>(SimulationState::SowingTraversal));
  EXPECT_EQ(dread.is_cascading, 1);
}

TEST(CombatSimulationTest,
     GrantCoresRepelsBreachingEnemiesAndSelfHealsGameOver) {
  Engine engine;
  engine.Initialize(10, 0.15f);

  // Spawn enemy right at atmospheric boundary (breaching position)
  EXPECT_TRUE(engine.SpawnEnemy(2, 0.14f, 0.02f, 0.0f, 50.0f, 0));

  // Update should flag GameOver due to breach
  engine.Update(0.016f);
  EXPECT_EQ(engine.GetSimulationState(), SimulationState::GameOver);

  // Grant cores (e.g. from watching an ad or emergency flare)
  engine.GrantCores(8);
  EXPECT_EQ(engine.GetSimulationState(), SimulationState::OrbitalIdle);

  auto &registry = engine.GetRegistry();
  auto view = registry.view<EnemyVesselComponent>();
  ASSERT_NE(view.begin(), view.end());
  auto enemy_entity = *view.begin();
  const auto &enemy = view.get<EnemyVesselComponent>(enemy_entity);

  // Enemy must be repelled safely above the boundary line (>= 0.15 + 0.30 =
  // 0.45)
  EXPECT_GE(enemy.world_pos_y, 0.45f);

  // Next simulation tick should NOT immediately re-trigger GameOver
  engine.Update(0.016f);
  EXPECT_EQ(engine.GetSimulationState(), SimulationState::OrbitalIdle);
}

TEST(CombatSimulationTest, Phase27PredictCascadeAlphaMultiplierParity) {
  entt::registry registry;
  CombatSystem combat(registry);
  combat.InitializeDreadnought(12, 0.2f);

  // Set lance alpha multiplier to 2.5
  combat.SetLanceAlphaMultiplier(2.5f);

  // Predict from bay 13, direction 1
  auto pred = combat.PredictSow(13, 1);
  EXPECT_TRUE(pred.triggers_lance);
  EXPECT_GT(pred.final_mass, 0u);
  // Base quadratic damage: final_mass^2 * 100.0f * 2.5f
  const float expected_damage =
      static_cast<float>(pred.final_mass * pred.final_mass) * 100.0f * 2.5f;
  EXPECT_FLOAT_EQ(pred.predicted_damage, expected_damage);
}

TEST(CombatSimulationTest,
     DirectBayDischargeUnleashesStoredMassAndTriadMultiplier) {
  Engine engine;
  engine.Initialize(10, 0.2f);

  // Spawn an enemy in Corridor 3 (Frontline Bay 11) with 600 hull
  ASSERT_TRUE(engine.SpawnEnemy(3, 0.75f, 0.0f, 0.0f, 600.0f, 1));

  // Pre-charge Bay 11 with M = 2 units (base damage = 400, triad 1.5x = 600)
  std::array<uint32_t, kTotalBays> charges{};
  charges[11] = 2;
  engine.RestoreSnapshot(charges, 10, 0);

  // Execute direct bay discharge with 1.5x Morabaraba Mill Triad multiplier
  EXPECT_TRUE(engine.DischargeBay(11, 1.5f));

  // Verify Bay 11 was emptied without consuming a reserve core
  std::array<BatteryComponent, kTotalBays> bays{};
  engine.GetBays(absl::MakeSpan(bays));
  EXPECT_EQ(bays[11].charge_units, 0u);
  EXPECT_EQ(engine.GetDreadnoughtState().reserve_cores, 10u);

  // Verify enemy took 400 * 1.5 = 600 damage and was destroyed
  std::array<EnemyVesselComponent, 8> enemies{};
  uint32_t count = engine.GetEnemies(absl::MakeSpan(enemies));
  ASSERT_EQ(count, 1u);
  EXPECT_EQ(enemies[0].is_destroyed, 1);
}

TEST(CombatSimulationTest,
     BaoMtajiChainCaptureHarvestsEnemyEnergyAndContinuesCascade) {
  entt::registry registry;
  CombatSystem combat(registry);
  combat.InitializeDreadnought(12, 0.2f);

  // Align dreadnought in Corridor 2 (Frontline Bay 10, X = 0.3125f)
  combat.SetTargetPositionX(0.3125f);
  for (int i = 0; i < 40; ++i) {
    combat.Update(kFixedTimeStep);
  }

  // Spawn enemy in Corridor 2 with 600 hull
  ASSERT_TRUE(combat.SpawnEnemy(2, 0.75f, 0.0f, 0.0f, 600.0f, 1));

  // Pre-charge Bay 10 with 1 unit so landing on it produces final_mass = 2
  std::array<uint32_t, kTotalBays> charges{};
  charges[10] = 1;
  combat.RestoreSnapshot(charges, 12, 0);

  // Inject into Bay 9 (+1 CW) -> lands on Bay 10 with final_mass = 2
  ASSERT_TRUE(combat.InjectCore(9, 1));
  combat.Update(kFixedTimeStep);  // Step 9 -> 10 (remaining_units = 0)
  combat.Update(kFixedTimeStep);  // EvaluateDestination -> settles in Bay 10

  // Explicitly discharge primed Bay 10 (mass = 2) -> fires lance and harvests
  // +2 Mtaji seeds into SowingTraversal!
  ASSERT_TRUE(combat.DischargeBay(10, 1.0f));
  EXPECT_EQ(combat.GetSimulationState(), SimulationState::SowingTraversal);

  // Advance 2 more steps to sow the 2 harvested Mtaji seeds into Bays 11 & 12
  combat.Update(kFixedTimeStep);  // Step -> Bay 11
  combat.Update(kFixedTimeStep);  // Step -> Bay 12

  auto bay_view = registry.view<BatteryComponent>();
  uint32_t bay11_charge = 0;
  uint32_t bay12_charge = 0;
  for (auto ent : bay_view) {
    const auto &b = bay_view.get<BatteryComponent>(ent);
    if (b.bay_index == 11) bay11_charge = b.charge_units;
    if (b.bay_index == 12) bay12_charge = b.charge_units;
  }
  EXPECT_EQ(bay11_charge, 1u);
  EXPECT_EQ(bay12_charge, 1u);
}

TEST(CombatSimulationTest, FanoronaApproachAndWithdrawalVectorStrikes) {
  Engine engine;
  engine.Initialize(12, 0.2f);

  // Position dreadnought in Corridor 4 (X = 0.5625f)
  engine.SetTargetPosition(0.5625f, 0.45f);
  ASSERT_TRUE(engine.SpawnEnemy(4, 0.60f, 0.0f, 100.0f, 200.0f, 1));

  // Trigger Fanorona Approach Strike
  EXPECT_TRUE(engine.TriggerFanoronaStrike(true));

  std::array<EnemyVesselComponent, 8> enemies{};
  ASSERT_EQ(engine.GetEnemies(absl::MakeSpan(enemies)), 1u);
  EXPECT_EQ(enemies[0].current_shields, 0.0f);
  EXPECT_LT(enemies[0].current_hull, 200.0f);

  // Trigger Fanorona Withdrawal Pulse
  EXPECT_TRUE(engine.TriggerFanoronaStrike(false));
  std::array<FlakBurstComponent, 8> flaks{};
  EXPECT_GT(engine.GetFlakBursts(absl::MakeSpan(flaks)), 0u);
}

TEST(CombatSimulationTest,
     YoteSurgicalCullTargetsSpecificOrHighestThreatEnemy) {
  Engine engine;
  engine.Initialize(12, 0.2f);

  // Spawn an Escort in Corridor 1 and a Cruiser in Corridor 6
  ASSERT_TRUE(engine.SpawnEnemy(1, 0.80f, 0.0f, 0.0f, 100.0f, 0));
  ASSERT_TRUE(engine.SpawnEnemy(6, 0.70f, 0.0f, 150.0f, 300.0f, 1));

  // Execute Yoté Surgical Cull with entity_id = 0 (auto-prioritizes Cruiser)
  EXPECT_TRUE(engine.CullEnemy(0));

  std::array<EnemyVesselComponent, 8> enemies{};
  uint32_t count = engine.GetEnemies(absl::MakeSpan(enemies));
  ASSERT_EQ(count, 2u);
  for (uint32_t i = 0; i < count; ++i) {
    if (enemies[i].assigned_corridor == 6) {
      EXPECT_EQ(enemies[i].is_destroyed, 1);
    } else if (enemies[i].assigned_corridor == 1) {
      EXPECT_EQ(enemies[i].is_destroyed, 0);
    }
  }
}

TEST(CombatSimulationTest, SmoothInvaderSeparationNoStuttering) {
  Engine engine;
  engine.Initialize(12, 0.2f);
  engine.SetLateralDrift(true);

  // Spawn two invaders close together in the same corridor
  ASSERT_TRUE(engine.SpawnEnemy(3, 0.80f, 0.02f, 50.0f, 100.0f, 0));
  ASSERT_TRUE(engine.SpawnEnemy(3, 0.84f, 0.02f, 50.0f, 100.0f, 1));

  std::array<EnemyVesselComponent, 8> prev{};
  std::array<EnemyVesselComponent, 8> curr{};
  ASSERT_EQ(engine.GetEnemies(absl::MakeSpan(prev)), 2u);

  for (int step = 0; step < 60; ++step) {
    engine.Update(kFixedTimeStep);
    ASSERT_EQ(engine.GetEnemies(absl::MakeSpan(curr)), 2u);
    for (size_t i = 0; i < 2; ++i) {
      const float dx = std::abs(curr[i].world_pos_x - prev[i].world_pos_x);
      const float dy = std::abs(curr[i].world_pos_y - prev[i].world_pos_y);
      // Verify no sudden position teleportation (> 0.015 per 16ms frame)
      EXPECT_LT(dx, 0.015f);
      EXPECT_LT(dy, 0.015f);
    }
    prev = curr;
  }
}

TEST(CombatSimulationTest,
     FrontlineBaysNeverAutoFireWithoutPlayerCommandAndKillHarvestsSeeds) {
  Engine engine;
  engine.Initialize(10, 0.2f);

  // Spawn an enemy in Corridor 2 (Totem Bay 10) with 500 hull, and a second
  // enemy in Corridor 5 so the match stays in OrbitalIdle.
  ASSERT_TRUE(engine.SpawnEnemy(2, 0.75f, 0.0f, 0.0f, 500.0f, 1));
  ASSERT_TRUE(engine.SpawnEnemy(5, 0.85f, 0.0f, 0.0f, 500.0f, 1));

  // Set Totem Bay 10 to M = 2
  std::array<uint32_t, kTotalBays> charges{};
  charges[10] = 2;
  engine.RestoreSnapshot(charges, 10, 0);

  // Step 3.0 seconds (180 ticks of 0.0166s): frontline bays must NEVER
  // auto-fire without an explicit player discharge command!
  for (int i = 0; i < 180; ++i) {
    engine.Update(kFixedTimeStep);
  }

  std::array<BatteryComponent, kTotalBays> bays{};
  engine.GetBays(absl::MakeSpan(bays));
  EXPECT_EQ(bays[10].charge_units, 2u);

  std::array<EnemyVesselComponent, 8> enemies{};
  ASSERT_EQ(engine.GetEnemies(absl::MakeSpan(enemies)), 2u);
  float corridor2_hull = 0.0f;
  for (const auto &e : enemies) {
    if (e.assigned_corridor == 2) corridor2_hull = e.current_hull;
  }
  EXPECT_FLOAT_EQ(corridor2_hull, 500.0f);

  // Now explicitly fire Bay 10 (M = 2 -> 400 DMG) via player command
  ASSERT_TRUE(engine.DischargeBay(10, 1.0f));
  ASSERT_EQ(engine.GetEnemies(absl::MakeSpan(enemies)), 2u);
  for (const auto &e : enemies) {
    if (e.assigned_corridor == 2) corridor2_hull = e.current_hull;
  }
  EXPECT_FLOAT_EQ(corridor2_hull, 100.0f);

  // Finish off the weakened enemy in Corridor 2 (100 hull left) and verify
  // killing the enemy harvests seeds into Bay 11
  charges[10] = 1;
  engine.RestoreSnapshot(charges, 10, 0);
  ASSERT_TRUE(engine.DischargeBay(10, 1.0f));
  EXPECT_EQ(engine.GetSimulationState(), SimulationState::SowingTraversal);
  engine.Update(kFixedTimeStep);
  engine.GetBays(absl::MakeSpan(bays));
  EXPECT_EQ(bays[11].charge_units, 1u);
}

TEST(CombatSimulationTest, IntelligentEnemyEvadesChargedCorridor) {
  Engine engine;
  engine.Initialize(12, 0.2f);
  engine.SetLateralDrift(true);

  // Spawn a Flagship (vessel_type = 2, behavior_mode = 0) in Corridor 3
  ASSERT_TRUE(engine.SpawnEnemy(3, 0.80f, 0.01f, 100.0f, 300.0f, 2));

  // Charge Bay 11 (Corridor 3) with M = 4 and Bay 10 (Corridor 2) with M = 3,
  // leaving Bay 12 (Corridor 4, right side) at M = 0 (unshielded/safe).
  std::array<uint32_t, kTotalBays> charges{};
  charges[10] = 3;
  charges[11] = 4;
  charges[12] = 0;
  engine.RestoreSnapshot(charges, 12, 0);

  std::array<EnemyVesselComponent, 8> enemies{};
  ASSERT_EQ(engine.GetEnemies(absl::MakeSpan(enemies)), 1u);
  const float start_x = enemies[0].world_pos_x;

  // Step simulation: intelligent flagship should steer right (+X) toward the
  // uncharged Corridor 4
  for (int i = 0; i < 45; ++i) {
    engine.Update(kFixedTimeStep);
  }
  ASSERT_EQ(engine.GetEnemies(absl::MakeSpan(enemies)), 1u);
  EXPECT_GT(enemies[0].world_pos_x, start_x);
}

}  // namespace void_sower::ecs
