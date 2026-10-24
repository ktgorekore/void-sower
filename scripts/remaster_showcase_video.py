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

"""Remasters the official 30s Void Sower YouTube & Play Store showcase video.

Captures authentic live gameplay from the Android emulator showcasing:
  1. 3D Tactical Combat & Quadratic M^2 Mega Gun (16x) Super Beam discharge.
  2. Bao la Kiswahili plasma sowing & 3-Beam Golden Morabaraba Fence Blast.
  3. Native C++ MCTS AI AUTO Tactical Solver executing Grandmaster cascades.
  4. Campaign Star Map, Special Operations, 3D Fleet Hangar & Pilot PRO Dossier.

Composites an atmospheric C-minor sci-fi ambient synth background track with
synchronized in-game sound effects (particle lances, sowing steps, overload
chimes, shield deflections, flak explosions, and victory fanfare).
"""

import os
import shutil
import subprocess
import sys
import threading
import time
import wave
import numpy as np

DEVICE = "emulator-5554"
SCRATCH_DIR = "/tmp/void_sower_remaster"
AUDIO_DIR = "/home/kelvingorekore/projects/void-sower/assets/audio"

DOCS_SHOWCASE_MP4 = (
    "/home/kelvingorekore/projects/void-sower/docs/media/"
    "void_sower_gameplay_showcase.mp4"
)
DOCS_SOLVER_MP4 = (
    "/home/kelvingorekore/projects/void-sower/docs/media/"
    "void_sower_solver_showcase_30s.mp4"
)
STORE_PROMO_MP4 = (
    "/home/kelvingorekore/projects/void-sower/store_listing/assets/"
    "promo_gameplay.mp4"
)

DOCS_SHOWCASE_GIF = (
    "/home/kelvingorekore/projects/void-sower/docs/media/"
    "void_sower_solver_showcase.gif"
)
STORE_PROMO_GIF = (
    "/home/kelvingorekore/projects/void-sower/store_listing/assets/"
    "promo_gameplay.gif"
)


def adb_cmd(args):
  """Executes an adb command targeting the default emulator."""
  cmd = ["adb", "-s", DEVICE] + args
  return subprocess.run(cmd, capture_output=True, text=True, check=False)


def tap(x, y):
  """Taps the specified physical display coordinates."""
  adb_cmd(["shell", "input", "tap", str(x), str(y)])


def swipe(x1, y1, x2, y2, duration_ms=220):
  """Executes a swipe gesture between two points."""
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
  """Sends an Android keyevent code."""
  adb_cmd(["shell", "input", "keyevent", str(code)])


def seed_gameplay_state():
  """Seeds user preferences for high-tier 3D & Afrofuturist gameplay demo."""
  print(
      "[State] Seeding Pro pilot profile and Sector 9 campaign progression..."
  )
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
      ' value="true" />\n'
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
  xml_path = "/tmp/prefs_remaster.xml"
  with open(xml_path, "w", encoding="utf-8") as f:
    f.write(pref_xml)

  subprocess.run(
      [
          "adb",
          "-s",
          DEVICE,
          "push",
          xml_path,
          "/data/local/tmp/prefs_remaster.xml",
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
      "/data/local/tmp/prefs_remaster.xml",
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


def generate_synth_music(output_path: str, duration_sec: float = 31.0):
  """Generates an atmospheric sci-fi ambient synth background track in C minor."""
  sample_rate = 44100
  total_samples = int(sample_rate * duration_sec)
  t = np.linspace(0, duration_sec, total_samples, endpoint=False)

  chord_freqs = [
      (130.81, 0.22),  # C3
      (155.56, 0.18),  # Eb3
      (196.00, 0.16),  # G3
      (233.08, 0.14),  # Bb3
      (293.66, 0.10),  # D4
  ]

  signal = np.zeros(total_samples, dtype=np.float32)
  lfo = 0.5 + 0.5 * np.sin(2 * np.pi * 0.15 * t)
  lfo2 = 0.5 + 0.5 * np.sin(2 * np.pi * 0.3 * t + 0.5)

  for freq, amp in chord_freqs:
    osc1 = np.sin(2 * np.pi * freq * t)
    osc2 = np.sin(2 * np.pi * (freq * 1.003) * t)
    signal += amp * (0.6 * osc1 + 0.4 * osc2) * (0.8 + 0.2 * lfo)

  sub_bass = np.sin(2 * np.pi * 65.41 * t) + 0.3 * np.sin(2 * np.pi * 32.70 * t)
  signal += 0.35 * sub_bass * (0.85 + 0.15 * lfo2)

  shimmer = np.sin(2 * np.pi * 523.25 * t) + np.sin(2 * np.pi * 783.99 * t)
  signal += 0.04 * shimmer * lfo

  attack_samples = int(sample_rate * 1.2)
  release_samples = int(sample_rate * 1.8)
  signal[:attack_samples] *= np.linspace(0.0, 1.0, attack_samples)
  signal[-release_samples:] *= np.linspace(1.0, 0.0, release_samples)

  max_val = np.max(np.abs(signal))
  if max_val > 0:
    signal = signal / max_val * 0.30

  pcm_data = (signal * 32767).astype(np.int16)
  stereo_data = np.empty((total_samples * 2,), dtype=np.int16)
  stereo_data[0::2] = pcm_data
  stereo_data[1::2] = pcm_data

  with wave.open(output_path, "wb") as wf:
    wf.setnchannels(2)
    wf.setsampwidth(2)
    wf.setframerate(sample_rate)
    wf.writeframes(stereo_data.tobytes())
  print(f"[Audio] Synthesized ambient synth track -> {output_path}")


def generate_sfx_track(output_path: str, duration_sec: float = 31.0):
  """Composites Void Sower in-game sound effects synchronized with 3D combat."""
  sample_rate = 44100
  total_samples = int(sample_rate * duration_sec)
  mix = np.zeros(total_samples, dtype=np.float32)

  def load_wav(name):
    path = os.path.join(AUDIO_DIR, name)
    if not os.path.exists(path):
      return np.zeros(0, dtype=np.float32)
    with wave.open(path, "rb") as wf:
      n = wf.getnframes()
      frames = wf.readframes(n)
      samples = (
          np.frombuffer(frames, dtype=np.int16).astype(np.float32) / 32768.0
      )
      if wf.getnchannels() == 2:
        samples = samples.reshape(-1, 2).mean(axis=1)
      return samples

  sow_step = load_wav("sow_step.wav")
  lance_fire = load_wav("lance_fire.wav")
  flak_burst = load_wav("flak_burst.wav")
  inject_core = load_wav("inject_core.wav")
  overload = load_wav("overload.wav")
  bullet_deflect = load_wav("bullet_deflect.wav")
  victory = load_wav("victory.wav")

  def place_sfx(sfx, start_time_sec, volume=1.0):
    if len(sfx) == 0:
      return
    start_idx = int(start_time_sec * sample_rate)
    end_idx = min(start_idx + len(sfx), total_samples)
    if start_idx < total_samples:
      chunk_len = end_idx - start_idx
      mix[start_idx:end_idx] += sfx[:chunk_len] * volume

  # Phase 1 (0.0s - 6.5s): Mega Gun Overcharge & 16x Quadratic Super Beam
  place_sfx(inject_core, 0.8, 0.85)
  place_sfx(sow_step, 1.3, 0.90)
  place_sfx(sow_step, 1.5, 0.92)
  place_sfx(sow_step, 1.9, 0.95)
  place_sfx(overload, 2.2, 1.05)
  place_sfx(lance_fire, 3.0, 1.35)
  place_sfx(flak_burst, 3.4, 1.10)
  place_sfx(lance_fire, 4.8, 1.25)
  place_sfx(flak_burst, 5.2, 1.00)

  # Phase 2 (6.5s - 14.0s): Bao Sowing & 3-Beam Golden Morabaraba Fence Blast
  for t_sow in [6.8, 7.0, 7.2, 8.2, 8.4, 8.6]:
    place_sfx(sow_step, t_sow, 0.90)
  place_sfx(overload, 9.0, 1.05)
  place_sfx(bullet_deflect, 9.8, 0.95)
  # Triple Golden Fence Blast barrage!
  place_sfx(lance_fire, 10.6, 1.40)
  place_sfx(lance_fire, 10.68, 1.25)
  place_sfx(flak_burst, 11.0, 1.15)
  place_sfx(flak_burst, 11.2, 1.05)
  place_sfx(lance_fire, 12.5, 1.25)
  place_sfx(flak_burst, 12.9, 1.00)

  # Phase 3 (14.0s - 22.0s): C++ MCTS AI Autopilot Solver Cascades
  place_sfx(inject_core, 14.2, 0.90)
  place_sfx(overload, 15.0, 1.00)
  for t_ai in [16.0, 17.4, 18.8, 20.3]:
    place_sfx(sow_step, t_ai - 0.3, 0.85)
    place_sfx(lance_fire, t_ai, 1.30)
    place_sfx(flak_burst, t_ai + 0.4, 1.05)
  place_sfx(bullet_deflect, 18.1, 0.95)

  # Phase 4 (22.0s - 30.0s): Star Map, Special Ops, 3D Hangar & Pilot PRO Dossier
  place_sfx(inject_core, 22.3, 0.85)
  place_sfx(sow_step, 24.2, 0.85)
  place_sfx(inject_core, 26.0, 0.90)
  place_sfx(overload, 27.6, 0.95)
  place_sfx(victory, 28.3, 1.25)

  peak = np.max(np.abs(mix))
  if peak > 0:
    mix = np.tanh(mix * 0.95)

  pcm_data = (mix * 32767).astype(np.int16)
  stereo_data = np.empty((total_samples * 2,), dtype=np.int16)
  stereo_data[0::2] = pcm_data
  stereo_data[1::2] = pcm_data

  with wave.open(output_path, "wb") as wf:
    wf.setnchannels(2)
    wf.setsampwidth(2)
    wf.setframerate(sample_rate)
    wf.writeframes(stereo_data.tobytes())
  print(f"[SFX] Synthesized gameplay SFX track -> {output_path}")


def write_ass_subtitles(ass_path: str):
  """Generates an ASS subtitle overlay highlighting 3D combat & UI features."""
  ass_content = """[Script Info]
ScriptType: v4.00+
PlayResX: 1080
PlayResY: 2400
WrapStyle: 0
ScaledBorderAndShadow: yes

[V4+ Styles]
Format: Name, Fontname, Fontsize, PrimaryColour, SecondaryColour, OutlineColour, BackColour, Bold, Italic, Underline, StrikeOut, ScaleX, ScaleY, Spacing, Angle, BorderStyle, Outline, Shadow, Alignment, MarginL, MarginR, MarginV, Encoding
Style: HudBanner,Sans,25,&H0066D1FF,&H00FFD54F,&H5505070B,&HDD05070B,-1,0,0,0,100,100,1.2,0,3,10,0,8,30,30,32,1

[Events]
Format: Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text
Dialogue: 0,0:00:00.20,0:00:06.40,HudBanner,,0,0,32,,3D TACTICAL COMBAT • QUADRATIC M² MEGA GUN (16x SUPER BEAM)
Dialogue: 0,0:00:06.50,0:00:13.90,HudBanner,,0,0,32,,BAO SOWING & MORABARABA • 3-BEAM GOLDEN FENCE BLAST BARRAGE
Dialogue: 0,0:00:14.00,0:00:21.90,HudBanner,,0,0,32,,NATIVE C++ MCTS AI AUTOPILOT • GRANDMASTER SOWING CASCADES
Dialogue: 0,0:00:22.00,0:00:29.90,HudBanner,,0,0,32,,CAMPAIGN COMMAND • SPECIAL OPS, 3D FLEET HANGAR & PRO DOSSIER
"""
  with open(ass_path, "w", encoding="utf-8") as f:
    f.write(ass_content)
  print(f"[Subtitles] Wrote ASS HUD callout captions -> {ass_path}")


def execute_gameplay_actions():
  """Drives real-time 3D gameplay choreography in Sector 9 for 30s recording."""
  t0 = time.time()

  def wait_until(sec):
    rem = sec - (time.time() - t0)
    if rem > 0:
      time.sleep(rem)

  print("[Choreography] Starting 30s live 3D gameplay choreography...")

  # Phase 1 (0.0s - 6.5s): Charge Mega Gun (Totem #3) & Fire 16x Super Beam
  wait_until(0.8)
  swipe(595, 2420, 297, 2420, 180)
  wait_until(1.3)
  tap(265, 2800)  # SOW ›
  wait_until(1.8)
  tap(265, 2800)  # SOW › (Totem #3 now has 4+ seeds = MEGA GUN 16x!)
  wait_until(2.3)
  swipe(297, 2420, 446, 2420, 180)  # Align on Corridor 3 (Totem #3)
  wait_until(3.0)
  tap(672, 2800)  # Unleash 16x Quadratic Super Beam!
  wait_until(4.4)
  swipe(446, 2420, 1192, 2420, 200)  # Slide to Corridor 8 (Totem #8)
  wait_until(4.8)
  tap(672, 2800)  # Unleash second Super Beam!

  # Phase 2 (6.5s - 14.0s): Build 4-Totem Morabaraba Laser Fence & Fire 3-Beam Blast
  wait_until(6.5)
  swipe(1192, 2420, 446, 2420, 180)
  wait_until(6.8)
  tap(265, 2800)  # SOW › across Totems #4-#7
  wait_until(7.8)
  swipe(446, 2420, 1192, 2420, 180)
  wait_until(8.2)
  tap(115, 2800)  # ‹ SOW across Totems #7-#4 -> Golden Laser Fence active!
  wait_until(9.2)
  # Thrust forward into Vanguard range along Corridor 5
  swipe(745, 2420, 745, 1850, 240)
  wait_until(10.6)
  tap(1180, 2800)  # Fire 3-Beam Golden Morabaraba FENCE BLAST Barrage!
  wait_until(12.5)
  tap(1180, 2800)  # Follow-up blaster strike

  # Phase 3 (14.0s - 22.0s): Engage Native C++ MCTS AI Autopilot Solver
  wait_until(14.0)
  tap(1250, 224)  # Open Tactical Pause
  wait_until(14.7)
  tap(1050, 2200)  # Toggle AI SOLVER ON
  wait_until(15.3)
  tap(671, 1500)  # Resume Combat -> AI AUTO active!
  # Trigger additional beam discharges while AI AUTO maneuvers
  wait_until(17.4)
  tap(1180, 2800)
  wait_until(20.3)
  tap(672, 2800)

  # Phase 4 (22.0s - 30.0s): Star Map -> Special Ops -> 3D Hangar -> Pilot PRO
  wait_until(22.2)
  tap(343, 224)  # Open Campaign Star Map via top-left HUD button
  wait_until(24.1)
  tap(345, 2815)  # Switch to OPS (Special Operations Command Deck)
  wait_until(25.9)
  tap(560, 2815)  # Open FLEET (3D Orbital Drydock Hangar)
  wait_until(27.6)
  keyevent(4)  # Close Hangar modal
  wait_until(28.1)
  tap(780, 2815)  # Open PILOT (Pilot Flight Dossier with PRO badge)

  print("[Choreography] Completed 30s live 3D gameplay choreography.")


def build_final_videos(
    raw_video: str, synth_audio: str, sfx_audio: str, ass_path: str
):
  """Composites mastered video with ASS captions, ambient synth, and SFX."""
  os.makedirs(os.path.dirname(DOCS_SHOWCASE_MP4), exist_ok=True)
  os.makedirs(os.path.dirname(STORE_PROMO_MP4), exist_ok=True)

  mastered_temp = os.path.join(SCRATCH_DIR, "mastered_showcase.mp4")

  cmd = [
      "ffmpeg",
      "-y",
      "-i",
      raw_video,
      "-i",
      synth_audio,
      "-i",
      sfx_audio,
      "-filter_complex",
      (
          f"[0:v]trim=0:30,setpts=PTS-STARTPTS,ass={ass_path}[v];"
          "[1:a]volume=0.42[a_bg];"
          "[2:a]volume=1.15[a_sfx];"
          "[a_bg][a_sfx]amix=inputs=2:duration=first:dropout_transition=2[a]"
      ),
      "-map",
      "[v]",
      "-map",
      "[a]",
      "-c:v",
      "libx264",
      "-preset",
      "slow",
      "-crf",
      "18",
      "-pix_fmt",
      "yuv420p",
      "-c:a",
      "aac",
      "-b:a",
      "192k",
      "-t",
      "30.0",
      "-movflags",
      "+faststart",
      mastered_temp,
  ]

  print("[FFmpeg] Executing 30s showcase mastering pass...")
  res = subprocess.run(cmd, capture_output=True, text=True, check=False)
  if res.returncode != 0:
    print(f"[FFmpeg Error] {res.stderr}")
    sys.exit(1)

  for dest in [DOCS_SHOWCASE_MP4, DOCS_SOLVER_MP4, STORE_PROMO_MP4]:
    shutil.copyfile(mastered_temp, dest)
    print(f"[Deploy MP4] -> {dest} ({os.path.getsize(dest)} bytes)")

  print("[FFmpeg] Generating preview animated GIF...")
  gif_temp = os.path.join(SCRATCH_DIR, "preview.gif")
  gif_cmd = [
      "ffmpeg",
      "-y",
      "-ss",
      "2.0",
      "-t",
      "14.0",
      "-i",
      mastered_temp,
      "-filter_complex",
      (
          "[0:v]fps=15,scale=360:800:flags=lanczos,split[s0][s1];"
          "[s0]palettegen=max_colors=128[p];"
          "[s1][p]paletteuse=dither=bayer:bayer_scale=3"
      ),
      gif_temp,
  ]
  res_gif = subprocess.run(gif_cmd, capture_output=True, text=True, check=False)
  if res_gif.returncode != 0:
    print(f"[FFmpeg GIF Error] {res_gif.stderr}")
  else:
    for gif_dest in [DOCS_SHOWCASE_GIF, STORE_PROMO_GIF]:
      shutil.copyfile(gif_temp, gif_dest)
      print(f"[Deploy GIF] -> {gif_dest} ({os.path.getsize(gif_dest)} bytes)")


def main():
  os.makedirs(SCRATCH_DIR, exist_ok=True)

  print("[Display] Verifying display size is device native...")
  adb_cmd(["shell", "wm", "size", "reset"])
  adb_cmd(["shell", "wm", "density", "reset"])
  time.sleep(1.0)

  synth_wav = os.path.join(SCRATCH_DIR, "ambient_synth_30s.wav")
  sfx_wav = os.path.join(SCRATCH_DIR, "gameplay_sfx_30s.wav")
  ass_path = os.path.join(SCRATCH_DIR, "showcase_captions.ass")
  generate_synth_music(synth_wav, duration_sec=31.0)
  generate_sfx_track(sfx_wav, duration_sec=31.0)
  write_ass_subtitles(ass_path)

  seed_gameplay_state()
  print(
      "[App] Launching com.voidsower.app & staging Sector 9 (Great Siphon)..."
  )
  adb_cmd(["shell", "am", "start", "-n", "com.voidsower.app/.MainActivity"])
  time.sleep(2.4)
  tap(343, 224)  # Open Star Map
  time.sleep(1.4)
  tap(1100, 2235)  # Engage Sector 9
  time.sleep(1.2)

  remote_raw_mp4 = "/sdcard/showcase_raw.mp4"
  local_raw_mp4 = os.path.join(SCRATCH_DIR, "raw_recording_30s.mp4")
  adb_cmd(["shell", "rm", "-f", remote_raw_mp4])

  rec_cmd = [
      "adb",
      "-s",
      DEVICE,
      "shell",
      "screenrecord",
      "--size",
      "1080x2400",
      "--bit-rate",
      "12000000",
      "--time-limit",
      "30",
      remote_raw_mp4,
  ]
  print(f"[Record] Launching 30s screenrecord ({rec_cmd})...")
  rec_proc = subprocess.Popen(rec_cmd)

  choreo_thread = threading.Thread(target=execute_gameplay_actions)
  choreo_thread.start()

  rec_proc.wait()
  choreo_thread.join()
  time.sleep(1.0)

  print("[Pull] Pulling raw recording from device...")
  pull_res = subprocess.run(
      ["adb", "-s", DEVICE, "pull", remote_raw_mp4, local_raw_mp4],
      capture_output=True,
      text=True,
      check=False,
  )
  if pull_res.returncode != 0 or not os.path.exists(local_raw_mp4):
    raise RuntimeError(f"Failed to pull screenrecord: {pull_res.stderr}")

  print(f"[Pulled] {local_raw_mp4} ({os.path.getsize(local_raw_mp4)} bytes)")

  build_final_videos(local_raw_mp4, synth_wav, sfx_wav, ass_path)

  print(
      "\n[SUCCESS] Void Sower gameplay showcase and promo video successfully"
      " remastered with BGM and combat audio effects!"
  )


if __name__ == "__main__":
  main()
