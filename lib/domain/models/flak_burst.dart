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

/// State representation of a secondary radial flak explosion.
class FlakBurst {
  const FlakBurst({
    required this.worldPosX,
    required this.worldPosY,
    required this.blastRadius,
    required this.areaDamage,
    required this.lifetime,
    required this.remainingLifetime,
    required this.active,
  });

  final double worldPosX;
  final double worldPosY;
  final double blastRadius;
  final double areaDamage;
  final double lifetime;
  final double remainingLifetime;
  final bool active;
}
