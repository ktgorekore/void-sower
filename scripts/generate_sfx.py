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
  dur = 0.12
  t = np.linspace(0, dur, int(SAMPLE_RATE * dur), endpoint=False)
  env = np.exp(-t * 32.0)

  # Dual-tone resonant marimba/kalimba wood chime + harmonic crystal (Eb5 / Bb5)
  f1 = 622.25  # Eb5
  f2 = 932.33  # Bb5
  f3 = 1244.50  # Eb6
  f4 = 311.13  # Eb4 body resonance
  sig = (
      0.45 * np.sin(2 * np.pi * f1 * t)
      + 0.35 * np.sin(2 * np.pi * f2 * t)
      + 0.20 * np.sin(2 * np.pi * f3 * t)
      + 0.30 * np.sin(2 * np.pi * f4 * t)
  ) * env

  # Crisp wooden mallet strike attack transient
  click = np.random.uniform(-0.5, 0.5, len(t)) * np.exp(-t * 220.0)
  sig = np.tanh(sig + click)
  write_wav("sow_step.wav", sig)


def gen_inject_core():
  """Magnetic sci-fi core injection thunk & capacitor charging whoosh."""
  dur = 0.20
  t = np.linspace(0, dur, int(SAMPLE_RATE * dur), endpoint=False)
  env = np.sin(np.pi * t / dur) ** 0.4 * np.exp(-t * 6.0)

  # Pitch sweep rising 240 Hz -> 1180 Hz
  freq = 240.0 + (1180.0 - 240.0) * (t / dur) ** 1.6
  phase = 2 * np.pi * np.cumsum(freq) / SAMPLE_RATE
  sig = 0.70 * np.sin(phase) * env

  # Heavy pneumatic magnetic lock click at start
  click_env = np.exp(-t * 140.0)
  sig += (
      0.6 * np.sin(2 * np.pi * 1400.0 * t) + 0.5 * np.sin(2 * np.pi * 160.0 * t)
  ) * click_env
  sig = np.tanh(sig * 1.3)
  write_wav("inject_core.wav", sig)


def gen_lance_fire():
  """Massive, visceral axial Particle Lance discharge.

  Sub-bass punch + supersonic laser screech chirp + plasma sizzle.
  """
  dur = 0.52
  t = np.linspace(0, dur, int(SAMPLE_RATE * dur), endpoint=False)

  # 1. 808 Sub-bass thump (110 Hz -> 32 Hz)
  bass_env = np.exp(-t * 11.0)
  bass_freq = 110.0 - 78.0 * (t / dur)
  bass_phase = 2 * np.pi * np.cumsum(bass_freq) / SAMPLE_RATE
  bass = 0.85 * np.sin(bass_phase) * bass_env

  # 2. Piercing laser sweep (2400 Hz -> 360 Hz) with heavy FM modulation
  laser_env = np.exp(-t * 8.0)
  laser_freq = 2400.0 * np.exp(-t * 9.0) + 360.0
  fm = 60.0 * np.sin(2 * np.pi * 140.0 * t)
  laser_phase = 2 * np.pi * np.cumsum(laser_freq + fm) / SAMPLE_RATE
  laser = 0.70 * np.sin(laser_phase) * laser_env

  # 3. White-hot ionized plasma sizzle burst
  noise = np.random.uniform(-0.45, 0.45, len(t)) * np.exp(-t * 14.0)

  # Heavy analog drive saturation curve
  combined = np.tanh((bass + laser + noise) * 1.4)
  write_wav("lance_fire.wav", combined)


def gen_flak_burst():
  """Secondary flak detonation: crunchy explosion with metallic shrapnel reverb."""
  dur = 0.40
  t = np.linspace(0, dur, int(SAMPLE_RATE * dur), endpoint=False)

  # Low-frequency shockwave thump
  sub_env = np.exp(-t * 16.0)
  sub = 0.85 * np.sin(2 * np.pi * 60.0 * t) * sub_env

  # Dense metallic burst noise
  noise = np.random.uniform(-0.7, 0.7, len(t))
  filtered_noise = np.convolve(noise, np.ones(6) / 6, mode="same")
  noise_env = np.exp(-t * 11.0)

  sig = np.tanh(sub + filtered_noise * noise_env * 1.3)
  write_wav("flak_burst.wav", sig)


def gen_shield_hit():
  """Conduit breach / shield impact electrical alarm crack.

  Triggered when enemy bomb directly strikes the dreadnought!
  """
  dur = 0.45
  t = np.linspace(0, dur, int(SAMPLE_RATE * dur), endpoint=False)

  # Electrical breaker buzz
  buzz_freq = 160.0
  buzz = 0.6 * np.sign(np.sin(2 * np.pi * buzz_freq * t)) * np.exp(-t * 10.0)

  # Warning chirp (900 Hz -> 180 Hz)
  chirp_freq = 900.0 - 720.0 * (t / dur)
  chirp_phase = 2 * np.pi * np.cumsum(chirp_freq) / SAMPLE_RATE
  chirp = 0.6 * np.sin(chirp_phase) * np.exp(-t * 8.0)

  # Heavy distortion crack
  crack = np.random.uniform(-0.6, 0.6, len(t)) * np.exp(-t * 35.0)

  sig = np.tanh(buzz + chirp + crack)
  write_wav("shield_hit.wav", sig)
  write_wav("conduit_breach.wav", sig)


def gen_bullet_deflect():
  """Laser beam bullet deflection ping: crisp high-energy ricochet and glass chime."""
  dur = 0.22
  t = np.linspace(0, dur, int(SAMPLE_RATE * dur), endpoint=False)
  env = np.exp(-t * 22.0)

  # High-speed laser chirp 2800 Hz -> 850 Hz
  freq = 2800.0 * np.exp(-t * 18.0) + 850.0
  phase = 2 * np.pi * np.cumsum(freq) / SAMPLE_RATE
  chirp = 0.65 * np.sin(phase) * env

  # Crystalline chime overtone (3300 Hz)
  chime = 0.40 * np.sin(2 * np.pi * 3300.0 * t) * np.exp(-t * 30.0)

  # Metallic transient click
  click = np.random.uniform(-0.5, 0.5, len(t)) * np.exp(-t * 160.0)

  sig = np.tanh(chirp + chime + click)
  write_wav("bullet_deflect.wav", sig)


def gen_victory():
  """Ascending celebratory Afrofuturist synth fanfare in Eb Major."""
  dur = 1.8
  t = np.linspace(0, dur, int(SAMPLE_RATE * dur), endpoint=False)
  sig = np.zeros_like(t)

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

    tone = (
        0.5 * np.sin(2 * np.pi * freq * t_seg)
        + 0.25 * np.sin(2 * np.pi * freq * 2 * t_seg)
        + 0.15 * np.sin(2 * np.pi * freq * 3 * t_seg)
    )
    sig[start_idx:end_idx] += tone * env

  sig = np.tanh(sig * 1.2)
  write_wav("victory.wav", sig)


def gen_defeat():
  """Deep power-down reactor failure sound with descending pitch whine."""
  dur = 1.4
  t = np.linspace(0, dur, int(SAMPLE_RATE * dur), endpoint=False)
  env = np.exp(-t * 2.2)

  freq = 1100.0 * np.exp(-t * 3.5) + 50.0
  phase = 2 * np.pi * np.cumsum(freq) / SAMPLE_RATE
  whine = 0.55 * np.sin(phase) * env

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
  gen_bullet_deflect()
  gen_victory()
  gen_defeat()
  print("[SFX Generator] All sound effects generated successfully!")


if __name__ == "__main__":
  main()
