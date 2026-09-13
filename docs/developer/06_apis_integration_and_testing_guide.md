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

# Void Sower Developer Guide: APIs, Integration & Testing Matrix

[◄ Developer Hub](README.md) | [01: Game Rules](01_game_rules_and_mechanics.md) | [02: ECS Engine](02_cpp_ecs_engine_architecture.md) | [03: FFI Bridge](03_dart_ffi_bridge_and_isolate_architecture.md) | [04: Presentation](04_presentation_shaders_and_audio_visual_pipeline.md) | [05: Campaign](05_campaign_economy_and_player_identity.md) | [06: Testing](06_apis_integration_and_testing_guide.md) | [07: Procedural Generation](07_procedural_generation_and_solvability_guarantees.md)

---

## 1. Testing Philosophy & Verification Pyramid

Void Sower adheres to a dual-layer verification strategy. The native C++17 ECS simulation core is audited through **Google Test (GTest)** with boundary wrapping tests, while the Dart presentation and UI layer is verified via **Flutter Unit & Widget Tests**.

```
                   ▲
                  / \
                 /   \
                /  UI \        Flutter Widget Tests (test/widget_test.dart)
               / tests \       • 7 interactive widget test cases
              /─────────\      • 100% pass rate across onboarding, dialogs & HUD
             /  Native   \
            /  C++ GTest  \    C++ GTest Matrix (src/tests/)
           /   Unit Tests  \   • Ring buffer, spatial grid, FFI boundary & combat
          /─────────────────\  • Zero memory leak / AddressSanitizer compliance
```

---

## 2. Native C++ Google Test Matrix ([`src/tests/`](file:///home/kelvingorekore/projects/void-sower/src/tests/))

The native test harness evaluates simulation determinism, bitwise arithmetic, and FFI boundaries:

### 2.1 Test Suite Breakdown

| Test Binary / Source | Subsystem Under Test | Key Assertions & Edge Cases Verified |
| :--- | :--- | :--- |
| [`ring_buffer_test.cpp`](file:///home/kelvingorekore/projects/void-sower/src/tests/ring_buffer_test.cpp) | `RingBufferSystem` | Power-of-two bitwise masking (`& 0x0F`), forward/backward boundary wrapping at $15 \to 0$ and $0 \to 15$, multi-step destination prediction. |
| [`spatial_grid_test.cpp`](file:///home/kelvingorekore/projects/void-sower/src/tests/spatial_grid_test.cpp) | `SpatialGrid` | Corridor bucketing ($C_0..C_7$), out-of-bounds coordinate clamping, zero allocation capacity limits ($32$ per bucket). |
| [`combat_simulation_test.cpp`](file:///home/kelvingorekore/projects/void-sower/src/tests/combat_simulation_test.cpp) | `CombatSystem` | Quadratic lance damage ($D = \alpha \cdot M^2$), secondary flak dispersion ($D_{\text{flak}} = \beta \cdot \sqrt{M'}$), multi-lap cascades, boundary breach defeat. |
| [`wave_generator_test.cpp`](file:///home/kelvingorekore/projects/void-sower/src/tests/wave_generator_test.cpp) | `WaveGenerator` | Backward-play program inversion determinism, core budget constraints, corridor mask compliance. |
| [`ffi_boundary_test.cpp`](file:///home/kelvingorekore/projects/void-sower/src/tests/ffi_boundary_test.cpp) | `src/void_sower.h` | Flat C ABI pointer integrity, zero-copy struct serialization, memory alignment across boundaries. |

### 2.2 Running Native Tests Locally
```bash
# Configure CMake build directory
cmake -B build -S src

# Compile native test executable
cmake --build build --target void_sower_tests

# Run native test suite
./build/void_sower_tests
```

---

## 3. Flutter Widget & Integration Test Suite ([`test/widget_test.dart`](file:///home/kelvingorekore/projects/void-sower/test/widget_test.dart))

The Flutter test suite verifies UI state transitions, touch interactions, dialog rendering, and HUD telemetry:

```dart
void main() {
  testWidgets('VoidSowerApp launches campaign map screen', (tester) async { ... });

  group('Phase 13 UI Polish Tests', () {
    testWidgets('TutorialOverlay steps through flight academy', (tester) async { ... });
    testWidgets('BaoCodexDialog displays rules and lore', (tester) async { ... });
    testWidgets('FleetHangarDialog displays chassis variants and stats', (tester) async { ... });
    testWidgets('CommandArcWidget displays 16 bays, pips, and corridor notches', (tester) async { ... });
    testWidgets('ProjectionShelf displays trajectory telemetry and lance damage', (tester) async { ... });
  });
}
```

### 3.1 Running Flutter Tests
```bash
flutter test
```
**Current Status**: `00:01 +7: All tests passed!`

---

## 4. Code Hygiene & Formatting Enforcement

To ensure zero divergence across developer environments and automated CI agents, all code must pass the repository formatting audit:

### 4.1 Automated Audit Script
```bash
python3 scripts/verify_format.py --all
```
The script audits all source files across the project:
- **C/C++ Files (`.h`, `.cpp`, `.cc`)**: Verified against Google C++ style via `clang-format -style=Google`.
- **Dart Files (`.dart`)**: Verified against official Dart style via `dart format --output=none --set-exit-if-changed`.
- **License Headers**: Verifies presence of the Apache 2.0 header attributed to **Void Sower Authors**.

### 4.2 Formatting Modified Code
```bash
# Format C++ source files
clang-format -style=Google -i src/*.cpp src/*.h src/*/*.cpp src/*/*.h

# Format Dart source files
dart format lib/ test/
```

---

## 5. Release Bundle & 16 KB Page Size Verification

Before any build is submitted to Google Play Console or tagged for release, run the automated release bundle builder:

```bash
bash scripts/build_release_bundle.sh
```

### Automated Audits Performed
1. Compiles optimized Android App Bundle (`app-release.aab`).
2. Extracts native `.so` binaries from universal split APKs.
3. Runs `readelf -l` across all shared libraries to verify **16 KB memory page size alignment** (`0x4000` boundary).
4. Verifies compressed device download payload is strictly $< 25\text{ MB}$ (Current: **7.51 MB**).

---

## 🧭 Navigation

| [◄ 05: Campaign Economy](05_campaign_economy_and_player_identity.md) | [🏠 Developer Hub](README.md) | [Next: 07 Procedural Generation ►](07_procedural_generation_and_solvability_guarantees.md) |
|:---:|:---:|:---:|
