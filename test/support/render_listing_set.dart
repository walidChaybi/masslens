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

import 'dart:ui' as ui;
import 'package:mass_lens/features/measurements/domain/measurement.dart';
import 'package:mass_lens/features/nutrition/application/nutrition_diary_controller.dart';
import 'package:mass_lens/features/nutrition/data/nutrition_log_store.dart';
import 'package:mass_lens/features/nutrition/domain/nutrition_log.dart';

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

  testWidgets('export four listing screenshots', (tester) async {
    SharedPreferences.setMockInitialValues({});
    debugDisableShadows = false;
    await tester.binding.setSurfaceSize(const Size(432, 768));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final now = DateTime.now();
    final entries = List.generate(
      7,
      (i) => NutritionLogEntry.create(
        id: 'listing-sample-$i',
        loggedAt: DateTime(now.year, now.month, now.day - i, 12),
        mealType: MealType.lunch,
        label: 'Sample food diary',
        nutrition: NutritionTotals(
          caloriesKcal: [
            1420,
            1940,
            1780,
            2000,
            1850,
            1920,
            1680,
          ][i].toDouble(),
          proteinGrams: [92, 125, 110, 140, 118, 132, 105][i].toDouble(),
          carbsGrams: [164, 225, 209, 241, 218, 230, 190][i].toDouble(),
          fatGrams: [44, 60, 52, 64, 55, 62, 49][i].toDouble(),
        ),
      ),
    );
    final controller = AppController(
      measurementStore: const MeasurementStore(),
      onboardingComplete: true,
      appUnlockedThisSession: true,
      nutritionDiaryController: NutritionDiaryController(
        store: const NutritionLogStore(),
        entries: entries,
      ),
      monetizationController: MonetizationController.forTesting(
        api: _StarterAccessApi(),
        adService: AppAdService(),
      ),
    );
    addTearDown(controller.dispose);
    await controller.monetization.initialize();
    final boundaryKey = GlobalKey();
    final theme = buildAppTheme();
    final title = ValueNotifier<int>(0);
    addTearDown(title.dispose);
    final phone = AppScope(
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
        builder: (context, child) => MediaQuery(
          data: const MediaQueryData(
            size: Size(390, 680),
            devicePixelRatio: 2.5,
          ),
          child: child!,
        ),
        home: const AppShell(),
      ),
    );
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: RepaintBoundary(
          key: boundaryKey,
          child: ValueListenableBuilder<int>(
            valueListenable: title,
            child: phone,
            builder: (_, index, child) =>
                _ListingPanel(index: index, child: child!),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    Future<void> save(String file) async {
      await tester.pumpAndSettle();
      await _useAndroidFallbackFont(tester);
      expect(tester.takeException(), isNull);
      final boundary =
          boundaryKey.currentContext!.findRenderObject()!
              as RenderRepaintBoundary;
      await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: 2.5);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        File(
          'play-store/listing-screenshots/$file',
        ).writeAsBytesSync(bytes!.buffer.asUint8List());
        image.dispose();
      });
    }

    await save('01-photo-weight-estimates.png');
    await tester.tap(find.widgetWithText(NavigationDestination, 'Nutrition'));
    title.value = 1;
    await save('02-calories-and-macros.png');
    await tester.tap(find.text('Trends'));
    title.value = 2;
    await tester.pumpAndSettle();
    await tester.drag(find.text('Daily calories'), const Offset(0, -100));
    await tester.pumpAndSettle();
    await save('03-nutrition-trends.png');
    await tester.tap(find.widgetWithText(NavigationDestination, 'Guide'));
    title.value = 3;
    await save('04-photo-capture-guide.png');
    debugDisableShadows = true;
  });
}

class _ListingPanel extends StatelessWidget {
  const _ListingPanel({required this.index, required this.child});
  final int index;
  final Widget child;
  @override
  Widget build(BuildContext context) {
    const navy = Color(0xFF142439);
    const lime = Color(0xFFBBF641);
    const cream = Color(0xFFF6F3EA);
    final dark = index == 0 || index == 2;
    final fg = dark ? cream : navy;
    const headings = [
      'Explore weight.\nFrom a photo.',
      'Your calories.\nYour daily view.',
      'See your week\nat a glance.',
      'A clearer photo\nstarts here.',
    ];
    const subtitles = [
      'AI estimates for visible objects',
      'Keep calories and macros together',
      'Follow calories and macro trends',
      'Simple tips for your next scan',
    ];
    return ColoredBox(
      color: dark ? navy : cream,
      child: Stack(
        children: [
          Positioned(
            right: -115,
            top: 340,
            child: Container(
              width: 270,
              height: 270,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: (dark ? lime : navy).withValues(alpha: .09),
                  width: 1,
                ),
              ),
            ),
          ),
          Positioned(
            left: 28,
            right: 28,
            top: 22,
            child: Row(
              children: [
                Icon(
                  Icons.center_focus_strong_rounded,
                  color: dark ? lime : navy,
                  size: 19,
                ),
                const SizedBox(width: 7),
                Text(
                  'MassLens',
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: fg,
                  ),
                ),
                const Spacer(),
                Text(
                  '0${index + 1} / 04',
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 1.2,
                    color: fg.withValues(alpha: .6),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 28,
            right: 28,
            top: 54,
            child: Text(
              headings[index],
              style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 34,
                height: 1.04,
                fontWeight: FontWeight.w700,
                letterSpacing: -.8,
                color: fg,
              ),
            ),
          ),
          Positioned(
            left: 28,
            right: 28,
            top: 133,
            child: Text(
              subtitles[index],
              style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: fg.withValues(alpha: .7),
              ),
            ),
          ),
          Positioned(
            left: 46,
            top: 161,
            width: 340,
            height: 584.8,
            child: FittedBox(
              fit: BoxFit.contain,
              child: Container(
                width: 400,
                height: 688,
                decoration: BoxDecoration(
                  color: const Color(0xFF25364A),
                  borderRadius: BorderRadius.circular(29),
                  border: Border.all(color: const Color(0xFF566270), width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF08111D).withValues(alpha: .3),
                      blurRadius: 26,
                      offset: const Offset(0, 16),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(4),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: SizedBox(width: 390, height: 680, child: child),
                ),
              ),
            ),
          ),
          Positioned(
            left: 12,
            right: 12,
            bottom: 7,
            child: Text(
              index == 1 || index == 2
                  ? 'Illustrative diary data · Actual app interface'
                  : 'Photo estimates are approximate, not measurements.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 9,
                color: fg.withValues(alpha: .65),
              ),
            ),
          ),
        ],
      ),
    );
  }
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
