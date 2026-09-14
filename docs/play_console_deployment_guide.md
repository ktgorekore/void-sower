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

# Google Play Console Deployment & Pre-Launch Validation Guide

This document defines the deployment instructions, Store Gate 7 🚦 checklist, and verification protocols for publishing **Void Sower: Kinetic Mancala** (`com.voidsower.app`) on the Google Play Store.

---

## 🛠️ Step 1: Release Build Generation

### Method A: Automated GitHub Actions Release Pipeline (Recommended)

Every tagged release (`v*`) automatically triggers the continuous release workflow:

1. **Tag and Push to GitHub**:
   ```bash
   git tag -a v1.0.0 -m "Release v1.0.0 - Production Release Candidate"
   git push origin main --tags
   ```
2. **Automated Pipeline Execution**:
   * Runs the C++ GTest suite, 16 KB ELF memory page alignment verification, and Flutter test suites.
   * Compiles the optimized Android App Bundle (`void-sower-v1.0.0.aab`) with Dart code obfuscation.
   * Audits 16 KB page size alignment across all native shared libraries (`libvoid_sower.so`).
   * Packages Dart debug symbol maps (`void-sower-symbols-v1.0.0.zip`).
   * Publishes a GitHub Release under **Releases** with downloadable `.aab` artifacts and SHA-256 checksums.
3. **Upload Keystore Generation & Repository Secrets**:
   If you have not yet created an upload keystore, generate one using `keytool`:
   ```bash
   keytool -genkeypair -v \
     -keystore android/app/upload-keystore.jks \
     -keyalg RSA \
     -keysize 2048 \
     -validity 10000 \
     -alias upload
   ```
   > [!IMPORTANT]
   > Keep `upload-keystore.jks` and your passwords safe. Keystores are strictly git-ignored (`.gitignore`) and must **never** be committed to version control.

   Next, configure the following secrets under **Repository Settings > Secrets and variables > Actions**:
   * `ANDROID_KEYSTORE_BASE64`: Base64-encoded release keystore string:
     ```bash
     base64 -w 0 android/app/upload-keystore.jks
     ```
   * `ANDROID_KEY_ALIAS`: Keystore key alias (e.g., `upload`)
   * `ANDROID_KEY_PASSWORD`: Keystore key password
   * `ANDROID_STORE_PASSWORD`: Keystore store password

---

### Method B: Local Build Pipeline

Execute the local automated build and audit pipeline:

```bash
./scripts/build_release_bundle.sh
```

This generates:
- **Android App Bundle**: `build/app/outputs/bundle/release/app-release.aab`
- **Native Debug Symbols**: `BUNDLE-METADATA/com.android.tools.build.debugsymbols/`
- **Dart Obfuscation Symbol Map**: `build/app/outputs/symbols/`
- **Verification Metrics**: Confirms 16 KB page alignment and user download payload size $< 25\text{ MB}$.

---

## 🚀 Step 2: Internal Testing Track Deployment

1. Navigate to [Google Play Console](https://play.google.com/console) > **Release** > **Testing** > **Internal testing**.
2. Click **Create new release**.
3. Upload `app-release.aab`.
4. Upload Dart obfuscation mapping files from `build/app/outputs/symbols/` to enable Crashlytics symbolicated stack traces.
5. In **Release notes**, provide release highlights:
   ```text
   Initial production release of Void Sower: Kinetic Mancala featuring the 16-bay dreadnought capacitor ring, 7-sector Kilwa Nebula campaign, interactive Flight Academy onboarding, and Afrofuturist audiovisual styling.
   ```
6. Save and click **Review release** > **Start rollout to Internal testing**.

---

## 🔍 Step 3: Pre-Launch Report (Firebase Test Lab) Verification

Google Play automatically runs an automated robotic crawler test across a diverse matrix of physical Android devices (phones, tablets, and foldables) for ~1 hour after upload.

### Critical Pass/Fail Criteria:
| Metric | Threshold Requirement | Validation Status |
| :--- | :--- | :--- |
| **Native C++ Crashes** | Exactly **0** crashes | MUST PASS |
| **Dart Unhandled Exceptions** | Exactly **0** exceptions | MUST PASS |
| **ANRs (App Not Responding)** | Exactly **0** ANRs | MUST PASS |
| **16 KB Memory Page Alignment** | 100% compliant across ARM64, ARMv7, x86_64 | MUST PASS (121/121 verified) |
| **RAM Memory Footprint** | Peak memory $\le 150\text{ MB}$ baseline | MUST PASS |
| **Frame Rate** | $\ge 60\text{ FPS}$ standard, $120\text{ FPS}$ on high-refresh displays | MUST PASS |
| **Accessibility Touch Targets** | All interactive buttons $\ge 48 \times 48\text{ dp}$ | MUST PASS |
| **Color Contrast Ratio** | $\ge 4.5:1$ text-to-background contrast | MUST PASS |

---

## 💳 Step 4: In-App Product (IAP) Provisioning

1. Navigate to **Monetize** > **Products** > **In-app products**.
2. Click **Create product**.
3. Configure the Pro Upgrade:
   - **Product ID**: `void_sower_pro_lifetime`
   - **Name**: `Void Sower Pro Lifetime`
   - **Description**: `Unlock 100% Ad-Free combat, unlimited predictive lance trajectory telemetry, and exclusive MK-III Sovereign chassis variant.`
   - **Status**: `Active`
   - **Default Price**: `$0.99 USD` (with automated localized price conversion enabled across all Google Play billing currencies).
4. Save and activate product.

---

## 🎮 Step 5: Play Games Services & Cloud Save Configuration

1. Navigate to **Grow** > **Play Games Services** > **Setup and management** > **Configuration**.
2. Link the Android application `com.voidsower.app` with OAuth 2.0 Client credentials.
3. Configure Leaderboards:
   - `leaderboard_galactic_high_score`: Galactic High Score
   - `leaderboard_deepest_cascade`: Deepest Cascade Relay
   - `leaderboard_liberated_sectors`: Total Star Sectors Liberated
4. Configure Achievements:
   - `ach_first_core_sown`: First Core Sown (Complete initial namua injection)
   - `ach_quadratic_overload`: Critical Discharge (Deliver $\ge 1,000$ quadratic lance damage)
   - `ach_kilwa_liberator`: Kilwa Basin Victor (Liberate all 7 campaign sectors)
   - `ach_perfect_cadence`: Harmonic Cascade (Trigger 5-lap sowing cascade in a single turn)
5. Enable **Saved Games** (Cloud Save) snapshots API for cross-device campaign save states.

---

## 📄 Step 6: Store Listing & Content Declarations

Upload the marketing and metadata deliverables from [`store_listing/google_play_metadata.md`](file:///home/kelvingorekore/projects/void-sower/store_listing/google_play_metadata.md):
1. **App Title & Descriptions**: Copy localized translations for `en`, `sw`, `yo`, `fr`, `es`.
2. **App Icon**: Upload $512 \times 512\text{ PNG}$ high-resolution adaptive icon.
3. **Feature Graphic**: Upload $1024 \times 500\text{ PNG}$ banner featuring Void Sower branding.
4. **App Content Questionnaire**:
   - Complete IARC questionnaire (Result: ESRB Everyone 10+ / PEGI 7 for fantasy sci-fi combat).
   - Complete Data Safety form:
     - Declare Crashlytics diagnostic telemetry.
     - Declare optional anonymous Analytics.
     - Declare AdMob ad identifier usage.
     - State that all data in transit is encrypted via HTTPS/TLS.
     - State that players can request account/profile deletion directly within the in-app settings screen (GDPR compliance).
   - Target Age: Age 13 and older.
