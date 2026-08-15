import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as image_library;
import 'package:mass_lens/app/app_controller.dart';
import 'package:mass_lens/app/mass_lens_app.dart';
import 'package:mass_lens/core/services/app_review_service.dart';
import 'package:mass_lens/features/measurements/data/measurement_store.dart';
import 'package:mass_lens/features/onboarding/presentation/onboarding_screen.dart';
import 'package:mass_lens/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('five guided pages complete once without Skip or swipe', (
    tester,
  ) async {
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
    expect(find.text('Keep the whole object visible'), findsOneWidget);
    await _tapContinue(tester);
    expect(find.text('Bright light, simple background'), findsOneWidget);
    await _tapContinue(tester);
    expect(find.text('Almost ready'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1700));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('You’re ready to scan'), findsOneWidget);
    expect(find.text('3 starter scans'), findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('onboarding_continue')));
    await tester.tap(find.byKey(const Key('onboarding_continue')));
    await tester.pump();
    expect(find.byKey(const Key('onboarding_review_prompt')), findsOneWidget);
    expect(find.text('Help MassLens grow'), findsOneWidget);
    await tester.tap(find.byKey(const Key('onboarding_review_later')));
    await tester.pumpAndSettle();
    expect(controller.onboardingComplete, isTrue);
    expect(find.byKey(const Key('digital_scale_screen')), findsOneWidget);
    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getBool('mass_lens.onboarding_complete'), isTrue);
    expect(
      preferences.getBool('mass_lens.onboarding_review_prompt_handled'),
      isTrue,
    );
  });

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

    await _reachReadyPage(tester);
    final continueButton = find.byKey(const Key('onboarding_continue'));
    await tester.ensureVisible(continueButton);
    await tester.tap(continueButton);
    await tester.pump();

    expect(find.byKey(const Key('onboarding_review_prompt')), findsOneWidget);
    await tester.tap(find.byKey(const Key('onboarding_review_now')));
    await tester.pumpAndSettle();

    expect(review.requestCount, 1);
    expect(controller.onboardingReviewPromptHandled, isTrue);
    expect(controller.onboardingComplete, isTrue);
    expect(find.byKey(const Key('digital_scale_screen')), findsOneWidget);

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
    expect(find.text('Keep the whole object visible'), findsOneWidget);

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

Future<void> _reachReadyPage(WidgetTester tester) async {
  await _tapContinue(tester);
  await _tapContinue(tester);
  await _tapContinue(tester);
  await tester.pump(const Duration(milliseconds: 1700));
  await tester.pump(const Duration(milliseconds: 500));
  expect(find.byKey(const Key('onboarding_page_5')), findsOneWidget);
}

class _FakeMeasurementStore extends MeasurementStore {
  const _FakeMeasurementStore();
}

class _FakeAppReviewService implements AppReviewService {
  int requestCount = 0;

  @override
  Future<bool> requestReview() async {
    requestCount += 1;
    return true;
  }
}
