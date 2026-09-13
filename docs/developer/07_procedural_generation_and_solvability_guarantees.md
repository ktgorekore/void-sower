<!--
  Copyright 2026 Void Sower Authors.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

      http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
-->

# Void Sower Developer Guide: Procedural Wave Generation & Solvability Guarantees

[◄ Developer Hub](README.md) | [01: Game Rules](01_game_rules_and_mechanics.md) | [02: ECS Engine](02_cpp_ecs_engine_architecture.md) | [03: FFI Bridge](03_dart_ffi_bridge_and_isolate_architecture.md) | [04: Presentation](04_presentation_shaders_and_audio_visual_pipeline.md) | [05: Campaign](05_campaign_economy_and_player_identity.md) | [06: Testing](06_apis_integration_and_testing_guide.md) | [07: Procedural Generation](07_procedural_generation_and_solvability_guarantees.md)

---

## 1. Algorithmic Overview & Mathematical Invariants

In high-stakes tactical puzzle shooters, randomly spawning enemies across attack corridors often produces **mathematically impossible encounters** where the player is starved of plasma cores or incapable of generating required lance mass before enemy craft breach the atmospheric boundary line ($y = 0.20$).

To guarantee fairness, player trust, and competitive integrity, **Void Sower** abandons naive random spawning. Instead, the procedural engine implements **Backward-Play Program Inversion** paired with **Monte Carlo Tree Search (MCTS)** verification.

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                 BACKWARD-PLAY PROGRAM INVERSION PIPELINE                    │
│                                                                             │
│  [Step 1: Terminal Victory State] ──► Empty board, all enemies cleared      │
│                 │                                                           │
│                 ▼                                                           │
│  [Step 2: Inverted Sowing Moves]  ──► Execute K reverse sowing steps        │
│                 │                     Accumulate required core budget B     │
│                 ▼                                                           │
│  [Step 3: Forward Projection]     ──► Place enemies in corridors aligned    │
│                 │                     with projected quadratic lance hits   │
│                 ▼                                                           │
│  [Step 4: MCTS UCT Verification]  ──► 400 rollouts, depth 6                 │
│                                       Quantify optimal move count & stars   │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 2. Backward-Play Program Inversion Algorithm ([`src/ecs/systems/wave_generator.cpp`](file:///home/kelvingorekore/projects/void-sower/src/ecs/systems/wave_generator.cpp))

Program inversion is a formal algorithmic technique that synthesizes solvable initial states by running simulation rules in reverse:

### 2.1 Inverted Step Mechanics
1. **Target Allocation**: The generator selects $K$ target corridors to receive particle lance discharges based on the chosen difficulty tier ($K \in [1, 2]$ for Tier 1, $K \in [3, 5]$ for Tier 2, $K \ge 6$ for Tier 3).
2. **Reverse Sowing Traversal**:
   - Starting from a desired terminal frontline bay $b_{\text{term}} \in [8, 15]$, the generator rewinds the sowing path by stepping in reverse:
     $$b_{k-1} = (b_k - \vec{d} + 16) \ \& \ 0\text{x}0\text{F}$$
   - Masses are gathered rather than deposited, determining the exact initial bay state and core injection sequence required to recreate the terminal discharge.
3. **Enemy Vessel Parameter Synthesis**:
   - For each corridor $C_i$ targeted by an inverted lance of mass $M_i$, the generator instantiates an enemy vessel with hit points matching the expected quadratic damage:
     $$\text{Total HP}(C_i) \le \alpha \cdot M_i^2$$
   - The vessel's initial altitude $y_{\text{start}}$ and velocity $v_y$ are set such that it arrives precisely at the optimal firing window before breaching the boundary:
     $$y_{\text{start}} = y_{\text{boundary}} + v_y \cdot t_{\text{intercept}}$$

### 2.2 Mathematical Proof of Solvability
Because every generated encounter is constructed as the direct forward replay of a proven backward trajectory, the encounter is guaranteed by construction to have **at least one valid canonical solution sequence** within the player's core budget:

$$\exists \ \mathcal{S}^* = \langle (b_1, \vec{d}_1), (b_2, \vec{d}_2), \dots, (b_K, \vec{d}_K) \rangle \quad \text{s.t.} \quad \text{SimState}(\mathcal{S}^*) = \text{Victory}$$

---

## 3. Monte Carlo Tree Search (MCTS) Solvability Quantification ([`src/ecs/systems/mcts_solver.cpp`](file:///home/kelvingorekore/projects/void-sower/src/ecs/systems/mcts_solver.cpp))

To quantify the cognitive difficulty of the generated wave and assign the baseline $\text{optimal\_moves}$ metric for star ratings, the engine runs a native C++ **MCTS Solver** using the **Upper Confidence bounds applied to Trees (UCT)** algorithm.

### 3.1 The UCT Selection Formula
At each tree node during simulation selection, child action $a$ is chosen to maximize:

$$UCT(s, a) = Q(s, a) + c \cdot \sqrt{\frac{\ln N(s)}{N(s, a)}}$$

where:
- $Q(s, a)$ is the empirical win rate of taking move $a$ from state $s$.
- $N(s)$ is the visit count of parent state $s$.
- $N(s, a)$ is the visit count of child action $(s, a)$.
- $c = \sqrt{2} \approx 1.414$ is the theoretical exploration vs. exploitation parameter.

### 3.2 Evaluation Result Schema ([`src/ecs/systems/mcts_solver.h`](file:///home/kelvingorekore/projects/void-sower/src/ecs/systems/mcts_solver.h))
```cpp
struct MctsEvaluationResult {
  bool is_solvable;                    // True if a winning path was found
  uint32_t simulated_rollouts;         // Total rollouts evaluated (up to 400)
  uint32_t optimal_move_count;         // Shortest move sequence to victory
  std::vector<MctsMove> winning_sequence; // Canonical sequence of (bay, dir)
};
```

---

## 4. Encounter Difficulty Taxonomy

Encounter difficulty is parameterized across three distinct operational tiers in [`EncounterDifficulty`](file:///home/kelvingorekore/projects/void-sower/src/ecs/systems/wave_generator.h#L28-L32):

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                      ENCOUNTER DIFFICULTY TAXONOMY                          │
├────────────────────┬──────────────┬────────────┬─────────────┬──────────────┤
│ Tier Class         │ Move Depth   │ Core Cap   │ Craft Types │ Cascade Need │
├────────────────────┼──────────────┼────────────┼─────────────┼──────────────┤
│ **Sector Patrol**  │ 1 to 2 Moves │ 12 Cores   │ Escort      │ Linear Sows  │
│ **Planetary Siege**│ 3 to 5 Moves │ 24 Cores   │ Cruiser     │ Relay Sows   │
│ **Flagship Bastion**│ 6+ Moves    │ 36 Cores   │ Boss + Wing │ Multi-Laps   │
└────────────────────┴──────────────┴────────────┴─────────────┴──────────────┘
```

### 4.1 Tier 1: Sector Patrol (Outer Bastions)
- **Objective**: Introduce fundamental Bao sowing traversal and frontline corridor alignment.
- **Craft Composition**: Light escort drones descending at moderate speed ($v_y = 0.03$).
- **Solution Strategy**: Single-lap sowing directly into frontline bays $8$ to $15$.

### 4.2 Tier 2: Planetary Siege (Monsoon Straits)
- **Objective**: Require strategic inner reservoir charge storage and secondary flak detonations.
- **Craft Composition**: Armored cruisers with kinetic shields requiring $M \ge 2$ ($D \ge 400$).
- **Solution Strategy**: Sowing into inner bays to trigger single-lap relay overloads that discharge amplified particle lances.

### 4.3 Tier 3: Flagship Bastion (Citadel Core)
- **Objective**: Full tactical mastery combining Nyumba super-capacitors, Kichwa vector reversals, and multi-lap cascade overloads.
- **Craft Composition**: Multi-segment Flagship boss accompanied by flanking escort screens.
- **Solution Strategy**: Coordinating 4-to-6 core deposits into Nyumba bays $3$ and $4$ to unleash catastrophic quadratic lances ($D \ge 1,600$).

---

## 🧭 Navigation

| [◄ 06: APIs & Testing](06_apis_integration_and_testing_guide.md) | [🏠 Developer Hub](README.md) |
|:---:|:---:|
