import 'package:flutter_test/flutter_test.dart';
import 'package:mass_lens/features/measurements/domain/measurement.dart';
import 'package:mass_lens/features/monetization/domain/access_status.dart';
import 'package:mass_lens/features/scan/data/ai_estimate_payload.dart';
import 'package:mass_lens/features/scan/data/cloudflare_estimate_repository.dart';
import 'package:mass_lens/features/scan/data/estimate_repository_factory.dart';

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

  test('AI size is approximate and displays length x width x height', () {
    const dimensions = DimensionsMm(width: 180, height: 90, depth: 300);

    expect(
      formatApproximateDimensions(dimensions, UnitSystem.metric),
      '≈ 30.0 × 18.0 × 9.0 cm',
    );
    expect(
      formatApproximateDimensions(dimensions, UnitSystem.imperial),
      '≈ 11.8 × 7.1 × 3.5 in',
    );
  });

  test('repository factory always uses the real cloud AI path', () {
    expect(EstimateEngineConfig.isAiEnabled, isTrue);
    expect(buildEstimateRepository(), isA<CloudflareEstimateRepository>());
    expect(EstimateEngineConfig.productionModelLabel, 'gpt-5-nano');
  });

  test('ads-only access has three starters and a rewarded balance cap', () {
    const access = AccessStatus.fallback();
    expect(access.starterScansRemaining, 3);
    expect(access.rewardBalanceCap, 3);
    expect(access.rewardedScans, 0);
    expect(access.canScan, isFalse);

    final enforced = AccessStatus.fromJson(const {
      'starterScansRemaining': 3,
      'rewardedScans': 0,
      'legacyScans': 0,
      'remainingScans': 3,
      'rewardBalanceCap': 3,
      'scanAccessEnforced': true,
      'adsEnabled': true,
    });
    expect(enforced.canScan, isTrue);

    final preview = AccessStatus.fromJson(const {
      'remainingScans': 3,
      'scanAccessEnforced': false,
      'adsEnabled': false,
    });
    expect(preview.canScan, isFalse);
  });

  test('server ad policy enforces scan cadence and cooldowns', () {
    const policy = AdPolicy();
    final now = DateTime.utc(2026, 8, 8, 12);
    expect(
      policy.shouldShowInterstitial(completedScanCount: 1, now: now),
      isFalse,
    );
    expect(
      policy.shouldShowInterstitial(completedScanCount: 2, now: now),
      isTrue,
    );
    expect(
      policy.shouldShowInterstitial(
        completedScanCount: 4,
        now: now,
        lastShownAt: now.subtract(const Duration(seconds: 179)),
      ),
      isFalse,
    );
    expect(
      policy.shouldShowAppOpen(
        backgroundTime: const Duration(hours: 3),
        now: now,
      ),
      isFalse,
    );
    expect(
      policy.shouldShowAppOpen(
        backgroundTime: const Duration(hours: 4),
        now: now,
      ),
      isTrue,
    );
  });

  test('AI payload maps to a non-demo measurement', () {
    final measurement = measurementFromAiEstimatePayload({
      'object_label': 'Ceramic mug',
      'category': 'Household',
      'estimate_grams': 360,
      'lower_bound_grams': 290,
      'upper_bound_grams': 450,
      'confidence': 'medium',
      'dimensions_mm': {'width': 85, 'height': 105, 'depth': 85},
      'assumptions': ['No visible scale reference'],
    }, '/tmp/mug.jpg');

    expect(measurement.objectLabel, 'Ceramic mug');
    expect(measurement.estimateGrams, 360);
    expect(measurement.dimensions.height, 105);
  });
}
