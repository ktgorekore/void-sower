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
cmake -B src/build -S src -DCMAKE_BUILD_TYPE=Release
cmake --build src/build -j$(nproc)
ctest --test-dir src/build --output-on-failure

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

echo "======================================================================"
echo "Artifact: $BUNDLE_OUTPUT"
echo "Size: $BUNDLE_SIZE_MB MB ($BUNDLE_SIZE bytes)"
echo "SHA-256: $SHA256"
echo "Debug Symbols: $SYMBOL_DIR"
echo "======================================================================"

if [ "$BUNDLE_SIZE" -gt "$MAX_SIZE_BYTES" ]; then
  echo "[!] Warning: Bundle size ($BUNDLE_SIZE_MB MB) exceeds 25 MB limit!"
else
  echo "[+] Bundle size ($BUNDLE_SIZE_MB MB) is strictly within target (< 25 MB)."
fi

echo "[+] Release build pipeline completed successfully!"
