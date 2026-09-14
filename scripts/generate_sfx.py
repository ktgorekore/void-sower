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

"""Generates high-impact, Afrofuturist sci-fi sound effects for Void Sower."""

import os
import wave
import numpy as np

SAMPLE_RATE = 44100
OUTPUT_DIR = "/home/kelvingorekore/projects/void-sower/assets/audio"


def write_wav(filename: str, samples: np.ndarray):
  """Writes 1D float32 audio samples [-1.0, 1.0] to a 16-bit PCM WAV file."""
  os.makedirs(OUTPUT_DIR, exist_ok=True)
  path = os.path.join(OUTPUT_DIR, filename)

  # Normalize and prevent clipping
  peak = np.max(np.abs(samples))
  if peak > 0:
    samples = samples / peak * 0.92

  pcm = (samples * 32767).astype(np.int16)
  with wave.open(path, "wb") as wf:
    wf.setnchannels(1)  # Mono for low-latency spatial audio
    wf.setsampwidth(2)
    wf.setframerate(SAMPLE_RATE)
    wf.writeframes(pcm.tobytes())
  print(f"[SFX] Generated: {path} ({len(samples)/SAMPLE_RATE:.2f}s)")


def gen_sow_step():
  """Resonant Afrofuturist mbira/crystal count-and-capture step."""
  dur = 0.10
  t = np.linspace(0, dur, int(SAMPLE_RATE * dur), endpoint=False)
  env = np.exp(-t * 35.0)

  # Dual-tone kalimba wood chime + harmonic crystal
  f1 = 880.0
  f2 = 1760.0
  f3 = 440.0
  sig = (
      0.55 * np.sin(2 * np.pi * f1 * t)
      + 0.30 * np.sin(2 * np.pi * f2 * t)
      + 0.40 * np.sin(2 * np.pi * f3 * t)
  ) * env

  # Crisp initial attack click
  click = np.random.uniform(-0.4, 0.4, len(t)) * np.exp(-t * 180.0)
  sig += click
  write_wav("sow_step.wav", sig)


def gen_inject_core():
  """Magnetic sci-fi core injection thunk & capacitor charging whoosh."""
  dur = 0.18
  t = np.linspace(0, dur, int(SAMPLE_RATE * dur), endpoint=False)
  env = np.sin(np.pi * t / dur) ** 0.5 * np.exp(-t * 8.0)

  # Pitch sweep rising 280 Hz -> 920 Hz
  freq = 280.0 + (920.0 - 280.0) * (t / dur) ** 1.8
  phase = 2 * np.pi * np.cumsum(freq) / SAMPLE_RATE
  sig = 0.65 * np.sin(phase) * env

  # Heavy magnetic lock click at start
  click_env = np.exp(-t * 120.0)
  sig += (
      0.5 * np.sin(2 * np.pi * 1200.0 * t) + 0.4 * np.sin(2 * np.pi * 180.0 * t)
  ) * click_env
  write_wav("inject_core.wav", sig)


def gen_lance_fire():
  """Massive, visceral axial Particle Lance discharge.

  Sub-bass punch + supersonic laser screech chirp + plasma sizzle.
  """
  dur = 0.48
  t = np.linspace(0, dur, int(SAMPLE_RATE * dur), endpoint=False)

  # 1. Sub-bass thump (80 Hz -> 35 Hz)
  bass_env = np.exp(-t * 14.0)
  bass_freq = 85.0 - 45.0 * (t / dur)
  bass_phase = 2 * np.pi * np.cumsum(bass_freq) / SAMPLE_RATE
  bass = 0.75 * np.sin(bass_phase) * bass_env

  # 2. Piercing laser sweep (1900 Hz -> 320 Hz) with FM modulation
  laser_env = np.exp(-t * 9.0)
  laser_freq = 1900.0 * np.exp(-t * 8.0) + 320.0
  fm = 40.0 * np.sin(2 * np.pi * 120.0 * t)
  laser_phase = 2 * np.pi * np.cumsum(laser_freq + fm) / SAMPLE_RATE
  laser = 0.60 * np.sin(laser_phase) * laser_env

  # 3. White-hot plasma sizzle burst
  noise = np.random.uniform(-0.35, 0.35, len(t)) * np.exp(-t * 16.0)

  # Soft saturation curve
  combined = np.tanh(bass + laser + noise)
  write_wav("lance_fire.wav", combined)


def gen_flak_burst():
  """Secondary flak detonation: crunchy explosion with metallic shrapnel reverb."""
  dur = 0.38
  t = np.linspace(0, dur, int(SAMPLE_RATE * dur), endpoint=False)

  # Low-frequency shockwave thump
  sub_env = np.exp(-t * 18.0)
  sub = 0.8 * np.sin(2 * np.pi * 65.0 * t) * sub_env

  # Dense metallic burst noise
  noise = np.random.uniform(-0.6, 0.6, len(t))
  # Lowpass filter effect via simple moving average
  filtered_noise = np.convolve(noise, np.ones(8) / 8, mode="same")
  noise_env = np.exp(-t * 12.0)

  sig = np.tanh(sub + filtered_noise * noise_env * 1.2)
  write_wav("flak_burst.wav", sig)


def gen_shield_hit():
  """Conduit breach / shield impact electrical alarm crack.

  Triggered when enemy bomb directly strikes the dreadnought!
  """
  dur = 0.42
  t = np.linspace(0, dur, int(SAMPLE_RATE * dur), endpoint=False)

  # Electrical buzzer / crackle
  buzz_freq = 140.0
  buzz = 0.5 * np.sign(np.sin(2 * np.pi * buzz_freq * t)) * np.exp(-t * 12.0)

  # Warning chirp (750 Hz -> 200 Hz)
  chirp_freq = 750.0 - 550.0 * (t / dur)
  chirp_phase = 2 * np.pi * np.cumsum(chirp_freq) / SAMPLE_RATE
  chirp = 0.5 * np.sin(chirp_phase) * np.exp(-t * 10.0)

  # Distortion crack
  crack = np.random.uniform(-0.5, 0.5, len(t)) * np.exp(-t * 45.0)

  sig = np.tanh(buzz + chirp + crack)
  write_wav("shield_hit.wav", sig)
  write_wav("conduit_breach.wav", sig)


def gen_victory():
  """Ascending celebratory Afrofuturist synth fanfare in Eb Major."""
  dur = 1.8
  t = np.linspace(0, dur, int(SAMPLE_RATE * dur), endpoint=False)
  sig = np.zeros_like(t)

  # Arpeggio notes: Eb4 (311.13), G4 (392.00), Bb4 (466.16), Eb5 (622.25), G5 (783.99)
  notes = [
      (0.00, 0.35, 311.13),
      (0.18, 0.35, 392.00),
      (0.36, 0.35, 466.16),
      (0.54, 0.55, 622.25),
      (0.72, 1.05, 783.99),
  ]

  for start_t, note_dur, freq in notes:
    start_idx = int(start_t * SAMPLE_RATE)
    end_idx = min(int((start_t + note_dur) * SAMPLE_RATE), len(t))
    t_seg = t[start_idx:end_idx] - start_t
    env = np.sin(np.pi * t_seg / note_dur) ** 0.6 * np.exp(-t_seg * 1.5)

    # Rich saw-like chime
    tone = (
        0.5 * np.sin(2 * np.pi * freq * t_seg)
        + 0.25 * np.sin(2 * np.pi * freq * 2 * t_seg)
        + 0.15 * np.sin(2 * np.pi * freq * 3 * t_seg)
    )
    sig[start_idx:end_idx] += tone * env

  write_wav("victory.wav", sig)


def gen_defeat():
  """Deep power-down reactor failure sound with descending pitch whine."""
  dur = 1.4
  t = np.linspace(0, dur, int(SAMPLE_RATE * dur), endpoint=False)
  env = np.exp(-t * 2.2)

  # Reactor spin-down whine: 1100 Hz down to 60 Hz
  freq = 1100.0 * np.exp(-t * 3.5) + 50.0
  phase = 2 * np.pi * np.cumsum(freq) / SAMPLE_RATE
  whine = 0.55 * np.sin(phase) * env

  # Sub-bass rumble
  rumble = (
      0.6 * np.sin(2 * np.pi * 45.0 * t) * env * (1.0 + 0.3 * np.sin(20.0 * t))
  )

  sig = np.tanh(whine + rumble)
  write_wav("defeat.wav", sig)


def main():
  print("[SFX Generator] Synthesizing Void Sower sound palette...")
  gen_sow_step()
  gen_inject_core()
  gen_lance_fire()
  gen_flak_burst()
  gen_shield_hit()
  gen_victory()
  gen_defeat()
  print("[SFX Generator] All sound effects generated successfully!")


if __name__ == "__main__":
  main()
