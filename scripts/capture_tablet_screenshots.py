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

"""Automates high-resolution tablet (2560x1600) screenshot capture for Google Play Console."""

import os
import shutil
import subprocess
import sys
import time

SCREENSHOTS_DIR = "/home/kelvingorekore/projects/void-sower/store_listing/screenshots/tablet"


def get_device():
  res = subprocess.run(["adb", "devices"], capture_output=True, text=True)
  lines = res.stdout.strip().split("\n")[1:]
  for line in lines:
    parts = line.split()
    if len(parts) >= 2 and parts[1] == "device":
      dev = parts[0]
      size_res = subprocess.run(["adb", "-s", dev, "shell", "wm", "size"], capture_output=True, text=True)
      if "2560x1600" in size_res.stdout or "1600x2560" in size_res.stdout:
        return dev
  return "emulator-5556"


def adb_cmd(args, device):
  cmd = ["adb", "-s", device] + args
  return subprocess.run(cmd, capture_output=True, text=True)


def tap(x, y, device):
  adb_cmd(["shell", "input", "tap", str(x), str(y)], device)


def keyevent(code, device):
  adb_cmd(["shell", "input", "keyevent", str(code)], device)


def capture(dest_name, device):
  dest_path = os.path.join(SCREENSHOTS_DIR, dest_name)
  print(f"[Tablet Capture] Grabbing {dest_name}...")
  with open(dest_path, "wb") as f:
    subprocess.run(["adb", "-s", device, "exec-out", "screencap", "-p"], stdout=f)
  print(f"[Saved] -> {dest_path}")
  return dest_path


def main():
  os.makedirs(SCREENSHOTS_DIR, exist_ok=True)
  device = get_device()
  print(f"[Init] Targeting device: {device}")

  keyevent(4, device)
  time.sleep(0.5)

  adb_cmd(["shell", "settings", "put", "secure", "immersive_mode_confirmations", "confirmed"], device)

  # 1. Reset state: force-stop app, clear data, and seed persistent Pro unlock with rich profile
  print("[Init] Resetting app state & seeding Pro entitlement...")
  adb_cmd(["shell", "am", "force-stop", "com.voidsower.app"], device)
  time.sleep(0.5)
  adb_cmd(["shell", "pm", "clear", "com.voidsower.app"], device)
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
      '    <boolean name="flutter.void_sower_pro_unlocked" value="true" />\n'
      '    <boolean name="flutter.void_sower_completed_tutorial" value="false" />\n'
      '    <int name="flutter.void_sower_high_score" value="34820" />\n'
      '    <int name="flutter.void_sower_liberated_sectors" value="6" />\n'
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
  subprocess.run(["adb", "-s", device, "push", "/tmp/prefs.xml", "/data/local/tmp/prefs.xml"], check=True)
  adb_cmd(["shell", "run-as", "com.voidsower.app", "mkdir", "-p", "shared_prefs"], device)
  adb_cmd(["shell", "run-as", "com.voidsower.app", "cp", "/data/local/tmp/prefs.xml", "shared_prefs/FlutterSharedPreferences.xml"], device)
  adb_cmd(["shell", "run-as", "com.voidsower.app", "chmod", "660", "shared_prefs/FlutterSharedPreferences.xml"], device)
  time.sleep(0.5)

  # Launch App directly into Combat Arena
  print("[Launch] Clearing logcat and starting Void Sower main activity on tablet...")
  adb_cmd(["logcat", "-c"], device)
  adb_cmd(["shell", "am", "start", "-n", "com.voidsower.app/.MainActivity"], device)
  
  print("[Wait] Waiting for app first frame & simulation tick...")
  app_ready = False
  for _ in range(50):
    time.sleep(0.5)
    res = adb_cmd(["logcat", "-d", "-s", "flutter:V"], device)
    if "Tick 1" in res.stdout or "Tick 2" in res.stdout:
      print("[Wait] App initialized successfully!")
      app_ready = True
      break
  if not app_ready:
    print("[Wait] Fallback wait...")
    time.sleep(5.0)
  else:
    time.sleep(2.0)

  # 1. Screenshot 05: Flight Academy Onboarding on Tablet (appears on launch over arena)
  print("[Tablet Academy] Capturing 05_tablet_flight_academy.png...")
  capture("05_tablet_flight_academy.png", device)

  # Dismiss tutorial overlay: tap SKIP at x=1115, y=1070
  print("[Tablet Combat] Dismissing Flight Academy tutorial overlay (tap SKIP at x=1115, y=1070)...")
  tap(1115, 1070, device)
  time.sleep(1.5)

  # 2. Screenshot 01: Tactical Combat Grid on Tablet (Centered 580 dp viewport)
  print("[Tablet Combat] Capturing 01_tablet_tactical_combat.png...")
  capture("01_tablet_tactical_combat.png", device)

  # 3. Screenshot 02: Sowing Trajectory & Axial Lance
  print("[Tablet Combat] Discharging Axial Particle Lance (tap x=1280, y=1520)...")
  tap(1280, 1520, device)
  time.sleep(0.20)
  capture("02_tablet_sowing_trajectory.png", device)
  time.sleep(1.0)

  # 4. Screenshot 06: Bao Codex / Directives on Tablet (Tap PAUSE at x=1780, y=125, then DIRECTIVES at x=1280, y=990)
  print("[Tablet Codex] Opening Tactical Pause menu...")
  tap(1780, 125, device)
  time.sleep(1.2)
  print("[Tablet Codex] Opening Tactical Directives dialog (tap DIRECTIVES at x=1280, y=990)...")
  tap(1280, 990, device)
  time.sleep(1.8)
  capture("06_tablet_bao_codex.png", device)
  # Close Directives dialog via Back keyevent (returns directly to CombatScreen)
  print("[Tablet Codex] Dismissing Tactical Directives...")
  keyevent(4, device)
  time.sleep(1.0)

  # 5. Navigate to Star Map: Tap PAUSE at x=1780, y=125, then MAP at x=1030, y=990
  print("[Tablet Map] Opening Tactical Pause to navigate to Star Map...")
  tap(1780, 125, device)
  time.sleep(1.2)
  print("[Tablet Map] Tapping MAP button at x=1030, y=990...")
  tap(1030, 990, device)
  time.sleep(2.5)

  # Screenshot 03: Tablet Campaign Map
  print("[Tablet Map] Capturing 03_tablet_campaign_map.png...")
  capture("03_tablet_campaign_map.png", device)

  # 6. Screenshot 04: Tablet Fleet Hangar (tap FLEET at x=960, y=80 in top nav bar)
  print("[Tablet Hangar] Opening Fleet Hangar (tap FLEET at x=960, y=80)...")
  tap(960, 80, device)
  time.sleep(1.8)
  capture("04_tablet_fleet_hangar.png", device)
  keyevent(4, device)
  time.sleep(1.0)

  print("\n[Complete] All 6 Play Store tablet screenshots captured successfully!")


if __name__ == "__main__":
  main()
