import 'package:flutter_test/flutter_test.dart';
import 'package:mass_lens/features/scale/domain/touch_pressure_demo.dart';

void main() {
  group('TouchPressureDemo', () {
    test('normalizes a supported pressure range', () {
      expect(
        TouchPressureDemo.normalize(pressure: 0.6, minimum: 0.2, maximum: 1),
        closeTo(0.5, 0.0001),
      );
    });

    test('clamps values and rejects an invalid range', () {
      expect(
        TouchPressureDemo.normalize(pressure: -1, minimum: 0, maximum: 1),
        0,
      );
      expect(
        TouchPressureDemo.normalize(pressure: 2, minimum: 0, maximum: 1),
        1,
      );
      expect(
        TouchPressureDemo.normalize(pressure: 1, minimum: 1, maximum: 1),
        0,
      );
    });

    test('maps pressure only to a bounded demo value', () {
      expect(
        TouchPressureDemo.simulatedGrams(pressure: 0.5, minimum: 0, maximum: 1),
        TouchPressureDemo.maximumDemoGrams / 2,
      );
    });
  });
}
