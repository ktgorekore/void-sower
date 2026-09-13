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

/// State representation of a single dreadnought capacitor bay.
class BayState {
  const BayState({
    required this.bayIndex,
    required this.tier,
    required this.gridColumn,
    required this.chargeUnits,
    required this.radialPositionRad,
    required this.isFrontline,
    required this.isNyumba,
    required this.isKichwa,
    required this.isKimbi,
  });

  final int bayIndex;
  final int tier;
  final int gridColumn;
  final int chargeUnits;
  final double radialPositionRad;
  final bool isFrontline;
  final bool isNyumba;
  final bool isKichwa;
  final bool isKimbi;
}
