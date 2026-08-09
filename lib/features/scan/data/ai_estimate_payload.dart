import '../../measurements/domain/measurement.dart';

Measurement measurementFromAiEstimatePayload(
  Map<String, Object?> payload,
  String imagePath, {
  String? analysisLocale,
}) {
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
    confidence: ConfidenceLevel.values.byName(_string(payload, 'confidence')),
    dimensions: DimensionsMm(
      width: _number(dimensions, 'width'),
      height: _number(dimensions, 'height'),
      depth: _number(dimensions, 'depth'),
    ),
    assumptions: _stringList(payload, 'assumptions'),
    analysisLocale: analysisLocale,
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

List<String> _stringList(Map<String, Object?> payload, String key) {
  final value = payload[key];
  if (value is! List) {
    throw AiEstimatePayloadException('AI response is missing "$key".');
  }
  final items = value
      .whereType<String>()
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .take(6)
      .toList(growable: false);
  if (items.isEmpty) {
    throw AiEstimatePayloadException('AI response has an empty "$key".');
  }
  return items;
}

class AiEstimatePayloadException implements Exception {
  const AiEstimatePayloadException(this.message);

  final String message;

  @override
  String toString() => message;
}
