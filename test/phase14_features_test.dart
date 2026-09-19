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

import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_platform_interface/in_app_purchase_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:void_sower/config/ad_config.dart';
import 'package:void_sower/domain/models/user_profile.dart';
import 'package:void_sower/domain/services/ad_service.dart';
import 'package:void_sower/domain/services/iap_service.dart';
import 'package:void_sower/domain/services/persistence_service.dart';
import 'package:void_sower/presentation/services/audio_service.dart';
import 'package:void_sower/presentation/widgets/consent_preferences_dialog.dart';
import 'package:void_sower/presentation/widgets/legal_dialogs.dart';
import 'package:void_sower/presentation/widgets/profile_modal.dart';
import 'package:void_sower/presentation/widgets/rewarded_ad_modal.dart';
import 'package:void_sower/presentation/widgets/settings_modal.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await PersistenceService.instance.initialize();
  });

  group('Phase 14: UserProfile Model Tests', () {
    test('Calculates ranks correctly based on score thresholds', () {
      expect(PilotRank.fromScore(0), PilotRank.cadet);
      expect(PilotRank.fromScore(999), PilotRank.cadet);
      expect(PilotRank.fromScore(1000), PilotRank.ensign);
      expect(PilotRank.fromScore(4999), PilotRank.ensign);
      expect(PilotRank.fromScore(5000), PilotRank.lieutenant);
      expect(PilotRank.fromScore(14999), PilotRank.lieutenant);
      expect(PilotRank.fromScore(15000), PilotRank.commander);
      expect(PilotRank.fromScore(29999), PilotRank.commander);
      expect(PilotRank.fromScore(30000), PilotRank.admiral);
      expect(PilotRank.fromScore(49999), PilotRank.admiral);
      expect(PilotRank.fromScore(50000), PilotRank.voidAscendant);
      expect(PilotRank.fromScore(100000), PilotRank.voidAscendant);
    });

    test('Serializes to JSON and deserializes correctly', () {
      const profile = UserProfile(
        callsign: 'Apex-99',
        insignia: PilotInsignia.shonaStar,
        lifetimeScore: 12500,
        enemiesDestroyed: 45,
        lancesFired: 88,
        maxCascadeLaps: 3,
        unlockedAchievements: ['first_blood', 'grand_cascade'],
      );

      final json = profile.toJson();
      final restored = UserProfile.fromJson(json);

      expect(restored.callsign, 'Apex-99');
      expect(restored.insignia, PilotInsignia.shonaStar);
      expect(restored.lifetimeScore, 12500);
      expect(restored.rank, PilotRank.lieutenant);
      expect(restored.enemiesDestroyed, 45);
      expect(restored.lancesFired, 88);
      expect(restored.maxCascadeLaps, 3);
      expect(restored.unlockedAchievements, ['first_blood', 'grand_cascade']);
    });
  });

  group('Phase 14: PersistenceService Mobility & Settings Tests', () {
    test(
      'Persists and exports/imports save data with checksum verification',
      () async {
        final p = PersistenceService.instance;
        await p.setHighScore(42000);
        await p.setLiberatedSectors(5);
        await p.setProUnlocked(true);
        await p.setSfxVolume(0.75);
        await p.setBgmVolume(0.55);

        const testProfile = UserProfile(
          callsign: 'Titan-07',
          insignia: PilotInsignia.zuluAegis,
          lifetimeScore: 42000,
        );
        await p.saveUserProfile(testProfile);

        final exported = p.exportSaveJson();
        expect(exported, isNotEmpty);

        // Wipe current data
        await p.wipeAllData();
        expect(p.highScore, 0);
        expect(p.userProfile.callsign, 'Vanguard-01');

        // Import back
        final success = await p.importSaveJson(exported);
        expect(success, isTrue);
        expect(p.highScore, 42000);
        expect(p.liberatedSectors, 5);
        expect(p.isProUnlocked, isTrue);
        expect(p.userProfile.callsign, 'Titan-07');
        expect(p.userProfile.insignia, PilotInsignia.zuluAegis);
      },
    );

    test('Rejects corrupted or tampered save payloads', () async {
      final p = PersistenceService.instance;
      final invalidPayload = 'eyJzY2hlbWEiOiAiaW52YWxpZCJ9'; // Invalid schema
      final success = await p.importSaveJson(invalidPayload);
      expect(success, isFalse);

      final nonBase64 = '!!!NotBase64String!!!';
      final failure = await p.importSaveJson(nonBase64);
      expect(failure, isFalse);
    });
  });

  group('Phase 14: AudioService Volume & Muting Tests', () {
    test('Updates volume and mute channels independently', () async {
      final audio = AudioService.instance;
      await audio.setSfxVolume(0.5);
      expect(audio.sfxVolume, 0.5);

      await audio.setBgmVolume(0.3);
      expect(audio.bgmVolume, 0.3);

      await audio.setSfxMuted(true);
      expect(audio.isSfxMuted, isTrue);
      expect(audio.isMuted, isTrue);

      await audio.setBgmMuted(true);
      expect(audio.isBgmMuted, isTrue);

      await audio.setSfxMuted(false);
      expect(audio.isSfxMuted, isFalse);
    });

    test(
      'Configures exclusive audio focus with AndroidAudioFocus.gain and iOS soloAmbient',
      () {
        final ctx = AudioService.gameAudioContext;

        // Android verification: requests exclusive focus with game usage & music content
        expect(ctx.android.audioFocus, equals(AndroidAudioFocus.gain));
        expect(ctx.android.usageType, equals(AndroidUsageType.game));
        expect(ctx.android.contentType, equals(AndroidContentType.music));
        expect(ctx.android.isSpeakerphoneOn, isFalse);
        expect(ctx.android.stayAwake, isFalse);

        // iOS verification: soloAmbient category without mixing/ducking options
        expect(ctx.iOS.category, equals(AVAudioSessionCategory.soloAmbient));
        expect(ctx.iOS.options, isEmpty);
      },
    );

    test('Requests exclusive audio focus and initializes gracefully', () async {
      final audio = AudioService.instance;
      await audio.initialize();
      await audio.requestExclusiveAudioFocus();
      expect(
        AudioService.gameAudioContext.android.audioFocus,
        equals(AndroidAudioFocus.gain),
      );
    });
  });

  group('Phase 14: Monetization Tests', () {
    test('AdConfig test constants are defined', () {
      expect(AdConfig.androidRewardedTestId, isNotEmpty);
      expect(AdConfig.iosRewardedTestId, isNotEmpty);
      expect(AdConfig.rewardedCooldown.inMinutes, 3);
      expect(AdConfig.emergencyCoresReward, 8);
    });

    test('AdService grants instant bypass for Pro commanders', () async {
      final p = PersistenceService.instance;
      await p.setProUnlocked(true);

      final adService = AdService.instance;
      final rewarded = await adService.showRewardedAd();
      expect(rewarded, isTrue);
    });

    test('IapService purchases and restores Pro Lifetime', () async {
      final fakeIap = _FakeInAppPurchase();
      final iap = IapService.instance;
      iap.setIapForTesting(fakeIap);
      await iap.initialize();

      final p = PersistenceService.instance;
      await p.setProUnlocked(false);
      expect(p.isProUnlocked, isFalse);

      final purchaseFuture = iap.purchaseProLifetime();
      fakeIap.emitPurchase(
        PurchaseDetails(
          purchaseID: 'tx_001',
          productID: IapService.kProLifetimeSku,
          verificationData: PurchaseVerificationData(
            localVerificationData: 'test',
            serverVerificationData: 'test',
            source: 'test',
          ),
          transactionDate: '2026-09-14',
          status: PurchaseStatus.purchased,
        ),
      );

      final outcome = await purchaseFuture;
      expect(outcome.isSuccess, isTrue);
      expect(p.isProUnlocked, isTrue);

      await p.setProUnlocked(false);
      await iap.restorePurchases();
      // Allow stream event to process
      await Future<void>.delayed(Duration.zero);
      expect(p.isProUnlocked, isTrue);

      fakeIap.dispose();
      await iap.resetForTesting();
    });
  });

  group('Phase 14: Widget Presentation Tests', () {
    testWidgets('SettingsModal renders all 4 category tabs', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: SettingsModal())),
      );
      await tester.pumpAndSettle();

      expect(find.text('FLEET SYSTEM CONFIG'), findsOneWidget);
      expect(find.text('AUDIO & HAPTICS'), findsOneWidget);
      expect(find.text('GRAPHICS'), findsOneWidget);
      expect(find.text('DIAGNOSTICS'), findsOneWidget);
      expect(find.text('LEGAL & ABOUT'), findsOneWidget);
    });

    testWidgets(
      'SettingsModal renders FLIGHT ACADEMY button when onLaunchAcademy is provided',
      (tester) async {
        bool academyLaunched = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SettingsModal(
                onLaunchAcademy: () => academyLaunched = true,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Switch to DIAGNOSTICS tab
        await tester.tap(find.text('DIAGNOSTICS'));
        await tester.pumpAndSettle();

        expect(find.text('FLIGHT ACADEMY'), findsOneWidget);
        expect(find.text('RESET FLIGHT ACADEMY TUTORIAL'), findsOneWidget);

        await tester.tap(find.text('FLIGHT ACADEMY'));
        await tester.pumpAndSettle();

        expect(academyLaunched, isTrue);
      },
    );

    testWidgets('ProfileModal renders pilot dossier and insignia selector', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: ProfileModal())),
      );
      await tester.pumpAndSettle();

      expect(find.text('PILOT FLIGHT DOSSIER'), findsOneWidget);
      expect(find.text('PILOT CLOUD ACCOUNT'), findsOneWidget);
      expect(find.text('SQUADRON ROSTER (PROFILES)'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('SQUADRON CULTURAL INSIGNIA'),
        150.0,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('SQUADRON CULTURAL INSIGNIA'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('LIFETIME COMBAT TELEMETRY'),
        150.0,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('LIFETIME COMBAT TELEMETRY'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('EXPORT SAVE'),
        150.0,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('EXPORT SAVE'), findsOneWidget);
      expect(find.text('IMPORT SAVE'), findsOneWidget);
    });

    testWidgets('LegalDialogs render privacy policy and terms', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: PrivacyPolicyDialog())),
      );
      await tester.pumpAndSettle();

      expect(find.text('PRIVACY POLICY'), findsOneWidget);
      expect(find.text('ACKNOWLEDGE'), findsOneWidget);

      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: TermsOfServiceDialog())),
      );
      await tester.pumpAndSettle();

      expect(find.text('TERMS OF SERVICE'), findsOneWidget);
      expect(find.text('AGREE & CLOSE'), findsOneWidget);
    });

    testWidgets('ConsentPreferencesDialog renders GDPR controls', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: ConsentPreferencesDialog())),
      );
      await tester.pumpAndSettle();

      expect(find.text('CONSENT PREFERENCES'), findsOneWidget);
      expect(find.text('Personalized Advertising'), findsOneWidget);
      expect(find.text('Anonymous Crash Telemetry'), findsOneWidget);
      expect(find.text('DATA ERASURE (GDPR / CCPA)'), findsOneWidget);
    });

    testWidgets(
      'RewardedAdModal displays emergency flare prompt and awards cores',
      (tester) async {
        AdService.instance.resetCooldownForTesting();
        await PersistenceService.instance.setProUnlocked(false);
        int awarded = 0;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: RewardedAdModal(onCoresGranted: (cores) => awarded = cores),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('CRITICAL REACTOR DEPLETION'), findsOneWidget);
        expect(find.text('Emergency Orbital Flare Available'), findsOneWidget);

        await tester.tap(find.text('CHANNEL (+8)'));
        await tester.pumpAndSettle();

        expect(awarded, 8);
      },
    );
  });
}

class _FakeInAppPurchase implements InAppPurchase {
  final StreamController<List<PurchaseDetails>> _controller =
      StreamController<List<PurchaseDetails>>.broadcast();

  @override
  Stream<List<PurchaseDetails>> get purchaseStream => _controller.stream;

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<ProductDetailsResponse> queryProductDetails(
    Set<String> identifiers,
  ) async {
    return ProductDetailsResponse(
      productDetails: [
        ProductDetails(
          id: IapService.kProLifetimeSku,
          title: 'Pro Lifetime',
          description: 'Unlock all Pro features permanently',
          price: r'$1.29',
          rawPrice: 1.29,
          currencyCode: 'USD',
        ),
      ],
      notFoundIDs: const [],
    );
  }

  @override
  Future<bool> buyNonConsumable({required PurchaseParam purchaseParam}) async =>
      true;

  @override
  Future<bool> buyConsumable({
    required PurchaseParam purchaseParam,
    bool autoConsume = true,
  }) async => false;

  @override
  Future<void> completePurchase(PurchaseDetails purchase) async {}

  @override
  Future<void> restorePurchases({String? applicationUserName}) async {
    _controller.add([
      PurchaseDetails(
        purchaseID: 'restore_tx',
        productID: IapService.kProLifetimeSku,
        verificationData: PurchaseVerificationData(
          localVerificationData: 'test',
          serverVerificationData: 'test',
          source: 'test',
        ),
        transactionDate: '2026-09-14',
        status: PurchaseStatus.restored,
      ),
    ]);
  }

  @override
  Future<String> countryCode() async => 'US';

  @override
  T getPlatformAddition<T extends InAppPurchasePlatformAddition?>() {
    throw UnimplementedError();
  }

  void emitPurchase(PurchaseDetails purchase) {
    _controller.add([purchase]);
  }

  void dispose() {
    _controller.close();
  }
}
