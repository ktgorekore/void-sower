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
  static const Color emeraldShield = Color(0xFF00FFA3);

  static const Color textPrimary = Color(0xFFF0F4FC);
  static const Color textSecondary = Color(0xFF90A0C0);
  static const Color textMuted = Color(0xFF5A6882);

  /// Glassmorphic frosted-glass box decoration with subtle neon border glow.
  static BoxDecoration glassmorphic({
    Color borderColor = cardSurface,
    double borderWidth = 1.0,
    double borderRadius = 12.0,
    double opacity = 0.85,
    List<BoxShadow>? extraShadows,
  }) {
    return BoxDecoration(
      color: cardSurface.withValues(alpha: opacity),
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(color: borderColor, width: borderWidth),
      boxShadow: [
        BoxShadow(
          color: obsidianBlack.withValues(alpha: 0.6),
          blurRadius: 12.0,
          offset: const Offset(0, 4),
        ),
        ...?extraShadows,
      ],
    );
  }

  /// Neon glowing box decoration for active tactical indicators and buttons.
  static BoxDecoration neonGlow({
    required Color color,
    double blur = 10.0,
    double borderRadius = 8.0,
  }) {
    return BoxDecoration(
      color: color.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(color: color, width: 1.5),
      boxShadow: [
        BoxShadow(
          color: color.withValues(alpha: 0.35),
          blurRadius: blur,
          spreadRadius: 1.0,
        ),
      ],
    );
  }

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
