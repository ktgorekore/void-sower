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

DEVICE = "emulator-5554"
SCREENSHOTS_DIR = "/home/kelvingorekore/projects/void-sower/store_listing/screenshots/tablet"


def adb_cmd(args):
  cmd = ["adb", "-s", DEVICE] + args
  return subprocess.run(cmd, capture_output=True, text=True)


def tap(x, y):
  adb_cmd(["shell", "input", "tap", str(x), str(y)])


def keyevent(code):
  adb_cmd(["shell", "input", "keyevent", str(code)])


def capture(dest_name):
  dest_path = os.path.join(SCREENSHOTS_DIR, dest_name)
  print(f"[Tablet Capture] Grabbing {dest_name}...")
  with open(dest_path, "wb") as f:
    subprocess.run(["adb", "-s", DEVICE, "exec-out", "screencap", "-p"], stdout=f)
  print(f"[Saved] -> {dest_path}")
  return dest_path


def main():
  os.makedirs(SCREENSHOTS_DIR, exist_ok=True)

  try:
    print("[Display] Setting tablet display configuration (2560x1600 @ 320 dpi)...")
    adb_cmd(["shell", "wm", "size", "2560x1600"])
    adb_cmd(["shell", "wm", "density", "320"])
    time.sleep(1.5)

    adb_cmd(["shell", "settings", "put", "secure", "immersive_mode_confirmations", "confirmed"])

    # Reset state: force-stop app, clear data, and seed persistent Pro unlock
    print("[Init] Resetting app state & seeding Pro entitlement...")
    adb_cmd(["shell", "am", "force-stop", "com.voidsower.app"])
    time.sleep(0.5)
    adb_cmd(["shell", "pm", "clear", "com.voidsower.app"])
    time.sleep(1.0)

    pref_xml = (
        '<?xml version="1.0" encoding="utf-8" standalone="yes" ?>'
        '<map>'
        '<boolean name="flutter.void_sower_pro_unlocked" value="true" />'
        '<boolean name="flutter.void_sower_completed_tutorial" value="false" />'
        '</map>'
    )
    import base64
    b64_val = base64.b64encode(pref_xml.encode("utf-8")).decode("ascii")
    adb_cmd([
        "shell",
        "run-as",
        "com.voidsower.app",
        "sh",
        "-c",
        f"mkdir -p shared_prefs && echo {b64_val} | base64 -d > shared_prefs/FlutterSharedPreferences.xml",
    ])
    time.sleep(0.5)

    # Launch App directly into Combat Arena
    print("[Launch] Starting Void Sower main activity on tablet...")
    adb_cmd(["shell", "am", "start", "-n", "com.voidsower.app/.MainActivity"])
    time.sleep(4.0)

    # 1. Screenshot 05: Flight Academy Onboarding on Tablet
    print("[Tablet Academy] Capturing 05_tablet_flight_academy.png...")
    capture("05_tablet_flight_academy.png")

    # Dismiss tutorial overlay (tap SKIP near bottom of briefing card)
    print("[Tablet Combat] Dismissing Flight Academy tutorial overlay...")
    tap(1100, 1100)
    time.sleep(1.5)

    # 2. Screenshot 01: Tactical Combat Grid on Tablet (Centered 580 dp viewport)
    print("[Tablet Combat] Capturing 01_tablet_tactical_combat.png...")
    capture("01_tablet_tactical_combat.png")

    # 3. Screenshot 02: Sowing Trajectory & Axial Lance
    print("[Tablet Combat] Discharging Axial Particle Lance...")
    tap(1060, 1480)
    time.sleep(0.15)
    capture("02_tablet_sowing_trajectory.png")
    time.sleep(1.0)

    # 4. Screenshot 06: Bao Codex on Tablet (Tap RULES button in Tier 1)
    print("[Tablet Codex] Opening Bao Codex dialog...")
    tap(1620, 90)
    time.sleep(1.2)
    capture("06_tablet_bao_codex.png")
    keyevent(4)
    time.sleep(0.8)

    # 5. Navigate to Star Map: Tap MAP button in Tier 1
    print("[Tablet Map] Navigating to Star Map...")
    tap(750, 90)
    time.sleep(2.0)

    # Screenshot 03: Tablet Campaign Map
    print("[Tablet Map] Capturing 03_tablet_campaign_map.png...")
    capture("03_tablet_campaign_map.png")

    # 6. Screenshot 04: Tablet Fleet Hangar
    print("[Tablet Hangar] Opening Fleet Hangar...")
    tap(2100, 80)
    time.sleep(1.2)
    capture("04_tablet_fleet_hangar.png")
    keyevent(4)
    time.sleep(0.8)

    print("\n[Complete] All 6 Play Store tablet screenshots captured successfully!")

  finally:
    print("[Display] Restoring default display resolution and density...")
    adb_cmd(["shell", "wm", "size", "reset"])
    adb_cmd(["shell", "wm", "density", "reset"])
    time.sleep(1.0)


if __name__ == "__main__":
  main()
