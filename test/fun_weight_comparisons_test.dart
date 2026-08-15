import 'package:flutter_test/flutter_test.dart';
import 'package:mass_lens/features/measurements/domain/fun_weight_comparisons.dart';

void main() {
  test('buildFunWeightComparisons picks smartphone for ~400g', () {
    final fun = buildFunWeightComparisons(400);
    expect(fun, isNotNull);
    expect(
      fun!.parts.map((part) => part.unit),
      contains(FunWeightUnit.smartphone),
    );
    expect(fun.parts, hasLength(2));
    expect(fun.parts.first.quantityText, '2');
  });

  test('buildFunWeightComparisons returns null for non-positive values', () {
    expect(buildFunWeightComparisons(0), isNull);
    expect(buildFunWeightComparisons(-5), isNull);
  });
}

