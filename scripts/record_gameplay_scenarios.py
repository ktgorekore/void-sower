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

"""Automates gameplay demonstration scenarios on the Android emulator for video capture."""

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

  # 1. 0s..4s: Flight Academy Tutorial shown over combat arena
  wait_until(4.0)
  print("[Timeline 4.0s] Dismiss Flight Academy (tap SKIP at x=210, y=2060)")
  tap(210, 2060)

  # 2. 5.0s: Open Tactical Pause and navigate to Star Map
  wait_until(5.0)
  print("[Timeline 5.0s] Open Tactical Pause menu (tap x=1215, y=335)")
  tap(1215, 335)

  wait_until(5.8)
  print("[Timeline 5.8s] Open Star Map (tap MAP at x=320, y=1820)")
  tap(320, 1820)

  # 3. 7.8s: Inspect Fleet Hangar
  wait_until(7.8)
  print("[Timeline 7.8s] Open Fleet Hangar (tap Rocket icon at x=700, y=240)")
  tap(700, 240)

  wait_until(10.5)
  print("[Timeline 10.5s] Close Fleet Hangar")
  keyevent(4)

  # 4. 11.8s: Inspect Pilot Dossier
  wait_until(11.8)
  print("[Timeline 11.8s] Open Pilot Dossier (tap Profile icon at x=830, y=240)")
  tap(830, 240)

  wait_until(14.5)
  print("[Timeline 14.5s] Close Pilot Dossier")
  keyevent(4)

  # 5. 15.8s: Inspect Bao Codex
  wait_until(15.8)
  print("[Timeline 15.8s] Open Bao Codex (tap Codex icon at x=980, y=240)")
  tap(980, 240)

  wait_until(18.5)
  print("[Timeline 18.5s] Close Bao Codex")
  keyevent(4)

  # 6. 20.0s: Return to Combat Arena
  wait_until(20.0)
  print("[Timeline 20.0s] Return to Combat Arena")
  keyevent(4)

  # 7. 22.5s: Slide flagship laterally
  wait_until(22.5)
  print("[Timeline 22.5s] Slide dreadnought laterally along corridor (y=2200)")
  swipe(400, 2200, 950, 2200, 350)

  wait_until(25.0)
  print("[Timeline 25.0s] Slide back to center (y=2200)")
  swipe(950, 2200, 672, 2200, 250)

  # 8. 27.0s: Discharge Axial Particle Lance
  wait_until(27.0)
  print("[Timeline 27.0s] Tap Axial Discharge (x=500, y=2770)")
  tap(500, 2770)

  # 9. 29.5s: Sow bay sequentially
  wait_until(29.5)
  print("[Timeline 29.5s] Sow Frontline Bay (tap SOW RIGHT at x=850, y=2770)")
  tap(850, 2770)

  wait_until(32.0)
  print("[Timeline 32.0s] Sow Frontline Bay again")
  tap(850, 2770)

  # 10. 35.0s: Engage Autonomous AI Tactical Solver in Right Wing (x=1050, y=335)
  wait_until(35.0)
  print("[Timeline 35.0s] Engage AI Tactical Solver (tap x=1050, y=335 in Right Wing)")
  tap(1050, 335)

  print("[Record 60s] AI Solver active, autonomously clearing orbital corridors...")
  rec_proc.wait()
  print("[Record 60s] Screen recording completed successfully!")


def record_30s_showcase():
  print("\n[Record 30s] Setting up Tactical Solver Showcase...")
  reset_app_pro_state(completed_tutorial=True)

  print("[Record 30s] Starting Void Sower main activity...")
  adb_cmd(["shell", "am", "start", "-n", "com.voidsower.app/.MainActivity"])
  time.sleep(4.0)

  # Ensure combat arena is fresh via Pause -> Restart
  print("[Record 30s] Restarting fresh combat sortie (tap PAUSE x=1215, y=335 then RESTART x=350, y=1670)...")
  tap(1215, 335)
  time.sleep(0.8)
  tap(350, 1670)
  time.sleep(1.2)

  # Activate solver immediately in Right Wing
  print("[Record 30s] Engaging AI Tactical Solver (tap x=1050, y=335 in Right Wing)...")
  tap(1050, 335)
  time.sleep(0.5)

  print("[Record 30s] Launching 30s showcase recording...")
  rec_proc = subprocess.Popen([
      "adb", "-s", DEVICE, "shell",
      "screenrecord", "--size", "1080x2400", "--bit-rate", "14000000", "--time-limit", "30",
      "/sdcard/solver_30s.mp4"
  ])

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
