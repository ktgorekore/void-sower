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

# Google Play Console Release Notes — v0.2.3 (Build 5)

## Release Track: Internal Testing / Closed Testing (Alpha / Beta)

---

### Copy-Paste Release Notes for Play Console (`en-US`)
```text
<en-US>
🚀 Void Sower v0.2.3 — Pro Commander Update!
• Pro Commander Tier: Unlock lifetime access ($1.29) or earn temporary battle passes with rewarded transmissions.
• Tactical Gating: AI Solver autopilot, MK-III Singularity Sovereign flagship, and deep sensor telemetry.
• Afrofuturistic Pro Upgrade Modal with seamless purchase restoration.
• Complete asset refresh: 60s tutorial walkthrough & updated high-res tactical displays.
• Native C++17 engine fully audited for Android 15 (16 KB page size).
</en-US>
```
*Character Count:* **476 / 500 max characters** (Google Play compliant).

---

### Localized Release Notes

#### 🇹🇿 Swahili (`sw`)
```text
<sw>
🚀 Void Sower v0.2.3 — Sasisho la Kamanda wa Pro!
• Daraja la Pro: Pata ufikiaji wa kudumu ($1.29) au tumia pasi za muda kupitia matangazo ya hiari.
• Vipengele vya Kipekee: AI Solver, chombo kikuu cha MK-III Singularity Sovereign, na rada ya kina.
• Dirisha jipya la ununuzi lenye muundo wa Kiafrika na urejeshaji wa ununuzi kwa urahisi.
• Picha mpya na mwongozo kamili wa sekunde 60 kwa marubani wapya.
• Injini ya C++17 imeboreshwa kwa Android 15 (kurasa za kumbukumbu za 16 KB).
</sw>
```
*Character Count:* **466 / 500 max characters**.

#### 🇫🇷 French (`fr-FR`)
```text
<fr-FR>
🚀 Void Sower v0.2.3 — Mise à jour Pro Commander !
• Rang Pro Commander : Débloquez l'accès à vie (1,29 $) ou obtenez des passes temporaires via vidéos récompensées.
• Fonctionnalités Pro : Pilote automatique IA, vaisseau amiral MK-III Singularity et télémétrie avancée.
• Nouvelle interface afrofuturiste de surclassement avec restauration instantanée des achats.
• Nouveaux visuels tactiques haute résolution et tutoriel de 60s.
• Moteur natif C++17 optimisé pour Android 15 (pages de 16 Ko).
</fr-FR>
```
*Character Count:* **476 / 500 max characters**.

#### 🇪🇸 Spanish (`es-ES`)
```text
<es-ES>
🚀 Void Sower v0.2.3 — ¡Actualización Pro Commander!
• Nivel Pro Commander: Desbloqueo de por vida ($1.29) o pases temporales mediante transmisiones recompensadas.
• Funciones Pro: Piloto automático de IA, buque insignia MK-III Singularity y telemetría de sensores profunda.
• Modal de mejora afrofuturista con restauración de compras con un toque.
• Nuevos recursos tácticos en alta definición y tutorial de 60s.
• Motor natif C++17 optimizado para Android 15 (páginas de memoria de 16 KB).
</es-ES>
```
*Character Count:* **475 / 500 max characters**.

---

## ⚡ Technical Release Highlights

1. **Hybrid Pro Entitlement Engine (`EntitlementService`):**
   - Granular `ProFeature` access evaluation for AI solver, MK-III flagship, and deep telemetry.
   - Synchronous, zero-latency reactive entitlement streams.
   - Dual-path access: persistent lifetime IAP ($1.29 USD) or temporary in-memory passes granted via Google AdMob rewarded video ads.
2. **Glassmorphic Afrofuturist Storefront (`ProUpgradeModal`):**
   - High-contrast neon gold and cyan palette with tactile haptics.
   - Integrated with `IapService` for single-tap checkout and instant receipt validation / restore purchases.
3. **CI / Native Toolchain Stability:**
   - Pinned `objective_c: 9.5.0` in `pubspec.yaml` dependency overrides to resolve the `Architecture.arm64e` build hook error on Linux GitHub runners.
4. **Comprehensive Media & Store Listing Refresh:**
   - 60s narrated cinematic gameplay tutorial (`void_sower_how_to_play_60s.mp4`) mastered with ambient synth pads and dynamic SFX.
   - 30s tactical AI solver showcase (`void_sower_solver_showcase_30s.mp4`) and 128-color Bayer-dithered preview GIF.
   - Updated phone ($1344 \times 2992$) and tablet ($2560 \times 1600$) screenshots capturing the latest Afrofuturistic HUD.
5. **Android 15 16 KB Page Size Compliance:**
   - Native C++ shared libraries built with `-Wl,-z,max-page-size=16384` across `arm64-v8a` and `x86_64` ABIs.

---

## 🚀 Play Console Upload Checklist

1. **Artifact:** `build/app/outputs/bundle/release/void-sower-v0.2.3.aab` (or downloaded from GitHub Actions Release).
2. **Native Debug Symbols:** `void-sower-symbols-v0.2.3.zip`.
3. **Version Code:** `5` (`0.2.3+5`).
4. **Signing:** Upload keystore configured via `android/key.properties` (or CI GitHub repository secret `ANDROID_KEYSTORE_BASE64`).
5. **Release Track:** **Internal testing** / **Closed testing (Alpha / Beta)**.
6. **Target Audience:** All enrolled test pilots.
