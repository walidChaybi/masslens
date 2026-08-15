import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mass_lens/app/app_controller.dart';
import 'package:mass_lens/features/home/presentation/home_screen.dart';
import 'package:mass_lens/features/measurements/data/measurement_store.dart';
import 'package:mass_lens/features/measurements/domain/measurement.dart';
import 'package:mass_lens/features/nutrition/application/nutrition_diary_controller.dart';
import 'package:mass_lens/features/nutrition/data/nutrition_log_store.dart';
import 'package:mass_lens/features/nutrition/domain/nutrition_log.dart';
import 'package:mass_lens/features/nutrition/presentation/nutrition_screen.dart';
import 'package:mass_lens/features/settings/presentation/settings_screen.dart';
import 'package:mass_lens/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('home shows a separate Nutrition & Trends entry card', (
    tester,
  ) async {
    var opened = false;
    final controller = _controller();
    addTearDown(controller.dispose);
    await _pump(
      tester,
      controller,
      Scaffold(
        body: HomeScreen(
          onMeasure: (_) {},
          onGallery: (_) {},
          onViewHistory: () {},
          onOpenNutrition: () => opened = true,
        ),
      ),
    );

    final card = find.byKey(const Key('home_nutrition_button'));
    expect(card, findsOneWidget);
    expect(find.byKey(const Key('home_scan_button')), findsOneWidget);
    await tester.ensureVisible(card);
    await tester.tap(card);

    expect(opened, isTrue);
  });

  testWidgets('manual entry updates day totals and renders trend charts', (
    tester,
  ) async {
    final controller = _controller();
    addTearDown(controller.dispose);
    await _pump(tester, controller, const Scaffold(body: NutritionScreen()));

    final add = find.byKey(const Key('nutrition_add_food'));
    await tester.ensureVisible(add);
    await tester.tap(add);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('nutrition_add_manual')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('nutrition_label_field')),
      'Greek yogurt',
    );
    await tester.enterText(
      find.byKey(const Key('nutrition_calories_field')),
      '220',
    );
    final save = find.byKey(const Key('nutrition_save_manual_entry'));
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pumpAndSettle();

    expect(controller.nutritionDiary.entries, hasLength(1));
    expect(controller.nutritionDiary.entries.single.label, 'Greek yogurt');
    expect(
      controller.nutritionDiary.entries.single.nutrition.caloriesKcal,
      220,
    );
    expect(find.text('Greek yogurt'), findsOneWidget);

    await tester.tap(find.text('Trends'));
    await tester.pumpAndSettle();

    expect(find.byType(BarChart), findsOneWidget);
    expect(find.byType(LineChart), findsOneWidget);
    expect(find.text('Logged days'), findsOneWidget);
  });

  testWidgets('saved food scan is copied explicitly as an independent entry', (
    tester,
  ) async {
    final scan = _foodMeasurement();
    final controller = _controller(measurements: [scan]);
    addTearDown(controller.dispose);
    await _pump(tester, controller, const Scaffold(body: NutritionScreen()));

    final add = find.byKey(const Key('nutrition_add_food'));
    await tester.ensureVisible(add);
    await tester.tap(add);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.byKey(const Key('nutrition_add_from_scan')));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Lunch plate'), findsWidgets);
    await tester.tap(find.text('Lunch plate').last);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    final save = find.byKey(const Key('nutrition_save_scan_entry'));
    expect(save, findsOneWidget);
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(controller.nutritionDiary.entries, hasLength(1));
    final logged = controller.nutritionDiary.entries.single;
    expect(logged.sourceMeasurementId, scan.id);
    expect(logged.nutrition.caloriesKcal, 500);
    expect(logged.isPartial, isTrue);

    final changedComponents = [...scan.foodComponents];
    changedComponents[0] = changedComponents[0].copyWith(
      userAdjustedGrams: 100.0,
    );
    await controller.updateMeasurement(
      scan.copyWith(foodComponents: changedComponents),
    );
    expect(controller.measurements.single.nutritionTotals.caloriesKcal, 200);
    expect(
      controller.nutritionDiary.entries.single.nutrition.caloriesKcal,
      500,
    );
  });

  testWidgets('settings clears nutrition without clearing saved scans', (
    tester,
  ) async {
    final scan = _foodMeasurement();
    final controller = _controller(
      measurements: [scan],
      entries: [
        NutritionLogEntry.fromMeasurement(
          id: 'entry',
          loggedAt: DateTime.now(),
          mealType: MealType.lunch,
          measurement: scan,
        ),
      ],
    );
    addTearDown(controller.dispose);
    await _pump(tester, controller, const Scaffold(body: SettingsScreen()));

    final clear = find.text('Clear nutrition history');
    await tester.scrollUntilVisible(
      clear,
      500,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(clear);
    await tester.pump();
    await tester.tap(clear);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Clear nutrition').last);
    await tester.pumpAndSettle();

    expect(controller.nutritionDiary.entries, isEmpty);
    expect(controller.measurements.single.id, scan.id);
  });

  testWidgets('nutrition dashboard fits narrow large-text EN FR and ES', (
    tester,
  ) async {
    final controller = _controller();
    addTearDown(controller.dispose);

    for (final locale in const [Locale('en'), Locale('fr'), Locale('es')]) {
      await _pump(
        tester,
        controller,
        Scaffold(
          body: NutritionScreen(key: ValueKey(locale.languageCode)),
        ),
        locale: locale,
        logicalSize: const Size(360, 800),
        textScale: 1.3,
      );
      expect(tester.takeException(), isNull);
      final l10n = AppLocalizations.of(
        tester.element(find.byKey(const Key('nutrition_view_selector'))),
      );
      await tester.tap(find.text(l10n.nutritionTrendsTab));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(find.byKey(const Key('nutrition_period_selector')), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.drag(find.byType(ListView), const Offset(0, -900));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(BarChart), findsOneWidget);
      expect(find.byType(LineChart), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });
}

AppController _controller({
  List<Measurement> measurements = const [],
  List<NutritionLogEntry> entries = const [],
}) => AppController(
  measurementStore: const MeasurementStore(),
  measurements: measurements,
  nutritionDiaryController: NutritionDiaryController(
    store: const NutritionLogStore(),
    entries: entries,
  ),
);

Future<void> _pump(
  WidgetTester tester,
  AppController controller,
  Widget home, {
  Locale locale = const Locale('en'),
  Size logicalSize = const Size(540, 960),
  double textScale = 1,
}) async {
  tester.view.physicalSize = logicalSize;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    AppScope(
      controller: controller,
      child: MaterialApp(
        locale: locale,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: home,
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
}

Measurement _foodMeasurement() => Measurement(
  id: 'food-scan',
  createdAt: DateTime.now(),
  imagePath: '/tmp/missing-food.jpg',
  objectLabel: 'Lunch plate',
  category: 'Food',
  estimateGrams: 250,
  lowerBoundGrams: 200,
  upperBoundGrams: 300,
  confidence: ConfidenceLevel.medium,
  assumptions: const ['Estimated serving'],
  scanMode: ScanMode.foodPlate,
  mealLabel: 'Lunch plate',
  foodComponents: const [
    FoodComponent(
      label: 'Pasta',
      estimateGrams: 200,
      lowerBoundGrams: 170,
      upperBoundGrams: 230,
      confidence: ConfidenceLevel.medium,
      userAdjustedGrams: 250,
      nutrition: NutritionReference(
        fdcId: 1,
        description: 'Pasta, cooked',
        dataType: 'Foundation',
        per100g: NutritionPer100g(
          caloriesKcal: 200,
          proteinGrams: 10,
          carbsGrams: 35,
          fatGrams: 4,
        ),
      ),
    ),
    FoodComponent(
      label: 'Unknown sauce',
      estimateGrams: 0,
      lowerBoundGrams: 0,
      upperBoundGrams: 0,
      confidence: ConfidenceLevel.low,
    ),
  ],
);
