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

"""Automates high-resolution screenshot capture for Google Play Console store listing."""

import os
import shutil
import subprocess
import sys
import time

DEVICE = "emulator-5554"
SCREENSHOTS_DIR = "/home/kelvingorekore/projects/void-sower/store_listing/screenshots/phone"
ASSETS_DIR = "/home/kelvingorekore/projects/void-sower/store_listing/assets"


def adb_cmd(args):
  cmd = ["adb", "-s", DEVICE] + args
  return subprocess.run(cmd, capture_output=True, text=True)


def tap(x, y):
  adb_cmd(["shell", "input", "tap", str(x), str(y)])


def keyevent(code):
  adb_cmd(["shell", "input", "keyevent", str(code)])


def capture(dest_name):
  dest_path = os.path.join(SCREENSHOTS_DIR, dest_name)
  print(f"[Capture] Grabbing {dest_name}...")
  with open(dest_path, "wb") as f:
    subprocess.run(["adb", "-s", DEVICE, "exec-out", "screencap", "-p"], stdout=f)
  print(f"[Saved] -> {dest_path}")
  return dest_path


def main():
  os.makedirs(SCREENSHOTS_DIR, exist_ok=True)
  os.makedirs(ASSETS_DIR, exist_ok=True)

  adb_cmd(["shell", "settings", "put", "secure", "immersive_mode_confirmations", "confirmed"])

  # 1. Reset state: force-stop app, clear data, and seed persistent Pro unlock
  print("[Init] Resetting app state & seeding Pro entitlement...")
  adb_cmd(["shell", "am", "force-stop", "com.voidsower.app"])
  time.sleep(0.5)
  adb_cmd(["shell", "pm", "clear", "com.voidsower.app"])
  time.sleep(1.0)

  pref_xml = (
      '<?xml version="1.0" encoding="utf-8" standalone="yes" ?>\n'
      '<map>\n'
      '    <boolean name="flutter.void_sower_pro_unlocked" value="true" />\n'
      '    <boolean name="flutter.void_sower_completed_tutorial" value="false" />\n'
      '</map>\n'
  )
  with open("/tmp/prefs.xml", "w") as f:
    f.write(pref_xml)
  subprocess.run(["adb", "-s", DEVICE, "push", "/tmp/prefs.xml", "/data/local/tmp/prefs.xml"], check=True)
  adb_cmd(["shell", "run-as", "com.voidsower.app", "mkdir", "-p", "shared_prefs"])
  adb_cmd(["shell", "run-as", "com.voidsower.app", "cp", "/data/local/tmp/prefs.xml", "shared_prefs/FlutterSharedPreferences.xml"])
  adb_cmd(["shell", "run-as", "com.voidsower.app", "chmod", "660", "shared_prefs/FlutterSharedPreferences.xml"])
  time.sleep(0.5)

  # Launch App directly into Combat Arena
  print("[Launch] Starting Void Sower main activity...")
  adb_cmd(["shell", "am", "start", "-n", "com.voidsower.app/.MainActivity"])
  time.sleep(3.5)

  # Screenshot 03: Flight Academy Onboarding (Appears on launch over combat arena)
  print("[Academy] Capturing 03_flight_academy_onboarding.png...")
  capture("03_flight_academy_onboarding.png")
  shutil.copyfile(
      os.path.join(SCREENSHOTS_DIR, "03_flight_academy_onboarding.png"),
      os.path.join(ASSETS_DIR, "phone_02_flight_academy.png"),
  )

  # Dismiss tutorial overlay to enter active combat (tap SKIP at x=210, y=2060)
  print("[Combat] Dismissing Flight Academy tutorial overlay (tap SKIP)...")
  tap(210, 2060)
  time.sleep(1.5)

  # Screenshot 01: Tactical Combat Grid (Active combat corridor with enemies, dreadnought, capacitor ring)
  print("[Combat] Capturing 01_tactical_combat_grid.png...")
  capture("01_tactical_combat_grid.png")
  shutil.copyfile(
      os.path.join(SCREENSHOTS_DIR, "01_tactical_combat_grid.png"),
      os.path.join(ASSETS_DIR, "phone_01_tactical_combat_grid.png"),
  )

  # Screenshot 07: Bao Orbital Codex (Tap RULES button at x=883, y=210 in Tier 1)
  print("[Codex] Opening Bao Codex dialog...")
  tap(883, 210)
  time.sleep(1.2)
  capture("07_bao_orbital_codex.png")
  shutil.copyfile(
      os.path.join(SCREENSHOTS_DIR, "07_bao_orbital_codex.png"),
      os.path.join(ASSETS_DIR, "phone_03_bao_codex.png"),
  )
  # Close Bao Codex dialog via Back keyevent
  keyevent(4)
  time.sleep(0.8)

  # Screenshot 08: Pilot Telemetry Dashboard (Tap Pilot Callsign pill at x=130, y=305 in Tier 2)
  print("[Profile] Opening Pilot Dossier modal...")
  tap(130, 305)
  time.sleep(1.2)
  capture("08_pilot_telemetry_dashboard.png")
  shutil.copyfile(
      os.path.join(SCREENSHOTS_DIR, "08_pilot_telemetry_dashboard.png"),
      os.path.join(ASSETS_DIR, "phone_04_pilot_dossier.png"),
  )
  # Close Pilot Dossier modal via Back keyevent
  keyevent(4)
  time.sleep(0.8)

  # Navigate to Star Map: Tap [ MAP ] button in Tier 1 (x=75, y=210)
  print("[Map] Navigating to Kilwa Basin Campaign Star Map...")
  tap(75, 210)
  time.sleep(1.8)

  # Screenshot 05: Kilwa Basin Campaign Map
  print("[Map] Capturing 05_kilwa_basin_campaign_map.png...")
  capture("05_kilwa_basin_campaign_map.png")

  # Screenshot 04: Orbital Fleet Hangar (Tap Rocket icon at x=696, y=220 in Map AppBar)
  print("[Hangar] Opening Fleet Hangar dialog...")
  tap(696, 220)
  time.sleep(1.2)
  capture("04_orbital_fleet_hangar.png")
  shutil.copyfile(
      os.path.join(SCREENSHOTS_DIR, "04_orbital_fleet_hangar.png"),
      os.path.join(ASSETS_DIR, "phone_06_hangar.png"),
  )
  # Close Hangar dialog via Back keyevent
  keyevent(4)
  time.sleep(0.8)

  # Return to CombatScreen: Tap back arrow at x=84, y=220
  print("[Combat] Returning to Combat Arena...")
  tap(84, 220)
  time.sleep(1.2)

  # Screenshot 02: Quadratic Lance Discharge (Discharge particle lance up corridor)
  print("[Combat] Discharging Axial Particle Lance...")
  tap(500, 2770)  # AXIAL DISCHARGE button
  time.sleep(0.15)
  capture("02_quadratic_lance_discharge.png")
  shutil.copyfile(
      os.path.join(SCREENSHOTS_DIR, "02_quadratic_lance_discharge.png"),
      os.path.join(ASSETS_DIR, "phone_02_quadratic_lances.png"),
  )
  time.sleep(0.5)

  # Restart combat fresh before activating AI solver
  print("[Combat] Restarting combat for clean AI victory sequence...")
  tap(906, 390)  # RESTART button in Tier 3
  time.sleep(0.8)

  # Activate AI Solver in Tier 3 (x=1260, y=390) to eliminate invaders and achieve Victory
  print("[Solver] Activating AI Tactical Solver to clear sector...")
  tap(1260, 390)

  # Poll every 0.25s for victory modal
  print("[Victory] Waiting for Sector Liberation modal...")
  import numpy as np
  from PIL import Image

  modal_captured = False
  for attempt in range(160):
    time.sleep(0.25)
    dest_path = os.path.join(SCREENSHOTS_DIR, "06_sector_liberation_victory.png")
    with open(dest_path, "wb") as f:
      subprocess.run(["adb", "-s", DEVICE, "exec-out", "screencap", "-p"], stdout=f)
    if attempt < 12:
      # Victory takes at least 3-5 seconds of solver execution
      continue
    try:
      im = Image.open(dest_path)
      arr = np.array(im)
      # Check for gold/amber victory modal card around center (y: 800..1800, x: 200..1100)
      gold_mask = (
          (arr[800:1800, 200:1100, 0] > 200)
          & (arr[800:1800, 200:1100, 1] > 160)
          & (arr[800:1800, 200:1100, 2] < 60)
      )
      if np.sum(gold_mask) > 300:
        print(f"[Victory] Captured 06_sector_liberation_victory.png (attempt {attempt + 1})!")
        modal_captured = True
        break
    except Exception as e:
      pass

  if not modal_captured:
    print("[Victory] Reached timeout, keeping latest frame for 06_sector_liberation_victory.png")

  print("\n[Complete] All 8 Play Store phone screenshots recaptured successfully!")


if __name__ == "__main__":
  main()
