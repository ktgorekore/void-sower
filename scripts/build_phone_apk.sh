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
# Build and Package Standalone Release APK for Physical Google Pixel Devices

set -euo pipefail

OUTPUT_DIR="build/app/outputs/flutter-apk"
TARGET_APK="$OUTPUT_DIR/app-release.apk"
DIST_APK="build/void-sower-pixel.apk"

echo "======================================================================"
echo "VOID SOWER: Physical Pixel Phone Release APK Builder"
echo "======================================================================"
echo "[1/3] Building optimized ARM64 release APK for Google Pixel..."

flutter build apk --release \
  --target-platform android-arm64 \
  --tree-shake-icons

if [ ! -f "$TARGET_APK" ]; then
  echo "[-] Error: Expected APK not found at $TARGET_APK"
  exit 1
fi

echo "[2/3] Verifying 16 KB ELF memory page alignment..."
./scripts/verify_16kb_alignment.sh build/app/intermediates

echo "[3/3] Copying convenient distribution artifact to $DIST_APK..."
cp "$TARGET_APK" "$DIST_APK"

APK_SIZE=$(stat -c%s "$DIST_APK" 2>/dev/null || stat -f%z "$DIST_APK")
APK_SIZE_MB=$(echo "scale=2; $APK_SIZE / 1048576" | bc)
SHA256=$(sha256sum "$DIST_APK" | awk '{print $1}')
LOCAL_IP=$(hostname -I | awk '{print $1}')

echo "======================================================================"
echo "SUCCESS! Ready for direct phone installation:"
echo "  Artifact: $DIST_APK ($APK_SIZE_MB MB)"
echo "  SHA-256:  $SHA256"
echo "======================================================================"
echo ""
echo "HOW TO INSTALL ON YOUR PIXEL PHONE:"
echo ""
echo "Method 1: Direct Download over Wi-Fi (No Cables)"
echo "  1. Run this command in your terminal to host the file:"
echo "     python3 -m http.server 8080 --directory build"
echo "  2. Open Chrome on your Pixel phone (connected to same Wi-Fi) and visit:"
echo "     http://${LOCAL_IP}:8080/void-sower-pixel.apk"
echo "  3. When downloaded, tap the file in Chrome or Files app and select 'Install'."
echo "     (If prompted, toggle 'Allow from this source' for Chrome/Files)."
echo ""
echo "Method 2: Direct USB Install via ADB (Instant)"
echo "  Connect your Pixel via USB cable (with USB debugging enabled) and run:"
echo "     adb install -r $DIST_APK"
echo ""
echo "Method 3: Cloud Drive (Google Drive / OneDrive / Nextcloud)"
echo "  Upload '$DIST_APK' to your Drive, open the Drive app on your phone, tap the file to install."
echo "======================================================================"
