import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mass_lens/features/measurements/data/measurement_store.dart';
import 'package:mass_lens/features/measurements/domain/measurement.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test(
    'upgrade deletes demo history while retaining real AI history',
    () async {
      final real = _measurement('real').toJson()..['isDemo'] = false;
      final demo = _measurement('demo').toJson()..['isDemo'] = true;
      final unmarkedOldDemo = _measurement('old').toJson();
      SharedPreferences.setMockInitialValues({
        'mass_lens.measurement_history.v1': jsonEncode([
          demo,
          real,
          unmarkedOldDemo,
        ]),
      });

      final loaded = await const MeasurementStore().load();
      expect(loaded.map((item) => item.id), ['real']);

      final preferences = await SharedPreferences.getInstance();
      final stored =
          jsonDecode(preferences.getString('mass_lens.measurement_history.v1')!)
              as List;
      expect(stored, hasLength(1));
      expect((stored.single as Map)['id'], 'real');
    },
  );
}

Measurement _measurement(String id) => Measurement(
  id: id,
  createdAt: DateTime.utc(2026, 8, 8),
  imagePath: '/tmp/$id.jpg',
  objectLabel: 'Object',
  category: 'Household',
  estimateGrams: 100,
  lowerBoundGrams: 80,
  upperBoundGrams: 120,
  confidence: ConfidenceLevel.medium,
  dimensions: const DimensionsMm(width: 10, height: 10, depth: 10),
  assumptions: const ['AI estimate'],
);
