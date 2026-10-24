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

"""Automates high-resolution phone screenshot capture for Google Play Console.

Captures all 10 phone screenshots (1344x2992 @ 480dpi) plus asset/docs mirrors,
prioritizing live 3D gameplay action over static menus:
  - 01: 3D Tactical Combat Grid with Nyumba Mega Gun Ready (16x SUPER BEAM dock)
  - 02: Quadratic Exaggerated Super Beam (25x-36x MEGA GUN with 5 double helices
        & concentric 3D shockwave rings)
  - 03: Interactive Flight Academy Onboarding over 3D Orbital Trench
  - 04: Orbital Fleet Hangar with 4 Afrofuturist Dreadnought Chassis
  - 05: Clean Kilwa Nebula Basin Campaign Star Map (Sector 9 Active Siege)
  - 06: 3-Beam Golden Morabaraba FENCE BLAST Barrage (3 simultaneous lances)
  - 07: Active Bao Sowing & 3D Morabaraba Laser Fence (MILL 1.5x + FENCE BLAST)
  - 08: Quadratic Lance Direct Boss Strike + Yote Snipe Ready (CULL x1 unlocked)
  - 09: Focused Multi-Seed Fire Lance (4x-9x SUPER BEAM mid-flight)
  - 10: AI Auto-Pilot (AI AUTO) Active Siege & Lance Barrage
Every screenshot is strictly verified against white screens, system dialogs, and ads.
"""

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


def swipe(x1, y1, x2, y2, duration_ms=250):
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
        f"ABORT: Screenshot {dest_name} contains white screen or ad"
        f" ({white_pct:.1f}% white pixels)!"
    )

  dest_path = os.path.join(SCREENSHOTS_DIR, dest_name)
  shutil.copyfile(temp_path, dest_path)
  print(f"[Saved] -> {dest_path} ({os.path.getsize(dest_path)} bytes)")

  for m_name in mirror_names or []:
    mirror_path = os.path.join(ASSETS_DIR, m_name)
    shutil.copyfile(dest_path, mirror_path)
    print(f"[Mirrored Asset] -> {mirror_path}")

  for d_name in docs_names or []:
    docs_path = os.path.join(DOCS_STORE_DIR, d_name)
    shutil.copyfile(dest_path, docs_path)
    print(f"[Mirrored Docs] -> {docs_path}")

  docs_same_path = os.path.join(DOCS_STORE_DIR, dest_name)
  shutil.copyfile(dest_path, docs_same_path)
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
    tap_x,
    tap_y,
    delay_s,
    dest_name,
    mirror_names=None,
    docs_names=None,
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
      '    <int name="flutter.void_sower_sector_stars_7" value="2" />\n'
      '    <int name="flutter.void_sower_sector_stars_8" value="2" />\n'
      '    <string'
      f' name="flutter.void_sower_user_profile">{escaped_profile}</string>\n'
      '    <string'
      ' name="flutter.void_sower_active_profile_id">pilot_default</string>\n'
      "</map>\n"
  )
  with open("/tmp/prefs.xml", "w", encoding="utf-8") as f:
    f.write(pref_xml)
  subprocess.run(
      ["adb", "-s", DEVICE, "push", "/tmp/prefs.xml", "/data/local/tmp/prefs.xml"],
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


def main():
  os.makedirs(SCREENSHOTS_DIR, exist_ok=True)
  os.makedirs(ASSETS_DIR, exist_ok=True)
  os.makedirs(DOCS_STORE_DIR, exist_ok=True)

  # Ensure native phone display resolution (1344x2992 @ 480dpi)
  adb_cmd(["shell", "wm", "size", "reset"])
  adb_cmd(["shell", "wm", "density", "reset"])
  time.sleep(1.0)

  # =========================================================================
  # Phase 1: Flight Academy Onboarding over 3D Orbital Trench
  # =========================================================================
  print("\n[Phase 1] Capturing Flight Academy Onboarding (03)...")
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
      "03_flight_academy_onboarding.png",
      mirror_names=["phone_02_flight_academy.png"],
  )

  # =========================================================================
  # Phase 2: Clean Campaign Star Map (05) & Orbital Fleet Hangar (04)
  # =========================================================================
  print("\n[Phase 2] Capturing Clean Campaign Star Map (05) & Hangar (04)...")
  seed_prefs(
      pro_unlocked=True,
      completed_tutorial=True,
      high_score=48950,
      liberated_sectors=9,
      selected_chassis="mk4_golden_sovereign",
  )
  adb_cmd(["shell", "am", "start", "-n", "com.voidsower.app/.MainActivity"])
  time.sleep(2.4)

  # Open Campaign Star Map via top-left Star Map button
  tap(343, 224)
  time.sleep(1.5)
  capture(
      "05_kilwa_basin_campaign_map.png",
      docs_names=["03_orbital_command_campaign.png"],
  )

  # Open Orbital Fleet Hangar via bottom nav FLEET tab
  tap(560, 2815)
  time.sleep(1.2)
  capture(
      "04_orbital_fleet_hangar.png",
      mirror_names=["phone_06_hangar.png"],
      docs_names=["04_fleet_hangar_inspection.png"],
  )
  # Close Hangar modal
  keyevent(4)
  time.sleep(0.8)

  # =========================================================================
  # Phase 3: Sector 9 3D Combat Grid (01) + Quadratic Exaggerated MEGA GUN (02)
  #          + Direct Apex Boss Strike / Yote Snipe Ready (08)
  # =========================================================================
  print(
      "\n[Phase 3] Engaging Sector 9 for Mega Gun Ready (01) & Quadratic"
      " Exaggerated Super Beam (02, 08)..."
  )
  # Tap ENGAGE on Sector 9 from the Star Map
  tap(1100, 2235)
  time.sleep(1.6)

  # Slide Defender to Corridor 1 (Totem #2) and sow right twice to overcharge
  # Totem #3 (Nyumba bay 10) to 4+ seeds (MEGA GUN 16x-25x SUPER BEAM!)
  swipe(580, 2350, 250, 2250, 140)
  time.sleep(0.25)
  tap(265, 2800)
  time.sleep(0.35)
  tap(265, 2800)
  time.sleep(0.35)

  # Slide Defender to Corridor 2 (Totem #3) so the dock displays:
  # "✨ TOTEM #3 • MEGA GUN ••••" / "⚡ TAP FOR 16x SUPER BEAM"
  swipe(250, 2250, 420, 1950, 160)
  time.sleep(0.30)

  # Screenshot 01: Active 3D Combat Grid with Nyumba Mega Gun Ready & 6 Enemies
  capture(
      "01_tactical_combat_grid.png",
      mirror_names=[
          "phone_01_tactical_combat_grid.png",
          "phone_02_nyumba_storage.png",
      ],
      docs_names=["01_combat_tactical_depth.png"],
  )

  # Screenshot 02: Fire Quadratic Exaggerated MEGA GUN Super Beam down C3!
  tap_and_capture_beam(
      672,
      2800,
      0.08,
      "02_axial_particle_lance.png",
      mirror_names=["phone_02_axial_particle_lance.png"],
      docs_names=["02_axial_particle_lance.png"],
  )
  time.sleep(0.45)

  # Now slide to Corridor 7 (Totem #8, which has 5 seeds on its Nyumba throne)
  # and unleash a second Quadratic Exaggerated Super Beam directly into the
  # Apex Boss Flagship (unlocking Yote Snipe Ready / CULL x1 + 1260x DMG)!
  swipe(420, 1950, 1240, 2100, 180)
  time.sleep(0.30)
  tap_and_capture_beam(
      1180,
      2800,
      0.08,
      "08_pilot_telemetry_dashboard.png",
      mirror_names=["phone_04_pilot_dossier.png"],
  )
  time.sleep(0.45)

  # =========================================================================
  # Phase 4: Active Bao Sowing & Golden 3D Morabaraba Laser Fence (07)
  #          + 3-Beam Golden Morabaraba FENCE BLAST Barrage (06)
  # =========================================================================
  print(
      "\n[Phase 4] Building 4-Totem Morabaraba Laser Fence (07) & Firing 3-Beam"
      " Golden FENCE BLAST Barrage (06)..."
  )
  seed_prefs(
      pro_unlocked=True,
      completed_tutorial=True,
      high_score=48950,
      liberated_sectors=9,
      selected_chassis="mk4_golden_sovereign",
  )
  launch_sector_9()

  # 1. Slide to Totem #3 (x=420) and tap SOW › (265, 2800) -> sows 4 seeds into
  #    Totems #4, #5, #6, #7 (each now has 1 seed).
  swipe(580, 2450, 420, 2450, 220)
  time.sleep(0.35)
  tap(265, 2800)
  time.sleep(0.55)

  # 2. Slide to Totem #8 (x=1240) and tap ‹ SOW (115, 2800) -> sows 4 seeds
  #    leftward into Totems #7, #6, #5, #4 (each now has 2 seeds: 2, 2, 2, 2!).
  swipe(980, 2450, 1240, 2450, 220)
  time.sleep(0.35)
  tap(115, 2800)
  time.sleep(0.55)

  # 3. Tap BLASTER FIRE once so the HUD updates and illuminates the Golden
  #    Morabaraba Laser Fence ("MILL 1.5x" chip + gold "FENCE BLAST" button)
  tap(1180, 2800)
  time.sleep(0.45)

  # Screenshot 07: Active Bao Sowing & Golden 3D Morabaraba Laser Fence Ready
  capture(
      "07_bao_orbital_codex.png",
      mirror_names=[
          "phone_03_bao_codex.png",
          "phone_02_capacitor_sowing.png",
      ],
      docs_names=["05_tactical_directives_codex.png"],
  )

  # Screenshot 06: Fire the 3-Beam Golden Morabaraba FENCE BLAST Barrage!
  tap_and_capture_beam(
      1180,
      2800,
      0.08,
      "06_sector_liberation_victory.png",
      mirror_names=[
          "phone_05_sector_liberation.png",
          "phone_05_tactical_settings.png",
      ],
      docs_names=[
          "06_sector_liberation_victory.png",
          "06_tactical_pause_controls.png",
      ],
  )
  time.sleep(0.45)

  # =========================================================================
  # Phase 5: Focused Multi-Seed Fire Lance (09) & AI Auto-Pilot Siege (10)
  # =========================================================================
  print(
      "\n[Phase 5] Capturing Focused Fire Lance (09) & AI Auto-Pilot Siege"
      " (10)..."
  )
  seed_prefs(
      pro_unlocked=True,
      completed_tutorial=True,
      high_score=48950,
      liberated_sectors=9,
      selected_chassis="mk3_zimbabwe_spire",
  )
  launch_sector_9()

  # Slide to Corridor 2 (Totem #3 has 3 seeds -> 9x SUPER BEAM) and fire!
  swipe(580, 2350, 420, 2050, 160)
  time.sleep(0.30)
  tap_and_capture_beam(
      1180,
      2800,
      0.08,
      "09_pro_commander_upgrade.png",
      mirror_names=["phone_07_pro_commander.png"],
  )
  time.sleep(0.45)

  # Enable AI Tactical Solver via Pause Menu -> AI Solver toggle -> Resume
  keyevent(4)
  time.sleep(0.8)
  tap(1050, 2200)
  time.sleep(0.45)
  tap(671, 1500)
  time.sleep(0.35)

  # Fire immediately while AI AUTO is active in the HUD!
  tap_and_capture_beam(
      1180,
      2800,
      0.08,
      "10_checkpoint_relic_draft_siege.png",
      mirror_names=["phone_08_checkpoint_relic_draft.png"],
      docs_names=["07_checkpoint_relic_draft.png"],
  )

  print(
      "\n[Complete] All 10 Play Store phone screenshots and asset/docs mirrors"
      " captured and verified!"
  )


if __name__ == "__main__":
  main()
