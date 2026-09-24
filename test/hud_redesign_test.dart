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
      'HudHeader renders Minimal Orbit layout with Left Wing, Right Wing, and open center corridor',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        bool pauseTapped = false;

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
                onTogglePause: () => pauseTapped = true,
              ),
            ),
          ),
        );

        // Left Wing: Sector badge, SCORE with 6-digit typography, Sector Name
        expect(find.text('S3 • SIEGE'), findsOneWidget);
        expect(find.text('SCORE'), findsOneWidget);
        expect(find.text('001,420'), findsOneWidget);
        expect(find.text('Kipumbwi Trench'), findsOneWidget);
        // Clutter removed: Callsign and HI-SCORE are shifted off live HUD
        expect(find.text('HI-SCORE'), findsNothing);
        expect(find.text('KILIMA_ONE'), findsNothing);

        // Right Wing: Cores fuel gauge (16 CORES), Hostile elimination tracker (2/6), single pause icon
        expect(find.text('16'), findsOneWidget);
        expect(find.text('CORES'), findsOneWidget);
        expect(find.text('2/6'), findsOneWidget);
        expect(find.byIcon(Icons.pause), findsOneWidget);
        expect(find.text('PAUSE'), findsNothing);

        // Meta buttons and AI toggles are cleanly shifted into PauseMenuDialog
        expect(find.text('MAP'), findsNothing);
        expect(find.text('RULES'), findsNothing);
        expect(find.text('SETTINGS'), findsNothing);
        expect(find.text('ABORT'), findsNothing);
        expect(find.text('AI'), findsNothing);
        expect(find.byIcon(Icons.replay), findsNothing);
        expect(find.byIcon(Icons.stop_circle_outlined), findsNothing);

        // Tap PAUSE icon
        await tester.tap(find.byIcon(Icons.pause));
        await tester.pumpAndSettle();
        expect(pauseTapped, isTrue);
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
        expect(find.text('DIRECTIVES'), findsOneWidget);
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

        await tester.tap(find.text('DIRECTIVES'));
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

    testWidgets('HudHeader formats score with 6-digit grouped typography', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
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
      expect(find.text('008,500'), findsOneWidget);
    });

    testWidgets(
      'HudHeader displays AI SIM and UNRANKED when isAiAssisted is true',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: HudHeader(
                reserveCores: 20,
                score: 8500,
                isAiAssisted: true,
                difficultyTier: 2,
                sectorId: 5,
              ),
            ),
          ),
        );

        expect(find.text('AI SIM'), findsOneWidget);
        expect(find.text('UNRANKED'), findsOneWidget);
      },
    );

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
      'HudHeader eliminates callsign and Pro badge clutter during active combat to preserve sightline',
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

        // In HUD 2.0 Minimal Orbit, callsign and pro badge are shifted off live combat viewport
        expect(find.text('COMMANDER_Z'), findsNothing);
        expect(find.text('PRO'), findsNothing);
        expect(find.byIcon(Icons.person), findsNothing);
      },
    );

    testWidgets(
      'HudHeader renders single streamlined pause button while secondary controls reside in PauseMenuDialog',
      (tester) async {
        bool pauseTapped = false;

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
              ),
            ),
          ),
        );

        // Verify single streamlined pause button exists
        expect(find.byIcon(Icons.pause), findsOneWidget);
        // Verify secondary controls (replay, stop) are NOT on the live HUD
        expect(find.byIcon(Icons.replay), findsNothing);
        expect(find.byIcon(Icons.stop_circle_outlined), findsNothing);

        // Verify NO text labels are used on live HUD controls
        expect(find.text('PAUSE'), findsNothing);
        expect(find.text('RESUME'), findsNothing);
        expect(find.text('RESTART'), findsNothing);
        expect(find.text('ABORT'), findsNothing);

        // Tap Pause icon
        await tester.tap(find.byIcon(Icons.pause));
        await tester.pumpAndSettle();
        expect(pauseTapped, isTrue);
      },
    );

    testWidgets(
      'PauseMenuDialog integrates AI Auto-Solve toggle alongside tactical controls',
      (tester) async {
        bool aiTapped = false;
        bool resumeTapped = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: PauseMenuDialog(
                sectorId: 2,
                sectorName: 'Zanzibar Reef Gate',
                difficultyTier: 1,
                score: 2400,
                highScore: 8000,
                isAutoSolving: false,
                onResume: () => resumeTapped = true,
                onRestart: () {},
                onAbort: () {},
                onToggleAutoSolve: () => aiTapped = true,
              ),
            ),
          ),
        );

        // AI tactical assist button is accessible within PauseMenuDialog
        expect(find.text('AI AUTO-SOLVER: STANDBY'), findsOneWidget);
        expect(find.byIcon(Icons.smart_toy), findsOneWidget);

        await tester.tap(find.text('AI AUTO-SOLVER: STANDBY'));
        await tester.pumpAndSettle();
        expect(aiTapped, isTrue);

        await tester.tap(find.byIcon(Icons.play_arrow));
        await tester.pumpAndSettle();
        expect(resumeTapped, isTrue);
      },
    );

    testWidgets(
      'HudHeader horizontally aligns bounding boxes and preserves center corridor sightline',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        // 1. Test during active gameplay
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: HudHeader(
                reserveCores: 25,
                score: 1200,
                highScore: 5000,
                difficultyTier: 0,
                sectorId: 1,
                sectorName: 'Zanzibar Reef Gate',
                userProfile: const UserProfile(callsign: 'VIPER_ONE'),
                totalInvaders: 2,
                invadersRemaining: 2,
                onTogglePause: () {},
              ),
            ),
          ),
        );

        final scoreFinder = find.text('001,200');
        final sectorFinder = find.text('S1 • PATROL');
        expect(scoreFinder, findsOneWidget);
        expect(sectorFinder, findsOneWidget);

        // Verify Left Wing and Right Wing containers have matching heights and top Y during gameplay
        final containers = tester
            .widgetList<Container>(find.byType(Container))
            .where((c) {
              final dec = c.decoration;
              return dec is BoxDecoration &&
                  dec.borderRadius == BorderRadius.circular(10.0);
            })
            .toList();
        expect(containers.length, equals(2));

        final leftWingSize = tester.getSize(find.byWidget(containers[0]));
        final rightWingSize = tester.getSize(find.byWidget(containers[1]));
        final leftWingTop = tester.getTopLeft(find.byWidget(containers[0])).dy;
        final rightWingTop = tester.getTopLeft(find.byWidget(containers[1])).dy;

        expect(
          leftWingTop,
          equals(rightWingTop),
          reason: 'Top edges must be horizontally aligned',
        );
        expect(
          leftWingSize.height,
          equals(rightWingSize.height),
          reason: 'Bounding box heights must match during gameplay',
        );

        // 2. Test after victory / sector secured
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: HudHeader(
                reserveCores: 20,
                score: 1200,
                highScore: 5000,
                difficultyTier: 0,
                sectorId: 1,
                userProfile: const UserProfile(callsign: 'VIPER_ONE'),
                isSecured: true,
                totalInvaders: 2,
                invadersRemaining: 0,
              ),
            ),
          ),
        );

        final securedContainers = tester
            .widgetList<Container>(find.byType(Container))
            .where((c) {
              final dec = c.decoration;
              return dec is BoxDecoration &&
                  dec.borderRadius == BorderRadius.circular(10.0);
            })
            .toList();
        expect(securedContainers.length, equals(2));

        final securedLeftSize = tester.getSize(
          find.byWidget(securedContainers[0]),
        );
        final securedRightSize = tester.getSize(
          find.byWidget(securedContainers[1]),
        );
        final securedLeftTop = tester
            .getTopLeft(find.byWidget(securedContainers[0]))
            .dy;
        final securedRightTop = tester
            .getTopLeft(find.byWidget(securedContainers[1]))
            .dy;

        expect(
          securedLeftTop,
          equals(securedRightTop),
          reason: 'Top edges must align after victory',
        );
        expect(
          securedLeftSize.height,
          equals(securedRightSize.height),
          reason: 'Heights must match after victory',
        );
      },
    );
  });
}
