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
1. 60s comprehensive narrated tutorial showing 3D corridor alignment, Bao
   count-and-capture sowing, Quadratic M^2 Axial Particle Lances, Morabaraba
   Laser Fence barrages, and the native C++ MCTS AI Tactical Solver.
2. 30s high-intensity combat showcase highlighting Phantom Drift evasive craft
   and Void Swarm respawning horde incursions with AI Tactical Solver.
"""

import subprocess
import sys
import time

DEVICE = "emulator-5554"


def adb_cmd(args):
  cmd = ["adb", "-s", DEVICE] + args
  return subprocess.run(cmd, capture_output=True, text=True, check=False)


def tap(x, y):
  adb_cmd(["shell", "input", "tap", str(x), str(y)])


def swipe(x1, y1, x2, y2, duration_ms=200):
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


def reset_app_pro_state(completed_tutorial=True):
  """Seeds SharedPreferences with Pro unlocked and Sector 9 unlocked."""
  adb_cmd([
      "shell",
      "settings",
      "put",
      "secure",
      "immersive_mode_confirmations",
      "confirmed",
  ])
  adb_cmd(["shell", "am", "force-stop", "com.voidsower.app"])
  time.sleep(0.5)

  profile_json = (
      '{"id":"pilot_default","callsign":"Vanguard-01","insignia":"shonaStar",'
      '"lifetimeScore":48950,"enemiesDestroyed":248,"lancesFired":164,'
      '"maxCascadeLaps":6,"missionsPlayed":42,"victories":36,"defeats":6,'
      '"flawlessVictories":24,"totalSeedsSown":680,"flakBurstsTriggered":48,'
      '"totalCoresSaved":390,"currentStreak":9,"longestStreak":16,'
      '"lastPlayedDate":"2026-10-24","totalFlightTimeSeconds":8420,'
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
      '    <boolean name="flutter.void_sower_pro_unlocked" value="true" />\n'
      '    <boolean name="flutter.void_sower_ads_disabled" value="true" />\n'
      '    <boolean name="flutter.void_sower_completed_tutorial"'
      f' value="{"true" if completed_tutorial else "false"}" />\n'
      '    <int name="flutter.void_sower_high_score" value="48950" />\n'
      '    <int name="flutter.void_sower_liberated_sectors" value="9" />\n'
      '    <string name="flutter.void_sower_selected_chassis">'
      "mk4_golden_sovereign</string>\n"
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


def record_60s_tutorial():
  print("[Record 60s] Seeding Pro Commander state & staging Sector 9...")
  reset_app_pro_state(completed_tutorial=True)

  adb_cmd(["shell", "am", "start", "-n", "com.voidsower.app/.MainActivity"])
  time.sleep(2.4)
  tap(343, 224)  # Star Map
  time.sleep(1.4)
  tap(1100, 2235)  # Engage Sector 9
  time.sleep(1.2)

  print("[Record 60s] Launching screenrecord (60s at 1080x2400)...")
  adb_cmd(["shell", "rm", "-f", "/sdcard/gameplay_60s.mp4"])
  rec_proc = subprocess.Popen([
      "adb",
      "-s",
      DEVICE,
      "shell",
      "screenrecord",
      "--size",
      "1080x2400",
      "--bit-rate",
      "14000000",
      "--time-limit",
      "60",
      "/sdcard/gameplay_60s.mp4",
  ])

  t0 = time.time()

  def wait_until(target_sec):
    rem = target_sec - (time.time() - t0)
    if rem > 0:
      time.sleep(rem)

  # Phase 1: 0s..8.0s — Threat & 8 Corridors
  wait_until(2.0)
  tap(1180, 2800)  # Fire nose blaster

  # Phase 2: 8.0s..16.5s — Aiming & Corridor Alignment
  wait_until(8.2)
  swipe(595, 2420, 297, 2420, 200)  # Slide to C2
  wait_until(11.0)
  swipe(297, 2420, 1043, 2420, 220)  # Slide to C7
  wait_until(13.5)
  swipe(1043, 2420, 297, 2420, 220)  # Slide back to C2

  # Phase 3: 16.5s..26.0s — 16-Bay Capacitor Ring & Sowing Cascades
  wait_until(18.0)
  tap(265, 2800)  # SOW ›
  wait_until(21.5)
  tap(265, 2800)  # SOW › (Totem #3 charged to 4+ seeds = MEGA GUN 16x!)
  wait_until(23.5)
  swipe(297, 2420, 446, 2420, 180)  # Align on C3 (Totem #3)

  # Phase 4: 26.0s..36.0s — Axial Particle Lance Discharge
  wait_until(26.0)
  tap(672, 2800)  # Fire 16x Quadratic Super Beam on C3!
  wait_until(30.5)
  swipe(446, 2420, 1192, 2420, 220)  # Align on C8 (Totem #8)
  wait_until(32.0)
  tap(672, 2800)  # Fire Quadratic Super Beam on C8!

  # Phase 5: 36.0s..43.5s — Harmonic Shield Deflection & Counter-Strike
  wait_until(37.0)
  swipe(1192, 2420, 595, 2420, 200)  # Align C4
  wait_until(38.5)
  tap(265, 2800)  # Sow right
  wait_until(41.0)
  tap(1180, 2800)  # Counter-strike lance / blaster

  # Phase 6: 43.5s..60.0s — AI Tactical Advisor & Campaign Command
  wait_until(43.5)
  tap(1250, 224)  # Open Tactical Pause
  wait_until(44.3)
  tap(1050, 2200)  # Toggle AI Solver ON
  wait_until(45.0)
  tap(671, 1500)  # Resume Combat with AI AUTO active!
  wait_until(47.5)
  tap(1180, 2800)
  wait_until(50.0)
  tap(672, 2800)
  wait_until(53.0)
  tap(343, 224)  # Show Campaign Star Map
  wait_until(56.0)
  tap(560, 2815)  # Show 3D Orbital Fleet Hangar

  rec_proc.wait()
  print("[Record 60s] Screen recording completed successfully!")


if __name__ == "__main__":
  record_60s_tutorial()
