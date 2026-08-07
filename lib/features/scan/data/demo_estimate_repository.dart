import 'dart:io';

import '../../measurements/domain/measurement.dart';
import '../domain/estimate_repository.dart';
import '../domain/measured_dimensions.dart';

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
    final preset = _presetFor(seed);
    final fillFactor = switch (request.fillState) {
      'Empty' => 0.72,
      'Partly filled' => 0.9,
      'Full' => 1.18,
      'Solid' => 1.1,
      _ => 1.0,
    };
    final materialFactor = switch (request.material) {
      'Metal' => 1.15,
      'Plastic' || 'Fabric' || 'Cardboard/Paper' => 0.9,
      _ => 1.0,
    };
    final estimate = preset.grams * variation * fillFactor * materialFactor;
    final measured = request.measuredDimensions;
    final hasContext =
        request.material != 'Unknown' ||
        request.fillState != 'Unknown' ||
        request.referenceObject != 'None' ||
        request.knownDimension != null ||
        measured != null ||
        request.secondaryImagePath != null;
    final confidence = hasContext
        ? ConfidenceLevel.medium
        : ConfidenceLevel.low;
    final spread = confidence == ConfidenceLevel.low ? 0.24 : 0.16;
    final dimensionVariation = 0.94 + ((seed % 13) / 100);
    final dimensions = _dimensionsFor(
      preset.dimensions,
      dimensionVariation,
      request.knownDimension,
      measured,
    );

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
      dimensions: dimensions,
      assumptions: [
        request.material == 'Unknown'
            ? 'Material inferred from appearance'
            : '${request.material} material supplied by user',
        request.fillState == 'Unknown'
            ? 'Fill state inferred'
            : '${request.fillState} state supplied by user',
        if (request.knownDimension case final knownDimension?)
          '${knownDimension.axis} supplied as ${knownDimension.value} '
              '${knownDimension.unit}',
        if (measured != null)
          '${measured.formatSummary()} measured with ${measured.sourceLabel}',
        request.referenceObject == 'None'
            ? 'No physical scale reference'
            : '${request.referenceObject} visible as scale reference',
      ],
    );
  }

  _EstimatePreset _presetFor(int seed) {
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

  DimensionsMm _dimensionsFor(
    DimensionsMm base,
    double variation,
    KnownDimensionInput? knownDimension,
    MeasuredDimensions? measured,
  ) {
    final varied = DimensionsMm(
      width: base.width * variation,
      height: base.height * variation,
      depth: base.depth * variation,
    );
    if (measured != null) return measured.mergeWith(varied);
    if (knownDimension == null) return varied;

    final current = switch (knownDimension.axis) {
      'Height' => varied.height,
      'Depth' => varied.depth,
      _ => varied.width,
    };
    final scale = knownDimension.millimeters / current;
    return DimensionsMm(
      width: varied.width * scale,
      height: varied.height * scale,
      depth: varied.depth * scale,
    );
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
