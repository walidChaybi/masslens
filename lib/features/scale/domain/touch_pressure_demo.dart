/// Converts Flutter pointer-pressure samples into a visual demo value.
///
/// This is intentionally kept separate from physical scale readings: touch
/// pressure is device-dependent and cannot be calibrated into mass.
abstract final class TouchPressureDemo {
  static const double maximumDemoGrams = 500;

  static double normalize({
    required double pressure,
    required double minimum,
    required double maximum,
  }) {
    if (!pressure.isFinite || !minimum.isFinite || !maximum.isFinite) {
      return 0;
    }
    final range = maximum - minimum;
    if (range <= 0) return 0;
    return ((pressure - minimum) / range).clamp(0.0, 1.0).toDouble();
  }

  static double simulatedGrams({
    required double pressure,
    required double minimum,
    required double maximum,
  }) {
    return normalize(pressure: pressure, minimum: minimum, maximum: maximum) *
        maximumDemoGrams;
  }
}
