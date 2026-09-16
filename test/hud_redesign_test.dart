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
import 'package:flutter_test/flutter_test.dart';
import 'package:void_sower/domain/models/user_profile.dart';
import 'package:void_sower/presentation/widgets/hud_header.dart';
import 'package:void_sower/presentation/widgets/victory_dialog.dart';

void main() {
  group('Top HUD Redesign & Universal Controls Tests', () {
    testWidgets(
      'HudHeader renders 3 tiers and all telemetry elements cleanly',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        bool settingsTapped = false;
        bool mapTapped = false;
        bool pauseTapped = false;
        bool restartTapped = false;
        bool abortTapped = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: HudHeader(
                reserveCores: 16,
                score: 1420,
                difficultyTier: 1,
                sectorId: 3,
                sectorName: 'Kipumbwi Trench',
                userProfile: const UserProfile(callsign: 'KILIMA_ONE'),
                totalInvaders: 6,
                invadersRemaining: 4,
                isPaused: false,
                onSettingsTap: () => settingsTapped = true,
                onMapTap: () => mapTapped = true,
                onTogglePause: () => pauseTapped = true,
                onRestartTap: () => restartTapped = true,
                onStopTap: () => abortTapped = true,
              ),
            ),
          ),
        );

        // Bar 1 elements: MAP, S3 • SIEGE, SETTINGS
        expect(find.text('MAP'), findsOneWidget);
        expect(find.text('S3 • SIEGE'), findsOneWidget);
        final settingsFinder = find.byIcon(Icons.settings);
        expect(settingsFinder, findsOneWidget);
        final settingsIcon = tester.widget<Icon>(settingsFinder);
        expect(settingsIcon.size, 18.0);

        // Bar 2 elements: Callsign, Score, Cores, Hostiles
        expect(find.text('KILIMA_ONE'), findsOneWidget);
        expect(find.text('1420'), findsOneWidget);
        expect(find.text('16 CORES'), findsOneWidget);
        expect(find.text('2/6 HOSTILES'), findsOneWidget);

        // Bar 3 elements: SORTIE ACTIVE, PAUSE, RESTART, ABORT
        expect(find.text('SORTIE ACTIVE'), findsOneWidget);
        expect(find.text('PAUSE'), findsOneWidget);
        expect(find.text('RESTART'), findsOneWidget);
        expect(find.text('ABORT'), findsOneWidget);

        // Test taps
        await tester.tap(settingsFinder);
        await tester.pumpAndSettle();
        expect(settingsTapped, isTrue);

        await tester.tap(find.text('MAP'));
        await tester.pumpAndSettle();
        expect(mapTapped, isTrue);

        await tester.tap(find.text('PAUSE'));
        await tester.pumpAndSettle();
        expect(pauseTapped, isTrue);

        await tester.tap(find.text('RESTART'));
        await tester.pumpAndSettle();
        expect(restartTapped, isTrue);

        await tester.tap(find.text('ABORT'));
        await tester.pumpAndSettle();
        expect(abortTapped, isTrue);
      },
    );

    testWidgets(
      'HudHeader reflects paused state with TIME DILATED and RESUME',
      (tester) async {
        bool resumeTapped = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: HudHeader(
                reserveCores: 8,
                score: 500,
                difficultyTier: 0,
                isPaused: true,
                onSettingsTap: () {},
                onTogglePause: () => resumeTapped = true,
              ),
            ),
          ),
        );

        expect(find.text('TIME DILATED'), findsOneWidget);
        expect(find.text('RESUME'), findsOneWidget);

        await tester.tap(find.text('RESUME'));
        await tester.pumpAndSettle();
        expect(resumeTapped, isTrue);
      },
    );

    testWidgets(
      'HudHeader in secured state offers NEXT SECTOR and REPLAY actions',
      (tester) async {
        bool nextSectorTapped = false;
        bool replayTapped = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: HudHeader(
                reserveCores: 12,
                score: 2800,
                difficultyTier: 0,
                sectorId: 1,
                isSecured: true,
                invadersRemaining: 0,
                totalInvaders: 4,
                onSettingsTap: () {},
                onNextSectorTap: () => nextSectorTapped = true,
                onRestartTap: () => replayTapped = true,
              ),
            ),
          ),
        );

        expect(find.text('SECTOR SECURED'), findsOneWidget);
        expect(find.text('SECURED'), findsOneWidget);
        expect(find.text('NEXT SECTOR'), findsOneWidget);
        expect(find.text('REPLAY'), findsOneWidget);

        await tester.tap(find.text('NEXT SECTOR'));
        await tester.pumpAndSettle();
        expect(nextSectorTapped, isTrue);

        await tester.tap(find.text('REPLAY'));
        await tester.pumpAndSettle();
        expect(replayTapped, isTrue);
      },
    );

    testWidgets('VictoryDialog close button triggers onDismiss', (
      tester,
    ) async {
      bool dismissed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VictoryDialog(
              sectorId: 1,
              score: 3000,
              coresRemaining: 14,
              onNextSector: () {},
              onDismiss: () => dismissed = true,
            ),
          ),
        ),
      );

      expect(find.text('SECTOR 1 LIBERATED!'), findsOneWidget);
      final closeFinder = find.byIcon(Icons.close);
      expect(closeFinder, findsOneWidget);

      await tester.tap(closeFinder);
      await tester.pumpAndSettle();
      expect(dismissed, isTrue);
    });
  });
}
