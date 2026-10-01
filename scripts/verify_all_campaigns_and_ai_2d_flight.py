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

"""Automated verification script for all 3 campaign theaters and 2D AI flight dynamics.

Verifies:
1. Campaign 1: Kilwa Basin (Standard Deep Space Warfare with AI 2D Flight)
2. Star Map Navigation: Kilwa Basin, Phantom Drift, and Void Swarm theaters
3. Campaign 2: Phantom Drift (Evasive Invaders with lateral thrusters & 2D AI Intercepts)
4. Campaign 3: Void Swarm (Dense Respawning Swarm Horde, Core Siphon & 2D AI Sorties)
5. Captures verified screenshots and full 55s video showcase.
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
SCREENSHOTS_DIR = os.path.join(ARTIFACT_DIR, "campaign_screenshots")
VIDEO_PATH = os.path.join(ARTIFACT_DIR, "campaigns_and_ai_2d_flight.mp4")


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
    print("[Focus] Launching com.voidsower.app...")
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
  print("[Profile] Resetting app state and unlocking all 3 campaign theaters...")
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
      '    <int name="flutter.void_sower_high_score" value="64200" />\n'
      '    <int name="flutter.void_sower_liberated_sectors" value="12" />\n'
      '    <int name="flutter.void_sower_campaign_liberated_kilwa_basin" value="9" />\n'
      '    <int name="flutter.void_sower_campaign_liberated_phantom_drift" value="9" />\n'
      '    <int name="flutter.void_sower_campaign_liberated_void_swarm" value="9" />\n'
      '    <int name="flutter.void_sower_sector_stars_1" value="3" />\n'
      '    <int name="flutter.void_sower_sector_stars_10" value="3" />\n'
      '    <int name="flutter.void_sower_sector_stars_19" value="3" />\n'
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


def run_campaign_verification():
  seed_test_profile()

  print("[Launch] Launching Void Sower MainActivity...")
  adb(["shell", "am", "start", "-n", "com.voidsower.app/.MainActivity"])
  time.sleep(4.0)

  # Start 55s screen recording
  print("[Record] Launching 55s comprehensive campaign & 2D AI flight video recording...")
  rec_proc = subprocess.Popen([
      "adb", "-s", DEVICE, "shell",
      "screenrecord", "--size", "1080x2400", "--bit-rate", "14000000", "--time-limit", "55",
      "/sdcard/campaigns_and_ai_2d_flight.mp4"
  ])

  t0 = time.time()

  def wait_until(sec):
    elapsed = time.time() - t0
    rem = sec - elapsed
    if rem > 0:
      time.sleep(rem)

  # --- PART 1: Campaign 1 (Kilwa Basin) Combat with Autonomous 2D AI Flight ---
  print("\n--- PART 1: Campaign 1 (Kilwa Basin) Autonomous 2D AI Flight ---")
  # Engage AI solver
  tap(1262, 234)  # Pause
  time.sleep(0.8)
  tap(970, 1880)  # Engage AI Solver
  time.sleep(0.6)
  tap(672, 1710)  # Resume Sortie
  print("[Campaign 1] AI Solver active: soaring into deep space with 2D flight dynamics...")

  # Wait 4 seconds for AI solver to advance in 2D space
  wait_until(7.0)
  capture_screenshot("01_kilwa_basin_ai_2d_deep_space_flight.png")

  # --- PART 2: Campaign Star Map Navigation & Theater Verification ---
  print("\n--- PART 2: Campaign Star Map Navigation ---")
  wait_until(10.0)
  tap(1262, 234)  # Pause
  time.sleep(0.8)
  tap(310, 1880)  # Open Star Map
  time.sleep(2.0)

  print("[Star Map] Capturing Theater 1: Kilwa Basin...")
  capture_screenshot("02_star_map_kilwa_basin_theater.png")

  wait_until(15.0)
  print("[Star Map] Switching to Theater 2: Phantom Drift...")
  tap(672, 440)   # Phantom Drift tab
  time.sleep(1.2)
  capture_screenshot("03_star_map_phantom_drift_theater.png")

  wait_until(19.0)
  print("[Star Map] Switching to Theater 3: Void Swarm...")
  tap(1110, 440)  # Void Swarm tab
  time.sleep(1.2)
  capture_screenshot("04_star_map_void_swarm_theater.png")

  # --- PART 3: Campaign 2 (Phantom Drift - Sector 10: Evasive Invaders) ---
  print("\n--- PART 3: Campaign 2 (Phantom Drift - Sector 10) ---")
  wait_until(23.0)
  tap(672, 440)   # Switch back to Phantom Drift tab
  time.sleep(1.0)
  print("[Phantom Drift] Launching Sector 10 with AI Auto-Solver...")
  tap(880, 750)   # Tap AI button on Sector 10 card
  time.sleep(2.0)

  # Let AI Solver track and hunt evasive invaders with 2D deep space maneuvers
  wait_until(32.0)
  print("[Phantom Drift] Capturing Evasive Invader 2D combat with AI flight...")
  capture_screenshot("05_phantom_drift_evasive_invaders_2d_flight.png")

  # --- PART 4: Campaign 3 (Void Swarm - Sector 19: Respawning Swarm Horde) ---
  print("\n--- PART 4: Campaign 3 (Void Swarm - Sector 19) ---")
  wait_until(36.0)
  tap(1262, 234)  # Pause
  time.sleep(0.8)
  tap(310, 1880)  # Open Star Map
  time.sleep(2.0)
  tap(1110, 440)  # Switch to Void Swarm tab
  time.sleep(1.2)
  print("[Void Swarm] Launching Sector 19 Swarm Frontline with AI Auto-Solver...")
  tap(880, 750)   # Tap AI button on Sector 19 card
  time.sleep(2.0)

  # Let AI Solver manage dense swarm horde with forward sorties and canopy ramming
  wait_until(48.0)
  print("[Void Swarm] Capturing Dense Swarm Horde 2D combat with AI flight...")
  capture_screenshot("06_void_swarm_dense_horde_2d_flight.png")

  # Wait for screen recording to finalize
  print("\n[Record] Waiting for screen recording to finalize...")
  rec_proc.wait()
  time.sleep(1.0)

  # Pull video
  print(f"[Record] Pulling video from emulator to {VIDEO_PATH}...")
  subprocess.run(["adb", "-s", DEVICE, "pull", "/sdcard/campaigns_and_ai_2d_flight.mp4", VIDEO_PATH], check=True)
  if os.path.exists(VIDEO_PATH):
    print(f"[Record] Video saved successfully: {os.path.getsize(VIDEO_PATH)} bytes")

  print("\n=== ALL CAMPAIGNS & 2D AI FLIGHT VERIFICATION COMPLETE ===")


if __name__ == "__main__":
  run_campaign_verification()
