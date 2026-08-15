import 'package:flutter_test/flutter_test.dart';
import 'package:mass_lens/features/measurements/domain/measurement.dart';
import 'package:mass_lens/features/scan/data/ai_estimate_payload.dart';

void main() {
  test('legacy measurement JSON defaults to object mode', () {
    final restored = Measurement.fromJson({
      'id': 'legacy',
      'createdAt': '2026-08-15T10:00:00.000Z',
      'imagePath': '/tmp/object.jpg',
      'objectLabel': 'Parcel',
      'category': 'Parcel',
      'estimateGrams': 1000,
      'lowerBoundGrams': 800,
      'upperBoundGrams': 1200,
      'confidence': 'medium',
      'dimensions': {'width': 300, 'height': 200, 'depth': 100},
      'assumptions': ['Cardboard box'],
    });

    expect(restored.scanMode, ScanMode.object);
    expect(restored.dimensions, isNotNull);
    expect(restored.foodComponents, isEmpty);
    expect(restored.totalEstimateGrams, 1000);
  });

  test('food measurement and nutrition survive JSON round trip', () {
    final measurement = _foodMeasurement();
    final restored = Measurement.fromJson(measurement.toJson());

    expect(restored.scanMode, ScanMode.foodPlate);
    expect(restored.mealLabel, 'Chicken and rice');
    expect(restored.dimensions, isNull);
    expect(restored.foodComponents, hasLength(2));
    expect(restored.foodComponents.first.userAdjustedGrams, 150);
    expect(restored.foodComponents.first.nutrition!.fdcId, 171077);
    expect(restored.foodComponents.first.nutrition!.caloriesKcalPer100g, 100);
    expect(restored.foodComponents.last.nutrition, isNull);
  });

  test('food aggregates weights, calorie range, macros, and partial state', () {
    final measurement = _foodMeasurement(adjustedGrams: null);

    expect(measurement.totalEstimateGrams, 300);
    expect(measurement.totalLowerBoundGrams, 240);
    expect(measurement.totalUpperBoundGrams, 360);
    expect(measurement.nutritionTotals.caloriesKcal, 200);
    expect(measurement.nutritionTotals.proteinGrams, 20);
    expect(measurement.nutritionTotals.carbsGrams, 40);
    expect(measurement.nutritionTotals.fatGrams, 10);
    expect(measurement.calorieLowerBoundKcal, 160);
    expect(measurement.calorieUpperBoundKcal, 240);
    expect(measurement.lowerBoundNutritionTotals.proteinGrams, 16);
    expect(measurement.lowerBoundNutritionTotals.carbsGrams, 32);
    expect(measurement.lowerBoundNutritionTotals.fatGrams, 8);
    expect(measurement.upperBoundNutritionTotals.proteinGrams, 24);
    expect(measurement.upperBoundNutritionTotals.carbsGrams, 48);
    expect(measurement.upperBoundNutritionTotals.fatGrams, 12);
    expect(measurement.hasNutritionData, isTrue);
    expect(measurement.hasPartialNutrition, isTrue);
  });

  test('adjusting and removing items recomputes effective plate totals', () {
    final measurement = _foodMeasurement(adjustedGrams: null);
    final adjustedItems = [...measurement.foodComponents];
    adjustedItems[0] = adjustedItems[0].copyWith(userAdjustedGrams: 150.0);
    final adjusted = measurement.copyWith(foodComponents: adjustedItems);

    expect(adjusted.totalEstimateGrams, 250);
    expect(adjusted.estimateGrams, 250);
    expect(adjusted.totalLowerBoundGrams, 240);
    expect(adjusted.totalUpperBoundGrams, 360);
    expect(adjusted.nutritionTotals.caloriesKcal, 150);
    expect(adjusted.nutritionTotals.proteinGrams, 15);

    final removed = adjusted.copyWith(
      foodComponents: [adjusted.foodComponents.first],
    );
    expect(removed.totalEstimateGrams, 150);
    expect(removed.totalLowerBoundGrams, 160);
    expect(removed.totalUpperBoundGrams, 240);
    expect(removed.hasPartialNutrition, isFalse);
    expect(removed.nutritionTotals.caloriesKcal, 150);

    final cleared = removed.foodComponents.single.copyWith(
      userAdjustedGrams: null,
    );
    expect(cleared.effectiveGrams, 200);
  });

  test('food AI response maps USDA data without model-generated totals', () {
    final measurement = measurementFromAiEstimatePayload(
      {
        'meal_label': 'Chicken and rice',
        'confidence': 'medium',
        'items': [
          {
            'label': 'Grilled chicken breast',
            'estimate_grams': 200,
            'lower_bound_grams': 160,
            'upper_bound_grams': 240,
            'confidence': 'high',
            'nutrition': {
              'fdc_id': 171077,
              'description': 'Chicken breast, grilled',
              'data_type': 'SR Legacy',
              'calories_kcal_per_100g': 165,
              'protein_grams_per_100g': 31,
              'carbs_grams_per_100g': 0,
              'fat_grams_per_100g': 3.6,
            },
          },
          {
            'label': 'Rice',
            'estimate_grams': 180,
            'lower_bound_grams': 140,
            'upper_bound_grams': 220,
            'confidence': 'medium',
            'nutrition': null,
          },
        ],
        'assumptions': [
          'Standard dinner plate',
          'Chicken is boneless',
          'Rice is cooked',
        ],
      },
      '/tmp/meal.jpg',
      analysisLocale: 'fr',
      scanMode: ScanMode.foodPlate,
    );

    expect(measurement.scanMode, ScanMode.foodPlate);
    expect(measurement.objectLabel, 'Chicken and rice');
    expect(measurement.category, 'Food');
    expect(measurement.estimateGrams, 380);
    expect(measurement.lowerBoundGrams, 300);
    expect(measurement.upperBoundGrams, 460);
    expect(measurement.analysisLocale, 'fr');
    expect(measurement.dimensions, isNull);
    expect(measurement.nutritionTotals.caloriesKcal, 330);
    expect(measurement.nutritionTotals.proteinGrams, 62);
    expect(measurement.hasPartialNutrition, isTrue);
  });

  test('food AI response rejects a plate with no nutrition match', () {
    expect(
      () => measurementFromAiEstimatePayload(
        {
          'meal_label': 'Unknown plate',
          'confidence': 'low',
          'items': [
            {
              'label': 'Unknown food',
              'estimate_grams': 100,
              'lower_bound_grams': 50,
              'upper_bound_grams': 150,
              'confidence': 'low',
              'nutrition': null,
            },
          ],
          'assumptions': [
            'Unknown recipe',
            'No size reference',
            'Food visible',
          ],
        },
        '/tmp/unknown.jpg',
        scanMode: ScanMode.foodPlate,
      ),
      throwsA(isA<AiEstimatePayloadException>()),
    );
  });
}

Measurement _foodMeasurement({double? adjustedGrams = 150}) {
  const nutrition = NutritionReference(
    fdcId: 171077,
    description: 'Chicken breast, grilled',
    dataType: 'SR Legacy',
    per100g: NutritionPer100g(
      caloriesKcal: 100,
      proteinGrams: 10,
      carbsGrams: 20,
      fatGrams: 5,
    ),
  );
  return Measurement(
    id: 'food-1',
    createdAt: DateTime.utc(2026, 8, 15, 10),
    imagePath: '/tmp/meal.jpg',
    objectLabel: 'Chicken and rice',
    category: 'Food',
    estimateGrams: adjustedGrams == null ? 300 : 250,
    lowerBoundGrams: 240,
    upperBoundGrams: 360,
    confidence: ConfidenceLevel.medium,
    assumptions: const ['One', 'Two', 'Three'],
    scanMode: ScanMode.foodPlate,
    mealLabel: 'Chicken and rice',
    foodComponents: [
      FoodComponent(
        label: 'Chicken',
        estimateGrams: 200,
        lowerBoundGrams: 160,
        upperBoundGrams: 240,
        confidence: ConfidenceLevel.high,
        nutrition: nutrition,
        userAdjustedGrams: adjustedGrams,
      ),
      const FoodComponent(
        label: 'Rice',
        estimateGrams: 100,
        lowerBoundGrams: 80,
        upperBoundGrams: 120,
        confidence: ConfidenceLevel.medium,
      ),
    ],
  );
}
