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


def record_60s_tutorial():
  print("[Record 60s] Resetting app state to fresh cadet profile...")
  adb_cmd(["shell", "settings", "put", "secure", "immersive_mode_confirmations", "confirmed"])
  adb_cmd(["shell", "pm", "clear", "com.voidsower.app"])
  time.sleep(1.0)
  adb_cmd([
      "shell",
      "run-as",
      "com.voidsower.app",
      "sh",
      "-c",
      "mkdir -p shared_prefs && echo '<?xml version=\"1.0\" encoding=\"utf-8\" standalone=\"yes\" ?><map><boolean name=\"flutter.void_sower_pro_unlocked\" value=\"true\" /></map>' > shared_prefs/FlutterSharedPreferences.xml",
  ])
  time.sleep(0.5)
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

  # 1. Inspect Fleet Hangar
  wait_until(2.0)
  print("[Timeline 2.0s] Open Fleet Hangar")
  tap(696, 243)

  wait_until(4.5)
  print("[Timeline 4.5s] Close Fleet Hangar")
  keyevent(4)

  # 2. Inspect Pilot Dossier
  wait_until(5.8)
  print("[Timeline 5.8s] Open Pilot Dossier")
  tap(840, 243)

  wait_until(8.2)
  print("[Timeline 8.2s] Close Pilot Dossier")
  keyevent(4)

  # 3. Inspect Bao Codex
  wait_until(9.5)
  print("[Timeline 9.5s] Open Bao Codex")
  tap(984, 243)

  wait_until(12.0)
  print("[Timeline 12.0s] Close Bao Codex")
  keyevent(4)

  # 4. Engage Sector 1 (Zanzibar Reef Gate)
  wait_until(13.2)
  print("[Timeline 13.2s] Engage Sector 1")
  tap(1105, 957)

  # 5. Briefing overlay displayed (Combat paused)
  wait_until(15.5)
  print("[Timeline 15.5s] Briefing displayed, letting user review...")

  wait_until(18.0)
  print("[Timeline 18.0s] Launch combat from briefing (SKIP/DISMISS)")
  tap(293, 2130)

  # 6. Active combat maneuvers
  wait_until(20.5)
  print("[Timeline 20.5s] Slide dreadnought laterally")
  swipe(400, 2000, 850, 2000, 250)

  wait_until(22.5)
  print("[Timeline 22.5s] Double tap flagship to quick-fire axial prow lance")
  tap(850, 2000)
  time.sleep(0.08)
  tap(850, 2000)

  wait_until(25.0)
  print("[Timeline 25.0s] Tap Axial Discharge button")
  tap(938, 2809)

  wait_until(27.5)
  print("[Timeline 27.5s] Sow bay sequentially")
  swipe(590, 2565, 950, 2565, 200)

  # 7. Autonomous AI Tactical Solver demonstration
  wait_until(30.0)
  print("[Timeline 30.0s] Tap AI Tactical Solver")
  tap(624, 332)
  time.sleep(0.5)
  print("[Timeline 30.5s] Unlock Pro Commander license")
  tap(671, 2106)
  time.sleep(0.6)
  print("[Timeline 31.1s] Engage AI Tactical Solver")
  tap(624, 332)

  print("[Record 60s] AI Solver active, allowing autonomous tactical clearing...")
  rec_proc.wait()
  print("[Record 60s] Screen recording completed successfully!")


def record_30s_showcase():
  print("\n[Record 30s] Setting up Tactical Solver Showcase...")
  adb_cmd(["shell", "am", "force-stop", "com.voidsower.app"])
  time.sleep(1.0)
  adb_cmd(["shell", "am", "start", "-n", "com.voidsower.app/.MainActivity"])
  time.sleep(2.5)
  # Tap Sector 1
  tap(1105, 957)
  time.sleep(1.2)
  # Dismiss tutorial if open
  tap(293, 2130)
  time.sleep(0.5)
  # Activate solver
  tap(624, 332)
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
