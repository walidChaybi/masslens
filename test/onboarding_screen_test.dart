import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as image_library;
import 'package:mass_lens/app/app_controller.dart';
import 'package:mass_lens/app/mass_lens_app.dart';
import 'package:mass_lens/core/services/app_review_service.dart';
import 'package:mass_lens/features/measurements/data/measurement_store.dart';
import 'package:mass_lens/features/monetization/application/monetization_controller.dart';
import 'package:mass_lens/features/monetization/data/app_ad_service.dart';
import 'package:mass_lens/features/monetization/data/monetization_api.dart';
import 'package:mass_lens/features/monetization/domain/access_status.dart';
import 'package:mass_lens/features/monetization/presentation/native_ad_card.dart';
import 'package:mass_lens/features/onboarding/presentation/onboarding_screen.dart';
import 'package:mass_lens/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('paywall-only relaunch skips welcome pages', (tester) async {
    final controller = AppController(
      measurementStore: const _FakeMeasurementStore(),
      welcomeComplete: true,
    );
    addTearDown(controller.dispose);
    await tester.pumpWidget(MassLensApp(controller: controller));
    await tester.pump();

    expect(find.text('Know more at a glance'), findsNothing);
    expect(find.byKey(const Key('onboarding_page_paywall')), findsOneWidget);
    expect(find.text('Photo estimates.'), findsOneWidget);
    expect(find.byKey(const Key('watch_ad_for_scan')), findsNothing);
  });

  testWidgets('welcome completion persists when reaching the paywall', (
    tester,
  ) async {
    final controller = AppController(
      measurementStore: const _FakeMeasurementStore(),
    );
    addTearDown(controller.dispose);
    await tester.pumpWidget(MassLensApp(controller: controller));
    await tester.pump();

    await _reachPaywall(tester);
    expect(controller.welcomeComplete, isTrue);
    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getBool('mass_lens.welcome_complete'), isTrue);
  });

  testWidgets(
    'three welcome pages then paywall complete without Skip or swipe',
    (tester) async {
      final controller = AppController(
        measurementStore: const _FakeMeasurementStore(),
      );
      addTearDown(controller.dispose);
      await tester.pumpWidget(MassLensApp(controller: controller));
      await tester.pump();

      expect(find.byKey(const Key('onboarding_page_1')), findsOneWidget);
      expect(find.text('Know more at a glance'), findsOneWidget);
      expect(find.text('Skip'), findsNothing);

      await tester.drag(
        find.byKey(const Key('onboarding_pages')),
        const Offset(-300, 0),
      );
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Know more at a glance'), findsOneWidget);

      await _tapContinue(tester);
      expect(find.byKey(const Key('onboarding_page_2')), findsOneWidget);
      expect(find.text('Keep the whole object visible'), findsNothing);
      await _tapContinue(tester);
      expect(find.byKey(const Key('onboarding_page_3')), findsOneWidget);
      expect(find.text('Bright light, simple background'), findsNothing);
      await _tapContinue(tester);
      await tester.pump(const Duration(milliseconds: 450));

      expect(find.byKey(const Key('onboarding_page_paywall')), findsOneWidget);
      expect(find.byKey(const Key('paywall_headline')), findsOneWidget);
      expect(find.text('Photo estimates.'), findsOneWidget);
      expect(find.text('Explore with AI.'), findsOneWidget);
      expect(find.text('Unlimited + ad-free'), findsOneWidget);
      expect(find.text('2–4 kg'), findsOneWidget);
      expect(find.byKey(const Key('paywall_luggage_hero')), findsOneWidget);
      expect(find.byKey(const Key('paywall_scale_hero')), findsNothing);
      expect(find.byKey(const Key('buy_lifetime_unlock')), findsOneWidget);
      expect(find.byKey(const Key('paywall_skip')), findsOneWidget);

      await tester.tap(find.byKey(const Key('paywall_skip')));
      await tester.pump();
      expect(find.byKey(const Key('onboarding_review_prompt')), findsOneWidget);
      expect(find.text('Help MassLens grow'), findsOneWidget);
      await tester.tap(find.byKey(const Key('onboarding_review_later')));
      await tester.pumpAndSettle();
      expect(controller.onboardingComplete, isTrue);
      expect(find.byKey(const Key('home_scan_button')), findsOneWidget);
      final preferences = await SharedPreferences.getInstance();
      expect(preferences.getBool('mass_lens.onboarding_complete'), isTrue);
      expect(
        preferences.getBool('mass_lens.onboarding_review_prompt_handled'),
        isTrue,
      );
    },
  );

  testWidgets('review choice invokes Google Play once and never gates entry', (
    tester,
  ) async {
    final review = _FakeAppReviewService();
    final controller = AppController(
      measurementStore: const _FakeMeasurementStore(),
      appReviewService: review,
    );
    addTearDown(controller.dispose);
    await tester.pumpWidget(MassLensApp(controller: controller));
    await tester.pump();

    await _reachPaywall(tester);
    await tester.tap(find.byKey(const Key('paywall_skip')));
    await tester.pump();

    expect(find.byKey(const Key('onboarding_review_prompt')), findsOneWidget);
    await tester.tap(find.byKey(const Key('onboarding_review_now')));
    await tester.pumpAndSettle();

    expect(review.requestCount, 1);
    expect(controller.onboardingReviewPromptHandled, isTrue);
    expect(controller.onboardingComplete, isTrue);
    expect(find.byKey(const Key('home_scan_button')), findsOneWidget);

    expect(
      await controller.handleOnboardingReview(requestReview: true),
      isFalse,
    );
    expect(review.requestCount, 1);
  });

  testWidgets('Android Back returns to the preceding educational page', (
    tester,
  ) async {
    final controller = AppController(
      measurementStore: const _FakeMeasurementStore(),
    );
    addTearDown(controller.dispose);
    await tester.pumpWidget(MassLensApp(controller: controller));
    await tester.pump();
    await _tapContinue(tester);
    expect(find.byKey(const Key('onboarding_page_2')), findsOneWidget);
    expect(find.text('Keep the whole object visible'), findsNothing);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Know more at a glance'), findsOneWidget);
    expect(controller.onboardingComplete, isFalse);
  });

  testWidgets('French and Spanish follow the selected app locale', (
    tester,
  ) async {
    for (final entry in const [
      (Locale('fr'), 'Des informations en un clin d’œil', 'Commencer'),
      (Locale('es'), 'Más información de un vistazo', 'Empezar'),
    ]) {
      final controller = AppController(
        measurementStore: const _FakeMeasurementStore(),
      );
      await tester.pumpWidget(
        AppScope(
          controller: controller,
          child: MaterialApp(
            locale: entry.$1,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const OnboardingScreen(),
          ),
        ),
      );
      await tester.pump();
      expect(find.text(entry.$2), findsOneWidget);
      expect(find.text(entry.$3), findsOneWidget);
      controller.dispose();
    }
  });

  testWidgets('unsupported device languages fall back to English', (
    tester,
  ) async {
    tester.binding.platformDispatcher.localesTestValue = const [Locale('de')];
    addTearDown(tester.binding.platformDispatcher.clearLocalesTestValue);
    final controller = AppController(
      measurementStore: const _FakeMeasurementStore(),
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(MassLensApp(controller: controller));
    await tester.pump();

    expect(find.text('Know more at a glance'), findsOneWidget);
    expect(find.text('Get started'), findsOneWidget);
  });

  testWidgets('onboarding remains usable on tablets and with large text', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    for (final configuration in const [
      (Size(800, 1100), 1.0),
      (Size(360, 640), 1.5),
    ]) {
      await tester.binding.setSurfaceSize(configuration.$1);
      final controller = AppController(
        measurementStore: const _FakeMeasurementStore(),
      );
      await tester.pumpWidget(
        AppScope(
          controller: controller,
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(configuration.$2)),
              child: child!,
            ),
            home: const OnboardingScreen(),
          ),
        ),
      );
      await tester.pump();

      final button = find.byKey(const Key('onboarding_continue'));
      await tester.ensureVisible(button);
      expect(button, findsOneWidget);
      expect(tester.takeException(), isNull);
      controller.dispose();
    }
  });

  testWidgets('compact layout keeps the CTA above a Samsung navigation inset', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    addTearDown(tester.view.resetPadding);
    addTearDown(tester.view.resetViewPadding);
    await tester.binding.setSurfaceSize(const Size(360, 640));
    final physicalBottomInset = 48 * tester.view.devicePixelRatio;
    tester.view.padding = FakeViewPadding(bottom: physicalBottomInset);
    tester.view.viewPadding = FakeViewPadding(bottom: physicalBottomInset);
    final controller = AppController(
      measurementStore: const _FakeMeasurementStore(),
    );
    addTearDown(controller.dispose);
    await tester.pumpWidget(MassLensApp(controller: controller));
    await tester.pump();

    final button = find.byKey(const Key('onboarding_continue'));
    expect(button, findsOneWidget);
    await tester.ensureVisible(button);
    final rect = tester.getRect(button);
    expect(rect.bottom, lessThanOrEqualTo(592));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'welcome keeps the estimate limitation visible with compact native ads',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final monetization = MonetizationController.forTesting(
        api: _AdsEnabledMonetizationApi(),
        adService: _AdsEnabledAppAdService(),
      );
      await monetization.initialize();
      final controller = AppController(
        measurementStore: const _FakeMeasurementStore(),
        monetizationController: monetization,
      );
      addTearDown(controller.dispose);
      await tester.pumpWidget(MassLensApp(controller: controller));
      await tester.pump();

      expect(find.text('Know more at a glance'), findsOneWidget);
      final description = AppLocalizations.of(
        tester.element(find.byKey(const Key('onboarding_page_1'))),
      ).onboardingHeroBody;
      expect(find.text(description), findsOneWidget);

      for (final placement in [
        'onboarding_intro',
        'onboarding_framing',
        'onboarding_light',
      ]) {
        expect(
          find.text(
            'Leave clear space around every edge and avoid hands or clutter covering the object.',
          ),
          findsNothing,
        );
        expect(
          find.text(
            'Good lighting and a steady photo help AI recognize shape and material more accurately.',
          ),
          findsNothing,
        );
        final ad = find.byKey(Key('native_ad_loading_$placement'));
        expect(ad, findsOneWidget);
        final size = tester.getSize(ad);
        expect(size.width, 312);
        expect(size.height, 120);
        expect(
          tester.widget<NativeAdCard>(find.byType(NativeAdCard)).medium,
          isFalse,
        );
        final continueButton = find
            .byKey(const Key('onboarding_continue'))
            .hitTestable();
        expect(tester.getRect(continueButton).bottom, lessThanOrEqualTo(640));
        if (placement != 'onboarding_light') {
          await tester.tap(continueButton);
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 450));
        }
      }
      expect(tester.takeException(), isNull);
    },
  );

  test('onboarding review decision survives a process relaunch', () async {
    final review = _FakeAppReviewService();
    final first = AppController(
      measurementStore: const _FakeMeasurementStore(),
      appReviewService: review,
    );
    await first.handleOnboardingReview(requestReview: false);
    first.dispose();

    final relaunched = await AppController.bootstrap(
      store: const _FakeMeasurementStore(),
    );
    addTearDown(relaunched.dispose);
    expect(relaunched.onboardingReviewPromptHandled, isTrue);
    expect(review.requestCount, 0);
  });

  test('original onboarding artwork is optimized and cutouts keep alpha', () {
    const paths = [
      'assets/onboarding/masslens_hero.webp',
      'assets/onboarding/teal_mug.webp',
      'assets/onboarding/balance.webp',
    ];
    final bytes = paths.map((path) => File(path).readAsBytesSync()).toList();
    expect(
      bytes.fold<int>(0, (sum, item) => sum + item.length),
      lessThan(2500000),
    );
    for (final item in bytes) {
      expect(image_library.decodeImage(item), isNotNull);
    }
    for (final item in bytes.skip(1)) {
      final decoded = image_library.decodeImage(item)!;
      expect(decoded.getPixel(0, 0).a, 0);
    }
  });
}

Future<void> _tapContinue(WidgetTester tester) async {
  final button = find.byKey(const Key('onboarding_continue'));
  await tester.ensureVisible(button);
  await tester.pump();
  await tester.tap(button);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 450));
}

Future<void> _reachPaywall(WidgetTester tester) async {
  await _tapContinue(tester);
  await _tapContinue(tester);
  await _tapContinue(tester);
  await tester.pump(const Duration(milliseconds: 450));
  expect(find.byKey(const Key('onboarding_page_paywall')), findsOneWidget);
}

class _FakeMeasurementStore extends MeasurementStore {
  const _FakeMeasurementStore();
}

final class _AdsEnabledMonetizationApi extends MonetizationApi {
  _AdsEnabledMonetizationApi() : super(apiUrl: 'https://example.invalid');

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

final class _AdsEnabledAppAdService extends AppAdService {
  @override
  bool get canRequestNativeAds => true;

  @override
  Future<void> updatePlan({
    required bool adsAllowed,
    required AdPolicy policy,
  }) async {}

  @override
  void dispose() {}
}

class _FakeAppReviewService implements AppReviewService {
  int requestCount = 0;

  @override
  Future<bool> requestReview() async {
    requestCount += 1;
    return true;
  }
}
