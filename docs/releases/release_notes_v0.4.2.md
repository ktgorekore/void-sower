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

# Google Play Console Release Notes — v0.4.2 (Build 44)

## Release Track: Production / Internal / Open Testing

---

### Copy-Paste Release Notes for Play Console (`en-US`)
```text
<en-US>
🚀 Void Sower v0.4.2 — 3D Totem Turrets, Laser Fence & Visual Guide!
• 3D Totem Turrets: Shoot enemies to harvest seeds & grow 8 3D turrets! 1 seed = Shield, 2+ seeds = Auto-Gun, 4+ seeds = 16x Super Beam!
• Morabaraba Laser Fence: Link 3 Auto-Guns in a row to form a golden Laser Fence that zaps enemy bombs & boosts beams by 1.5x!
• Visual-First UI: Glowing seed pips (●●○○), ultra-short tips & 60 FPS animated visual tutorials with zero math jargon!
</en-US>
```
*Character Count:* **462 / 500 max characters** (Google Play compliant).

---

### Localized Release Notes

#### 🇹🇿 Swahili (`sw`)
```text
<sw>
🚀 Void Sower v0.4.2 — Minara ya 3D, Ukuta wa Leza na Mwongozo wa Picha!
• Minara ya 3D: Piga maadui uvune mbegu za kukuza minara 8! Mbegu 1 = Ngao, 2+ = Bunduki Kiotomatiki, 4+ = Miale Mikubwa 16x!
• Ukuta wa Leza (3 Mfululizo): Unganisha bunduki 3 mfululizo kuunda ukuta wa dhahabu unaolipua mabomu!
• UI Rahisi ya Picha: Taa za mbegu (●●○○), vidokezo vifupi na mafunzo ya video ya 60 FPS bila lugha ngumu!
</sw>
```
*Character Count:* **425 / 500 max characters**.

#### 🇫🇷 French (`fr-FR`)
```text
<fr-FR>
🚀 Void Sower v0.4.2 — Tourelles 3D, Barrière Laser & Guide Visuel !
• Tourelles Totem 3D : Tirez pour récolter des graines ! 1 graine = Bouclier, 2+ = Tourelle Auto, 4+ = Super Rayon 16x !
• Barrière Laser : Alignez 3 Tourelles Auto pour créer une barrière dorée qui détruit les bombes et booste vos tirs de 1,5x !
• Interface 100 % Visuelle : Points lumineux (●●○○), astuces courtes et tutoriels animés 60 FPS ultra clairs !
</fr-FR>
```
*Character Count:* **442 / 500 max characters**.

#### 🇪🇸 Spanish (`es-ES`)
```text
<es-ES>
🚀 Void Sower v0.4.2 — ¡Torretas 3D, Valla Láser y Guía Visual!
• Torretas Tótem 3D: ¡Dispara para cosechar semillas! 1 semilla = Escudo, 2+ = Auto-Cañón, 4+ = ¡Súper Rayo 16x!
• Valla Láser: ¡Alinea 3 Auto-Cañones seguidos para formar una valla dorada que destruye bombas y potencia rayos 1.5x!
• Interfaz Visual Simple: Indicadores de semillas (●●○○), consejos breves y tutoriales animados a 60 FPS sin jerga técnica.
</es-ES>
```
*Character Count:* **439 / 500 max characters**.

---

### Internal Engineering Notes (Build 44)
- **3D Ancestral Totem Turrets & Shoot-to-Harvest Seed Loop (`DischargeSystem`, `CombatSystem`, `CombatCoordinator`, `CombatPainter`):**
  - Replaced the 2D 16-box spreadsheet footer with 8 3D Ancestral Totem Turrets rendered directly in the 3D orbital arena (`normZ = 0.032`) plus a streamlined 3-control Martial Command Bar (`[ ‹ SOW ]`, `[ TOTEM STATUS / SUPER BEAM ]`, `[ SOW › ]`, `[ BLASTER FIRE ]`).
  - **Shoot-to-Harvest**: Every 2 blaster hits on an enemy or any enemy kill harvests a glowing seed directly into the active corridor's 3D Totem Turret (`HarvestSeedToBay`).
  - **Autonomous Totem Sentry Fire**: Totem Turrets with `2+` seeds (`AUTO-GUN`) automatically fire plasma bolts up their corridor every `1.5s` (`StepTotemTurrets` in C++ `DischargeSystem` and `MockVoidSowerEngine`), dealing `25 × M` damage and stripping enemy shields.
- **Morabaraba 3-in-a-Row Laser Fence (`CombatCoordinator`, `InvaderBulletManager`, `CombatPainter`):**
  - Aligning 3 adjacent Auto-Gun Turrets (`2+` seeds each) projects a golden 3D Morabaraba Laser Fence across their corridors that automatically intercepts and vaporizes descending enemy plasma bombs (`LASER FENCE ZAP! +50`) and grants a `1.5x` beam multiplier.
- **Plain-English Visual UI, Seed Pips & Updated Animated Tutorials (`MancalaBatteryDockWidget`, `KineticRuleDiorama`, `TutorialOverlay`, `TacticalDirectivesModal`, `BaoCodexDialog`):**
  - Removed all mathematical/technical jargon (`M²`, `M=0`, `T0 DORMANT`, `T3 SUPER-PRISM`, `NAMUA`, `SIPHON`, `CCW`) across the HUD, floating combat callouts, and tutorials.
  - Added 4 glowing visual seed pips (`● ● ○ ○`) and plain-English turret levels (`EMPTY`, `SHIELD`, `AUTO-GUN`, `MEGA GUN`) to the center command console.
  - Replaced bottom text banners with ultra-short icon-led directive nuggets (`🎯 SHOOT = +SEEDS  •  ⚡ 2+ SEEDS = AUTO-GUN  •  🛡️ 3 IN A ROW = LASER FENCE` and `💡 TIP: TAP SOW › TO POWER UP TOTEM #7`).
  - Re-authored all 4 60 FPS animated `KineticRuleDiorama` canvases (`sowingAndNamua`, `relayAndCascade`, `quadraticDamage`, `vanguardAltitude`) with pre-laid-out static `TextPainter`s (zero per-frame allocations) and updated the 5-step interactive Flight Academy, How-to-Play Directives, and Bao Codex to use visual chips and 1-sentence plain-English descriptions.
