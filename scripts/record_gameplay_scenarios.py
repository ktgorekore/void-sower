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
  reset_app_pro_state(completed_tutorial=False)

  print("[Record 60s] Starting Void Sower main activity...")
  adb_cmd(["shell", "am", "start", "-n", "com.voidsower.app/.MainActivity"])
  time.sleep(3.5)

  print("[Record 60s] Launching screenrecord (60s at 1080x2400)...")
  rec_proc = subprocess.Popen([
      "adb", "-s", DEVICE, "shell",
      "screenrecord", "--size", "1080x2400", "--bit-rate", "14000000", "--time-limit", "60",
      "/sdcard/gameplay_60s.mp4"
  ])

  t0 = time.time()

  def wait_until(target_sec):
    elapsed = time.time() - t0
    rem = target_sec - elapsed
    if rem > 0:
      time.sleep(rem)

  # 1. 0s..4s: Flight Academy Tutorial overlay shown over combat arena
  wait_until(3.5)
  print("[Timeline 3.5s] Dismiss Flight Academy (tap SKIP at x=210, y=2060)")
  tap(210, 2060)

  # 2. 4s..9s: Active Kilwa Basin Combat (Corridor evasion + axial lance discharge)
  wait_until(5.0)
  print("[Timeline 5.0s] Slide dreadnought laterally to evade incoming bombs")
  swipe(400, 2200, 950, 2200, 300)

  wait_until(6.5)
  print("[Timeline 6.5s] Align back to target corridor")
  swipe(950, 2200, 672, 2200, 250)

  wait_until(7.8)
  print("[Timeline 7.8s] Discharge Axial Particle Lance (tap x=500, y=2850)")
  tap(500, 2850)

  # 3. 9s..16s: Pause -> Multi-Theater Campaign Star Map
  wait_until(9.5)
  print("[Timeline 9.5s] Open Tactical Pause menu (tap x=889, y=330)")
  tap(889, 330)

  wait_until(10.5)
  print("[Timeline 10.5s] Open Star Map (tap MAP at x=310, y=1740)")
  tap(310, 1740)

  wait_until(12.0)
  print("[Timeline 12.0s] Open Pilot Telemetry Dossier (tap x=260, y=700)")
  tap(260, 700)

  wait_until(14.5)
  print("[Timeline 14.5s] Close Pilot Dossier")
  keyevent(4)

  # 4. 16s..27s: Switch to Phantom Drift Theater (Evasive Invaders)
  wait_until(16.0)
  print("[Timeline 16.0s] Switch to Phantom Drift theater tab (tap x=670, y=500)")
  tap(670, 500)

  wait_until(17.5)
  print("[Timeline 17.5s] Select Sector 10 Aldabra Shimmer Reef (tap ENGAGE at x=830, y=1280)")
  tap(830, 1280)

  wait_until(18.5)
  print("[Timeline 18.5s] Launch Phantom Drift Battle (tap ENGAGE BATTLE at x=675, y=2850)")
  tap(675, 2850)

  wait_until(21.0)
  print("[Timeline 21.0s] Phantom Drift active - fire particle lance at drifting invader")
  tap(500, 2850)

  wait_until(23.5)
  print("[Timeline 23.5s] Sow capacitor bay to track lateral movement")
  tap(440, 2520)
  time.sleep(0.3)
  tap(500, 2850)

  # 5. 27s..38s: Switch to Void Swarm Theater (Respawning Invaders & Core Siphon)
  wait_until(27.0)
  print("[Timeline 27.0s] Open Tactical Pause to return to Star Map (tap x=889, y=330)")
  tap(889, 330)

  wait_until(28.0)
  print("[Timeline 28.0s] Open Star Map (tap MAP at x=310, y=1740)")
  tap(310, 1740)

  wait_until(29.5)
  print("[Timeline 29.5s] Switch to Void Swarm theater tab (tap x=1090, y=500)")
  tap(1090, 500)

  wait_until(31.0)
  print("[Timeline 31.0s] Select Sector 19 Comoros Hive Gate (tap ENGAGE at x=830, y=1280)")
  tap(830, 1280)

  wait_until(32.0)
  print("[Timeline 32.0s] Launch Void Swarm Battle (tap ENGAGE BATTLE at x=675, y=2850)")
  tap(675, 2850)

  # 6. 38s..50s: Engage Autonomous AI Tactical Solver (Pro Feature)
  wait_until(36.5)
  print("[Timeline 36.5s] Engage AI Tactical Solver (tap x=1020, y=230 in HUD)")
  tap(1020, 230)

  print("[Record 60s] AI Solver active, executing optimal cascades against swarm...")
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
  tap(889, 330)  # Pause
  time.sleep(0.8)
  tap(310, 1740) # Map
  time.sleep(1.5)
  tap(670, 500)  # Phantom Drift tab
  time.sleep(0.8)
  tap(830, 1280) # Sector 10 ENGAGE
  time.sleep(0.8)
  tap(675, 2850) # ENGAGE BATTLE
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
  wait_until(1.0)
  print("[Showcase 1.0s] Engage AI Tactical Solver in Phantom Drift (tap x=1020, y=230)")
  tap(1020, 230)

  # Part 2: Transition to Void Swarm (14s..17s) - Respawning Swarm Invaders
  wait_until(14.0)
  print("[Showcase 14.0s] Open Tactical Pause (tap x=889, y=330)")
  tap(889, 330)

  wait_until(14.8)
  print("[Showcase 14.8s] Open Star Map (tap MAP at x=310, y=1740)")
  tap(310, 1740)

  wait_until(16.0)
  print("[Showcase 16.0s] Switch to Void Swarm tab (tap x=1090, y=500)")
  tap(1090, 500)

  wait_until(16.8)
  print("[Showcase 16.8s] Select Sector 19 (tap ENGAGE at x=830, y=1280)")
  tap(830, 1280)

  wait_until(17.5)
  print("[Showcase 17.5s] Launch Void Swarm Battle (tap ENGAGE BATTLE at x=675, y=2850)")
  tap(675, 2850)

  # Part 3: Void Swarm (18s..30s) - Dense Respawning Horde with Tactical Core Siphon
  wait_until(19.5)
  print("[Showcase 19.5s] Engage AI Tactical Solver in Void Swarm (tap x=1020, y=230)")
  tap(1020, 230)

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
