import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../l10n/l10n.dart';
import '../../measurements/domain/measurement.dart';

abstract final class SubjectCutout {
  static const _channel = MethodChannel(
    'com.masslens.mass_lens/subject_cutout',
  );
  static final _pending = <String, Future<String?>>{};

  static Future<String?> prepare(String path) {
    if (_pending.containsKey(path)) return _pending[path]!;
    if (_pending.length >= 3) _pending.remove(_pending.keys.first);
    return _pending[path] = _extract(path);
  }

  static Future<String?> _extract(String path) async {
    try {
      return await _channel.invokeMethod<String>('extract', {'path': path});
    } on Object {
      return null;
    }
  }
}

class ScanAnalysisView extends StatefulWidget {
  const ScanAnalysisView({
    required this.imagePath,
    required this.step,
    required this.scanMode,
    required this.onClose,
    super.key,
  });
  final String imagePath;
  final int step;
  final ScanMode scanMode;
  final VoidCallback onClose;

  @override
  State<ScanAnalysisView> createState() => _ScanAnalysisViewState();
}

class _ScanAnalysisViewState extends State<ScanAnalysisView>
    with SingleTickerProviderStateMixin {
  late final _motion = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  );
  String? _cutout;

  @override
  void initState() {
    super.initState();
    unawaited(
      SubjectCutout.prepare(widget.imagePath).then((path) {
        if (mounted) setState(() => _cutout = path);
      }),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _motion.stop();
    } else if (!_motion.isAnimating) {
      _motion.repeat();
    }
  }

  @override
  void dispose() {
    _motion.dispose();
    super.dispose();
  }

  Widget _photo(String path) => Image.file(
    File(path),
    fit: BoxFit.contain,
    gaplessPlayback: true,
    errorBuilder: (_, _, _) => const SizedBox.expand(),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isFood = widget.scanMode == ScanMode.foodPlate;
    final progressLabels = isFood
        ? [
            l10n.scanProgressIdentifyFood,
            l10n.scanProgressMatchUsda,
            l10n.scanProgressNutrition,
          ]
        : [
            l10n.scanProgressShape,
            l10n.scanProgressMaterial,
            l10n.scanProgressRange,
          ];
    return ColoredBox(
      key: const Key('fullscreen_scan_analysis'),
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          AnimatedBuilder(
            animation: _motion,
            child: _photo(widget.imagePath),
            builder: (context, photo) {
              final wave = math.sin(_motion.value * math.pi * 2);
              return Transform(
                key: const Key('scan_photo_wobble'),
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.001)
                  ..rotateX(wave * 0.035)
                  ..rotateY(math.cos(_motion.value * math.pi * 2) * 0.045),
                child: photo,
              );
            },
          ),
          AnimatedBuilder(
            animation: _motion,
            builder: (context, _) {
              final phase = _motion.value;
              final wave = math.sin(phase * math.pi * 2);
              return Stack(
                fit: StackFit.expand,
                children: [
                  if (_cutout case final path?)
                    Transform.rotate(
                      angle: wave * 0.025,
                      child: Transform.scale(
                        scale: 1.02 + wave * 0.02,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Opacity(
                              opacity: 0.7 + wave * 0.1,
                              child: ImageFiltered(
                                imageFilter: ui.ImageFilter.blur(
                                  sigmaX: 5,
                                  sigmaY: 5,
                                ),
                                child: ColorFiltered(
                                  colorFilter: const ColorFilter.mode(
                                    Colors.white,
                                    BlendMode.srcIn,
                                  ),
                                  child: _photo(path),
                                ),
                              ),
                            ),
                            _photo(path),
                            ShaderMask(
                              blendMode: BlendMode.srcIn,
                              shaderCallback: (bounds) => LinearGradient(
                                begin: Alignment(-1, phase * 3 - 2),
                                end: Alignment(1, phase * 3 - 1),
                                colors: const [
                                  Colors.transparent,
                                  Colors.white38,
                                  Colors.transparent,
                                ],
                              ).createShader(bounds),
                              child: _photo(path),
                            ),
                          ],
                        ),
                      ),
                    ),
                  IgnorePointer(
                    child: CustomPaint(
                      painter: _ScanSweepPainter(phase, widget.scanMode),
                    ),
                  ),
                ],
              );
            },
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 80, 24, 36),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black87],
                ),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      progressLabels[widget.step.clamp(0, 2)],
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const LinearProgressIndicator(
                      color: Color(0xffc4ff53),
                      backgroundColor: Colors.white24,
                      minHeight: 3,
                    ),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: IconButton.filledTonal(
                  tooltip: l10n.commonClose,
                  onPressed: widget.onClose,
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black54,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.close_rounded),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScanSweepPainter extends CustomPainter {
  _ScanSweepPainter(this.phase, this.scanMode);

  final double phase;
  final ScanMode scanMode;

  @override
  void paint(Canvas canvas, Size size) {
    const accent = Color(0xFF58D6C7);
    const white = Colors.white;
    final scanY =
        size.height *
        (0.15 + 0.70 * (0.5 - 0.5 * math.cos(phase * math.pi * 2)));
    final band = Rect.fromLTWH(0, scanY - 44, size.width, 88);
    canvas.drawRect(
      band,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Color(0x3358D6C7), Colors.transparent],
        ).createShader(band),
    );
    canvas.drawLine(
      Offset(0, scanY),
      Offset(size.width, scanY),
      Paint()
        ..color = accent.withValues(alpha: 0.85)
        ..strokeWidth = 2,
    );
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide;
    final sweep = phase * math.pi * 2;

    final ringPaint = Paint()
      ..color = accent.withValues(alpha: 0.30)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawCircle(center, radius * 0.32, ringPaint);
    canvas.drawCircle(
      center,
      radius * 0.32,
      Paint()
        ..color = accent.withValues(alpha: 0.08)
        ..style = PaintingStyle.fill,
    );

    final sweepPaint = Paint()
      ..color = accent.withValues(alpha: 0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius * 0.45),
      sweep - 0.45,
      0.9,
      false,
      sweepPaint,
    );

    final streakPaint = Paint()
      ..color = white.withValues(alpha: 0.22)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius * 0.47),
      sweep - 0.05,
      0.1,
      false,
      streakPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ScanSweepPainter oldDelegate) =>
      oldDelegate.phase != phase || oldDelegate.scanMode != scanMode;
}
