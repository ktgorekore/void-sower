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

"""Automates gameplay demonstration scenarios on the Android emulator for video capture.

Captures:
1. 60s comprehensive narrated tutorial showing count-and-capture, multi-theater campaigns,
   evasive invaders, respawning swarm hordes, and Pro Commander benefits.
2. 30s high-intensity combat showcase highlighting Phantom Drift evasive craft and Void Swarm
   respawning horde incursions with tactical core siphon.
"""

import os
import subprocess
import sys
import time

DEVICE = "emulator-5554"


def adb_cmd(args):
  cmd = ["adb", "-s", DEVICE] + args
  return subprocess.run(cmd, capture_output=True, text=True)


def tap(x, y):
  adb_cmd(["shell", "input", "tap", str(x), str(y)])


def swipe(x1, y1, x2, y2, duration_ms=200):
  adb_cmd(["shell", "input", "swipe", str(x1), str(y1), str(x2), str(y2), str(duration_ms)])


def keyevent(code):
  adb_cmd(["shell", "input", "keyevent", str(code)])


def reset_app_pro_state(completed_tutorial=False):
  """Resets app state cleanly via pm clear and injects persistent SharedPreferences."""
  adb_cmd(["shell", "settings", "put", "secure", "immersive_mode_confirmations", "confirmed"])
  adb_cmd(["shell", "am", "force-stop", "com.voidsower.app"])
  time.sleep(0.5)
  adb_cmd(["shell", "pm", "clear", "com.voidsower.app"])
  time.sleep(1.0)

  pref_xml = (
      '<?xml version="1.0" encoding="utf-8" standalone="yes" ?>\n'
      '<map>\n'
      '    <boolean name="flutter.void_sower_pro_unlocked" value="true" />\n'
      f'    <boolean name="flutter.void_sower_completed_tutorial" value="{"true" if completed_tutorial else "false"}" />\n'
      '    <int name="flutter.void_sower_high_score" value="12480" />\n'
      '</map>\n'
  )
  with open("/tmp/prefs.xml", "w") as f:
    f.write(pref_xml)
  subprocess.run(["adb", "-s", DEVICE, "push", "/tmp/prefs.xml", "/data/local/tmp/prefs.xml"], check=True)
  adb_cmd(["shell", "run-as", "com.voidsower.app", "mkdir", "-p", "shared_prefs"])
  adb_cmd(["shell", "run-as", "com.voidsower.app", "cp", "/data/local/tmp/prefs.xml", "shared_prefs/FlutterSharedPreferences.xml"])
  adb_cmd(["shell", "run-as", "com.voidsower.app", "chmod", "660", "shared_prefs/FlutterSharedPreferences.xml"])
  time.sleep(0.5)


def record_60s_tutorial():
  print("[Record 60s] Resetting app state to fresh cadet profile with Pro unlocked...")
  reset_app_pro_state(completed_tutorial=True)

  print("[Record 60s] Starting Void Sower main activity directly into combat arena...")
  adb_cmd(["shell", "am", "start", "-n", "com.voidsower.app/.MainActivity"])
  time.sleep(3.5)

  print("[Record 60s] Launching screenrecord (60s at 1080x2400)...")
  rec_proc = subprocess.Popen([
      "adb", "-s", DEVICE, "shell",
      "screenrecord", "--size", "1080x2400", "--bit-rate", "16000000", "--time-limit", "60",
      "/sdcard/gameplay_60s.mp4"
  ])

  t0 = time.time()

  def wait_until(target_sec):
    elapsed = time.time() - t0
    rem = target_sec - elapsed
    if rem > 0:
      time.sleep(rem)

  # Phase 1: 0s..7.6s — Threat & Corridors (Invaders descending down C2 and C7)
  print("[Timeline 0s..7.6s] Observing descending assault craft down eight corridors...")

  # Phase 2: 7.6s..15.5s — Aiming & Corridor Alignment
  wait_until(8.5)
  print("[Timeline 8.5s] Align prow to Corridor 2 (tap C2 notch at x=252, y=2406)")
  tap(252, 2406)

  wait_until(11.5)
  print("[Timeline 11.5s] Align prow to Corridor 7 (tap C7 notch at x=1092, y=2406)")
  tap(1092, 2406)

  wait_until(14.0)
  print("[Timeline 14.0s] Re-align prow to Corridor 2 (tap C2 notch at x=252, y=2406)")
  tap(252, 2406)

  # Phase 3: 15.5s..25.2s — 16-Bay Capacitor Ring & Sowing Cascades
  wait_until(16.5)
  print("[Timeline 16.5s] Focus frontline Bay 9 under C2 (tap x=252, y=2530)")
  tap(252, 2530)

  wait_until(19.5)
  print("[Timeline 19.5s] Sow plasma cores clockwise across frontline bays (swipe Bay 9 rightwards)")
  swipe(252, 2530, 588, 2530, 200)

  wait_until(23.0)
  print("[Timeline 23.0s] Select frontline Bay 9 (tap x=252, y=2530)")
  tap(252, 2530)

  # Phase 4: 25.2s..35.2s — Axial Particle Lance Discharge
  wait_until(25.5)
  print("[Timeline 25.5s] Tap Axial Discharge bar (tap x=672, y=2830)")
  tap(672, 2830)

  wait_until(28.0)
  print("[Timeline 28.0s] Quick-fire secondary prow pulse (tap arena x=252, y=1500)")
  tap(252, 1500)

  # Phase 5: 35.2s..43.3s — Harmonic Shield Deflection vs EMP Breaches
  wait_until(36.0)
  print("[Timeline 36.0s] Align charged canopy under C7 craft (tap C7 at x=1092, y=2406)")
  tap(1092, 2406)

  wait_until(39.5)
  print("[Timeline 39.5s] Re-align charged canopy under C2 craft (tap C2 at x=252, y=2406)")
  tap(252, 2406)

  # Phase 6: 43.3s..60.0s — Autonomous AI Tactical Advisor & Sector Victory
  wait_until(43.5)
  print("[Timeline 43.5s] Open Tactical Pause menu (tap x=1240, y=225)")
  tap(1240, 225)

  wait_until(44.3)
  print("[Timeline 44.3s] Engage AI Tactical Auto-Solver in Pause Dialog (tap x=672, y=1630)")
  tap(672, 1630)

  wait_until(45.0)
  print("[Timeline 45.0s] Resume Sortie with AI Solver Active (tap x=250, y=1520)")
  tap(250, 1520)

  print("[Record 60s] AI Solver active, executing Grandmaster cascades toward victory...")
  rec_proc.wait()
  print("[Record 60s] Screen recording completed successfully!")


def record_30s_showcase():
  print("\n[Record 30s] Setting up Tactical Solver Showcase (Evasive + Respawning Invaders)...")
  reset_app_pro_state(completed_tutorial=True)

  print("[Record 30s] Starting Void Sower main activity...")
  adb_cmd(["shell", "am", "start", "-n", "com.voidsower.app/.MainActivity"])
  time.sleep(3.5)

  # Navigate to Phantom Drift (Sector 10: Evasive Invaders)
  print("[Record 30s] Navigating to Phantom Drift (Sector 10)...")
  tap(1240, 225) # Pause
  time.sleep(0.8)
  tap(310, 1820) # Map
  time.sleep(1.5)
  tap(672, 680)  # Phantom Drift theater tab
  time.sleep(0.8)
  tap(915, 1040) # Sector 10 AI launch
  time.sleep(1.8)

  print("[Record 30s] Launching 30s showcase recording...")
  rec_proc = subprocess.Popen([
      "adb", "-s", DEVICE, "shell",
      "screenrecord", "--size", "1080x2400", "--bit-rate", "14000000", "--time-limit", "30",
      "/sdcard/solver_30s.mp4"
  ])

  t0 = time.time()

  def wait_until(target_sec):
    elapsed = time.time() - t0
    rem = target_sec - elapsed
    if rem > 0:
      time.sleep(rem)

  # Part 1: Phantom Drift (0s..14s) - Evasive Invaders with lateral thrusters
  print("[Showcase 0s..14s] Autonomous AI executing evasion intercepts in Phantom Drift...")

  # Part 2: Transition to Void Swarm (14s..17s) - Respawning Swarm Invaders
  wait_until(14.0)
  print("[Showcase 14.0s] Open Tactical Pause (tap x=1240, y=225)")
  tap(1240, 225)

  wait_until(14.8)
  print("[Showcase 14.8s] Open Star Map (tap MAP at x=310, y=1820)")
  tap(310, 1820)

  wait_until(16.0)
  print("[Showcase 16.0s] Switch to Void Swarm tab (tap x=1090, y=680)")
  tap(1090, 680)

  wait_until(16.8)
  print("[Showcase 16.8s] Launch Sector 19 Void Swarm with AI (tap AI at x=915, y=1040)")
  tap(915, 1040)

  # Part 3: Void Swarm (18s..30s) - Dense Respawning Horde with Tactical Core Siphon
  print("[Showcase 18s..30s] Autonomous AI managing dense swarm horde and core siphon...")

  rec_proc.wait()
  print("[Record 30s] Showcase recording completed successfully!")


if __name__ == "__main__":
  if len(sys.argv) > 1 and sys.argv[1] == "--showcase":
    record_30s_showcase()
  elif len(sys.argv) > 1 and sys.argv[1] == "--tutorial":
    record_60s_tutorial()
  else:
    record_60s_tutorial()
    record_30s_showcase()
