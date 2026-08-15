import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mass_lens/app/app_controller.dart';
import 'package:mass_lens/core/theme/app_theme.dart';
import 'package:mass_lens/features/home/presentation/home_screen.dart';
import 'package:mass_lens/features/measurements/data/measurement_store.dart';
import 'package:mass_lens/features/monetization/application/monetization_controller.dart';
import 'package:mass_lens/features/monetization/data/app_ad_service.dart';
import 'package:mass_lens/features/monetization/data/monetization_api.dart';
import 'package:mass_lens/features/monetization/domain/access_status.dart';
import 'package:mass_lens/features/monetization/domain/reward_attempt.dart';
import 'package:mass_lens/features/monetization/presentation/rewarded_scan_sheet.dart';
import 'package:mass_lens/l10n/l10n.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test(
    'completed ad receives immediate client credit without polling',
    () async {
      final clock = _FakeClock(DateTime.utc(2026, 8, 8, 12));
      final api = _FakeMonetizationApi(clock: clock);
      final ads = _FakeAppAdService();
      final controller = MonetizationController.forTesting(
        api: api,
        adService: ads,
        now: clock.now,
      );
      addTearDown(controller.dispose);
      await controller.initialize();

      final credited = await controller.watchAdForScan();

      expect(credited, isTrue);
      expect(ads.showCount, 1);
      expect(api.events.map((event) => event.event), [
        RewardAttemptEvent.started,
        RewardAttemptEvent.clientEarned,
      ]);
      expect(api.events.map((event) => event.attemptId).toSet(), hasLength(1));
      expect(RewardAttemptId.isValid(api.events.first.attemptId), isTrue);
      expect(api.queriedAttemptIds, isEmpty);
      expect(controller.hasPendingReward, isFalse);
      expect(controller.rewardFlowState, RewardFlowState.verified);
    },
  );

  test('provider exception details are never exposed as notices', () async {
    final accessController = MonetizationController.forTesting(
      api: _ThrowingAccessApi(),
      adService: _FakeAppAdService(),
    );
    addTearDown(accessController.dispose);

    await accessController.initialize();

    expect(accessController.message, 'Could not refresh scan access.');
    expect(accessController.message, isNot(contains('private-provider-token')));

    final clock = _FakeClock(DateTime.utc(2026, 8, 8, 12));
    final rewardController = MonetizationController.forTesting(
      api: _ThrowingRewardStartApi(clock: clock),
      adService: _FakeAppAdService(),
      now: clock.now,
    );
    addTearDown(rewardController.dispose);
    await rewardController.initialize();

    expect(await rewardController.watchAdForScan(), isFalse);
    expect(rewardController.message, 'The rewarded ad could not start.');
    expect(rewardController.message, isNot(contains('private-provider-token')));
  });

  test(
    'full rewarded balance keeps the earned attempt for a later retry',
    () async {
      final clock = _FakeClock(DateTime.utc(2026, 8, 8, 12));
      final controller = MonetizationController.forTesting(
        api: _FakeMonetizationApi(
          clock: clock,
          clientEarnedFailures: 1,
          clientEarnedFailureStatusCode: 409,
        ),
        adService: _FakeAppAdService(),
        now: clock.now,
      );
      addTearDown(controller.dispose);
      await controller.initialize();

      expect(await controller.watchAdForScan(), isFalse);
      expect(controller.hasPendingReward, isTrue);
      expect(controller.rewardFlowState, RewardFlowState.pending);
      expect(controller.message, contains('balance is full'));
    },
  );

  test('missing earned attempt is terminal and is not retried', () async {
    final clock = _FakeClock(DateTime.utc(2026, 8, 8, 12));
    final controller = MonetizationController.forTesting(
      api: _FakeMonetizationApi(
        clock: clock,
        clientEarnedFailures: 1,
        clientEarnedFailureStatusCode: 404,
      ),
      adService: _FakeAppAdService(),
      now: clock.now,
    );
    addTearDown(controller.dispose);
    await controller.initialize();

    expect(await controller.watchAdForScan(), isFalse);
    expect(controller.hasPendingReward, isFalse);
    expect(controller.rewardFlowState, RewardFlowState.failed);
    expect(controller.message, 'This reward attempt could not be found.');
  });

  test(
    'pending scan credit persists, blocks repeats, and reconciles on boot',
    () async {
      final clock = _FakeClock(DateTime.utc(2026, 8, 8, 12));
      final pendingApi = _FakeMonetizationApi(
        clock: clock,
        clientEarnedFailures: 2,
      );
      final ads = _FakeAppAdService();
      final first = MonetizationController.forTesting(
        api: pendingApi,
        adService: ads,
        now: clock.now,
      );
      await first.initialize();

      expect(await first.watchAdForScan(), isFalse);
      expect(first.hasPendingReward, isTrue);
      expect(first.rewardFlowState, RewardFlowState.pending);
      final attemptId = pendingApi.events.first.attemptId;
      final preferences = await SharedPreferences.getInstance();
      final persisted =
          jsonDecode(
                preferences.getString('mass_lens.reward_attempt_state.v1')!,
              )
              as Map<String, Object?>;
      expect((persisted['attempts'] as List), hasLength(1));

      expect(await first.watchAdForScan(), isFalse);
      expect(ads.showCount, 1);
      expect(first.rewardStartBlocked, isTrue);
      first.dispose();

      final creditedApi = _FakeMonetizationApi(clock: clock);
      final restored = MonetizationController.forTesting(
        api: creditedApi,
        adService: _FakeAppAdService(),
        now: clock.now,
      );
      addTearDown(restored.dispose);

      await restored.initialize();

      expect(creditedApi.queriedAttemptIds, [attemptId]);
      expect(creditedApi.events.map((event) => event.event), [
        RewardAttemptEvent.clientEarned,
      ]);
      expect(restored.hasPendingReward, isFalse);
      expect(restored.rewardFlowState, RewardFlowState.verified);
      expect(restored.message, 'One scan was added.');
    },
  );

  testWidgets('pending sheet is durable, checkable, and compact-screen safe', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(360, 520));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final clock = _FakeClock(DateTime.utc(2026, 8, 8, 12));
    final monetization = MonetizationController.forTesting(
      api: _FakeMonetizationApi(clock: clock, clientEarnedFailures: 1),
      adService: _FakeAppAdService(),
      now: clock.now,
    );
    await monetization.initialize();
    expect(await monetization.watchAdForScan(), isFalse);
    final appController = AppController(
      measurementStore: const MeasurementStore(),
      onboardingComplete: true,
      monetizationController: monetization,
    );
    addTearDown(appController.dispose);

    await tester.pumpWidget(
      AppScope(
        controller: appController,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: buildAppTheme(),
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: FilledButton(
                  onPressed: () => showRewardedScanSheet(context),
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('reward_sync_pending')), findsOneWidget);
    expect(find.byKey(const Key('check_reward_status')), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('sheet explains unavailable ads and exposes privacy choices', (
    tester,
  ) async {
    final clock = _FakeClock(DateTime.utc(2026, 8, 8, 12));
    final ads = _FakeAppAdService(
      requestAds: false,
      ready: false,
      privacyOptionsRequired: true,
    );
    final monetization = MonetizationController.forTesting(
      api: _FakeMonetizationApi(clock: clock),
      adService: ads,
      now: clock.now,
    );
    await monetization.initialize();
    final appController = AppController(
      measurementStore: const MeasurementStore(),
      onboardingComplete: true,
      monetizationController: monetization,
    );
    addTearDown(appController.dispose);

    await _openRewardSheet(tester, appController);

    final watchButton = tester.widget<FilledButton>(
      find.byKey(const Key('watch_ad_for_scan')),
    );
    expect(watchButton.onPressed, isNull);
    expect(find.text('Rewarded ads unavailable'), findsOneWidget);
    expect(find.textContaining('consent or configuration'), findsOneWidget);
    expect(find.text('Privacy choices'), findsOneWidget);
    expect(find.byKey(const Key('retry_rewarded_ad')), findsNothing);

    await tester.tap(find.text('Privacy choices'));
    await tester.pump();
    expect(ads.privacyOptionsShowCount, 1);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('retry reloads an unavailable rewarded ad without a spinner', (
    tester,
  ) async {
    final clock = _FakeClock(DateTime.utc(2026, 8, 8, 12));
    final ads = _FakeAppAdService(requestAds: true, ready: false);
    final monetization = MonetizationController.forTesting(
      api: _FakeMonetizationApi(clock: clock),
      adService: ads,
      now: clock.now,
    );
    await monetization.initialize();
    ads.readyOnNextUpdate = true;
    final appController = AppController(
      measurementStore: const MeasurementStore(),
      onboardingComplete: true,
      monetizationController: monetization,
    );
    addTearDown(appController.dispose);

    await _openRewardSheet(tester, appController);

    expect(find.text('Rewarded ad is loading'), findsOneWidget);
    expect(find.byKey(const Key('retry_rewarded_ad')), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);

    await tester.tap(find.byKey(const Key('retry_rewarded_ad')));
    await tester.pumpAndSettle();

    expect(find.text('Watch an ad · Get 1 scan'), findsOneWidget);
    expect(find.byKey(const Key('retry_rewarded_ad')), findsNothing);
    final watchButton = tester.widget<FilledButton>(
      find.byKey(const Key('watch_ad_for_scan')),
    );
    expect(watchButton.onPressed, isNotNull);
    expect(ads.updatePlanCount, 2);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('AI home keeps a rewarded scan CTA when ads are enabled', (
    tester,
  ) async {
    final clock = _FakeClock(DateTime.utc(2026, 8, 8, 12));
    final monetization = MonetizationController.forTesting(
      api: _FakeMonetizationApi(clock: clock),
      adService: _FakeAppAdService(),
      now: clock.now,
    );
    await monetization.initialize();
    final appController = AppController(
      measurementStore: const MeasurementStore(),
      onboardingComplete: true,
      monetizationController: monetization,
    );
    addTearDown(appController.dispose);

    await tester.pumpWidget(
      AppScope(
        controller: appController,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: buildAppTheme(),
          home: Scaffold(
            body: HomeScreen(
              onMeasure: (_) {},
              onGallery: (_) {},
              onViewHistory: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(appController.monetization.access.adsEnabled, isTrue);
    expect(find.byKey(const Key('home_reward_cta')), findsOneWidget);
    expect(find.text('0 left · Get +1'), findsOneWidget);
  });
}

Future<void> _openRewardSheet(
  WidgetTester tester,
  AppController controller,
) async {
  await tester.pumpWidget(
    AppScope(
      controller: controller,
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: buildAppTheme(),
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: FilledButton(
                onPressed: () => showRewardedScanSheet(context),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
}

class _FakeClock {
  _FakeClock(this.value);

  DateTime value;

  DateTime now() => value;
}

class _RewardEventCall {
  const _RewardEventCall(this.attemptId, this.event);

  final String attemptId;
  final RewardAttemptEvent event;
}

class _FakeMonetizationApi extends MonetizationApi {
  _FakeMonetizationApi({
    required this.clock,
    this.clientEarnedFailures = 0,
    this.clientEarnedFailureStatusCode,
  }) : super(apiUrl: 'https://example.invalid');

  final _FakeClock clock;
  int clientEarnedFailures;
  final int? clientEarnedFailureStatusCode;
  final List<_RewardEventCall> events = [];
  final List<String> queriedAttemptIds = [];

  @override
  Future<AccessStatus> getAccess(String clientId) async => const AccessStatus(
    starterScansRemaining: 0,
    rewardedScans: 0,
    legacyScans: 0,
    remainingScans: 0,
    rewardBalanceCap: 3,
    scanAccessEnforced: true,
    adsEnabled: true,
    isAuthoritative: true,
    analysisModel: 'gpt-5-nano',
    adPolicy: AdPolicy(),
  );

  @override
  Future<RewardAttemptStatus> recordRewardAttempt({
    required String clientId,
    required String attemptId,
    required RewardAttemptEvent event,
  }) async {
    events.add(_RewardEventCall(attemptId, event));
    if (event == RewardAttemptEvent.started) {
      return _status(attemptId, RewardAttemptServerState.pending);
    }
    if (clientEarnedFailures > 0) {
      clientEarnedFailures -= 1;
      throw MonetizationApiException(
        'Connection lost after reward.',
        statusCode: clientEarnedFailureStatusCode,
      );
    }
    return _status(attemptId, RewardAttemptServerState.verified);
  }

  @override
  Future<RewardAttemptStatus> getRewardAttempt({
    required String clientId,
    required String attemptId,
  }) async {
    queriedAttemptIds.add(attemptId);
    return _status(attemptId, RewardAttemptServerState.pending);
  }

  RewardAttemptStatus _status(
    String attemptId,
    RewardAttemptServerState state,
  ) => RewardAttemptStatus(
    attemptId: attemptId,
    state: state,
    createdAt: clock.now(),
    updatedAt: clock.now(),
    expiresAt: clock.now().add(const Duration(hours: 24)),
  );
}

final class _ThrowingAccessApi extends MonetizationApi {
  _ThrowingAccessApi() : super(apiUrl: 'https://example.invalid');

  @override
  Future<AccessStatus> getAccess(String clientId) async {
    throw StateError('private-provider-token');
  }
}

final class _ThrowingRewardStartApi extends _FakeMonetizationApi {
  _ThrowingRewardStartApi({required super.clock});

  @override
  Future<RewardAttemptStatus> recordRewardAttempt({
    required String clientId,
    required String attemptId,
    required RewardAttemptEvent event,
  }) async {
    throw StateError('private-provider-token');
  }
}

class _FakeAppAdService extends AppAdService {
  _FakeAppAdService({
    this.requestAds = true,
    this.ready = true,
    bool privacyOptionsRequired = false,
  }) : _privacyOptionsRequired = privacyOptionsRequired;

  final bool requestAds;
  bool ready;
  final bool _privacyOptionsRequired;
  bool readyOnNextUpdate = false;
  int showCount = 0;
  int updatePlanCount = 0;
  int privacyOptionsShowCount = 0;

  @override
  bool get canRequestAds => requestAds;

  @override
  bool get rewardedReady => ready;

  @override
  bool get privacyOptionsRequired => _privacyOptionsRequired;

  @override
  Future<void> updatePlan({
    required bool adsAllowed,
    required AdPolicy policy,
  }) async {
    updatePlanCount += 1;
    if (readyOnNextUpdate) {
      readyOnNextUpdate = false;
      ready = true;
    }
  }

  @override
  Future<void> showPrivacyOptions() async {
    privacyOptionsShowCount += 1;
  }

  @override
  Future<bool> showRewarded({required void Function() onClientEarned}) async {
    showCount += 1;
    onClientEarned();
    return true;
  }

  @override
  void dispose() {}
}
