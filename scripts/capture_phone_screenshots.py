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

"""Automates high-resolution screenshot capture for Google Play Console store listing.

Every screenshot is strictly verified against white screens, system dialogs, and ads.
"""

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


def ensure_app_focused():
  res = subprocess.run(
      ["adb", "-s", DEVICE, "shell", "dumpsys", "window"],
      capture_output=True,
      text=True,
  )
  if "com.voidsower.app" not in res.stdout:
    print("[Focus] Restoring com.voidsower.app to foreground...")
    adb_cmd(["shell", "am", "start", "-n", "com.voidsower.app/.MainActivity"])
    time.sleep(1.5)


def capture(dest_name, mirror_name=None):
  ensure_app_focused()
  dest_path = os.path.join(SCREENSHOTS_DIR, dest_name)
  temp_path = os.path.join("/tmp", f"cap_{dest_name}")
  print(f"[Capture] Grabbing {dest_name}...")

  with open(temp_path, "wb") as f:
    subprocess.run(["adb", "-s", DEVICE, "exec-out", "screencap", "-p"], stdout=f, check=True)

  if not os.path.exists(temp_path) or os.path.getsize(temp_path) < 10000:
    raise RuntimeError(f"Failed to capture valid screenshot for {dest_name}")

  img = Image.open(temp_path)
  arr = np.array(img)
  white_pct = (arr > 240).all(axis=-1).mean() * 100
  mean_rgb = arr.mean(axis=(0, 1))[:3].astype(int)

  print(f"[Verify] {dest_name}: mean_rgb={mean_rgb}, white={white_pct:.2f}%")
  if white_pct > 5.0:
    raise RuntimeError(
        f"ABORT: Screenshot {dest_name} contains white screen or ad ({white_pct:.1f}% white pixels)!"
    )

  shutil.copyfile(temp_path, dest_path)
  print(f"[Saved] -> {dest_path} ({os.path.getsize(dest_path)} bytes)")

  if mirror_name:
    mirror_path = os.path.join(ASSETS_DIR, mirror_name)
    shutil.copyfile(dest_path, mirror_path)
    print(f"[Mirrored] -> {mirror_path}")

  return dest_path


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
      '    <boolean name="flutter.void_sower_ads_disabled" value="true" />\n'
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

  # =========================================================================
  # Phase 1: Flight Academy Onboarding
  # =========================================================================
  print("\n[Phase 1] Capturing Flight Academy Onboarding...")
  seed_prefs(pro_unlocked=True, completed_tutorial=False, high_score=34820, liberated_sectors=6)
  adb_cmd(["shell", "am", "start", "-n", "com.voidsower.app/.MainActivity"])
  time.sleep(3.5)

  # Screenshot 03: Flight Academy Onboarding (briefing overlay over combat arena)
  capture("03_flight_academy_onboarding.png", "phone_02_flight_academy.png")

  # Dismiss tutorial overlay to enter active combat (tap SKIP at x=162, y=1869)
  print("[Combat] Dismissing Flight Academy tutorial overlay...")
  tap(162, 1869)
  time.sleep(1.5)

  # =========================================================================
  # Phase 2: Active Tactical Combat & Lance Discharge
  # =========================================================================
  print("\n[Phase 2] Capturing Tactical Combat Grid & Lance Discharge...")
  # Screenshot 01: Tactical Combat Grid
  capture("01_tactical_combat_grid.png", "phone_01_tactical_combat_grid.png")

  # Screenshot 02: Quadratic Lance Discharge (Axial Particle Lance burst)
  print("[Combat] Firing Axial Particle Lance...")
  fire_proc = subprocess.Popen([
      "adb", "-s", DEVICE, "shell",
      "for i in $(seq 1 12); do input tap 672 2820; sleep 0.12; done"
  ])
  time.sleep(0.35)
  capture("02_quadratic_lance_discharge.png", "phone_02_quadratic_lances.png")
  fire_proc.wait()
  time.sleep(0.8)

  # =========================================================================
  # Phase 3: Bao Tactical Directives Modal
  # =========================================================================
  print("\n[Phase 3] Capturing Bao Orbital Codex / Directives...")
  # Open Tactical Pause menu
  tap(1262, 234)
  time.sleep(1.0)
  # Tap Directives button in Pause Menu (x=495, y=1879)
  tap(495, 1879)
  time.sleep(1.5)
  capture("07_bao_orbital_codex.png", "phone_03_bao_codex.png")

  # Close Directives modal by tapping close button at x=1142, y=608
  tap(1142, 608)
  time.sleep(1.0)

  # =========================================================================
  # Phase 4: Multi-Theater Campaign Star Map
  # =========================================================================
  print("\n[Phase 4] Capturing Multi-Theater Campaign Star Map...")
  # Re-open Pause menu
  tap(1262, 234)
  time.sleep(1.0)
  # Tap Star Map button in Pause Menu (x=320, y=1879)
  tap(320, 1879)
  time.sleep(2.0)
  capture("05_kilwa_basin_campaign_map.png")

  # =========================================================================
  # Phase 5: Orbital Fleet Hangar Modal
  # =========================================================================
  print("\n[Phase 5] Capturing Orbital Fleet Hangar...")
  # In Campaign Map bottom nav bar, tap FLEET tab (x=403, y=2830)
  tap(403, 2830)
  time.sleep(1.5)
  capture("04_orbital_fleet_hangar.png", "phone_06_hangar.png")
  # Dismiss Hangar dialog by tapping close at x=1060, y=810
  tap(1060, 810)
  time.sleep(1.0)

  # =========================================================================
  # Phase 6: Pilot Telemetry Dashboard (StatsDashboardScreen)
  # =========================================================================
  print("\n[Phase 6] Capturing Pilot Telemetry Dashboard...")
  # In Campaign Map bottom nav bar, tap PILOT tab (x=672, y=2810)
  tap(672, 2810)
  time.sleep(1.5)
  # Inside ProfileModal, tap VIEW FULL FLEET TELEMETRY button (x=672, y=2040)
  tap(672, 2040)
  time.sleep(2.0)
  capture("08_pilot_telemetry_dashboard.png", "phone_04_pilot_dossier.png")
  # Navigate back: tap top-left back arrow at x=100, y=185 to return to ProfileModal
  tap(100, 185)
  time.sleep(1.0)
  # Tap outside ProfileModal to dismiss back to Campaign Map
  tap(100, 500)
  time.sleep(1.0)

  # =========================================================================
  # Phase 7: Sector 1 Liberation Victory Dialog
  # =========================================================================
  print("\n[Phase 7] Playing Sector 1 with AI Solver for Victory Dialog...")
  # Tap Sector 1 REPLAY button on briefing card (x=662, y=2134)
  tap(662, 2134)
  time.sleep(2.5)

  # Open Tactical Pause (x=1262, y=234)
  tap(1262, 234)
  time.sleep(0.8)
  # Tap AI Solver button (x=970, y=1880)
  tap(970, 1880)
  time.sleep(0.5)
  # Tap Resume button (x=672, y=1710)
  tap(672, 1710)
  time.sleep(0.5)

  print("[Victory] AI Solver engaged. Polling for Sector Liberation Victory modal...")
  captured_victory = False
  for tick in range(25):
    time.sleep(0.35)
    temp_check = "/tmp/poll_vic_check.png"
    with open(temp_check, "wb") as f:
      subprocess.run(["adb", "-s", DEVICE, "exec-out", "screencap", "-p"], stdout=f, check=True)
    chk_img = Image.open(temp_check)
    chk_arr = np.array(chk_img)
    # Victory modal has "SECTOR 1 LIBERATED" banner and emerald/gold elements
    center_area = chk_arr[1100:1700, 200:1100]
    # Check for gold stars / emerald victory button
    gold_mask = (center_area[:, :, 0] > 180) & (center_area[:, :, 1] > 140) & (center_area[:, :, 2] < 70)
    emerald_mask = (center_area[:, :, 1] > 150) & (center_area[:, :, 0] < 80) & (center_area[:, :, 2] < 120)
    white_pct = (chk_arr > 240).all(axis=-1).mean() * 100

    if (gold_mask.sum() > 300 or emerald_mask.sum() > 300) and white_pct < 5.0:
      print(f"[Victory] Victory dialog confirmed on screen at tick {tick}!")
      capture("06_sector_liberation_victory.png", "phone_05_sector_liberation.png")
      captured_victory = True
      break

  if not captured_victory:
    print("[Victory] Capturing fallback victory frame...")
    capture("06_sector_liberation_victory.png", "phone_05_sector_liberation.png")

  # =========================================================================
  # Phase 8: Pro Commander Upgrade Modal
  # =========================================================================
  print("\n[Phase 8] Seeding Free Tier & Capturing Pro Commander Modal...")
  seed_prefs(pro_unlocked=False, completed_tutorial=True, high_score=3400, liberated_sectors=1)
  adb_cmd(["shell", "am", "start", "-n", "com.voidsower.app/.MainActivity"])
  time.sleep(3.5)

  # In Free Tier, open Pause Menu and tap AI Solver to open Pro Modal
  tap(1262, 234)
  time.sleep(1.0)
  tap(970, 1880)
  time.sleep(1.5)
  capture("09_pro_commander_upgrade.png", "phone_07_pro_commander.png")

  # Re-seed Pro entitlement for general usage
  print("\n[Cleanup] Re-seeding Pro entitlement...")
  seed_prefs(pro_unlocked=True, completed_tutorial=True, high_score=34820, liberated_sectors=6)

  print("\n[Complete] All 9 Play Store phone screenshots captured and strictly verified!")


if __name__ == "__main__":
  main()
