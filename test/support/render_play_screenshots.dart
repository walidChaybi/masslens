// Render real application widgets for the new listing; no fabricated scan results.
// flutter test test/support/render_play_screenshots.dart --update-goldens --dart-define=ADMOB_ENABLED=false
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'package:mass_lens/features/monetization/data/app_ad_service.dart';
import 'package:mass_lens/features/monetization/application/monetization_controller.dart';
import 'package:mass_lens/features/monetization/data/monetization_api.dart';
import 'package:mass_lens/features/monetization/domain/access_status.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mass_lens/app/app_controller.dart';
import 'package:mass_lens/core/theme/app_theme.dart';
import 'package:mass_lens/features/measurements/data/measurement_store.dart';
import 'package:mass_lens/features/shell/presentation/app_shell.dart';
import 'package:mass_lens/features/onboarding/presentation/onboarding_screen.dart';
import 'package:mass_lens/l10n/l10n.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final properties = File('android/local.properties').readAsStringSync();
    final sdk = RegExp(
      r'^flutter.sdk=(.+)$',
      multiLine: true,
    ).firstMatch(properties)!.group(1)!;
    final fonts = '$sdk/bin/cache/artifacts/material_fonts';
    for (final family in ['Roboto', 'Ahem']) {
      final loader = FontLoader(family);
      for (final face in ['Regular', 'Medium', 'Bold']) {
        loader.addFont(
          Future.value(
            ByteData.sublistView(
              File('$fonts/Roboto-$face.ttf').readAsBytesSync(),
            ),
          ),
        );
      }
      await loader.load();
    }
    final icons = FontLoader('MaterialIcons');
    icons.addFont(
      Future.value(
        ByteData.sublistView(
          File('$fonts/MaterialIcons-Regular.otf').readAsBytesSync(),
        ),
      ),
    );
    await icons.load();
  });

  testWidgets('render the cleaned app for upload', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final controller = AppController(
      measurementStore: const MeasurementStore(),
      onboardingComplete: true,
      appUnlockedThisSession: true,
      monetizationController: MonetizationController.forTesting(
        api: _StarterAccessApi(),
        adService: AppAdService(),
      ),
    );
    addTearDown(controller.dispose);
    await controller.monetization.initialize();
    final theme = buildAppTheme();
    Widget app(Widget screen) => AppScope(
      controller: controller,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: theme.copyWith(
          textTheme: theme.textTheme.apply(fontFamily: 'Roboto'),
          primaryTextTheme: theme.primaryTextTheme.apply(fontFamily: 'Roboto'),
        ),
        home: screen,
      ),
    );
    await tester.pumpWidget(app(const AppShell()));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('nav_digital_scale')), findsNothing);
    await _useAndroidFallbackFont(tester);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile(
        '../../play-store/new-app/screenshots/01-photo-estimates.png',
      ),
    );
    await tester.tap(find.byKey(const Key('open_navigation')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('nav_nutrition')));
    await tester.pumpAndSettle();
    await _useAndroidFallbackFont(tester);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile(
        '../../play-store/new-app/screenshots/02-nutrition-diary.png',
      ),
    );
    final context = tester.element(find.byType(AppShell));
    await tester.runAsync(() async {
      await precacheImage(
        const AssetImage('assets/onboarding/masslens_hero.webp'),
        context,
      );
      await precacheImage(
        const AssetImage('assets/onboarding/teal_mug.webp'),
        context,
      );
    });
    await tester.pumpWidget(app(const OnboardingScreen()));
    await tester.pumpAndSettle();
    await _useAndroidFallbackFont(tester);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('../../play-store/new-app/screenshots/03-welcome.png'),
    );
    expect(tester.takeException(), isNull);
  });
}

// The widget-test engine substitutes Ahem for unspecified fonts. Restore
// Android's Roboto fallback solely in the exported render tree.
Future<void> _useAndroidFallbackFont(WidgetTester tester) async {
  InlineSpan font(InlineSpan span) {
    if (span is! TextSpan) return span;
    return TextSpan(
      text: span.text,
      style: (span.style ?? const TextStyle()).copyWith(
        fontFamily: span.style?.fontFamily ?? 'Roboto',
      ),
      children: span.children?.map(font).toList(),
    );
  }

  for (final element in find.byType(RichText).evaluate()) {
    final paragraph = element.renderObject;
    if (paragraph is RenderParagraph) paragraph.text = font(paragraph.text);
  }
  await tester.pump();
}

class _StarterAccessApi extends MonetizationApi {
  const _StarterAccessApi() : super(apiUrl: 'https://example.invalid');
  @override
  Future<AccessStatus> getAccess(String clientId) async => const AccessStatus(
    starterScansRemaining: 2,
    rewardedScans: 0,
    legacyScans: 0,
    remainingScans: 2,
    rewardBalanceCap: 3,
    hasLifetime: false,
    scanAccessEnforced: true,
    adsEnabled: false,
    isAuthoritative: true,
    analysisModel: 'gpt-5-nano',
    adPolicy: AdPolicy(),
  );
}
