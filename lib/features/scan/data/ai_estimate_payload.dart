import '../../measurements/domain/measurement.dart';

Measurement measurementFromAiEstimatePayload(
  Map<String, Object?> payload,
  String imagePath, {
  String? analysisLocale,
  ScanMode scanMode = ScanMode.object,
}) {
  if (scanMode == ScanMode.foodPlate) {
    return _foodMeasurementFromPayload(
      payload,
      imagePath,
      analysisLocale: analysisLocale,
    );
  }

  final dimensionsPayload = payload['dimensions_mm'];
  if (dimensionsPayload is! Map) {
    throw const AiEstimatePayloadException(
      'AI response is missing "dimensions_mm".',
    );
  }
  final dimensions = Map<String, Object?>.from(dimensionsPayload);
  final estimate = _number(payload, 'estimate_grams');
  final lowerBound = _number(payload, 'lower_bound_grams');
  final upperBound = _number(payload, 'upper_bound_grams');
  final now = DateTime.now();

  return Measurement(
    id: now.microsecondsSinceEpoch.toString(),
    createdAt: now,
    imagePath: imagePath,
    objectLabel: _string(payload, 'object_label'),
    category: _string(payload, 'category'),
    estimateGrams: estimate,
    lowerBoundGrams: lowerBound > estimate ? estimate : lowerBound,
    upperBoundGrams: upperBound < estimate ? estimate : upperBound,
    confidence: _confidence(payload, 'confidence'),
    dimensions: DimensionsMm(
      width: _number(dimensions, 'width'),
      height: _number(dimensions, 'height'),
      depth: _number(dimensions, 'depth'),
    ),
    assumptions: _stringList(payload, 'assumptions'),
    analysisLocale: analysisLocale,
  );
}

Measurement _foodMeasurementFromPayload(
  Map<String, Object?> payload,
  String imagePath, {
  String? analysisLocale,
}) {
  final itemsPayload = payload['items'];
  if (itemsPayload is! List ||
      itemsPayload.isEmpty ||
      itemsPayload.length > 6) {
    throw const AiEstimatePayloadException(
      'AI response must include between one and six food items.',
    );
  }

  final items = <FoodComponent>[];
  for (final itemPayload in itemsPayload) {
    if (itemPayload is! Map) {
      throw const AiEstimatePayloadException(
        'AI response contains an invalid food item.',
      );
    }
    final item = Map<String, Object?>.from(itemPayload);
    final estimate = _number(item, 'estimate_grams');
    final lowerBound = _number(item, 'lower_bound_grams');
    final upperBound = _number(item, 'upper_bound_grams');
    final nutritionPayload = item['nutrition'];
    if (nutritionPayload != null && nutritionPayload is! Map) {
      throw const AiEstimatePayloadException(
        'AI response contains invalid food nutrition data.',
      );
    }
    items.add(
      FoodComponent(
        label: _string(item, 'label'),
        estimateGrams: estimate,
        lowerBoundGrams: lowerBound > estimate ? estimate : lowerBound,
        upperBoundGrams: upperBound < estimate ? estimate : upperBound,
        confidence: _confidence(item, 'confidence'),
        nutrition: nutritionPayload is Map
            ? _nutritionFromPayload(Map<String, Object?>.from(nutritionPayload))
            : null,
      ),
    );
  }

  if (!items.any((item) => item.nutrition != null)) {
    throw const AiEstimatePayloadException(
      'AI response did not include nutrition for any food item.',
    );
  }

  final mealLabel = _string(payload, 'meal_label');
  final now = DateTime.now();
  return Measurement(
    id: now.microsecondsSinceEpoch.toString(),
    createdAt: now,
    imagePath: imagePath,
    objectLabel: mealLabel,
    category: 'Food',
    estimateGrams: items.fold(0, (sum, item) => sum + item.estimateGrams),
    lowerBoundGrams: items.fold(0, (sum, item) => sum + item.lowerBoundGrams),
    upperBoundGrams: items.fold(0, (sum, item) => sum + item.upperBoundGrams),
    confidence: _confidence(payload, 'confidence'),
    assumptions: _stringList(payload, 'assumptions', exactCount: 3),
    analysisLocale: analysisLocale,
    scanMode: ScanMode.foodPlate,
    mealLabel: mealLabel,
    foodComponents: items,
  );
}

NutritionReference _nutritionFromPayload(Map<String, Object?> payload) {
  return NutritionReference(
    fdcId: _integer(payload, 'fdc_id'),
    description: _string(payload, 'description'),
    dataType: _string(payload, 'data_type'),
    per100g: NutritionPer100g(
      caloriesKcal: _number(payload, 'calories_kcal_per_100g'),
      proteinGrams: _number(payload, 'protein_grams_per_100g'),
      carbsGrams: _number(payload, 'carbs_grams_per_100g'),
      fatGrams: _number(payload, 'fat_grams_per_100g'),
    ),
  );
}

Map<String, Object?> mapFromUnknownPayload(Object? value) {
  if (value is! Map) {
    throw const AiEstimatePayloadException('AI response was not an object.');
  }
  return Map<String, Object?>.from(value);
}

String mimeTypeForImagePath(String path) {
  final lower = path.toLowerCase();
  if (lower.endsWith('.png')) return 'image/png';
  if (lower.endsWith('.webp')) return 'image/webp';
  if (lower.endsWith('.heic') || lower.endsWith('.heif')) return 'image/heic';
  return 'image/jpeg';
}

String _string(Map<String, Object?> payload, String key) {
  final value = payload[key];
  if (value is String && value.trim().isNotEmpty) return value.trim();
  throw AiEstimatePayloadException('AI response is missing "$key".');
}

double _number(Map<String, Object?> payload, String key) {
  final value = payload[key];
  if (value is num && value.isFinite && value >= 0) {
    return value.toDouble();
  }
  throw AiEstimatePayloadException('AI response has an invalid "$key".');
}

int _integer(Map<String, Object?> payload, String key) {
  final value = payload[key];
  if (value is int && value > 0) return value;
  if (value is num &&
      value.isFinite &&
      value > 0 &&
      value == value.roundToDouble()) {
    return value.toInt();
  }
  throw AiEstimatePayloadException('AI response has an invalid "$key".');
}

ConfidenceLevel _confidence(Map<String, Object?> payload, String key) {
  return switch (_string(payload, key)) {
    'low' => ConfidenceLevel.low,
    'medium' => ConfidenceLevel.medium,
    'high' => ConfidenceLevel.high,
    _ => throw AiEstimatePayloadException('AI response has an invalid "$key".'),
  };
}

List<String> _stringList(
  Map<String, Object?> payload,
  String key, {
  int? exactCount,
}) {
  final value = payload[key];
  if (value is! List) {
    throw AiEstimatePayloadException('AI response is missing "$key".');
  }
  if (exactCount != null && value.length != exactCount) {
    throw AiEstimatePayloadException(
      'AI response must include exactly $exactCount values for "$key".',
    );
  }
  final items = value
      .whereType<String>()
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .toList(growable: false);
  if (items.isEmpty) {
    throw AiEstimatePayloadException('AI response has an empty "$key".');
  }
  if (exactCount != null &&
      (items.length != value.length || items.length != exactCount)) {
    throw AiEstimatePayloadException(
      'AI response has invalid values for "$key".',
    );
  }
  return items.take(6).toList(growable: false);
}

class AiEstimatePayloadException implements Exception {
  const AiEstimatePayloadException(this.message);

  final String message;

  @override
  String toString() => message;
}
