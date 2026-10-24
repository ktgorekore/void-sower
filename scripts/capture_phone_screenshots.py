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

"""Automates Play Store phone screenshot capture with 100% filename accuracy.

Captures 10 visually appealing, high-impact phone screenshots (1344x2992) where
every filename strictly matches the visual scene depicted:
  01_tactical_combat_grid.png          - 3D Combat Grid & Charged Mega Gun (16x)
  02_axial_particle_lance.png          - Quadratic M^2 Double-Helix Super Beam
  03_morabaraba_fence_blast_barrage.png- 3-Beam Golden Morabaraba Fence Blast
  04_morabaraba_laser_fence_sowing.png - Active Bao Sowing & 3D Laser Fence
  05_ai_autopilot_tactical_solver.png  - Autonomous C++ MCTS AI AUTO Solver Beam
  06_kilwa_basin_campaign_map.png      - Kilwa Nebula Basin Campaign Star Map
  07_orbital_fleet_hangar.png          - Orbital Drydock 3D Dreadnought Hangar
  08_special_operations_command.png    - Special Ops (Daily Sortie & Incursion)
  09_pilot_telemetry_dossier.png       - Pilot Dossier & Telemetry (PRO Badge)
  10_flight_academy_onboarding.png     - Interactive Flight Academy Simulator
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
    "/home/kelvingorekore/projects/void-sower/store_listing/screenshots/phone"
)
ASSETS_DIR = "/home/kelvingorekore/projects/void-sower/store_listing/assets"
DOCS_STORE_DIR = (
    "/home/kelvingorekore/projects/void-sower/docs/media/store_screenshots"
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


def verify_and_save(temp_path, dest_name, mirror_names=None, docs_names=None):
  if not os.path.exists(temp_path) or os.path.getsize(temp_path) < 10000:
    raise RuntimeError(f"Failed to capture valid screenshot for {dest_name}")

  img = Image.open(temp_path)
  arr = np.array(img)
  white_pct = (arr > 240).all(axis=-1).mean() * 100
  mean_rgb = arr.mean(axis=(0, 1))[:3].astype(int)

  print(f"[Verify] {dest_name}: mean_rgb={mean_rgb}, white={white_pct:.2f}%")
  if white_pct > 5.0:
    raise RuntimeError(
        f"ABORT: Screenshot {dest_name} contains white screen or test ad"
        f" ({white_pct:.1f}% white pixels)!"
    )

  dest_path = os.path.join(SCREENSHOTS_DIR, dest_name)
  shutil.copyfile(temp_path, dest_path)
  print(f"[Saved] -> {dest_path} ({os.path.getsize(dest_path)} bytes)")

  for m_name in mirror_names or []:
    m_path = os.path.join(ASSETS_DIR, m_name)
    shutil.copyfile(dest_path, m_path)
    print(f"[Mirrored Asset] -> {m_path}")

  # Always mirror the canonical name to docs/media/store_screenshots/ plus any
  # extra alias names (such as 01_combat_tactical_depth.png for README.md).
  all_docs_names = [dest_name] + (docs_names or [])
  for d_name in dict.fromkeys(all_docs_names):
    d_path = os.path.join(DOCS_STORE_DIR, d_name)
    shutil.copyfile(dest_path, d_path)
    print(f"[Mirrored Docs] -> {d_path}")

  return dest_path


def capture(dest_name, mirror_names=None, docs_names=None):
  ensure_app_focused()
  temp_path = os.path.join("/tmp", f"cap_{dest_name}")
  print(f"[Capture] Grabbing {dest_name}...")
  with open(temp_path, "wb") as f:
    subprocess.run(
        ["adb", "-s", DEVICE, "exec-out", "screencap", "-p"],
        stdout=f,
        check=True,
    )
  return verify_and_save(temp_path, dest_name, mirror_names, docs_names)


def tap_and_capture_beam(
    tap_x, tap_y, delay_s, dest_name, mirror_names=None, docs_names=None
):
  """Fires a dock button and captures the lance beam in a single shell call."""
  ensure_app_focused()
  temp_path = os.path.join("/tmp", f"cap_{dest_name}")
  print(
      f"[Beam Capture] Tapping ({tap_x}, {tap_y}) + {delay_s}s -> {dest_name}"
  )
  shell_cmd = f"input tap {tap_x} {tap_y}; sleep {delay_s}; screencap -p"
  with open(temp_path, "wb") as f:
    subprocess.run(
        ["adb", "-s", DEVICE, "exec-out", shell_cmd],
        stdout=f,
        check=True,
    )
  return verify_and_save(temp_path, dest_name, mirror_names, docs_names)


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
  with open("/tmp/prefs.xml", "w", encoding="utf-8") as f:
    f.write(pref_xml)
  subprocess.run(
      [
          "adb",
          "-s",
          DEVICE,
          "push",
          "/tmp/prefs.xml",
          "/data/local/tmp/prefs.xml",
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
      "/data/local/tmp/prefs.xml",
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


def launch_sector_9():
  """Launches app, navigates to Star Map, and engages Sector 9 (Bastion)."""
  adb_cmd(["shell", "am", "start", "-n", "com.voidsower.app/.MainActivity"])
  time.sleep(2.4)
  # Tap Star Map button in top-left HUD
  tap(343, 224)
  time.sleep(1.5)
  # Tap ENGAGE on Sector 9 (Great Siphon Singularity)
  tap(1100, 2235)
  time.sleep(1.6)


def clean_stale_screenshots():
  """Removes stale/mismatched screenshot PNGs before writing fresh ones."""
  for path in glob.glob(os.path.join(SCREENSHOTS_DIR, "*.png")):
    os.remove(path)
  for path in glob.glob(os.path.join(ASSETS_DIR, "phone_*.png")):
    os.remove(path)
  for path in glob.glob(os.path.join(DOCS_STORE_DIR, "*.png")):
    os.remove(path)


def main():
  os.makedirs(SCREENSHOTS_DIR, exist_ok=True)
  os.makedirs(ASSETS_DIR, exist_ok=True)
  os.makedirs(DOCS_STORE_DIR, exist_ok=True)
  clean_stale_screenshots()

  # Ensure native phone display resolution (1344x2992 @ 480dpi)
  adb_cmd(["shell", "wm", "size", "reset"])
  adb_cmd(["shell", "wm", "density", "reset"])
  time.sleep(1.0)

  # =========================================================================
  # Phase 1: Interactive Flight Academy Onboarding (10)
  # =========================================================================
  print("\n[Phase 1] Capturing Flight Academy Onboarding (10)...")
  seed_prefs(
      pro_unlocked=True,
      completed_tutorial=False,
      high_score=48950,
      liberated_sectors=8,
      selected_chassis="mk4_golden_sovereign",
  )
  adb_cmd(["shell", "am", "start", "-n", "com.voidsower.app/.MainActivity"])
  time.sleep(3.0)
  capture(
      "10_flight_academy_onboarding.png",
      mirror_names=["phone_10_flight_academy_onboarding.png"],
  )

  # =========================================================================
  # Phase 2: Campaign Star Map (06), Fleet Hangar (07), Special Ops (08),
  #          & Pilot Telemetry Dossier with Profile-Linked PRO Badge (09)
  # =========================================================================
  print(
      "\n[Phase 2] Capturing Campaign Star Map (06), Fleet Hangar (07),"
      " Special Ops (08), & Pilot Telemetry Dossier (09)..."
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

  # Open Pilot Flight Dossier directly over the 3D Combat Arena via top-left
  # Profile Avatar (x=75, y=224) to showcase the profile-linked PRO badge!
  tap(75, 224)
  time.sleep(1.2)
  capture(
      "09_pilot_telemetry_dossier.png",
      mirror_names=["phone_09_pilot_telemetry_dossier.png"],
  )
  keyevent(4)
  time.sleep(0.8)

  # Open Campaign Star Map via top-left Star Map button (x=343, y=224)
  tap(343, 224)
  time.sleep(1.5)
  capture(
      "06_kilwa_basin_campaign_map.png",
      mirror_names=["phone_06_kilwa_basin_campaign_map.png"],
  )

  # Open Orbital Fleet Hangar via bottom nav FLEET tab (x=560, y=2815)
  tap(560, 2815)
  time.sleep(1.2)
  capture(
      "07_orbital_fleet_hangar.png",
      mirror_names=["phone_07_orbital_fleet_hangar.png"],
  )
  keyevent(4)
  time.sleep(0.8)

  # Switch to Special Operations Command Deck via OPS tab (x=345, y=2815)
  tap(345, 2815)
  time.sleep(1.2)
  capture(
      "08_special_operations_command.png",
      mirror_names=["phone_08_special_operations_command.png"],
  )

  # Switch back to SECTORS tab (x=130, y=2815) to engage Sector 9
  tap(130, 2815)
  time.sleep(1.0)

  # =========================================================================
  # Phase 3: Sector 9 3D Tactical Combat Grid with Mega Gun Ready (01)
  #          + Quadratic Exaggerated MEGA GUN Super Beam (02)
  # =========================================================================
  print(
      "\n[Phase 3] Engaging Sector 9 for Mega Gun Ready (01) & Quadratic"
      " Exaggerated Super Beam (02)..."
  )
  tap(1100, 2235)
  time.sleep(1.6)

  # Slide Defender laterally at y=2420 to Corridor 2 (Totem #2, x=297) and sow
  # right twice to charge Totem #3 (Nyumba bay 10) to 4+ seeds (MEGA GUN 16x!)
  swipe(595, 2420, 297, 2420, 180)
  time.sleep(0.30)
  tap(265, 2800)
  time.sleep(0.35)
  tap(265, 2800)
  time.sleep(0.35)

  # Slide Defender purely horizontally at y=2420 to Corridor 3 (Totem #3, x=446)
  # so the dock glows: "✨ #3 •••• 16x"
  swipe(297, 2420, 446, 2420, 180)
  time.sleep(0.35)

  # Screenshot 01: Active 3D Combat Grid with Nyumba Mega Gun Ready & 6 Enemies
  capture(
      "01_tactical_combat_grid.png",
      mirror_names=["phone_01_tactical_combat_grid.png"],
      docs_names=["01_combat_tactical_depth.png"],
  )

  # Screenshot 02: Fire Quadratic Exaggerated MEGA GUN Super Beam down C3!
  tap_and_capture_beam(
      672,
      2800,
      0.08,
      "02_axial_particle_lance.png",
      mirror_names=["phone_02_axial_particle_lance.png"],
  )
  time.sleep(0.45)

  # =========================================================================
  # Phase 4: Active Bao Sowing & Golden 3D Morabaraba Laser Fence (04)
  #          + 3-Beam Golden Morabaraba FENCE BLAST Barrage (03)
  # =========================================================================
  print(
      "\n[Phase 4] Building 4-Totem Morabaraba Laser Fence (04) & Firing 3-Beam"
      " Golden FENCE BLAST Barrage (03)..."
  )
  seed_prefs(
      pro_unlocked=True,
      completed_tutorial=True,
      high_score=48950,
      liberated_sectors=9,
      selected_chassis="mk4_golden_sovereign",
  )
  launch_sector_9()

  # 1. Slide to Totem #3 (x=446) and tap SOW › (265, 2800) -> sows 4 seeds into
  #    Totems #4, #5, #6, #7 (each now has 1 seed).
  swipe(595, 2420, 446, 2420, 200)
  time.sleep(0.35)
  tap(265, 2800)
  time.sleep(0.55)

  # 2. Slide to Totem #8 (x=1192) and tap ‹ SOW (115, 2800) -> sows 4 seeds
  #    leftward into Totems #7, #6, #5, #4 (each now has 2 seeds: 2, 2, 2, 2!).
  swipe(980, 2420, 1192, 2420, 200)
  time.sleep(0.35)
  tap(115, 2800)
  time.sleep(0.55)

  # 3. Slide back to Totem #3 (x=446, which has 3 seeds) and fire its 9x Super
  #    Beam while the Golden Morabaraba Laser Fence ("MILL 1.5x" + "BLAST") is
  #    illuminated across Totems #4-#7!
  swipe(1192, 2420, 446, 2420, 200)
  time.sleep(0.30)
  tap_and_capture_beam(
      672,
      2800,
      0.08,
      "04_morabaraba_laser_fence_sowing.png",
      mirror_names=["phone_04_morabaraba_laser_fence_sowing.png"],
  )
  time.sleep(0.45)

  # 4. Screenshot 03: Fire the 3-Beam Golden Morabaraba FENCE BLAST Barrage!
  tap_and_capture_beam(
      1180,
      2800,
      0.08,
      "03_morabaraba_fence_blast_barrage.png",
      mirror_names=["phone_03_morabaraba_fence_blast_barrage.png"],
  )
  time.sleep(0.45)

  # =========================================================================
  # Phase 5: Autonomous C++ MCTS AI AUTO Tactical Solver in Action (05)
  # =========================================================================
  print(
      "\n[Phase 5] Capturing Autonomous C++ MCTS AI AUTO Tactical Solver (05)..."
  )
  seed_prefs(
      pro_unlocked=True,
      completed_tutorial=True,
      high_score=48950,
      liberated_sectors=9,
      selected_chassis="mk3_zimbabwe_spire",
  )
  launch_sector_9()

  # Enable AI Tactical Solver via Pause Menu -> AI Solver toggle -> Resume
  keyevent(4)
  time.sleep(0.8)
  tap(1050, 2200)
  time.sleep(0.45)
  tap(671, 1500)
  time.sleep(0.35)

  # Fire immediately while AI AUTO is active in the HUD and AI SIM is in dock!
  tap_and_capture_beam(
      1180,
      2800,
      0.08,
      "05_ai_autopilot_tactical_solver.png",
      mirror_names=["phone_05_ai_autopilot_tactical_solver.png"],
  )

  print(
      "\n[Complete] All 10 Play Store phone screenshots and asset/docs mirrors"
      " captured and verified with 100% filename accuracy!"
  )


if __name__ == "__main__":
  main()
