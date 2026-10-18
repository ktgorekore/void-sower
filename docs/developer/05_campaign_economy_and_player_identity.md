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

# Void Sower Developer Guide: Campaign Economy, Fleet Hangar & Player Identity

[◄ Developer Hub](README.md) | [01: Game Rules](01_game_rules_and_mechanics.md) | [02: ECS Engine](02_cpp_ecs_engine_architecture.md) | [03: FFI Bridge](03_dart_ffi_bridge_and_isolate_architecture.md) | [04: Presentation](04_presentation_shaders_and_audio_visual_pipeline.md) | [05: Campaign](05_campaign_economy_and_player_identity.md) | [06: Testing](06_apis_integration_and_testing_guide.md) | [07: Procedural Generation](07_procedural_generation_and_solvability_guarantees.md)

---

## 1. Campaign Progression & 3-Operation World Map Architecture

The campaign spans **27 sectors across 3 distinct orbital operations** (`9` sectors per operation), with every sector structured as a **3-Act Story Mission** (`Act I: Vanguard Recon` $\to$ `Act II: Tactical Siege + Relic Draft` $\to$ `Act III: Apex Command Boss`):

```
Operation 1: KILWA NEBULA BASIN (Sectors 1–9 · Standard Orbital Doctrine)
  [ Tier 1: Outer Bastions ] ──► [ Tier 2: Monsoon Straits ] ──► [ Tier 3: Core Siphon ]
   • S1 Zanzibar Reef Gate        • S4 Kaskazi Ion Stream         • S7 Kilwa Kisiwani Citadel
   • S2 Pemba Channel Relay       • S5 Kusi Vortex Outpost        • S8 Songo Mnara Flagship Berth
   • S3 Mafia Trench Fortress     • S6 Lindi Ridge Bastion        • S9 Great Siphon Singularity

Operation 2: PHANTOM DRIFT (Sectors 10–18 · Lateral Evasive Corridors)
   • S10 Aldabra Shimmer Rift .. S18 Agalega Singularity Zenith (Adaptive lateral-evading wings)

Operation 3: VOID SWARM (Sectors 19–27 · Horde Crucible & Core Siphon)
   • S19 Comoros Hive Gate .. S27 Mozambique Singularity Hive (Multi-wave hordes + Core Siphon)
```

### Sector Node Properties ([`lib/domain/models/campaign_sector.dart`](file:///home/kelvingorekore/projects/void-sower/lib/domain/models/campaign_sector.dart))
Each sector defines specific combat and narrative parameters:
- **`sectorId`**: 1-based sector identifier (`1..27`).
- **`name`** & **`region`**: Swahili Coast, Indian Ocean Atoll, or Mozambique Channel designation.
- **`difficultyTier`**: Integer $0$, $1$, or $2$ determining wave generator budgets and enemy vessel mix.
- **`doctrine`**: `standardOrbital`, `phantomDrift`, or `voidSwarm`.
- **`reinforcementQuota`**: Progressive reinforcement budget (`4..20`) driving the transition from **Act I (`vanguardRecon`)** $\to$ **Act II (`tacticalSiege` + 3-choice Relic Draft)** $\to$ **Act III (`apexBoss`)**.
- **`starsEarned`** & **`bestScore`**: High-water mark star performance ($0$ to $3$) and best recorded score.

### Star Performance Formula
```dart
int calculateStarsEarned({required int coresUsed, required int optimalMoves}) {
  if (coresUsed <= optimalMoves + 1) return 3;
  if (coresUsed <= optimalMoves + 3) return 2;
  return 1;
}
```

---

## 2. Orbital Fleet Hangar ([`lib/domain/services/fleet_service.dart`](file:///home/kelvingorekore/projects/void-sower/lib/domain/services/fleet_service.dart))

The Fleet Hangar enables pilots to unlock and equip dreadnought chassis variants tailored to different tactical combat styles:

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                       ORBITAL FLEET CHASSIS VARIANTS                        │
├──────────────────────────┬───────────────┬─────────────┬────────────────────┤
│ Chassis Class            │ Core Capacity │ Lance Alpha │ Tactical Role      │
├──────────────────────────┼───────────────┼─────────────┼────────────────────┤
│ **MK-I Bastion**         │ 32 Cores      │ 100% (Base) │ Balanced Starter   │
│ **MK-II Monsoon**        │ 36 Cores      │ 114% Alpha  │ Offensive Striker  │
│ **MK-III Singularity**   │ 40 Cores      │ 128% Alpha  │ Heavy Dreadnought  │
└──────────────────────────┴───────────────┴─────────────┴────────────────────┘
```

### Chassis Specializations
1. **MK-I Bastion Standard**:
   - Starting chassis available to all pilots upon enlistment.
   - Balanced baseline configuration with standard 16-bay capacitor rings and 32-core reactor capacity.
2. **MK-II Monsoon Vanguard**:
   - Enhanced Nyumba retention conduits amplifying quadratic lance discharges by $+14\%$.
   - Expanded reactor capacity (36 cores) facilitating deeper multi-lap cascade overloads.
3. **MK-III Singularity Sovereign**:
   - High-tier orbital flagship featuring massive 40-core capacitor reserves and $+28\%$ particle lance alpha.
   - Unlocked by achieving 15 total campaign stars across the Kilwa Nebula Basin.

---

## 3. Pilot Telemetry & GDPR-Compliant Local Privacy

Void Sower adheres to strict privacy-by-design standards. All pilot progression, telemetry statistics, and configuration settings are stored **locally on-device**:

### 3.1 Data Architecture ([`lib/domain/services/privacy_service.dart`](file:///home/kelvingorekore/projects/void-sower/lib/domain/services/privacy_service.dart))
- **No Cloud Tracking by Default**: Guest play does not require account creation, email entry, or persistent cloud syncing.
- **Local Progress Storage**: Game state is serialized to sandboxed application storage (`SharedPreferences` / encrypted key-value store).
- **Clean Uninstall Policy**: Configured with `android:allowBackup="false"` and `data_extraction_rules.xml` so local guest data is wiped cleanly upon application removal without ghost restorations from cloud backups.

### 3.2 Right to Data Portability & Erasure
The Pilot Telemetry Dashboard ([`StatsDashboardScreen`](file:///home/kelvingorekore/projects/void-sower/lib/presentation/screens/stats_dashboard_screen.dart)) provides explicit user-facing controls:
- **Export Flight Telemetry**: Generates a clean JSON dump containing all local sector scores, core counts, and play stats.
- **Wipe All Flight Records**: Invokes `PrivacyService.instance.eraseAllUserData()`, completely purging all local campaign records, unlocked ships, and high scores with immediate verification.

---

## 4. Monetization & In-App Economy

Void Sower maintains a transparent, player-first monetization model designed to satisfy Google Play Store Families and Core Game guidelines:

### 4.1 Pro Upgrade In-App Purchase ([`lib/domain/services/iap_service.dart`](file:///home/kelvingorekore/projects/void-sower/lib/domain/services/iap_service.dart))
- **Product ID**: `void_sower_pro_lifetime`
- **Price Point**: `$1.29 USD` (Tier 1 non-consumable)
- **Entitlements**:
  - Permanently removes all interstitial and banner advertisements (100% ad-free).
  - Unlocks Autonomous AI Tactical Solver & Autopilot powered by native C++ MCTS.
  - Unlocks Holographic Tactical Move Advisor (real-time glowing move hints).
  - Instantly unlocks the MK-III Singularity Sovereign flagship (+30% lance alpha, 40 cores) and exclusive MK-IV Golden Sovereign hull.
  - Unlocks Deep Sensor Telemetry (full multi-lap cascade spline trajectories and quadratic damage readouts).
  - Grants 3 Chrono-Anchor in-combat rewinds per sector.
  - Unlocks the Orbital Simulation Lab & Endless Skirmish arena.
  - Instant Emergency Reactor Flares (+8 cores) on demand with zero ads and zero cooldown.

### 4.2 Non-Intrusive Rewarded Transmissions ([`lib/domain/services/ad_service.dart`](file:///home/kelvingorekore/projects/void-sower/lib/domain/services/ad_service.dart))
- Free players can voluntarily opt into rewarded video ads for single-mission or single-use passes:
  - $+8\text{ Emergency Core Injection}$ during combat reactor depletion.
  - Tactical Overclock: 3 optimal AI solver moves.
  - Flagship Rental: 1 combat mission piloting the MK-III Singularity Sovereign.
  - Deep Scan: 1 combat mission with deep cascade telemetry.
  - Emergency Chrono-Rewind: 1 undo upon fatal reactor breach.
- Zero forced interstitial popups during active combat simulations.

📖 *See the complete breakdown and comparison matrix in [`docs/tier_definition_and_monetization.md`](../tier_definition_and_monetization.md).*

---

## 🧭 Navigation

| [◄ 04: Presentation & Shaders](04_presentation_shaders_and_audio_visual_pipeline.md) | [🏠 Developer Hub](README.md) | [Next: 06 APIs, Integration & Testing Guide ►](06_apis_integration_and_testing_guide.md) |
|:---:|:---:|:---:|
