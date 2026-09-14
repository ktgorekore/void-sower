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

import 'core/logging.dart';
import 'domain/services/game_engine_interface.dart';
import 'domain/services/persistence_service.dart';
import 'engine/ffi_void_sower_engine.dart';
import 'engine/mock_void_sower_engine.dart';
import 'presentation/screens/campaign_map_screen.dart';
import 'presentation/screens/combat_screen.dart';
import 'presentation/services/audio_service.dart';
import 'presentation/services/shader_service.dart';
import 'presentation/theme/void_theme.dart';

/// Optional environment flag to launch directly into combat viewport for testing/recording.
const bool kStartCombat = bool.fromEnvironment(
  'START_COMBAT',
  defaultValue: false,
);

/// Optional environment flag to start tactical AI solver immediately.
const bool kAutoSolve = bool.fromEnvironment('AUTO_SOLVE', defaultValue: false);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kVlogLevel > 0) {
    debugPrint(
      '[VoidSower] Verbose debug mode ENABLED with VLOG_LEVEL=$kVlogLevel',
    );
  }

  await PersistenceService.instance.initialize();
  await AudioService.instance.initialize();
  await ShaderService.instance.initialize();

  IVoidSowerEngine engine;
  try {
    engine = FfiVoidSowerEngine();
  } catch (e) {
    debugPrint(
      '[Main] Native FFI library unavailable ($e), using MockVoidSowerEngine',
    );
    engine = MockVoidSowerEngine();
  }

  runApp(VoidSowerApp(engine: engine));
}

/// Root widget for the Void Sower application.
class VoidSowerApp extends StatelessWidget {
  /// Creates the [VoidSowerApp].
  const VoidSowerApp({super.key, required this.engine});

  final IVoidSowerEngine engine;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Void Sower: Bao Orbital Batteries',
      debugShowCheckedModeBanner: false,
      theme: VoidTheme.darkTheme,
      home: kStartCombat
          ? CombatScreen(engine: engine, autoStartSolver: kAutoSolve)
          : CampaignMapScreen(engine: engine),
    );
  }
}
