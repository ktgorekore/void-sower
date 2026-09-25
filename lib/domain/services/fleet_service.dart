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

import '../models/pro_feature.dart';
import 'ad_service.dart';
import 'entitlement_service.dart';

/// Dreadnought hull chassis schematic.
class FleetChassis {
  const FleetChassis({
    required this.chassisId,
    required this.name,
    required this.description,
    required this.coreCapacity,
    required this.lanceAlphaBonus,
    required this.isUnlocked,
    this.unlockRequirement = '',
  });

  final String chassisId;
  final String name;
  final String description;
  final int coreCapacity;
  final double lanceAlphaBonus;
  final bool isUnlocked;
  final String unlockRequirement;
}

/// Service managing unlockable dreadnought chassis variants, progression unlocks,
/// and temporary rewarded rental passes.
class FleetService {
  FleetService._();
  static final FleetService instance = FleetService._();

  final Set<String> _temporaryRentals = <String>{};

  /// Checks whether a given dreadnought chassis variant is currently unlocked.
  bool isChassisUnlocked(String chassisId) {
    if (chassisId == 'mk1_bastion' || chassisId == 'mk2_monsoon') return true;
    if (_temporaryRentals.contains(chassisId)) return true;

    if (chassisId == 'mk3_singularity') {
      return EntitlementService.instance.isFeatureAccessible(
        ProFeature.mk3SingularityChassis,
      );
    }

    if (chassisId == 'mk4_golden_sovereign') {
      return EntitlementService.instance.isFeatureAccessible(
        ProFeature.goldenSovereignSkin,
      );
    }

    return false;
  }

  /// Grants a temporary chassis rental pass for the current session.
  void grantTemporaryRental(String chassisId) {
    _temporaryRentals.add(chassisId);
  }

  /// Initiates a rewarded transmission ad to rent a locked chassis.
  Future<bool> rentWithRewardedAd(String chassisId) async {
    final success = await AdService.instance.showRewardedAd();
    if (success) {
      grantTemporaryRental(chassisId);
      return true;
    }
    return false;
  }

  /// Clears active temporary rentals (for testing).
  void resetRentalsForTesting() {
    _temporaryRentals.clear();
  }

  /// Returns the full list of dreadnought chassis schematics with real-time unlock status.
  List<FleetChassis> getChassisList() {
    return [
      FleetChassis(
        chassisId: 'mk1_bastion',
        name: 'MK-I Bastion Standard',
        description:
            'Standard 16-bay orbital dreadnought with balanced capacitor rings.',
        coreCapacity: 32,
        lanceAlphaBonus: 1.0,
        isUnlocked: isChassisUnlocked('mk1_bastion'),
        unlockRequirement: 'Standard issue flagship.',
      ),
      FleetChassis(
        chassisId: 'mk2_monsoon',
        name: 'MK-II Monsoon Vanguard',
        description:
            'Enhanced Nyumba conduits with 15% amplified quadratic lance discharge.',
        coreCapacity: 36,
        lanceAlphaBonus: 1.15,
        isUnlocked: isChassisUnlocked('mk2_monsoon'),
        unlockRequirement: 'Liberate Sector 2 to unlock.',
      ),
      FleetChassis(
        chassisId: 'mk3_singularity',
        name: 'MK-III Singularity Sovereign',
        description:
            'Graviton containment core with 40 cores and +30% quadratic lance alpha.',
        coreCapacity: 40,
        lanceAlphaBonus: 1.30,
        isUnlocked: isChassisUnlocked('mk3_singularity'),
        unlockRequirement: 'Pro Commander Exclusive / Ad Rental Pass.',
      ),
      FleetChassis(
        chassisId: 'mk4_golden_sovereign',
        name: 'MK-IV Golden Sovereign',
        description:
            'Gilded solar lattice flagship with 44 cores, +40% lance alpha, and radiant antimatter trails.',
        coreCapacity: 44,
        lanceAlphaBonus: 1.40,
        isUnlocked: isChassisUnlocked('mk4_golden_sovereign'),
        unlockRequirement: 'Pro Commander Exclusive / Ad Rental Pass.',
      ),
    ];
  }

  /// Retrieves a specific chassis by ID, falling back to MK-I Bastion if not found.
  FleetChassis getChassis(String chassisId) {
    final list = getChassisList();
    for (final c in list) {
      if (c.chassisId == chassisId) return c;
    }
    return list.first;
  }
}
