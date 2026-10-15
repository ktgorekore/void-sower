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

# Google Play Console Release Notes — v0.4.0 (Build 42)

## Release Track: Production / Internal / Open Testing

---

### Copy-Paste Release Notes for Play Console (`en-US`)
```text
<en-US>
🚀 Void Sower v0.4.0 — 3D Deep-Space Theater & Afrofuturist Overhaul!
• Wide-Field 3D Space & Camera Gimbal: Switch between Chase, Bridge, Orbit & Top-Down 3D angles with 1-finger yaw/pitch tilt.
• Solid 3D Fleet & Swaying Invaders: Gouraud-shaded 3D ships bank across 8 diegetic emitter lanes toward a distant Target Star.
• African Strategic Fusions: Morabaraba 3-Bay Mills (1.5x lance), Yoté Surgical Culls & 3-Phase Checkpoint Relic Drafts.
</en-US>
```
*Character Count:* **445 / 500 max characters** (Google Play compliant).

---

### Localized Release Notes

#### 🇹🇿 Swahili (`sw`)
```text
<sw>
🚀 Void Sower v0.4.0 — Anga ya 3D na Maboresho ya Afrofuturist!
• Kamera ya 3D Inayozunguka: Badili kati ya Chase, Bridge, Orbit na Top-Down 3D huku ukielekeza meli kuelekea Nyota Lengwa.
• Meli Imara za 3D: Wavamizi wa 3D wanayumba kati ya njia 8 zenye vituo vya nishati vya C1–C8 bila mistari ya zamani.
• Mbinu za Kiafrika: Mfumo wa Morabaraba (1.5x leza), Yoté Surgical Cull na Chaguo la Visukuku katika awamu 3 za vita.
</sw>
```
*Character Count:* **436 / 500 max characters**.

#### 🇫🇷 French (`fr-FR`)
```text
<fr-FR>
🚀 Void Sower v0.4.0 — Théâtre Spatial 3D & Refonte Afrofuturiste !
• Caméra 3D Interactive : Alternez entre Chase, Bridge, Orbit et Top-Down 3D avec inclinaison libre vers l'Étoile Cible.
• Flotte 3D Solide : Vaisseaux 3D à ombrage de Gouraud oscillant entre 8 quais émetteurs C1–C8 sans grille filaire.
• Fusions Stratégiques Africaines : Moulins Morabaraba (lance 1,5x), Frappe Yoté et Reliques de Checkpoint en 3 phases.
</fr-FR>
```
*Character Count:* **439 / 500 max characters**.

#### 🇪🇸 Spanish (`es-ES`)
```text
<es-ES>
🚀 Void Sower v0.4.0 — ¡Teatro Espacial 3D y Renovación Afrofuturista!
• Cámara 3D Interactiva: Alterna entre vistas Chase, Bridge, Orbit y Top-Down 3D rumbo a la Estrella Objetivo.
• Flota 3D Sólida: Naves 3D con sombreado Gouraud que oscilan entre 8 muelles emisores C1–C8 sin rejillas de alambre.
• Fusiones Estratégicas Africanas: Molinos Morabaraba (lanza 1.5x), Golpe Yoté y Reliquias de Control en 3 fases.
</es-ES>
```
*Character Count:* **428 / 500 max characters**.

---

### Internal Engineering Notes (Build 42)
- **Wide-Field 3D Perspective Camera (`CombatCamera3D`):**
  - Implemented an interactive 3D perspective camera gimbal in `lib/presentation/widgets/combat_camera_3d.dart` supporting 4 one-tap presets (`CHASE 3D 26°/0°`, `BRIDGE 3D 38°/-22°`, `ORBIT 3D 32°/18°`, `TOP-DOWN 76°/0°`), fine `◄` `►` yaw / `▼` `▲` pitch step buttons, and direct 1-finger upper-viewport drag tilting.
  - Tuned perspective foreshortening (`_perspStrength = 0.56 * math.cos(p * 0.78)`) so the 8 combat corridors remain spacious (`62.5%+` of viewport width at `normZ = 1.0`) and anchored deep-space horizon coordinates (`normZ > 1.0`) asymptotically so the **3D Target Star & Dyson Sanctuary** renders cleanly below the Admiral Zawadi comms strip with zero HUD overlap.
- **Lineless Diegetic 3D Space Architecture (`CombatBackgroundPainter` & `CombatPainter`):**
  - Removed all vertical wireframe corridor grid lines, horizontal sleeper ribs, and full-screen corridor border boxes.
  - Replaced wireframe outlines with diegetic 3D space indicators:
    - **8 Sculpted 3D Hexagonal Orbital Emitter Docks (`C1..C8`)** along the bottom defense perimeter (`normZ = 0.002..0.064`) whose holographic lenses pulse crimson when an invader sways into that lane or cyan for the Defender's active lane.
    - **Floating 3D Astral Waypoint Buoys** streaming down the center of each lane (`(c + 0.5) / 8.0`), glowing crimson in enemy-occupied corridors, solar-gold in Morabaraba Mill Triad lanes, and projecting forward-flowing 3D holographic chevrons (`▲`) in the Defender's active corridor.
    - **Scrolling 3D Flanking Stargate Wing-Pylons** in peripheral space (`normX = 0.015` and `0.985`) that rush past the camera as the Defender thrusts forward toward the Target Star.
- **Solid Gouraud-Shaded 3D Fleet (`Dreadnought3DMesh` & `Invader3DMesh`):**
  - Built hardware-accelerated `ui.Vertices.raw(ui.VertexMode.triangles, ...)` Gouraud-shaded polyhedral 3D meshes with painter's-algorithm depth sorting, Blinn-Phong specular highlights, and zero per-frame allocations for the player's **3D Defender Flagship** and 3 hostile vessel classes (**Kaskazi Interceptor Drone**, **Hegemony Armored Cruiser**, and **Apex Dreadnought Carrier**).
- **Dynamic Multi-Corridor Invader Swaying & 2D Anti-Overlap Separation (`MovementSystem`, `CombatCoordinator`, `MockVoidSowerEngine`):**
  - Restored and amplified sinusoidal multi-corridor weaving across all sectors (`engine.setLateralDrift(true)`), dynamically updating `assigned_corridor = clamp(floor(world_pos_x * 8.0), 0, 7)` on every tick, banking 3D wings (`effectiveRoll` / `effectiveYaw`), displaying live `⌖ [C1]..[C8]` corridor lock badges above each hull, and enforcing pairwise 2D spatial separation (`kMinGapX = 0.095f`, `kMinGapY = 0.16f`).
- **Pan-African Strategic Fusions & 3-Phase Ascending Sector Checkpoints:**
  - Integrated **Bao la Kiswahili** Nyumba tax/sow rules, **Morabaraba 3-Bay Mill Resonance** (`1.5x` lance multiplier), **Yoté Cross-Capture Surgical Cull** (instant execute on weakest flanking ship upon capturing $\ge 4$ cores), **Fanorona Approach & Withdrawal** dual-vector discharges, and **3-Phase Sector Checkpoints (`P1: RECON`, `P2: SIEGE`, `P3: APEX BOSS`)** with mid-sector **Tactical Relic Drafts** and **Admiral Zawadi** holographic briefings.
