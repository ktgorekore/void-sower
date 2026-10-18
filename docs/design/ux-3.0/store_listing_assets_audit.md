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
| **01** | **Combat Viewport (Mega Gun Ready)** | [`01_combat_tactical_depth.png`](file:///home/kelvingorekore/projects/void-sower/docs/media/store_screenshots/01_combat_tactical_depth.png) | `1344 x 2992` | Tier 3 (`S9 • BASTION`) 3D combat with 6 descending enemy vessels (Cruisers, Interceptors, Apex Boss Flagship), spinning 3D Golden Nyumba Diamond Crystals above Totems #3 and #8, and the dock glowing `✨ TOTEM #3 • MEGA GUN ••••` (`⚡ TAP FOR 16x SUPER BEAM`). |
| **02** | **Quadratic Exaggerated Super Beam** | [`02_axial_particle_lance.png`](file:///home/kelvingorekore/projects/void-sower/docs/media/store_screenshots/02_axial_particle_lance.png) | `1344 x 2992` | Full-height **Quadratic Exaggerated `MEGA GUN` Super Beam (`16x`–`36x`)** erupting down Corridor #3 (`SUPER CRIT +20419`), featuring wide volumetric plasma cone, 5 counter-wound quadratic double-helix diamonds, 5 concentric 3D shockwave rings, and 8-point muzzle/impact star novas. |
| **03** | **Orbital Command Deck** | [`03_orbital_command_campaign.png`](file:///home/kelvingorekore/projects/void-sower/docs/media/store_screenshots/03_orbital_command_campaign.png) | `1344 x 2992` | Clean, modal-free `KILWA NEBULA BASIN` Campaign Star Map (`LIBERATED 8/9`) with `Great Siphon Singularity • Tier 3 Corridors • ENGAGE` active. |
| **04** | **Fleet Hangar Inspection** | [`04_fleet_hangar_inspection.png`](file:///home/kelvingorekore/projects/void-sower/docs/media/store_screenshots/04_fleet_hangar_inspection.png) | `1344 x 2992` | `ORBITAL DRYDOCK` 3D wireframe mesh preview (`16V`) and Dreadnought chassis selector (`MK-I Bastion Standard`, `MK-II Monsoon Vanguard`). |
| **05** | **Bao Sowing & Morabaraba Laser Fence** | [`05_tactical_directives_codex.png`](file:///home/kelvingorekore/projects/void-sower/docs/media/store_screenshots/05_tactical_directives_codex.png) | `1344 x 2992` | Active Bao sowing with a 3-Totem Golden 3D Morabaraba Laser Fence (`MILL 1.5x` badge + gold `FENCE BLAST` button) simultaneous with a Quadratic Exaggerated Super Beam (`⚡ 900x DMG`, `SUPER CRIT +9446`). |
| **06** | **3-Beam Morabaraba Fence Blast** | [`06_tactical_pause_controls.png`](file:///home/kelvingorekore/projects/void-sower/docs/media/store_screenshots/06_tactical_pause_controls.png) | `1344 x 2992` | Simultaneous **3-Beam Golden Morabaraba `FENCE BLAST` Barrage** across Corridors #5, #6, and #7 with 3 side-by-side golden quadratic double-helix beams, `+1 SNIPE READY!`, `+4 CORES (CACHE DISCOVERED)`, and `CULL ×1` unlocked. |

### Tablet Screenshot Portfolio (`1600 x 2560 px`)

| # | Screen ID | Target File | Dimensions | Visual Subject & Audit Findings |
| :-: | :--- | :--- | :--- | :--- |
| **01** | **Tablet Tactical Combat (Mega Gun)** | [`01_tablet_tactical_combat.png`](file:///home/kelvingorekore/projects/void-sower/store_listing/screenshots/tablet/01_tablet_tactical_combat.png) | `1600 x 2560` | Wide-aspect 10-inch tablet Tier 3 (`S9 • BASTION`) 3D combat with 6 enemy vessels, spinning 3D Golden Nyumba Diamond Crystals, and `✨ TOTEM #3 • MEGA GUN ••••` (`⚡ TAP FOR 16x SUPER BEAM`) dock. |
| **02** | **Tablet Quadratic Super Beam** | [`02_tablet_axial_particle_lance.png`](file:///home/kelvingorekore/projects/void-sower/store_listing/screenshots/tablet/02_tablet_axial_particle_lance.png) | `1600 x 2560` | Massive **Quadratic Exaggerated `MEGA GUN` Super Beam** on 16:10 tablet display (`SUPER CRIT +19813`, `DEFLECT +50`, 5 counter-wound double-helix diamonds, 5 concentric shockwave rings, 8-point star novas). |
| **03** | **Tablet Campaign Star Map** | [`03_tablet_campaign_map.png`](file:///home/kelvingorekore/projects/void-sower/store_listing/screenshots/tablet/03_tablet_campaign_map.png) | `1600 x 2560` | Clean `KILWA NEBULA BASIN` Campaign Star Map (`LIBERATED 8/9`, `Great Siphon Singularity • ENGAGE`) on 16:10 tablet display. |
| **04** | **Tablet Fleet Hangar** | [`04_tablet_fleet_hangar.png`](file:///home/kelvingorekore/projects/void-sower/store_listing/screenshots/tablet/04_tablet_fleet_hangar.png) | `1600 x 2560` | `ORBITAL DRYDOCK` 3D Dreadnought wireframe preview and chassis telemetry on 16:10 tablet display. |
| **05** | **Tablet Flight Academy** | [`05_tablet_flight_academy.png`](file:///home/kelvingorekore/projects/void-sower/store_listing/screenshots/tablet/05_tablet_flight_academy.png) | `1600 x 2560` | Interactive Flight Academy onboarding over the 3D Orbital Trench on 16:10 tablet display. |
| **06** | **Tablet 3-Beam Fence Blast** | [`06_tablet_bao_codex.png`](file:///home/kelvingorekore/projects/void-sower/store_listing/screenshots/tablet/06_tablet_bao_codex.png) | `1600 x 2560` | Simultaneous **3-Beam Golden Morabaraba `FENCE BLAST` Barrage** firing 3 side-by-side golden quadratic double-helix beams (`⚡ 100x DMG`, `DEFLECT +50`) across the 16:10 tablet viewport. |

---

## 3. Gameplay Showcase Video Specifications

| Metric | Specification | Verification Result |
| :--- | :--- | :--- |
| **File Location** | [`docs/media/void_sower_gameplay_showcase.mp4`](file:///home/kelvingorekore/projects/void-sower/docs/media/void_sower_gameplay_showcase.mp4) | Accessible locally in workspace |
| **Duration** | `23.98 seconds` | Meets Google Play promo video threshold (< 30s) |
| **Resolution** | `720 x 1600 px` | 9:20 vertical portrait native ratio |
| **Video Codec** | H.264 (Baseline Profile / AVC1) | Universally supported across mobile and web |
| **Frame Rate** | `48.83 – 60.0 fps` progressive | Silky smooth animations |
| **Bitrate** | `4.82 Mbps` | High visual clarity without blocking artifacts |
| **Content Sequence** | 1. 3D lateral and depth maneuvers.<br>2. Capacitor sowing cascade and Namua core injection.<br>3. Corridor alignment and laser discharge (`SUPER CRIT +1600`).<br>4. Tactical pause overlay and real-time score display.<br>5. Instant sortie resumption without freeze.<br>6. Smooth navigation to Campaign Star Map. | Zero crashes, zero freezes, flawless UX |

---

## 4. Quality Audit Checklist

- [x] **No Test Ads:** Ad banners and test interstitial overlays have been verified absent during all captures.
- [x] **No Login Walls:** Screens showcase playable game modes without third-party auth popups.
- [x] **No Debug Banners:** `debugShowCheckedModeBanner: false` ensures zero Flutter debug banners in all media.
- [x] **High DPI Resolution:** Screenshots are 1344x2992 (exceeding standard 1080p requirements for crisp store display).
- [x] **Consistent Brand Palette:** Strict compliance with Void Theme (`#070C18` Obsidian, `#00E5FF` Cyan, `#FFD700` Gold, `#7C3AED` Amethyst).
- [x] **16 KB Page-Size Kernel Compatibility:** Engine operates smoothly on Android 16 KB kernel emulator.
