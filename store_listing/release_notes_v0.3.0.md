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

# Google Play Console Release Notes — v0.3.0 (Build 40)

## Release Track: Production / Internal / Open Testing

---

### Copy-Paste Release Notes for Play Console (`en-US`)
```text
<en-US>
🚀 Void Sower v0.3.0 — The UX 3.0 & 3D Deep Space Overhaul!
• 3D Space Depth: Maneuver across Apogee, Mid-Combat, and Forward horizons with 3D flight physics and ground projection telemetry.
• Bow-Aligned Particle Lance: Intuitive forward-firing targeting pod locking directly onto descending invaders.
• Streamlined UX: Decluttered Star Map, instant pause resumption with zero freezes, and honest defeat flows.
• Subtle Tactical Advisory: Universal real-time corridor AI scanning for all pilots.
</en-US>
```
*Character Count:* **489 / 500 max characters** (Google Play compliant).

---

### Localized Release Notes

#### 🇹🇿 Swahili (`sw`)
```text
<sw>
🚀 Void Sower v0.3.0 — Maboresho Makubwa ya UX 3.0 na Anga ya 3D!
• Kina cha Anga 3D: Sogeza chombo chako angani kwa kimo halisi cha Apogee na Forward Horizons.
• Miale ya Moja kwa Moja: Silaha ya leza sasa inalenga na kupiga moja kwa moja mbele ya chombo chako.
• Urambazaji Mwepesi: Ramani safi ya nyota, kurejea vitani papo hapo bila kukwama, na mtiririko safi.
• Mwongozo Tulivu wa AI: Ufuatiliaji wa adui unapatikana kwa wote bila kufunika skrini.
</sw>
```
*Character Count:* **457 / 500 max characters**.

#### 🇫🇷 French (`fr-FR`)
```text
<fr-FR>
🚀 Void Sower v0.3.0 — Refonte Majeure UX 3.0 & Combat Spatial 3D !
• Profondeur 3D Réelle : Manœuvrez entre les horizons d'Apogée et d'Engagement avec télémétrie orbitale.
• Lance de Particules Axiale : Axe de tir aligné directement sur la proue pour cibler les assaillants.
• Interface Épurée : Carte stellaire clarifiée, reprise instantanée après pause sans aucun gel d'écran.
• Conseil IA Subtil : Radar tactique universel accessible à tous les pilotes sans encombrement.
</fr-FR>
```
*Character Count:* **487 / 500 max characters**.

#### 🇪🇸 Spanish (`es-ES`)
```text
<es-ES>
🚀 Void Sower v0.3.0 — ¡Gran Renovación UX 3.0 y Combate Espacial 3D!
• Profundidad Espacial 3D: Maniobra entre horizontes de Apogeo y Cercanía con telemetría de vuelo real.
• Lanza de Partículas Frontal: Disparo intuitivo alineado en la proa que apunta directo a los invasores.
• Interfaz Limpia y Fluida: Mapa estelar rediseñado y reanudación tras pausa sin congelamientos.
• Asesoría IA No Intrusiva: Escaneo táctico de pasillos disponible para todos los pilotos.
</es-ES>
```
*Character Count:* **479 / 500 max characters**.

---

### Internal Engineering Notes (Build 40)
- **3D Spatial Simulation:** Implemented concentric horizon depth rings (`APOGEE HORIZON Z: +40km`, `MID-COMBAT HORIZON Z: +20km`, `FORWARD ENGAGE HORIZON Z: +10km`) and ground projection anchor ring in `CombatPainter`.
- **Bow-Aligned Firing Pod:** Refactored conduit projectile origin and lock-on HUD in `CommandArcWidget` and `CombatPainter` to originate at the dreadnought's front prow.
- **Invader Meshes:** Inverted enemy craft flight angles to face down towards the player dreadnought with descending engine plumes and health tracking.
- **Universal Advisory Bar:** Converted Pro-exclusive floating advice bar to a subtle, fixed 20dp status strip (`TACTICAL AI SCANNING CORRIDORS... STANDBY`) ensuring zero layout jumping.
- **Frictionless Pause & Resumption:** Reworked `PauseMenuDialog` and `CombatScreen` lifecycle to unfreeze ticker loops cleanly upon settings return and resume taps.
- **Respectful Defeat Flow:** Removed mid-game 8-core popup dialogs; implemented honest `ORBITAL BREACH` screen with instant Retry or Star Map return.
- **Brand Identity & Media:** Revamped 512x512 app icon, Android launcher mipmaps, 1024x500 feature graphic, 6 native 1344x2992 store screenshots, and 24s 60 FPS gameplay showcase video.
