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

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:void_sower/domain/services/daily_sortie_service.dart';
import 'package:void_sower/domain/services/persistence_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Daily Galactic Sortie Service Tests', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await PersistenceService.instance.resetForTesting();
    });

    test(
      'Generates deterministic daily sector parameters based on UTC date',
      () {
        final service = DailySortieService.instance;
        final sector = service.getTodaySector();

        expect(sector.sectorId, equals(8888));
        expect(sector.campaignId, equals('daily_sortie'));
        expect(sector.name, startsWith('DAILY SORTIE:'));
        expect(sector.isUnlocked, isTrue);
        expect(service.todayModifierTitle, isNotEmpty);
        expect(service.todayModifierDescription, isNotEmpty);
      },
    );

    test('Records and persists daily high score correctly', () async {
      final service = DailySortieService.instance;
      expect(service.todayBestScore, equals(0));

      await service.recordTodayScore(45000);
      expect(service.todayBestScore, equals(45000));

      // Lower score does not overwrite
      await service.recordTodayScore(30000);
      expect(service.todayBestScore, equals(45000));

      // Higher score updates
      await service.recordTodayScore(62000);
      expect(service.todayBestScore, equals(62000));
    });
  });
}
