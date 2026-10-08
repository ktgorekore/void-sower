<!--
  Copyright 2026 Void Sower Authors.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

      http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
-->

# Google Play Console Release Notes — v0.3.1 (Build 41)

## Release Track: Production / Internal / Open Testing

---

### Copy-Paste Release Notes for Play Console (`en-US`)
```text
<en-US>
⚡ Void Sower v0.3.1 — Performance & Battery Optimization Update!
• Zero-Allocation Rendering: Buttery smooth 60/120Hz starfield projection and particle combat with zero transient frame allocations.
• Battery Conservation: Smart RouteAware lifecycle management halts background timers and combat tickers during menus and overlays.
• Robust Ad Flow: Hardened state machine guarantees reliable rewarded boosts.
• Architecture Hardening: Naturally aligned FFI engine structs with boundary validation.
</en-US>
```
*Character Count:* **495 / 500 max characters** (Google Play compliant).

---

### Localized Release Notes

#### 🇹🇿 Swahili (`sw`)
```text
<sw>
⚡ Void Sower v0.3.1 — Maboresho ya Utendaji na Uhifadhi wa Betri!
• Michoro Laini ya 60/120Hz: Anga ya nyota na mapigano ya leza yasiyochukua kumbukumbu ya ziada kwa fremu.
• Uhifadhi wa Betri: Mfumo mahiri wa kusitisha vihesabu muda wakati wa menyu na kurasa za mapumziko.
• Utazamaji Matangazo Imara: Usimamizi thabiti unaohakikisha zawadi za Pro Boost bila hitilafu.
• Muundo Thabiti wa Injini: Miundo iliyopangwa kiasili ya FFI na ukaguzi madhubuti wa mipaka.
</sw>
```
*Character Count:* **476 / 500 max characters**.

#### 🇫🇷 French (`fr-FR`)
```text
<fr-FR>
⚡ Void Sower v0.3.1 — Optimisation des Performances & Économie de Batterie !
• Rendu Fluide 60/120Hz : Projection stellaire et tirs laser sans allocation transitoire par trame.
• Préservation de Batterie : Pause intelligente des horloges et moteurs graphiques dans les menus et fenêtres.
• Publicités Récompensées Fiables : Machine à états robuste pour les bonus Pro Boost.
• Moteur FFI Renforcé : Alignement naturel des structures C++ et validation stricte des limites.
</fr-FR>
```
*Character Count:* **494 / 500 max characters**.

#### 🇪🇸 Spanish (`es-ES`)
```text
<es-ES>
⚡ Void Sower v0.3.1 — ¡Optimización de Rendimiento y Ahorro de Batería!
• Renderizado Fluido 60/120Hz: Campo estelar 3D y combate láser sin asignaciones de memoria por cuadro.
• Ahorro Inteligente de Batería: Pausa de temporizadores y bucles gráficos en menús y pantallas fijas.
• Anuncios Recompensados Confiables: Flujo blindado que asegura las bonificaciones Pro Boost.
• Motor C++ / FFI Fortalecido: Alineación natural de estructuras y validación segura de memoria.
</es-ES>
```
*Character Count:* **487 / 500 max characters**.

---

### Internal Engineering Notes (Build 41)
- **Natural FFI Memory Alignment:** Removed `#pragma pack(push, 1)` from `src/void_sower.h` and eliminated `@ffi.Packed(1)` annotations from `void_sower_bindings_generated.dart`. Replaced packed layouts with natural 4-byte/8-byte alignments and explicit padding across all 7 FFI structs (`VoidSowerBayFFI`, `VoidSowerEnemyFFI`, `VoidSowerLanceFFI`, `VoidSowerFlakFFI`, `VoidSowerDreadnoughtFFI`, `VoidSowerPredictionFFI`, `VoidSowerWaveConfigFFI`).
- **Snapshot Bounds Checking:** Updated `void_sower_restore_snapshot` signature with `size_t charges_length` (accepting `chargesLength = 16` via Dart FFI) and added defensive buffer validation (`charges_length == 0 || !bay_charges`).
- **Hot-Path Memory Reaping:** Replaced heap `std::vector` in `CombatSystem::Update` with pre-allocated `absl::InlinedVector<entt::entity, 128> reap_buffer_` to achieve zero allocations during entity destruction on 60/120 Hz loops.
- **Power-of-Two Bitwise Masking:** Replaced modulo operations with bitwise masks in `CombatCoordinator` (`& 3 == 0`), `CombatSystem` (`& 1`), and `WaveGenerator` (`& 1`).
- **Battery & Ticker Lifecycle:**
  - Integrated `RouteObserver` and `RouteAware` in `CampaignMapScreen` to halt the 1-second Pro Boost countdown timer when pushed over (e.g. entering combat) and cleanly resume on pop.
  - Halted the Flutter `Ticker` loop in `CombatScreen` whenever static modals or sheets (`defeatGrace`, `defeatModal`, `victoryModal`, `victoryReview`, `settings`) are visible, resuming strictly on active gameplay.
- **Audio Carrier Wave Elimination:** Removed `_buildSilentWavBytes` and in-memory silent WAV playback fallback in `AudioService`.
- **Zero-Allocation Canvas Projections:**
  - Converted `CombatPainter._drawEnemyBullet` to use `canvas.translate` with `Offset.zero` and `const Offset(0.0, -16.0)`, eliminating 2 allocations per bullet per frame.
  - Converted `StarfieldPainter.paint` and `_paintCosmicNebulae` to use canvas translations and `Offset.zero`, preventing per-star and per-nebula transient object allocations.
- **Hardened Ad Lifecycle State Machine:** Refactored `AdService` to an explicit `AdLifecycleState` enum (`uninitialized`, `idle`, `loading`, `ready`, `showing`, `error`) with single-flight re-entrance guards, and decoupled Pro Boost entitlement granting from rewarded ad display.
