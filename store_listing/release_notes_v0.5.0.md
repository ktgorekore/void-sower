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

# Google Play Console Release Notes — v0.5.0 (Build 45)

## Release Track: Production / Internal / Open Testing

---

### Copy-Paste Release Notes for Play Console (`en-US`)
```text
<en-US>
🚀 Void Sower v0.5.0 — 3-Act Story Missions, Active Super Beams & Adaptive AI!
• 100% Player-Driven Combat: Totems hold stored M² power until YOU command a Super Beam, Sow Cascade, or 3-Bay Fence Blast!
• 3-Act Story Sectors: Every sector now features Act I Recon, Act II Siege + Relic Draft & Act III Apex Boss with live comms!
• Automatic 3D Flight Camera: Smooth reactive 3D banking & pitching as you fly—no manual camera buttons!
• Smarter Enemies: Invaders evade charged lanes & flank weak bays!
</en-US>
```
*Character Count:* **496 / 500 max characters** (Google Play compliant).

---

### Localized Release Notes

#### 🇹🇿 Swahili (`sw`)
```text
<sw>
🚀 Void Sower v0.5.0 — Misheni za Hadithi za Hatua 3, Miale Kuu na AI Janja!
• Mapigano ya Mchezaji 100%: Minara inahifadhi nguvu hadi UFYATUE Miale Kuu au Ukuta wa Leza!
• Misheni za Hatua 3: Kila sekta ina Hatua ya 1 (Upelelezi), Hatua ya 2 (Mzingiro + Visukuku) na Hatua ya 3 (Bosi Mkuu)!
• Kamera ya 3D Kiotomatiki: Kamera inainama na kupaa moja kwa moja unapoendesha meli!
• Maadui Wajanja: Maadui wanakwepa njia zenye chaji kubwa!
</sw>
```
*Character Count:* **449 / 500 max characters**.

#### 🇫🇷 French (`fr-FR`)
```text
<fr-FR>
🚀 Void Sower v0.5.0 — Missions en 3 Actes, Super Rayons Actifs & IA Adaptative !
• Combat 100 % Actif : Vos tourelles stockent l'énergie M² jusqu'à VOTRE tir ou barrage !
• Missions Scénarisées en 3 Actes : Acte I Recon, Acte II Siège + Reliques et Acte III Boss Apex avec transmissions radio !
• Caméra 3D Automatique : Inclinaison et tangage 3D dynamiques selon votre vol, sans boutons superflus !
• IA Ennemie Tactique : Les ennemis esquivent les couloirs chargés !
</fr-FR>
```
*Character Count:* **474 / 500 max characters**.

#### 🇪🇸 Spanish (`es-ES`)
```text
<es-ES>
🚀 Void Sower v0.5.0 — ¡Misiones en 3 Actos, Súper Rayos Activos e IA Adaptativa!
• Combate 100% Activo: ¡Los tótems almacenan energía M² hasta que TÚ dispares un Súper Rayo o Valla Láser!
• Misiones de Historia en 3 Actos: ¡Acto I Reconocimiento, Acto II Asedio + Reliquias y Acto III Jefe Ápex con radio en vivo!
• Cámara 3D Automática: ¡Inclinación y cabeceo 3D reactivos al volar sin botones manuales!
• IA Enemiga Inteligente: ¡Los invasores esquivan carriles cargados!
</es-ES>
```
*Character Count:* **478 / 500 max characters**.

---

### Internal Engineering Notes (Build 45)
- **Eliminated Passive Auto-Firing Victories (100% Player-Triggered Offensive Firing):**
  - Fixed backward-play wave generation in `WaveGenerator::GenerateWave` (`src/ecs/systems/wave_generator.cpp`) so `simulated_bays[frontline_bay] = 0` when gathering backward into the origin bay, preventing waves from starting with pre-charged `M >= 2` frontline bays in enemy corridors.
  - Removed `ProcessAutonomousTotemTurrets` from `CombatSystem` (`src/ecs/systems/combat_system.cpp`) and `MockVoidSowerEngine` (`lib/engine/mock_void_sower_engine.dart`). Charged frontline Totems provide defensive bomb shields ($M \ge 1$), Morabaraba 3-in-a-row Laser Fences ($M \ge 2$), and stored $M^2$ power that discharges **only** when the player commands a shot or sowing cascade.
  - Updated `MancalaBatteryDockWidget` tier labels from `'AUTO-GUN'` to `'SUPER BEAM'`.
- **Automatic Reactive 3D Flight Camera (Removed Manual Camera Gimbal Clutter):**
  - Removed the manual 5-button 3D Camera Gimbal Dock (`CHASE 3D`, `BRIDGE 3D`, `ORBIT 3D`, `TOP-DOWN`, pitch/yaw buttons) from `CombatScreen` (`lib/presentation/screens/combat_screen.dart`).
  - Connected `_camera3D` pitch and banking yaw directly to the Dreadnought's forward depth (`normForward`) and lateral velocity (`velocityDx`) in `_onTick` for seamless 3D space flight immersion.
- **Full 3-Act Story Progression Across All 27 Sectors & Holographic Comms Overlay:**
  - Enabled progressive `reinforcementQuota` across **Kilwa Nebula Basin** (Sectors 1–9) and **Phantom Drift** (Sectors 10–18) in `CampaignService` (`lib/domain/services/campaign_service.dart`) so every sector progresses through all 3 story acts (`Phase I: Vanguard Recon` $\to$ `Phase II: Tactical Siege + Relic Draft` $\to$ `Phase III: Apex Command Boss`).
  - Enriched `SectorNarrativeRegistry` (`lib/domain/models/narrative_transmission.dart`) with sector-specific lore targets across all 27 sectors and added the tap-to-dismiss **3-Act Story & Comms HUD Overlay** (`narrative_comms_banner` and `story_act_status_pill`) in `CombatScreen`.
- **Progressively Intelligent Enemy AI:**
  - Upgraded `MovementSystem::AdvanceEnemies` (`src/ecs/systems/movement_system.cpp`) and `MockVoidSowerEngine.stepSimulation` with zero-allocation tactical battlefield awareness: lateral-maneuvering enemies actively evade `M >= 2` charged corridors when an adjacent corridor has lower charge, flank unshielded (`M == 0`) conduits, and screen damaged capital vessels.
  - Upgraded `InvaderBulletManager.update` (`lib/presentation/controllers/invader_bullet_manager.dart`) to prioritize shooters aligned with the Dreadnought or charged frontline bays.
