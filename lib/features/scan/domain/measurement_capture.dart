import 'measured_dimensions.dart';

class MeasurementCapture {
  const MeasurementCapture({required this.imagePath, this.dimensions});

  final String imagePath;
  final MeasuredDimensions? dimensions;
}
