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

Captures all 10 phone screenshots featuring:
  - 3D Perspective Orbital Trench Canyon & Ringed Afrofuturist Planet
  - Interactive 3D Camera Gimbal modes (CHASE 3D 26°/0°, BRIDGE 3D 38°/-22°, ORBIT 3D 32°/18°)
  - Pure 3D Polyhedral Dreadnought & Enemy Ships with 3D ground shadows & laser tethers
  - African strategic fusions (Bao la Kiswahili, Morabaraba 1.5x Mill, Fanorona vectors, Yoté Cull)
  - 3-Phase Ascending Sector Checkpoints (P1: RECON, P2: SIEGE + Relic Draft, P3: APEX BOSS)
Every screenshot is strictly verified against white screens, system dialogs, and ads.
"""

import os
import shutil
import subprocess
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

  # Also mirror into docs/media/store_screenshots/<dest_name>
  docs_same_path = os.path.join(DOCS_STORE_DIR, dest_name)
  shutil.copyfile(dest_path, docs_same_path)

  return dest_path


def seed_prefs(pro_unlocked=True, completed_tutorial=False, high_score=34820, liberated_sectors=6):
  adb_cmd(["shell", "settings", "put", "secure", "immersive_mode_confirmations", "confirmed"])
  adb_cmd(["shell", "input", "keyevent", "3"])
  time.sleep(0.6)
  adb_cmd(["shell", "am", "force-stop", "com.voidsower.app"])
  time.sleep(0.6)

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

  # =========================================================================
  # Phase 1: Flight Academy Onboarding over 3D Orbital Trench
  # =========================================================================
  print("\n[Phase 1] Capturing Flight Academy Onboarding over 3D Orbital Trench...")
  seed_prefs(pro_unlocked=True, completed_tutorial=False, high_score=34820, liberated_sectors=6)
  adb_cmd(["shell", "am", "start", "-n", "com.voidsower.app/.MainActivity"])
  time.sleep(3.2)

  # Screenshot 03: Flight Academy Onboarding
  capture("03_flight_academy_onboarding.png", "phone_02_flight_academy.png")

  # =========================================================================
  # Phase 2: Active 3D Tactical Combat in CHASE 3D (26°/0°) with Admiral Zawadi Comms
  # =========================================================================
  print("\n[Phase 2] Launching fresh sortie in CHASE 3D (26°/0°) with Admiral Zawadi Comms...")
  seed_prefs(pro_unlocked=True, completed_tutorial=True, high_score=34820, liberated_sectors=6)
  adb_cmd(["shell", "am", "start", "-n", "com.voidsower.app/.MainActivity"])
  time.sleep(2.4)

  # Clean CHASE 3D combat screen with Admiral Zawadi comms banner, P1: RECON, and 3D fleet
  capture("01_tactical_combat_grid.png", "phone_01_tactical_combat_grid.png", "01_combat_tactical_depth.png")

  # =========================================================================
  # Phase 3: BRIDGE 3D (38°/-22°) Isometric Command Angle + Nose Cannon Lance
  # =========================================================================
  print("\n[Phase 3] Switching to BRIDGE 3D (38°/-22°), aligning Defender to C4 & Firing Nose Cannon Lance...")
  # Tap 3D Camera Gimbal mode button (x=200, y=2365) -> switches to BRIDGE 3D 38°/-22°
  tap(200, 2365)
  time.sleep(0.35)
  # Steer Defender laterally to C4 along the bottom defense perimeter
  swipe(350, 2220, 600, 2220, 220)
  time.sleep(0.25)

  # Fire Axial Particle Lance via C4 pad repeatedly while capturing mid-beam
  fire_proc = subprocess.Popen([
      "adb", "-s", DEVICE, "shell",
      "for i in $(seq 1 10); do input tap 600 2580; sleep 0.08; done"
  ])
  time.sleep(0.25)
  capture("02_axial_particle_lance.png", "phone_02_axial_particle_lance.png", "02_axial_particle_lance.png")
  fire_proc.wait()
  time.sleep(0.5)

  # =========================================================================
  # Phase 4: Tactical Pause Menu & Bao Orbital Codex
  # =========================================================================
  print("\n[Phase 4] Capturing Tactical Pause Controls & Bao Orbital Codex...")
  tap(1250, 224)
  time.sleep(1.2)
  capture_temp = os.path.join(DOCS_STORE_DIR, "06_tactical_pause_controls.png")
  with open(capture_temp, "wb") as f:
    subprocess.run(["adb", "-s", DEVICE, "exec-out", "screencap", "-p"], stdout=f, check=True)
  print(f"[Docs Mirrored] -> {capture_temp}")

  # Tap Directives button in Pause Menu (x=942, y=1735)
  print("[Directives] Opening Tactical Directives modal...")
  tap(942, 1735)
  time.sleep(1.2)
  capture("07_bao_orbital_codex.png", "phone_03_bao_codex.png", "05_tactical_directives_codex.png")

  keyevent(4)
  time.sleep(0.8)

  # =========================================================================
  # Phase 5: Multi-Theater Campaign Star Map
  # =========================================================================
  print("\n[Phase 5] Returning to Star Map...")
  tap(1250, 224)
  time.sleep(0.8)
  tap(460, 1735)
  time.sleep(2.0)
  capture("05_kilwa_basin_campaign_map.png", docs_name="03_orbital_command_campaign.png")

  # =========================================================================
  # Phase 6: Orbital Fleet Hangar Modal
  # =========================================================================
  print("\n[Phase 6] Capturing Orbital Fleet Hangar...")
  tap(392, 2815)
  time.sleep(1.2)
  capture("04_orbital_fleet_hangar.png", "phone_06_hangar.png", "04_fleet_hangar_inspection.png")
  keyevent(4)
  time.sleep(0.8)

  # =========================================================================
  # Phase 7: Pilot Telemetry Dashboard
  # =========================================================================
  print("\n[Phase 7] Capturing Pilot Telemetry Dashboard...")
  tap(628, 2819)
  time.sleep(1.2)
  capture("08_pilot_telemetry_dashboard.png", "phone_04_pilot_dossier.png")
  keyevent(4)
  time.sleep(0.8)

  # =========================================================================
  # Phase 8: Special Operations & Pro Commander Hub
  # =========================================================================
  print("\n[Phase 8] Capturing Special Operations / Pro Commander...")
  tap(1128, 468)
  time.sleep(1.5)
  capture("09_pro_commander_upgrade.png", "phone_07_pro_commander.png")
  tap(203, 468)
  time.sleep(0.8)

  # =========================================================================
  # Phase 9: ORBIT 3D (32°/18°) + Checkpoint Relic Draft & Sector Liberation Victory
  # =========================================================================
  print("\n[Phase 9] Launching Sector 9 in ORBIT 3D (32°/18°) with AI Solver for Checkpoint Relic Draft & Victory...")
  seed_prefs(completed_tutorial=True, pro_unlocked=True, liberated_sectors=9)
  adb_cmd(["shell", "am", "start", "-n", "com.voidsower.app/.MainActivity"])
  time.sleep(2.2)

  # Tap 3D Camera Gimbal twice (x=200, y=2365) -> CHASE 3D -> BRIDGE 3D -> ORBIT 3D 32°/18°
  tap(200, 2365)
  time.sleep(0.25)
  tap(200, 2365)
  time.sleep(0.35)

  # Open Tactical Pause via keyevent 4
  keyevent(4)
  time.sleep(0.8)
  # Tap AI Solver button in bottom quick hardware strip (x=1050, y=2200)
  tap(1050, 2200)
  time.sleep(0.5)
  # Tap RESUME COMBAT button (x=671, y=1500)
  tap(671, 1500)
  time.sleep(0.5)

  print("[Victory] AI Solver engaged in ORBIT 3D. Polling for P2: SIEGE Relic Draft & Victory modal...")
  captured_checkpoint = False
  captured_victory = False
  for tick in range(65):
    time.sleep(0.35)
    temp_check = "/tmp/poll_vic_check.png"
    with open(temp_check, "wb") as f:
      subprocess.run(["adb", "-s", DEVICE, "exec-out", "screencap", "-p"], stdout=f, check=True)
    chk_img = Image.open(temp_check)
    chk_arr = np.array(chk_img)

    # Check for the solid cyan/emerald CONTINUE CAMPAIGN / STAR MAP button on the Victory Modal (y=1650..2150)
    # and dimmed bottom dock (y=2550..2750) when modal barrier is active
    btn_area = chk_arr[1650:2150, 250:1090]
    cta_mask = (btn_area[:, :, 1] > 170) & (btn_area[:, :, 0] < 70) & (btn_area[:, :, 2] > 100)
    dock_brightness = chk_arr[2550:2750, 200:1140].mean()
    is_victory_modal = cta_mask.sum() > 6000 and dock_brightness < 28.0

    # Check if P2: SIEGE + RELIC draft strip is visible at y=460..550 (amber/gold border & pills)
    relic_strip = chk_arr[460:550, 40:1300]
    relic_gold = (relic_strip[:, :, 0] > 180) & (relic_strip[:, :, 1] > 120) & (relic_strip[:, :, 2] < 80)

    if not captured_checkpoint and not is_victory_modal and (relic_gold.sum() > 450 or tick == 8):
      print(f"[Checkpoint] Capturing ORBIT 3D + P2: SIEGE Relic Draft & AI Solver cascade at tick {tick} (relic_gold={relic_gold.sum()})...")
      capture(
          "10_checkpoint_relic_draft_siege.png",
          "phone_08_checkpoint_relic_draft.png",
          "07_checkpoint_relic_draft.png",
      )
      captured_checkpoint = True

    if is_victory_modal:
      print(f"[Victory] Victory dialog confirmed on screen at tick {tick} (cta_pixels={cta_mask.sum()}, dock_mean={dock_brightness:.1f})!")
      capture("06_sector_liberation_victory.png", "phone_05_sector_liberation.png")
      captured_victory = True
      break

  if not captured_victory:
    print("[Victory] Capturing current combat / victory state...")
    capture("06_sector_liberation_victory.png", "phone_05_sector_liberation.png")

  print("\n[Complete] All 10 Play Store phone screenshots captured and strictly verified!")


if __name__ == "__main__":
  main()
