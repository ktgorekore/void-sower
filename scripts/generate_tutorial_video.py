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
    "Your weapon system is the ancient sixteen-bay Bao Mancala capacitor ring. "
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


def build_final_video(
    raw_video: str, narration_audio: str, synth_audio: str, ass_sub: str, output_path: str
):
  """Composites video, narration, background music, and subtitles into master video."""
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
      "-filter_complex",
      (
          "[0:v]trim=0:60,setpts=PTS-STARTPTS,"
          f"ass={ass_sub}[v];"
          "[1:a]volume=1.35[a_voice];"
          "[2:a]volume=0.32[a_bg];"
          "[a_voice][a_bg]amix=inputs=2:duration=first:dropout_transition=2[a]"
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

  # 1. Synthesize Speech
  synthesize_narration(narration_wav, narration_srt)
  vtt_to_ass(narration_srt, narration_ass)

  # 2. Synthesize Background Audio
  generate_synth_music(synth_wav, duration_sec=62.0)

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

  build_final_video(local_raw_video, narration_wav, synth_wav, narration_ass, target_docs)
  shutil.copyfile(target_docs, target_store)
  print(f"[Deploy] Copied to store assets: {target_store}")


if __name__ == "__main__":
  main()
