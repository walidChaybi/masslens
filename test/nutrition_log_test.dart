import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mass_lens/app/app_controller.dart';
import 'package:mass_lens/features/measurements/data/measurement_store.dart';
import 'package:mass_lens/features/measurements/domain/measurement.dart';
import 'package:mass_lens/features/nutrition/application/nutrition_diary_controller.dart';
import 'package:mass_lens/features/nutrition/data/nutrition_log_store.dart';
import 'package:mass_lens/features/nutrition/domain/nutrition_log.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('entry JSON round-trip preserves stable day and source snapshot', () {
    final entry = NutritionLogEntry.create(
      id: 'entry-1',
      loggedAt: DateTime(2026, 8, 15, 12, 30),
      mealType: MealType.lunch,
      label: 'Pasta bowl',
      weightGrams: 325,
      nutrition: const NutritionTotals(
        caloriesKcal: 540,
        proteinGrams: 22,
        carbsGrams: 84,
        fatGrams: 14,
      ),
      isPartial: true,
      sourceMeasurementId: 'scan-1',
    );

    final restored = NutritionLogEntry.fromJson(entry.toJson());

    expect(restored.id, entry.id);
    expect(restored.dayKey, '2026-08-15');
    expect(restored.mealType, MealType.lunch);
    expect(restored.weightGrams, 325);
    expect(restored.nutrition.caloriesKcal, 540);
    expect(restored.isPartial, isTrue);
    expect(restored.sourceMeasurementId, 'scan-1');
  });

  test(
    'store skips malformed rows while preserving valid local records',
    () async {
      final valid = _entry('valid', DateTime(2026, 8, 15), calories: 400);
      SharedPreferences.setMockInitialValues({
        NutritionLogStore.storageKey: jsonEncode([
          valid.toJson(),
          {'id': 'broken', 'loggedAt': 'not-a-date'},
          'not-a-map',
        ]),
      });

      final loaded = await const NutritionLogStore().load();

      expect(loaded, hasLength(1));
      expect(loaded.single.id, 'valid');
    },
  );

  test('period contains missing days and averages only logged days', () {
    final entries = [
      _entry('one', DateTime(2026, 8, 10, 8), calories: 400),
      _entry('two', DateTime(2026, 8, 12, 19), calories: 800),
    ];

    final period = summarizeNutritionPeriod(
      entries,
      endingOn: DateTime(2026, 8, 15),
      dayCount: 7,
    );

    expect(period.days, hasLength(7));
    expect(period.days.map((day) => day.dayKey), [
      '2026-08-09',
      '2026-08-10',
      '2026-08-11',
      '2026-08-12',
      '2026-08-13',
      '2026-08-14',
      '2026-08-15',
    ]);
    expect(period.loggedDays, 2);
    expect(period.totals.caloriesKcal, 1200);
    expect(period.averageOnLoggedDays.caloriesKcal, 600);
    expect(period.days[2].totals.caloriesKcal, 0);
  });

  test('food scan import snapshots corrected nutrition and partial status', () {
    final measurement = _foodMeasurement();

    final entry = NutritionLogEntry.fromMeasurement(
      id: 'log-1',
      loggedAt: DateTime(2026, 8, 15, 13),
      mealType: MealType.lunch,
      measurement: measurement,
    );

    expect(entry.label, 'Lunch plate');
    expect(entry.weightGrams, 250);
    expect(entry.nutrition.caloriesKcal, 500);
    expect(entry.nutrition.proteinGrams, 25);
    expect(entry.isPartial, isTrue);
    expect(entry.sourceMeasurementId, measurement.id);
  });

  test('nutrition history and scan history clear independently', () async {
    final measurement = _foodMeasurement();
    final diary = NutritionDiaryController(
      store: const NutritionLogStore(),
      entries: [
        NutritionLogEntry.fromMeasurement(
          id: 'log-1',
          loggedAt: DateTime(2026, 8, 15),
          mealType: MealType.lunch,
          measurement: measurement,
        ),
      ],
    );
    final controller = AppController(
      measurementStore: const MeasurementStore(),
      measurements: [measurement],
      nutritionDiaryController: diary,
    );
    addTearDown(controller.dispose);

    await controller.clearHistory();
    expect(controller.measurements, isEmpty);
    expect(
      controller.nutritionDiary.entries.single.nutrition.caloriesKcal,
      500,
    );

    await controller.nutritionDiary.clear();
    expect(controller.nutritionDiary.entries, isEmpty);
  });

  test('manual entries reject negative or completely empty nutrition', () {
    expect(
      () => NutritionLogEntry.create(
        id: 'negative',
        loggedAt: DateTime(2026, 8, 15),
        mealType: MealType.snack,
        label: 'Invalid',
        nutrition: const NutritionTotals(
          caloriesKcal: -1,
          proteinGrams: 0,
          carbsGrams: 0,
          fatGrams: 0,
        ),
      ),
      throwsFormatException,
    );
    expect(
      () => NutritionLogEntry.create(
        id: 'empty',
        loggedAt: DateTime(2026, 8, 15),
        mealType: MealType.snack,
        label: 'Invalid',
        nutrition: NutritionTotals.zero,
      ),
      throwsFormatException,
    );
  });
}

NutritionLogEntry _entry(
  String id,
  DateTime date, {
  required double calories,
}) => NutritionLogEntry.create(
  id: id,
  loggedAt: date,
  mealType: MealType.snack,
  label: id,
  nutrition: NutritionTotals(
    caloriesKcal: calories,
    proteinGrams: calories / 40,
    carbsGrams: calories / 20,
    fatGrams: calories / 90,
  ),
);

Measurement _foodMeasurement() => Measurement(
  id: 'food-scan',
  createdAt: DateTime(2026, 8, 15),
  imagePath: '/tmp/food.jpg',
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
