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

# Google Play Console Release Notes — v0.5.1 (Build 46)

## Release Track: Production / Internal / Open Testing

---

### Copy-Paste Release Notes for Play Console (`en-US`)
```text
<en-US>
🚀 Void Sower v0.5.1 — Streamlined HUD, 1-Tap Star Map & Special Ops, Plus Battery Boost!
• Clean Combat Viewport: Unified top HUD bar with Pilot Avatar & concise 1-word bottom dock controls for an unobstructed 3D arena!
• Instant Navigation: New 1-tap Star Map & Special Ops shortcuts right in the HUD + glowing OPS tab on the Campaign Map!
• Battery & Smoothness Boost: Faster 3D rendering, lower battery drain, zero-allocation hot paths & hardened C++ FFI stability!
</en-US>
```
*Character Count:* **473 / 500 max characters** (Google Play compliant).

---

### Localized Release Notes

#### 🇹🇿 Swahili (`sw`)
```text
<sw>
🚀 Void Sower v0.5.1 — HUD Safi, Njia ya Mkato ya Ramani na Special Ops, na Betri Imara!
• Uwanja Safi wa Mapigano: Upau mmoja wa juu wenye picha ya Rubani na vitufe vifupi chini kwa mwonekano bora wa 3D!
• Urambazaji wa Haraka: Vitufe vya Ramani ya Nyota na Special Ops moja kwa moja kwenye HUD pamoja na kichupo cha OPS!
• Utendaji na Betri Bora: Uchoraji wa haraka wa 3D, matumizi madogo ya betri na injini imara ya C++ FFI!
</sw>
```
*Character Count:* **439 / 500 max characters**.

#### 🇫🇷 French (`fr-FR`)
```text
<fr-FR>
🚀 Void Sower v0.5.1 — HUD Épuré, Carte Stellaire & Opérations Spéciales en 1 Clic + Batterie Optimisée !
• Vue de Combat Dégagée : Barre HUD supérieure unifiée avec avatar pilote et commandes compactes pour une arène 3D limpide !
• Navigation Instantanée : Accès direct à la Carte Stellaire et aux Opérations Spéciales (`OPS`) depuis le HUD et la carte !
• Autonomie & Fluidité : Rendu 3D optimisé, économie de batterie et moteur C++ FFI renforcé !
</fr-FR>
```
*Character Count:* **465 / 500 max characters**.

#### 🇪🇸 Spanish (`es-ES`)
```text
<es-ES>
🚀 Void Sower v0.5.1 — ¡HUD Limpio, Mapa Estelar y Operaciones Especiales en 1 Toque + Ahorro de Batería!
• Vista de Combate Despejada: ¡Barra superior unificada con avatar de piloto y controles concisos para una arena 3D limpia!
• Navegación Instantánea: ¡Atajos directos al Mapa Estelar y Operaciones Especiales (`OPS`) desde el HUD y el mapa!
• Batería y Rendimiento: ¡Renderizado 3D más fluido, menor consumo de batería y motor C++ FFI blindado!
</es-ES>
```
*Character Count:* **462 / 500 max characters**.

---

### Internal Engineering Notes (Build 46)
- **Unified Single-Bar Top HUD & Decluttered Bottom Command Dock (`SlimlineHudHeader`, `MancalaBatteryDockWidget`, `CombatScreen`):**
  - Consolidated the top combat HUD into a single topmost telemetry bar featuring a Gmail-style circular Pilot Profile Avatar (`hud_profile_avatar_button`) on the far left and removed secondary stacked comms/story/relic overlays.
  - Decluttered the bottom Mancala battery dock by removing multi-line totem descriptions and the bottom advisory text strip while preserving crisp visual seed pips (`● ● ○ ○`), shield/fence icons, and 1-word button labels (`‹ SOW`, `SOW ›`, `FIRE`/`BLAST`).
- **Enhanced Star Map & Special Ops Discoverability (`SlimlineHudHeader`, `CampaignMapScreen`, `CombatScreen`):**
  - Added a glowing cyan **Star Map** button (`hud_map_button`) and an amber-violet **Special Ops** shortcut (`hud_special_ops_button`) directly in the top HUD bar for 1-tap workflow navigation.
  - Promoted **Special Ops** to a dedicated glowing bottom navigation tab (`OPS`, `bottom_nav_special_ops`) and a high-contrast accented tab (`top_switcher_special_ops`) on `CampaignMapScreen`.
- **Battery Drain & App Lifecycle Remediation (`CombatScreen`, `LandscapeOrientationShield`, `SlimlineHudHeader`, `ProBoostModal`, `KineticRuleDiorama`, `ProfileModal`):**
  - Stopped the root `LandscapeOrientationShield` `AnimationController` completely while in portrait orientation or backgrounded, eliminating idle 60–120 FPS animation ticks.
  - Added `_computeHudStateHash()` diffing in `CombatScreen._onCoordinatorStateChanged()` so 60 Hz frame ticks and 2D ship drag gestures repaint only the `CustomPaint` canvas without rebuilding the widget tree unless HUD-displayed values change.
  - Subscribed `CombatScreen` to `routeObserver` via `RouteAware` and added `WidgetsBindingObserver` lifecycle suspension to 1 Hz `Timer.periodic` countdowns in `SlimlineHudHeader` and `ProBoostModal`.
  - Added `isComplex` / `willChange` raster cache hints to `CustomPaint`, gated secondary per-triangle software `drawPath` passes and helical lance ribbons when `isLowBattery == true`, and disposed `importController` in `ProfileModal._importSave`.
- **Hot-Path Performance & Native C++17 FFI Boundary Hardening (`src/void_sower.cpp`, `FfiVoidSowerEngine`, `Invader3DMesh`, `TacticalSolverController`):**
  - Added deterministic `vertices.dispose()` calls immediately after `canvas.drawVertices(...)` in `CombatBackgroundPainter`, `Dreadnought3DMesh`, and `Invader3DMesh`, and pre-allocated per-class typed-data views in `Invader3DMesh`.
  - Throttled `TacticalSolverMode.advisor` MCTS evaluations (`0.15s` cooldown) and cached `activeMillTriadBays` and `activeMutations` to eliminate per-frame allocations.
  - Implemented multi-client singleton lease reference counting (`void_sower_retain` / `void_sower_release`), `std::isfinite` float/enum boundary sanitization across all `extern "C"` FFI endpoints and ECS systems, entity validity guards in `BaoCascadeSystem::PredictSow`, and complete `_checkDisposed()` enforcement in `FfiVoidSowerEngine`.
