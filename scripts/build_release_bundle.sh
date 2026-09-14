#!/usr/bin/env bash
#
# Copyright 2026 Void Sower Authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# Release Android App Bundle (.aab) Build & Optimization Pipeline

set -euo pipefail

SYMBOL_DIR="build/app/outputs/symbols"
BUNDLE_OUTPUT="build/app/outputs/bundle/release/app-release.aab"
MAX_SIZE_BYTES=26214400 # 25 MB

echo "======================================================================"
echo "VOID SOWER: Android App Bundle (.aab) Release Build Pipeline"
echo "======================================================================"

# Step 1: Pre-build validation
echo "[1/4] Running test suite and static analysis..."
flutter test --no-pub
cmake -B build/native_build -S src -DCMAKE_BUILD_TYPE=Release
cmake --build build/native_build -j$(nproc)
ctest --test-dir build/native_build --output-on-failure

# Verify release signing configuration
if [ ! -f "android/key.properties" ]; then
  echo "[-] Error: 'android/key.properties' not found!"
  echo "    Google Play rejects bundles signed with debug certificates."
  echo "    Please create 'android/key.properties' with your release keystore credentials:"
  echo "      storePassword=<your-password>"
  echo "      keyPassword=<your-password>"
  echo "      keyAlias=upload"
  echo "      storeFile=upload-keystore.jks"
  exit 1
fi

# Step 2: Build release bundle with Dart symbol obfuscation
echo "[2/4] Building optimized release Android App Bundle (.aab)..."
mkdir -p "$SYMBOL_DIR"
flutter build appbundle --release \
  --obfuscate \
  --split-debug-info="$SYMBOL_DIR" \
  --tree-shake-icons

# Step 3: Verify 16 KB page size alignment on native binaries
echo "[3/4] Running 16 KB ELF memory page alignment audit..."
./scripts/verify_16kb_alignment.sh build

# Step 4: Verify package size & fingerprint
echo "[4/4] Verifying bundle artifact integrity..."
if [ ! -f "$BUNDLE_OUTPUT" ]; then
  echo "[-] Error: Release bundle not found at $BUNDLE_OUTPUT"
  exit 1
fi

BUNDLE_SIZE=$(stat -c%s "$BUNDLE_OUTPUT" 2>/dev/null || stat -f%z "$BUNDLE_OUTPUT")
BUNDLE_SIZE_MB=$(echo "scale=2; $BUNDLE_SIZE / 1048576" | bc)
SHA256=$(sha256sum "$BUNDLE_OUTPUT" | awk '{print $1}')

# Calculate device-delivered payload size (excluding Play Console debug symbols in BUNDLE-METADATA)
# Measures single-architecture (arm64-v8a) split APK download payload delivered to user devices
PAYLOAD_STATS=$(unzip -v "$BUNDLE_OUTPUT" 2>/dev/null | awk '$8 ~ /^base\// && $8 !~ /^base\/lib\/(armeabi-v7a|x86_64)\// { orig += $1; comp += $3 } END { printf "%d %d", orig, comp }')
PAYLOAD_UNCOMPRESSED_BYTES=$(echo "$PAYLOAD_STATS" | awk '{print $1}')
PAYLOAD_COMPRESSED_BYTES=$(echo "$PAYLOAD_STATS" | awk '{print $2}')
PAYLOAD_DOWNLOAD_MB=$(echo "scale=2; $PAYLOAD_COMPRESSED_BYTES / 1048576" | bc)
PAYLOAD_INSTALLED_MB=$(echo "scale=2; $PAYLOAD_UNCOMPRESSED_BYTES / 1048576" | bc)

# Verify the bundle is signed with a release certificate (not debug)
CERT_OWNER=$(keytool -printcert -jarfile "$BUNDLE_OUTPUT" 2>/dev/null | grep "Owner:" | head -n 1 || true)
if echo "$CERT_OWNER" | grep -qi "Android Debug"; then
  echo "[-] Error: Release bundle was signed with the Android Debug certificate!"
  echo "    Google Play rejects debug-signed bundles. Verify android/key.properties."
  exit 1
fi

echo "======================================================================"
echo "Artifact: $BUNDLE_OUTPUT"
echo "Signing Certificate: $CERT_OWNER"
echo "Total Bundle Upload Size: $BUNDLE_SIZE_MB MB ($BUNDLE_SIZE bytes)"
echo "Estimated User Download Size (arm64-v8a): $PAYLOAD_DOWNLOAD_MB MB ($PAYLOAD_COMPRESSED_BYTES bytes)"
echo "Installed Device Footprint: $PAYLOAD_INSTALLED_MB MB ($PAYLOAD_UNCOMPRESSED_BYTES bytes)"
echo "SHA-256: $SHA256"
echo "Debug Symbols: $SYMBOL_DIR"
echo "======================================================================"

# Verification against Store Gate 6 standards
PLAY_UPLOAD_LIMIT_BYTES=209715200 # 200 MB Play Console AAB limit
if [ "$BUNDLE_SIZE" -gt "$PLAY_UPLOAD_LIMIT_BYTES" ]; then
  echo "[-] Error: Bundle size ($BUNDLE_SIZE_MB MB) exceeds Google Play 200 MB upload limit!"
  exit 1
else
  echo "[+] Bundle upload size ($BUNDLE_SIZE_MB MB) is within Google Play limit (< 200 MB)."
fi

if [ "$PAYLOAD_COMPRESSED_BYTES" -gt "$MAX_SIZE_BYTES" ]; then
  echo "[!] Warning: Estimated download payload ($PAYLOAD_DOWNLOAD_MB MB) exceeds 25 MB target!"
  exit 1
else
  echo "[+] Estimated download payload ($PAYLOAD_DOWNLOAD_MB MB) is strictly within target (< 25 MB)."
fi

echo "[+] Release build pipeline completed successfully!"

