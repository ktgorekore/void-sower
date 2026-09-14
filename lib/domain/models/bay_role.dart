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

/// Categorizes the topological and tactical roles of individual capacitor bays
/// in the 16-bay Bao la Kiswahili dreadnought ring buffer.
enum BayRole {
  /// Inner reservoir bays (Bays 0..2, 5..7): Mass accumulation bank.
  standardInner,

  /// Frontline battery bays (Bays 10..13): Direct corridor alignment.
  standardFrontline,

  /// Super-Capacitor / House (Bays 3 & 4): High-capacity energy well.
  nyumbaSuperCapacitor,

  /// Vector Conduit / Head (Bays 8 & 15): Outer ring apex emitters.
  kichwaVectorConduit,

  /// Flank Deflection Chamber (Bays 9 & 14): Lateral beam steering.
  kimbiDeflectionChamber;

  /// Resolves the topological role for a given bay index (0..15).
  static BayRole fromIndex(int bayIndex) {
    if (bayIndex == 3 || bayIndex == 4) {
      return BayRole.nyumbaSuperCapacitor;
    }
    if (bayIndex == 8 || bayIndex == 15) {
      return BayRole.kichwaVectorConduit;
    }
    if (bayIndex == 9 || bayIndex == 14) {
      return BayRole.kimbiDeflectionChamber;
    }
    return bayIndex >= 8 ? BayRole.standardFrontline : BayRole.standardInner;
  }

  /// Whether this bay is capable of direct frontline cross-discharge into an attack corridor.
  bool get isFrontline =>
      this == BayRole.standardFrontline ||
      this == BayRole.kichwaVectorConduit ||
      this == BayRole.kimbiDeflectionChamber;
}
