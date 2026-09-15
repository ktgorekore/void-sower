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

# Google Play Console Release Notes — v0.2.5 (Build 7)

## Release Track: Internal Testing / Closed Testing (Alpha / Beta)

---

### Copy-Paste Release Notes for Play Console (`en-US`)
```text
<en-US>
🚀 Void Sower v0.2.5 — Adaptive Launcher Icons & Storefront Overhaul!
• Upgraded application icons to Android Adaptive Icons with native circle, squircle, and rounded shape support.
• Resolved issue where launcher displayed a square inside a white circle on devices with circular icons.
• Added high-resolution 108dp adaptive foregrounds, cosmic navy background vectors, and legacy round icons across all screen densities.
• Updated 512x512 Google Play Store listing icon.
</en-US>
```
*Character Count:* **476 / 500 max characters** (Google Play compliant).

---

### Localized Release Notes

#### 🇹🇿 Swahili (`sw`)
```text
<sw>
🚀 Void Sower v0.2.5 — Maboresho ya Aikoni za Skrini na Duka la Google Play!
• Aikoni zimeboreshwa kusaidia mifumo yote ya Android Adaptive Icons ikiwemo maumbo ya duara na mraba.
• Imerekebisha hitilafu ambapo aikoni ilionekana kama mraba ndani ya duara kwenye simu zenye aikoni za duara.
• Imeongeza tabaka za michoro ya anga na meli ya kivita kwenye viwango vyote vya ubora wa skrini.
• Imesasisha aikoni ya 512x512 ya Duka la Google Play.
</sw>
```
*Character Count:* **445 / 500 max characters**.

#### 🇫🇷 French (`fr-FR`)
```text
<fr-FR>
🚀 Void Sower v0.2.5 — Icônes Adaptatives Android et Mise à Jour du Store !
• Prise en charge complète des icônes adaptatives Android (cercles, squircles, coins arrondis).
• Correction du problème d'affichage de l'icône carrée dans un cercle blanc sur les téléphones modernes.
• Ajout des calques de premier plan 108dp, de l'arrière-plan vectoriel cosmique et des icônes rondes legacy.
• Mise à jour de l'icône 512x512 pour la fiche Google Play Store.
</fr-FR>
```
*Character Count:* **477 / 500 max characters**.

#### 🇪🇸 Spanish (`es-ES`)
```text
<es-ES>
🚀 Void Sower v0.2.5 — ¡Iconos Adaptativos y Actualización de Google Play!
• Compatibilidad total con iconos adaptativos de Android para formas circulares, cuadradas y redondeadas.
• Se corrigió el error donde el icono aparecía como un cuadrado dentro de un círculo blanco en móviles modernos.
• Añadidas capas de primer plano de 108dp, fondo vectorial cósmico e iconos circulares para todas las densidades.
• Actualizado el icono oficial de 512x512 para Google Play Store.
</es-ES>
```
*Character Count:* **474 / 500 max characters**.

---

## ⚡ Technical Release Highlights

1. **Android Adaptive Icon Architecture (`mipmap-anydpi-v26`):**
   - Configured `ic_launcher.xml` and `ic_launcher_round.xml` in `res/mipmap-anydpi-v26/` referencing `<background android:drawable="@drawable/ic_launcher_background"/>` and `<foreground android:drawable="@mipmap/ic_launcher_foreground"/>`.
   - Registered `android:roundIcon="@mipmap/ic_launcher_round"` in `AndroidManifest.xml`.
2. **Safe-Zone Centered Foreground Layer:**
   - Sized foreground assets to 108dp across all density buckets (`mdpi`: 108px, `hdpi`: 162px, `xhdpi`: 216px, `xxhdpi`: 324px, `xxxhdpi`: 432px).
   - Centered the Afrofuturistic dreadnought flagship within the 72dp safe zone so circular, squircle, and rounded masks display the flagship without clipping or square edge artifacts.
3. **Cosmic Space Vector Background & Legacy Round Fallbacks:**
   - Created `drawable/ic_launcher_background.xml` with Obsidian Black (`#070A12`) and Deep Space Navy (`#0D1220`) vector geometry.
   - Generated circular-masked `ic_launcher_round.png` assets with alpha transparency for legacy Android 7.1 launchers.
4. **Google Play Store Specification Conformance:**
   - Provisioned 512x512 32-bit PNG web launcher icons in `android/app/src/main/ic_launcher-web.png` and `store_listing/assets/app_icon_512.png` (554 KB, well under the 1024 KB limit).
