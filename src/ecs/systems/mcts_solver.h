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

#ifndef VOID_SOWER_ECS_SYSTEMS_MCTS_SOLVER_H_
#define VOID_SOWER_ECS_SYSTEMS_MCTS_SOLVER_H_

#include <absl/container/inlined_vector.h>

#include <cstdint>
#include <entt/entt.hpp>

#include "ring_buffer.h"

namespace void_sower::ecs {

/**
 * @brief Discrete action in the Bao orbital battery search space.
 */
struct MctsMove {
  uint8_t bay_index{0};
  int8_t direction{1};  ///< +1: Clockwise, -1: Counter-Clockwise
};

/**
 * @brief Result summary of Monte Carlo Tree Search solvability evaluation.
 */
struct MctsEvaluationResult {
  bool is_solvable{false};
  uint32_t simulated_rollouts{0};
  uint32_t optimal_move_count{0};
  absl::InlinedVector<MctsMove, 16> winning_sequence;
};

/**
 * @brief Monte Carlo Tree Search (UCT) solver for quantifying encounter
 * difficulty and guaranteeing mathematical solvability.
 */
class MctsSolver {
 public:
  explicit MctsSolver(entt::registry& registry);
  ~MctsSolver() = default;

  /// Evaluates whether the current combat wave is solvable within core budget.
  MctsEvaluationResult EvaluateSolvability(uint32_t max_simulations = 400,
                                           uint32_t max_depth = 6);

 private:
  entt::registry& registry_;
};

}  // namespace void_sower::ecs

#endif  // VOID_SOWER_ECS_SYSTEMS_MCTS_SOLVER_H_
