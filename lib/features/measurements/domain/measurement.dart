import 'package:intl/intl.dart';

enum ConfidenceLevel { low, medium, high }

enum UnitSystem { metric, imperial }

class DimensionsMm {
  const DimensionsMm({
    required this.width,
    required this.height,
    required this.depth,
  });

  final double width;
  final double height;
  final double depth;

  Map<String, Object> toJson() => {
    'width': width,
    'height': height,
    'depth': depth,
  };

  factory DimensionsMm.fromJson(Map<String, Object?> json) {
    return DimensionsMm(
      width: (json['width'] as num).toDouble(),
      height: (json['height'] as num).toDouble(),
      depth: (json['depth'] as num).toDouble(),
    );
  }
}

class Measurement {
  const Measurement({
    required this.id,
    required this.createdAt,
    required this.imagePath,
    required this.objectLabel,
    required this.category,
    required this.estimateGrams,
    required this.lowerBoundGrams,
    required this.upperBoundGrams,
    required this.confidence,
    required this.dimensions,
    required this.assumptions,
    this.analysisLocale,
  });

  final String id;
  final DateTime createdAt;
  final String imagePath;
  final String objectLabel;
  final String category;
  final double estimateGrams;
  final double lowerBoundGrams;
  final double upperBoundGrams;
  final ConfidenceLevel confidence;
  final DimensionsMm dimensions;
  final List<String> assumptions;
  final String? analysisLocale;

  Measurement copyWith({
    String? imagePath,
    DimensionsMm? dimensions,
    List<String>? assumptions,
    String? analysisLocale,
  }) {
    return Measurement(
      id: id,
      createdAt: createdAt,
      imagePath: imagePath ?? this.imagePath,
      objectLabel: objectLabel,
      category: category,
      estimateGrams: estimateGrams,
      lowerBoundGrams: lowerBoundGrams,
      upperBoundGrams: upperBoundGrams,
      confidence: confidence,
      dimensions: dimensions ?? this.dimensions,
      assumptions: assumptions ?? this.assumptions,
      analysisLocale: analysisLocale ?? this.analysisLocale,
    );
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'createdAt': createdAt.toIso8601String(),
    'imagePath': imagePath,
    'objectLabel': objectLabel,
    'category': category,
    'estimateGrams': estimateGrams,
    'lowerBoundGrams': lowerBoundGrams,
    'upperBoundGrams': upperBoundGrams,
    'confidence': confidence.name,
    'dimensions': dimensions.toJson(),
    'assumptions': assumptions,
    if (analysisLocale != null) 'analysisLocale': analysisLocale,
  };

  factory Measurement.fromJson(Map<String, Object?> json) {
    return Measurement(
      id: json['id']! as String,
      createdAt: DateTime.parse(json['createdAt']! as String),
      imagePath: json['imagePath']! as String,
      objectLabel: json['objectLabel']! as String,
      category: json['category']! as String,
      estimateGrams: (json['estimateGrams'] as num).toDouble(),
      lowerBoundGrams: (json['lowerBoundGrams'] as num).toDouble(),
      upperBoundGrams: (json['upperBoundGrams'] as num).toDouble(),
      confidence: ConfidenceLevel.values.byName(json['confidence']! as String),
      dimensions: DimensionsMm.fromJson(
        Map<String, Object?>.from(json['dimensions']! as Map),
      ),
      assumptions: List<String>.from(json['assumptions']! as List),
      analysisLocale: json['analysisLocale'] as String?,
    );
  }
}

String formatWeight(double grams, UnitSystem unitSystem, {String? localeName}) {
  final locale = localeName ?? 'en';
  if (unitSystem == UnitSystem.imperial) {
    final ounces = grams / 28.349523125;
    if (ounces < 16) {
      return '${NumberFormat('0.0', locale).format(ounces)} oz';
    }
    return '${NumberFormat('0.00', locale).format(ounces / 16)} lb';
  }

  if (grams < 1000) {
    return '${NumberFormat('0', locale).format(grams)} g';
  }
  return '${NumberFormat('0.00', locale).format(grams / 1000)} kg';
}

String formatDimensions(
  DimensionsMm dimensions,
  UnitSystem unitSystem, {
  String? localeName,
}) {
  return formatApproximateDimensions(
    dimensions,
    unitSystem,
    localeName: localeName,
  );
}

/// Formats the AI-inferred vertical axis and unordered horizontal footprint as
/// user-facing length x width x height. The approximation marker is
/// intentional: an uncalibrated photo is not a physical measurement.
String formatApproximateDimensions(
  DimensionsMm dimensions,
  UnitSystem unitSystem, {
  String? localeName,
}) {
  final formatter = NumberFormat('0.0', localeName ?? 'en');
  final length = dimensions.width > dimensions.depth
      ? dimensions.width
      : dimensions.depth;
  final width = dimensions.width > dimensions.depth
      ? dimensions.depth
      : dimensions.width;

  if (unitSystem == UnitSystem.imperial) {
    const mmPerInch = 25.4;
    return '≈ ${formatter.format(length / mmPerInch)} × '
        '${formatter.format(width / mmPerInch)} × '
        '${formatter.format(dimensions.height / mmPerInch)} in';
  }

  return '≈ ${formatter.format(length / 10)} × '
      '${formatter.format(width / 10)} × '
      '${formatter.format(dimensions.height / 10)} cm';
}

String formatMeasurementDate(
  DateTime date, {
  String? localeName,
  String todayLabel = 'Today',
  String yesterdayLabel = 'Yesterday',
}) {
  final now = DateTime.now();
  final local = date.toLocal();
  final locale = localeName ?? 'en';
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(local.year, local.month, local.day);
  final difference = today.difference(day).inDays;
  if (difference == 0) {
    return '$todayLabel, ${DateFormat.jm(locale).format(local)}';
  }
  if (difference == 1) return yesterdayLabel;
  return DateFormat.yMMMd(locale).format(local);
}
