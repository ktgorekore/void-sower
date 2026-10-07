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

import 'settings_modal.dart';

/// Modal presentation providing in-combat audio, visual, and academy settings.
class CombatSettingsSheet extends StatelessWidget {
  /// Creates a [CombatSettingsSheet].
  const CombatSettingsSheet({
    super.key,
    required this.onLaunchAcademy,
    required this.onResetTutorial,
    this.onClose,
  });

  /// Callback when user elects to launch tactical academy flight training.
  final VoidCallback onLaunchAcademy;

  /// Callback when user resets academy tutorial progress.
  final VoidCallback onResetTutorial;

  /// Optional dismiss callback.
  final VoidCallback? onClose;

  /// Displays the combat settings modal dialog.
  static Future<void> show({
    required BuildContext context,
    required VoidCallback onLaunchAcademy,
    required VoidCallback onResetTutorial,
  }) {
    return showDialog<void>(
      context: context,
      builder: (dialogCtx) => CombatSettingsSheet(
        onLaunchAcademy: onLaunchAcademy,
        onResetTutorial: onResetTutorial,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SettingsModal(
      onLaunchAcademy: onLaunchAcademy,
      onResetTutorial: onResetTutorial,
    );
  }
}
