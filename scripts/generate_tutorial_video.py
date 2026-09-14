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

"""Generates the official 60-second narrated 'How to Play' video for Void Sower."""

import asyncio
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
    "Welcome Commander to Void Sower. You command the Olympus Dreadnought flagship "
    "stationed at the bottom atmospheric defense line, defending against relentless waves of the Void Swarm. "
    "Alien assault vessels advance down eight tactical corridors, dropping deadly plasma bombs directly toward your flagship. "
    "Maneuver horizontally to evade incoming ordnance while your flagship conduit locks onto that corridor. "
    "Your weapon system is powered by a twenty-eight core reactor and the sixteen-bay Bao Mancala capacitor ring. "
    "Tap Discharge or sow seeds sequentially around the orbital ring to unleash a catastrophic upward Particle Lance. "
    "The lance vaporizes enemy formations and deflects incoming bombs in that corridor. "
    "Sow into the inner reservoir bays zero through seven to bank energy for devastating multi-lap cascade relays. "
    "Master the ancient African sowing mathematics to liberate the cosmos!"
)

VOICE = "en-US-ChristopherNeural"
RATE = "+4%"

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

  # 1. Opening sequence (briefing & initial core injection)
  place_sfx(inject_core, 0.8, 0.8)
  place_sfx(inject_core, 2.2, 0.8)

  # 2. First sowing cadence (Bao Mancala hops)
  for i, t_offset in enumerate([4.0, 4.25, 4.5, 4.75, 5.0, 5.25]):
    place_sfx(sow_step, t_offset, 0.75 + i * 0.05)

  # 3. First devastating Particle Lance blast & explosion
  place_sfx(lance_fire, 5.6, 1.2)
  place_sfx(flak_burst, 6.2, 0.9)
  place_sfx(bullet_deflect, 7.0, 0.8)

  # 4. Continuous active combat loops throughout 60s
  combat_events = [
      (9.0, "sow"), (9.2, "sow"), (9.4, "sow"), (9.6, "lance"), (10.2, "flak"),
      (12.5, "inject"), (13.5, "sow"), (13.7, "sow"), (13.9, "sow"), (14.1, "lance"), (14.8, "deflect"),
      (17.0, "sow"), (17.2, "sow"), (17.5, "lance"), (18.2, "flak"), (19.0, "shield"),
      (21.5, "inject"), (22.2, "sow"), (22.4, "sow"), (22.6, "sow"), (22.9, "lance"), (23.5, "flak"),
      (26.0, "sow"), (26.2, "sow"), (26.5, "lance"), (27.2, "deflect"), (28.0, "deflect"),
      (30.5, "inject"), (31.2, "sow"), (31.4, "sow"), (31.6, "sow"), (31.9, "lance"), (32.6, "flak"),
      (35.0, "sow"), (35.2, "sow"), (35.5, "lance"), (36.2, "flak"), (37.5, "shield"),
      (40.0, "sow"), (40.2, "sow"), (40.4, "sow"), (40.7, "lance"), (41.4, "deflect"),
      (44.0, "inject"), (45.0, "sow"), (45.2, "sow"), (45.5, "lance"), (46.2, "flak"),
      (48.5, "sow"), (48.7, "sow"), (49.0, "lance"), (49.8, "flak"), (50.5, "deflect"),
      (53.0, "sow"), (53.2, "sow"), (53.4, "sow"), (53.7, "lance"), (54.5, "flak"),
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

  # 5. Grand victory finale
  place_sfx(victory, 56.5, 1.1)

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

  print(f"[FFmpeg] Executing mastering pass...")
  res = subprocess.run(cmd, capture_output=True, text=True)
  if res.returncode != 0:
    print(f"[FFmpeg Error] {res.stderr}")
    sys.exit(1)
  print(f"[Mastering] Successfully produced master video: {output_path}")


def main():
  os.makedirs(SCRATCH_DIR, exist_ok=True)
  narration_wav = os.path.join(SCRATCH_DIR, "narration.wav")
  narration_srt = os.path.join(SCRATCH_DIR, "subtitles.srt")
  narration_ass = os.path.join(SCRATCH_DIR, "subtitles.ass")
  synth_wav = os.path.join(SCRATCH_DIR, "background_synth.wav")
  sfx_wav = os.path.join(SCRATCH_DIR, "combat_sfx.wav")

  # 1. Synthesize Speech
  synthesize_narration(narration_wav, narration_srt)
  vtt_to_ass(narration_srt, narration_ass)

  # 2. Synthesize Background Audio & Sound Effects
  generate_synth_music(synth_wav, duration_sec=62.0)
  generate_sfx_mix(sfx_wav, duration_sec=62.0)

  # 3. Pull gameplay recording from device if available
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
  target_docs = "/home/kelvingorekore/projects/void-sower/docs/media/void_sower_how_to_play_60s.mp4"
  target_store = "/home/kelvingorekore/projects/void-sower/store_listing/assets/how_to_play_60s.mp4"

  build_final_video(local_raw_video, narration_wav, synth_wav, sfx_wav, narration_ass, target_docs)
  shutil.copyfile(target_docs, target_store)
  print(f"[Deploy] Copied to store assets: {target_store}")


if __name__ == "__main__":
  main()
