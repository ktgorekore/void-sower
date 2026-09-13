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

import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';

/// Preloads and manages runtime GLSL shaders with graceful fallback.
class ShaderService {
  ShaderService._();
  static final ShaderService instance = ShaderService._();

  ui.FragmentProgram? _lanceProgram;
  ui.FragmentProgram? _flakProgram;
  ui.FragmentProgram? _capacitorProgram;
  ui.FragmentProgram? _atmosphericProgram;

  bool _isInitialized = false;
  bool get isReady => _isInitialized;

  Future<void> initialize() async {
    if (_isInitialized) return;
    try {
      _lanceProgram = await ui.FragmentProgram.fromAsset(
        'shaders/particle_lance.frag',
      );
      _flakProgram = await ui.FragmentProgram.fromAsset(
        'shaders/flak_burst.frag',
      );
      _capacitorProgram = await ui.FragmentProgram.fromAsset(
        'shaders/plasma_capacitor.frag',
      );
      _atmosphericProgram = await ui.FragmentProgram.fromAsset(
        'shaders/atmospheric_siphon.frag',
      );
      _isInitialized = true;
    } catch (e) {
      debugPrint('[ShaderService] Failed to load GLSL shaders: $e');
      _isInitialized = false;
    }
  }

  ui.FragmentShader? createLanceShader() => _lanceProgram?.fragmentShader();
  ui.FragmentShader? createFlakShader() => _flakProgram?.fragmentShader();
  ui.FragmentShader? createCapacitorShader() =>
      _capacitorProgram?.fragmentShader();
  ui.FragmentShader? createAtmosphericShader() =>
      _atmosphericProgram?.fragmentShader();
}
