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

# Void Sower Engineering Roadmap & Google Play Store Deployment Plan

This document serves as the master execution roadmap for **Void Sower: Bao Orbital Batteries**, detailing architectural milestones, implemented game features, quality verification criteria, and the step-by-step production path for launching on the **Google Play Store**.

---

## 🚦 Status Legend

* `[ ]` **Pending**: Planned task not yet initiated.
* `[/]` **In Progress**: Active development undergoing implementation or code review.
* `[x]` **Completed**: Fully implemented, verified with comprehensive tests, and committed to git.

---

## 🏆 Completed Milestones & Architectural Highlights

- **Core Toolchain & Architecture Foundation (Phase 0)**: Initialized Flutter 3.x / Dart FFI standalone application targeting Android 15 (API 35, minSdk 24). Integrated CMake via Android Gradle `externalNativeBuild` with EnTT v3.13.2 ECS and Abseil C++ via `FetchContent`. Enforced universal 16 KB Android page alignment (`-Wl,-z,max-page-size=16384`), compiler security hardening flags (`-fstack-protector-strong`, `-D_FORTIFY_SOURCE=2`), classic `#ifndef VOID_SOWER_...` header guards, C++17 single-line nested namespaces (`namespace void_sower::ecs`), and verbatim Apache 2.0 license headers across all codebases.
- **Cognitas-Pattern High-Performance Ring Buffer (Phase 1)**: Integrated power-of-two ($N = 16 = 2^4$) circular buffer utilizing single-cycle bitwise masking (`& 0x0F`) and 64-byte cache-line alignment (`alignas(64)`), eliminating slow modulo division and false sharing on the 60 Hz simulation hot path.

---

## 🏛️ Phase 0: Repository Scaffolding, Native Build System & Android Toolchain (Completed ✅)

- [x] **Task 0.1: Project Scaffolding & Flutter Initialization**
  - [x] Initialize standalone Flutter application targeting Android mobile-first (`com.voidsower.app`).
  - [x] Configure `pubspec.yaml` with `ffi`, `audioplayers`, `shared_preferences`, and `ffigen`.
  - [x] Port `scripts/verify_16kb_alignment.sh` for automated ELF page size verification.
- [x] **Task 0.2: Native C++17 CMake Infrastructure & Android Gradle Integration**
  - [x] Configure `android/app/build.gradle.kts` with `externalNativeBuild` pointing to `src/CMakeLists.txt`.
  - [x] Configure NDK ABI filters: `arm64-v8a`, `armeabi-v7a`, `x86_64`.
  - [x] Integrate header-only EnTT v3.13.2 and Abseil C++ via CMake `FetchContent`.
  - [x] Apply `-Wl,-z,max-page-size=16384` for Android 15 16 KB page size compliance.
  - [x] Configure compiler security flags: `-fstack-protector-strong`, `-D_FORTIFY_SOURCE=2`, `-Wall`, `-Wextra`.
- [x] **Task 0.3: Contributor Guidelines & Engineering Standards**
  - [x] Author comprehensive `AGENTS.md` synthesizing rules from `cognitas-trading`, `oware-2048`, and `hotpathcpp`.
  - [x] Enforce verbatim Apache 2.0 headers, classic header guards, and C++17 single-line nested namespaces.
  - [x] Configure git remote `git@github.com:ktgorekore/void-sower.git`.

---

## ⚡ Phase 1: High-Performance Ring Buffer & C++17 EnTT ECS Simulation Core (In Progress [/])

- [x] **Task 1.1: Data-Oriented POD Components & Cache Alignment**
  - [x] Define `BatteryComponent` in `src/ecs/components.h` for the 16 capacitor bays.
  - [x] Define `SowingStateComponent` tracking traversal head, remaining units, direction, and cascade depth.
  - [x] Define `EnemyVesselComponent` with shields, hull, velocity, and corridor assignment.
  - [x] Define `ParticleLanceComponent` and `FlakBurstComponent` for combat discharges.
  - [x] Define `DreadnoughtStateComponent` and `SpatialGridBucket`.
- [x] **Task 1.2: Cognitas-Pattern Power-of-Two Ring Buffer System**
  - [x] Implement branchless bitwise masking arithmetic in `src/ecs/systems/ring_buffer.h`:
    $$\text{index} = (\text{current} + \text{direction} + 16) \ \& \ 0\text{x}0\text{F}$$
  - [x] Implement constant-time multi-step trajectory evaluator `StepBayMulti()`.
  - [x] Implement special bay rule handlers:
    - *Nyumba* (Bays 3 & 4): House super-capacitors with retention rules.
    - *Kichwa* (Bays 8 & 15): Head vector conduits allowing angular momentum reversals.
    - *Kimbi* (Bays 9 & 14): Flank deflection chambers inverting flak vectors.
- [x] **Task 1.3: 2D Uniform Spatial Grid System**
  - [x] Implement `SpatialGrid` in `src/ecs/systems/spatial_grid.h` and `src/ecs/systems/spatial_grid.cpp`.
  - [x] 8 corridor buckets pre-allocated in static memory, eliminating runtime heap allocations.
  - [x] $O(1)$ spatial registration and $O(N)$ corridor raycast culling.
- [x] **Task 1.4: Deterministic 60 Hz Combat System & FSM**
  - [x] Implement `CombatSystem` in `src/ecs/systems/combat_system.h` and `combat_system.cpp`.
  - [x] 9-state simulation FSM: `OrbitalIdle`, `CoreInjection`, `SowingTraversal`, `EvaluateDestination`, `CrossDischarge`, `RelayOverload`, `CleanupCheck`, `Victory`, `GameOver`.
  - [x] Quadratic lance damage formula: $D(M) = \alpha \cdot M^2$.
  - [x] Flak burst area damage formula: $D_{\text{flak}} = \beta \cdot \sqrt{M'}$.
  - [x] Automatic relay overloading with intermediate flak trail venting.
  - [x] Instantaneous dry-run predictive targeting telemetry `PredictSow()`.
- [x] **Task 1.5: High-Level Engine Orchestrator**
  - [x] Implement `Engine` in `src/ecs/engine.h` and `src/ecs/engine.cpp` coordinating EnTT registry, combat system, and wave generator.
- [x] **Task 1.6: Native Google Test Suite Execution**
  - [x] Implement `src/tests/ring_buffer_test.cpp` verifying bitwise masking, boundary wrapping, and special bays.
  - [x] Implement `src/tests/combat_simulation_test.cpp` verifying damage formulas and mass conservation.
  - [x] Implement `src/tests/spatial_grid_test.cpp` verifying corridor raycasts.
  - [x] Verify 100% CTest pass rate.

---

## 🌉 Phase 2: High-Performance Flat C ABI & Dart FFI Zero-Copy Bridge (Completed ✅)

- [x] **Task 2.1: Flat C ABI Interface Definitions**
  - [x] Author `src/void_sower.h` exposing flat `extern "C"` functions and packed POD exchange structs.
- [x] **Task 2.2: Thread-Safe C ABI Implementation & Span Bounds Checking**
  - [x] Implement `src/void_sower.cpp` wrapping all C endpoints in `std::shared_mutex` (shared reader vs. exclusive writer).
  - [x] Wrap incoming memory pointers in `absl::Span` bounds checkers.
- [x] **Task 2.3: Automated FFI Bindings Synthesis via `ffigen`**
  - [x] Author `ffigen.yaml` targeting `src/void_sower.h`.
  - [x] Synthesize type-safe Dart bindings in `lib/engine/void_sower_bindings_generated.dart`.
- [x] **Task 2.4: Zero-Copy Pointer Caching in Dart `FfiVoidSowerEngine`**
  - [x] Pre-allocate fixed native struct pointers (`calloc`) once upon engine initialization in `lib/engine/ffi_void_sower_engine.dart`.
  - [x] Reuse native pointers for per-frame polling, eliminating Dart GC churn.
- [x] **Task 2.5: Mock Engine & Background Isolate Runner**
  - [x] Implement `MockVoidSowerEngine` in `lib/engine/mock_void_sower_engine.dart` for deterministic Flutter widget tests.
  - [x] Implement `IsolateRunner` in `lib/engine/isolate_runner.dart` for executing heavy procedural generation and solvers on background isolates.

---

## 🌌 Phase 3: Procedural Wave Generation & Solvability Guarantees (Program Inversion + MCTS) (Completed ✅)

- [x] **Task 3.1: Backward-Play Program Inversion Algorithm**
  - [x] Implement `WaveGenerator` in `src/ecs/systems/wave_generator.h` and `wave_generator.cpp`.
  - [x] Terminal victory state initialization -> inverse cross-discharge -> inverse sow (gathering) -> inverse injection (un-namua).
  - [x] Controlled entropy placement (drone screens, shield variances).
- [x] **Task 3.2: Monte Carlo Tree Search (MCTS) Solvability Evaluator**
  - [x] Implement UCT-based MCTS agent in C++ exploring decision state tree.
  - [x] Quantify encounter difficulty through MCTS convergence complexity:
    - Tier 1 (Sector Patrol): Rapid convergence, forgiving margins.
    - Tier 2 (Planetary Siege): Moderate convergence, tight alignment windows.
    - Tier 3 (Flagship Bastion): High convergence complexity, complex multi-lap cascades.
- [x] **Task 3.3: Solvability Invariant Verification Suite**
  - [x] Author `src/tests/wave_generator_test.cpp` verifying that every generated wave has $\ge 1$ forward clearing path within core budget.

---

## 🎮 Phase 4: Ergonomic One-Thumb Mobile Viewport & Gesture Controls (Portrait Mode) (Completed ✅)

- [x] **Task 4.1: Three-Tier Ergonomic Viewport Architecture**
  - [x] Implement `CombatScreen` in `lib/presentation/screens/combat_screen.dart`.
  - [x] Upper 60%: Tactical Combat Corridor (unobstructed non-interactive combat zone).
  - [x] Middle 10%: Dynamic Projection Shelf (projected targeting reticles, $\alpha \cdot M^2$ damage readouts).
  - [x] Lower 30%: Primary Thumb Command Arc (16 capacitor bays, central reactor hub, lateral slider).
- [x] **Task 4.2: One-Thumb Gesture Input Engine**
  - [x] Implement `CommandArcWidget` in `lib/presentation/widgets/command_arc_widget.dart`.
  - [x] Horizontal thumb slider: Smoothly pan dreadnought along orbital horizon with critically damped spring interpolation.
  - [x] Radial bay tap & swipe: Sowing direction selection (sweep left = CCW -1, sweep right = CW +1) with illuminated vector paths.
  - [x] Upward flick: Core injection (*namua*) from central reactor into target bay.
  - [x] Thumb hold: Instantaneous dry-run predictive targeting telemetry via FFI.
- [x] **Task 4.3: Adaptive Layout Engine across Form Factors**
  - [x] Responsive layout engine supporting compact phones ($9:19.5$), tall phones ($9:21$), foldables ($1:1$), and tablets ($16:10$).
  - [x] Eliminate `RenderFlex` overflows with `LayoutBuilder` and `SafeArea`.

---

## 🎨 Phase 5: Visual Juice, Custom GLSL Shaders & Particle Burst Engine (Completed ✅)

- [x] **Task 5.1: Custom GLSL Fragment Shaders**
  - [x] Author `shaders/particle_lance.frag`: Axial particle lance with dynamic width, heat bloom, and electromagnetic noise.
  - [x] Author `shaders/flak_burst.frag`: Expanding radial shockwave with chromatic aberration.
  - [x] Author `shaders/plasma_capacitor.frag`: Pulsing plasma charge reflecting accumulated mass ($M$).
  - [x] Author `shaders/atmospheric_siphon.frag`: Scrolling energetic planetary horizon.
- [x] **Task 5.2: Viewport CustomPainter & Repaint Isolation**
  - [x] Implement `CombatPainter` in `lib/presentation/widgets/combat_painter.dart`.
  - [x] Wrap background nebula/starfield in `RepaintBoundary` to isolate high-frequency combat redraws.
- [x] **Task 5.3: Bounded Dynamic Particle Burst Engine**
  - [x] Implement `ParticleService` in `lib/presentation/services/particle_service.dart` with object pooling (`kMaxActiveParticles = 300`).
  - [x] Tiered particle explosions for flak bursts, shield breaks, and flagship destruction.
- [x] **Task 5.4: Zero-Idle Power Optimization**
  - [x] Condition frame tickers to pause when the game is idle with zero active particles (0 FPS idle draw).

---

## 🔊 Phase 6: Low-Latency SoundPool Audio System & Synchronized Haptics Pipeline (Completed ✅)

- [x] **Task 6.1: Low-Latency SoundPool Audio Player Pooling**
  - [x] Implement `AudioService` in `lib/presentation/services/audio_service.dart` with SoundPool player pooling.
  - [x] Pre-warm and pre-prime audio buffers on app startup using uncompressed WAV assets (`assets/audio/*.wav`).
  - [x] Harmonic pitch-ramping audio synthesis for multi-lap cascade relays.
- [x] **Task 6.2: Synchronized Tactile Haptics Engine**
  - [x] Implement `HapticService` in `lib/presentation/services/haptic_service.dart`.
  - [x] High-frequency micro-ticks ($15\text{ ms}$ at $30\text{ Hz}$) tracing the circular cadence of the sowing traversal.
  - [x] Heavy resonant transient ($80\text{ ms}$) upon firing a high-mass particle lance cross-discharge.
  - [x] Battery-saving haptics toggle in Settings.

---

## 🗺️ Phase 7: Kilwa Nebula Campaign Metagame, Star Map & Player Identity (Completed ✅)

- [x] **Task 7.1: Kilwa Nebula Basin Interactive Star Map**
  - [x] Implement `CampaignMapScreen` in `lib/presentation/screens/campaign_map_screen.dart`.
  - [x] Three progressive sector regions: Outer Bastions (Tier 1), Monsoon Straits (Tier 2), Core Siphon (Tier 3).
  - [x] 3-Star sector efficiency rating based on plasma core conservation and wave clearance speed.
- [x] **Task 7.2: Fleet Upgrades & Dreadnought Schematics**
  - [x] Implement `FleetService` in `lib/domain/services/fleet_service.dart`.
  - [x] Unlockable chassis variants for asymmetric sowing configurations.
  - [x] Specialized seed isotopes (Graviton Seeds pulling adjacent craft into lance line).
- [x] **Task 7.3: Player Profile & Statistics Dashboard**
  - [x] Implement `StatsDashboardScreen` in `lib/presentation/screens/stats_dashboard_screen.dart`.
  - [x] Lifetime telemetry: sectors liberated, total plasma sown, maximum cascade depth, quadratic damage delivered.
  - [x] Device persistence via `SharedPreferences` with anonymous guest auto-provisioning.

---

## 🛡️ Phase 8: Privacy Compliance, UMP Consent & Legal Readiness (Store Gate 1 🚦) (Completed ✅)

- [x] **Task 8.1: Google User Messaging Platform (UMP SDK) Integration**
  - [x] Implement `PrivacyService` in `lib/domain/services/privacy_service.dart`.
  - [x] Manage consent states (`unknown`, `required`, `obtained`, `notRequired`, `denied`).
  - [x] Gate all ad requests strictly on `canRequestAds` approval.
  - [x] Configure `setTagForUnderAgeOfConsent` (TFUA) and COPPA compliance.
  - [x] In-app "Consent Preferences" modal in Settings.
- [x] **Task 8.2: Legal Documentation & Terms Hosting**
  - [x] Authored `docs/privacy_policy.md` and `docs/terms_of_service.md` with Apache 2.0 headers.
  - [x] In-app clickable dialog viewers.
- [x] **Task 8.3: Clean Uninstall & Data Hygiene (Disable Android Auto-Backup)**
  - [x] Configure `android:allowBackup="false"` in `AndroidManifest.xml`.
  - [x] Author `data_extraction_rules.xml` blocking cloud auto-backup of guest progress.
  - [x] GDPR/CCPA User Data Erasure ("Right to Be Forgotten") confirmation dialog in Settings.

---

## 💰 Phase 9: Production Monetization: Rewarded Ads & Pro In-App Purchase (Store Gate 2 🚦) (Completed ✅)

- [x] **Task 9.1: Google Mobile Ads (AdMob) Production Integration**
  - [x] Implement `AdService` in `lib/presentation/services/ad_service.dart`.
  - [x] Rewarded Interstitial units offered strictly at natural pauses (sector completion, emergency retreat).
  - [x] Smart frequency capping (minimum 3-minute cooldown) and offline fallback.
- [x] **Task 9.2: Google Play In-App Purchase (Play Billing Library v7)**
  - [x] Implement `IapService` in `lib/domain/services/iap_service.dart` managing non-consumable SKU `void_sower_pro_lifetime` ($0.99).
  - [x] Lifetime Pro unlock benefits: 100% ad-free, unlimited predictive telemetry, exclusive golden chassis skin, advanced MCTS analytics.
  - [x] Mandatory `completePurchase` transaction acknowledgment to prevent automatic refunds.
  - [x] In-app "Restore Purchases" flow.

---

## 📊 Phase 10: Telemetry, Crashlytics & Native NDK Symbolication (Store Gate 3 🚦) (Completed ✅)

- [x] **Task 10.1: Dual-Analytics Pipeline Integration**
  - [x] Implement `AnalyticsService` in `lib/domain/services/analytics_service.dart` with `IAnalyticsSink`.
  - [x] Log lifecycle telemetry: `sector_started`, `sector_completed`, `lance_fired`, `cascade_triggered`, `pro_purchased`.
- [x] **Task 10.2: Firebase Crashlytics & Native NDK Crash Symbolication**
  - [x] Implement `CrashReportingService` with circular breadcrumb buffer.
  - [x] Configure `ndk.debugSymbolLevel = "FULL"` in `android/app/build.gradle.kts` for automated C++ stack trace symbolication in Google Play Console.
- [x] **Task 10.3: Google Play In-App Review & In-App Update APIs**
  - [x] Rate-limited in-app review prompts triggered after liberating major star sectors.
  - [x] Flexible in-app update checks for hotfix patches.

---

## 🌐 Phase 11: Internationalization (i18n), Accessibility (a11y) & Store Assets (Store Gate 4 & 5 🚦) (Completed ✅)

- [x] **Task 11.1: Multi-Language Localization (i18n)**
  - [x] Configure ARB files in `lib/l10n/` (`app_en.arb`, `app_sw.arb`, `app_yo.arb`, `app_fr.arb`, `app_es.arb`).
  - [x] High-quality localized translations honoring cultural roots (Swahili & Yoruba).
  - [x] In-app language selector override in Settings.
- [x] **Task 11.2: Accessibility (a11y) & Screen Reader Semantics**
  - [x] Wrap interactive capacitor bays and HUD gauges in Flutter `Semantics` widgets.
  - [x] Enforce $\ge 48 \times 48\text{ dp}$ touch bounds across all interactive controls.
  - [x] High-contrast reticle mode and colorblind-assist geometric glyphs for shield frequencies.
- [x] **Task 11.3: Google Play Store Visual Assets & Marketing Deliverables**
  - [x] High-resolution adaptive launcher icon ($512 \times 512\text{ PNG}$).
  - [x] Google Play Feature Graphic ($1024 \times 500\text{ PNG}$) with prominent Void Sower branding.
  - [x] Localized phone ($1080 \times 2400$) and tablet ($1600 \times 2560$) screenshots.
  - [x] Store listing metadata (Title under 30 chars, short description under 80 chars, keyword-optimized full description).

---

## 📦 Phase 12: Build Engineering, Security Hardening & Play Console Deployment (Store Gate 6 & 7 🚦)

- [x] **Task 12.0: Continuous Integration & Automated GitHub Release Pipelines**
  - [x] Author `.github/workflows/ci.yml`: Automated quality gate (Google C++ style, GTests, 16 KB page alignment, flutter analyze, flutter test).
  - [x] Author `.github/workflows/release.yml`: Tag/dispatch release pipeline with keystore secret decoding / debug fallback, optimized AAB build with obfuscation & split debug info, 16 KB audit, artifact packaging, SHA-256 calculation, and GitHub Release publication.
  - [x] Author `scripts/verify_format.py`: Staged and repository-wide (`--all`) C++ and Dart format auditing.
  - [x] Author `scripts/build_release_bundle.sh`: Local reproducible release bundle builder with symbol splitting and size validation (< 25 MB).
- [x] **Task 12.1: ProGuard / R8 Minification & FFI Symbol Preservation**
  - [x] Author release `android/app/proguard-rules.pro` preserving `extern "C" void_sower_*` symbols, EnTT types, and plugin registrants.
  - [ ] Verify release AAB download size is strictly under 25 MB.
- [ ] **Task 12.2: Cross-Platform 16 KB Page Alignment Audit**
  - [ ] Build release native shared libraries (`libvoid_sower.so`) for `arm64-v8a`, `armeabi-v7a`, `x86_64`.
  - [x] Run `scripts/verify_16kb_alignment.sh` verifying 100% compliance with $0\times 4000$ (16 KB) alignment.
- [ ] **Task 12.3: Production Android Keystore & Release AAB Signing**
  - [x] Configure `android/key.properties` and release signing in `build.gradle.kts`.
  - [x] Author signed release bundle pipeline using `scripts/build_release_bundle.sh`.
- [ ] **Task 12.4: Internal Testing Track & Closed Beta Rollout**
  - [ ] Upload signed `.aab` to Google Play Console Internal Testing track.
  - [ ] Inspect Google Play Pre-Launch Report (0 native crashes, 0 ANRs, < 150 MB baseline RAM).
  - [ ] Promote to Closed Beta track for 7-day community playtest.
- [ ] **Task 12.5: Staged Production Rollout**
  - [ ] Staged production deployment: Day 1 (10%) -> Day 3 (25%) -> Day 5 (50%) -> Day 7 (100% global release).
  - [ ] Live operations monitoring with Crashlytics crash-free users $> 99.5\%$.
