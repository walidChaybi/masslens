import 'dart:typed_data';

/// Identifies how a weight entered the application.
///
/// Keeping provenance on every reading prevents a Bluetooth measurement from
/// being confused with an AI estimate or a manually entered value later.
enum ScaleReadingSource { standardBluetoothWeightScale }

/// Unit selected by bit 0 of the Bluetooth Weight Measurement flags field.
enum ScaleMeasurementUnit { siKilograms, imperialPounds }

enum ScaleReadingStatus { successful, unsuccessful }

/// A standards-based scale reading, stored canonically in grams.
final class ScaleReading {
  const ScaleReading({
    required this.status,
    required this.weightGrams,
    required this.transmittedUnit,
    required this.source,
    required this.deviceId,
    required this.receivedAt,
    required this.rawWeight,
    required this.rawFlags,
    this.deviceName,
    this.measuredAt,
    this.userId,
    this.bodyMassIndex,
    this.heightMeters,
  });

  /// Null only when the scale reports the WSS 0xFFFF unsuccessful sentinel.
  final double? weightGrams;
  final ScaleReadingStatus status;
  final ScaleMeasurementUnit transmittedUnit;
  final ScaleReadingSource source;
  final String deviceId;
  final String? deviceName;

  /// Time the application received the indication or notification.
  final DateTime receivedAt;

  /// Optional device-local timestamp from the measurement packet.
  ///
  /// The Bluetooth Date Time value does not contain a timezone.
  final DateTime? measuredAt;

  /// Optional WSS user ID. The reserved value 0xFF means unknown user.
  final int? userId;
  final double? bodyMassIndex;

  /// Optional height converted to meters, regardless of transmitted units.
  final double? heightMeters;
  final int rawWeight;
  final int rawFlags;

  bool get isSuccessful => status == ScaleReadingStatus.successful;
  bool get hasKnownUser => userId != null && userId != 0xff;

  @override
  String toString() {
    return 'ScaleReading('
        'status: ${status.name}, '
        'weightGrams: $weightGrams, '
        'unit: ${transmittedUnit.name}, '
        'deviceId: $deviceId)';
  }
}

enum WeightScaleParseErrorCode {
  packetTooShort,
  reservedFlagsSet,
  truncatedOptionalField,
  unexpectedTrailingData,
  invalidTimestamp,
  inconsistentUnsuccessfulMeasurement,
}

final class WeightScaleParseException implements FormatException {
  const WeightScaleParseException(this.code, this.message, {this.offset});

  final WeightScaleParseErrorCode code;

  @override
  final String message;

  @override
  final int? offset;

  @override
  Object? get source => null;

  @override
  String toString() => 'WeightScaleParseException(${code.name}): $message';
}

/// Pure parser for Bluetooth SIG Weight Measurement characteristic 0x2A9D.
///
/// WSS values are little-endian. SI weight has a resolution of 0.005 kg and
/// imperial weight has a resolution of 0.01 lb. Optional Date Time, User ID,
/// BMI, and Height fields are parsed according to flags bits 1-3.
abstract final class WeightScaleMeasurementParser {
  static const _gramsPerPound = 453.59237;

  static ScaleReading parse(
    Uint8List value, {
    required String deviceId,
    String? deviceName,
    DateTime? receivedAt,
    bool rejectReservedFlags = true,
  }) {
    if (value.length < 3) {
      throw const WeightScaleParseException(
        WeightScaleParseErrorCode.packetTooShort,
        'A Weight Measurement requires at least flags and weight.',
        offset: 0,
      );
    }

    final bytes = ByteData.sublistView(value);
    final flags = bytes.getUint8(0);
    if (rejectReservedFlags && flags & 0xf0 != 0) {
      throw const WeightScaleParseException(
        WeightScaleParseErrorCode.reservedFlagsSet,
        'Reserved Weight Measurement flag bits must be zero.',
        offset: 0,
      );
    }

    final unit = flags & 0x01 == 0
        ? ScaleMeasurementUnit.siKilograms
        : ScaleMeasurementUnit.imperialPounds;
    final rawWeight = bytes.getUint16(1, Endian.little);
    var offset = 3;

    DateTime? measuredAt;
    if (flags & 0x02 != 0) {
      _requireBytes(value, offset, 7, 'timestamp');
      measuredAt = _parseDateTime(bytes, offset);
      offset += 7;
    }

    int? userId;
    if (flags & 0x04 != 0) {
      _requireBytes(value, offset, 1, 'user ID');
      userId = bytes.getUint8(offset);
      offset += 1;
    }

    double? bodyMassIndex;
    double? heightMeters;
    final hasBodyMassIndexAndHeight = flags & 0x08 != 0;
    if (hasBodyMassIndexAndHeight) {
      if (rawWeight == 0xffff) {
        throw WeightScaleParseException(
          WeightScaleParseErrorCode.inconsistentUnsuccessfulMeasurement,
          'BMI and height cannot accompany an unsuccessful measurement.',
          offset: offset,
        );
      }
      _requireBytes(value, offset, 4, 'BMI and height');
      final rawBodyMassIndex = bytes.getUint16(offset, Endian.little);
      final rawHeight = bytes.getUint16(offset + 2, Endian.little);
      bodyMassIndex = rawBodyMassIndex == 0xffff
          ? null
          : rawBodyMassIndex * 0.1;
      heightMeters = rawHeight == 0xffff
          ? null
          : unit == ScaleMeasurementUnit.siKilograms
          ? rawHeight * 0.001
          : rawHeight * 0.1 * 0.0254;
      offset += 4;
    }

    if (offset != value.length) {
      throw WeightScaleParseException(
        WeightScaleParseErrorCode.unexpectedTrailingData,
        'The packet contains ${value.length - offset} unexpected byte(s).',
        offset: offset,
      );
    }

    final successful = rawWeight != 0xffff;
    final weightGrams = !successful
        ? null
        : unit == ScaleMeasurementUnit.siKilograms
        ? rawWeight * 5.0
        : rawWeight * 0.01 * _gramsPerPound;

    return ScaleReading(
      status: successful
          ? ScaleReadingStatus.successful
          : ScaleReadingStatus.unsuccessful,
      weightGrams: weightGrams,
      transmittedUnit: unit,
      source: ScaleReadingSource.standardBluetoothWeightScale,
      deviceId: deviceId,
      deviceName: deviceName,
      receivedAt: receivedAt ?? DateTime.now().toUtc(),
      measuredAt: measuredAt,
      userId: userId,
      bodyMassIndex: bodyMassIndex,
      heightMeters: heightMeters,
      rawWeight: rawWeight,
      rawFlags: flags,
    );
  }

  static DateTime _parseDateTime(ByteData bytes, int offset) {
    final year = bytes.getUint16(offset, Endian.little);
    final month = bytes.getUint8(offset + 2);
    final day = bytes.getUint8(offset + 3);
    final hour = bytes.getUint8(offset + 4);
    final minute = bytes.getUint8(offset + 5);
    final second = bytes.getUint8(offset + 6);

    if (year < 1582 ||
        year > 9999 ||
        month < 1 ||
        month > 12 ||
        day < 1 ||
        day > 31 ||
        hour > 23 ||
        minute > 59 ||
        second > 59) {
      throw WeightScaleParseException(
        WeightScaleParseErrorCode.invalidTimestamp,
        'The measurement contains an invalid Bluetooth Date Time.',
        offset: offset,
      );
    }

    final parsed = DateTime(year, month, day, hour, minute, second);
    if (parsed.year != year ||
        parsed.month != month ||
        parsed.day != day ||
        parsed.hour != hour ||
        parsed.minute != minute ||
        parsed.second != second) {
      throw WeightScaleParseException(
        WeightScaleParseErrorCode.invalidTimestamp,
        'The measurement contains a calendar date that does not exist.',
        offset: offset,
      );
    }
    return parsed;
  }

  static void _requireBytes(
    Uint8List value,
    int offset,
    int count,
    String field,
  ) {
    if (value.length - offset >= count) return;
    throw WeightScaleParseException(
      WeightScaleParseErrorCode.truncatedOptionalField,
      'The optional $field field is truncated.',
      offset: offset,
    );
  }
}
