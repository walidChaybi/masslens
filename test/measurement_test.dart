import 'package:flutter_test/flutter_test.dart';
import 'package:mass_lens/features/measurements/domain/measurement.dart';
import 'package:mass_lens/features/monetization/data/monetization_config.dart';
import 'package:mass_lens/features/scan/data/ai_estimate_payload.dart';
import 'package:mass_lens/features/scan/data/demo_estimate_repository.dart';
import 'package:mass_lens/features/scan/data/estimate_repository_factory.dart';
import 'package:mass_lens/features/scan/domain/estimate_repository.dart';
import 'package:mass_lens/features/scan/domain/measured_dimensions.dart';

void main() {
  test('measurement survives JSON round trip', () {
    final measurement = Measurement(
      id: 'm-1',
      createdAt: DateTime.utc(2026, 7, 30, 8, 15),
      imagePath: '/tmp/object.jpg',
      objectLabel: 'Shipping parcel',
      category: 'Parcel',
      estimateGrams: 2500,
      lowerBoundGrams: 2100,
      upperBoundGrams: 2900,
      confidence: ConfidenceLevel.medium,
      dimensions: const DimensionsMm(width: 320, height: 220, depth: 260),
      assumptions: const ['Hollow construction'],
    );

    final restored = Measurement.fromJson(measurement.toJson());

    expect(restored.id, measurement.id);
    expect(restored.createdAt, measurement.createdAt);
    expect(restored.estimateGrams, measurement.estimateGrams);
    expect(restored.dimensions.width, 320);
    expect(restored.assumptions, ['Hollow construction']);
  });

  test('weight formatting uses canonical grams for both unit systems', () {
    expect(formatWeight(750, UnitSystem.metric), '750 g');
    expect(formatWeight(2500, UnitSystem.metric), '2.50 kg');
    expect(formatWeight(453.59237, UnitSystem.imperial), '1.00 lb');
  });

  test('demo repository returns a range containing its estimate', () async {
    const repository = DemoEstimateRepository(analysisDelay: Duration.zero);
    final result = await repository.analyze(
      const EstimateRequest(
        imagePath: '/tmp/non-existent.jpg',
        material: 'Wood',
        fillState: 'Solid',
        referenceObject: 'Ruler',
        knownDimension: KnownDimensionInput(
          axis: 'Height',
          value: 85,
          unit: 'cm',
        ),
      ),
    );

    expect(result.confidence, ConfidenceLevel.medium);
    expect(result.lowerBoundGrams, lessThan(result.estimateGrams));
    expect(result.upperBoundGrams, greaterThan(result.estimateGrams));
    expect(result.dimensions.height, closeTo(850, 0.001));
    expect(result.assumptions, contains('Wood material supplied by user'));
    expect(result.assumptions, contains('Ruler visible as scale reference'));
  });

  test('repository factory keeps demo mode by default', () {
    expect(EstimateEngineConfig.isAiEnabled, isFalse);
    expect(buildEstimateRepository(), isA<DemoEstimateRepository>());
  });

  test(
    'measured axes override inferred dimensions without changing confidence',
    () async {
      const repository = DemoEstimateRepository(analysisDelay: Duration.zero);
      final result = await repository.analyze(
        const EstimateRequest(
          imagePath: '/tmp/non-existent.jpg',
          measuredDimensions: MeasuredDimensions(
            widthMm: 320,
            heightMm: 210,
            method: MeasurementMethod.arCoreDepth,
          ),
        ),
      );

      expect(result.dimensions.width, 320);
      expect(result.dimensions.height, 210);
      expect(result.dimensions.depth, greaterThan(0));
      expect(result.confidence, ConfidenceLevel.medium);
      expect(
        result.assumptions,
        contains('32.0 × 21.0 cm measured with AR depth'),
      );
    },
  );

  test('launch catalog contains only Basic and Max scan packs', () {
    expect(MonetizationConfig.packs.map((pack) => pack.productId), [
      'masslens_100_scans',
      'masslens_500_scans',
    ]);
    expect(MonetizationConfig.packs.map((pack) => pack.scanCredits), [
      100,
      500,
    ]);
  });

  test('AI payload maps to a non-demo measurement', () {
    final measurement = measurementFromAiEstimatePayload(
      {
        'object_label': 'Ceramic mug',
        'category': 'Household',
        'estimate_grams': 360,
        'lower_bound_grams': 290,
        'upper_bound_grams': 450,
        'confidence': 'medium',
        'dimensions_mm': {'width': 85, 'height': 105, 'depth': 85},
        'assumptions': ['No visible scale reference'],
      },
      '/tmp/mug.jpg',
      isDemo: false,
    );

    expect(measurement.isDemo, isFalse);
    expect(measurement.objectLabel, 'Ceramic mug');
    expect(measurement.estimateGrams, 360);
    expect(measurement.dimensions.height, 105);
  });
}
