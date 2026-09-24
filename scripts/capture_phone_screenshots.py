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
  temp_path = os.path.join("/tmp", f"cap_{dest_name}")
  print(f"[Capture] Grabbing {dest_name}...")
  with open(temp_path, "wb") as f:
    subprocess.run(["adb", "-s", DEVICE, "exec-out", "screencap", "-p"], stdout=f, check=True)
  if os.path.exists(temp_path) and os.path.getsize(temp_path) > 10000:
    shutil.copyfile(temp_path, dest_path)
    print(f"[Saved] -> {dest_path} ({os.path.getsize(dest_path)} bytes)")
    return dest_path
  else:
    print(f"[Error] Failed to capture valid screenshot for {dest_name}")
    return None


def seed_prefs(pro_unlocked=True, completed_tutorial=False, high_score=34820, liberated_sectors=6):
  adb_cmd(["shell", "settings", "put", "secure", "immersive_mode_confirmations", "confirmed"])
  adb_cmd(["shell", "am", "force-stop", "com.voidsower.app"])
  time.sleep(0.5)
  adb_cmd(["shell", "pm", "clear", "com.voidsower.app"])
  time.sleep(1.0)

  profile_json = (
      '{"id":"pilot_default","callsign":"Vanguard-01","insignia":"shonaStar",'
      '"lifetimeScore":34820,"enemiesDestroyed":142,"lancesFired":86,"maxCascadeLaps":4,'
      '"missionsPlayed":28,"victories":22,"defeats":6,"flawlessVictories":14,"totalSeedsSown":340,'
      '"flakBurstsTriggered":24,"totalCoresSaved":184,"currentStreak":5,"longestStreak":12,'
      '"lastPlayedDate":"2026-09-19","totalFlightTimeSeconds":4820,'
      '"chassisSorties":{"mk1_bastion":16,"mk2_monsoon":12},'
      '"campaignSorties":{"kilwa_basin":18,"phantom_drift":10},'
      '"unlockedAchievements":["first_sortie","flawless_defense","cascade_master","iron_hull"],'
      '"isGoogleLinked":false}'
  )
  escaped_profile = profile_json.replace('"', '&quot;')

  pref_xml = (
      '<?xml version="1.0" encoding="utf-8" standalone="yes" ?>\n'
      '<map>\n'
      f'    <boolean name="flutter.void_sower_pro_unlocked" value="{"true" if pro_unlocked else "false"}" />\n'
      f'    <boolean name="flutter.void_sower_completed_tutorial" value="{"true" if completed_tutorial else "false"}" />\n'
      f'    <int name="flutter.void_sower_high_score" value="{high_score}" />\n'
      f'    <int name="flutter.void_sower_liberated_sectors" value="{liberated_sectors}" />\n'
      '    <int name="flutter.void_sower_sector_stars_1" value="3" />\n'
      '    <int name="flutter.void_sower_sector_stars_2" value="3" />\n'
      '    <int name="flutter.void_sower_sector_stars_3" value="3" />\n'
      '    <int name="flutter.void_sower_sector_stars_4" value="2" />\n'
      '    <int name="flutter.void_sower_sector_stars_5" value="2" />\n'
      f'    <string name="flutter.void_sower_user_profile">{escaped_profile}</string>\n'
      '    <string name="flutter.void_sower_active_profile_id">pilot_default</string>\n'
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

  # Dismiss any lingering system dialogs
  keyevent(4)
  time.sleep(0.5)

  # =========================================================================
  # Phase 1: Pro Unlocked Suite
  # =========================================================================
  print("\n[Phase 1] Seeding Pro Entitlement & Initializing App...")
  seed_prefs(pro_unlocked=True, completed_tutorial=False, high_score=34820, liberated_sectors=6)

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

  # Screenshot 07: Bao Tactical Directives (Tap PAUSE at x=1240, y=225, then DIRECTIVES at x=672, y=1820)
  print("[Directives] Opening Tactical Pause menu...")
  tap(1240, 225)
  time.sleep(1.0)
  print("[Directives] Opening Tactical Directives modal (tap DIRECTIVES at x=672, y=1820)...")
  tap(672, 1820)
  time.sleep(1.2)
  capture("07_bao_orbital_codex.png")
  shutil.copyfile(
      os.path.join(SCREENSHOTS_DIR, "07_bao_orbital_codex.png"),
      os.path.join(ASSETS_DIR, "phone_03_bao_codex.png"),
  )
  # Dismiss Directives and open Pause menu to reach Star Map
  print("[Directives] Dismissing Tactical Directives...")
  keyevent(4)
  time.sleep(1.0)

  # Navigate to Star Map: Must open Pause first because Directives closed pause menu
  print("[Map] Opening Pause menu to navigate to Star Map...")
  tap(1240, 225)
  time.sleep(1.2)
  print("[Map] Navigating to Campaign Star Map from Pause menu (tap MAP at x=310, y=1820)...")
  tap(310, 1820)
  time.sleep(2.0)

  # Screenshot 05: Multi-Theater Campaign Map (Kilwa Basin, Phantom Drift, Void Swarm)
  print("[Map] Capturing 05_kilwa_basin_campaign_map.png...")
  capture("05_kilwa_basin_campaign_map.png")

  # Screenshot 04: Orbital Fleet Hangar (Tap FLEET tab at x=336, y=250 in top nav bar)
  print("[Hangar] Opening Fleet Hangar modal from top nav bar...")
  tap(336, 250)
  time.sleep(1.2)
  capture("04_orbital_fleet_hangar.png")
  shutil.copyfile(
      os.path.join(SCREENSHOTS_DIR, "04_orbital_fleet_hangar.png"),
      os.path.join(ASSETS_DIR, "phone_06_hangar.png"),
  )
  keyevent(4)
  time.sleep(0.8)

  # Screenshot 08: Pilot Telemetry Dashboard (Tap PILOT tab at x=560, y=250 in top nav bar)
  print("[Telemetry] Opening Pilot Dossier dashboard from top nav bar...")
  tap(560, 250)
  time.sleep(1.5)
  capture("08_pilot_telemetry_dashboard.png")
  shutil.copyfile(
      os.path.join(SCREENSHOTS_DIR, "08_pilot_telemetry_dashboard.png"),
      os.path.join(ASSETS_DIR, "phone_04_pilot_dossier.png"),
  )
  keyevent(4)
  time.sleep(0.8)

  # Launch Sector 6 (Lindi Ridge Objective) to capture quadratic lance discharge
  print("[Combat] Launching Lindi Ridge Sector 6 (tap ENGAGE at x=1100, y=2430)...")
  tap(1100, 2430)
  time.sleep(2.0)

  # Screenshot 02: Quadratic Lance Discharge
  print("[Combat] Discharging Axial Particle Lance (tap AXIAL DISCHARGE at x=672, y=2800)...")
  tap(672, 2800)
  time.sleep(0.18)
  capture("02_quadratic_lance_discharge.png")
  shutil.copyfile(
      os.path.join(SCREENSHOTS_DIR, "02_quadratic_lance_discharge.png"),
      os.path.join(ASSETS_DIR, "phone_02_quadratic_lances.png"),
  )
  time.sleep(1.0)

  # Return to Map and launch Sector 1 with AI auto-solver for clean victory sequence
  print("[Victory] Returning to Star Map...")
  tap(1240, 225)  # Pause
  time.sleep(1.0)
  tap(310, 1820)  # Map
  time.sleep(1.5)

  print("[Victory] Launching Sector 1 with AI Auto-Solver (tap AI button at x=890, y=1040)...")
  tap(890, 1040)
  time.sleep(4.0)

  # Poll for victory modal (Sector 1 clears in ~4-6 seconds with AI auto-solve)
  print("[Victory] Waiting for Sector Liberation modal...")
  modal_captured = False
  for attempt in range(25):
    time.sleep(0.5)
    temp_path = os.path.join("/tmp", "temp_victory.png")
    with open(temp_path, "wb") as f:
      subprocess.run(["adb", "-s", DEVICE, "exec-out", "screencap", "-p"], stdout=f)
    if os.path.exists(temp_path) and os.path.getsize(temp_path) > 10000:
      try:
        im = Image.open(temp_path)
        arr = np.array(im)
        # Check center region where VictoryDialog sits (y: 800..1800, x: 200..1144)
        crop = arr[800:1800, 200:1144]
        # Look for gold and cyan accents of the victory card
        gold_pts = np.where((crop[:, :, 0] > 180) & (crop[:, :, 1] > 140) & (crop[:, :, 2] < 70))
        if len(gold_pts[0]) > 300:
          dest_path = os.path.join(SCREENSHOTS_DIR, "06_sector_liberation_victory.png")
          shutil.copyfile(temp_path, dest_path)
          print(f"[Victory] Captured 06_sector_liberation_victory.png (attempt {attempt + 1}, {os.path.getsize(dest_path)} bytes)!")
          modal_captured = True
          break
      except Exception as e:
        pass

  if not modal_captured:
    print("[Victory] Timeout reached, capturing current state as fallback for 06_sector_liberation_victory.png")
    capture("06_sector_liberation_victory.png")

  shutil.copyfile(
      os.path.join(SCREENSHOTS_DIR, "06_sector_liberation_victory.png"),
      os.path.join(ASSETS_DIR, "phone_05_sector_liberation.png"),
  )

  # =========================================================================
  # Phase 2: Free Tier -> Capture Pro Upgrade Modal
  # =========================================================================
  print("\n[Phase 2] Seeding Free Tier & Capturing Pro Commander Modal...")
  seed_prefs(pro_unlocked=False, completed_tutorial=True, high_score=3400, liberated_sectors=1)
  adb_cmd(["shell", "am", "start", "-n", "com.voidsower.app/.MainActivity"])
  time.sleep(3.5)

  # Tap PAUSE at x=1240, y=225, then MAP at x=310, y=1820
  tap(1240, 225)
  time.sleep(1.0)
  tap(310, 1820)
  time.sleep(2.0)

  # In Free Tier, switch to Phantom Drift (locked theater) at x=670, y=680
  print("[Pro Modal] Switching to locked Phantom Drift theater (x=670, y=680)...")
  tap(670, 680)
  time.sleep(1.2)
  print("[Pro Modal] Tapping locked Sector 11 card (x=672, y=1340)...")
  tap(672, 1340)
  time.sleep(1.2)
  print("[Pro Modal] Tapping INSTANTLY UNLOCK ALL SECTORS • PRO (x=672, y=2710)...")
  tap(672, 2710)
  time.sleep(1.5)
  capture("09_pro_commander_upgrade.png")
  shutil.copyfile(
      os.path.join(SCREENSHOTS_DIR, "09_pro_commander_upgrade.png"),
      os.path.join(ASSETS_DIR, "phone_07_pro_commander.png"),
  )

  # Re-seed Pro entitlement so device remains unlocked for general usage
  print("\n[Cleanup] Re-seeding Pro entitlement...")
  seed_prefs(pro_unlocked=True, completed_tutorial=True, high_score=34820, liberated_sectors=6)

  print("\n[Complete] All Play Store phone screenshots recaptured successfully!")


if __name__ == "__main__":
  main()
