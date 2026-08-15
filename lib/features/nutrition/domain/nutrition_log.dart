import '../../measurements/domain/measurement.dart';

enum MealType { breakfast, lunch, dinner, snack }

extension MealTypeWire on MealType {
  String get wireValue => name;

  static MealType fromWireValue(Object? value) {
    return MealType.values.firstWhere(
      (type) => type.wireValue == value,
      orElse: () => MealType.snack,
    );
  }
}

String nutritionDayKey(DateTime value) {
  final local = value.toLocal();
  return '${local.year.toString().padLeft(4, '0')}-'
      '${local.month.toString().padLeft(2, '0')}-'
      '${local.day.toString().padLeft(2, '0')}';
}

DateTime nutritionDay(DateTime value) {
  final local = value.toLocal();
  return DateTime(local.year, local.month, local.day);
}

class NutritionLogEntry {
  const NutritionLogEntry({
    required this.id,
    required this.loggedAt,
    required this.dayKey,
    required this.mealType,
    required this.label,
    required this.nutrition,
    this.weightGrams,
    this.isPartial = false,
    this.sourceMeasurementId,
  });

  factory NutritionLogEntry.create({
    required String id,
    required DateTime loggedAt,
    required MealType mealType,
    required String label,
    required NutritionTotals nutrition,
    double? weightGrams,
    bool isPartial = false,
    String? sourceMeasurementId,
  }) {
    final entry = NutritionLogEntry(
      id: id.trim(),
      loggedAt: loggedAt,
      dayKey: nutritionDayKey(loggedAt),
      mealType: mealType,
      label: label.trim(),
      nutrition: nutrition,
      weightGrams: weightGrams,
      isPartial: isPartial,
      sourceMeasurementId: sourceMeasurementId?.trim(),
    );
    entry.validate();
    return entry;
  }

  factory NutritionLogEntry.fromMeasurement({
    required String id,
    required DateTime loggedAt,
    required MealType mealType,
    required Measurement measurement,
  }) {
    if (!measurement.isFoodPlate || !measurement.hasNutritionData) {
      throw const FormatException(
        'Only food scans with nutrition can be added to the diary.',
      );
    }
    return NutritionLogEntry.create(
      id: id,
      loggedAt: loggedAt,
      mealType: mealType,
      label: measurement.mealLabel ?? measurement.objectLabel,
      nutrition: measurement.nutritionTotals,
      weightGrams: measurement.totalEstimateGrams,
      isPartial: measurement.hasPartialNutrition,
      sourceMeasurementId: measurement.id,
    );
  }

  final String id;
  final DateTime loggedAt;
  final String dayKey;
  final MealType mealType;
  final String label;
  final double? weightGrams;
  final NutritionTotals nutrition;
  final bool isPartial;
  final String? sourceMeasurementId;

  NutritionLogEntry copyWith({
    DateTime? loggedAt,
    MealType? mealType,
    String? label,
    Object? weightGrams = _notProvided,
    NutritionTotals? nutrition,
    bool? isPartial,
    Object? sourceMeasurementId = _notProvided,
  }) {
    return NutritionLogEntry.create(
      id: id,
      loggedAt: loggedAt ?? this.loggedAt,
      mealType: mealType ?? this.mealType,
      label: label ?? this.label,
      weightGrams: identical(weightGrams, _notProvided)
          ? this.weightGrams
          : weightGrams as double?,
      nutrition: nutrition ?? this.nutrition,
      isPartial: isPartial ?? this.isPartial,
      sourceMeasurementId: identical(sourceMeasurementId, _notProvided)
          ? this.sourceMeasurementId
          : sourceMeasurementId as String?,
    );
  }

  void validate() {
    if (id.isEmpty) throw const FormatException('Nutrition entry ID is empty.');
    if (label.isEmpty) {
      throw const FormatException('Nutrition entry label is empty.');
    }
    if (!_validDayKey(dayKey)) {
      throw const FormatException('Nutrition entry day is invalid.');
    }
    final values = [
      nutrition.caloriesKcal,
      nutrition.proteinGrams,
      nutrition.carbsGrams,
      nutrition.fatGrams,
    ];
    if (values.any((value) => !value.isFinite || value < 0)) {
      throw const FormatException('Nutrition values must be non-negative.');
    }
    if (values.every((value) => value == 0)) {
      throw const FormatException('At least one nutrition value is required.');
    }
    final weight = weightGrams;
    if (weight != null && (!weight.isFinite || weight <= 0)) {
      throw const FormatException('Weight must be greater than zero.');
    }
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'loggedAt': loggedAt.toIso8601String(),
    'dayKey': dayKey,
    'mealType': mealType.wireValue,
    'label': label,
    if (weightGrams != null) 'weightGrams': weightGrams,
    'caloriesKcal': nutrition.caloriesKcal,
    'proteinGrams': nutrition.proteinGrams,
    'carbsGrams': nutrition.carbsGrams,
    'fatGrams': nutrition.fatGrams,
    'isPartial': isPartial,
    if (sourceMeasurementId != null) 'sourceMeasurementId': sourceMeasurementId,
  };

  factory NutritionLogEntry.fromJson(Map<String, Object?> json) {
    final loggedAt = DateTime.parse(_string(json, 'loggedAt'));
    final entry = NutritionLogEntry(
      id: _string(json, 'id'),
      loggedAt: loggedAt,
      dayKey: (json['dayKey'] as String?)?.trim().isNotEmpty == true
          ? (json['dayKey']! as String).trim()
          : nutritionDayKey(loggedAt),
      mealType: MealTypeWire.fromWireValue(json['mealType']),
      label: _string(json, 'label'),
      weightGrams: _optionalNumber(json['weightGrams']),
      nutrition: NutritionTotals(
        caloriesKcal: _number(json, 'caloriesKcal'),
        proteinGrams: _number(json, 'proteinGrams'),
        carbsGrams: _number(json, 'carbsGrams'),
        fatGrams: _number(json, 'fatGrams'),
      ),
      isPartial: json['isPartial'] as bool? ?? false,
      sourceMeasurementId: (json['sourceMeasurementId'] as String?)?.trim(),
    );
    entry.validate();
    return entry;
  }
}

class NutritionDaySummary {
  const NutritionDaySummary({
    required this.day,
    required this.dayKey,
    required this.entries,
    required this.totals,
    required this.hasPartialData,
  });

  final DateTime day;
  final String dayKey;
  final List<NutritionLogEntry> entries;
  final NutritionTotals totals;
  final bool hasPartialData;

  bool get hasEntries => entries.isNotEmpty;
}

class NutritionPeriodSummary {
  const NutritionPeriodSummary({
    required this.days,
    required this.totals,
    required this.averageOnLoggedDays,
    required this.loggedDays,
    required this.hasPartialData,
  });

  final List<NutritionDaySummary> days;
  final NutritionTotals totals;
  final NutritionTotals averageOnLoggedDays;
  final int loggedDays;
  final bool hasPartialData;
}

NutritionDaySummary summarizeNutritionDay(
  Iterable<NutritionLogEntry> entries,
  DateTime day,
) {
  final normalized = nutritionDay(day);
  final key = nutritionDayKey(normalized);
  final matching = entries.where((entry) => entry.dayKey == key).toList()
    ..sort((a, b) => b.loggedAt.compareTo(a.loggedAt));
  final totals = matching.fold(
    NutritionTotals.zero,
    (sum, entry) => sum + entry.nutrition,
  );
  return NutritionDaySummary(
    day: normalized,
    dayKey: key,
    entries: List.unmodifiable(matching),
    totals: totals,
    hasPartialData: matching.any((entry) => entry.isPartial),
  );
}

NutritionPeriodSummary summarizeNutritionPeriod(
  Iterable<NutritionLogEntry> entries, {
  required DateTime endingOn,
  required int dayCount,
}) {
  if (dayCount <= 0) {
    throw ArgumentError.value(dayCount, 'dayCount', 'Must be positive.');
  }
  final end = nutritionDay(endingOn);
  final days = List.generate(
    dayCount,
    (index) => summarizeNutritionDay(
      entries,
      DateTime(end.year, end.month, end.day - (dayCount - index - 1)),
    ),
    growable: false,
  );
  final logged = days.where((day) => day.hasEntries).toList(growable: false);
  final totals = days.fold(
    NutritionTotals.zero,
    (sum, day) => sum + day.totals,
  );
  return NutritionPeriodSummary(
    days: days,
    totals: totals,
    averageOnLoggedDays: logged.isEmpty
        ? NutritionTotals.zero
        : NutritionTotals(
            caloriesKcal: totals.caloriesKcal / logged.length,
            proteinGrams: totals.proteinGrams / logged.length,
            carbsGrams: totals.carbsGrams / logged.length,
            fatGrams: totals.fatGrams / logged.length,
          ),
    loggedDays: logged.length,
    hasPartialData: days.any((day) => day.hasPartialData),
  );
}

const _notProvided = Object();

bool _validDayKey(String value) {
  final match = RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value);
  if (!match) return false;
  final parsed = DateTime.tryParse(value);
  return parsed != null && nutritionDayKey(parsed) == value;
}

String _string(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is String && value.trim().isNotEmpty) return value.trim();
  throw FormatException('Invalid string value for "$key".');
}

double _number(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is num && value.isFinite) return value.toDouble();
  throw FormatException('Invalid numeric value for "$key".');
}

double? _optionalNumber(Object? value) {
  if (value == null) return null;
  if (value is num && value.isFinite) return value.toDouble();
  throw const FormatException('Invalid optional numeric value.');
}
