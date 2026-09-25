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

"""Orchestrates comprehensive profiling across all three campaign final Sector 9s on Android emulator."""

import json
import os
import re
import shutil
import subprocess
import sys
import threading
import time

DEVICE = "emulator-5554"
PKG = "com.voidsower.app"
OUT_BASE_DIR = ".agents/tmp/profiler_campaign_sector9s"
DURATION_PER_SECTOR = 35

CAMPAIGNS = [
    {
        "id": "kilwa_basin",
        "name": "Kilwa Nebula Basin",
        "sector_id": 9,
        "sector_name": "Great Siphon Singularity",
        "threat_tier": "Tier 3 (Singularity Core / Heavy Assault)",
        "tab_tap": (264, 487),
        "needs_scroll": True,
        "default_ai_tap": (917, 2581),
    },
    {
        "id": "phantom_drift",
        "name": "Phantom Drift",
        "sector_id": 18,
        "sector_name": "Agalega Singularity Zenith",
        "threat_tier": "Tier 3 (Singularity Drift / Evasive Craft)",
        "tab_tap": (672, 487),
        "needs_scroll": False,
        "default_ai_tap": (917, 2581),
    },
    {
        "id": "void_swarm",
        "name": "Void Swarm",
        "sector_id": 27,
        "sector_name": "Mozambique Singularity Hive",
        "threat_tier": "Tier 3 (Apex Crucible / Swarm Horde)",
        "tab_tap": (1080, 487),
        "needs_scroll": False,
        "default_ai_tap": (917, 2581),
    },
]


def adb(args):
  cmd = ["adb", "-s", DEVICE] + args
  return subprocess.run(cmd, capture_output=True, text=True)


def tap(x, y):
  adb(["shell", "input", "tap", str(x), str(y)])


def swipe(x1, y1, x2, y2, duration_ms=250):
  adb(["shell", "input", "swipe", str(x1), str(y1), str(x2), str(y2), str(duration_ms)])


def get_pid():
  res = adb(["shell", "pidof", PKG])
  if res.returncode == 0 and res.stdout.strip():
    return res.stdout.strip().split()[0]
  return None


def get_layout_text():
  res = subprocess.run([
      "/home/kelvingorekore/Android/Sdk/cmdline-tools/latest/bin/android",
      "layout"
  ], capture_output=True, text=True)
  return res.stdout


def ensure_on_map():
  """Ensures the app is on the Campaign Map screen."""
  print("[Nav] Verifying/Navigating to Campaign Star Map...")
  pid = get_pid()
  if not pid:
    print("[Nav] Launching app...")
    adb(["shell", "am", "start", "-n", f"{PKG}/.MainActivity"])
    time.sleep(3.5)

  layout_text = get_layout_text()

  if "ORBITAL COMMAND DECK" in layout_text:
    print("[Nav] Confirmed on Campaign Star Map.")
    return

  if "TACTICAL PAUSE" in layout_text:
    print("[Nav] On Tactical Pause dialog, tapping Star Map...")
    tap(319, 1814)
    time.sleep(2.0)
    return

  print("[Nav] In active combat, opening pause menu...")
  tap(1262, 232)
  time.sleep(1.2)
  tap(319, 1814)
  time.sleep(2.0)


def combat_watchdog(stop_event):
  """Periodically handles victory/defeat dialogs or keeps AI firing during intense combat."""
  while not stop_event.is_set():
    time.sleep(2.0)
    # If a victory dialog or defeat modal appears in center, tap Replay or Advance
    tap(672, 1640)


def parse_meminfo(mem_text):
  """Parses dumpsys meminfo into structured dictionary."""
  res = {
      "native_heap_pss_kb": 0,
      "native_heap_dirty_kb": 0,
      "dalvik_heap_pss_kb": 0,
      "dalvik_heap_dirty_kb": 0,
      "graphics_pss_kb": 0,
      "total_pss_kb": 0,
      "total_dirty_kb": 0,
  }
  for line in mem_text.splitlines():
    line_s = line.strip()
    if line_s.startswith("Native Heap"):
      parts = line_s.split()
      if len(parts) >= 3:
        try:
          res["native_heap_pss_kb"] = int(parts[2])
          res["native_heap_dirty_kb"] = int(parts[3])
        except ValueError:
          pass
    elif line_s.startswith("Dalvik Heap"):
      parts = line_s.split()
      if len(parts) >= 3:
        try:
          res["dalvik_heap_pss_kb"] = int(parts[2])
          res["dalvik_heap_dirty_kb"] = int(parts[3])
        except ValueError:
          pass
    elif line_s.startswith("Graphics"):
      parts = line_s.split()
      if len(parts) >= 2:
        try:
          res["graphics_pss_kb"] = int(parts[1])
        except ValueError:
          pass
    elif line_s.startswith("TOTAL PSS:"):
      m = re.search(r"TOTAL PSS:\s+(\d+)", line_s)
      if m:
        res["total_pss_kb"] = int(m.group(1))
    elif line_s.startswith("TOTAL") and "TOTAL PSS" not in line_s:
      parts = line_s.split()
      if len(parts) >= 3:
        try:
          res["total_pss_kb"] = int(parts[1])
          res["total_dirty_kb"] = int(parts[2])
        except ValueError:
          pass
  return res


def parse_gfxinfo(gfx_text):
  """Parses dumpsys gfxinfo into structured dictionary."""
  res = {
      "total_frames": 0,
      "janky_frames": 0,
      "janky_pct": 0.0,
      "percentile_50_ms": 0,
      "percentile_90_ms": 0,
      "percentile_95_ms": 0,
      "percentile_99_ms": 0,
      "missed_vsync": 0,
  }
  for line in gfx_text.splitlines():
    line_s = line.strip()
    if "Total frames rendered:" in line_s:
      m = re.search(r"Total frames rendered:\s+(\d+)", line_s)
      if m:
        res["total_frames"] = int(m.group(1))
    elif "Janky frames:" in line_s:
      m = re.search(r"Janky frames:\s+(\d+)\s+\(([\d\.]+)%\)", line_s)
      if m:
        res["janky_frames"] = int(m.group(1))
        res["janky_pct"] = float(m.group(2))
    elif "50th percentile:" in line_s:
      m = re.search(r"50th percentile:\s+(\d+)ms", line_s)
      if m:
        res["percentile_50_ms"] = int(m.group(1))
    elif "90th percentile:" in line_s:
      m = re.search(r"90th percentile:\s+(\d+)ms", line_s)
      if m:
        res["percentile_90_ms"] = int(m.group(1))
    elif "95th percentile:" in line_s:
      m = re.search(r"95th percentile:\s+(\d+)ms", line_s)
      if m:
        res["percentile_95_ms"] = int(m.group(1))
    elif "99th percentile:" in line_s:
      m = re.search(r"99th percentile:\s+(\d+)ms", line_s)
      if m:
        res["percentile_99_ms"] = int(m.group(1))
    elif "Number Missed Vsync:" in line_s:
      m = re.search(r"Number Missed Vsync:\s+(\d+)", line_s)
      if m:
        res["missed_vsync"] = int(m.group(1))
  return res


def parse_dso_report(dso_text):
  """Extracts percentage overhead of key libraries from simpleperf DSO report."""
  dso_map = {}
  for line in dso_text.splitlines():
    parts = line.strip().split()
    if len(parts) >= 2:
      try:
        pct_str = parts[0].rstrip("%")
        pct = float(pct_str)
        dso_name = parts[-1]
        dso_map[dso_name] = pct
      except ValueError:
        pass
  return dso_map


def profile_campaign_sector(campaign):
  cid = campaign["id"]
  cname = campaign["name"]
  sec_id = campaign["sector_id"]
  sec_name = campaign["sector_name"]
  out_dir = os.path.join(OUT_BASE_DIR, cid)
  os.makedirs(out_dir, exist_ok=True)

  print(f"\n{'='*70}")
  print(f"[Profiling Session] {cname} — Sector {sec_id}: {sec_name}")
  print(f"[Threat Tier] {campaign['threat_tier']}")
  print(f"{'='*70}")

  # 1. Ensure on Campaign Map
  ensure_on_map()

  # 2. Tap campaign theater tab
  tab_x, tab_y = campaign["tab_tap"]
  print(f"[Nav] Selecting theater tab for {cname} at ({tab_x}, {tab_y})...")
  tap(tab_x, tab_y)
  time.sleep(1.5)

  # 3. Locate Sector 9 card dynamically or scroll
  if campaign["needs_scroll"]:
    print("[Nav] Scrolling down to expose Sector 9 card...")
    swipe(672, 2400, 672, 1000, 300)
    time.sleep(1.0)

  layout_text = get_layout_text()
  ai_tap_x, ai_tap_y = campaign["default_ai_tap"]
  try:
    layout_data = json.loads(layout_text)
    for item in layout_data:
      desc = item.get("content-desc", "")
      if sec_name in desc and "center" in item:
        center = json.loads(item["center"])
        ai_tap_x = 917
        ai_tap_y = center[1]
        print(f"[Nav] Detected {sec_name} at Y={ai_tap_y}, targeting AI button at ({ai_tap_x}, {ai_tap_y})")
        break
  except Exception as e:
    print(f"[Nav] Warning parsing layout ({e}), using default AI button coords ({ai_tap_x}, {ai_tap_y})")

  # 4. Tap AI launch button on Sector 9
  print(f"[Nav] Launching Sector {sec_id} with AI Auto-Solver at ({ai_tap_x}, {ai_tap_y})...")
  tap(ai_tap_x, ai_tap_y)
  time.sleep(3.0)  # Allow combat arena to initialize and invaders to deploy

  # 5. Capture active combat screenshot
  screen_path = os.path.join(out_dir, f"combat_sector_{sec_id}.png")
  print(f"[Capture] Capturing live combat screenshot to {screen_path}...")
  with open(screen_path, "wb") as f:
    subprocess.run(["adb", "-s", DEVICE, "exec-out", "screencap", "-p"], stdout=f, check=True)

  # 6. Reset graphics frame stats
  adb(["shell", "dumpsys", "gfxinfo", PKG, "reset"])

  # 7. Start watchdog
  stop_event = threading.Event()
  wd_thread = threading.Thread(target=combat_watchdog, args=(stop_event,))
  wd_thread.daemon = True
  wd_thread.start()

  # 8. Run Simpleperf recording
  perf_device_path = f"/data/local/tmp/perf_{cid}_sec{sec_id}.data"
  pid = get_pid()
  print(f"[Simpleperf] Recording {DURATION_PER_SECTOR}s with call-graph on PID {pid}...")
  t0 = time.time()
  rec_proc = adb([
      "shell", "simpleperf", "record",
      "--app", PKG,
      "-g",
      "--duration", str(DURATION_PER_SECTOR),
      "-o", perf_device_path,
  ])
  elapsed = time.time() - t0
  print(f"[Simpleperf] Recording completed in {elapsed:.1f}s.")
  print(f"[Simpleperf Output]\n{rec_proc.stdout.strip()}")
  stop_event.set()

  # 9. Dump meminfo & gfxinfo
  print("[Telemetry] Gathering meminfo and gfxinfo...")
  mem_text = adb(["shell", "dumpsys", "meminfo", PKG]).stdout
  with open(os.path.join(out_dir, "meminfo.txt"), "w") as f:
    f.write(mem_text)

  gfx_text = adb(["shell", "dumpsys", "gfxinfo", PKG, "framestats"]).stdout
  with open(os.path.join(out_dir, "gfxinfo_framestats.txt"), "w") as f:
    f.write(gfx_text)

  # 10. Pull perf data
  local_perf = os.path.join(out_dir, f"perf_{cid}_sec{sec_id}.data")
  print(f"[Simpleperf] Pulling perf data to {local_perf}...")
  adb(["pull", perf_device_path, local_perf])

  # 11. Generate Simpleperf reports
  dso_rep = adb(["shell", "simpleperf", "report", "-i", perf_device_path, "--sort", "dso", "-n"]).stdout
  with open(os.path.join(out_dir, "report_dso.txt"), "w") as f:
    f.write(dso_rep)

  sym_rep = adb(["shell", "simpleperf", "report", "-i", perf_device_path, "--sort", "dso,symbol", "-n"]).stdout
  with open(os.path.join(out_dir, "report_symbols.txt"), "w") as f:
    f.write(sym_rep)

  th_rep = adb(["shell", "simpleperf", "report", "-i", perf_device_path, "--sort", "tid,comm", "-n"]).stdout
  with open(os.path.join(out_dir, "report_threads.txt"), "w") as f:
    f.write(th_rep)

  # Return to map for next campaign
  print("[Nav] Returning to Campaign Star Map...")
  tap(1262, 232)  # Pause
  time.sleep(1.0)
  tap(319, 1814)  # Map
  time.sleep(2.0)

  # Parse metrics
  mem_parsed = parse_meminfo(mem_text)
  gfx_parsed = parse_gfxinfo(gfx_text)
  dso_parsed = parse_dso_report(dso_rep)

  # Sample count
  sample_count = 0
  lost_count = 0
  m_samp = re.search(r"Samples recorded:\s+([\d,]+)\.\s+Samples lost:\s+(\d+)", rec_proc.stdout)
  if m_samp:
    sample_count = int(m_samp.group(1).replace(",", ""))
    lost_count = int(m_samp.group(2))

  session_summary = {
      "campaign_id": cid,
      "campaign_name": cname,
      "sector_id": sec_id,
      "sector_name": sec_name,
      "threat_tier": campaign["threat_tier"],
      "duration_sec": DURATION_PER_SECTOR,
      "samples_recorded": sample_count,
      "samples_lost": lost_count,
      "memory": mem_parsed,
      "graphics": gfx_parsed,
      "dso_overhead": dso_parsed,
      "top_symbols": sym_rep.strip().splitlines()[:25],
      "threads": th_rep.strip().splitlines()[:15],
  }

  summary_path = os.path.join(out_dir, "session_summary.json")
  with open(summary_path, "w") as f:
    json.dump(session_summary, f, indent=2)

  print(f"[Done] Session finished for {cname} Sector {sec_id}!")
  return session_summary


def main():
  os.makedirs(OUT_BASE_DIR, exist_ok=True)
  print(f"======================================================================")
  print(f"VOID SOWER: Comprehensive Campaign Final Sector 9 Deep Profiler")
  print(f"Target: {PKG} on {DEVICE} (NVIDIA GPU Host Accelerated)")
  print(f"======================================================================")

  all_results = []
  for camp in CAMPAIGNS:
    res = profile_campaign_sector(camp)
    all_results.append(res)

  master_file = os.path.join(OUT_BASE_DIR, "all_campaigns_sector9_summary.json")
  with open(master_file, "w") as f:
    json.dump(all_results, f, indent=2)

  print(f"\n======================================================================")
  print(f"ALL PROFILING SESSIONS COMPLETED!")
  print(f"Master summary saved to: {master_file}")
  print(f"======================================================================")


if __name__ == "__main__":
  main()
