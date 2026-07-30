import 'dart:io';

import '../../measurements/domain/measurement.dart';
import '../domain/estimate_repository.dart';

class DemoEstimateRepository implements EstimateRepository {
  const DemoEstimateRepository({
    this.analysisDelay = const Duration(seconds: 2),
  });

  final Duration analysisDelay;

  @override
  Future<Measurement> analyze(EstimateRequest request) async {
    await Future<void>.delayed(analysisDelay);

    final file = File(request.imagePath);
    final fileSize = await file.exists() ? await file.length() : 42;
    final seed =
        fileSize +
        request.imagePath.codeUnits.fold<int>(0, (sum, value) => sum + value);
    final variation = 0.88 + ((seed % 25) / 100);
    final preset = _presetFor(request.category, seed);
    final structureFactor = switch (request.structure) {
      'Hollow' => 0.82,
      'Solid' => 1.12,
      _ => 1.0,
    };
    final estimate = preset.grams * variation * structureFactor;
    final confidence = request.category == 'Auto'
        ? ConfidenceLevel.low
        : ConfidenceLevel.medium;
    final spread = confidence == ConfidenceLevel.low ? 0.24 : 0.16;
    final dimensionVariation = 0.94 + ((seed % 13) / 100);

    return Measurement(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      createdAt: DateTime.now(),
      imagePath: request.imagePath,
      objectLabel: preset.label,
      category: preset.category,
      estimateGrams: estimate,
      lowerBoundGrams: estimate * (1 - spread),
      upperBoundGrams: estimate * (1 + spread),
      confidence: confidence,
      dimensions: DimensionsMm(
        width: preset.dimensions.width * dimensionVariation,
        height: preset.dimensions.height * dimensionVariation,
        depth: preset.dimensions.depth * dimensionVariation,
      ),
      assumptions: [
        request.structure == 'Unknown'
            ? 'Internal structure inferred'
            : '${request.structure.toLowerCase()} construction',
        'No physical scale reference',
        'Typical ${preset.category.toLowerCase()} density',
      ],
    );
  }

  _EstimatePreset _presetFor(String category, int seed) {
    if (category != 'Auto') {
      return switch (category) {
        'Food' => const _EstimatePreset(
          label: 'Fresh produce',
          category: 'Food',
          grams: 920,
          dimensions: DimensionsMm(width: 180, height: 135, depth: 145),
        ),
        'Parcel' => const _EstimatePreset(
          label: 'Shipping parcel',
          category: 'Parcel',
          grams: 2450,
          dimensions: DimensionsMm(width: 360, height: 240, depth: 280),
        ),
        'Furniture' => const _EstimatePreset(
          label: 'Compact side chair',
          category: 'Furniture',
          grams: 6300,
          dimensions: DimensionsMm(width: 480, height: 820, depth: 510),
        ),
        'Electronics' => const _EstimatePreset(
          label: 'Portable electronic device',
          category: 'Electronics',
          grams: 780,
          dimensions: DimensionsMm(width: 245, height: 165, depth: 28),
        ),
        _ => const _EstimatePreset(
          label: 'Household object',
          category: 'Other',
          grams: 1350,
          dimensions: DimensionsMm(width: 260, height: 190, depth: 170),
        ),
      };
    }

    const presets = [
      _EstimatePreset(
        label: 'Hard-shell carry-on',
        category: 'Luggage',
        grams: 3200,
        dimensions: DimensionsMm(width: 355, height: 550, depth: 230),
      ),
      _EstimatePreset(
        label: 'Wooden dining chair',
        category: 'Furniture',
        grams: 5900,
        dimensions: DimensionsMm(width: 455, height: 850, depth: 505),
      ),
      _EstimatePreset(
        label: 'Fresh melon',
        category: 'Food',
        grams: 1280,
        dimensions: DimensionsMm(width: 195, height: 170, depth: 185),
      ),
      _EstimatePreset(
        label: 'Packed delivery box',
        category: 'Parcel',
        grams: 2100,
        dimensions: DimensionsMm(width: 330, height: 220, depth: 250),
      ),
    ];
    return presets[seed % presets.length];
  }
}

class _EstimatePreset {
  const _EstimatePreset({
    required this.label,
    required this.category,
    required this.grams,
    required this.dimensions,
  });

  final String label;
  final String category;
  final double grams;
  final DimensionsMm dimensions;
}
