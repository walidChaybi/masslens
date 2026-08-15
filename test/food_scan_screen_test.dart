import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mass_lens/app/app_controller.dart';
import 'package:mass_lens/core/theme/app_theme.dart';
import 'package:mass_lens/features/measurements/data/measurement_store.dart';
import 'package:mass_lens/features/measurements/domain/measurement.dart';
import 'package:mass_lens/features/scan/data/photo_picker.dart';
import 'package:mass_lens/features/scan/domain/estimate_repository.dart';
import 'package:mass_lens/features/scan/presentation/scan_screen.dart';
import 'package:mass_lens/l10n/l10n.dart';

void main() {
  testWidgets(
    'food scan sends plate context and supports correcting and removing items',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 1800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final controller = AppController(
        measurementStore: const _MemoryMeasurementStore(),
        onboardingComplete: true,
      );
      addTearDown(controller.dispose);
      final repository = _FoodEstimateRepository();

      await tester.pumpWidget(
        AppScope(
          controller: controller,
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            theme: buildAppTheme(),
            home: ScanScreen(
              estimateRepository: repository,
              photoPicker: const _FoodPhotoPicker(),
              scanMode: ScanMode.foodPlate,
              autoStart: false,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Food Scale'), findsOneWidget);
      expect(find.text('Photograph one whole plate'), findsOneWidget);

      await tester.tap(find.byKey(const Key('gallery_button')));
      await tester.pumpAndSettle();
      expect(find.text('Confirm the whole meal is visible'), findsOneWidget);

      await tester.tap(find.byKey(const Key('add_details_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('container_Bowl')));
      await tester.enterText(
        find.byKey(const Key('known_dimension_field')),
        '24',
      );
      await tester.scrollUntilVisible(
        find.text('Done').last,
        250,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.tap(find.text('Done').last);
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.byKey(const Key('analyze_button')),
        250,
      );
      await tester.tap(find.byKey(const Key('analyze_button')));
      await tester.pumpAndSettle();

      expect(repository.lastRequest?.scanMode, ScanMode.foodPlate);
      expect(repository.lastRequest?.containerType, 'Bowl');
      expect(repository.lastRequest?.knownDimension?.axis, 'Diameter');
      expect(repository.lastRequest?.knownDimension?.value, 24);
      expect(repository.lastRequest?.knownDimension?.unit, 'cm');
      expect(find.byKey(const Key('food_result_view')), findsOneWidget);
      expect(find.byKey(const Key('food_total_calories')), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const Key('food_result_view')),
          matching: find.text('Partial total'),
        ),
        findsOneWidget,
      );
      expect(find.byKey(const Key('food_component_0')), findsOneWidget);

      final editFirst = find.descendant(
        of: find.byKey(const Key('food_component_0')),
        matching: find.byKey(const Key('edit_food_amount')),
      );
      final foodResultScrollable = find.descendant(
        of: find.byKey(const Key('food_result_view')),
        matching: find.byType(Scrollable),
      );
      await tester.scrollUntilVisible(
        editFirst,
        300,
        scrollable: foodResultScrollable,
      );
      await tester.tap(editFirst);
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('food_amount_field')), '100');
      await tester.tap(find.byKey(const Key('food_amount_save')));
      await tester.pumpAndSettle();

      expect(
        tester.widget<Text>(find.byKey(const Key('result_weight'))).data,
        '280 g',
      );
      expect(
        tester.widget<Text>(find.byKey(const Key('food_total_calories'))).data,
        '165 kcal',
      );

      await tester.scrollUntilVisible(
        find.byKey(const Key('food_component_1')),
        300,
        scrollable: foodResultScrollable,
      );
      final removeSecond = find.descendant(
        of: find.byKey(const Key('food_component_1')),
        matching: find.byKey(const Key('remove_food_item')),
      );
      await tester.scrollUntilVisible(
        removeSecond,
        200,
        scrollable: foodResultScrollable,
      );
      await tester.tap(removeSecond);
      await tester.pump();

      expect(find.byKey(const Key('food_component_1')), findsNothing);
      expect(
        find.descendant(
          of: find.byKey(const Key('food_result_view')),
          matching: find.text('Complete total'),
        ),
        findsOneWidget,
      );
      expect(
        tester.widget<Text>(find.byKey(const Key('result_weight'))).data,
        '100 g',
      );

      await tester.scrollUntilVisible(
        find.byKey(const Key('save_result_button')),
        300,
        scrollable: foodResultScrollable,
      );
      await tester.tap(find.byKey(const Key('save_result_button')));
      await tester.pumpAndSettle();

      expect(controller.measurements, hasLength(1));
      expect(controller.measurements.single.scanMode, ScanMode.foodPlate);
      expect(controller.measurements.single.foodComponents, hasLength(1));
      expect(
        controller.measurements.single.foodComponents.single.userAdjustedGrams,
        100,
      );
    },
  );
}

class _FoodPhotoPicker implements PhotoPicker {
  const _FoodPhotoPicker();

  @override
  Future<String?> pick(PhotoSource source) async => '/tmp/food-plate.jpg';
}

class _FoodEstimateRepository implements EstimateRepository {
  EstimateRequest? lastRequest;

  @override
  Future<Measurement> analyze(EstimateRequest request) async {
    lastRequest = request;
    return Measurement(
      id: 'food-widget-result',
      createdAt: DateTime.utc(2026, 8, 15, 12),
      imagePath: request.imagePath,
      objectLabel: 'Chicken and rice',
      category: 'Food',
      estimateGrams: 380,
      lowerBoundGrams: 300,
      upperBoundGrams: 460,
      confidence: ConfidenceLevel.medium,
      assumptions: const [
        'Standard bowl size',
        'Chicken is boneless',
        'Rice is cooked',
      ],
      scanMode: ScanMode.foodPlate,
      mealLabel: 'Chicken and rice',
      foodComponents: const [
        FoodComponent(
          label: 'Grilled chicken breast',
          estimateGrams: 200,
          lowerBoundGrams: 160,
          upperBoundGrams: 240,
          confidence: ConfidenceLevel.high,
          nutrition: NutritionReference(
            fdcId: 171077,
            description: 'Chicken breast, grilled',
            dataType: 'SR Legacy',
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
          estimateGrams: 180,
          lowerBoundGrams: 140,
          upperBoundGrams: 220,
          confidence: ConfidenceLevel.medium,
        ),
      ],
    );
  }
}

class _MemoryMeasurementStore extends MeasurementStore {
  const _MemoryMeasurementStore();

  @override
  Future<Measurement> persistImage(Measurement measurement) async =>
      measurement;

  @override
  Future<void> saveAll(List<Measurement> measurements) async {}
}
