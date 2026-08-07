import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mass_lens/features/scale/domain/scale_reading.dart';

void main() {
  group('WeightScaleMeasurementParser', () {
    test('parses an SI measurement into canonical grams', () {
      final reading = WeightScaleMeasurementParser.parse(
        Uint8List.fromList([0x00, 0x64, 0x00]),
        deviceId: 'scale-1',
        deviceName: 'Test scale',
        receivedAt: DateTime.utc(2026, 8, 5),
      );

      expect(reading.status, ScaleReadingStatus.successful);
      expect(reading.transmittedUnit, ScaleMeasurementUnit.siKilograms);
      expect(reading.weightGrams, 500);
      expect(reading.deviceId, 'scale-1');
      expect(reading.source, ScaleReadingSource.standardBluetoothWeightScale);
    });

    test('parses an imperial measurement into canonical grams', () {
      final reading = WeightScaleMeasurementParser.parse(
        Uint8List.fromList([0x01, 0x64, 0x00]),
        deviceId: 'scale-2',
      );

      expect(reading.transmittedUnit, ScaleMeasurementUnit.imperialPounds);
      expect(reading.weightGrams, closeTo(453.59237, 0.00001));
    });

    test('parses timestamp, user, BMI, and height fields', () {
      final reading = WeightScaleMeasurementParser.parse(
        Uint8List.fromList([
          0x0e,
          0xe8,
          0x03,
          0xea,
          0x07,
          0x08,
          0x05,
          0x0c,
          0x22,
          0x38,
          0x07,
          0xe1,
          0x00,
          0x08,
          0x07,
        ]),
        deviceId: 'scale-3',
      );

      expect(reading.weightGrams, 5000);
      expect(reading.measuredAt, DateTime(2026, 8, 5, 12, 34, 56));
      expect(reading.userId, 7);
      expect(reading.bodyMassIndex, 22.5);
      expect(reading.heightMeters, closeTo(1.8, 0.00001));
    });

    test('keeps the unsuccessful sentinel as a non-reading', () {
      final reading = WeightScaleMeasurementParser.parse(
        Uint8List.fromList([0x00, 0xff, 0xff]),
        deviceId: 'scale-4',
      );

      expect(reading.status, ScaleReadingStatus.unsuccessful);
      expect(reading.weightGrams, isNull);
    });

    test('rejects reserved flags, truncation, and trailing data', () {
      expect(
        () => WeightScaleMeasurementParser.parse(
          Uint8List.fromList([0x10, 0x01, 0x00]),
          deviceId: 'scale',
        ),
        throwsA(
          isA<WeightScaleParseException>().having(
            (error) => error.code,
            'code',
            WeightScaleParseErrorCode.reservedFlagsSet,
          ),
        ),
      );
      expect(
        () => WeightScaleMeasurementParser.parse(
          Uint8List.fromList([0x02, 0x01, 0x00, 0xea]),
          deviceId: 'scale',
        ),
        throwsA(
          isA<WeightScaleParseException>().having(
            (error) => error.code,
            'code',
            WeightScaleParseErrorCode.truncatedOptionalField,
          ),
        ),
      );
      expect(
        () => WeightScaleMeasurementParser.parse(
          Uint8List.fromList([0x00, 0x01, 0x00, 0x00]),
          deviceId: 'scale',
        ),
        throwsA(
          isA<WeightScaleParseException>().having(
            (error) => error.code,
            'code',
            WeightScaleParseErrorCode.unexpectedTrailingData,
          ),
        ),
      );
    });
  });
}
