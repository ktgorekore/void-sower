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

/// Dreadnought hull chassis schematic.
class FleetChassis {
  const FleetChassis({
    required this.chassisId,
    required this.name,
    required this.description,
    required this.coreCapacity,
    required this.lanceAlphaBonus,
    required this.isUnlocked,
  });

  final String chassisId;
  final String name;
  final String description;
  final int coreCapacity;
  final double lanceAlphaBonus;
  final bool isUnlocked;
}

/// Service managing unlockable dreadnought chassis variants.
class FleetService {
  FleetService._();
  static final FleetService instance = FleetService._();

  List<FleetChassis> getChassisList() {
    return const [
      FleetChassis(
        chassisId: 'mk1_bastion',
        name: 'MK-I Bastion Standard',
        description:
            'Standard 16-bay orbital dreadnought with balanced capacitor rings.',
        coreCapacity: 32,
        lanceAlphaBonus: 1.0,
        isUnlocked: true,
      ),
      FleetChassis(
        chassisId: 'mk2_monsoon',
        name: 'MK-II Monsoon Vanguard',
        description:
            'Enhanced Nyumba conduits with 15% amplified quadratic lance discharge.',
        coreCapacity: 36,
        lanceAlphaBonus: 1.15,
        isUnlocked: true,
      ),
      FleetChassis(
        chassisId: 'mk3_singularity',
        name: 'MK-III Singularity Sovereign',
        description:
            'Graviton containment core with 30% enhanced cascade flak radius.',
        coreCapacity: 40,
        lanceAlphaBonus: 1.30,
        isUnlocked: false,
      ),
    ];
  }
}
