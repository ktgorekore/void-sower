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

# Closed Beta Testing & Staged Production Rollout Plan

This document outlines the testing protocols, quality metrics, and staged rollout timeline for **Void Sower: Kinetic Mancala** (`com.voidsower.app`).

---

## 🧪 Phase 1: Closed Beta Testing Protocol (7-Day Window)

### Objectives
1. Validate gameplay balance, count-and-capture sowing mechanics, and player retention across diverse Android mobile hardware.
2. Verify Crashlytics telemetry stability and zero memory leak degradation over prolonged multi-sector combat sessions.
3. Validate interactive Flight Academy onboarding comprehension with novice players unfamiliar with traditional Bao la Kiswahili mechanics.
4. Stress-test Android 15 16 KB ELF memory page alignment and Impeller rendering performance on diverse GPU chipsets (Adreno, Mali, PowerVR).

### Target Cohort
- **Tester Count**: 100 – 500 opt-in community playtesters.
- **Device Diversity**: Android 7.0 (API 24) through Android 15 (API 35), including high-end 120 Hz flagships, budget devices (2 GB RAM), foldables, and tablets.

### Tester Incentives & Rewards: Lifetime Pro
- **Lifetime Pro Entitlement**: All verified early testers participating in the Closed Beta track receive permanent, lifetime access to **Void Sower PRO**.
- **Included Features**:
  - 100% ad-free experience.
  - Unlimited predictive lance trajectory telemetry on the Projection Shelf.
  - Exclusive MK-III Singularity Sovereign dreadnought chassis unlock.
  - Access to advanced mathematical MCTS analytics.
- **Strategic Purpose**: Accelerates tester recruitment, maximizes D1/D7 retention, incentivizes comprehensive bug reporting, and rewards early community champions.

### Key Performance Indicators (KPIs):
| Metric | Beta Target | Production Minimum |
| :--- | :--- | :--- |
| **Crash-Free User Rate** | $\ge 99.8\%$ | $\ge 99.5\%$ |
| **ANR (App Not Responding) Rate** | $< 0.05\%$ | $< 0.10\%$ |
| **Session Length (Median)** | $\ge 9.0\text{ minutes}$ | $\ge 7.0\text{ minutes}$ |
| **D1 Player Retention** | $\ge 45\%$ | $\ge 38\%$ |
| **D7 Player Retention** | $\ge 20\%$ | $\ge 16\%$ |
| **Pro Upgrade Conversion** | $3.0\% – 5.0\%$ | $\ge 2.5\%$ |

---

## 🚀 Phase 2: Staged Production Rollout Schedule

Upon successful completion of Closed Beta testing and validation of all KPI thresholds, the production rollout is executed through Google Play Console staged releases:

```
[Day 1: 10%] ───(12-hr canary monitoring)───► [Day 3: 25%]
                                                     │
                                            (Crashlytics check)
                                                     │
[Day 7: 100% Full Global Release] ◄── [Day 5: 50%] ◄─┘
```

### Staged Rollout Timeline:

1. **Day 1 — 10% Initial Staged Rollout**:
   - Promote build from Closed Beta to Production Track at 10% staged release.
   - Monitor real-time Crashlytics telemetry and Google Play vitals during initial 12-hour window.
   - Halt rollout immediately if crash-free user rate drops below $99.0\%$.

2. **Day 3 — 25% Expanded Rollout**:
   - Review early store ratings and comments regarding tutorial clarity and controls.
   - Verify zero IAP fulfillment failures or restore purchases exceptions.

3. **Day 5 — 50% Half-Fleet Rollout**:
   - Broaden distribution across primary launch territories (North America, East Africa, West Africa, Europe).
   - Evaluate server load on leaderboard and cloud save endpoints.

4. **Day 7 — 100% Full Global Production Rollout**:
   - Complete 100% rollout to all Google Play users worldwide.
   - Celebrate global launch of Void Sower: Kinetic Mancala! 🚀

---

## 🚨 Incident Response & Rollback Runbook

### Rollback / Hotfix Triggers:
1. **Critical Native Crash**: Any reproducible SIGSEGV, memory violation, or FFI crash affecting $> 0.2\%$ of users.
2. **IAP Entitlement Loss**: Failure to grant Pro tier upon successful Google Play Billing transaction.
3. **Data Loss**: Corruption or wiping of player campaign progression or unlocked chassis.

### Emergency Procedures:
1. **Halt Rollout**: Immediately pause staged rollout in Google Play Console to prevent further installs of the affected version.
2. **Reproduce & Isolate**: Pinpoint the regression using Crashlytics symbolicated stack traces and deterministic game seed logs.
3. **Hotfix Release**: Increment `versionCode` and `versionName` in `pubspec.yaml` (e.g., `1.0.1`), apply fix, run `./scripts/build_release_bundle.sh`, and deploy emergency hotfix directly to 100% production.
