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

# Google Play Console Release Notes — v0.5.2 (Build 47)

## Release Track: Production / Internal / Open Testing

---

### Copy-Paste Release Notes for Play Console (`en-US`)
```text
<en-US>
🚀 Void Sower v0.5.2 — Profile-Linked PRO Badge & Crisp 1–2 Word UI Labels!
• Profile-Linked PRO Badge: Repositioned the PRO status pill right next to your Pilot Avatar across the HUD, Campaign Map & Dossier!
• Crisp 1–2 Word UI Labels: Audited & shortened buttons, badges, headers & stats across all 18 screens to eliminate text wrapping or clipping!
• Refreshed Storefront Media: Updated Play Store phone & tablet screenshots showcasing the cleaner, zero-wrap tactical interface!
</en-US>
```
*Character Count:* **474 / 500 max characters** (Google Play compliant).

---

### Localized Release Notes

#### 🇹🇿 Swahili (`sw`)
```text
<sw>
🚀 Void Sower v0.5.2 — Beji ya PRO Kando ya Picha ya Rubani na Lebo Fupi Safi!
• Beji ya PRO Kando ya Wasifu: Beji ya PRO sasa ipo moja kwa moja kando ya picha ya Rubani kwenye HUD, Ramani na Wasifu!
• Lebo Fupi za Maneno 1–2: Vifungo, vichwa na takwimu zote zimefupishwa ili kuondoa kukatika kwa maandishi kwenye skrini!
• Mwonekano Safi wa 3D: Picha mpya za Play Store za simu na kompyuta kibao zenye kiolesura safi cha mbinu!
</sw>
```
*Character Count:* **435 / 500 max characters**.

#### 🇫🇷 French (`fr-FR`)
```text
<fr-FR>
🚀 Void Sower v0.5.2 — Badge PRO Lié au Profil Pilote & Libellés UI Ultra-Concis !
• Badge PRO à Côté de l'Avatar : Le badge PRO est désormais placé juste à côté de votre avatar pilote dans le HUD, la Carte et le Dossier !
• Libellés Concis (1–2 Mots) : Tous les boutons, en-têtes et compteurs ont été raccourcis pour éliminer toute troncature ou retour à la ligne !
• Captures Actualisées : Nouvelles captures téléphone et tablette présentant l'interface épurée !
</fr-FR>
```
*Character Count:* **476 / 500 max characters**.

#### 🇪🇸 Spanish (`es-ES`)
```text
<es-ES>
🚀 Void Sower v0.5.2 — ¡Insignia PRO Junto al Perfil de Piloto y Etiquetas Concisas!
• Insignia PRO Vinculada al Perfil: ¡La insignia PRO ahora se ubica junto a tu avatar de piloto en el HUD, Mapa Estelar y Dossier!
• Etiquetas de 1–2 Palabras: ¡Botones, encabezados y estadísticas abreviados en las 18 pantallas para evitar cortes o saltos de línea!
• Capturas Renovadas: ¡Nuevas capturas de teléfono y tableta con la interfaz táctica optimizada!
</es-ES>
```
*Character Count:* **465 / 500 max characters**.

---

### Internal Engineering Notes (Build 47)
- **Profile-Linked PRO Status Badge (`SlimlineHudHeader`, `ProfileModal`, `StatsDashboardScreen`, `CampaignMapScreen`):**
  - Repositioned the PRO status pill (`Key('hud_pro_pill')`) in `SlimlineHudHeader` immediately to the right of the circular Pilot Profile Avatar (`Key('hud_profile_avatar')`) before the first vertical divider, making it immediately obvious that PRO status is tied to the user profile.
  - Added a gilded `Icons.workspace_premium` badge overlay directly on the user profile avatar in `ProfileModal` and `StatsDashboardScreen`, and paired the PRO badge next to the `PILOT` bottom navigation icon on `CampaignMapScreen` when Pro is active.
- **Game-Wide UI Label String Audit & Shortening (18 Presentation Files):**
  - Shortened verbose multi-word phrases into crisp 1–2 word labels across `ProfileModal`, `StatsDashboardScreen`, `CombatScreen`, `PauseMenuDialog`, `VictoryDialog`, `GameOverDialog`, `CampaignMapScreen`, `SimulationLabScreen`, `CommandArcWidget`, `ProjectionShelf`, `ProUpgradeModal`, `ProBoostModal`, `RewardedAdModal`, `SettingsModal`, `TacticalDirectivesModal`, `TutorialOverlay`, and `FleetHangarDialog` to prevent text wrapping or truncation on compact mobile screens.
- **Test Suite & Storefront Media Refresh:**
  - Updated all 15 widget test suites (356/356 passing, 0 analyzer warnings) and recaptured all 10 phone and 7 tablet Google Play Store screenshots.
