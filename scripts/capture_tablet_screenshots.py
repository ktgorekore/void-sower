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

"""Automates high-resolution tablet screenshot capture for Google Play Store listing.

Configures the Android display to 1600x2560 @ 320dpi (10-inch portrait tablet layout),
captures all 6 tablet screenshots showcasing the UX 3.0 interface and 3D depth,
and cleanly restores the display resolution.
"""

import os
import shutil
import subprocess
import sys
import time
import numpy as np
from PIL import Image

DEVICE = "emulator-5554"
SCREENSHOTS_DIR = "/home/kelvingorekore/projects/void-sower/store_listing/screenshots/tablet"


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


def capture(dest_name, mirror_name=None):
  ensure_app_focused()
  dest_path = os.path.join(SCREENSHOTS_DIR, dest_name)
  temp_path = os.path.join("/tmp", f"cap_tablet_{dest_name}")
  print(f"[Capture Tablet] Grabbing {dest_name}...")

  with open(temp_path, "wb") as f:
    subprocess.run(["adb", "-s", DEVICE, "exec-out", "screencap", "-p"], stdout=f, check=True)

  if not os.path.exists(temp_path) or os.path.getsize(temp_path) < 10000:
    raise RuntimeError(f"Failed to capture valid screenshot for {dest_name}")

  img = Image.open(temp_path)
  arr = np.array(img)
  white_pct = (arr > 240).all(axis=-1).mean() * 100
  mean_rgb = arr.mean(axis=(0, 1))[:3].astype(int)

  print(f"[Verify Tablet] {dest_name}: mean_rgb={mean_rgb}, white={white_pct:.2f}%")
  if white_pct > 5.0:
    raise RuntimeError(
        f"ABORT: Tablet screenshot {dest_name} contains white screen or ad ({white_pct:.1f}% white pixels)!"
    )

  shutil.copyfile(temp_path, dest_path)
  print(f"[Saved] -> {dest_path} ({os.path.getsize(dest_path)} bytes)")

  if mirror_name:
    mirror_path = os.path.join(SCREENSHOTS_DIR, mirror_name)
    shutil.copyfile(dest_path, mirror_path)
    print(f"[Mirrored] -> {mirror_path}")

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
  with open("/tmp/prefs_tablet.xml", "w") as f:
    f.write(pref_xml)
  subprocess.run(["adb", "-s", DEVICE, "push", "/tmp/prefs_tablet.xml", "/data/local/tmp/prefs_tablet.xml"], check=True)
  adb_cmd(["shell", "run-as", "com.voidsower.app", "mkdir", "-p", "shared_prefs"])
  adb_cmd(["shell", "run-as", "com.voidsower.app", "cp", "/data/local/tmp/prefs_tablet.xml", "shared_prefs/FlutterSharedPreferences.xml"])
  adb_cmd(["shell", "run-as", "com.voidsower.app", "chmod", "660", "shared_prefs/FlutterSharedPreferences.xml"])
  time.sleep(0.5)


def main():
  os.makedirs(SCREENSHOTS_DIR, exist_ok=True)

  try:
    print("[Display] Setting tablet resolution (1600x2560 @ 320dpi)...")
    adb_cmd(["shell", "wm", "size", "1600x2560"])
    adb_cmd(["shell", "wm", "density", "320"])
    time.sleep(2.0)

    # =========================================================================
    # Phase 1: Tablet Flight Academy Onboarding
    # =========================================================================
    print("\n[Tablet Phase 1] Capturing Flight Academy Onboarding...")
    seed_prefs(pro_unlocked=True, completed_tutorial=False, high_score=34820, liberated_sectors=6)
    adb_cmd(["shell", "am", "start", "-n", "com.voidsower.app/.MainActivity"])
    time.sleep(3.0)
    capture("05_tablet_flight_academy.png")

    # =========================================================================
    # Phase 2: Tablet Active Tactical Combat (Baseline Z: 0km)
    # =========================================================================
    print("\n[Tablet Phase 2] Capturing Tactical Combat Grid (Z: 0km)...")
    seed_prefs(pro_unlocked=True, completed_tutorial=True, high_score=34820, liberated_sectors=6)
    adb_cmd(["shell", "am", "start", "-n", "com.voidsower.app/.MainActivity"])
    time.sleep(2.5)
    capture("01_tablet_tactical_combat.png")

    # =========================================================================
    # Phase 3: Tablet Axial Particle Lance (Mid-Combat Depth Z: +20km)
    # =========================================================================
    print("\n[Tablet Phase 3] Advancing Defender & Discharging Axial Particle Lance...")
    # Swipe ship forward in 3D perspective space (from center 800, 2000 up to 800, 1400)
    swipe(800, 2000, 800, 1400, 250)
    time.sleep(0.3)

    # Fire Axial Particle Lance via FIRE trigger repeatedly
    fire_proc = subprocess.Popen([
        "adb", "-s", DEVICE, "shell",
        "for i in $(seq 1 12); do input tap 710 2260; sleep 0.08; done"
    ])
    time.sleep(0.25)
    capture("02_tablet_axial_particle_lance.png", mirror_name="02_tablet_sowing_trajectory.png")
    fire_proc.wait()
    time.sleep(0.5)

    # =========================================================================
    # Phase 4: Tablet Tactical Directives (Bao Codex)
    # =========================================================================
    print("\n[Tablet Phase 4] Capturing Tactical Directives (Bao Codex)...")
    # Open pause menu via back keyevent
    keyevent(4)
    time.sleep(1.0)
    # Tap Directives button in pause menu (x=950, y=1420)
    tap(950, 1420)
    time.sleep(1.2)
    capture("06_tablet_bao_codex.png")

    # Dismiss Directives modal cleanly via back keyevent
    keyevent(4)
    time.sleep(0.8)

    # =========================================================================
    # Phase 5: Tablet Multi-Theater Campaign Star Map
    # =========================================================================
    print("\n[Tablet Phase 5] Capturing Campaign Map...")
    # Re-open pause menu via back keyevent
    keyevent(4)
    time.sleep(0.8)
    # Tap SECTORS MAP button in pause menu (x=650, y=1420)
    tap(650, 1420)
    time.sleep(2.0)
    capture("03_tablet_campaign_map.png")

    # =========================================================================
    # Phase 6: Tablet Orbital Fleet Hangar
    # =========================================================================
    print("\n[Tablet Phase 6] Capturing Orbital Fleet Hangar...")
    # Tap FLEET tab in tablet bottom nav (x=544, y=2460)
    tap(544, 2460)
    time.sleep(1.2)
    capture("04_tablet_fleet_hangar.png")
    # Dismiss Hangar cleanly via back keyevent
    keyevent(4)
    time.sleep(0.8)

    print("\n[Complete] All 6 tablet screenshots captured and verified!")

  finally:
    print("\n[Display] Resetting display size and density to device native...")
    adb_cmd(["shell", "wm", "size", "reset"])
    adb_cmd(["shell", "wm", "density", "reset"])
    time.sleep(1.5)
    seed_prefs(pro_unlocked=True, completed_tutorial=True, high_score=34820, liberated_sectors=6)


if __name__ == "__main__":
  main()
