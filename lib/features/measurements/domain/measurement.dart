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

  Measurement copyWith({
    String? imagePath,
    DimensionsMm? dimensions,
    List<String>? assumptions,
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
    );
  }
}

String formatWeight(double grams, UnitSystem unitSystem) {
  if (unitSystem == UnitSystem.imperial) {
    final ounces = grams / 28.349523125;
    if (ounces < 16) {
      return '${ounces.toStringAsFixed(1)} oz';
    }
    return '${(ounces / 16).toStringAsFixed(2)} lb';
  }

  if (grams < 1000) {
    return '${grams.round()} g';
  }
  return '${(grams / 1000).toStringAsFixed(2)} kg';
}

String formatDimensions(DimensionsMm dimensions, UnitSystem unitSystem) {
  return formatApproximateDimensions(dimensions, unitSystem);
}

/// Formats the AI-inferred vertical axis and unordered horizontal footprint as
/// user-facing length x width x height. The approximation marker is
/// intentional: an uncalibrated photo is not a physical measurement.
String formatApproximateDimensions(
  DimensionsMm dimensions,
  UnitSystem unitSystem,
) {
  final length = dimensions.width > dimensions.depth
      ? dimensions.width
      : dimensions.depth;
  final width = dimensions.width > dimensions.depth
      ? dimensions.depth
      : dimensions.width;

  if (unitSystem == UnitSystem.imperial) {
    const mmPerInch = 25.4;
    return '≈ ${(length / mmPerInch).toStringAsFixed(1)} × '
        '${(width / mmPerInch).toStringAsFixed(1)} × '
        '${(dimensions.height / mmPerInch).toStringAsFixed(1)} in';
  }

  return '≈ ${(length / 10).toStringAsFixed(1)} × '
      '${(width / 10).toStringAsFixed(1)} × '
      '${(dimensions.height / 10).toStringAsFixed(1)} cm';
}

String formatMeasurementDate(DateTime date) {
  final now = DateTime.now();
  final local = date.toLocal();
  final difference = now.difference(local);
  if (difference.inDays == 0) {
    final hour = local.hour == 0
        ? 12
        : local.hour > 12
        ? local.hour - 12
        : local.hour;
    final minute = local.minute.toString().padLeft(2, '0');
    final suffix = local.hour >= 12 ? 'PM' : 'AM';
    return 'Today, $hour:$minute $suffix';
  }
  if (difference.inDays == 1) return 'Yesterday';

  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${months[local.month - 1]} ${local.day}, ${local.year}';
}
