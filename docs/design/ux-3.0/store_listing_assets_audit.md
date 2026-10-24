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

# 🚀 Google Play Store Listing & Media Assets Audit (UX 3.0)

This document records the visual assets, live emulator verification, and audit of the promotional and in-store materials for **VOID SOWER** under the **UX 3.0 Clean Sci-Fi Aesthetic**.

---

## 1. Play Store Branding Assets

| Asset Type | File Path | Dimensions | Format | Audit Status | Description |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Prominent Feature Graphic** | [`docs/media/feature_graphic_1024x500.png`](file:///home/kelvingorekore/projects/void-sower/docs/media/feature_graphic_1024x500.png) | `1024 x 500 px` | 24-bit PNG | **PASSED (Pristine)** | Epic panoramic deep-space dreadnought launching axial cyan particle lances against descending alien swarms with glowing 16-bay planetary defense ring and bold modern typography. |
| **Store App Icon** | [`docs/media/app_icon_512x512.png`](file:///home/kelvingorekore/projects/void-sower/docs/media/app_icon_512x512.png) | `512 x 512 px` | 32-bit PNG | **PASSED (Pristine)** | Heroic top-down dreadnought warship with illuminated cyan plasma prow, gold core, thruster contrails, and 16-segment capacitor energy halo against obsidian deep space. |
| **Project Icon Asset** | [`assets/icons/app_icon.png`](file:///home/kelvingorekore/projects/void-sower/assets/icons/app_icon.png) | `512 x 512 px` | 32-bit PNG | **PASSED (Pristine)** | High-resolution master icon asset for Flutter framework packaging. |
| **Android Launcher Icons** | `android/app/src/main/res/mipmap-*/` | `48–192 px` | PNG (Square & Round) | **PASSED (Pristine)** | Scaled across all screen densities (`mdpi`, `hdpi`, `xhdpi`, `xxhdpi`, `xxxhdpi`). |

---

## 2. Live Emulator Screenshot Audit (Pixel-Pristine Verification)

Captured directly from Android 17 (16 KB page-size kernel) on physical resolution **`1344 x 2992 px`** with **zero debug banners**, **zero test ads**, and **zero intrusive login prompts**.

### Phone Screenshot Portfolio (`1344 x 2992 px`)

| # | Screen ID | Target File | Dimensions | Visual Subject & Audit Findings |
| :-: | :--- | :--- | :--- | :--- |
| **01** | **Tactical Combat Grid (Mega Gun Ready)** | [`01_tactical_combat_grid.png`](file:///home/kelvingorekore/projects/void-sower/store_listing/screenshots/phone/01_tactical_combat_grid.png) | `1344 x 2992` | Tier 3 (`S9 • BASTION`) 3D combat with 6 descending enemy vessels, spinning 3D Golden Nyumba Diamond Crystals above Totems #3 and #8, profile-linked `PRO` badge on the top-left pilot avatar, and the dock glowing `✨ #3 • MEGA GUN ••••` (`16x`). |
| **02** | **Quadratic Axial Particle Lance** | [`02_axial_particle_lance.png`](file:///home/kelvingorekore/projects/void-sower/store_listing/screenshots/phone/02_axial_particle_lance.png) | `1344 x 2992` | Full-height **Quadratic Exaggerated `MEGA GUN` Super Beam (`16x`–`36x`)** erupting down Corridor #3 (`SUPER CRIT +17373`, `CANOPY RAM! +75`), featuring wide volumetric plasma cone, 5 counter-wound quadratic double-helix diamonds, 5 concentric 3D shockwave rings, and 8-point muzzle/impact star novas. |
| **03** | **3-Beam Morabaraba Fence Blast Barrage** | [`03_morabaraba_fence_blast_barrage.png`](file:///home/kelvingorekore/projects/void-sower/store_listing/screenshots/phone/03_morabaraba_fence_blast_barrage.png) | `1344 x 2992` | Simultaneous **3-Beam Golden Morabaraba `FENCE BLAST` Barrage** across Corridors #5, #6, and #7 with 3 side-by-side golden quadratic double-helix beams, `MORABARABA FENCE +75`, `+4 CORES`, `+2 SEEDS`, and `DEFLECT +50`. |
| **04** | **Bao Sowing & Morabaraba Laser Fence** | [`04_morabaraba_laser_fence_sowing.png`](file:///home/kelvingorekore/projects/void-sower/store_listing/screenshots/phone/04_morabaraba_laser_fence_sowing.png) | `1344 x 2992` | Active Bao sowing with a 3-Totem Golden 3D Morabaraba Laser Fence (`MILL 1.5x` badge + gold `BLAST` button) simultaneous with a Quadratic Exaggerated Super Beam (`⚡ 900x DMG`, `SUPER CRIT +12630`). |
| **05** | **AI Autopilot Tactical Solver** | [`05_ai_autopilot_tactical_solver.png`](file:///home/kelvingorekore/projects/void-sower/store_listing/screenshots/phone/05_ai_autopilot_tactical_solver.png) | `1344 x 2992` | Autonomous C++ MCTS `AI AUTO` / `AI SIM` tactical solver orchestrating multi-lap Bao cascades and firing a cyan/gold quadratic Particle Lance down Corridor #2. |
| **06** | **Kilwa Basin Campaign Map** | [`06_kilwa_basin_campaign_map.png`](file:///home/kelvingorekore/projects/void-sower/store_listing/screenshots/phone/06_kilwa_basin_campaign_map.png) | `1344 x 2992` | Clean, modal-free `KILWA NEBULA BASIN` Campaign Star Map (`LIBERATED 8/9`, `3★` medals) with `Great Siphon Singularity • ACTIVE SIEGE` ready for deployment. |
| **07** | **Orbital Fleet Hangar** | [`07_orbital_fleet_hangar.png`](file:///home/kelvingorekore/projects/void-sower/store_listing/screenshots/phone/07_orbital_fleet_hangar.png) | `1344 x 2992` | `ORBITAL DRYDOCK` 3D wireframe mesh preview (`3D MESH // 16V`) and Dreadnought chassis selector (`MK-I Bastion Standard`, `MK-II Monsoon Vanguard`, `MK-III Kilwa Apex`). |
| **08** | **Special Operations Command** | [`08_special_operations_command.png`](file:///home/kelvingorekore/projects/void-sower/store_listing/screenshots/phone/08_special_operations_command.png) | `1344 x 2992` | `SPECIAL OPERATIONS` modal (`DAILY SORTIE`, `VOID INCURSION`, `PRO FLEET`) featuring concise 1–2 word tactical action badges (`LAUNCH`, `SURVIVAL`, `ENDLESS`). |
| **09** | **Pilot Telemetry Dossier** | [`09_pilot_telemetry_dossier.png`](file:///home/kelvingorekore/projects/void-sower/store_listing/screenshots/phone/09_pilot_telemetry_dossier.png) | `1344 x 2992` | `PILOT TELEMETRY // COMMAND RECORD` dossier (`OVERVIEW`, `ACCOLADES`, `LOGS`) highlighting the gold medal badge anchored on the pilot avatar and `Vanguard-01 [PRO]`. |
| **10** | **Flight Academy Onboarding** | [`10_flight_academy_onboarding.png`](file:///home/kelvingorekore/projects/void-sower/store_listing/screenshots/phone/10_flight_academy_onboarding.png) | `1344 x 2992` | Interactive `FLIGHT ACADEMY` (`STEP 1/5: 1. SHOOT TO GROW TURRETS`) over the 3D Orbital Trench. |

### Tablet Screenshot Portfolio (`1600 x 2560 px`)

| # | Screen ID | Target File | Dimensions | Visual Subject & Audit Findings |
| :-: | :--- | :--- | :--- | :--- |
| **01** | **Tablet Tactical Combat (Mega Gun)** | [`01_tablet_tactical_combat.png`](file:///home/kelvingorekore/projects/void-sower/store_listing/screenshots/tablet/01_tablet_tactical_combat.png) | `1600 x 2560` | Wide-aspect 10-inch tablet Tier 3 (`S9 • BASTION`) 3D combat with 6 enemy vessels, spinning 3D Golden Nyumba Diamond Crystals, and `✨ #3 • MEGA GUN ••••` (`16x`) dock. |
| **02** | **Tablet Quadratic Super Beam** | [`02_tablet_axial_particle_lance.png`](file:///home/kelvingorekore/projects/void-sower/store_listing/screenshots/tablet/02_tablet_axial_particle_lance.png) | `1600 x 2560` | Massive **Quadratic Exaggerated `MEGA GUN` Super Beam** on 16:10 tablet display (`SUPER CRIT +17139`, 5 counter-wound double-helix diamonds, 5 concentric shockwave rings, 8-point star novas). |
| **03** | **Tablet 3-Beam Fence Blast** | [`03_tablet_morabaraba_fence_blast.png`](file:///home/kelvingorekore/projects/void-sower/store_listing/screenshots/tablet/03_tablet_morabaraba_fence_blast.png) | `1600 x 2560` | Simultaneous **3-Beam Golden Morabaraba `FENCE BLAST` Barrage** firing 3 side-by-side golden quadratic double-helix beams (`+4 CORES`, `DEFLECT +50`) across the 16:10 tablet viewport. |
| **04** | **Tablet Morabaraba Laser Fence & Sowing** | [`04_tablet_morabaraba_laser_fence.png`](file:///home/kelvingorekore/projects/void-sower/store_listing/screenshots/tablet/04_tablet_morabaraba_laser_fence.png) | `1600 x 2560` | Active Bao sowing with a 3-Totem Golden 3D Morabaraba Laser Fence (`MILL 1.5x` + `BLAST`) simultaneous with a `⚡ 900x DMG` Super Beam (`SUPER CRIT +10006`). |
| **05** | **Tablet Campaign Star Map** | [`05_tablet_campaign_map.png`](file:///home/kelvingorekore/projects/void-sower/store_listing/screenshots/tablet/05_tablet_campaign_map.png) | `1600 x 2560` | Clean `KILWA NEBULA BASIN` Campaign Star Map (`LIBERATED 8/9`, `Great Siphon Singularity • ACTIVE SIEGE`) on 16:10 tablet display. |
| **06** | **Tablet Fleet Hangar** | [`06_tablet_fleet_hangar.png`](file:///home/kelvingorekore/projects/void-sower/store_listing/screenshots/tablet/06_tablet_fleet_hangar.png) | `1600 x 2560` | `ORBITAL DRYDOCK` 3D Dreadnought wireframe preview (`3D MESH // 16V`) and chassis telemetry on 16:10 tablet display. |
| **07** | **Tablet Pilot Telemetry Dossier** | [`07_tablet_pilot_telemetry_dossier.png`](file:///home/kelvingorekore/projects/void-sower/store_listing/screenshots/tablet/07_tablet_pilot_telemetry_dossier.png) | `1600 x 2560` | `PILOT TELEMETRY // COMMAND RECORD` dossier on 16:10 tablet display with profile-linked `PRO` badge and `OVERVIEW` / `ACCOLADES` / `LOGS` tabs. |
| **08** | **Tablet Flight Academy** | [`08_tablet_flight_academy.png`](file:///home/kelvingorekore/projects/void-sower/store_listing/screenshots/tablet/08_tablet_flight_academy.png) | `1600 x 2560` | Interactive `FLIGHT ACADEMY` onboarding over the 3D Orbital Trench on 16:10 tablet display. |

---

## 3. Gameplay Showcase & Tutorial Video Specifications (with BGM + Combat SFX)

| Metric | 30s YouTube & Play Store Showcase | 60s Narrated Tutorial Showcase |
| :--- | :--- | :--- |
| **File Locations** | [`docs/media/void_sower_gameplay_showcase.mp4`](file:///home/kelvingorekore/projects/void-sower/docs/media/void_sower_gameplay_showcase.mp4)<br>[`docs/media/void_sower_solver_showcase_30s.mp4`](file:///home/kelvingorekore/projects/void-sower/docs/media/void_sower_solver_showcase_30s.mp4)<br>[`store_listing/assets/promo_gameplay.mp4`](file:///home/kelvingorekore/projects/void-sower/store_listing/assets/promo_gameplay.mp4) | [`docs/media/void_sower_how_to_play_60s.mp4`](file:///home/kelvingorekore/projects/void-sower/docs/media/void_sower_how_to_play_60s.mp4)<br>[`store_listing/assets/how_to_play_60s.mp4`](file:///home/kelvingorekore/projects/void-sower/store_listing/assets/how_to_play_60s.mp4)<br>[`assets/video/how_to_play.mp4`](file:///home/kelvingorekore/projects/void-sower/assets/video/how_to_play.mp4) |
| **Duration** | `30.00 seconds` | `60.00 seconds` |
| **Resolution** | `1080 x 2400 px` (60 FPS) | `1080 x 2400 px` (30 FPS) |
| **Video / Audio Codecs** | H.264 (`libx264`) + Stereo AAC (`44.1 kHz`, `192 kbps`) | H.264 (`libx264`) + Stereo AAC (`44.1 kHz`, `192 kbps`) |
| **Audio Mix** | Procedural Deep-Space Synth BGM + Synchronized Combat SFX (`lance_fire.wav`, `flak_burst.wav`, `sow_step.wav`, `inject_core.wav`, `overload.wav`, `bullet_deflect.wav`, `victory.wav`) | Neural Voiceover (`en-US-ChristopherNeural`) + Ducking Ambient Synth BGM + Synchronized Combat SFX |

---

## 4. Quality Audit Checklist

- [x] **No Test Ads:** Ad banners and test interstitial overlays have been verified absent during all captures.
- [x] **No Login Walls:** Screens showcase playable game modes without third-party auth popups.
- [x] **No Debug Banners:** `debugShowCheckedModeBanner: false` ensures zero Flutter debug banners in all media.
- [x] **High DPI Resolution:** Screenshots are 1344x2992 (exceeding standard 1080p requirements for crisp store display).
- [x] **Consistent Brand Palette:** Strict compliance with Void Theme (`#070C18` Obsidian, `#00E5FF` Cyan, `#FFD700` Gold, `#7C3AED` Amethyst).
- [x] **16 KB Page-Size Kernel Compatibility:** Engine operates smoothly on Android 16 KB kernel emulator.
