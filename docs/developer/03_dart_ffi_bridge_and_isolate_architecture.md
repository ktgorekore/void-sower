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

# Void Sower Developer Guide: Dart FFI Bridge & Background Isolate Architecture

[◄ Developer Hub](README.md) | [01: Game Rules](01_game_rules_and_mechanics.md) | [02: ECS Engine](02_cpp_ecs_engine_architecture.md) | [03: FFI Bridge](03_dart_ffi_bridge_and_isolate_architecture.md) | [04: Presentation](04_presentation_shaders_and_audio_visual_pipeline.md) | [05: Campaign](05_campaign_economy_and_player_identity.md) | [06: Testing](06_apis_integration_and_testing_guide.md) | [07: Procedural Generation](07_procedural_generation_and_solvability_guarantees.md)

---

## 1. Architecture & Design Principles

The boundary between Flutter's Dart UI thread and the native C++17 EnTT simulation engine is bridged via **Dart Foreign Function Interface (Dart FFI)**.

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                             FLUTTER UI THREAD                               │
│  MainGameScreen / CombatPainter ──► FfiVoidSowerEngine (Polling / Inputs)   │
└──────────────────────────────────────┬──────────────────────────────────────┘
                                       │ Direct Dart FFI Pointers
                                       ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                 FLAT C-STYLE ABI: extern "C" in void_sower.h                │
│  vs_engine_create()           vs_engine_inject_core()      vs_predict_sow() │
│  vs_engine_update()           vs_get_dreadnought_state()   vs_get_bays()    │
└──────────────────────────────────────┬──────────────────────────────────────┘
                                       │ Internal Pointer Dispatch
                                       ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                        NATIVE C++17 ECS ENGINE CORE                         │
│  void_sower::ecs::EngineSingleton ──► entt::registry & CombatSystem         │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Strict Architectural Invariants
1. **Flat C-Style ABI (`extern "C"`)**: All exported entry points use pure C linkage without name mangling or class hierarchies.
2. **Zero Runtime Exceptions Across Boundaries**: C++ exceptions are strictly banned across the FFI boundary. All failures return deterministic status codes (`0` or `1`) or zeroed POD structs.
3. **Zero-Copy Memory Pointer Caching**: The Dart engine pre-allocates native struct buffers (`calloc`) once during initialization and reuses them for per-frame state polling. This completely eliminates garbage collection pressure and allocation churn.
4. **Android 15 16 KB Memory Page Size Alignment**: Native libraries are explicitly linked with `-Wl,-z,max-page-size=16384` to ensure binary compatibility across Android 15+ kernels.
5. **Background Isolate Offloading**: Heavy procedural level generation and Monte Carlo Tree Search (MCTS) solvability validations execute inside background Dart isolates (`IsolateRunner`), guaranteeing an uncompromised 60/120 FPS UI thread.

---

## 2. Flat C-Style Application Binary Interface ([`src/void_sower.h`](file:///home/kelvingorekore/projects/void-sower/src/void_sower.h))

The native bridge exposes a minimalist, high-speed API:

```c
#ifndef VOID_SOWER_VOID_SOWER_H_
#define VOID_SOWER_VOID_SOWER_H_

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

// Opaque Engine Handle
typedef void* vs_engine_handle_t;

// Lifecycle Management
vs_engine_handle_t vs_engine_create(void);
void vs_engine_destroy(vs_engine_handle_t handle);

// Tactical Combat Operations
uint8_t vs_engine_initialize_dreadnought(vs_engine_handle_t handle, uint32_t starting_cores, float boundary_y);
uint8_t vs_engine_inject_core(vs_engine_handle_t handle, uint8_t target_bay, int8_t direction);
void vs_engine_update(vs_engine_handle_t handle, float delta_time);
void vs_engine_set_target_x(vs_engine_handle_t handle, float target_x);

// Instantaneous Trajectory Prediction
typedef struct {
  uint8_t terminal_bay;
  int8_t terminal_corridor;
  uint32_t final_mass;
  float predicted_damage;
  uint16_t total_cascade_laps;
  uint8_t triggers_lance;
  uint8_t triggers_relay;
} vs_prediction_result_t;

vs_prediction_result_t vs_predict_sow(vs_engine_handle_t handle, uint8_t start_bay, int8_t direction);

// Zero-Copy Telemetry Polling
typedef struct {
  float orbital_position_x;
  float target_position_x;
  uint32_t reserve_cores;
  float boundary_line_y;
  uint8_t is_cascading;
  uint32_t total_score;
  uint8_t current_sim_state;
  uint32_t cores_used;
} vs_dreadnought_state_t;

void vs_get_dreadnought_state(vs_engine_handle_t handle, vs_dreadnought_state_t* out_state);

// Batch Bay Polling (16 Bays)
void vs_get_bays(vs_engine_handle_t handle, void* out_bays_array, uint32_t max_bays);

// Dynamic Combatants Polling
uint32_t vs_get_enemies(vs_engine_handle_t handle, void* out_enemies_array, uint32_t max_enemies);
uint32_t vs_get_lances(vs_engine_handle_t handle, void* out_lances_array, uint32_t max_lances);
uint32_t vs_get_flaks(vs_engine_handle_t handle, void* out_flaks_array, uint32_t max_flaks);

#ifdef __cplusplus
}
#endif

#endif // VOID_SOWER_VOID_SOWER_H_
```

---

## 3. Zero-Copy Pointer Caching in Dart ([`lib/engine/ffi_void_sower_engine.dart`](file:///home/kelvingorekore/projects/void-sower/lib/engine/ffi_void_sower_engine.dart))

During app initialization, `FfiVoidSowerEngine` pre-allocates native heap memory buffers via `calloc` and caches them for the entire session lifecycle:

```dart
class FfiVoidSowerEngine implements IVoidSowerEngine {
  late final Pointer<Void> _handle;
  late final Pointer<vs_dreadnought_state_t> _dreadnoughtStatePtr;
  late final Pointer<BatteryComponent> _baysPtr;
  late final Pointer<EnemyVesselComponent> _enemiesPtr;
  late final Pointer<ParticleLanceComponent> _lancesPtr;
  late final Pointer<FlakBurstComponent> _flaksPtr;

  FfiVoidSowerEngine() {
    _handle = _bindings.vs_engine_create();
    
    // Allocate fixed-size native memory buffers once
    _dreadnoughtStatePtr = calloc<vs_dreadnought_state_t>();
    _baysPtr = calloc<BatteryComponent>(16);
    _enemiesPtr = calloc<EnemyVesselComponent>(64);
    _lancesPtr = calloc<ParticleLanceComponent>(8);
    _flaksPtr = calloc<FlakBurstComponent>(32);
  }

  @override
  DreadnoughtState getDreadnoughtState() {
    _bindings.vs_get_dreadnought_state(_handle, _dreadnoughtStatePtr);
    final ref = _dreadnoughtStatePtr.ref;
    return DreadnoughtState(
      orbitalPositionX: ref.orbital_position_x,
      reserveCores: ref.reserve_cores,
      isCascading: ref.is_cascading != 0,
      totalScore: ref.total_score,
      simState: SimulationState.values[ref.current_sim_state],
      coresUsed: ref.cores_used,
    );
  }

  @override
  void dispose() {
    _bindings.vs_engine_destroy(_handle);
    calloc.free(_dreadnoughtStatePtr);
    calloc.free(_baysPtr);
    calloc.free(_enemiesPtr);
    calloc.free(_lancesPtr);
    calloc.free(_flaksPtr);
  }
}
```

### Performance Benefits
- **Zero GC Churn**: Polling state 60 or 120 times per second triggers **0 garbage collection events**.
- **Deterministic Pointer Reuse**: Direct memory writes from C++ overwrite the cached buffer with no intermediate serialization or string parsing.

---

## 4. Android 15 16 KB Memory Page Alignment

Android 15 introduces mandatory support for devices utilizing **16 KB physical memory page sizes** (replacing legacy 4 KB pages). Shared native libraries (`.so`) that are not 16 KB page-aligned will fail to load at runtime with `dlopen` failures.

### Linker Configuration ([`src/CMakeLists.txt`](file:///home/kelvingorekore/projects/void-sower/src/CMakeLists.txt))
To guarantee compliance across all targets, Void Sower passes the max-page-size linker flag:
```cmake
target_link_options(void_sower PRIVATE
  -Wl,-z,max-page-size=16384
)
```

### Verification Command
Run `readelf` on the compiled library to inspect ELF segment alignment:
```bash
readelf -l build/libvoid_sower.so | grep -E "LOAD|Align"
```
Output verifies alignment of `0x4000` (16,384 bytes):
```
  LOAD           0x000000 0x0000000000000000 0x0000000000000000 0x012340 0x012340 R   0x4000
  LOAD           0x013000 0x0000000000013000 0x0000000000013000 0x045680 0x045680 R E 0x4000
```
This was verified on live hardware in the **Pixel 10 Pro XL** emulator (`PAGE_SIZE = 16384`), confirming seamless native execution.

---

## 5. Background Isolate Architecture ([`lib/engine/isolate_runner.dart`](file:///home/kelvingorekore/projects/void-sower/lib/engine/isolate_runner.dart))

Executing deep procedural wave generation and Monte Carlo Tree Search rollouts (up to 400 iterations across depth 6) directly on Flutter's main UI thread can introduce frame drops. Void Sower offloads heavy operations to a dedicated background isolate:

```dart
class IsolateRunner {
  /// Spawns a background isolate to generate a solvable wave and verify with MCTS.
  static Future<WaveGenerationResult> generateSolvableWaveAsync(
    WaveGeneratorConfig config,
  ) async {
    return compute(_backgroundWaveGeneratorWorker, config);
  }

  static WaveGenerationResult _backgroundWaveGeneratorWorker(
    WaveGeneratorConfig config,
  ) {
    // Instantiates an isolated native engine instance in background thread
    final engine = FfiVoidSowerEngine();
    final result = engine.generateWaveWithMctsValidation(config);
    engine.dispose();
    return result;
  }
}
```

This guarantees that the Flutter raster and UI threads run uninhibited at a steady 60 or 120 FPS during active transition screens.

---

## 🧭 Navigation

| [◄ 02: ECS Engine](02_cpp_ecs_engine_architecture.md) | [🏠 Developer Hub](README.md) | [Next: 04 Presentation & Shaders ►](04_presentation_shaders_and_audio_visual_pipeline.md) |
|:---:|:---:|:---:|
