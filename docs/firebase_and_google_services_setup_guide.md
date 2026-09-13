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

# Firebase & Google Services Setup and Provisioning Guide

This guide details the complete protocol for provisioning, configuring, and linking Google Firebase and Google Cloud services for **Void Sower: Kinetic Mancala** (`com.voidsower.app`).

---

## 📋 Overview of Integrated Services

| Service | Purpose in Void Sower | Integration Point |
| :--- | :--- | :--- |
| **Firebase Crashlytics** | Real-time C++ NDK SIGSEGV / Dart unhandled exception monitoring | `android/app/build.gradle.kts`, `CrashReportingService` |
| **Google Analytics for Games** | Player progression, sector completion, and cascade depth telemetry | `AnalyticsService` |
| **Cloud Firestore** | Cross-device player profile sync, high scores, and achievement states | `StatsDashboardScreen` |
| **Google Mobile Ads (AdMob)** | COPPA-compliant Rewarded Interstitial units at sector completion | `AdService` |
| **Google Play Billing** | One-time non-consumable `$0.99` Pro Upgrade (`void_sower_pro_lifetime`) | `IapService` |
| **Google Play Games Services** | Cloud Save snapshots, global leaderboards, and achievement badges | `FleetService`, `CampaignService` |

---

## 🛠️ Step 1: Create Firebase Project

### Method A: Via Firebase CLI (Recommended)

1. Ensure the Firebase CLI is installed and authenticated:
   ```bash
   npx -y firebase-tools@latest login
   ```
2. Create the production Firebase project:
   ```bash
   npx -y firebase-tools@latest projects:create void-sower-prod --title "Void Sower Production"
   ```
3. Set the active project:
   ```bash
   npx -y firebase-tools@latest use void-sower-prod
   ```

### Method B: Via Firebase Web Console

1. Navigate to the [Firebase Console](https://console.firebase.google.com/).
2. Click **Add project** (or **Create a project**).
3. Project Name: `Void Sower` (Project ID: `void-sower-prod` or `void-sower-app`).
4. **Google Analytics**: Enable Google Analytics for this project.
5. Select or create a Google Analytics account (e.g., `Void Sower Analytics`). Configure location and currency (`USD`).
6. Click **Create project**.

---

## 📱 Step 2: Register Android Application

1. In the Firebase Project Overview, click the **Android** icon (`+ Add app`).
2. Enter Android package configuration:
   - **Android package name**: `com.voidsower.app` (must match `applicationId` in `android/app/build.gradle.kts`).
   - **App nickname**: `Void Sower (Android Release)`
   - **Debug signing certificate SHA-1**: (See Step 3 below).
3. Click **Register app**.

---

## 🔑 Step 3: Extract and Register Keystore Fingerprints

Firebase Authentication, Google Sign-In, and Google Play Integrity require registering both SHA-1 and SHA-256 certificate fingerprints.

### 1. Debug Keystore Fingerprints
Run the following command to retrieve the local debug keystore fingerprints:
```bash
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
```
Extract:
- **SHA-1** (e.g., `AA:BB:CC:...`)
- **SHA-256** (e.g., `11:22:33:...`)

### 2. Release Keystore Fingerprints
If using a production upload keystore (`android/app/upload-keystore.jks` or as specified in `android/key.properties`):
```bash
keytool -list -v -keystore android/app/upload-keystore.jks -alias upload -storepass <STORE_PASSWORD>
```
Extract:
- **SHA-1**
- **SHA-256**

### 3. Google Play App Signing Fingerprint (Production)
Once the first `.aab` is uploaded to the Google Play Console:
1. Navigate to **Google Play Console** > **Setup** > **App integrity** > **App signing**.
2. Copy the **SHA-1 certificate fingerprint** and **SHA-256 certificate fingerprint** of the **App signing key certificate**.
3. Add both fingerprints to **Firebase Console** > **Project settings** > **Your apps** > `com.voidsower.app` > **Add fingerprint**.

---

## 📥 Step 4: Download and Place `google-services.json`

1. Download the generated `google-services.json` configuration file from Firebase Console.
2. Place the file directly in the Android app directory:
   ```bash
   cp ~/Downloads/google-services.json android/app/google-services.json
   ```
3. Verify that `android/app/build.gradle.kts` has the Google Services plugin enabled:
   ```kotlin
   plugins {
       id("com.android.application")
       id("dev.flutter.flutter-gradle-plugin")
       id("com.google.gms.google-services") // Apply Google Services plugin
       id("com.google.firebase.crashlytics") // Apply Crashlytics NDK plugin
   }
   ```
4. Verify `android/build.gradle.kts` root dependencies include:
   ```kotlin
   dependencies {
       classpath("com.google.gms:google-services:4.4.2")
       classpath("com.google.firebase:firebase-crashlytics-gradle:3.0.3")
   }
   ```

---

## 💥 Step 5: Firebase Crashlytics & Native NDK Symbolication

Void Sower runs high-performance native C++17 algorithms via FFI (`libvoid_sower.so`). Crashlytics must be configured to upload native symbols for un-stripped stack traces:

1. In `android/app/build.gradle.kts`, ensure NDK debug symbol generation is set to `FULL`:
   ```kotlin
   android {
       buildTypes {
           release {
               ndk {
                   debugSymbolLevel = "FULL"
               }
           }
       }
   }
   ```
2. When building the release App Bundle via `scripts/build_release_bundle.sh`, native debug symbols are automatically retained in `BUNDLE-METADATA/com.android.tools.build.debugsymbols/` and Dart obfuscation symbols are split into `build/app/outputs/symbols/`.
3. Verify crash reporting initialization in Dart:
   - `CrashReportingService` captures both Dart unhandled zone errors (`PlatformDispatcher.instance.onError`) and native signals.

---

## 📊 Step 6: Google Analytics & Custom Game Events

Configure custom game event parameters in the Firebase Console:

1. Navigate to **Analytics** > **Events**.
2. Void Sower automatically dispatches the following custom events:
   - `sector_started`: `sector_id`, `difficulty_tier`, `chassis_variant`
   - `sector_completed`: `sector_id`, `score`, `stars_earned`, `duration_seconds`
   - `lance_fired`: `corridor_index`, `accumulated_mass`, `damage_delivered`
   - `cascade_triggered`: `lap_depth`, `consecutive_sows`
   - `pro_purchased`: `sku_id`, `price_micros`, `currency`
3. Under **Analytics** > **Custom definitions**, create custom dimensions for:
   - `chassis_variant` (User scope)
   - `sector_id` (Event scope)
   - `stars_earned` (Event scope)

---

## 🛡️ Step 7: Cloud Firestore Security Rules

For guest player profile storage and anonymous progression sync:

1. Navigate to **Build** > **Firestore Database** > **Create database**.
2. Location: Choose multi-region close to primary audience (e.g., `nam5` for North America or `eur3` for Europe).
3. Apply secure, least-privilege security rules:
   ```javascript
   rules_version = '2';
   service cloud.firestore {
     match /databases/{database}/documents {
       // Player profiles: Only authenticated user can read/write their own document
       match /players/{userId} {
         allow read: if request.auth != null;
         allow write: if request.auth != null && request.auth.uid == userId;
       }
       
       // Global high score leaderboards: Publicly readable, write-validated
       match /leaderboards/{boardId}/scores/{scoreId} {
         allow read: if true;
         allow create: if request.auth != null 
                       && request.resource.data.score is int 
                       && request.resource.data.score >= 0;
         allow update, delete: if false;
       }
     }
   }
   ```

---

## 💰 Step 8: Link Firebase with Google Play Console

Linking Firebase to Google Play unlocks Google Play In-App Purchase analytics, subscription retention stats, and automated event tracking:

1. In **Firebase Console**, click the **Gear icon (Project settings)** > **Integrations**.
2. Locate **Google Play** and click **Link**.
3. Select your Google Play Developer Account.
4. Ensure `com.voidsower.app` is linked.
5. Grant necessary permissions for In-App Purchase data sync.
