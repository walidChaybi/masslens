import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mass_lens/app/app_controller.dart';
import 'package:mass_lens/core/theme/app_theme.dart';
import 'package:mass_lens/features/guide/presentation/guide_screen.dart';
import 'package:mass_lens/features/history/presentation/history_screen.dart';
import 'package:mass_lens/features/home/presentation/home_screen.dart';
import 'package:mass_lens/features/measurements/data/measurement_store.dart';
import 'package:mass_lens/features/measurements/domain/measurement.dart';
import 'package:mass_lens/features/measurements/presentation/measurement_detail_screen.dart';
import 'package:mass_lens/features/scan/presentation/scan_screen.dart';
import 'package:mass_lens/features/settings/presentation/settings_screen.dart';
import 'package:mass_lens/l10n/display_labels.dart';
import 'package:mass_lens/l10n/l10n.dart';

void main() {
  test('generated catalogs support English, French, and Spanish', () async {
    expect(
      AppLocalizations.supportedLocales.map((locale) => locale.languageCode),
      containsAll(<String>['en', 'fr', 'es']),
    );

    final en = await AppLocalizations.delegate.load(const Locale('en'));
    final fr = await AppLocalizations.delegate.load(const Locale('fr'));
    final es = await AppLocalizations.delegate.load(const Locale('es'));

    expect(en.onboardingHeroTitle, 'Know more at a glance');
    expect(fr.onboardingHeroTitle, 'Des informations en un clin d’œil');
    expect(es.onboardingHeroTitle, 'Más información de un vistazo');
    expect(en.onboardingReviewAction, 'Review app');
    expect(fr.onboardingReviewAction, 'Donner un avis');
    expect(es.onboardingReviewAction, 'Escribir reseña');
    expect(en.homeModeFoodMacros, 'Food & macros');
    expect(fr.homeModeFoodMacros, 'Aliments et macros');
    expect(es.homeModeFoodMacros, 'Comida y macros');
    expect(en.scanFoodScale, 'Food Scale');
    expect(fr.scanFoodScale, 'Balance alimentaire');
    expect(es.scanFoodScale, 'Báscula de alimentos');
    expect(en.accessScansLeft(1), '1 scan left');
    expect(fr.accessScansLeft(2), '2 scans restants');
    expect(es.accessScansLeft(0), 'No hay escaneos disponibles');
    expect(localizedMaterial(fr, 'Glass/Ceramic'), 'Verre/Céramique');
    expect(localizedMaterial(es, 'Plastic'), 'Plástico');
    expect(localizedMaterial(en, 'future-wire-value'), 'future-wire-value');
  });

  test('measurement numbers use the active locale', () {
    expect(formatWeight(2500, UnitSystem.metric, localeName: 'en'), '2.50 kg');
    expect(formatWeight(2500, UnitSystem.metric, localeName: 'fr'), '2,50 kg');
    expect(
      formatApproximateDimensions(
        const DimensionsMm(width: 180, height: 90, depth: 300),
        UnitSystem.metric,
        localeName: 'es',
      ),
      '≈ 30,0 × 18,0 × 9,0 cm',
    );
  });

  testWidgets('localized production surfaces fit a compact viewport', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(360, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    for (final locale in const [Locale('en'), Locale('fr'), Locale('es')]) {
      final controller = AppController(
        measurementStore: const MeasurementStore(),
        onboardingComplete: true,
      );
      addTearDown(controller.dispose);
      final l10n = await AppLocalizations.delegate.load(locale);

      final surfaces = <({String name, Widget screen, String visibleText})>[
        (
          name: 'guide',
          screen: GuideScreen(onScan: () {}),
          visibleText: l10n.guideTitle,
        ),
        (
          name: 'settings',
          screen: const SettingsScreen(),
          visibleText: l10n.settingsTitle,
        ),
        (
          name: 'home',
          screen: HomeScreen(
            onMeasure: (_) {},
            onGallery: (_) {},
            onViewHistory: () {},
          ),
          visibleText: l10n.homeAiWeight,
        ),
        (
          name: 'history',
          screen: HistoryScreen(onScan: () {}),
          visibleText: l10n.historyTitle,
        ),
        (
          name: 'scan',
          screen: ScanScreen(autoStart: false),
          visibleText: l10n.scanPhotographObject,
        ),
        (
          name: 'food scan',
          screen: ScanScreen(autoStart: false, scanMode: ScanMode.foodPlate),
          visibleText: l10n.scanPhotographMeal,
        ),
        (
          name: 'measurement detail',
          screen: MeasurementDetailScreen(
            measurement: Measurement(
              id: 'localized-${locale.languageCode}',
              createdAt: DateTime(2026, 8, 9),
              imagePath: '/missing/localized-image.jpg',
              objectLabel: 'Object',
              category: 'Household',
              estimateGrams: 2500,
              lowerBoundGrams: 2000,
              upperBoundGrams: 3000,
              confidence: ConfidenceLevel.medium,
              dimensions: const DimensionsMm(
                width: 180,
                height: 90,
                depth: 300,
              ),
              assumptions: const ['Size', 'Material', 'Uncertainty'],
            ),
          ),
          visibleText: l10n.detailSavedEstimate,
        ),
      ];

      for (final surface in surfaces) {
        await tester.pumpWidget(
          AppScope(
            controller: controller,
            child: MaterialApp(
              locale: locale,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              theme: buildAppTheme(),
              home: Scaffold(body: surface.screen),
            ),
          ),
        );
        await tester.pump();

        expect(find.text(surface.visibleText), findsOneWidget);
        expect(
          tester.takeException(),
          isNull,
          reason: '${surface.name} overflowed in ${locale.languageCode}',
        );
      }
    }
  });
}
