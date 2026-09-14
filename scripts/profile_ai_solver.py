#!/usr/bin/env python3
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

"""Orchestrates 65-second deep profiling of Void Sower with active AI Tactical Solver."""

import os
import subprocess
import sys
import threading
import time

DEVICE = "emulator-5554"
PKG = "com.voidsower.app"
OUT_DIR = ".agents/tmp/profiler"
DURATION = 65


def adb(args):
  cmd = ["adb", "-s", DEVICE] + args
  return subprocess.run(cmd, capture_output=True, text=True)


def tap(x, y):
  adb(["shell", "input", "tap", str(x), str(y)])


def get_pid():
  res = adb(["shell", "pidof", PKG])
  if res.returncode == 0 and res.stdout.strip():
    return res.stdout.strip().split()[0]
  return None


def ensure_solver_running():
  pid = get_pid()
  if not pid:
    print("[Setup] Launching app...")
    adb(["shell", "am", "start", "-n", f"{PKG}/.MainActivity"])
    time.sleep(3.0)

  print("[Setup] Navigating into active combat...")
  # Tap ENGAGE on Sector 1
  tap(1105, 957)
  time.sleep(1.0)
  # Dismiss tutorial if open
  tap(294, 2131)
  time.sleep(0.5)
  # Activate AI Solver
  tap(624, 332)
  time.sleep(0.5)


def gameplay_watchdog(stop_event):
  """Periodically advances sectors or taps buttons if a wave clears or needs retry during profiling."""
  while not stop_event.is_set():
    time.sleep(1.0)
    # Tap advance sector if victory dialog is showing (672, 1950)
    tap(672, 1950)
    # Tap try again if defeat dialog is showing (980, 1850)
    tap(980, 1850)
    # Tap skip tutorial if briefing is showing
    tap(294, 2131)
    # Re-engage sector if on map screen
    tap(1105, 957)


def main():
  os.makedirs(OUT_DIR, exist_ok=True)
  print(f"[Profiler] Target package: {PKG} on {DEVICE}")
  print(f"[Profiler] Profiling duration: {DURATION}s")

  ensure_solver_running()
  pid = get_pid()
  print(f"[Profiler] Target PID: {pid}")

  # Reset graphics framestats
  adb(["shell", "dumpsys", "gfxinfo", PKG, "reset"])

  # Start gameplay watchdog in background thread
  stop_event = threading.Event()
  watchdog_thread = threading.Thread(target=gameplay_watchdog, args=(stop_event,))
  watchdog_thread.daemon = True
  watchdog_thread.start()

  # Launch Simpleperf recording
  perf_data_device = f"/data/local/tmp/perf_aisolver_{DURATION}s.data"
  print(f"[Profiler] Recording simpleperf telemetry ({DURATION}s with call-graph)...")

  record_cmd = [
      "adb", "-s", DEVICE, "shell",
      "simpleperf", "record",
      "--app", PKG,
      "-g",
      "--duration", str(DURATION),
      "-o", perf_data_device,
  ]

  t0 = time.time()
  rec_proc = subprocess.run(record_cmd, capture_output=True, text=True)
  elapsed = time.time() - t0
  print(f"[Profiler] Simpleperf recording finished in {elapsed:.1f}s.")
  print(f"[Profiler Output]\n{rec_proc.stdout}\n{rec_proc.stderr}")

  stop_event.set()

  # Collect memory and graphics telemetry
  print("[Profiler] Dumping gfxinfo & meminfo...")
  gfx_out = adb(["shell", "dumpsys", "gfxinfo", PKG, "framestats"]).stdout
  with open(os.path.join(OUT_DIR, "gfxinfo_framestats.txt"), "w") as f:
    f.write(gfx_out)

  mem_out = adb(["shell", "dumpsys", "meminfo", PKG]).stdout
  with open(os.path.join(OUT_DIR, "meminfo.txt"), "w") as f:
    f.write(mem_out)

  # Pull simpleperf data
  local_perf_data = os.path.join(OUT_DIR, f"perf_aisolver_{DURATION}s.data")
  print(f"[Profiler] Pulling perf.data to {local_perf_data}...")
  adb(["pull", perf_data_device, local_perf_data])

  # Generate DSO report
  print("[Profiler] Generating DSO overhead breakdown...")
  dso_report = adb([
      "shell", "simpleperf", "report",
      "-i", perf_data_device,
      "--sort", "dso",
      "-n"
  ]).stdout
  with open(os.path.join(OUT_DIR, "report_dso.txt"), "w") as f:
    f.write(dso_report)

  # Generate Symbol report (top 60 functions)
  print("[Profiler] Generating symbol hot spot report...")
  symbol_report = adb([
      "shell", "simpleperf", "report",
      "-i", perf_data_device,
      "--sort", "dso,symbol",
      "-n"
  ]).stdout
  with open(os.path.join(OUT_DIR, "report_symbols.txt"), "w") as f:
    f.write(symbol_report)

  # Generate Thread report
  print("[Profiler] Generating thread utilization report...")
  thread_report = adb([
      "shell", "simpleperf", "report",
      "-i", perf_data_device,
      "--sort", "tid,comm",
      "-n"
  ]).stdout
  with open(os.path.join(OUT_DIR, "report_threads.txt"), "w") as f:
    f.write(thread_report)

  # Generate Call Graph report
  print("[Profiler] Generating call graph report...")
  callgraph_report = adb([
      "shell", "simpleperf", "report",
      "-i", perf_data_device,
      "-g",
      "--max-stack", "16",
      "-n"
  ]).stdout
  with open(os.path.join(OUT_DIR, "report_callgraph.txt"), "w") as f:
    f.write(callgraph_report[:500000])

  print("\n=======================================================")
  print("TOP 15 DSO / BINARY OVERHEAD:")
  print("=======================================================")
  dso_lines = dso_report.strip().split("\n")
  for line in dso_lines[:25]:
    print(line)

  print("\n=======================================================")
  print("TOP 25 HOT SPOT SYMBOLS:")
  print("=======================================================")
  sym_lines = symbol_report.strip().split("\n")
  for line in sym_lines[:35]:
    print(line)

  print("\n=======================================================")
  print("THREAD OVERHEAD BREAKDOWN:")
  print("=======================================================")
  th_lines = thread_report.strip().split("\n")
  for line in th_lines[:20]:
    print(line)
  print("=======================================================\n")


if __name__ == "__main__":
  main()
