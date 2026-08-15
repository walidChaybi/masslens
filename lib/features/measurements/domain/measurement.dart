import 'package:intl/intl.dart';

enum ConfidenceLevel { low, medium, high }

enum UnitSystem { metric, imperial }

enum ScanMode {
  object('object'),
  foodPlate('food_plate');

  const ScanMode(this.wireValue);

  final String wireValue;

  static ScanMode fromWireValue(Object? value) {
    return switch (value) {
      'food_plate' || 'foodPlate' => ScanMode.foodPlate,
      _ => ScanMode.object,
    };
  }
}

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

class NutritionPer100g {
  const NutritionPer100g({
    required this.caloriesKcal,
    required this.proteinGrams,
    required this.carbsGrams,
    required this.fatGrams,
  });

  final double caloriesKcal;
  final double proteinGrams;
  final double carbsGrams;
  final double fatGrams;

  NutritionTotals forWeight(double grams) {
    final multiplier = grams / 100;
    return NutritionTotals(
      caloriesKcal: caloriesKcal * multiplier,
      proteinGrams: proteinGrams * multiplier,
      carbsGrams: carbsGrams * multiplier,
      fatGrams: fatGrams * multiplier,
    );
  }

  Map<String, Object> toJson() => {
    'caloriesKcal': caloriesKcal,
    'proteinGrams': proteinGrams,
    'carbsGrams': carbsGrams,
    'fatGrams': fatGrams,
  };

  factory NutritionPer100g.fromJson(Map<String, Object?> json) {
    return NutritionPer100g(
      caloriesKcal: _jsonNumber(json, 'caloriesKcal'),
      proteinGrams: _jsonNumber(json, 'proteinGrams'),
      carbsGrams: _jsonNumber(json, 'carbsGrams'),
      fatGrams: _jsonNumber(json, 'fatGrams'),
    );
  }
}

class NutritionReference {
  const NutritionReference({
    required this.fdcId,
    required this.description,
    required this.dataType,
    required this.per100g,
  });

  final int fdcId;
  final String description;
  final String dataType;
  final NutritionPer100g per100g;

  double get caloriesKcalPer100g => per100g.caloriesKcal;
  double get proteinGramsPer100g => per100g.proteinGrams;
  double get carbsGramsPer100g => per100g.carbsGrams;
  double get fatGramsPer100g => per100g.fatGrams;

  Map<String, Object> toJson() => {
    'fdcId': fdcId,
    'description': description,
    'dataType': dataType,
    'per100g': per100g.toJson(),
  };

  factory NutritionReference.fromJson(Map<String, Object?> json) {
    return NutritionReference(
      fdcId: _jsonInteger(json, 'fdcId'),
      description: _jsonString(json, 'description'),
      dataType: _jsonString(json, 'dataType'),
      per100g: NutritionPer100g.fromJson(
        Map<String, Object?>.from(json['per100g']! as Map),
      ),
    );
  }
}

class NutritionTotals {
  const NutritionTotals({
    required this.caloriesKcal,
    required this.proteinGrams,
    required this.carbsGrams,
    required this.fatGrams,
  });

  static const zero = NutritionTotals(
    caloriesKcal: 0,
    proteinGrams: 0,
    carbsGrams: 0,
    fatGrams: 0,
  );

  final double caloriesKcal;
  final double proteinGrams;
  final double carbsGrams;
  final double fatGrams;

  NutritionTotals operator +(NutritionTotals other) {
    return NutritionTotals(
      caloriesKcal: caloriesKcal + other.caloriesKcal,
      proteinGrams: proteinGrams + other.proteinGrams,
      carbsGrams: carbsGrams + other.carbsGrams,
      fatGrams: fatGrams + other.fatGrams,
    );
  }
}

const _notProvided = Object();

class FoodComponent {
  const FoodComponent({
    required this.label,
    required this.estimateGrams,
    required this.lowerBoundGrams,
    required this.upperBoundGrams,
    required this.confidence,
    this.nutrition,
    this.userAdjustedGrams,
  });

  final String label;
  final double estimateGrams;
  final double lowerBoundGrams;
  final double upperBoundGrams;
  final ConfidenceLevel confidence;
  final NutritionReference? nutrition;
  final double? userAdjustedGrams;

  double get effectiveGrams => userAdjustedGrams ?? estimateGrams;

  NutritionTotals? get effectiveNutrition =>
      nutrition?.per100g.forWeight(effectiveGrams);

  NutritionTotals? get lowerBoundNutrition =>
      nutrition?.per100g.forWeight(lowerBoundGrams);

  NutritionTotals? get upperBoundNutrition =>
      nutrition?.per100g.forWeight(upperBoundGrams);

  FoodComponent copyWith({
    String? label,
    double? estimateGrams,
    double? lowerBoundGrams,
    double? upperBoundGrams,
    ConfidenceLevel? confidence,
    Object? nutrition = _notProvided,
    Object? userAdjustedGrams = _notProvided,
  }) {
    return FoodComponent(
      label: label ?? this.label,
      estimateGrams: estimateGrams ?? this.estimateGrams,
      lowerBoundGrams: lowerBoundGrams ?? this.lowerBoundGrams,
      upperBoundGrams: upperBoundGrams ?? this.upperBoundGrams,
      confidence: confidence ?? this.confidence,
      nutrition: identical(nutrition, _notProvided)
          ? this.nutrition
          : nutrition as NutritionReference?,
      userAdjustedGrams: identical(userAdjustedGrams, _notProvided)
          ? this.userAdjustedGrams
          : userAdjustedGrams as double?,
    );
  }

  Map<String, Object?> toJson() => {
    'label': label,
    'estimateGrams': estimateGrams,
    'lowerBoundGrams': lowerBoundGrams,
    'upperBoundGrams': upperBoundGrams,
    'confidence': confidence.name,
    if (nutrition != null) 'nutrition': nutrition!.toJson(),
    if (userAdjustedGrams != null) 'userAdjustedGrams': userAdjustedGrams,
  };

  factory FoodComponent.fromJson(Map<String, Object?> json) {
    final nutritionPayload = json['nutrition'];
    return FoodComponent(
      label: _jsonString(json, 'label'),
      estimateGrams: _jsonNumber(json, 'estimateGrams'),
      lowerBoundGrams: _jsonNumber(json, 'lowerBoundGrams'),
      upperBoundGrams: _jsonNumber(json, 'upperBoundGrams'),
      confidence: ConfidenceLevel.values.byName(
        _jsonString(json, 'confidence'),
      ),
      nutrition: nutritionPayload is Map
          ? NutritionReference.fromJson(
              Map<String, Object?>.from(nutritionPayload),
            )
          : null,
      userAdjustedGrams: (json['userAdjustedGrams'] as num?)?.toDouble(),
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
    this.dimensions,
    required this.assumptions,
    this.analysisLocale,
    this.scanMode = ScanMode.object,
    this.mealLabel,
    this.foodComponents = const [],
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
  final DimensionsMm? dimensions;
  final List<String> assumptions;
  final String? analysisLocale;
  final ScanMode scanMode;
  final String? mealLabel;
  final List<FoodComponent> foodComponents;

  bool get isFoodPlate => scanMode == ScanMode.foodPlate;

  double get totalEstimateGrams => isFoodPlate
      ? foodComponents.fold(0, (sum, item) => sum + item.effectiveGrams)
      : estimateGrams;

  double get totalLowerBoundGrams => isFoodPlate
      ? foodComponents.fold(0, (sum, item) => sum + item.lowerBoundGrams)
      : lowerBoundGrams;

  double get totalUpperBoundGrams => isFoodPlate
      ? foodComponents.fold(0, (sum, item) => sum + item.upperBoundGrams)
      : upperBoundGrams;

  bool get hasNutritionData =>
      foodComponents.any((item) => item.nutrition != null);

  bool get hasPartialNutrition =>
      isFoodPlate && foodComponents.any((item) => item.nutrition == null);

  NutritionTotals get nutritionTotals =>
      _sumNutrition(foodComponents.map((item) => item.effectiveNutrition));

  NutritionTotals get lowerBoundNutritionTotals =>
      _sumNutrition(foodComponents.map((item) => item.lowerBoundNutrition));

  NutritionTotals get upperBoundNutritionTotals =>
      _sumNutrition(foodComponents.map((item) => item.upperBoundNutrition));

  double? get calorieLowerBoundKcal =>
      hasNutritionData ? lowerBoundNutritionTotals.caloriesKcal : null;

  double? get calorieUpperBoundKcal =>
      hasNutritionData ? upperBoundNutritionTotals.caloriesKcal : null;

  Measurement copyWith({
    String? imagePath,
    String? objectLabel,
    String? category,
    double? estimateGrams,
    double? lowerBoundGrams,
    double? upperBoundGrams,
    ConfidenceLevel? confidence,
    Object? dimensions = _notProvided,
    List<String>? assumptions,
    Object? analysisLocale = _notProvided,
    ScanMode? scanMode,
    Object? mealLabel = _notProvided,
    List<FoodComponent>? foodComponents,
  }) {
    final nextMode = scanMode ?? this.scanMode;
    final nextFoodComponents = foodComponents ?? this.foodComponents;
    final recomputeFoodTotals =
        nextMode == ScanMode.foodPlate && foodComponents != null;
    return Measurement(
      id: id,
      createdAt: createdAt,
      imagePath: imagePath ?? this.imagePath,
      objectLabel: objectLabel ?? this.objectLabel,
      category: category ?? this.category,
      estimateGrams:
          estimateGrams ??
          (recomputeFoodTotals
              ? nextFoodComponents.fold(
                  0,
                  (sum, item) => sum + item.effectiveGrams,
                )
              : this.estimateGrams),
      lowerBoundGrams:
          lowerBoundGrams ??
          (recomputeFoodTotals
              ? nextFoodComponents.fold(
                  0,
                  (sum, item) => sum + item.lowerBoundGrams,
                )
              : this.lowerBoundGrams),
      upperBoundGrams:
          upperBoundGrams ??
          (recomputeFoodTotals
              ? nextFoodComponents.fold(
                  0,
                  (sum, item) => sum + item.upperBoundGrams,
                )
              : this.upperBoundGrams),
      confidence: confidence ?? this.confidence,
      dimensions: identical(dimensions, _notProvided)
          ? this.dimensions
          : dimensions as DimensionsMm?,
      assumptions: assumptions ?? this.assumptions,
      analysisLocale: identical(analysisLocale, _notProvided)
          ? this.analysisLocale
          : analysisLocale as String?,
      scanMode: nextMode,
      mealLabel: identical(mealLabel, _notProvided)
          ? this.mealLabel
          : mealLabel as String?,
      foodComponents: nextFoodComponents,
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
    if (dimensions != null) 'dimensions': dimensions!.toJson(),
    'assumptions': assumptions,
    if (analysisLocale != null) 'analysisLocale': analysisLocale,
    'scanMode': scanMode.wireValue,
    if (mealLabel != null) 'mealLabel': mealLabel,
    if (foodComponents.isNotEmpty)
      'foodComponents': foodComponents.map((item) => item.toJson()).toList(),
  };

  factory Measurement.fromJson(Map<String, Object?> json) {
    final dimensionsPayload = json['dimensions'];
    final componentsPayload = json['foodComponents'];
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
      dimensions: dimensionsPayload is Map
          ? DimensionsMm.fromJson(Map<String, Object?>.from(dimensionsPayload))
          : null,
      assumptions: List<String>.from(json['assumptions']! as List),
      analysisLocale: json['analysisLocale'] as String?,
      scanMode: ScanMode.fromWireValue(json['scanMode']),
      mealLabel: json['mealLabel'] as String?,
      foodComponents: componentsPayload is List
          ? componentsPayload
                .whereType<Map>()
                .map(
                  (item) =>
                      FoodComponent.fromJson(Map<String, Object?>.from(item)),
                )
                .toList(growable: false)
          : const [],
    );
  }
}

NutritionTotals _sumNutrition(Iterable<NutritionTotals?> values) {
  return values.whereType<NutritionTotals>().fold(
    NutritionTotals.zero,
    (sum, value) => sum + value,
  );
}

double _jsonNumber(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is num && value.isFinite) return value.toDouble();
  throw FormatException('Invalid numeric value for "$key".');
}

int _jsonInteger(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is int) return value;
  if (value is num && value.isFinite && value == value.roundToDouble()) {
    return value.toInt();
  }
  throw FormatException('Invalid integer value for "$key".');
}

String _jsonString(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is String && value.trim().isNotEmpty) return value.trim();
  throw FormatException('Invalid string value for "$key".');
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
