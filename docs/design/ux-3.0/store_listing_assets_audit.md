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

### Screenshot Portfolio Overview

| # | Screen ID | Target File | Dimensions | Visual Subject & Audit Findings |
| :-: | :--- | :--- | :--- | :--- |
| **01** | **Combat Viewport (3D Depth)** | [`01_combat_tactical_depth.png`](file:///home/kelvingorekore/projects/void-sower/docs/media/store_screenshots/01_combat_tactical_depth.png) | `1344 x 2992` | Flagship dreadnought cruising into apogee horizon with concentric 3D depth rings (`+10km`, `+20km`, `+40km`), ground projection anchor ring, descending alien invaders, 16-bay capacitor matrix, and subtle universal tactical advisory bar (`TACTICAL AI SCANNING CORRIDORS... STANDBY`). |
| **02** | **Corridor Lock-on & Lance** | [`02_axial_particle_lance.png`](file:///home/kelvingorekore/projects/void-sower/docs/media/store_screenshots/02_axial_particle_lance.png) | `1344 x 2992` | Dreadnought locked onto corridor 5 (`[C5] VANGUARD +60% LANCE`), invader framed dead-center inside the targeting crosshairs, particle trails, and falling atmosphere cores (`-5 ATMOS PASS`). |
| **03** | **Orbital Command Deck** | [`03_orbital_command_campaign.png`](file:///home/kelvingorekore/projects/void-sower/docs/media/store_screenshots/03_orbital_command_campaign.png) | `1344 x 2992` | Clean, decluttered Campaign Star Map with spine progression, Sector 1 Zanzibar Reef Gate active, Tier 1–3 locked sectors, mode selector, and ergonomic bottom navigation. |
| **04** | **Fleet Hangar Inspection** | [`04_fleet_hangar_inspection.png`](file:///home/kelvingorekore/projects/void-sower/docs/media/store_screenshots/04_fleet_hangar_inspection.png) | `1344 x 2992` | Frosted glass inspection panel showcasing Vanguard Flagship stats (Core Capacity: 16, Lance Alpha: 60%, Hull Integrity: 100%), tactical perks, and active chassis selection. |
| **05** | **Tactical Directives Codex** | [`05_tactical_directives_codex.png`](file:///home/kelvingorekore/projects/void-sower/docs/media/store_screenshots/05_tactical_directives_codex.png) | `1344 x 2992` | 20-second combat rules interactive briefing displaying circular capacitor sowing animations, corridor targeting diagrams, flight academy, and quick engagement launch. |
| **06** | **Tactical Pause Menu** | [`06_tactical_pause_controls.png`](file:///home/kelvingorekore/projects/void-sower/docs/media/store_screenshots/06_tactical_pause_controls.png) | `1344 x 2992` | Translucent combat pause overlay featuring real-time sortie score, chrono-rewind, pro boost stacker, high-contrast action buttons (Restart, Resume, Abort), and quick utility icons. |

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
