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
import numpy as np
from PIL import Image

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


def seed_prefs(pro_unlocked=True, completed_tutorial=False, high_score=12480):
  adb_cmd(["shell", "settings", "put", "secure", "immersive_mode_confirmations", "confirmed"])
  adb_cmd(["shell", "am", "force-stop", "com.voidsower.app"])
  time.sleep(0.5)
  adb_cmd(["shell", "pm", "clear", "com.voidsower.app"])
  time.sleep(1.0)

  pref_xml = (
      '<?xml version="1.0" encoding="utf-8" standalone="yes" ?>\n'
      '<map>\n'
      f'    <boolean name="flutter.void_sower_pro_unlocked" value="{"true" if pro_unlocked else "false"}" />\n'
      f'    <boolean name="flutter.void_sower_completed_tutorial" value="{"true" if completed_tutorial else "false"}" />\n'
      f'    <int name="flutter.void_sower_high_score" value="{high_score}" />\n'
      '</map>\n'
  )
  with open("/tmp/prefs.xml", "w") as f:
    f.write(pref_xml)
  subprocess.run(["adb", "-s", DEVICE, "push", "/tmp/prefs.xml", "/data/local/tmp/prefs.xml"], check=True)
  adb_cmd(["shell", "run-as", "com.voidsower.app", "mkdir", "-p", "shared_prefs"])
  adb_cmd(["shell", "run-as", "com.voidsower.app", "cp", "/data/local/tmp/prefs.xml", "shared_prefs/FlutterSharedPreferences.xml"])
  adb_cmd(["shell", "run-as", "com.voidsower.app", "chmod", "660", "shared_prefs/FlutterSharedPreferences.xml"])
  time.sleep(0.5)


def main():
  os.makedirs(SCREENSHOTS_DIR, exist_ok=True)
  os.makedirs(ASSETS_DIR, exist_ok=True)

  # =========================================================================
  # Phase 1: Pro Unlocked Suite
  # =========================================================================
  print("\n[Phase 1] Seeding Pro Entitlement & Initializing App...")
  seed_prefs(pro_unlocked=True, completed_tutorial=False, high_score=12480)

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

  # Screenshot 01: Tactical Combat Grid (Active combat corridor with enemies, aligned dreadnought, capacitor ring)
  print("[Combat] Capturing 01_tactical_combat_grid.png...")
  capture("01_tactical_combat_grid.png")
  shutil.copyfile(
      os.path.join(SCREENSHOTS_DIR, "01_tactical_combat_grid.png"),
      os.path.join(ASSETS_DIR, "phone_01_tactical_combat_grid.png"),
  )

  # Screenshot 07: Bao Orbital Codex (Tap PAUSE at x=889, y=330, then RULES at x=671, y=1740)
  print("[Codex] Opening Tactical Pause menu...")
  tap(889, 330)
  time.sleep(1.0)
  print("[Codex] Opening Bao Codex dialog...")
  tap(671, 1740)
  time.sleep(1.2)
  capture("07_bao_orbital_codex.png")
  shutil.copyfile(
      os.path.join(SCREENSHOTS_DIR, "07_bao_orbital_codex.png"),
      os.path.join(ASSETS_DIR, "phone_03_bao_codex.png"),
  )
  print("[Codex] Dismissing Bao Codex...")
  keyevent(4)
  time.sleep(0.8)

  # Navigate to Star Map: Tap PAUSE at x=889, y=330, then MAP at x=310, y=1740
  print("[Map] Opening Tactical Pause to navigate to Star Map...")
  tap(889, 330)
  time.sleep(1.0)
  tap(310, 1740)
  time.sleep(2.0)

  # Screenshot 05: Multi-Theater Campaign Map (Kilwa Basin, Phantom Drift, Void Swarm)
  print("[Map] Capturing 05_kilwa_basin_campaign_map.png...")
  capture("05_kilwa_basin_campaign_map.png")

  # Screenshot 04: Orbital Fleet Hangar (Tap Rocket icon at x=690, y=240 in Map AppBar)
  print("[Hangar] Opening Fleet Hangar dialog...")
  tap(690, 240)
  time.sleep(1.2)
  capture("04_orbital_fleet_hangar.png")
  shutil.copyfile(
      os.path.join(SCREENSHOTS_DIR, "04_orbital_fleet_hangar.png"),
      os.path.join(ASSETS_DIR, "phone_06_hangar.png"),
  )
  keyevent(4)
  time.sleep(0.8)

  # Screenshot 08: Pilot Telemetry Dashboard (Tap Profile icon at x=1050, y=240 in Map AppBar)
  print("[Profile] Opening Pilot Dossier modal...")
  tap(1050, 240)
  time.sleep(1.2)
  capture("08_pilot_telemetry_dashboard.png")
  shutil.copyfile(
      os.path.join(SCREENSHOTS_DIR, "08_pilot_telemetry_dashboard.png"),
      os.path.join(ASSETS_DIR, "phone_04_pilot_dossier.png"),
  )
  keyevent(4)
  time.sleep(0.8)

  # Switch to Phantom Drift Theater (tap tab at x=670, y=500) and launch Sector 10
  print("[Theater] Switching to Phantom Drift theater (x=670, y=500)...")
  tap(670, 500)
  time.sleep(1.0)
  print("[Theater] Tapping ENGAGE on Sector 10 (x=830, y=1280)...")
  tap(830, 1280)
  time.sleep(0.8)
  print("[Theater] Launching battle (x=500, y=2800)...")
  tap(500, 2800)
  time.sleep(1.5)

  # Screenshot 02: Quadratic Lance Discharge
  # Select Bay 10 (has cores) and fire Axial Discharge
  print("[Combat] Discharging Axial Particle Lance in Phantom Drift...")
  tap(440, 2520)  # Select Bay 10
  time.sleep(0.3)
  tap(500, 2800)  # AXIAL DISCHARGE
  time.sleep(0.15)
  capture("02_quadratic_lance_discharge.png")
  shutil.copyfile(
      os.path.join(SCREENSHOTS_DIR, "02_quadratic_lance_discharge.png"),
      os.path.join(ASSETS_DIR, "phone_02_quadratic_lances.png"),
  )
  time.sleep(1.0)

  # Return to Map and launch Sector 1 for clean AI victory sequence
  print("[Victory] Returning to Star Map to launch Kilwa Basin S1...")
  tap(889, 330)  # Pause
  time.sleep(1.0)
  tap(310, 1740) # Map
  time.sleep(1.5)
  tap(250, 500)  # Kilwa Basin tab
  time.sleep(0.8)
  tap(830, 1265) # Sector 1 REPLAY / ENGAGE
  time.sleep(0.8)
  tap(675, 2850) # Launch battle
  time.sleep(1.8)

  # Activate AI Solver in right HUD (x=1020, y=230) to eliminate invaders and achieve Victory
  print("[Solver] Activating AI Tactical Solver to clear sector...")
  tap(1020, 230)

  # Poll for victory modal
  print("[Victory] Waiting for Sector Liberation modal...")
  modal_captured = False
  for attempt in range(40):
    time.sleep(0.5)
    dest_path = os.path.join(SCREENSHOTS_DIR, "06_sector_liberation_victory.png")
    with open(dest_path, "wb") as f:
      subprocess.run(["adb", "-s", DEVICE, "exec-out", "screencap", "-p"], stdout=f)
    if attempt < 4:
      continue
    try:
      im = Image.open(dest_path)
      arr = np.array(im)
      # Check for gold military crest in center: y: 800..1200, x: 550..800
      crop = arr[800:1200, 550:800]
      gold_pts = np.where(
          (crop[:, :, 0] > 220) & (crop[:, :, 1] > 160) & (crop[:, :, 2] < 50)
      )
      if len(gold_pts[0]) > 400:
        print(f"[Victory] Captured 06_sector_liberation_victory.png (attempt {attempt + 1})!")
        modal_captured = True
        break
    except Exception as e:
      pass

  if not modal_captured:
    print("[Victory] Reached timeout, keeping latest frame for 06_sector_liberation_victory.png")

  shutil.copyfile(
      os.path.join(SCREENSHOTS_DIR, "06_sector_liberation_victory.png"),
      os.path.join(ASSETS_DIR, "phone_05_sector_liberation.png"),
  )

  # =========================================================================
  # Phase 2: Free Tier -> Capture Pro Upgrade Modal
  # =========================================================================
  print("\n[Phase 2] Seeding Free Tier & Capturing Pro Commander Modal...")
  seed_prefs(pro_unlocked=False, completed_tutorial=True, high_score=3400)
  adb_cmd(["shell", "am", "start", "-n", "com.voidsower.app/.MainActivity"])
  time.sleep(3.5)

  # Tap PAUSE at x=889, y=330, then MAP at x=310, y=1740
  tap(889, 330)
  time.sleep(1.0)
  tap(310, 1740)
  time.sleep(2.0)

  # In Free Tier, tapping Phantom Drift tab at x=670, y=500 directly opens ProUpgradeModal!
  print("[Pro Modal] Tapping locked Phantom Drift tab to trigger Pro Upgrade Modal...")
  tap(670, 500)
  time.sleep(1.2)
  capture("09_pro_commander_upgrade.png")
  shutil.copyfile(
      os.path.join(SCREENSHOTS_DIR, "09_pro_commander_upgrade.png"),
      os.path.join(ASSETS_DIR, "phone_07_pro_commander.png"),
  )

  # Re-seed Pro entitlement so device remains unlocked for general usage
  print("\n[Cleanup] Re-seeding Pro entitlement...")
  seed_prefs(pro_unlocked=True, completed_tutorial=True, high_score=12480)

  print("\n[Complete] All Play Store phone screenshots recaptured successfully!")


if __name__ == "__main__":
  main()
