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

## 1. Campaign Progression & World Map Architecture

The campaign is set across the planetary orbit of the **Kilwa Nebula Basin**. Players progress through a linear sequence of 6 tactical defense sectors divided into 3 threat tiers:

```
[ Tier 1: Outer Bastions ] ──► [ Tier 2: Monsoon Straits ] ──► [ Tier 3: Citadel Core ]
 • Zanzibar Reef Gate           • Kaskazi Ion Stream            • Kilwa Apex Citadel
 • Pemba Channel Relay          • Kusi Vortex Outpost           • Singularity Rift
 • Mafia Trench Fortress        • Lindi Ridge Bastion
```

### Sector Node Properties ([`lib/domain/models/campaign_sector.dart`](file:///home/kelvingorekore/projects/void-sower/lib/domain/models/campaign_sector.dart))
Each sector defines specific combat constraints:
- **`sectorId`**: Unique identifier string.
- **`name`**: Swahili coastal inspired designation (e.g. "Zanzibar Reef Gate").
- **`region`**: Theater of operations (Outer Bastions, Monsoon Straits, Citadel Core).
- **`difficultyTier`**: Integer $0$, $1$, or $2$ determining wave generator parameters.
- **`isUnlocked`**: Boolean progression flag.
- **`starsEarned`**: High-water mark star performance ($0$ to $3$).
- **`highScore`**: Best recorded score in this sector.

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
- **Price Point**: `$0.99` (Tier 1 non-consumable)
- **Entitlements**:
  - Permanently removes all interstitial and banner advertisements.
  - Instantly unlocks the MK-II Monsoon Vanguard and MK-III Singularity Sovereign chassis.
  - Grants unlimited simulation undos and tactical trajectory telemetry overlays.

### 4.2 Non-Intrusive Rewarded Energy Boosts ([`lib/domain/services/ad_service.dart`](file:///home/kelvingorekore/projects/void-sower/lib/domain/services/ad_service.dart))
- Players playing the free tier can voluntarily opt into rewarded video ads during combat defeat screens to receive a $+4\text{ Emergency Core Injection}$ without losing campaign progress.
- Zero forced interstitial popups during active combat simulations.

---

## 🧭 Navigation

| [◄ 04: Presentation & Shaders](04_presentation_shaders_and_audio_visual_pipeline.md) | [🏠 Developer Hub](README.md) | [Next: 06 APIs, Integration & Testing Guide ►](06_apis_integration_and_testing_guide.md) |
|:---:|:---:|:---:|
