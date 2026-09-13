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

import 'package:flutter/services.dart';

/// Tactile haptics service synchronized with combat cadence and sowing traversals.
class HapticService {
  HapticService._();
  static final HapticService instance = HapticService._();

  bool isEnabled = true;

  /// Lightweight micro-tick tracing the step-by-step circular sowing cadence.
  Future<void> sowTick() async {
    if (!isEnabled) return;
    await HapticFeedback.selectionClick();
  }

  /// Upward flick confirmation when injecting a core into a bay (namua).
  Future<void> injectionClick() async {
    if (!isEnabled) return;
    await HapticFeedback.lightImpact();
  }

  /// Heavy resonant transient upon high-mass particle lance cross-discharge.
  Future<void> lanceDischarge() async {
    if (!isEnabled) return;
    await HapticFeedback.heavyImpact();
  }

  /// Medium pulse upon secondary radial flak explosion.
  Future<void> flakBurst() async {
    if (!isEnabled) return;
    await HapticFeedback.mediumImpact();
  }
}
