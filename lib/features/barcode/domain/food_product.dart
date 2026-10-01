import '../../measurements/domain/measurement.dart';

/// Where a packaged-food record came from. Shown to the user as attribution.
enum FoodProductSource {
  openFoodFacts('open_food_facts'),
  usda('usda');

  const FoodProductSource(this.wireValue);

  final String wireValue;

  static FoodProductSource fromWireValue(Object? value) {
    return value == FoodProductSource.usda.wireValue
        ? FoodProductSource.usda
        : FoodProductSource.openFoodFacts;
  }
}

/// A packaged food identified by its barcode, with label nutrition per 100 g
/// (or per 100 ml for drinks). Values come from a public database, never AI.
class FoodProduct {
  const FoodProduct({
    required this.barcode,
    required this.name,
    required this.per100g,
    required this.source,
    this.brand,
    this.servingGrams,
    this.packageGrams,
    this.isLiquid = false,
    this.hasPartialNutrition = false,
  });

  final String barcode;
  final String name;
  final String? brand;
  final NutritionPer100g per100g;
  final FoodProductSource source;
  final double? servingGrams;
  final double? packageGrams;
  final bool isLiquid;

  /// True when the database lacks one or more macros (stored as zero).
  final bool hasPartialNutrition;

  String get unit => isLiquid ? 'ml' : 'g';

  /// Diary label: "Name (Brand)" when a distinct brand is known.
  String get diaryLabel {
    final brandName = brand?.trim();
    if (brandName == null ||
        brandName.isEmpty ||
        name.toLowerCase().contains(brandName.toLowerCase())) {
      return name;
    }
    return '$name ($brandName)';
  }

  NutritionTotals nutritionFor(double grams) => per100g.forWeight(grams);

  Map<String, Object?> toJson() => {
    'barcode': barcode,
    'name': name,
    if (brand != null) 'brand': brand,
    'per100g': per100g.toJson(),
    'source': source.wireValue,
    if (servingGrams != null) 'servingGrams': servingGrams,
    if (packageGrams != null) 'packageGrams': packageGrams,
    'isLiquid': isLiquid,
    'hasPartialNutrition': hasPartialNutrition,
  };

  /// Parses both the local cache format and the MassLens Worker response.
  static FoodProduct? tryFromJson(Object? value) {
    if (value is! Map) return null;
    try {
      final json = Map<String, Object?>.from(value);
      final barcode = normalizeBarcode('${json['barcode'] ?? ''}');
      final name = (json['name'] as String?)?.trim() ?? '';
      final rawPer100 = json['per100g'];
      if (barcode == null || name.isEmpty || rawPer100 is! Map) return null;
      final per100 = NutritionPer100g.fromJson(
        Map<String, Object?>.from(rawPer100),
      );
      if (!isPlausiblePer100g(per100)) return null;
      final brand = (json['brand'] as String?)?.trim();
      return FoodProduct(
        barcode: barcode,
        name: name,
        brand: brand == null || brand.isEmpty ? null : brand,
        per100g: per100,
        source: FoodProductSource.fromWireValue(json['source']),
        servingGrams: plausibleAmount(json['servingGrams']),
        packageGrams: plausibleAmount(json['packageGrams']),
        isLiquid: json['isLiquid'] == true,
        hasPartialNutrition: json['hasPartialNutrition'] == true,
      );
    } on Object {
      return null;
    }
  }
}

/// Label values outside these limits are data-entry errors in the source.
bool isPlausiblePer100g(NutritionPer100g value) {
  final macros = [value.proteinGrams, value.carbsGrams, value.fatGrams];
  if (!value.caloriesKcal.isFinite ||
      value.caloriesKcal < 0 ||
      value.caloriesKcal > 950) {
    return false;
  }
  if (macros.any((macro) => !macro.isFinite || macro < 0 || macro > 100)) {
    return false;
  }
  if (macros.fold<double>(0, (sum, macro) => sum + macro) > 105) return false;
  return value.caloriesKcal > 0 || macros.any((macro) => macro > 0);
}

/// Serving and package sizes between 1 g and 5 kg; anything else is ignored.
double? plausibleAmount(Object? value) {
  final parsed = switch (value) {
    final num number => number.toDouble(),
    final String text => double.tryParse(text.trim().replaceAll(',', '.')),
    _ => null,
  };
  if (parsed == null || !parsed.isFinite || parsed < 1 || parsed > 5000) {
    return null;
  }
  return parsed;
}

/// Returns the digits of a valid EAN-8, UPC-A, EAN-13 or GTIN-14 code, or
/// null. Eight-digit UPC-E codes are expanded to their 12-digit UPC-A form.
String? normalizeBarcode(String raw) {
  final digits = raw.replaceAll(RegExp(r'[\s-]'), '');
  if (!RegExp(r'^(\d{8}|\d{12,14})$').hasMatch(digits)) return null;
  if (hasValidGtinCheckDigit(digits)) return digits;
  if (digits.length == 8) {
    final expanded = expandUpcE(digits);
    if (expanded != null && hasValidGtinCheckDigit(expanded)) return expanded;
  }
  return null;
}

bool hasValidGtinCheckDigit(String digits) {
  if (digits.length < 8 || !RegExp(r'^\d+$').hasMatch(digits)) return false;
  var sum = 0;
  final body = digits.substring(0, digits.length - 1);
  for (var index = 0; index < body.length; index++) {
    final digit = body.codeUnitAt(body.length - 1 - index) - 48;
    sum += index.isEven ? digit * 3 : digit;
  }
  final expected = (10 - sum % 10) % 10;
  return expected == digits.codeUnitAt(digits.length - 1) - 48;
}

/// Expands an 8-digit UPC-E code (number system 0 or 1) to UPC-A.
String? expandUpcE(String code) {
  if (!RegExp(r'^[01]\d{7}$').hasMatch(code)) return null;
  final system = code[0];
  final d = code.substring(1, 7);
  final check = code[7];
  final last = int.parse(d[5]);
  final String manufacturerAndProduct;
  if (last <= 2) {
    manufacturerAndProduct = '${d[0]}${d[1]}${d[5]}0000${d[2]}${d[3]}${d[4]}';
  } else if (last == 3) {
    manufacturerAndProduct = '${d[0]}${d[1]}${d[2]}00000${d[3]}${d[4]}';
  } else if (last == 4) {
    manufacturerAndProduct = '${d[0]}${d[1]}${d[2]}${d[3]}00000${d[4]}';
  } else {
    manufacturerAndProduct = '${d.substring(0, 5)}0000${d[5]}';
  }
  return '$system$manufacturerAndProduct$check';
}
