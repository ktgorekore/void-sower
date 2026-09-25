// Copyright 2026 Void Sower Authors.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

/// Discrete modal overlay and presentation flow states for [CombatScreen].
enum CombatOverlayState {
  /// Pure real-time combat view, zero modals, active simulation.
  none,

  /// Tactical pause menu open.
  paused,

  /// Interactive Flight Academy tutorial overlay active.
  briefing,

  /// Bao Codex rules and lore manual open.
  codex,

  /// Pilot audio/video/privacy settings modal open.
  settings,

  /// Commander pilot profile modal open.
  profile,

  /// Emergency auxiliary core rewarded ad modal open.
  emergencyFlare,

  /// Pro Commander upgrade & discovery modal open.
  proUpgrade,

  /// Post-breach explosion delay (400ms) before defeat modal appears.
  defeatGrace,

  /// Game Over defeat dialog visible.
  defeatModal,

  /// Fanfare and in-flight shot settling delay (600ms) before victory modal appears.
  victoryGrace,

  /// Sector Secured victory dialog visible.
  victoryModal,

  /// Victory dialog dismissed by user; battlefield remains in review state.
  victoryReview,
}

extension CombatOverlayStateX on CombatOverlayState {
  /// Whether an interactive modal dialog is presently obstructing combat gameplay.
  bool get isModalOpen =>
      this != CombatOverlayState.none &&
      this != CombatOverlayState.victoryReview &&
      this != CombatOverlayState.defeatGrace &&
      this != CombatOverlayState.victoryGrace;

  /// Whether the session is undergoing terminal post-match flow.
  bool get isTerminalFlow =>
      this == CombatOverlayState.defeatGrace ||
      this == CombatOverlayState.defeatModal ||
      this == CombatOverlayState.victoryGrace ||
      this == CombatOverlayState.victoryModal ||
      this == CombatOverlayState.victoryReview;
}
