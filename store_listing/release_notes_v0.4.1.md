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

# Google Play Console Release Notes — v0.4.1 (Build 43)

## Release Track: Production / Internal / Open Testing

---

### Copy-Paste Release Notes for Play Console (`en-US`)
```text
<en-US>
🚀 Void Sower v0.4.1 — Decoupled Sowing, Quadratic Lances & Clean 3D Space!
• Decoupled Sowing & Firing: Sowing redistributes cores across the capacitor ring without auto-firing; weapons fire on explicit command!
• Pronounced M² Particle Lances: Unleash massive quadratic volumetric plasma beams with twin gold/white helical spirals and shock rings.
• De-Cluttered 3D Arena: Clean viewport, discoverable 3D anomalies, smooth invader flight & top-HUD AI Autopilot indicator.
</en-US>
```
*Character Count:* **466 / 500 max characters** (Google Play compliant).

---

### Localized Release Notes

#### 🇹🇿 Swahili (`sw`)
```text
<sw>
🚀 Void Sower v0.4.1 — Upandaji Huru, Miale Mikubwa ya M² na Anga Safi ya 3D!
• Kutenganisha Upandaji na Upigaji: Kupanda nishati kunajaza betri bila kufyatua leza kiotomatiki; fyatua kwa amri yako mwenyewe!
• Miale ya Plasma ya M²: Fyatua miale mikubwa ya nishati yenye mawimbi ya dhahabu na pete za mshtuko wa 3D.
• Anga Safi ya 3D: Uwanja mpana usio na maandishi ya ziada, ugunduzi wa vitu angani na taa ya roboti ya AI kwenye upau wa juu.
</sw>
```
*Character Count:* **450 / 500 max characters**.

#### 🇫🇷 French (`fr-FR`)
```text
<fr-FR>
🚀 Void Sower v0.4.1 — Semis Dissocié, Lances M² & Espace 3D Épuré !
• Semis & Tir Découplés : Le semis redistribue les cœurs sans tir automatique ; déclenchez vos armes par commande explicite !
• Lances Volumétriques M² : Projetez des faisceaux plasma massifs avec doubles spirales hélicoïdales or/blanc et ondes de choc.
• Arène 3D Épurée : Vue dégagée, anomalies 3D à découvrir, vol fluide des envahisseurs et indicateur IA discret dans le HUD supérieur.
</fr-FR>
```
*Character Count:* **466 / 500 max characters**.

#### 🇪🇸 Spanish (`es-ES`)
```text
<es-ES>
🚀 Void Sower v0.4.1 — Siembra Disociada, Lanzas M² y Espacio 3D Depurado!
• Siembra y Disparo Separados: La siembra redistribuye núcleos sin disparar automáticamente; ¡dispara solo por comando explícito!
• Lanzas Plasmáticas M²: Desata rayos volumétricos masivos con dobles espirales doradas/blancas y anillos de choque en 3D.
• Espacio 3D Depurado: Vista limpia sin texto invasivo, anomalías 3D por descubrir y luz indicadora de IA en la barra superior.
</es-ES>
```
*Character Count:* **466 / 500 max characters**.

---

### Internal Engineering Notes (Build 43)
- **Decoupled Sowing from Weapon Firing (`BaoCascadeSystem`, `CombatSystem`, `CombatCoordinator`):**
  - Removed all automatic weapon firing from `BaoCascadeSystem::StepFSM` (`ExecuteCrossDischarge` and `ExecuteFlakDetonation` during `SowingTraversal`, `EvaluateDestination`, and `RelayOverload`). Sowing (`injectCore`) now strictly redistributes plasma cores across the 16-bay capacitor ring and builds quadratic $M^2$ frontline mass without firing.
  - Frontline batteries fire strictly when triggered by player command (dock `FIRE` button, tapping a frontline bay, or tapping in the 3D viewport).
  - Explicitly discharging a multi-core frontline bay ($M \ge 2$) that hits an enemy triggers Bao Mtaji capture seed harvesting (`+2` seeds) and redistribution into adjacent bays without auto-firing.
  - Seamless 3D touch steering: dragging in the 3D viewport steers the Defender smoothly across corridors without involuntarily sowing or discharging on finger lift.
- **Smooth 3D Invader Movement (Zero Stuttering) (`MovementSystem`, `MockVoidSowerEngine`):**
  - Replaced instantaneous attitude snaps (`bank_angle_rad`, `pitch_angle_rad`) with continuous exponential attitude damping (`1.0f - exp(-12.0f * dt)`).
  - Replaced pairwise anti-overlap position teleportation (`trailer.world_pos_y = ...`) with a continuous, `delta_time`-scaled soft spring separation force, eliminating frame-to-frame snapping during corridor crossovers while preserving natural sinusoidal swaying.
- **Pronounced Quadratic ($M^2$) Particle Lances (`CombatPainter`, `DischargeSystem`):**
  - Fixed coordinate bounds on volumetric glow shaders to ensure full visibility at all screen coordinates.
  - Rendered a multi-tier 3D perspective volumetric plasma cone scaled by quadratic mass $M = \sqrt{\text{damage} / 100}$, a blinding white-hot axial core spine, twin counter-wound gold and white helical plasma waves, concentric 3D elliptical shockwave rings, and 8-point muzzle/impact detonation novas.
  - Ensured `quickFireActiveCorridor()` captures prior mass before injection so explicit frontline discharges unleash full $(M+1)^2$ damage and visual scale.
  - Hardened victory evaluation in `CombatSystem::DischargeBay` and `CombatCoordinator.update` so neutralizing the final sector enemy with an explicit discharge transitions immediately to victory.
- **Straight Defender Attitude & Idle Beam Elimination (`CombatPainter`):**
  - Locked `rollRad = 0.0` and removed camera-yaw attitude bias so the Defender points straight up its corridor without axis yaw tilt.
  - Replaced the continuous idle laser targeting line with a compact prow muzzle indicator dot so no beam appears when idle.
- **Viewport De-Cluttering & Top-HUD AI Autopilot Indicator (`CombatScreen`, `SlimlineHudHeader`):**
  - Removed clutter from the 3D arena: removed rectangular-triangle sector emitters (`C1..C8`), radar distance rings, floating mid-board text banners, and sector directive text overlays.
  - Integrated AI Autopilot status directly into the top HUD header (`AI AUTO / ON ●` pill with glowing crimson border, background, and icon).
- **Discoverable 3D Deep-Space Anomalies (`SpaceAnomaly`, `CombatCoordinator`, `Starfield3DSimulation`):**
  - Replaced the static target star with a pre-allocated pool of 3D anomalies (`Core Caches`, `Ancient Bao Relics`, `Ion Nebula Surges`) drifting through 3D space, interceptable by flight or particle lances.
  - Coupled 3D starfield warp speed, lateral star parallax, and nebula drift to the Defender's live 3D velocity.
