import '../../measurements/domain/measurement.dart';

enum MeasurementMethod {
  arCoreDepth('arcore_depth', 'AR depth'),
  arCorePlane('arcore_plane', 'AR surface'),
  photoReference('photo_reference', 'Photo reference');

  const MeasurementMethod(this.wireName, this.label);

  final String wireName;
  final String label;

  static MeasurementMethod fromWireName(String value) {
    return values.firstWhere(
      (method) => method.wireName == value,
      orElse: () => throw FormatException('Unknown measurement method: $value'),
    );
  }
}

class MeasuredDimensions {
  const MeasuredDimensions({
    required this.widthMm,
    required this.heightMm,
    this.method = MeasurementMethod.photoReference,
    this.depthMm,
    this.referenceLabel,
  });

  final double widthMm;
  final double heightMm;
  final double? depthMm;
  final MeasurementMethod method;
  final String? referenceLabel;

  String get sourceLabel {
    final reference = referenceLabel?.trim();
    return reference == null || reference.isEmpty
        ? method.label
        : '${method.label} · $reference';
  }

  bool get isValid =>
      _isValidAxis(widthMm) &&
      _isValidAxis(heightMm) &&
      (depthMm == null || _isValidAxis(depthMm!));

  Map<String, Object> toJson() {
    if (!isValid) {
      throw const FormatException(
        'Measured dimensions must be between 5 and 5000 mm.',
      );
    }
    return {
      'widthMm': widthMm,
      'heightMm': heightMm,
      'depthMm': ?depthMm,
      'method': method.wireName,
      'referenceLabel': ?referenceLabel,
    };
  }

  factory MeasuredDimensions.fromJson(Map<Object?, Object?> json) {
    double number(String key) {
      final value = json[key];
      if (value is! num || !value.isFinite) {
        throw FormatException('Invalid measured dimension: $key');
      }
      return value.toDouble();
    }

    final method = json['method'];
    if (method is! String) {
      throw const FormatException('Missing measurement method');
    }
    final dimensions = MeasuredDimensions(
      widthMm: number('widthMm'),
      heightMm: number('heightMm'),
      depthMm: json['depthMm'] == null ? null : number('depthMm'),
      method: MeasurementMethod.fromWireName(method),
      referenceLabel: json['referenceLabel'] as String?,
    );
    if (!dimensions.isValid) {
      throw const FormatException(
        'Measured dimensions must be between 5 and 5000 mm.',
      );
    }
    return dimensions;
  }

  DimensionsMm mergeWith(DimensionsMm inferred) => DimensionsMm(
    width: widthMm,
    height: heightMm,
    depth: depthMm ?? inferred.depth,
  );

  String formatSummary() {
    final values = <double>[widthMm, heightMm, ?depthMm];
    return '${values.map((value) => (value / 10).toStringAsFixed(1)).join(' × ')} cm';
  }

  static bool _isValidAxis(double value) =>
      value.isFinite &&
      value >= MeasureCalibration.minMillimeters &&
      value <= MeasureCalibration.maxMillimeters;
}

class MeasureCalibration {
  const MeasureCalibration._(this.millimetersPerPixel);

  static const double minMillimeters = 5;
  static const double maxMillimeters = 5000;
  static const double _minReferencePixels = 12;

  final double millimetersPerPixel;

  static MeasureCalibration? fromReference({
    required double referencePixelLength,
    required double referenceMillimeters,
  }) {
    if (!referencePixelLength.isFinite ||
        !referenceMillimeters.isFinite ||
        referencePixelLength < _minReferencePixels ||
        referenceMillimeters <= 0) {
      return null;
    }
    return MeasureCalibration._(referenceMillimeters / referencePixelLength);
  }

  double toMillimeters(double pixels) {
    return (pixels * millimetersPerPixel).clamp(minMillimeters, maxMillimeters);
  }
}
