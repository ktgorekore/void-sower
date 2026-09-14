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

# Void Sower Developer Guide: Presentation Shaders & Audio-Visual Pipeline

[◄ Developer Hub](README.md) | [01: Game Rules](01_game_rules_and_mechanics.md) | [02: ECS Engine](02_cpp_ecs_engine_architecture.md) | [03: FFI Bridge](03_dart_ffi_bridge_and_isolate_architecture.md) | [04: Presentation](04_presentation_shaders_and_audio_visual_pipeline.md) | [05: Campaign](05_campaign_economy_and_player_identity.md) | [06: Testing](06_apis_integration_and_testing_guide.md) | [07: Procedural Generation](07_procedural_generation_and_solvability_guarantees.md)

---

## 1. Presentation Architecture & Visual Identity

Void Sower features a distinctive **Afrofuturist** visual aesthetic set in the starfields of the Kilwa Nebula Basin. Deep obsidian voids are punctuated by high-contrast **Solar Gold**, **Plasma Cyan**, and **Crimson Flare** particle emissions.

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                            FLUTTER WIDGET HIERARCHY                         │
│  CombatScreen                                                               │
│   ├── HudHeader (Two-Strip Tactical HUD: Fuel Gauge, Score, Tier & Commands)│
│   │    ├── Strip 1: Reactor Fuel ([⚡ REACTOR: 28]), Threat Tier & Score    │
│   │    └── Strip 2: Live Guidance Beacon, AI Solver, Academy & Bao Codex    │
│   ├── CombatPainter (CustomPainter Canvas: Stars, Lances, Flak, Enemies)    │
│   │    ├── Impeller GLSL Shaders (shaders/lance_beam.frag, flak_burst.frag) │
│   │    └── Floating Arcade Telemetry (-1 CORE (NAMUA), Damage & Deflects)   │
│   ├── ProjectionShelf (Real-Time Sowing & Damage Telemetry)                 │
│   └── CommandArcWidget (Lower 30% Viewport Ergonomic One-Thumb Controls)    │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 2. Afrofuturist Color Tokens & Theming ([`lib/presentation/theme/void_theme.dart`](file:///home/kelvingorekore/projects/void-sower/lib/presentation/theme/void_theme.dart))

All visual assets, shaders, and UI widgets adhere strictly to the standardized `VoidTheme` color tokens:

| Token Name | Hex Code | RGB Color | Primary Tactical Usage |
| :--- | :--- | :--- | :--- |
| **`obsidianBlack`** | `#070A12` | `rgb(7, 10, 18)` | Global background canvas & deepest cosmic void |
| **`deepSpaceVoid`** | `#0D1224` | `rgb(13, 18, 36)` | Secondary card surfaces & inactive bay reservoirs |
| **`cardSurface`** | `#1A2238` | `rgb(26, 34, 56)` | Glassmorphic containers & dialog panels |
| **`solarGold`** | `#FFB300` | `rgb(255, 179, 0)` | Player dreadnought hull, Nyumba sanctuaries & primary actions |
| **`plasmaCyan`** | `#00E5FF` | `rgb(0, 229, 255)` | Frontline capacitor bays, energy conduits & particle lances |
| **`crimsonFlare`** | `#FF2A6D` | `rgb(255, 42, 109)` | High-energy quadratic lance cores & atmospheric threat perimeter |
| **`emeraldShield`** | `#00E676` | `rgb(0, 230, 118)` | Kimbi flank deflection chambers & defensive barrier status |
| **`nebulaAmethyst`**| `#B388FF` | `rgb(179, 136, 255)`| Kichwa vector reversal conduits & cosmic anomaly fields |

### Glassmorphic Card Styling
```dart
static BoxDecoration glassmorphic({
  Color borderColor = VoidTheme.plasmaCyan,
  double borderWidth = 1.0,
  double borderRadius = 12.0,
}) {
  return BoxDecoration(
    color: VoidTheme.cardSurface.withValues(alpha: 0.65),
    borderRadius: BorderRadius.circular(borderRadius),
    border: Border.all(color: borderColor.withValues(alpha: 0.6), width: borderWidth),
    boxShadow: [
      BoxShadow(
        color: borderColor.withValues(alpha: 0.15),
        blurRadius: 12.0,
        spreadRadius: 1.0,
      ),
    ],
  );
}
```

---

## 3. High-Performance Canvas Rendering ([`lib/presentation/widgets/combat_painter.dart`](file:///home/kelvingorekore/projects/void-sower/lib/presentation/widgets/combat_painter.dart))

The tactical battlefield is rendered via `CombatPainter`, a custom `CustomPainter` executed directly on the GPU canvas:

### 3.1 Render Pass Sequencing
1. **Starfield Pass**: Draws 120 parallax stars with subtle warp velocity elongation along the Y-axis.
2. **Atmospheric Threshold Pass**: Renders the glowing red perimeter line at $y = 0.20$ with warning chevron hashes.
3. **Corridor Guides Pass**: Subtly renders the 8 vertical attack corridor separators ($C_0$ to $C_7$).
4. **Enemy Craft Pass**:
   - Escort Drones: Inverted triangular glyphs with cyan thruster contrails.
   - Armored Cruisers: Hexagonal heavy vessels with dual-tier shield arcs.
   - Flagship Boss: Segmented capital hull spanning across multiple corridors.
5. **Quadratic Particle Lance Pass**:
   - Vertical radiant beams originating at frontline bays.
   - Beam width and alpha bloom scale dynamically with accumulated mass:
     $$W_{\text{beam}} = \min\left(48.0, \ 12.0 + 4.0 \cdot M\right)$$
   - Core laser spine rendered in pure white surrounded by crimson and plasma cyan bloom halos.
6. **Radial Flak Detonations**: Concentric expanding shockwave rings with randomized sub-munition spark bursts.
7. **Floating Damage Text**: Transient damage numbers floating upward with quadratic scale pulses ($D \ge 1,000$ highlighted in crimson flare).

---

## 4. Impeller GLSL Fragment Shaders

Void Sower leverages Flutter's Impeller rendering engine with SPIR-V GLSL 460 shaders located in `shaders/`:

### 4.1 Particle Lance Shader (`shaders/lance_beam.frag`)
Produces dynamic plasma turbulence, core blooming, and relativistic energy pulses along axial discharge corridors:
```glsl
#version 460 core

precision highp float;

#include <flutter/runtime_effect.glsl>

uniform vec2 u_resolution;
uniform float u_time;
uniform float u_mass;
uniform vec4 u_core_color;
uniform vec4 u_glow_color;

out vec4 fragColor;

void main() {
  vec2 uv = FlutterFragCoord().xy / u_resolution;
  
  // Center beam calculation
  float dist_from_center = abs(uv.x - 0.5);
  float intensity = exp(-dist_from_center * (30.0 / sqrt(u_mass)));
  
  // Plasma turbulence noise along the beam
  float noise = sin(uv.y * 50.0 - u_time * 15.0) * cos(uv.y * 30.0 + u_time * 8.0);
  intensity += noise * 0.15;
  
  vec4 color = mix(u_glow_color, u_core_color, clamp(intensity * 1.5 - 0.5, 0.0, 1.0));
  fragColor = color * intensity;
}
```

### 4.2 Radial Flak Detonation Shader (`shaders/flak_burst.frag`)
Generates expanding circular shockwaves with chromatic aberration and sub-munition fallout:
```glsl
#version 460 core

precision highp float;

#include <flutter/runtime_effect.glsl>

uniform vec2 u_resolution;
uniform vec2 u_center;
uniform float u_progress;
uniform float u_radius;

out vec4 fragColor;

void main() {
  vec2 uv = FlutterFragCoord().xy / u_resolution;
  float d = distance(uv, u_center);
  
  float shockwave = smoothstep(u_radius * u_progress, u_radius * u_progress - 0.02, d) *
                    smoothstep(u_radius * u_progress - 0.04, u_radius * u_progress - 0.02, d);
                    
  fragColor = vec4(1.0, 0.7, 0.2, 1.0) * shockwave * (1.0 - u_progress);
}
```

---

## 5. Ergonomic One-Thumb Mobile Viewport Architecture

To ensure optimal playability on mobile devices in one-handed portrait orientation, the UI adheres to the **Lower 30% Viewport Command Arc standard**:

```
┌──────────────────────────────────────────────────────┐
│                  HUD & ENEMY COMBAT                  │
│                     (Upper 70%)                      │
│                                                      │
│                                                      │
│ ════════════════════════════════════════════════════ │ [y = 0.20]
├──────────────────────────────────────────────────────┤
│               PROJECTION SHELF TELEMETRY             │
│ ──────────────────────────────────────────────────── │
│               CAPACITIVE COMMAND ARC                 │ ◄── Primary Thumb Arc
│          (16 Bays, Guide Arc, Direction Pill)        │     (Lower 30%)
│ ──────────────────────────────────────────────────── │
│               LATERAL PLATFORM SLIDER                │
└──────────────────────────────────────────────────────┘
```

- **Touch Bounds**: All interactive bay cells maintain $\ge 48 \times 48\text{ dp}$ touch bounding boxes.
- **Radial Thumb Guidance**: A subtle golden guide curve traces the natural sweep of the player's thumb across the lower display.
- **Multimodal Gestures**:
  - **Tap**: Selects bay and shows projected lance trajectory on `ProjectionShelf`.
  - **Horizontal Swipe Left/Right**: Commences sowing traversal in chosen direction.
  - **Flick Upward / Double-Tap**: Instantly injects core (*Namua*) into selected bay.

---

## 6. Dynamic Audio & Haptic Feedback Engines

### 6.1 Audio Synthesis Engine ([`lib/presentation/services/audio_service.dart`](file:///home/kelvingorekore/projects/void-sower/lib/presentation/services/audio_service.dart))
- **Procedural Pitch Scaling**: Sowing ticks increment in pitch by $+1.5\text{ semitones}$ per consecutive bay during a traversal lap, building acoustic tension.
- **Resonant Low-End Thuds**: Quadratic lance firings trigger deep resonant synthesis ($80\text{ Hz}$ sine wave with rapid exponential decay).
- **Flak Explosions**: Multi-layered filtered white noise bursts for secondary flak detonations.

### 6.2 Multi-Pulse Haptic Engine ([`lib/presentation/services/haptic_service.dart`](file:///home/kelvingorekore/projects/void-sower/lib/presentation/services/haptic_service.dart))
- **`sowTick()`**: Ultra-short tactile feedback pulse ($8\text{ ms}$) on each bay traversal step.
- **`lanceDischarge()`**: Sustained heavy rumble sequence ($45\text{ ms}$) matching high-energy particle lance discharges.
- **`flakDetonation()`**: Dual-tap burst sequence simulating secondary shockwave propagation.

---

## 🧭 Navigation

| [◄ 03: FFI Bridge](03_dart_ffi_bridge_and_isolate_architecture.md) | [🏠 Developer Hub](README.md) | [Next: 05 Campaign Economy & Player Identity ►](05_campaign_economy_and_player_identity.md) |
|:---:|:---:|:---:|
