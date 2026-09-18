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

        // Right Wing: Cores micro-gauge, progress bar label, Hostiles, AI, and icon controls
        expect(find.text('16/50'), findsOneWidget);
        expect(find.text('ENERGY CORES'), findsOneWidget);
        expect(find.text('2/6'), findsOneWidget);
        expect(find.text('AI'), findsOneWidget);
        expect(find.byIcon(Icons.pause), findsOneWidget);
        expect(find.text('PAUSE'), findsNothing);

        // Meta buttons are cleanly shifted off live screen to preserve center sightline
        expect(find.text('MAP'), findsNothing);
        expect(find.text('RULES'), findsNothing);
        expect(find.text('SETTINGS'), findsNothing);
        expect(find.text('ABORT'), findsNothing);

        // Tap PAUSE icon
        await tester.tap(find.byIcon(Icons.pause));
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

        expect(find.byIcon(Icons.play_arrow), findsOneWidget);
        expect(find.byIcon(Icons.replay), findsOneWidget);
        expect(find.byIcon(Icons.stop_circle_outlined), findsOneWidget);
        expect(find.text('RESUME SORTIE'), findsNothing);
        expect(find.text('RESTART'), findsNothing);
        expect(find.text('ABORT'), findsNothing);
        expect(find.text('MAP'), findsOneWidget);
        expect(find.text('RULES'), findsOneWidget);
        expect(find.text('ACADEMY'), findsOneWidget);
        expect(find.text('SYSTEM & AUDIO SETTINGS'), findsOneWidget);

        await tester.tap(find.byIcon(Icons.play_arrow));
        await tester.pumpAndSettle();
        expect(resumeTapped, isTrue);

        await tester.tap(find.byIcon(Icons.replay));
        await tester.pumpAndSettle();
        expect(restartTapped, isTrue);

        await tester.tap(find.byIcon(Icons.stop_circle_outlined));
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

    testWidgets(
      'HudHeader reflects paused state with play arrow icon on pause button',
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
                onTogglePause: () => resumeTapped = true,
              ),
            ),
          ),
        );

        expect(find.byIcon(Icons.play_arrow), findsOneWidget);
        expect(find.text('RESUME'), findsNothing);
        expect(find.text('PAUSE'), findsNothing);

        await tester.tap(find.byIcon(Icons.play_arrow));
        await tester.pumpAndSettle();
        expect(resumeTapped, isTrue);
      },
    );

    testWidgets(
      'HudHeader in secured state displays clean SECURED indicator without pause or button clutter',
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
                onTogglePause: () {},
                onNextSectorTap: () => nextSectorTapped = true,
              ),
            ),
          ),
        );

        expect(find.text('SECURED'), findsOneWidget);
        // Clean HUD: PAUSE and cluttered NEXT buttons are eliminated
        expect(find.text('PAUSE'), findsNothing);
        expect(find.text('NEXT'), findsNothing);

        await tester.tap(find.text('SECURED'));
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

    testWidgets(
      'VictoryDialog is anchored to upper viewport with compact alignment',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: VictoryDialog(
                sectorId: 1,
                score: 4000,
                coresRemaining: 15,
                onNextSector: () {},
              ),
            ),
          ),
        );

        final dialogFinder = find.byType(Dialog);
        expect(dialogFinder, findsOneWidget);
        final dialog = tester.widget<Dialog>(dialogFinder);
        expect(dialog.alignment, const Alignment(0.0, -0.28));
      },
    );

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

    testWidgets(
      'GameOverDialog debounces premature taps during armDuration to prevent accidental clicks while shooting',
      (tester) async {
        bool retried = false;
        bool returnedToMap = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: GameOverDialog(
                score: 800,
                highScore: 2000,
                armDuration: const Duration(milliseconds: 500),
                onRetry: () => retried = true,
                onReturnToMap: () => returnedToMap = true,
              ),
            ),
          ),
        );

        // Immediate taps during desperate shooting cooldown should be ignored
        await tester.tap(find.text('TRY AGAIN'));
        await tester.pump();
        expect(retried, isFalse);

        await tester.tap(find.text('SECTOR MAP'));
        await tester.pump();
        expect(returnedToMap, isFalse);

        // After 500ms safety cooldown, buttons arm and taps succeed
        await tester.pump(const Duration(milliseconds: 500));
        await tester.tap(find.text('TRY AGAIN'));
        await tester.pumpAndSettle();
        expect(retried, isTrue);
      },
    );

    testWidgets(
      'GameOverDialog is anchored to upper viewport to avoid overlapping defender',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: GameOverDialog(
                score: 500,
                highScore: 1000,
                onRetry: () {},
                onReturnToMap: () {},
              ),
            ),
          ),
        );

        final dialogFinder = find.byType(Dialog);
        expect(dialogFinder, findsOneWidget);
        final dialog = tester.widget<Dialog>(dialogFinder);
        expect(dialog.alignment, const Alignment(0.0, -0.32));
      },
    );

    testWidgets(
      'HudHeader displays person icon and PRO badge when isPro is true',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: HudHeader(
                reserveCores: 20,
                score: 1500,
                highScore: 5000,
                isPro: true,
                difficultyTier: 1,
                sectorId: 2,
                userProfile: UserProfile(callsign: 'COMMANDER_Z'),
              ),
            ),
          ),
        );

        expect(find.text('COMMANDER_Z'), findsOneWidget);
        expect(find.byIcon(Icons.person), findsOneWidget);
        expect(find.text('PRO'), findsOneWidget);
      },
    );

    testWidgets(
      'HudHeader displays person icon and no PRO badge when isPro is false',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: HudHeader(
                reserveCores: 20,
                score: 1500,
                highScore: 5000,
                isPro: false,
                difficultyTier: 1,
                sectorId: 2,
                userProfile: UserProfile(callsign: 'RECRUIT_X'),
              ),
            ),
          ),
        );

        expect(find.text('RECRUIT_X'), findsOneWidget);
        expect(find.byIcon(Icons.person), findsOneWidget);
        expect(find.text('PRO'), findsNothing);
      },
    );

    testWidgets(
      'HudHeader renders icon-only simulation controls for pause, restart, and abort with no text',
      (tester) async {
        bool pauseTapped = false;
        bool restartTapped = false;
        bool stopTapped = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: HudHeader(
                reserveCores: 20,
                score: 1500,
                highScore: 5000,
                difficultyTier: 1,
                sectorId: 2,
                totalInvaders: 6,
                invadersRemaining: 3,
                isPaused: false,
                onTogglePause: () => pauseTapped = true,
                onRestartTap: () => restartTapped = true,
                onStopTap: () => stopTapped = true,
              ),
            ),
          ),
        );

        // Verify icon-only simulation controls exist
        expect(find.byIcon(Icons.pause), findsOneWidget);
        expect(find.byIcon(Icons.replay), findsOneWidget);
        expect(find.byIcon(Icons.stop_circle_outlined), findsOneWidget);

        // Verify NO text labels are used for simulation controls
        expect(find.text('PAUSE'), findsNothing);
        expect(find.text('RESUME'), findsNothing);
        expect(find.text('RESTART'), findsNothing);
        expect(find.text('ABORT'), findsNothing);

        // Tap Pause icon
        await tester.tap(find.byIcon(Icons.pause));
        await tester.pumpAndSettle();
        expect(pauseTapped, isTrue);

        // Tap Restart icon
        await tester.tap(find.byIcon(Icons.replay));
        await tester.pumpAndSettle();
        expect(restartTapped, isTrue);

        // Tap Stop/Abort icon
        await tester.tap(find.byIcon(Icons.stop_circle_outlined));
        await tester.pumpAndSettle();
        expect(stopTapped, isTrue);
      },
    );
  });
}
