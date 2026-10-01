import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:mass_lens/app/app_controller.dart';
import 'package:mass_lens/app/mass_lens_app.dart';
import 'package:mass_lens/features/measurements/data/measurement_store.dart';
import 'package:mass_lens/features/monetization/application/monetization_controller.dart';
import 'package:mass_lens/features/monetization/data/app_ad_service.dart';
import 'package:mass_lens/features/monetization/data/monetization_api.dart';
import 'package:mass_lens/features/monetization/data/monetization_config.dart';
import 'package:mass_lens/features/monetization/domain/access_status.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test(
    'reserved placements stay configured but outside interstitial loading',
    () {
      expect(
        AdMobConfig.bannerAdUnitId,
        'ca-app-pub-3940256099942544/6300978111',
      );
      expect(
        AdMobConfig.rewardedInterstitialAdUnitId,
        'ca-app-pub-3940256099942544/5354046379',
      );
    },
  );

  test('readiness wait handles no-fill, retry, and timeout', () async {
    final loader = _FakeInterstitialLoader();
    final service = AppAdService.forTesting(interstitialAdLoader: loader.load);
    addTearDown(service.dispose);

    final noFill = service.waitForInterstitial();
    expect(service.interstitialLoading, isTrue);
    loader.completeNext(null);
    expect(await noFill, isFalse);
    expect(service.interstitialLoading, isFalse);
    expect(service.interstitialReady, isFalse);

    final retry = service.waitForInterstitial();
    final loaded = _FakeInterstitialAd();
    loader.completeNext(loaded);
    expect(await retry, isTrue);
    expect(service.interstitialReady, isTrue);

    service.dispose();
    final timeoutLoader = _FakeInterstitialLoader();
    final timeoutService = AppAdService.forTesting(
      interstitialAdLoader: timeoutLoader.load,
    );
    addTearDown(timeoutService.dispose);
    expect(
      await timeoutService.waitForInterstitial(
        timeout: const Duration(milliseconds: 1),
      ),
      isFalse,
    );
    timeoutLoader.completeNext(null);
  });

  test('history drawer ad bypasses scan cadence, waits for dismissal, '
      'guards duplicates, and shares cooldown', () async {
    final clock = _FakeClock(DateTime.utc(2026, 8, 9, 12));
    final loader = _FakeInterstitialLoader();
    final paidPlacements = <String>[];
    final service = AppAdService.forTesting(
      interstitialAdLoader: loader.load,
      now: clock.now,
      onPaidEvent: (placement, _, _, _) => paidPlacements.add(placement),
    );
    addTearDown(service.dispose);

    final initialWait = service.waitForInterstitial();
    final firstAd = _FakeInterstitialAd();
    loader.completeNext(firstAd);
    expect(await initialWait, isTrue);
    expect(await service.showInterstitialAfterScan(1), isFalse);

    var dismissed = false;
    final firstShow = service.showDrawerHistoryInterstitial().then((value) {
      dismissed = true;
      return value;
    });
    await Future<void>.delayed(Duration.zero);
    expect(firstAd.showCount, 1);
    expect(dismissed, isFalse);
    expect(await service.showDrawerHistoryInterstitial(), isFalse);

    firstAd.emitPaid();
    firstAd.dismiss();
    expect(await firstShow, isTrue);
    expect(firstAd.disposeCount, 1);
    expect(paidPlacements, ['drawer_history_interstitial']);

    final scanAd = _FakeInterstitialAd();
    loader.completeNext(scanAd);
    expect(service.interstitialReady, isFalse);
    expect(await service.showInterstitialAfterScan(2), isFalse);

    clock.value = clock.value.add(const Duration(seconds: 181));
    expect(service.interstitialReady, isTrue);
    final scanShow = service.showInterstitialAfterScan(2);
    await Future<void>.delayed(Duration.zero);
    scanAd.dismiss();
    expect(await scanShow, isTrue);
    loader.completeNext(null);
  });

  test('failed and thrown shows return false and reload safely', () async {
    final loader = _FakeInterstitialLoader();
    final service = AppAdService.forTesting(interstitialAdLoader: loader.load);
    addTearDown(service.dispose);

    final failedWait = service.waitForInterstitial();
    final failed = _FakeInterstitialAd(failToShow: true);
    loader.completeNext(failed);
    expect(await failedWait, isTrue);
    expect(await service.showDrawerHistoryInterstitial(), isFalse);
    expect(failed.disposeCount, 1);

    final thrown = _FakeInterstitialAd(throwOnShow: true);
    loader.completeNext(thrown);
    expect(await service.waitForInterstitial(), isTrue);
    expect(await service.showDrawerHistoryInterstitial(), isFalse);
    expect(thrown.disposeCount, 1);

    loader.completeNext(null);
  });

  test(
    'drawer mode ads use distinct metrics and the shared cooldown',
    () async {
      final clock = _FakeClock(DateTime.utc(2026, 8, 9, 14));
      final loader = _FakeInterstitialLoader();
      final placements = <String>[];
      final service = AppAdService.forTesting(
        interstitialAdLoader: loader.load,
        now: clock.now,
        onPaidEvent: (placement, _, _, _) => placements.add(placement),
      );
      addTearDown(service.dispose);

      final firstWait = service.waitForInterstitial();
      final aiAd = _FakeInterstitialAd();
      loader.completeNext(aiAd);
      expect(await firstWait, isTrue);
      final aiShow = service.showDrawerModeInterstitial(aiScan: true);
      await Future<void>.delayed(Duration.zero);
      aiAd.emitPaid();
      aiAd.dismiss();
      expect(await aiShow, isTrue);

      final scaleAd = _FakeInterstitialAd();
      loader.completeNext(scaleAd);
      expect(await service.showDrawerModeInterstitial(aiScan: false), isFalse);
      clock.value = clock.value.add(const Duration(seconds: 181));
      final scaleShow = service.showDrawerModeInterstitial(aiScan: false);
      await Future<void>.delayed(Duration.zero);
      scaleAd.emitPaid();
      scaleAd.dismiss();
      expect(await scaleShow, isTrue);
      final historyAd = _FakeInterstitialAd();
      loader.completeNext(historyAd);
      await Future<void>.delayed(Duration.zero);
      clock.value = clock.value.add(const Duration(seconds: 181));
      final historyShow = service.showDrawerHistoryInterstitial();
      await Future<void>.delayed(Duration.zero);
      expect(historyAd.showCount, 1);
      historyAd.emitPaid();
      historyAd.dismiss();
      expect(await historyShow, isTrue);
      expect(placements, [
        'drawer_ai_scan_interstitial',
        'drawer_ai_scan_interstitial',
        'drawer_history_interstitial',
      ]);
      loader.completeNext(null);
    },
  );

  test('saved-result detail interstitial starts at the second close', () async {
    final loader = _FakeInterstitialLoader();
    final placements = <String>[];
    final service = AppAdService.forTesting(
      interstitialAdLoader: loader.load,
      onPaidEvent: (placement, _, _, _) => placements.add(placement),
    );
    addTearDown(service.dispose);

    final wait = service.waitForInterstitial();
    final ad = _FakeInterstitialAd();
    loader.completeNext(ad);
    expect(await wait, isTrue);
    expect(await service.showHistoryDetailInterstitial(1), isFalse);

    final showing = service.showHistoryDetailInterstitial(2);
    await Future<void>.delayed(Duration.zero);
    expect(ad.showCount, 1);
    ad.emitPaid();
    ad.dismiss();
    expect(await showing, isTrue);
    expect(placements, ['history_detail_interstitial']);
    loader.completeNext(null);
  });

  test('completion interstitial shows once inventory is ready and skips '
      'silently without it', () async {
    final loader = _FakeInterstitialLoader();
    final placements = <String>[];
    final service = AppAdService.forTesting(
      interstitialAdLoader: loader.load,
      onPaidEvent: (placement, _, _, _) => placements.add(placement),
    );
    final controller = MonetizationController.forTesting(
      api: _AdsEnabledApi(),
      adService: service,
    );
    addTearDown(controller.dispose);

    final showing = controller.showOnboardingCompletionInterstitial();
    await Future<void>.delayed(Duration.zero);
    final ad = _FakeInterstitialAd();
    loader.completeNext(ad);
    await Future<void>.delayed(Duration.zero);
    expect(ad.showCount, 1);
    ad.emitPaid();
    ad.dismiss();
    expect(await showing, isTrue);
    expect(placements, ['onboarding_interstitial']);

    // The shared cooldown keeps an immediate second attempt silent instead
    // of blocking entry into the app.
    final skipped = controller.showOnboardingCompletionInterstitial();
    await Future<void>.delayed(Duration.zero);
    loader.completeNext(null);
    expect(await skipped, isFalse);
  });

  testWidgets('drawer waits for each mode ad before changing screens', (
    tester,
  ) async {
    final clock = _FakeClock(DateTime.utc(2026, 8, 9, 16));
    final loader = _FakeInterstitialLoader();
    final service = AppAdService.forTesting(
      interstitialAdLoader: loader.load,
      now: clock.now,
    );
    final monetization = MonetizationController.forTesting(
      api: _AdsEnabledApi(),
      adService: service,
      now: clock.now,
    );
    final appController = AppController(
      measurementStore: const _FakeMeasurementStore(),
      onboardingComplete: true,
      appUnlockedThisSession: true,
      monetizationController: monetization,
    );
    addTearDown(appController.dispose);

    await tester.pumpWidget(MassLensApp(controller: appController));
    await tester.pumpAndSettle();
    final aiAd = _FakeInterstitialAd();
    loader.completeNext(aiAd);
    await tester.pump();

    await tester.tap(find.byKey(const Key('open_navigation')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('nav_history')));
    await tester.pump(const Duration(milliseconds: 300));
    expect(aiAd.showCount, 1);
    expect(find.byKey(const Key('home_scan_button')), findsOneWidget);
    expect(find.byKey(const Key('history_screen')), findsNothing);

    aiAd.dismiss();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('history_screen')), findsOneWidget);

    final scaleAd = _FakeInterstitialAd();
    loader.completeNext(scaleAd);
    clock.value = clock.value.add(const Duration(seconds: 181));
    await tester.pump();
    await tester.tap(find.byKey(const Key('open_navigation')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('nav_ai_scan')));
    await tester.pump(const Duration(milliseconds: 300));
    expect(scaleAd.showCount, 1);
    expect(find.byKey(const Key('history_screen')), findsOneWidget);

    scaleAd.dismiss();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('home_scan_button')), findsOneWidget);

    final historyAd = _FakeInterstitialAd();
    loader.completeNext(historyAd);
    clock.value = clock.value.add(const Duration(seconds: 181));
    await tester.pump();
    await tester.tap(find.byKey(const Key('open_navigation')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('nav_history')));
    await tester.pump(const Duration(milliseconds: 300));
    expect(historyAd.showCount, 1);
    expect(find.byKey(const Key('home_scan_button')), findsOneWidget);
    expect(find.byKey(const Key('history_screen')), findsNothing);

    historyAd.dismiss();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('history_screen')), findsOneWidget);
    loader.completeNext(null);
  });
}

final class _FakeClock {
  _FakeClock(this.value);

  DateTime value;

  DateTime now() => value;
}

final class _FakeInterstitialLoader {
  final _pending = <Completer<InterstitialAdHandle?>>[];

  Future<InterstitialAdHandle?> load(String adUnitId) {
    final completer = Completer<InterstitialAdHandle?>();
    _pending.add(completer);
    return completer.future;
  }

  void completeNext(InterstitialAdHandle? ad) {
    expect(_pending, isNotEmpty);
    _pending.removeAt(0).complete(ad);
  }
}

final class _FakeInterstitialAd implements InterstitialAdHandle {
  _FakeInterstitialAd({this.failToShow = false, this.throwOnShow = false});

  final bool failToShow;
  final bool throwOnShow;
  late void Function() _onShown;
  late void Function() _onDismissed;
  late void Function() _onFailedToShow;
  late void Function(double, PrecisionType, String) _onPaidEvent;
  int showCount = 0;
  int disposeCount = 0;

  @override
  void configure({
    required void Function() onShown,
    required void Function() onDismissed,
    required void Function() onFailedToShow,
    required void Function(
      double valueMicros,
      PrecisionType precision,
      String currencyCode,
    )
    onPaidEvent,
  }) {
    _onShown = onShown;
    _onDismissed = onDismissed;
    _onFailedToShow = onFailedToShow;
    _onPaidEvent = onPaidEvent;
  }

  @override
  Future<void> show() async {
    showCount += 1;
    if (throwOnShow) throw StateError('show failed');
    if (failToShow) {
      _onFailedToShow();
      return;
    }
    _onShown();
  }

  void emitPaid() {
    _onPaidEvent(1250, PrecisionType.estimated, 'USD');
  }

  void dismiss() {
    _onDismissed();
  }

  @override
  void dispose() {
    disposeCount += 1;
  }
}

final class _AdsEnabledApi extends MonetizationApi {
  _AdsEnabledApi() : super(apiUrl: 'https://example.invalid');

  @override
  Future<AccessStatus> getAccess(String clientId) async => const AccessStatus(
    starterScansRemaining: 2,
    rewardedScans: 0,
    legacyScans: 0,
    remainingScans: 2,
    rewardBalanceCap: 3,
    hasLifetime: false,
    scanAccessEnforced: true,
    adsEnabled: true,
    isAuthoritative: true,
    analysisModel: 'gpt-5-nano',
    adPolicy: AdPolicy(),
  );
}

final class _FakeMeasurementStore extends MeasurementStore {
  const _FakeMeasurementStore();
}
