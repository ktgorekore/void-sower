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
#include "void_sower.h"

namespace void_sower::ecs {

TEST(SpatialCombat2DTest, Dreadnought2DMovementAndClamping) {
  entt::registry registry;
  CombatSystem combat(registry);
  combat.InitializeDreadnought(24, 0.20f);

  entt::entity dread_entity = entt::null;
  auto view = registry.view<DreadnoughtStateComponent>();
  for (auto entity : view) {
    dread_entity = entity;
    break;
  }
  ASSERT_TRUE(dread_entity != entt::null);

  // Baseline at initialization
  const auto& dread_initial =
      registry.get<DreadnoughtStateComponent>(dread_entity);
  EXPECT_FLOAT_EQ(dread_initial.orbital_position_y, 0.20f);
  EXPECT_FLOAT_EQ(dread_initial.proximity_multiplier, 1.0f);

  // Push forward into deep space
  combat.SetTargetPosition(0.80f, 0.55f);

  const auto& dread = registry.get<DreadnoughtStateComponent>(dread_entity);
  EXPECT_FLOAT_EQ(dread.target_position_x, 0.80f);
  EXPECT_FLOAT_EQ(dread.target_position_y, 0.55f);
  EXPECT_FLOAT_EQ(dread.orbital_position_x, 0.80f);
  EXPECT_FLOAT_EQ(dread.orbital_position_y, 0.55f);

  // Proximity multiplier at y=0.55:
  // forward_depth = 0.55 - 0.20 = 0.35
  // norm_forward = 0.35 / 0.45 = 0.7777778
  // mult = 1.0 + 0.6 * (0.35 / 0.45) = 1.0 + 0.466667 = 1.466667
  EXPECT_NEAR(dread.proximity_multiplier, 1.466667f, 0.001f);

  // Test clamping bounds above 0.65
  combat.SetTargetPosition(1.50f, 0.95f);
  EXPECT_FLOAT_EQ(dread.target_position_x, 1.0f);
  EXPECT_FLOAT_EQ(dread.target_position_y, 0.65f);
  EXPECT_NEAR(dread.proximity_multiplier, 1.60f, 0.001f);

  // Test clamping bounds below boundary_line_y (0.20)
  combat.SetTargetPosition(-0.50f, 0.05f);
  EXPECT_FLOAT_EQ(dread.target_position_x, 0.0f);
  EXPECT_FLOAT_EQ(dread.target_position_y, 0.20f);
  EXPECT_FLOAT_EQ(dread.proximity_multiplier, 1.0f);
}

TEST(SpatialCombat2DTest, ProximityScalesQuadraticLanceDamageInDeepSpace) {
  entt::registry registry;
  CombatSystem combat(registry);
  combat.InitializeDreadnought(24, 0.20f);

  // Position in corridor 0 at maximum forward vanguard depth (y = 0.65)
  // Corridor 0 center is x = 0.5 / 8.0 = 0.0625f
  combat.SetTargetPosition(0.0625f, 0.65f);

  // Spawn an armored enemy in corridor 0
  auto enemy = registry.create();
  registry.emplace<EnemyVesselComponent>(enemy, EnemyVesselComponent{
                                                    .entity_id = 901,
                                                    .assigned_corridor = 0,
                                                    .world_pos_x = 0.0625f,
                                                    .world_pos_y = 0.85f,
                                                    .velocity_y = 0.01f,
                                                    .current_shields = 50.0f,
                                                    .max_shields = 50.0f,
                                                    .current_hull = 200.0f,
                                                    .max_hull = 200.0f,
                                                    .vessel_type = 1,
                                                    .is_destroyed = 0,
                                                });
  combat.RebuildSpatialGrid();

  // Inject into bay 7 (+1 CW) -> destination is bay 8 (corridor 0)
  EXPECT_TRUE(combat.InjectCore(7, 1));

  // Step SowingTraversal
  combat.Update(kFixedTimeStep);
  // Step EvaluateDestination & CrossDischarge
  combat.Update(kFixedTimeStep);

  // In deep space at y=0.65, proximity multiplier is 1.60.
  // Base lance damage M=1 is 100.
  // Scaled lance damage is 100 * 1.60 = 160.
  // Absorbs 50 shield + 110 hull -> hull remaining = 200 - 110 = 90.0f!
  const auto& vessel = registry.get<EnemyVesselComponent>(enemy);
  EXPECT_FLOAT_EQ(vessel.current_shields, 0.0f);
  EXPECT_FLOAT_EQ(vessel.current_hull, 90.0f);
  EXPECT_EQ(vessel.is_destroyed, 0);

  // Verify particle lance beam origin Y is at the dreadnought's position (0.65)
  auto lance_view = registry.view<ParticleLanceComponent>();
  bool found_lance = false;
  for (auto l_ent : lance_view) {
    const auto& lance = lance_view.get<ParticleLanceComponent>(l_ent);
    if (lance.active != 0) {
      found_lance = true;
      EXPECT_FLOAT_EQ(lance.origin_x, 0.0625f);
      EXPECT_FLOAT_EQ(lance.origin_y, 0.65f);
      EXPECT_FLOAT_EQ(lance.total_damage, 160.0f);
    }
  }
  EXPECT_TRUE(found_lance);
}

TEST(SpatialCombat2DTest, TacticalQuestLifecycleAndFFIStateExport) {
  void_sower_init(28, 0.20f);

  VoidSowerDreadnoughtFFI initial_state{};
  void_sower_get_dreadnought_state(&initial_state);
  EXPECT_FLOAT_EQ(initial_state.orbital_position_y, 0.20f);
  EXPECT_FLOAT_EQ(initial_state.proximity_multiplier, 1.0f);
  EXPECT_EQ(initial_state.active_quest_type, 0);
  EXPECT_EQ(initial_state.quest_status, 0);

  // Move dreadnought in 2D space via FFI
  void_sower_set_dreadnought_target(0.50f, 0.425f);

  // Step simulation
  void_sower_step_simulation(kFixedTimeStep);

  // Activate Outpost Reclamation quest
  void_sower_set_active_quest(
      static_cast<uint8_t>(QuestType::OutpostReclamation));

  // Update progress
  void_sower_update_quest(0.75f, static_cast<uint8_t>(QuestStatus::InProgress));

  VoidSowerDreadnoughtFFI active_state{};
  void_sower_get_dreadnought_state(&active_state);
  EXPECT_FLOAT_EQ(active_state.target_position_x, 0.50f);
  EXPECT_FLOAT_EQ(active_state.target_position_y, 0.425f);
  EXPECT_EQ(active_state.active_quest_type,
            static_cast<uint8_t>(QuestType::OutpostReclamation));
  EXPECT_EQ(active_state.quest_status,
            static_cast<uint8_t>(QuestStatus::InProgress));
  EXPECT_FLOAT_EQ(active_state.quest_progress, 0.75f);

  // Complete quest
  void_sower_update_quest(1.0f, static_cast<uint8_t>(QuestStatus::Completed));
  void_sower_get_dreadnought_state(&active_state);
  EXPECT_EQ(active_state.quest_status,
            static_cast<uint8_t>(QuestStatus::Completed));
  EXPECT_FLOAT_EQ(active_state.quest_progress, 1.0f);

  void_sower_free();
}

}  // namespace void_sower::ecs
