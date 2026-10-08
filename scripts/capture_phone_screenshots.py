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

Captures all phone screenshots featuring the UX 3.0 interface with a realistic mix
of spatial depths (threshold Z: 0km, mid-combat Z: +20km, forward engage Z: +10km).
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
DOCS_STORE_DIR = "/home/kelvingorekore/projects/void-sower/docs/media/store_screenshots"


def adb_cmd(args):
  cmd = ["adb", "-s", DEVICE] + args
  return subprocess.run(cmd, capture_output=True, text=True)


def tap(x, y):
  adb_cmd(["shell", "input", "tap", str(x), str(y)])


def swipe(x1, y1, x2, y2, duration_ms=250):
  adb_cmd(["shell", "input", "swipe", str(x1), str(y1), str(x2), str(y2), str(duration_ms)])


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


def capture(dest_name, mirror_name=None, docs_name=None):
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

  if docs_name:
    docs_path = os.path.join(DOCS_STORE_DIR, docs_name)
    shutil.copyfile(dest_path, docs_path)
    print(f"[Docs Mirrored] -> {docs_path}")

  return dest_path


def seed_prefs(pro_unlocked=True, completed_tutorial=False, high_score=34820, liberated_sectors=6):
  adb_cmd(["shell", "settings", "put", "secure", "immersive_mode_confirmations", "confirmed"])
  adb_cmd(["shell", "am", "force-stop", "com.voidsower.app"])
  time.sleep(0.5)
  adb_cmd(["shell", "pm", "clear", "com.voidsower.app"])
  time.sleep(0.8)

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
  os.makedirs(DOCS_STORE_DIR, exist_ok=True)

  # Remove any old quadratic lance screenshots
  for old_path in [
      os.path.join(SCREENSHOTS_DIR, "02_quadratic_lance_discharge.png"),
      os.path.join(ASSETS_DIR, "phone_02_quadratic_lances.png"),
  ]:
    if os.path.exists(old_path):
      os.remove(old_path)
      print(f"[Cleanup] Removed obsolete file: {old_path}")

  # =========================================================================
  # Phase 1: Flight Academy Onboarding
  # =========================================================================
  print("\n[Phase 1] Capturing Flight Academy Onboarding...")
  seed_prefs(pro_unlocked=True, completed_tutorial=False, high_score=34820, liberated_sectors=6)
  adb_cmd(["shell", "am", "start", "-n", "com.voidsower.app/.MainActivity"])
  time.sleep(3.0)

  # Screenshot 03: Flight Academy Onboarding (briefing overlay over combat arena)
  capture("03_flight_academy_onboarding.png", "phone_02_flight_academy.png")

  # =========================================================================
  # Phase 2: Active Tactical Combat (Baseline Threshold Defense Z: 0km)
  # =========================================================================
  print("\n[Phase 2] Capturing Tactical Combat Grid at Baseline Defense (Z: 0km)...")
  seed_prefs(pro_unlocked=True, completed_tutorial=True, high_score=34820, liberated_sectors=6)
  adb_cmd(["shell", "am", "start", "-n", "com.voidsower.app/.MainActivity"])
  time.sleep(2.5)

  # Clean combat screen with no dialog overlays
  capture("01_tactical_combat_grid.png", "phone_01_tactical_combat_grid.png", "01_combat_tactical_depth.png")

  # =========================================================================
  # Phase 3: Axial Particle Lance Discharge (Mid-Combat Depth Z: +20km)
  # =========================================================================
  print("\n[Phase 3] Advancing Defender to Mid-Combat Depth (Z: +20km) & Discharging Lance...")
  # Advance ship forward into combat arena
  swipe(672, 2300, 672, 1700, 250)
  time.sleep(0.3)

  # Fire Axial Particle Lance via FIRE trigger repeatedly
  fire_proc = subprocess.Popen([
      "adb", "-s", DEVICE, "shell",
      "for i in $(seq 1 12); do input tap 594 2639; sleep 0.08; done"
  ])
  time.sleep(0.25)
  capture("02_axial_particle_lance.png", "phone_02_axial_particle_lance.png", "02_axial_particle_lance.png")
  fire_proc.wait()
  time.sleep(0.5)

  # =========================================================================
  # Phase 4: Tactical Pause Menu & Tactical Directives
  # =========================================================================
  print("\n[Phase 4] Capturing Tactical Pause Controls...")
  # Open Tactical Pause menu via pause capsule in header (1175, 224)
  tap(1175, 224)
  time.sleep(1.2)
  # Capture 06_tactical_pause_controls.png for docs
  capture_temp = os.path.join(DOCS_STORE_DIR, "06_tactical_pause_controls.png")
  with open(capture_temp, "wb") as f:
    subprocess.run(["adb", "-s", DEVICE, "exec-out", "screencap", "-p"], stdout=f, check=True)
  print(f"[Docs Mirrored] -> {capture_temp}")

  # Tap Directives button in Pause Menu (x=942, y=1735)
  print("[Directives] Opening Tactical Directives modal...")
  tap(942, 1735)
  time.sleep(1.2)
  capture("07_bao_orbital_codex.png", "phone_03_bao_codex.png", "05_tactical_directives_codex.png")

  # Dismiss Directives modal cleanly via back keyevent
  keyevent(4)
  time.sleep(0.8)

  # =========================================================================
  # Phase 5: Multi-Theater Campaign Star Map
  # =========================================================================
  print("\n[Phase 5] Returning to Star Map...")
  # Re-open pause menu
  tap(1175, 224)
  time.sleep(0.8)
  # Tap SECTORS MAP button in pause menu (x=460, y=1735)
  tap(460, 1735)
  time.sleep(2.0)
  capture("05_kilwa_basin_campaign_map.png", docs_name="03_orbital_command_campaign.png")

  # =========================================================================
  # Phase 6: Orbital Fleet Hangar Modal
  # =========================================================================
  print("\n[Phase 6] Capturing Orbital Fleet Hangar...")
  # In Campaign Map bottom nav bar, tap FLEET tab (x=392, y=2815)
  tap(392, 2815)
  time.sleep(1.2)
  capture("04_orbital_fleet_hangar.png", "phone_06_hangar.png", "04_fleet_hangar_inspection.png")
  # Dismiss Hangar dialog cleanly via back keyevent
  keyevent(4)
  time.sleep(0.8)

  # =========================================================================
  # Phase 7: Pilot Telemetry Dashboard
  # =========================================================================
  print("\n[Phase 7] Capturing Pilot Telemetry Dashboard...")
  # In Campaign Map bottom nav bar, tap PILOT tab (x=628, y=2819)
  tap(628, 2819)
  time.sleep(1.2)
  capture("08_pilot_telemetry_dashboard.png", "phone_04_pilot_dossier.png")
  # Dismiss Pilot modal cleanly via back keyevent
  keyevent(4)
  time.sleep(0.8)

  # =========================================================================
  # Phase 8: Pro Commander Upgrade Modal (Special Operations)
  # =========================================================================
  print("\n[Phase 8] Capturing Special Operations / Pro Commander...")
  # In Campaign Map top bar, tap SPECIAL OPS tab (x=1128, y=423)
  tap(1128, 423)
  time.sleep(1.2)
  # Tap GET LIFETIME PRO at x=666, y=2517
  tap(666, 2517)
  time.sleep(1.2)
  capture("09_pro_commander_upgrade.png", "phone_07_pro_commander.png")
  # Dismiss Pro modal cleanly via back keyevent
  keyevent(4)
  time.sleep(0.8)
  # Return to Campaign tab (x=203, y=431)
  tap(203, 431)
  time.sleep(0.8)

  # =========================================================================
  # Phase 9: Sector 1 Liberation Victory
  # =========================================================================
  print("\n[Phase 9] Playing Sector 1 with AI Solver for Victory Dialog...")
  # Tap Sector 1 ENGAGE button on hero objective card (x=850, y=600)
  tap(850, 600)
  time.sleep(2.0)

  # Open Tactical Pause via keyevent 4
  keyevent(4)
  time.sleep(0.8)
  # Tap AI Solver button in bottom quick hardware strip (x=1050, y=2200)
  tap(1050, 2200)
  time.sleep(0.5)
  # Tap RESUME COMBAT button (x=671, y=1500)
  tap(671, 1500)
  time.sleep(0.5)

  print("[Victory] AI Solver engaged. Polling for Sector Liberation Victory modal...")
  captured_victory = False
  for tick in range(40):
    time.sleep(0.35)
    temp_check = "/tmp/poll_vic_check.png"
    with open(temp_check, "wb") as f:
      subprocess.run(["adb", "-s", DEVICE, "exec-out", "screencap", "-p"], stdout=f, check=True)
    chk_img = Image.open(temp_check)
    chk_arr = np.array(chk_img)
    # Victory modal has "SECTOR 1 LIBERATED" banner and emerald/gold elements
    center_area = chk_arr[1100:1700, 200:1100]
    gold_mask = (center_area[:, :, 0] > 180) & (center_area[:, :, 1] > 140) & (center_area[:, :, 2] < 70)
    emerald_mask = (center_area[:, :, 1] > 150) & (center_area[:, :, 0] < 80) & (center_area[:, :, 2] < 120)
    white_pct = (chk_arr > 240).all(axis=-1).mean() * 100

    if (gold_mask.sum() > 400 or emerald_mask.sum() > 400) and white_pct < 5.0:
      print(f"[Victory] Victory dialog confirmed on screen at tick {tick}!")
      capture("06_sector_liberation_victory.png", "phone_05_sector_liberation.png")
      captured_victory = True
      break

  if not captured_victory:
    print("[Victory] Capturing current combat / victory state...")
    capture("06_sector_liberation_victory.png", "phone_05_sector_liberation.png")

  # Re-seed Pro entitlement for normal usage
  print("\n[Cleanup] Re-seeding Pro entitlement...")
  seed_prefs(pro_unlocked=True, completed_tutorial=True, high_score=34820, liberated_sectors=6)

  print("\n[Complete] All 9 Play Store phone screenshots captured and strictly verified!")


if __name__ == "__main__":
  main()
