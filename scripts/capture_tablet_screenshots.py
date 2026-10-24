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

"""Automates high-resolution tablet screenshot capture for Google Play Console.

Configures the Android display to 1600x2560 @ 320dpi (10-inch portrait tablet),
captures 8 visually appealing tablet screenshots with 100% filename accuracy:
  01_tablet_tactical_combat.png         - 3D Combat Grid & Charged Mega Gun (16x)
  02_tablet_axial_particle_lance.png    - Quadratic M^2 Double-Helix Super Beam
  03_tablet_morabaraba_fence_blast.png  - 3-Beam Golden Morabaraba Fence Blast
  04_tablet_morabaraba_laser_fence.png  - Active Bao Sowing & 3D Laser Fence
  05_tablet_campaign_map.png            - Kilwa Nebula Basin Campaign Star Map
  06_tablet_fleet_hangar.png            - Orbital Drydock 3D Dreadnought Hangar
  07_tablet_pilot_telemetry_dossier.png - Pilot Dossier & Telemetry (PRO Badge)
  08_tablet_flight_academy.png          - Interactive Flight Academy Simulator
and cleanly restores native phone display resolution.
"""

import glob
import os
import shutil
import subprocess
import time
import numpy as np
from PIL import Image

DEVICE = "emulator-5554"
SCREENSHOTS_DIR = (
    "/home/kelvingorekore/projects/void-sower/store_listing/screenshots/tablet"
)


def adb_cmd(args):
  cmd = ["adb", "-s", DEVICE] + args
  return subprocess.run(cmd, capture_output=True, text=True, check=False)


def tap(x, y):
  adb_cmd(["shell", "input", "tap", str(x), str(y)])


def swipe(x1, y1, x2, y2, duration_ms=220):
  adb_cmd([
      "shell",
      "input",
      "swipe",
      str(x1),
      str(y1),
      str(x2),
      str(y2),
      str(duration_ms),
  ])


def keyevent(code):
  adb_cmd(["shell", "input", "keyevent", str(code)])


def ensure_app_focused():
  res = subprocess.run(
      ["adb", "-s", DEVICE, "shell", "dumpsys", "window"],
      capture_output=True,
      text=True,
      check=False,
  )
  if "com.voidsower.app" not in res.stdout:
    print("[Focus] Restoring com.voidsower.app to foreground...")
    adb_cmd(["shell", "am", "start", "-n", "com.voidsower.app/.MainActivity"])
    time.sleep(1.5)


def verify_and_save(temp_path, dest_name):
  if not os.path.exists(temp_path) or os.path.getsize(temp_path) < 10000:
    raise RuntimeError(f"Failed to capture valid screenshot for {dest_name}")

  img = Image.open(temp_path)
  arr = np.array(img)
  white_pct = (arr > 240).all(axis=-1).mean() * 100
  mean_rgb = arr.mean(axis=(0, 1))[:3].astype(int)

  print(
      f"[Verify Tablet] {dest_name}: mean_rgb={mean_rgb},"
      f" white={white_pct:.2f}%"
  )
  if white_pct > 5.0:
    raise RuntimeError(
        f"ABORT: Tablet screenshot {dest_name} contains white screen or ad"
        f" ({white_pct:.1f}% white pixels)!"
    )

  dest_path = os.path.join(SCREENSHOTS_DIR, dest_name)
  shutil.copyfile(temp_path, dest_path)
  print(f"[Saved] -> {dest_path} ({os.path.getsize(dest_path)} bytes)")
  return dest_path


def capture(dest_name):
  ensure_app_focused()
  temp_path = os.path.join("/tmp", f"cap_tablet_{dest_name}")
  print(f"[Capture Tablet] Grabbing {dest_name}...")
  with open(temp_path, "wb") as f:
    subprocess.run(
        ["adb", "-s", DEVICE, "exec-out", "screencap", "-p"],
        stdout=f,
        check=True,
    )
  return verify_and_save(temp_path, dest_name)


def tap_and_capture_beam(tap_x, tap_y, delay_s, dest_name):
  """Fires a dock button and captures the lance beam in a single shell call."""
  ensure_app_focused()
  temp_path = os.path.join("/tmp", f"cap_tablet_{dest_name}")
  print(
      f"[Beam Capture Tablet] Tapping ({tap_x}, {tap_y}) + {delay_s}s ->"
      f" {dest_name}"
  )
  shell_cmd = f"input tap {tap_x} {tap_y}; sleep {delay_s}; screencap -p"
  with open(temp_path, "wb") as f:
    subprocess.run(
        ["adb", "-s", DEVICE, "exec-out", shell_cmd],
        stdout=f,
        check=True,
    )
  return verify_and_save(temp_path, dest_name)


def seed_prefs(
    pro_unlocked=True,
    completed_tutorial=True,
    high_score=48950,
    liberated_sectors=9,
    selected_chassis="mk4_golden_sovereign",
):
  adb_cmd([
      "shell",
      "settings",
      "put",
      "secure",
      "immersive_mode_confirmations",
      "confirmed",
  ])
  adb_cmd(["shell", "input", "keyevent", "3"])
  time.sleep(0.5)
  adb_cmd(["shell", "am", "force-stop", "com.voidsower.app"])
  time.sleep(0.5)

  profile_json = (
      '{"id":"pilot_default","callsign":"Vanguard-01","insignia":"shonaStar",'
      f'"lifetimeScore":{high_score},"enemiesDestroyed":248,"lancesFired":164,'
      '"maxCascadeLaps":6,"missionsPlayed":42,"victories":36,"defeats":6,'
      '"flawlessVictories":24,"totalSeedsSown":680,"flakBurstsTriggered":48,'
      '"totalCoresSaved":390,"currentStreak":9,"longestStreak":16,'
      '"lastPlayedDate":"2026-10-18","totalFlightTimeSeconds":8420,'
      '"chassisSorties":{"mk1_bastion":14,"mk2_monsoon":12,'
      '"mk3_zimbabwe_spire":8,"mk4_golden_sovereign":8},'
      '"campaignSorties":{"kilwa_basin":28,"phantom_drift":14},'
      '"unlockedAchievements":["first_sortie","flawless_defense",'
      '"cascade_master","iron_hull"],'
      '"isGoogleLinked":false}'
  )
  escaped_profile = profile_json.replace('"', "&quot;")

  pref_xml = (
      '<?xml version="1.0" encoding="utf-8" standalone="yes" ?>\n'
      "<map>\n"
      '    <boolean name="flutter.void_sower_pro_unlocked"'
      f' value="{"true" if pro_unlocked else "false"}" />\n'
      '    <boolean name="flutter.void_sower_ads_disabled" value="true" />\n'
      '    <boolean name="flutter.void_sower_completed_tutorial"'
      f' value="{"true" if completed_tutorial else "false"}" />\n'
      f'    <int name="flutter.void_sower_high_score" value="{high_score}" />\n'
      '    <int name="flutter.void_sower_liberated_sectors"'
      f' value="{liberated_sectors}" />\n'
      '    <string'
      f' name="flutter.void_sower_selected_chassis">{selected_chassis}</string>\n'
      '    <int name="flutter.void_sower_sector_stars_1" value="3" />\n'
      '    <int name="flutter.void_sower_sector_stars_2" value="3" />\n'
      '    <int name="flutter.void_sower_sector_stars_3" value="3" />\n'
      '    <int name="flutter.void_sower_sector_stars_4" value="3" />\n'
      '    <int name="flutter.void_sower_sector_stars_5" value="3" />\n'
      '    <int name="flutter.void_sower_sector_stars_6" value="3" />\n'
      '    <int name="flutter.void_sower_sector_stars_7" value="3" />\n'
      '    <int name="flutter.void_sower_sector_stars_8" value="3" />\n'
      '    <string'
      f' name="flutter.void_sower_user_profile">{escaped_profile}</string>\n'
      '    <string'
      ' name="flutter.void_sower_active_profile_id">pilot_default</string>\n'
      "</map>\n"
  )
  with open("/tmp/prefs_tablet.xml", "w", encoding="utf-8") as f:
    f.write(pref_xml)
  subprocess.run(
      [
          "adb",
          "-s",
          DEVICE,
          "push",
          "/tmp/prefs_tablet.xml",
          "/data/local/tmp/prefs_tablet.xml",
      ],
      check=True,
  )
  adb_cmd([
      "shell",
      "run-as",
      "com.voidsower.app",
      "mkdir",
      "-p",
      "shared_prefs",
  ])
  adb_cmd([
      "shell",
      "run-as",
      "com.voidsower.app",
      "cp",
      "/data/local/tmp/prefs_tablet.xml",
      "shared_prefs/FlutterSharedPreferences.xml",
  ])
  adb_cmd([
      "shell",
      "run-as",
      "com.voidsower.app",
      "chmod",
      "660",
      "shared_prefs/FlutterSharedPreferences.xml",
  ])
  time.sleep(0.5)


def launch_tablet_sector_9():
  """Launches app, opens Star Map, and engages Sector 9 on 1600x2560 tablet."""
  adb_cmd(["shell", "am", "start", "-n", "com.voidsower.app/.MainActivity"])
  time.sleep(2.4)
  # Tap Star Map button in top-left HUD (x=228, y=180 on 1600x2560)
  tap(228, 180)
  time.sleep(1.5)
  # Tap ENGAGE on Sector 9 (x=1254, y=1497 on 1600x2560)
  tap(1254, 1497)
  time.sleep(1.6)


def main():
  os.makedirs(SCREENSHOTS_DIR, exist_ok=True)
  for path in glob.glob(os.path.join(SCREENSHOTS_DIR, "*.png")):
    os.remove(path)

  try:
    print("[Display] Setting tablet resolution (1600x2560 @ 320dpi)...")
    adb_cmd(["shell", "wm", "size", "1600x2560"])
    adb_cmd(["shell", "wm", "density", "320"])
    time.sleep(1.8)

    # =========================================================================
    # Phase 1: Tablet Flight Academy Onboarding (08)
    # =========================================================================
    print("\n[Tablet Phase 1] Capturing Flight Academy Onboarding (08)...")
    seed_prefs(
        pro_unlocked=True,
        completed_tutorial=False,
        high_score=48950,
        liberated_sectors=8,
        selected_chassis="mk4_golden_sovereign",
    )
    adb_cmd(["shell", "am", "start", "-n", "com.voidsower.app/.MainActivity"])
    time.sleep(3.0)
    capture("08_tablet_flight_academy.png")

    # =========================================================================
    # Phase 2: Tablet Pilot Telemetry Dossier (07), Campaign Star Map (05),
    #          & Orbital Fleet Hangar (06)
    # =========================================================================
    print(
        "\n[Tablet Phase 2] Capturing Pilot Dossier (07), Campaign Map (05) &"
        " Fleet Hangar (06)..."
    )
    seed_prefs(
        pro_unlocked=True,
        completed_tutorial=True,
        high_score=48950,
        liberated_sectors=9,
        selected_chassis="mk4_golden_sovereign",
    )
    adb_cmd(["shell", "am", "start", "-n", "com.voidsower.app/.MainActivity"])
    time.sleep(2.4)

    # Open Pilot Flight Dossier via top-left Profile Avatar (x=58, y=180)
    tap(58, 180)
    time.sleep(1.2)
    capture("07_tablet_pilot_telemetry_dossier.png")
    keyevent(4)
    time.sleep(0.8)

    # Open Campaign Star Map (x=228, y=180)
    tap(228, 180)
    time.sleep(1.5)
    capture("05_tablet_campaign_map.png")

    # Tap FLEET tab in tablet bottom nav (x=672, y=2420)
    tap(672, 2420)
    time.sleep(1.2)
    capture("06_tablet_fleet_hangar.png")
    keyevent(4)
    time.sleep(0.8)

    # =========================================================================
    # Phase 3: Tablet 3D Tactical Combat with Mega Gun Ready (01)
    #          + Quadratic Exaggerated MEGA GUN Super Beam (02)
    # =========================================================================
    print(
        "\n[Tablet Phase 3] Engaging Sector 9 for Mega Gun Ready (01) &"
        " Quadratic Exaggerated Super Beam (02)..."
    )
    tap(1254, 1497)
    time.sleep(1.6)

    # On 1600x2560 tablet, viewport spans x=240..1360:
    # c=1 (Totem #2): x=450, c=2 (Totem #3): x=590, c=3 (Totem #4): x=730,
    # c=7 (Totem #8): x=1290
    # Dock buttons at y=2410: ‹ SOW (310), SOW › (415), Center (800),
    # FIRE / BLAST (1268)
    swipe(730, 2150, 450, 2150, 160)
    time.sleep(0.25)
    tap(415, 2410)
    time.sleep(0.35)
    tap(415, 2410)
    time.sleep(0.35)

    # Slide to Corridor 2 (Totem #3, x=590) -> "✨ #3 •••• 16x"
    swipe(450, 2150, 590, 2150, 160)
    time.sleep(0.30)

    # Screenshot 01: Tablet 3D Tactical Combat with Mega Gun Ready & 6 Enemies
    capture("01_tablet_tactical_combat.png")

    # Screenshot 02: Tablet Quadratic Exaggerated MEGA GUN Super Beam!
    tap_and_capture_beam(
        800,
        2410,
        0.08,
        "02_tablet_axial_particle_lance.png",
    )
    time.sleep(0.45)

    # =========================================================================
    # Phase 4: Tablet Active Bao Sowing & Golden Morabaraba Laser Fence (04)
    #          + 3-Beam Golden Morabaraba FENCE BLAST Barrage (03)
    # =========================================================================
    print(
        "\n[Tablet Phase 4] Building 4-Totem Morabaraba Laser Fence (04) &"
        " Firing 3-Beam Golden FENCE BLAST Barrage (03)..."
    )
    seed_prefs(
        pro_unlocked=True,
        completed_tutorial=True,
        high_score=48950,
        liberated_sectors=9,
        selected_chassis="mk4_golden_sovereign",
    )
    launch_tablet_sector_9()

    # 1. Slide to Totem #3 (x=590) and tap SOW › (415, 2410) -> sows 4 seeds
    #    into Totems #4, #5, #6, #7 (each has 1 seed).
    swipe(730, 2150, 590, 2150, 200)
    time.sleep(0.35)
    tap(415, 2410)
    time.sleep(0.55)

    # 2. Slide to Totem #8 (x=1290) and tap ‹ SOW (310, 2410) -> sows 4 seeds
    #    leftward into Totems #7, #6, #5, #4 (each now has 2 seeds: 2, 2, 2, 2!).
    swipe(1010, 2150, 1290, 2150, 200)
    time.sleep(0.35)
    tap(310, 2410)
    time.sleep(0.55)

    # 3. Slide back to Totem #3 (x=590, which has 3 seeds) and fire its 9x Super
    #    Beam via the center status bar (800, 2410) while the Golden Morabaraba
    #    Laser Fence ("MILL 1.5x" + "BLAST") remains active across Totems #4-#7!
    swipe(1290, 2150, 590, 2150, 200)
    time.sleep(0.30)
    tap_and_capture_beam(
        800,
        2410,
        0.08,
        "04_tablet_morabaraba_laser_fence.png",
    )
    time.sleep(0.45)

    # 4. Now fire the 3-Beam Golden Morabaraba FENCE BLAST Barrage (1268, 2410)!
    tap_and_capture_beam(
        1268,
        2410,
        0.08,
        "03_tablet_morabaraba_fence_blast.png",
    )
    time.sleep(0.45)

    print("\n[Complete] All 8 tablet screenshots captured and verified!")

  finally:
    print("\n[Display] Resetting display size and density to device native...")
    adb_cmd(["shell", "wm", "size", "reset"])
    adb_cmd(["shell", "wm", "density", "reset"])
    time.sleep(1.5)
    seed_prefs(
        pro_unlocked=True,
        completed_tutorial=True,
        high_score=48950,
        liberated_sectors=9,
        selected_chassis="mk4_golden_sovereign",
    )


if __name__ == "__main__":
  main()
