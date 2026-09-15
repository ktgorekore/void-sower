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

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

BUILD_DIR="${REPO_ROOT}/build/native_bench"
RESULTS_JSON="${REPO_ROOT}/build/benchmark_results.json"
LOG_FILE="${REPO_ROOT}/BENCHMARK_LOG.md"

echo "======================================================================"
echo "VOID SOWER: Google Microbenchmark Runner & Performance Tracker"
echo "======================================================================"

mkdir -p "${REPO_ROOT}/build"

echo "[1/4] Configuring CMake in Release mode with benchmarks enabled..."
cmake -B "${BUILD_DIR}" -DCMAKE_BUILD_TYPE=Release -DBUILD_BENCHMARKS=ON "${REPO_ROOT}/src"

echo "[2/4] Building void_sower_benchmarks executable..."
cmake --build "${BUILD_DIR}" --target void_sower_benchmarks -j"$(nproc)"

echo "[3/4] Running microbenchmarks..."
"${BUILD_DIR}/void_sower_benchmarks" \
  --benchmark_out="${RESULTS_JSON}" \
  --benchmark_out_format=json

echo "[4/4] Parsing results and updating BENCHMARK_LOG.md..."
python3 - <<EOF
import json
import subprocess
import datetime
import os

repo_root = "${REPO_ROOT}"
results_file = "${RESULTS_JSON}"
log_file = "${LOG_FILE}"

with open(results_file, "r") as f:
    data = json.load(f)

benchmarks = {b["name"]: b for b in data.get("benchmarks", [])}

# Extract metrics
tick_ns = benchmarks.get("BM_CombatSystem_60HzUpdate", {}).get("cpu_time", 0.0)
sow_ns = benchmarks.get("BM_BaoPredictSow_Throughput", {}).get("cpu_time", 0.0)
lance_ns = benchmarks.get("BM_Discharge_LanceRaycast_ZeroAlloc", {}).get("cpu_time", 0.0)
flak_ns = benchmarks.get("BM_Discharge_FlakDetonation_ZeroAlloc", {}).get("cpu_time", 0.0)
mcts_ns = benchmarks.get("BM_MctsSolver_FullSearch_400Rollouts", {}).get("cpu_time", 0.0)
ffi_ns = benchmarks.get("BM_FFI_GetFullStateSnapshot", {}).get("cpu_time", 0.0)

# Convert MCTS from ns to ms
mcts_ms = mcts_ns / 1_000_000.0

try:
    commit_hash = subprocess.check_output(["git", "rev-parse", "--short", "HEAD"], cwd=repo_root).decode("utf-8").strip()
except Exception:
    commit_hash = "unknown"

date_utc = datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%d %H:%M")

arch = os.uname().machine
compiler = "GCC 13" # default on Ubuntu host
try:
    cc_version = subprocess.check_output(["g++", "-dumpfullversion", "-dumpversion"]).decode("utf-8").strip()
    compiler = f"GCC {cc_version}"
except Exception:
    pass

compiler_arch = f"{compiler} / {arch}"

# Target budget: 60Hz tick <= 15,000 ns (15 microseconds)
status = "PASS" if tick_ns <= 15000 else "REGRESSION"

row = f"| {date_utc} | \`{commit_hash}\` | {compiler_arch} | {tick_ns:,.0f} | {sow_ns:,.0f} | {lance_ns:,.0f} | {flak_ns:,.0f} | {mcts_ms:.3f} | {ffi_ns:,.0f} | {status} |\n"

with open(log_file, "a") as f:
    f.write(row)

print(f"[+] Benchmark entry recorded to {log_file}")
print(row.strip())
EOF

echo "======================================================================"
echo "Microbenchmarking completed successfully."
echo "======================================================================"
