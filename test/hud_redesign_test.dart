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
import 'package:void_sower/presentation/widgets/game_over_dialog.dart';
import 'package:void_sower/presentation/widgets/hud_header.dart';
import 'package:void_sower/presentation/widgets/pause_menu_dialog.dart';
import 'package:void_sower/presentation/widgets/victory_dialog.dart';

void main() {
  group('Split-Wing Tactical HUD & Pause Menu Tests', () {
    testWidgets(
      'HudHeader renders Split-Wing layout with Left Wing, Right Wing, and open center',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        bool pauseTapped = false;
        bool aiTapped = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: HudHeader(
                reserveCores: 16,
                score: 1420,
                highScore: 5000,
                difficultyTier: 1,
                sectorId: 3,
                sectorName: 'Kipumbwi Trench',
                userProfile: const UserProfile(callsign: 'KILIMA_ONE'),
                totalInvaders: 6,
                invadersRemaining: 4,
                isPaused: false,
                isAutoSolving: false,
                onTogglePause: () => pauseTapped = true,
                onToggleAutoSolve: () => aiTapped = true,
              ),
            ),
          ),
        );

        // Left Wing: Mission badge, SCORE & HI-SCORE with 6-digit typography, Callsign
        expect(find.text('S3 • SIEGE'), findsOneWidget);
        expect(find.text('SCORE'), findsOneWidget);
        expect(find.text('001,420'), findsOneWidget);
        expect(find.text('HI-SCORE'), findsOneWidget);
        expect(find.text('005,000'), findsOneWidget);
        expect(find.text('KILIMA_ONE'), findsOneWidget);

        // Right Wing: Cores micro-gauge, progress bar label, Hostiles, AI, PAUSE
        expect(find.text('16/50'), findsOneWidget);
        expect(find.text('ENERGY CORES'), findsOneWidget);
        expect(find.text('2/6'), findsOneWidget);
        expect(find.text('AI'), findsOneWidget);
        expect(find.text('PAUSE'), findsOneWidget);

        // Meta buttons are cleanly shifted off live screen to preserve center sightline
        expect(find.text('MAP'), findsNothing);
        expect(find.text('RULES'), findsNothing);
        expect(find.text('SETTINGS'), findsNothing);
        expect(find.text('ABORT'), findsNothing);

        // Tap PAUSE
        await tester.tap(find.text('PAUSE'));
        await tester.pumpAndSettle();
        expect(pauseTapped, isTrue);

        // Tap AI
        await tester.tap(find.text('AI'));
        await tester.pumpAndSettle();
        expect(aiTapped, isTrue);
      },
    );

    testWidgets(
      'PauseMenuDialog presents stacked simulation actions, campaign navigation, and settings',
      (tester) async {
        bool resumeTapped = false;
        bool restartTapped = false;
        bool abortTapped = false;
        bool mapTapped = false;
        bool codexTapped = false;
        bool academyTapped = false;
        bool settingsTapped = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: PauseMenuDialog(
                sectorId: 3,
                sectorName: 'Kipumbwi Trench',
                difficultyTier: 1,
                score: 1420,
                highScore: 5000,
                onResume: () => resumeTapped = true,
                onRestart: () => restartTapped = true,
                onAbort: () => abortTapped = true,
                onMap: () => mapTapped = true,
                onCodex: () => codexTapped = true,
                onAcademy: () => academyTapped = true,
                onSettings: () => settingsTapped = true,
              ),
            ),
          ),
        );

        expect(find.text('TACTICAL PAUSE'), findsOneWidget);
        expect(find.text('SECTOR 3 • Kipumbwi Trench • SIEGE'), findsOneWidget);
        expect(find.text('CURRENT SORTIE SCORE'), findsOneWidget);
        expect(find.text('1420'), findsOneWidget);
        expect(find.text('ALL-TIME HIGH SCORE'), findsOneWidget);
        expect(find.text('5000'), findsOneWidget);

        expect(find.text('RESUME SORTIE'), findsOneWidget);
        expect(find.text('RESTART'), findsOneWidget);
        expect(find.text('ABORT'), findsOneWidget);
        expect(find.text('MAP'), findsOneWidget);
        expect(find.text('RULES'), findsOneWidget);
        expect(find.text('ACADEMY'), findsOneWidget);
        expect(find.text('SYSTEM & AUDIO SETTINGS'), findsOneWidget);

        await tester.tap(find.text('RESUME SORTIE'));
        await tester.pumpAndSettle();
        expect(resumeTapped, isTrue);

        await tester.tap(find.text('RESTART'));
        await tester.pumpAndSettle();
        expect(restartTapped, isTrue);

        await tester.tap(find.text('ABORT'));
        await tester.pumpAndSettle();
        expect(abortTapped, isTrue);

        await tester.tap(find.text('MAP'));
        await tester.pumpAndSettle();
        expect(mapTapped, isTrue);

        await tester.tap(find.text('RULES'));
        await tester.pumpAndSettle();
        expect(codexTapped, isTrue);

        await tester.tap(find.text('ACADEMY'));
        await tester.pumpAndSettle();
        expect(academyTapped, isTrue);

        await tester.tap(find.text('SYSTEM & AUDIO SETTINGS'));
        await tester.pumpAndSettle();
        expect(settingsTapped, isTrue);
      },
    );

    testWidgets('HudHeader reflects paused state with RESUME on pause button', (
      tester,
    ) async {
      bool resumeTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HudHeader(
              reserveCores: 8,
              score: 500,
              difficultyTier: 0,
              isPaused: true,
              onTogglePause: () => resumeTapped = true,
            ),
          ),
        ),
      );

      expect(find.text('RESUME'), findsOneWidget);

      await tester.tap(find.text('RESUME'));
      await tester.pumpAndSettle();
      expect(resumeTapped, isTrue);
    });

    testWidgets(
      'HudHeader in secured state offers NEXT action and SECURED indicator',
      (tester) async {
        bool nextSectorTapped = false;

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
                onNextSectorTap: () => nextSectorTapped = true,
              ),
            ),
          ),
        );

        expect(find.text('SECURED'), findsOneWidget);
        expect(find.text('NEXT'), findsOneWidget);

        await tester.tap(find.text('NEXT'));
        await tester.pumpAndSettle();
        expect(nextSectorTapped, isTrue);
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

    testWidgets('HudHeader reflects new record when score exceeds highScore', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HudHeader(
              reserveCores: 20,
              score: 8500,
              highScore: 4000,
              difficultyTier: 2,
              sectorId: 5,
            ),
          ),
        ),
      );

      expect(find.text('SCORE'), findsOneWidget);
      // Both score and effective high score show 008,500
      expect(find.text('008,500'), findsNWidgets(2));
      expect(find.text('HI-SCORE ★'), findsOneWidget);
    });

    testWidgets(
      'VictoryDialog displays mission score, high score, and cores saved',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: VictoryDialog(
                sectorId: 2,
                sectorName: 'Pemba Shoals',
                score: 5200,
                highScore: 3000,
                coresRemaining: 18,
                onNextSector: () {},
              ),
            ),
          ),
        );

        expect(find.text('MISSION SCORE'), findsOneWidget);
        expect(
          find.text('5200'),
          findsNWidgets(2),
        ); // Mission score & new high score
        expect(find.text('★ NEW RECORD'), findsOneWidget);
        expect(find.text('CORES SAVED'), findsOneWidget);
        expect(find.text('18'), findsOneWidget);
      },
    );

    testWidgets('GameOverDialog displays final score and all-time high score', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GameOverDialog(
              score: 1200,
              highScore: 6000,
              onRetry: () {},
              onReturnToMap: () {},
            ),
          ),
        ),
      );

      expect(find.text('FINAL SCORE: 1200'), findsOneWidget);
      expect(find.text('ALL-TIME HIGH SCORE: 6000'), findsOneWidget);
    });
  });
}
