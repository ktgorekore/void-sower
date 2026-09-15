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


def main():
  os.makedirs(SCREENSHOTS_DIR, exist_ok=True)
  os.makedirs(ASSETS_DIR, exist_ok=True)

  adb_cmd(["shell", "settings", "put", "secure", "immersive_mode_confirmations", "confirmed"])

  # 1. Reset state to clean cadet profile with tutorial reset
  print("[Init] Resetting app state...")
  adb_cmd(["shell", "pm", "clear", "com.voidsower.app"])
  time.sleep(1.0)
  # Pre-seed Pro license
  adb_cmd([
      "shell",
      "run-as",
      "com.voidsower.app",
      "sh",
      "-c",
      "mkdir -p shared_prefs && echo '<?xml version=\"1.0\" encoding=\"utf-8\" standalone=\"yes\" ?><map><boolean name=\"flutter.void_sower_pro_unlocked\" value=\"true\" /></map>' > shared_prefs/FlutterSharedPreferences.xml",
  ])
  time.sleep(0.5)

  # Launch App
  adb_cmd(["shell", "am", "start", "-n", "com.voidsower.app/.MainActivity"])
  time.sleep(3.5)

  # Screenshot 05: Kilwa Basin Campaign Map
  capture("05_kilwa_basin_campaign_map.png")

  # Screenshot 04: Orbital Fleet Hangar
  print("[Hangar] Opening Fleet Hangar...")
  tap(515, 240)
  time.sleep(1.2)
  capture("04_orbital_fleet_hangar.png")
  shutil.copyfile(
      os.path.join(SCREENSHOTS_DIR, "04_orbital_fleet_hangar.png"),
      os.path.join(ASSETS_DIR, "phone_06_hangar.png"),
  )
  keyevent(4)
  time.sleep(0.8)

  # Screenshot 08: Pilot Telemetry Dashboard (Profile)
  print("[Profile] Opening Pilot Dossier...")
  tap(625, 240)
  time.sleep(1.2)
  capture("08_pilot_telemetry_dashboard.png")
  shutil.copyfile(
      os.path.join(SCREENSHOTS_DIR, "08_pilot_telemetry_dashboard.png"),
      os.path.join(ASSETS_DIR, "phone_04_pilot_dossier.png"),
  )
  keyevent(4)
  time.sleep(0.8)

  # Screenshot 07: Bao Orbital Codex
  print("[Codex] Opening Bao Codex...")
  tap(735, 240)
  time.sleep(1.2)
  capture("07_bao_orbital_codex.png")
  shutil.copyfile(
      os.path.join(SCREENSHOTS_DIR, "07_bao_orbital_codex.png"),
      os.path.join(ASSETS_DIR, "phone_03_bao_codex.png"),
  )
  keyevent(4)
  time.sleep(0.8)

  # Engage Sector 1 -> Screenshot 03: Flight Academy Onboarding
  print("[Sector 1] Engaging Zanzibar Reef Gate...")
  tap(1104, 958)
  time.sleep(1.5)
  capture("03_flight_academy_onboarding.png")
  shutil.copyfile(
      os.path.join(SCREENSHOTS_DIR, "03_flight_academy_onboarding.png"),
      os.path.join(ASSETS_DIR, "phone_02_flight_academy.png"),
  )

  # Dismiss tutorial overlay -> Active Combat
  print("[Combat] Launching active combat...")
  tap(293, 2130)
  time.sleep(2.0)

  # Screenshot 01: Tactical Combat Grid
  capture("01_tactical_combat_grid.png")
  shutil.copyfile(
      os.path.join(SCREENSHOTS_DIR, "01_tactical_combat_grid.png"),
      os.path.join(ASSETS_DIR, "phone_01_tactical_combat_grid.png"),
  )

  # Trigger Axial Discharge / Lance fire -> Screenshot 02: Quadratic Lance Discharge
  print("[Combat] Discharging Axial Lance...")
  tap(938, 2809)
  time.sleep(0.12)
  capture("02_quadratic_lance_discharge.png")
  shutil.copyfile(
      os.path.join(SCREENSHOTS_DIR, "02_quadratic_lance_discharge.png"),
      os.path.join(ASSETS_DIR, "phone_02_quadratic_lances.png"),
  )

  # Activate AI Solver to clear the wave and achieve victory
  print("[Solver] Activating AI Tactical Solver to clear sector...")
  tap(624, 332)

  # Wait for victory dialog (~15s)
  print("[Victory] Waiting for Sector Liberation...")
  time.sleep(14.0)
  capture("06_sector_liberation_victory.png")

  print("\n[Complete] All 8 Play Store phone screenshots recaptured successfully!")


if __name__ == "__main__":
  main()
