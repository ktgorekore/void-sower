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

/// Afrofuturist sci-fi aesthetic palette for Void Sower.
class VoidTheme {
  static const Color obsidianBlack = Color(0xFF070A12);
  static const Color deepSpaceVoid = Color(0xFF0D1220);
  static const Color cosmicNavy = Color(0xFF141B2D);
  static const Color cardSurface = Color(0xFF1B233A);

  static const Color solarGold = Color(0xFFFFB300);
  static const Color solarGoldLight = Color(0xFFFFD54F);
  static const Color plasmaCyan = Color(0xFF00E5FF);
  static const Color plasmaCyanLight = Color(0xFF84FFFF);
  static const Color crimsonFlare = Color(0xFFFF1744);
  static const Color nebulaAmethyst = Color(0xFF7C4DFF);

  static const Color textPrimary = Color(0xFFF0F4FC);
  static const Color textSecondary = Color(0xFF90A0C0);
  static const Color textMuted = Color(0xFF5A6882);

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: obsidianBlack,
      primaryColor: solarGold,
      colorScheme: const ColorScheme.dark(
        primary: solarGold,
        secondary: plasmaCyan,
        surface: cardSurface,
        error: crimsonFlare,
        onPrimary: obsidianBlack,
        onSecondary: obsidianBlack,
        onSurface: textPrimary,
      ),
      fontFamily: 'monospace',
    );
  }
}
