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

import 'package:flutter/material.dart';

import '../widgets/combat_settings_sheet.dart';

/// Coordinates modal presentation and lifecycle interactions during combat.
class CombatDialogCoordinator {
  /// Creates a [CombatDialogCoordinator] with the specified lifecycle callbacks.
  CombatDialogCoordinator({
    required this.onCombatPause,
    required this.onCombatResume,
    required this.onRestartCombat,
    required this.onAdvanceSector,
  });

  /// Callback to pause combat simulation and stop ticker.
  final VoidCallback onCombatPause;

  /// Callback to resume combat simulation and ticker.
  final VoidCallback onCombatResume;

  /// Callback to restart combat match.
  final VoidCallback onRestartCombat;

  /// Callback to advance to the next sector.
  final VoidCallback onAdvanceSector;

  /// Presents the combat settings dialog, pausing combat while open.
  Future<void> showSettings({
    required BuildContext context,
    required VoidCallback onLaunchAcademy,
    required VoidCallback onResetTutorial,
    VoidCallback? onDismiss,
  }) async {
    onCombatPause();
    await CombatSettingsSheet.show(
      context: context,
      onLaunchAcademy: onLaunchAcademy,
      onResetTutorial: onResetTutorial,
    );
    onDismiss?.call();
  }

  /// Presents the defeat / game-over dialog modal.
  Future<void> showDefeat({
    required BuildContext context,
    required WidgetBuilder builder,
    VoidCallback? onDismiss,
  }) async {
    onCombatPause();
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: builder,
    );
    onDismiss?.call();
  }

  /// Presents the victory dialog modal.
  Future<void> showVictory({
    required BuildContext context,
    required WidgetBuilder builder,
    VoidCallback? onDismiss,
  }) async {
    onCombatPause();
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: builder,
    );
    onDismiss?.call();
  }

  /// Presents the pause menu modal dialog.
  Future<void> showPauseMenu({
    required BuildContext context,
    required WidgetBuilder builder,
    Color? barrierColor,
    VoidCallback? onDismiss,
  }) async {
    onCombatPause();
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: barrierColor,
      builder: builder,
    );
    onDismiss?.call();
  }
}
