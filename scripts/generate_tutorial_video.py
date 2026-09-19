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

"""Generates official 60s narrated tutorial, 30s showcase videos, and preview GIFs."""

import math
import os
import shutil
import struct
import subprocess
import sys
import wave
import edge_tts
import numpy as np

NARRATION_TEXT = (
    "Welcome Commander to Void Sower, where ancient African Bao Mancala meets intense orbital arcade defense. "
    "Alien assault wings advance down eight corridors toward your planetary shield. "
    "Slide laterally to evade incoming plasma bombs and align your prow. "
    "Discharge devastating axial particle lances or sow plasma cores across the sixteen-bay capacitor ring to trigger explosive quadratic cascades! "
    "Conquer three distinct orbital campaigns: defend Kilwa Basin, intercept evasive craft with lateral thrusters in Phantom Drift, and survive relentless respawning hordes in the Void Swarm! "
    "Upgrade to Pro Commander for just one dollar and twenty-nine cents lifetime: unlock all twenty-seven sectors instantly, command four capital dreadnoughts, deploy our native C++ MCTS AI solver, and play completely ad-free. "
    "Master ancient mathematics and liberate the cosmos!"
)

VOICE = "en-US-ChristopherNeural"
RATE = "+6%"

SCRATCH_DIR = "/tmp/void_sower_tutorial"


def generate_synth_music(output_path: str, duration_sec: float = 60.0):
  """Generates an atmospheric sci-fi ambient synth background track."""
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
  lfo = 0.5 + 0.5 * np.sin(2 * np.pi * 0.12 * t)
  lfo2 = 0.5 + 0.5 * np.sin(2 * np.pi * 0.25 * t + 0.5)

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

  # Apply gentle attack (2s) and release (2.5s) envelope
  attack_samples = int(sample_rate * 2.0)
  release_samples = int(sample_rate * 2.5)
  fade_in = np.linspace(0.0, 1.0, attack_samples)
  fade_out = np.linspace(1.0, 0.0, release_samples)

  signal[:attack_samples] *= fade_in
  signal[-release_samples:] *= fade_out

  # Normalize to -16 dB peak
  max_val = np.max(np.abs(signal))
  if max_val > 0:
    signal = signal / max_val * 0.22

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
  print(f"[Audio] Synthesized background music -> {output_path}")


def synthesize_narration(audio_out: str, vtt_out: str):
  """Generates narration audio and subtitles using edge_tts CLI."""
  cmd = [
      "python3",
      "-m",
      "edge_tts",
      "--voice",
      VOICE,
      "--rate",
      RATE,
      "--text",
      NARRATION_TEXT,
      "--write-media",
      audio_out,
      "--write-subtitles",
      vtt_out,
  ]
  res = subprocess.run(cmd, capture_output=True, text=True)
  if res.returncode != 0:
    raise RuntimeError(f"edge_tts failed: {res.stderr}")
  print(f"[TTS] Synthesized narration audio -> {audio_out}")
  print(f"[TTS] Synthesized subtitles -> {vtt_out}")


def format_time_ass(ts_str: str) -> str:
  """Converts SRT/VTT timestamp to ASS H:MM:SS.cs timestamp."""
  ts_str = ts_str.replace(",", ".")
  parts = ts_str.split(":")
  h = int(parts[0])
  m = int(parts[1])
  s = float(parts[2])
  cs = int(round((s - int(s)) * 100))
  sec = int(s)
  if cs >= 100:
    cs -= 100
    sec += 1
  return f"{h}:{m:02d}:{sec:02d}.{cs:02d}"


def vtt_to_ass(vtt_file: str, ass_file: str):
  """Converts VTT format to styled ASS subtitles for high-res rendering."""
  with open(vtt_file, "r", encoding="utf-8") as f:
    lines = f.readlines()

  # Header with Afrofuturist sci-fi styling
  ass_content = [
      "[Script Info]",
      "Title: Void Sower Tutorial",
      "ScriptType: v4.00+",
      "WrapStyle: 0",
      "ScaledBorderAndShadow: yes",
      "YCbCr Matrix: None",
      "PlayResX: 1080",
      "PlayResY: 2400",
      "",
      "[V4+ Styles]",
      (
          "Format: Name, Fontname, Fontsize, PrimaryColour, SecondaryColour,"
          " OutlineColour, BackColour, Bold, Italic, Underline, StrikeOut,"
          " ScaleX, ScaleY, Spacing, Angle, BorderStyle, Outline, Shadow,"
          " Alignment, MarginL, MarginR, MarginV, Encoding"
      ),
      (
          "Style: Default,DejaVu Sans,44,&H00FFFFFF,&H0000FFFF,&H0008080A,"
          "&H90000000,-1,0,0,0,100,100,1.2,0,1,3.5,2.0,2,60,60,1250,1"
      ),
      "",
      "[Events]",
      "Format: Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text",
  ]

  i = 0
  while i < len(lines):
    line = lines[i].strip()
    if "-->" in line:
      parts = line.split("-->")
      start_ass = format_time_ass(parts[0].strip())
      end_ass = format_time_ass(parts[1].strip())

      text_lines = []
      i += 1
      while i < len(lines) and lines[i].strip():
        text_lines.append(lines[i].strip())
        i += 1
      caption = r"\N".join(text_lines)
      ass_content.append(
          f"Dialogue: 0,{start_ass},{end_ass},Default,,0,0,0,,{caption}"
      )
    i += 1

  with open(ass_file, "w", encoding="utf-8") as f:
    f.write("\n".join(ass_content) + "\n")
  print(f"[Subtitles] Formatted ASS subtitle track ({len(ass_content) - 13} cues) -> {ass_file}")


def generate_sfx_mix(output_path: str, duration_sec: float = 60.0):
  """Composites authentic Void Sower in-game sound effects synchronized with combat actions."""
  sample_rate = 44100
  total_samples = int(sample_rate * duration_sec)
  mix = np.zeros(total_samples, dtype=np.float32)

  audio_dir = "/home/kelvingorekore/projects/void-sower/assets/audio"

  def load_wav(name):
    path = os.path.join(audio_dir, name)
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
  shield_hit = load_wav("shield_hit.wav")
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

  # 1. Opening sequence (Command deck, hangar, dossier inspection)
  place_sfx(inject_core, 0.8, 0.8)
  place_sfx(inject_core, 2.0, 0.8)
  place_sfx(inject_core, 5.8, 0.8)
  place_sfx(inject_core, 9.5, 0.8)
  place_sfx(inject_core, 13.2, 0.8)

  # 2. Briefing progression & combat launch
  place_sfx(sow_step, 15.5, 0.8)
  place_sfx(inject_core, 18.0, 0.9)

  # 3. Double-tap axial prow fire & axial discharge
  place_sfx(lance_fire, 22.5, 1.25)
  place_sfx(flak_burst, 23.0, 0.9)
  place_sfx(lance_fire, 25.0, 1.2)
  place_sfx(bullet_deflect, 25.8, 0.8)

  # 4. First kinetic Mancala sow cadence
  for i, t_offset in enumerate([27.5, 27.75, 28.0]):
    place_sfx(sow_step, t_offset, 0.75 + i * 0.08)
  place_sfx(lance_fire, 28.5, 1.2)
  place_sfx(flak_burst, 29.1, 0.85)

  # 5. Continuous active AI combat loops throughout 30s-56s
  combat_events = [
      (31.0, "inject"), (32.0, "sow"), (32.2, "sow"), (32.4, "lance"), (33.0, "flak"),
      (35.0, "inject"), (36.0, "sow"), (36.2, "sow"), (36.5, "lance"), (37.2, "deflect"),
      (39.0, "sow"), (39.2, "sow"), (39.5, "lance"), (40.2, "flak"), (41.0, "shield"),
      (43.5, "inject"), (44.2, "sow"), (44.4, "sow"), (44.7, "lance"), (45.3, "flak"),
      (47.5, "sow"), (47.7, "sow"), (48.0, "lance"), (48.7, "deflect"), (49.5, "deflect"),
      (52.0, "sow"), (52.2, "sow"), (52.4, "sow"), (52.7, "lance"), (53.5, "flak"),
  ]
  for t_sec, ev in combat_events:
    if ev == "sow":
      place_sfx(sow_step, t_sec, 0.7)
    elif ev == "lance":
      place_sfx(lance_fire, t_sec, 1.15)
    elif ev == "flak":
      place_sfx(flak_burst, t_sec, 0.85)
    elif ev == "inject":
      place_sfx(inject_core, t_sec, 0.8)
    elif ev == "deflect":
      place_sfx(bullet_deflect, t_sec, 0.75)
    elif ev == "shield":
      place_sfx(shield_hit, t_sec, 0.8)

  # 6. Grand victory fanfare finale
  place_sfx(victory, 56.5, 1.2)

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
  print(f"[SFX] Synthesized full gameplay sound effects track -> {output_path}")


def generate_showcase_sfx_mix(output_path: str, duration_sec: float = 30.0):
  """Generates synchronized SFX for 30s tactical solver showcase."""
  sample_rate = 44100
  total_samples = int(sample_rate * duration_sec)
  mix = np.zeros(total_samples, dtype=np.float32)

  audio_dir = "/home/kelvingorekore/projects/void-sower/assets/audio"

  def load_wav(name):
    path = os.path.join(audio_dir, name)
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

  events = [
      (0.5, "inject"), (1.2, "sow"), (1.4, "sow"), (1.7, "lance"), (2.3, "flak"),
      (3.5, "deflect"), (4.2, "sow"), (4.4, "sow"), (4.7, "lance"), (5.3, "flak"),
      (7.0, "inject"), (8.0, "sow"), (8.2, "sow"), (8.5, "lance"), (9.2, "flak"),
      (11.0, "sow"), (11.2, "sow"), (11.4, "lance"), (12.1, "deflect"),
      (14.0, "inject"), (15.0, "sow"), (15.2, "sow"), (15.5, "lance"), (16.2, "flak"),
      (18.5, "sow"), (18.7, "sow"), (19.0, "lance"), (19.8, "flak"),
      (22.0, "inject"), (23.0, "sow"), (23.2, "sow"), (23.5, "lance"), (24.2, "flak"),
  ]
  for t_sec, ev in events:
    if ev == "sow":
      place_sfx(sow_step, t_sec, 0.75)
    elif ev == "lance":
      place_sfx(lance_fire, t_sec, 1.2)
    elif ev == "flak":
      place_sfx(flak_burst, t_sec, 0.9)
    elif ev == "inject":
      place_sfx(inject_core, t_sec, 0.8)
    elif ev == "deflect":
      place_sfx(bullet_deflect, t_sec, 0.8)

  place_sfx(victory, 26.5, 1.2)

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
  print(f"[SFX] Synthesized 30s showcase sound effects track -> {output_path}")


def build_final_video(
    raw_video: str, narration_audio: str, synth_audio: str, sfx_audio: str, ass_sub: str, output_path: str
):
  """Composites video, narration, background music, game sound effects, and subtitles."""
  os.makedirs(os.path.dirname(output_path), exist_ok=True)

  cmd = [
      "ffmpeg",
      "-y",
      "-i",
      raw_video,
      "-i",
      narration_audio,
      "-i",
      synth_audio,
      "-i",
      sfx_audio,
      "-filter_complex",
      (
          "[0:v]trim=0:60,setpts=PTS-STARTPTS,"
          f"ass={ass_sub}[v];"
          "[1:a]volume=1.35[a_voice];"
          "[2:a]volume=0.28[a_bg];"
          "[3:a]volume=0.88[a_sfx];"
          "[a_voice][a_bg][a_sfx]amix=inputs=3:duration=first:dropout_transition=2[a]"
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
      "60.0",
      "-movflags",
      "+faststart",
      output_path,
  ]

  print(f"[FFmpeg] Executing 60s tutorial mastering pass...")
  res = subprocess.run(cmd, capture_output=True, text=True)
  if res.returncode != 0:
    print(f"[FFmpeg Error] {res.stderr}")
    sys.exit(1)
  print(f"[Mastering] Successfully produced master tutorial video: {output_path}")


def build_showcase_video(raw_video: str, synth_audio: str, sfx_audio: str, output_path: str):
  """Composites 30-second AI Tactical Solver showcase video."""
  os.makedirs(os.path.dirname(output_path), exist_ok=True)

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
          "[1:a]volume=0.35[a_bg];"
          "[2:a]volume=1.0[a_sfx];"
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
      output_path,
  ]

  print(f"[FFmpeg] Executing 30s showcase mastering pass...")
  res = subprocess.run(cmd, capture_output=True, text=True)
  if res.returncode != 0:
    print(f"[FFmpeg Error] {res.stderr}")
    sys.exit(1)
  print(f"[Mastering] Successfully produced showcase video: {output_path}")


def build_animated_gif(video_path: str, output_path: str, start_sec: float = 6.0, duration_sec: float = 12.0):
  """Generates optimized Bayer-dithered preview GIF."""
  os.makedirs(os.path.dirname(output_path), exist_ok=True)

  cmd = [
      "ffmpeg",
      "-y",
      "-ss",
      str(start_sec),
      "-t",
      str(duration_sec),
      "-i",
      video_path,
      "-filter_complex",
      (
          "[0:v]fps=15,scale=360:800:flags=lanczos,split[s0][s1];"
          "[s0]palettegen=max_colors=128[p];"
          "[s1][p]paletteuse=dither=bayer:bayer_scale=3"
      ),
      output_path,
  ]

  print(f"[FFmpeg] Generating preview GIF -> {output_path}...")
  res = subprocess.run(cmd, capture_output=True, text=True)
  if res.returncode != 0:
    print(f"[FFmpeg GIF Error] {res.stderr}")
    sys.exit(1)
  print(f"[Mastering] Successfully produced preview GIF: {output_path}")


def main():
  os.makedirs(SCRATCH_DIR, exist_ok=True)
  narration_wav = os.path.join(SCRATCH_DIR, "narration.wav")
  narration_vtt = os.path.join(SCRATCH_DIR, "subtitles.vtt")
  narration_ass = os.path.join(SCRATCH_DIR, "subtitles.ass")
  synth_wav = os.path.join(SCRATCH_DIR, "background_synth.wav")
  synth_showcase_wav = os.path.join(SCRATCH_DIR, "background_synth_30s.wav")
  sfx_wav = os.path.join(SCRATCH_DIR, "combat_sfx.wav")
  sfx_showcase_wav = os.path.join(SCRATCH_DIR, "combat_sfx_30s.wav")

  # 1. Synthesize Speech & Subtitles
  synthesize_narration(narration_wav, narration_vtt)
  vtt_to_ass(narration_vtt, narration_ass)

  # 2. Synthesize Audio Tracks
  generate_synth_music(synth_wav, duration_sec=62.0)
  generate_synth_music(synth_showcase_wav, duration_sec=32.0)
  generate_sfx_mix(sfx_wav, duration_sec=62.0)
  generate_showcase_sfx_mix(sfx_showcase_wav, duration_sec=32.0)

  # 3. Pull gameplay recording from device
  local_raw_video = os.path.join(SCRATCH_DIR, "raw_gameplay_60s.mp4")
  print("[ADB] Pulling gameplay recording from emulator...")
  pull_res = subprocess.run(
      ["adb", "-s", "emulator-5554", "pull", "/sdcard/gameplay_60s.mp4", local_raw_video],
      capture_output=True,
      text=True,
  )
  if pull_res.returncode != 0 or not os.path.exists(local_raw_video):
    print(f"[ADB Error] Failed to pull /sdcard/gameplay_60s.mp4: {pull_res.stderr}")
    sys.exit(1)

  # 4. Master 60s How-to-Play Video
  target_docs_60s = "/home/kelvingorekore/projects/void-sower/docs/media/void_sower_how_to_play_60s.mp4"
  target_store_60s = "/home/kelvingorekore/projects/void-sower/store_listing/assets/how_to_play_60s.mp4"
  target_inapp_60s = "/home/kelvingorekore/projects/void-sower/assets/video/how_to_play.mp4"

  build_final_video(local_raw_video, narration_wav, synth_wav, sfx_wav, narration_ass, target_docs_60s)
  shutil.copyfile(target_docs_60s, target_store_60s)
  print(f"[Deploy] Copied to store assets: {target_store_60s}")
  os.makedirs(os.path.dirname(target_inapp_60s), exist_ok=True)
  shutil.copyfile(target_docs_60s, target_inapp_60s)
  print(f"[Deploy] Copied to in-app assets: {target_inapp_60s}")

  # 5. Pull & Master 30s Showcase Video if available
  local_showcase_video = os.path.join(SCRATCH_DIR, "raw_solver_30s.mp4")
  pull_showcase = subprocess.run(
      ["adb", "-s", "emulator-5554", "pull", "/sdcard/solver_30s.mp4", local_showcase_video],
      capture_output=True,
      text=True,
  )
  if pull_showcase.returncode == 0 and os.path.exists(local_showcase_video):
    target_docs_30s = "/home/kelvingorekore/projects/void-sower/docs/media/void_sower_solver_showcase_30s.mp4"
    target_store_30s = "/home/kelvingorekore/projects/void-sower/store_listing/assets/promo_gameplay.mp4"
    build_showcase_video(local_showcase_video, synth_showcase_wav, sfx_showcase_wav, target_docs_30s)
    shutil.copyfile(target_docs_30s, target_store_30s)
    print(f"[Deploy] Copied to store assets: {target_store_30s}")

    # 6. Master Preview GIFs
    target_docs_gif = "/home/kelvingorekore/projects/void-sower/docs/media/void_sower_solver_showcase.gif"
    target_store_gif = "/home/kelvingorekore/projects/void-sower/store_listing/assets/promo_gameplay.gif"
    build_animated_gif(target_docs_30s, target_docs_gif, start_sec=5.0, duration_sec=10.0)
    shutil.copyfile(target_docs_gif, target_store_gif)
    print(f"[Deploy] Copied to store assets: {target_store_gif}")


if __name__ == "__main__":
  main()
