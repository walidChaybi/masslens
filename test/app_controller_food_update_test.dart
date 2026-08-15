import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mass_lens/app/app_controller.dart';
import 'package:mass_lens/features/measurements/data/measurement_store.dart';
import 'package:mass_lens/features/measurements/domain/measurement.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('updating a food measurement persists component edits', () async {
    SharedPreferences.setMockInitialValues({});
    final original = _measurement();
    final controller = AppController(
      measurementStore: const MeasurementStore(),
      measurements: [original],
    );
    addTearDown(controller.dispose);

    final adjustedComponent = original.foodComponents.single.copyWith(
      userAdjustedGrams: 175.0,
    );
    final adjusted = original.copyWith(foodComponents: [adjustedComponent]);
    await controller.updateMeasurement(adjusted);

    expect(controller.measurements.single.totalEstimateGrams, 175);
    expect(controller.measurements.single.nutritionTotals.caloriesKcal, 280);

    final preferences = await SharedPreferences.getInstance();
    final stored =
        jsonDecode(preferences.getString('mass_lens.measurement_history.v1')!)
            as List;
    final restored = Measurement.fromJson(
      Map<String, Object?>.from(stored.single as Map),
    );
    expect(restored.foodComponents.single.userAdjustedGrams, 175);
    expect(restored.totalEstimateGrams, 175);
    expect(restored.nutritionTotals.caloriesKcal, 280);
  });
}

Measurement _measurement() => Measurement(
  id: 'food-saved',
  createdAt: DateTime.utc(2026, 8, 15),
  imagePath: '/tmp/food.jpg',
  objectLabel: 'Pasta',
  category: 'Food',
  estimateGrams: 200,
  lowerBoundGrams: 160,
  upperBoundGrams: 240,
  confidence: ConfidenceLevel.medium,
  assumptions: const ['One', 'Two', 'Three'],
  scanMode: ScanMode.foodPlate,
  mealLabel: 'Pasta',
  foodComponents: const [
    FoodComponent(
      label: 'Pasta',
      estimateGrams: 200,
      lowerBoundGrams: 160,
      upperBoundGrams: 240,
      confidence: ConfidenceLevel.medium,
      nutrition: NutritionReference(
        fdcId: 168927,
        description: 'Pasta, cooked',
        dataType: 'SR Legacy',
        per100g: NutritionPer100g(
          caloriesKcal: 160,
          proteinGrams: 6,
          carbsGrams: 31,
          fatGrams: 1,
        ),
      ),
    ),
  ],
);
