import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mass_lens/core/theme/app_theme.dart';
import 'package:mass_lens/features/measurements/domain/measurement.dart';
import 'package:mass_lens/features/measurements/presentation/measurement_detail_screen.dart';
import 'package:mass_lens/features/measurements/presentation/share_card.dart';
import 'package:mass_lens/l10n/l10n.dart';

void main() {
  testWidgets('saved food detail renders partial USDA nutrition honestly', (
    tester,
  ) async {
    await tester.pumpWidget(
      _LocalizedTestApp(
        child: SingleChildScrollView(
          child: MeasurementSummary(
            measurement: _foodMeasurement(),
            unitSystem: UnitSystem.metric,
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byKey(const Key('food_measurement_summary')), findsOneWidget);
    expect(find.text('Lunch plate'), findsOneWidget);
    expect(find.byKey(const Key('result_weight')), findsOneWidget);
    expect(find.text('250 g'), findsWidgets);
    expect(find.text('160 g — 240 g'), findsOneWidget);
    expect(find.byKey(const Key('food_total_calories')), findsOneWidget);
    expect(find.text('330'), findsOneWidget);
    expect(find.text('PARTIAL TOTAL'), findsOneWidget);
    expect(find.text('Chicken breast, roasted'), findsOneWidget);
    expect(find.text('Survey (FNDDS) · FDC 171077'), findsOneWidget);
    expect(
      find.text('Weight only — no complete USDA nutrition match'),
      findsWidgets,
    );
    expect(find.byKey(const Key('food_disclaimer')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('food share card includes meal totals, macros, and components', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 760));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      _LocalizedTestApp(
        child: Center(
          child: MeasurementShareCard(
            measurement: _foodMeasurement(),
            unitSystem: UnitSystem.metric,
            localeName: 'en',
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byKey(const Key('food_share_card')), findsOneWidget);
    expect(find.text('Lunch plate'), findsOneWidget);
    expect(find.byKey(const Key('food_share_calories')), findsOneWidget);
    expect(find.text('330'), findsOneWidget);
    expect(find.textContaining('Protein 62.0 g'), findsOneWidget);
    expect(find.textContaining('Chicken · 200 g'), findsOneWidget);
    expect(find.textContaining('Rice · 50 g'), findsOneWidget);
    expect(find.textContaining('USDA FoodData Central'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('legacy object detail tolerates absent visual dimensions', (
    tester,
  ) async {
    await tester.pumpWidget(
      _LocalizedTestApp(
        child: SingleChildScrollView(
          child: MeasurementSummary(
            measurement: Measurement(
              id: 'legacy',
              createdAt: DateTime(2026, 8, 15),
              imagePath: '/missing-object.jpg',
              objectLabel: 'Parcel',
              category: 'Parcel',
              estimateGrams: 800,
              lowerBoundGrams: 650,
              upperBoundGrams: 950,
              confidence: ConfidenceLevel.medium,
              assumptions: const ['Cardboard box'],
            ),
            unitSystem: UnitSystem.metric,
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Parcel'), findsOneWidget);
    expect(find.text('AI visual size'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

Measurement _foodMeasurement() {
  return Measurement(
    id: 'food-detail',
    createdAt: DateTime(2026, 8, 15),
    imagePath: '/missing-food.jpg',
    objectLabel: 'Lunch plate',
    mealLabel: 'Lunch plate',
    category: 'Food',
    estimateGrams: 200,
    lowerBoundGrams: 160,
    upperBoundGrams: 240,
    confidence: ConfidenceLevel.medium,
    assumptions: const [
      'The visible chicken is boneless.',
      'The rice is cooked.',
      'The plate is excluded from net weight.',
    ],
    scanMode: ScanMode.foodPlate,
    foodComponents: const [
      FoodComponent(
        label: 'Chicken',
        estimateGrams: 150,
        lowerBoundGrams: 120,
        upperBoundGrams: 180,
        userAdjustedGrams: 200,
        confidence: ConfidenceLevel.high,
        nutrition: NutritionReference(
          fdcId: 171077,
          description: 'Chicken breast, roasted',
          dataType: 'Survey (FNDDS)',
          per100g: NutritionPer100g(
            caloriesKcal: 165,
            proteinGrams: 31,
            carbsGrams: 0,
            fatGrams: 3.6,
          ),
        ),
      ),
      FoodComponent(
        label: 'Rice',
        estimateGrams: 50,
        lowerBoundGrams: 40,
        upperBoundGrams: 60,
        confidence: ConfidenceLevel.medium,
      ),
    ],
  );
}

class _LocalizedTestApp extends StatelessWidget {
  const _LocalizedTestApp({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: buildAppTheme(),
      home: Scaffold(
        body: SafeArea(
          child: Padding(padding: const EdgeInsets.all(20), child: child),
        ),
      ),
    );
  }
}
