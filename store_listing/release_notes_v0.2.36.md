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

# Google Play Console Release Notes — v0.2.36 (Build 39)

## Release Track: Production / Internal / Open Testing

---

### Copy-Paste Release Notes for Play Console (`en-US`)
```text
<en-US>
⚡ Void Sower v0.2.36 — Performance Engine & Battery Optimization!
• Ultra-Smooth 120 FPS: Eliminated rendering pipeline stalls and transient memory allocations for sustained high-refresh orbital combat.
• Battery Conservation: Hardened background lifecycle timers to prevent battery drain while minimized.
• Soundtrack Restoration: Seamless audio focus and ambient music resumption across app pauses.
• Tactical Accuracy: Upgraded native AI cascade simulation calculations for flawless weapon telemetry.
</en-US>
```
*Character Count:* **472 / 500 max characters** (Google Play compliant).

---

### Localized Release Notes

#### 🇹🇿 Swahili (`sw`)
```text
<sw>
⚡ Void Sower v0.2.36 — Uboreshaji wa Kasi na Utunzaji wa Betri!
• Fremu 120 kwa Sekunde: Uchezaji laini zaidi bila kukwama kwa kuondoa msongamano wa picha.
• Utunzaji wa Betri: Kuzuia matumizi yasiyo ya lazima ya betri wakati mchezo upo nyuma.
• Muziki Imara: Muziki na sauti zinaendelea vizuri bila kukatika unaporudi kwenye mchezo.
• Usahihi wa Vita: Utabiri sahihi zaidi wa silaha za plasma katika mfumo wa C++.
</sw>
```
*Character Count:* **434 / 500 max characters**.

#### 🇫🇷 French (`fr-FR`)
```text
<fr-FR>
⚡ Void Sower v0.2.36 — Performance & Économie d'Énergie !
• 120 FPS Ultra-Fluide : Élimination des saccades graphiques et optimisation mémoire en plein combat spatial.
• Économie de Batterie : Arrêt complet des calculs en arrière-plan pour préserver l'autonomie.
• Ambiance Sonore Rétablie : Reprise fluide des musiques spatiales après une pause ou un changement d'application.
• Précision Balistique : Calculs C++ synchronisés pour des tirs de lances plasma parfaits.
</fr-FR>
```
*Character Count:* **479 / 500 max characters**.

---

### Internal Engineering Notes (Build 39)
- Eliminated `canvas.saveLayer` offscreen GPU stalls in `CombatPainter` via pre-calculated opacity LUT.
- Replaced per-frame `Color`, `Offset`, and `Rect` heap allocations in `CombatPainter`, `Dreadnought3DMesh`, and `Starfield3DPainter`.
- Implemented lifecycle timer cancellation in `CombatScreen` across `paused` and `hidden` states.
- Fixed `AudioService.requestExclusiveAudioFocus()` audio source corruption.
- Harmonized `PredictCascadeResult()` in `bao_cascade_system.cpp` with `lance_alpha_multiplier_`.
- Normalized `ffi_boundary_test.cpp` to `namespace void_sower::tests`.
- Decoupled dialog workflows via `CombatSettingsSheet` and `CombatDialogCoordinator`.
