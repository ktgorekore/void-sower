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

"""Remasters the official 30s Void Sower gameplay showcase and promo video.

Captures authentic live gameplay from the Android emulator showcasing:
  1. The UX 3.0 Slimline HUD header and Mancala Battery Dock.
  2. 3D spatial depth maneuvers (Forward Engage +10km, Mid-Combat +20km, Apogee +40km).
  3. Plasma core sowing cascades across orbital conduits.
  4. Axial Particle Lance discharges with critical strikes and invader flak bursts.
  5. Tactical Pause inspection and seamless Multi-Theater Campaign Star Map navigation.

Composites an atmospheric C-minor sci-fi ambient synth background track with
synchronized in-game sound effects (particle lances, sowing steps, flak explosions, victory fanfare).
"""

import math
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

DOCS_SHOWCASE_MP4 = "/home/kelvingorekore/projects/void-sower/docs/media/void_sower_gameplay_showcase.mp4"
DOCS_SOLVER_MP4 = "/home/kelvingorekore/projects/void-sower/docs/media/void_sower_solver_showcase_30s.mp4"
STORE_PROMO_MP4 = "/home/kelvingorekore/projects/void-sower/store_listing/assets/promo_gameplay.mp4"

DOCS_SHOWCASE_GIF = "/home/kelvingorekore/projects/void-sower/docs/media/void_sower_solver_showcase.gif"
STORE_PROMO_GIF = "/home/kelvingorekore/projects/void-sower/store_listing/assets/promo_gameplay.gif"


def adb_cmd(args):
  """Executes an adb command targeting the default emulator."""
  cmd = ["adb", "-s", DEVICE] + args
  return subprocess.run(cmd, capture_output=True, text=True)


def tap(x, y):
  """Taps the specified physical display coordinates."""
  adb_cmd(["shell", "input", "tap", str(x), str(y)])


def swipe(x1, y1, x2, y2, duration_ms=250):
  """Executes a swipe gesture between two points."""
  adb_cmd(["shell", "input", "swipe", str(x1), str(y1), str(x2), str(y2), str(duration_ms)])


def seed_gameplay_state():
  """Seeds pristine user preferences for high-tier gameplay demonstration."""
  print("[State] Seeding Pro pilot profile and campaign progression...")
  adb_cmd(["shell", "settings", "put", "secure", "immersive_mode_confirmations", "confirmed"])
  adb_cmd(["shell", "am", "force-stop", "com.voidsower.app"])
  time.sleep(0.5)
  adb_cmd(["shell", "pm", "clear", "com.voidsower.app"])
  time.sleep(0.8)

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
      '    <boolean name="flutter.void_sower_pro_unlocked" value="true" />\n'
      '    <boolean name="flutter.void_sower_ads_disabled" value="true" />\n'
      '    <boolean name="flutter.void_sower_completed_tutorial" value="true" />\n'
      '    <int name="flutter.void_sower_high_score" value="34820" />\n'
      '    <int name="flutter.void_sower_liberated_sectors" value="6" />\n'
      '    <int name="flutter.void_sower_sector_stars_1" value="3" />\n'
      '    <int name="flutter.void_sower_sector_stars_2" value="3" />\n'
      '    <int name="flutter.void_sower_sector_stars_3" value="3" />\n'
      '    <int name="flutter.void_sower_sector_stars_4" value="2" />\n'
      '    <int name="flutter.void_sower_sector_stars_5" value="2" />\n'
      f'    <string name="flutter.void_sower_user_profile">{escaped_profile}</string>\n'
      '    <string name="flutter.void_sower_active_profile_id">pilot_default</string>\n'
      '</map>\n'
  )
  xml_path = "/tmp/prefs_remaster.xml"
  with open(xml_path, "w") as f:
    f.write(pref_xml)

  subprocess.run(["adb", "-s", DEVICE, "push", xml_path, "/data/local/tmp/prefs_remaster.xml"], check=True)
  adb_cmd(["shell", "run-as", "com.voidsower.app", "mkdir", "-p", "shared_prefs"])
  adb_cmd(["shell", "run-as", "com.voidsower.app", "cp", "/data/local/tmp/prefs_remaster.xml", "shared_prefs/FlutterSharedPreferences.xml"])
  adb_cmd(["shell", "run-as", "com.voidsower.app", "chmod", "660", "shared_prefs/FlutterSharedPreferences.xml"])
  time.sleep(0.5)


def generate_synth_music(output_path: str, duration_sec: float = 30.5):
  """Generates an atmospheric sci-fi ambient synth background track in C minor."""
  sample_rate = 44100
  total_samples = int(sample_rate * duration_sec)
  t = np.linspace(0, duration_sec, total_samples, endpoint=False)

  # Atmospheric chord progressions in C Minor (C, Eb, G, Bb, D)
  chord_freqs = [
      (130.81, 0.22),  # C3
      (155.56, 0.18),  # Eb3
      (196.00, 0.16),  # G3
      (233.08, 0.14),  # Bb3
      (293.66, 0.10),  # D4
  ]

  signal = np.zeros(total_samples, dtype=np.float32)

  # Add warm drone pads with slow LFO pulse
  lfo = 0.5 + 0.5 * np.sin(2 * np.pi * 0.15 * t)
  lfo2 = 0.5 + 0.5 * np.sin(2 * np.pi * 0.3 * t + 0.5)

  for freq, amp in chord_freqs:
    # Rich dual-oscillator detuning
    osc1 = np.sin(2 * np.pi * freq * t)
    osc2 = np.sin(2 * np.pi * (freq * 1.003) * t)
    signal += amp * (0.6 * osc1 + 0.4 * osc2) * (0.8 + 0.2 * lfo)

  # Sub-bass fundamental (65.4 Hz - C2)
  sub_bass = np.sin(2 * np.pi * 65.41 * t)
  sub_bass += 0.3 * np.sin(2 * np.pi * 32.70 * t)  # Sub-octave C1
  signal += 0.35 * sub_bass * (0.85 + 0.15 * lfo2)

  # Space shimmer texture (high harmonics filtered)
  shimmer = np.sin(2 * np.pi * 523.25 * t) + np.sin(2 * np.pi * 783.99 * t)
  signal += 0.04 * shimmer * lfo

  # Apply gentle attack (1.5s) and release (2.0s) envelope
  attack_samples = int(sample_rate * 1.5)
  release_samples = int(sample_rate * 2.0)
  fade_in = np.linspace(0.0, 1.0, attack_samples)
  fade_out = np.linspace(1.0, 0.0, release_samples)

  signal[:attack_samples] *= fade_in
  signal[-release_samples:] *= fade_out

  # Normalize
  max_val = np.max(np.abs(signal))
  if max_val > 0:
    signal = signal / max_val * 0.28

  # Convert to 16-bit PCM WAV (stereo)
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


def generate_sfx_track(output_path: str, duration_sec: float = 30.5):
  """Composites authentic Void Sower in-game sound effects synchronized with combat actions."""
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
      samples = np.frombuffer(frames, dtype=np.int16).astype(np.float32) / 32768.0
      if wf.getnchannels() == 2:
        samples = samples.reshape(-1, 2).mean(axis=1)
      return samples

  sow_step = load_wav("sow_step.wav")
  lance_fire = load_wav("lance_fire.wav")
  flak_burst = load_wav("flak_burst.wav")
  inject_core = load_wav("inject_core.wav")
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

  # Synchronized audio cues:
  # 1. Opening inspection & sowing
  place_sfx(inject_core, 0.8, 0.7)
  place_sfx(sow_step, 2.3, 0.8)
  place_sfx(sow_step, 2.55, 0.85)
  place_sfx(sow_step, 2.8, 0.9)
  place_sfx(inject_core, 4.2, 0.75)

  # 2. 3D Depth Maneuver forward
  place_sfx(inject_core, 5.8, 0.85)
  place_sfx(bullet_deflect, 7.5, 0.8)

  # 3. Particle Lance discharge barrage on C4
  place_sfx(lance_fire, 9.2, 1.25)
  place_sfx(flak_burst, 9.7, 0.9)
  place_sfx(lance_fire, 10.3, 1.25)
  place_sfx(flak_burst, 10.8, 0.95)
  place_sfx(lance_fire, 11.5, 1.3)
  place_sfx(flak_burst, 12.0, 1.0)
  place_sfx(bullet_deflect, 13.0, 0.85)

  # 4. Lateral shift to C2 and sowing cascade
  place_sfx(sow_step, 14.8, 0.8)
  place_sfx(sow_step, 15.05, 0.85)
  place_sfx(sow_step, 15.3, 0.9)
  place_sfx(lance_fire, 17.0, 1.25)
  place_sfx(flak_burst, 17.6, 0.9)
  place_sfx(lance_fire, 18.5, 1.2)
  place_sfx(flak_burst, 19.1, 0.9)

  # 5. Pull back to baseline
  place_sfx(inject_core, 21.2, 0.8)

  # 6. Tactical Pause & Campaign Map
  place_sfx(inject_core, 23.2, 0.8)
  place_sfx(inject_core, 25.6, 0.85)
  place_sfx(victory, 28.0, 1.2)

  # Soft limiter / compression
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


def execute_gameplay_actions():
  """Drives real-time gameplay choreography on the emulator during recording."""
  print("[Choreography] Starting automated live gameplay choreography...")

  # T = 0.0s..2.0s: Initial inspection at baseline Z: 0km
  time.sleep(2.0)

  # T = 2.0s..5.0s: Sowing cascade across front conduits
  print("[Action] Sowing cores clockwise across conduits C4 -> C6...")
  swipe(595, 2640, 915, 2640, 220)
  time.sleep(1.8)
  print("[Action] Injecting core via Nyumba vault...")
  tap(672, 2770)
  time.sleep(1.5)

  # T = 5.5s..8.5s: 3D Depth Maneuver forward
  print("[Action] Advancing Defender into 3D Deep Space (Z: +10km)...")
  swipe(672, 2300, 672, 1750, 250)
  time.sleep(1.5)
  print("[Action] Advancing Defender to Mid-Combat Horizon (Z: +20km)...")
  swipe(672, 1750, 672, 1250, 250)
  time.sleep(1.2)

  # T = 9.0s..14.0s: Discharging Axial Particle Lance on C4
  print("[Action] Discharging Axial Particle Lance barrage on C4...")
  for _ in range(8):
    tap(600, 2640)
    time.sleep(0.12)
  time.sleep(1.5)

  # T = 14.5s..18.0s: Lateral maneuver to corridor C2
  print("[Action] Lateral alignment to C2 and sowing cascade...")
  tap(275, 2640)
  time.sleep(0.5)
  swipe(275, 2640, 595, 2640, 200)
  time.sleep(1.5)

  # T = 17.5s..21.0s: Particle Lance barrage on C2
  print("[Action] Firing high-power lance on C2...")
  for _ in range(6):
    tap(275, 2640)
    time.sleep(0.12)
  time.sleep(1.2)

  # T = 21.0s..23.0s: Pull back to baseline Z: 0km
  print("[Action] Returning to baseline defense Z: 0km...")
  swipe(672, 1250, 672, 2300, 300)
  time.sleep(1.5)

  # T = 23.0s..25.5s: Open Slimline Tactical Pause
  print("[Action] Tapping Tactical Pause capsule...")
  tap(1175, 224)
  time.sleep(2.0)

  # T = 25.5s..28.5s: Transition to Campaign Star Map
  print("[Action] Tapping Star Map button in pause menu...")
  tap(460, 1735)
  time.sleep(2.5)

  # T = 28.5s..30.0s: Tap Pilot Telemetry Dossier tab
  print("[Action] Tapping Pilot Dossier tab in campaign bottom nav...")
  tap(672, 2815)
  time.sleep(1.5)

  print("[Choreography] Completed 30s live gameplay choreography.")


def build_final_videos(raw_video: str, synth_audio: str, sfx_audio: str):
  """Composites mastered video with ambient synth music and sound effects."""
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
          "[0:v]trim=0:30,setpts=PTS-STARTPTS[v];"
          "[1:a]volume=0.38[a_bg];"
          "[2:a]volume=1.05[a_sfx];"
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

  print(f"[FFmpeg] Executing 30s showcase mastering pass...")
  res = subprocess.run(cmd, capture_output=True, text=True)
  if res.returncode != 0:
    print(f"[FFmpeg Error] {res.stderr}")
    sys.exit(1)

  # Deploy to docs and store assets
  for dest in [DOCS_SHOWCASE_MP4, DOCS_SOLVER_MP4, STORE_PROMO_MP4]:
    shutil.copyfile(mastered_temp, dest)
    print(f"[Deploy MP4] -> {dest} ({os.path.getsize(dest)} bytes)")

  # Generate preview GIF (10-second highlight loop: 8.0s to 18.0s combat lance firing)
  print(f"[FFmpeg] Generating preview animated GIF...")
  gif_temp = os.path.join(SCRATCH_DIR, "preview.gif")
  gif_cmd = [
      "ffmpeg",
      "-y",
      "-ss",
      "8.0",
      "-t",
      "10.0",
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
  res_gif = subprocess.run(gif_cmd, capture_output=True, text=True)
  if res_gif.returncode != 0:
    print(f"[FFmpeg GIF Error] {res_gif.stderr}")
  else:
    for gif_dest in [DOCS_SHOWCASE_GIF, STORE_PROMO_GIF]:
      shutil.copyfile(gif_temp, gif_dest)
      print(f"[Deploy GIF] -> {gif_dest} ({os.path.getsize(gif_dest)} bytes)")


def main():
  os.makedirs(SCRATCH_DIR, exist_ok=True)

  # 1. Reset display resolution to native phone (1344x2992 @ 480dpi)
  print("[Display] Verifying display size is device native...")
  adb_cmd(["shell", "wm", "size", "reset"])
  adb_cmd(["shell", "wm", "density", "reset"])
  time.sleep(1.0)

  # 2. Seed state and start app
  seed_gameplay_state()
  print("[App] Launching com.voidsower.app...")
  adb_cmd(["shell", "am", "start", "-n", "com.voidsower.app/.MainActivity"])
  time.sleep(2.5)

  # 3. Prepare audio tracks
  synth_wav = os.path.join(SCRATCH_DIR, "ambient_synth_30s.wav")
  sfx_wav = os.path.join(SCRATCH_DIR, "gameplay_sfx_30s.wav")
  generate_synth_music(synth_wav, duration_sec=31.0)
  generate_sfx_track(sfx_wav, duration_sec=31.0)

  # 4. Start screen recording and run choreography thread
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

  # Run choreography concurrently
  choreo_thread = threading.Thread(target=execute_gameplay_actions)
  choreo_thread.start()

  # Wait for recording and choreography
  rec_proc.wait()
  choreo_thread.join()
  time.sleep(1.0)

  # Pull recording
  print("[Pull] Pulling raw recording from device...")
  pull_res = subprocess.run(
      ["adb", "-s", DEVICE, "pull", remote_raw_mp4, local_raw_mp4],
      capture_output=True,
      text=True,
  )
  if pull_res.returncode != 0 or not os.path.exists(local_raw_mp4):
    raise RuntimeError(f"Failed to pull screenrecord: {pull_res.stderr}")

  print(f"[Pulled] {local_raw_mp4} ({os.path.getsize(local_raw_mp4)} bytes)")

  # 5. Master video with audio
  build_final_videos(local_raw_mp4, synth_wav, sfx_wav)

  print("\n[SUCCESS] Void Sower gameplay showcase and promo video successfully remastered!")


if __name__ == "__main__":
  main()
