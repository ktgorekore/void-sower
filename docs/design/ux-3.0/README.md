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

# 🌌 Void Sower 3.0 Design System & UI Proposals

Welcome to the **Void Sower 3.0** design repository. This directory contains the complete visual language, vector mockups, rendered PNG assets, and detailed technical specifications for the next-generation Void Sower user experience.

---

## 📖 Master Specification
For the full architectural and ergonomic specification, read:
👉 [**Void Sower 3.0 UI/UX Specification**](file:///home/kelvingorekore/projects/void-sower/docs/design/ux-3.0/ux-ui-3.0-specification.md)

---

## 📱 Rendered Screens & Vector Mockups

| Screen / Flow | Vector SVG | Rendered Preview | Primary UX Focus |
|---|---|---|---|
| **Combat Viewport & Mancala Dock** | [gameplay.svg](file:///home/kelvingorekore/projects/void-sower/docs/design/ux-3.0/gameplay.svg) | [gameplay.png](file:///home/kelvingorekore/projects/void-sower/docs/design/ux-3.0/gameplay.png) | 560px open combat theater; 142px ultra-compact battery dock with integrated fire triggers & gold Nyumba vault. |
| **Orbital Command & Sectors Map** | [sectors.svg](file:///home/kelvingorekore/projects/void-sower/docs/design/ux-3.0/sectors.svg) | [sectors.png](file:///home/kelvingorekore/projects/void-sower/docs/design/ux-3.0/sectors.png) | Left-spine progression trajectory, compact header (<100px), distinctive Active Siege hero card, 5-tab global nav. |
| **Fleet Drydock & Vessel Hangar** | [fleet_hangar.svg](file:///home/kelvingorekore/projects/void-sower/docs/design/ux-3.0/fleet_hangar.svg) | [fleet_hangar.png](file:///home/kelvingorekore/projects/void-sower/docs/design/ux-3.0/fleet_hangar.png) | 3D holographic wireframe stage, capacitor and lance coefficient readouts, chassis loadout switcher. |
| **Pilot Dossier & Battle Records** | [pilot_profile.svg](file:///home/kelvingorekore/projects/void-sower/docs/design/ux-3.0/pilot_profile.svg) | [pilot_profile.png](file:///home/kelvingorekore/projects/void-sower/docs/design/ux-3.0/pilot_profile.png) | Holographic pilot avatar, career telemetry (stars, accuracy, score), honor citations & progress bars. |
| **Tactical Pause Drawer & Modals** | [pause_and_modals.svg](file:///home/kelvingorekore/projects/void-sower/docs/design/ux-3.0/pause_and_modals.svg) | [pause_and_modals.png](file:///home/kelvingorekore/projects/void-sower/docs/design/ux-3.0/pause_and_modals.png) | High-contrast frosted glass drawer, single-tap RESUME COMBAT, quick hardware toggles (SFX, Music, Haptic, AI). |
| **Simulation Lab & Tactical Solver** | [simulation_lab.svg](file:///home/kelvingorekore/projects/void-sower/docs/design/ux-3.0/simulation_lab.svg) | [simulation_lab.png](file:///home/kelvingorekore/projects/void-sower/docs/design/ux-3.0/simulation_lab.png) | Interactive 16-bay state editor, MCTS depth 8 move recommendations, step scrubber & execution controls. |
| **System Settings & Fleet Config** | [settings.svg](file:///home/kelvingorekore/projects/void-sower/docs/design/ux-3.0/settings.svg) | [settings.png](file:///home/kelvingorekore/projects/void-sower/docs/design/ux-3.0/settings.png) | Acoustic & kinetic calibration sliders, 120 FPS high refresh toggle, colorblind assistance, cloud save sync. |

---

## 🎨 Core Design Tokens Summary
- **Background Base:** Cosmic Obsidian (`#05070f`)
- **Primary Energy / Glow:** Plasma Cyan (`#00f0ff` / `#38bdf8`)
- **Prestige / Core Economy:** Solar Gold / Amber (`#fbbf24` / `#f59e0b` / `#78350f`)
- **Surface Elevation:** Translucent Glass (`#0f172a` @ 40-60%) with slate borders (`#1e293b`)
- **Navigation Bounds:** Strict lower 30% viewport thumb arc ($\ge 48 \times 48\text{ dp}$ touch areas)
