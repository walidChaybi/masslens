import 'dart:math' as math;

/// Reference objects used for fun, human-friendly weight comparisons.
///
/// The UI maps each unit to a localized display name; this domain layer stays
/// language-agnostic.
enum FunWeightUnit {
  aaBattery(23),
  smartphone(200),
  baguette(250),
  sodaCan(390),
  soccerBall(430),
  cat(4000),
  watermelon(5000),
  carTire(10000),
  washingMachine(70000);

  const FunWeightUnit(this.gramsPerUnit);

  final double gramsPerUnit;
}

final class FunWeightPart {
  const FunWeightPart(this.unit, this.quantityText);

  final FunWeightUnit unit;

  /// Pre-formatted quantity, e.g. "2" or "2.5".
  final String quantityText;
}

/// One or two relatable comparisons for a weight estimate,
/// e.g. "≈ 2 × smartphone, ≈ 0.9 × soccer ball".
final class FunWeightComparison {
  const FunWeightComparison(this.parts);

  final List<FunWeightPart> parts;
}

double _formatQuantity(double quantity) {
  // Keep 0.1 precision for small numbers, 1 decimal for the rest.
  if (quantity < 1) return double.parse(quantity.toStringAsFixed(1));
  if (quantity < 10) return double.parse(quantity.toStringAsFixed(1));
  if (quantity < 50) return double.parse(quantity.toStringAsFixed(0));
  return double.parse(quantity.toStringAsFixed(0));
}

String _formatQuantityText(double quantity) {
  final formatted = _formatQuantity(quantity);
  return formatted == formatted.toInt()
      ? formatted.toInt().toString()
      : formatted.toStringAsFixed(1);
}

FunWeightComparison? buildFunWeightComparisons(double estimateGrams) {
  if (!estimateGrams.isFinite || estimateGrams <= 0) return null;

  // Primary reference: aim near "2×" for readability.
  const target1 = 2.0;
  final candidates1 = FunWeightUnit.values
      .map((unit) => (unit: unit, quantity: estimateGrams / unit.gramsPerUnit))
      .where((item) => item.quantity >= 0.5 && item.quantity <= 8.0)
      .toList();
  if (candidates1.isEmpty) return null;

  candidates1.sort((a, b) {
    final diffA = (math.log(a.quantity) - math.log(target1)).abs();
    final diffB = (math.log(b.quantity) - math.log(target1)).abs();
    return diffA.compareTo(diffB);
  });
  final first = candidates1.first;
  final firstPart = FunWeightPart(
    first.unit,
    _formatQuantityText(first.quantity),
  );

  // Secondary reference: try to keep it smaller and different.
  const target2 = 0.7;
  final candidates2 = FunWeightUnit.values
      .where((unit) => unit != first.unit)
      .map((unit) => (unit: unit, quantity: estimateGrams / unit.gramsPerUnit))
      .where((item) => item.quantity >= 0.2 && item.quantity <= 3.5)
      .toList();

  if (candidates2.isEmpty) return FunWeightComparison([firstPart]);
  candidates2.sort((a, b) {
    final diffA = (math.log(a.quantity) - math.log(target2)).abs();
    final diffB = (math.log(b.quantity) - math.log(target2)).abs();
    return diffA.compareTo(diffB);
  });

  final second = candidates2.first;
  return FunWeightComparison([
    firstPart,
    FunWeightPart(second.unit, _formatQuantityText(second.quantity)),
  ]);
}
