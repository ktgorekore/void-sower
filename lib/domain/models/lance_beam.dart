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

/// State representation of an active axial particle lance discharge.
class LanceBeam {
  const LanceBeam({
    required this.firingBayIndex,
    required this.originX,
    required this.originY,
    required this.beamWidth,
    required this.sustainedDuration,
    required this.remainingDuration,
    required this.totalDamage,
    required this.active,
  });

  final int firingBayIndex;
  final double originX;
  final double originY;
  final double beamWidth;
  final double sustainedDuration;
  final double remainingDuration;
  final double totalDamage;
  final bool active;
}
