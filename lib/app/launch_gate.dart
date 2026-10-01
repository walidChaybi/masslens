import 'dart:async';

import 'package:flutter/widgets.dart';

import '../features/measurements/data/measurement_store.dart';
import 'app_controller.dart';
import 'mass_lens_app.dart';

/// Draws a frame identical to the Android launch screen immediately, then
/// swaps in the real app once local data is loaded. Android Vitals measures
/// cold start up to the first frame, so the splash no longer waits on
/// SharedPreferences, JSON decoding or plugin setup.
class LaunchGate extends StatefulWidget {
  const LaunchGate({super.key, this.bootstrap = AppController.bootstrap});

  final Future<AppController> Function() bootstrap;

  @override
  State<LaunchGate> createState() => _LaunchGateState();
}

class _LaunchGateState extends State<LaunchGate> {
  AppController? _controller;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    AppController controller;
    try {
      controller = await widget.bootstrap();
    } on Object {
      // Stores already fall back to empty data; this is a last resort.
      controller = AppController(measurementStore: const MeasurementStore());
    }
    if (!mounted) {
      controller.dispose();
      return;
    }
    setState(() => _controller = controller);
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (controller != null) return MassLensApp(controller: controller);
    return const LaunchPlaceholder();
  }
}

/// Mirrors `launch_background.xml`: canvas colour with the 72dp mark.
class LaunchPlaceholder extends StatelessWidget {
  const LaunchPlaceholder({super.key});

  static const canvas = Color(0xFFF7F8FC);
  static const canvasDark = Color(0xFF0B121C);

  @override
  Widget build(BuildContext context) {
    // The saved appearance is not loaded yet, so this follows the platform, as
    // values-night/colors.xml does for the native splash behind it.
    final dark =
        WidgetsBinding.instance.platformDispatcher.platformBrightness ==
        Brightness.dark;
    return ColoredBox(
      key: const Key('launch_placeholder'),
      color: dark ? canvasDark : canvas,
      child: const Center(
        child: CustomPaint(size: Size.square(72), painter: _MarkPainter()),
      ),
    );
  }
}

class _MarkPainter extends CustomPainter {
  const _MarkPainter();

  @override
  void paint(Canvas canvas, Size size) {
    // Same geometry as ic_masslens_mark.xml (108 x 108 viewport).
    canvas.scale(size.width / 108, size.height / 108);
    canvas.drawRRect(
      RRect.fromLTRBR(14, 14, 94, 94, const Radius.circular(8)),
      Paint()..color = const Color(0xFF121B36),
    );
    final m = Path()
      ..moveTo(31, 73)
      ..lineTo(31, 35)
      ..lineTo(41, 35)
      ..lineTo(54, 55)
      ..lineTo(67, 35)
      ..lineTo(77, 35)
      ..lineTo(77, 73)
      ..lineTo(67, 73)
      ..lineTo(67, 52)
      ..lineTo(58, 67)
      ..lineTo(50, 67)
      ..lineTo(41, 52)
      ..lineTo(41, 73)
      ..close();
    canvas.drawPath(m, Paint()..color = const Color(0xFFB7F34A));
    final corners = Path()
      ..moveTo(24, 34)
      ..lineTo(24, 24)
      ..lineTo(34, 24)
      ..moveTo(74, 84)
      ..lineTo(84, 84)
      ..lineTo(84, 74);
    canvas.drawPath(
      corners,
      Paint()
        ..color = const Color(0xFFFFFFFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
