import 'dart:convert';
import 'dart:math';

import '../../measurements/domain/measurement.dart';
import 'measured_dimensions.dart';

class KnownDimensionInput {
  const KnownDimensionInput({
    required this.axis,
    required this.value,
    required this.unit,
  });

  final String axis;
  final double value;
  final String unit;

  Map<String, Object> toJson() => {'axis': axis, 'value': value, 'unit': unit};

  double get millimeters => value * (unit == 'in' ? 25.4 : 10);
}

class EstimateRequest {
  const EstimateRequest({
    required this.imagePath,
    this.requestId = '',
    this.secondaryImagePath,
    this.material = 'Unknown',
    this.fillState = 'Unknown',
    this.referenceObject = 'None',
    this.knownDimension,
    this.measuredDimensions,
  });

  final String imagePath;
  final String requestId;
  final String? secondaryImagePath;
  final String material;
  final String fillState;
  final String referenceObject;
  final KnownDimensionInput? knownDimension;
  final MeasuredDimensions? measuredDimensions;
}

abstract final class ScanRequestId {
  static String create() {
    final random = Random.secure();
    final bytes = List<int>.generate(18, (_) => random.nextInt(256));
    return base64UrlEncode(bytes).replaceAll('=', '');
  }
}

abstract interface class EstimateRepository {
  Future<Measurement> analyze(EstimateRequest request);
}
