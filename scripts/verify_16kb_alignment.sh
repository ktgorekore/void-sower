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
# Automated ELF 16 KB Memory Page Size Alignment Verification Script
# Required for Android 15 (API level 35) 16 KB page size support.

set -euo pipefail

TARGET_DIR="${1:-build}"
REQUIRED_ALIGN_HEX="0x4000"
REQUIRED_ALIGN_DEC=16384

echo "======================================================================"
echo "VOID SOWER: Android 15 16 KB Page Alignment Verification Audit"
echo "Target Search Directory: $TARGET_DIR"
echo "Required Alignment: >= $REQUIRED_ALIGN_HEX ($REQUIRED_ALIGN_DEC bytes)"
echo "======================================================================"

if ! command -v readelf &> /dev/null; then
  echo "[-] Error: 'readelf' utility not found in PATH."
  exit 1
fi

SO_FILES=$(find "$TARGET_DIR" -type f -name "*.so" 2>/dev/null || true)

if [ -z "$SO_FILES" ]; then
  echo "[!] Notice: No .so shared libraries found in '$TARGET_DIR'."
  echo "    Build native Android libraries first (e.g., flutter build apk / aab)."
  exit 0
fi

FAILED=0
TOTAL=0

for so in $SO_FILES; do
  TOTAL=$((TOTAL + 1))
  echo -n "[*] Auditing $(basename "$so") ($so)... "

  # Extract LOAD segment lines using wide format
  LOAD_SEGMENTS=$(readelf -W -l "$so" | grep "LOAD" || true)

  if [ -z "$LOAD_SEGMENTS" ]; then
    echo "NO LOAD SEGMENTS"
    continue
  fi

  IS_COMPLIANT=1
  while IFS= read -r line; do
    # Extract Align value (last token on LOAD header line in readelf -W -l)
    ALIGN=$(echo "$line" | awk '{print $NF}')
    if [[ "$ALIGN" =~ ^0x[0-9a-fA-F]+$ ]]; then
      ALIGN_DEC=$((ALIGN))
      if [ "$ALIGN_DEC" -lt "$REQUIRED_ALIGN_DEC" ]; then
        IS_COMPLIANT=0
        echo ""
        echo "    [-] Non-compliant LOAD segment: $line (Align: $ALIGN < $REQUIRED_ALIGN_HEX)"
      fi
    fi
  done <<< "$LOAD_SEGMENTS"

  if [ "$IS_COMPLIANT" -eq 1 ]; then
    echo "PASSED (16 KB aligned)"
  else
    FAILED=$((FAILED + 1))
    echo "    FAILED: Not aligned to 16 KB boundary!"
  fi
done

echo "======================================================================"
echo "Audit Summary: $TOTAL scanned, $((TOTAL - FAILED)) passed, $FAILED failed."
echo "======================================================================"

if [ "$FAILED" -gt 0 ]; then
  echo "[-] Audit failed: $FAILED native libraries are not compliant with Android 15 16 KB page size!"
  exit 1
else
  echo "[+] All native libraries meet Android 15 16 KB page alignment standard!"
  exit 0
fi
