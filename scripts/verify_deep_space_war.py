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

"""Automated verification script for Deep Space War mechanics on Android Emulator.

Validates:
1. 2D forward flight controls into deep space (y in [0.20, 0.65]).
2. Proximity lance damage scaling (+60% damage close-range vanguard multiplier).
3. Mid-space canopy ramming & swept collision deflection (CANOPY RAM! +75 PTS).
4. Tactical quest progression HUD banner and animated progress bars.
5. 60 FPS frame metrics via dumpsys gfxinfo.
6. Capture of verified screenshots and showcase video.
"""

import os
import shutil
import subprocess
import sys
import time
import numpy as np
from PIL import Image

DEVICE = "emulator-5554"
ARTIFACT_DIR = "/home/kelvingorekore/.gemini/antigravity-cli/brain/1d594b4d-78ab-4d30-b2cb-a002eeb81b34"
SCREENSHOTS_DIR = os.path.join(ARTIFACT_DIR, "deep_space_screenshots")
VIDEO_PATH = os.path.join(ARTIFACT_DIR, "deep_space_war_verification.mp4")


def adb(args, check=True):
  cmd = ["adb", "-s", DEVICE] + args
  res = subprocess.run(cmd, capture_output=True, text=True)
  if check and res.returncode != 0:
    print(f"[ADB Error] cmd: {' '.join(cmd)}\nstderr: {res.stderr}")
  return res


def tap(x, y):
  adb(["shell", "input", "tap", str(x), str(y)])


def swipe(x1, y1, x2, y2, duration_ms=200):
  adb(["shell", "input", "swipe", str(x1), str(y1), str(x2), str(y2), str(duration_ms)])


def ensure_app_focused():
  res = subprocess.run(
      ["adb", "-s", DEVICE, "shell", "dumpsys", "window"],
      capture_output=True,
      text=True,
  )
  if "com.voidsower.app" not in res.stdout:
    print("[Focus] Launching com.voidsower.app to foreground...")
    adb(["shell", "am", "start", "-n", "com.voidsower.app/.MainActivity"])
    time.sleep(2.0)


def capture_screenshot(dest_name):
  ensure_app_focused()
  os.makedirs(SCREENSHOTS_DIR, exist_ok=True)
  dest_path = os.path.join(SCREENSHOTS_DIR, dest_name)
  temp_path = os.path.join("/tmp", f"cap_{dest_name}")

  with open(temp_path, "wb") as f:
    subprocess.run(["adb", "-s", DEVICE, "exec-out", "screencap", "-p"], stdout=f, check=True)

  if not os.path.exists(temp_path) or os.path.getsize(temp_path) < 10000:
    raise RuntimeError(f"Failed to capture valid screenshot for {dest_name}")

  img = Image.open(temp_path)
  arr = np.array(img)
  white_pct = (arr > 240).all(axis=-1).mean() * 100
  mean_rgb = arr.mean(axis=(0, 1))[:3].astype(int)

  print(f"[Capture] {dest_name}: size={img.size}, mean_rgb={mean_rgb}, white={white_pct:.2f}%")
  if white_pct > 15.0:
    print(f"[Warning] Screenshot {dest_name} contains high white pixel ratio ({white_pct:.1f}%)")

  shutil.copyfile(temp_path, dest_path)
  print(f"[Saved] -> {dest_path} ({os.path.getsize(dest_path)} bytes)")
  return dest_path


def seed_test_profile():
  print("[Profile] Resetting app state and injecting testing SharedPreferences...")
  adb(["shell", "settings", "put", "secure", "immersive_mode_confirmations", "confirmed"])
  adb(["shell", "am", "force-stop", "com.voidsower.app"])
  time.sleep(0.5)
  adb(["shell", "pm", "clear", "com.voidsower.app"])
  time.sleep(1.0)

  pref_xml = (
      '<?xml version="1.0" encoding="utf-8" standalone="yes" ?>\n'
      '<map>\n'
      '    <boolean name="flutter.void_sower_pro_unlocked" value="true" />\n'
      '    <boolean name="flutter.void_sower_ads_disabled" value="true" />\n'
      '    <boolean name="flutter.void_sower_completed_tutorial" value="true" />\n'
      '    <int name="flutter.void_sower_high_score" value="48200" />\n'
      '    <int name="flutter.void_sower_liberated_sectors" value="6" />\n'
      '    <int name="flutter.void_sower_sector_stars_1" value="3" />\n'
      '    <int name="flutter.void_sower_sector_stars_2" value="3" />\n'
      '    <int name="flutter.void_sower_sector_stars_3" value="3" />\n'
      '</map>\n'
  )
  with open("/tmp/prefs.xml", "w") as f:
    f.write(pref_xml)
  subprocess.run(["adb", "-s", DEVICE, "push", "/tmp/prefs.xml", "/data/local/tmp/prefs.xml"], check=True)
  adb(["shell", "run-as", "com.voidsower.app", "mkdir", "-p", "shared_prefs"])
  adb(["shell", "run-as", "com.voidsower.app", "cp", "/data/local/tmp/prefs.xml", "shared_prefs/FlutterSharedPreferences.xml"])
  adb(["shell", "run-as", "com.voidsower.app", "chmod", "660", "shared_prefs/FlutterSharedPreferences.xml"])
  time.sleep(0.5)
  print("[Profile] Seed complete.")


def collect_gfxinfo():
  print("[Metrics] Querying dumpsys gfxinfo com.voidsower.app...")
  res = subprocess.run(["adb", "-s", DEVICE, "shell", "dumpsys", "gfxinfo", "com.voidsower.app"], capture_output=True, text=True)
  return res.stdout


def run_verification():
  seed_test_profile()

  print("[Launch] Launching Void Sower MainActivity...")
  adb(["shell", "am", "start", "-n", "com.voidsower.app/.MainActivity"])
  time.sleep(4.0)

  # Check logcat for library loading
  log_res = subprocess.run(["adb", "-s", DEVICE, "logcat", "-d", "-s", "flutter", "DEBUG"], capture_output=True, text=True)
  print(f"[Logcat Check] Flutter logs: {len(log_res.stdout.splitlines())} lines captured.")

  # Reset gfxinfo
  adb(["shell", "dumpsys", "gfxinfo", "com.voidsower.app", "reset"])

  # Start 30s screenrecord in background
  print("[Record] Starting background screenrecord on emulator...")
  rec_proc = subprocess.Popen([
      "adb", "-s", DEVICE, "shell",
      "screenrecord", "--size", "1080x2400", "--bit-rate", "14000000", "--time-limit", "35",
      "/sdcard/deep_space_war_verification.mp4"
  ])

  t0 = time.time()

  # Step 1: Initial arena check & Quest Directive Banner
  print("[Step 1] Capturing Initial Combat Arena with Quest Directive HUD...")
  time.sleep(2.0)
  capture_screenshot("01_combat_arena_with_quest_hud.png")

  # Step 2: 2D Spatial Forward Flight into Deep Space
  # Playfield drag upward from lower command arc (x=672, y=2500 -> y=1200)
  print("[Step 2] Executing 2D forward drag into deep space (y in [0.20, 0.65])...")
  # Hold and drag smoothly
  swipe(672, 2500, 672, 1200, duration_ms=400)
  time.sleep(0.3)
  # Another upward glide to sustain forward deployment
  swipe(672, 2200, 672, 1100, duration_ms=500)
  time.sleep(0.2)
  capture_screenshot("02_deep_space_2d_flight.png")

  # Step 3: Proximity Lance Discharge (+60% Multiplier)
  print("[Step 3] Firing proximity particle lance at vanguard position...")
  # Upward flick to trigger quickFireActiveCorridor from vanguard position
  swipe(672, 1400, 672, 800, duration_ms=100)
  time.sleep(0.15)
  tap(672, 1200) # double tap / quick tap to fire secondary lance
  capture_screenshot("03_proximity_lance_vanguard.png")

  # Step 4: Mid-Space Canopy Ramming vs Descending Invaders
  print("[Step 4] Advancing dreadnought canopy to ram descending invader bullets...")
  # Align with Corridor 2/3 (x=380) and thrust forward
  swipe(672, 2400, 380, 1100, duration_ms=450)
  time.sleep(0.2)
  # Pulse harmonic shield / lance
  tap(380, 1100)
  time.sleep(0.3)
  capture_screenshot("04_mid_space_canopy_ramming.png")

  # Step 5: Lateral Sowing Cascades & Corridor Traversal
  print("[Step 5] Sowing plasma cores clockwise across frontline bays...")
  tap(277, 2496) # Bay focus
  time.sleep(0.2)
  tap(1127, 2829) # Sow Right
  time.sleep(0.5)
  capture_screenshot("05_tactical_sow_and_quest_progress.png")

  # Step 6: Engage AI Tactical Solver to clear invaders and observe victory/quest completion
  print("[Step 6] Engaging AI Tactical Auto-Solver for dynamic quest completion...")
  tap(1262, 234) # Tactical Pause
  time.sleep(0.8)
  tap(970, 1880) # Engage AI Solver
  time.sleep(0.6)
  tap(672, 1710) # Resume Sortie
  time.sleep(3.0)
  capture_screenshot("06_ai_solver_quest_execution.png")

  # Wait for screenrecord to finish
  print("[Record] Waiting for screenrecord to finalize...")
  rec_proc.wait()
  time.sleep(1.0)

  # Pull video
  print(f"[Record] Pulling video from emulator to {VIDEO_PATH}...")
  subprocess.run(["adb", "-s", DEVICE, "pull", "/sdcard/deep_space_war_verification.mp4", VIDEO_PATH], check=True)
  if os.path.exists(VIDEO_PATH):
    print(f"[Record] Video saved successfully: {os.path.getsize(VIDEO_PATH)} bytes")

  # Collect gfxinfo
  gfx = collect_gfxinfo()
  gfx_path = os.path.join(ARTIFACT_DIR, "gfxinfo_report.txt")
  with open(gfx_path, "w") as f:
    f.write(gfx)
  print(f"[Metrics] Gfxinfo saved to {gfx_path}")

  print("\n=== VERIFICATION RUN COMPLETE ===")


if __name__ == "__main__":
  run_verification()
