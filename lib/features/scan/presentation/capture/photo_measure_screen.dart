import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/measured_dimensions.dart';

typedef ImageDecoder = Future<ui.Image> Function(String path);

Future<ui.Image> _decodeImage(String path) async {
  final bytes = await File(path).readAsBytes();
  final codec = await ui.instantiateImageCodec(bytes);
  return (await codec.getNextFrame()).image;
}

enum _MeasureStep { reference, width, height, depth }

class PhotoMeasureScreen extends StatefulWidget {
  const PhotoMeasureScreen({
    required this.imagePath,
    this.decodeImage = _decodeImage,
    super.key,
  });

  final String imagePath;
  final ImageDecoder decodeImage;

  @override
  State<PhotoMeasureScreen> createState() => _PhotoMeasureScreenState();
}

class _PhotoMeasureScreenState extends State<PhotoMeasureScreen> {
  final _customReferenceController = TextEditingController();
  ui.Image? _image;
  String? _error;
  String? _referenceLabel;
  double? _referenceMm;
  _MeasureStep _step = _MeasureStep.reference;
  Offset? _start;
  Offset? _end;
  MeasureCalibration? _calibration;
  _EdgeSnapper? _snapper;
  bool _snapEnabled = true;
  double? _widthMm;
  double? _heightMm;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final image = await widget.decodeImage(widget.imagePath);
      if (mounted) setState(() => _image = image);
      final snapper = await _EdgeSnapper.fromImage(
        image,
      ).catchError((_) => null);
      if (mounted && identical(_image, image)) {
        setState(() => _snapper = snapper);
      }
    } on Object {
      if (mounted) setState(() => _error = 'This photo could not be opened.');
    }
  }

  @override
  void dispose() {
    _customReferenceController.dispose();
    _image?.dispose();
    super.dispose();
  }

  void _selectReference(String label, double millimeters) {
    setState(() {
      _referenceLabel = label;
      _referenceMm = millimeters;
      _step = _MeasureStep.reference;
      _start = null;
      _end = null;
    });
  }

  void _selectCustomReference() {
    final value = double.tryParse(
      _customReferenceController.text.trim().replaceAll(',', '.'),
    );
    if (value == null || value <= 0 || value > 500) {
      setState(() => _error = 'Enter a reference between 0 and 500 mm.');
      return;
    }
    _selectReference('Custom reference', value);
  }

  double? get _lineLength {
    final start = _start;
    final end = _end;
    return start == null || end == null ? null : (end - start).distance;
  }

  double? get _liveMillimeters {
    final pixels = _lineLength;
    final calibration = _calibration;
    if (pixels == null || calibration == null) return null;
    return calibration.toMillimeters(pixels);
  }

  Offset _measurementPoint(Offset localPosition, Size canvasSize) {
    final image = _image;
    final snapper = _snapper;
    if (!_snapEnabled || image == null || snapper == null) {
      return localPosition;
    }
    final destination = _imageDestination(canvasSize, image);
    final scale = destination.width / image.width;
    final clamped = Offset(
      localPosition.dx.clamp(destination.left, destination.right).toDouble(),
      localPosition.dy.clamp(destination.top, destination.bottom).toDouble(),
    );
    final imagePoint = Offset(
      (clamped.dx - destination.left) / scale,
      (clamped.dy - destination.top) / scale,
    );
    final snapped = snapper.snap(
      imagePoint,
      radius: (18 / scale).clamp(4, 34).toDouble(),
    );
    return Offset(
      destination.left + snapped.dx * scale,
      destination.top + snapped.dy * scale,
    );
  }

  void _next() {
    final pixels = _lineLength;
    if (pixels == null) return;
    switch (_step) {
      case _MeasureStep.reference:
        final calibration = MeasureCalibration.fromReference(
          referencePixelLength: pixels,
          referenceMillimeters: _referenceMm ?? 0,
        );
        if (calibration == null) {
          setState(() => _error = 'Move the points farther apart.');
          return;
        }
        setState(() {
          _calibration = calibration;
          _step = _MeasureStep.width;
          _start = null;
          _end = null;
          _error = null;
        });
      case _MeasureStep.width:
        setState(() {
          _widthMm = _calibration!.toMillimeters(pixels);
          _step = _MeasureStep.height;
          _start = null;
          _end = null;
        });
      case _MeasureStep.height:
        _heightMm = _calibration!.toMillimeters(pixels);
        _finish();
      case _MeasureStep.depth:
        _finish(depthMm: _calibration!.toMillimeters(pixels));
    }
  }

  void _measureDepth() {
    final pixels = _lineLength;
    if (pixels == null || _step != _MeasureStep.height) return;
    setState(() {
      _heightMm = _calibration!.toMillimeters(pixels);
      _step = _MeasureStep.depth;
      _start = null;
      _end = null;
    });
  }

  void _finish({double? depthMm}) {
    Navigator.of(context).pop(
      MeasuredDimensions(
        widthMm: _widthMm!,
        heightMm: _heightMm!,
        depthMm: depthMm,
        method: MeasurementMethod.photoReference,
        referenceLabel: _referenceLabel,
      ),
    );
  }

  String get _instruction => switch (_step) {
    _MeasureStep.reference => 'Trace the known edge',
    _MeasureStep.width => 'Trace the object width',
    _MeasureStep.height => 'Trace the object height',
    _MeasureStep.depth => 'Trace the object depth',
  };

  String get _actionLabel => switch (_step) {
    _MeasureStep.reference => 'Set scale',
    _MeasureStep.width => 'Next',
    _MeasureStep.height => 'Finish',
    _MeasureStep.depth => 'Finish',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E1622),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0E1622),
        foregroundColor: Colors.white,
        leading: IconButton(
          key: const Key('measure_back_button'),
          tooltip: 'Close',
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close_rounded),
        ),
        title: const Text('Measure photo'),
        actions: [
          IconButton(
            tooltip: _snapEnabled ? 'Edge snap on' : 'Edge snap off',
            onPressed: _snapper == null
                ? null
                : () => setState(() => _snapEnabled = !_snapEnabled),
            icon: Icon(
              _snapEnabled
                  ? Icons.auto_fix_high_rounded
                  : Icons.touch_app_rounded,
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Skip', style: TextStyle(color: Colors.white70)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _instruction,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (_referenceLabel != null)
                          Text(
                            '$_referenceLabel · ${_referenceMm!.toStringAsFixed(1)} mm',
                            style: const TextStyle(color: Colors.white60),
                          ),
                      ],
                    ),
                  ),
                  if (_liveMillimeters case final value?)
                    Text(
                      '${(value / 10).toStringAsFixed(1)} cm',
                      key: const Key('measure_live_value'),
                      style: const TextStyle(
                        color: AppColors.lime,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final canvasSize = Size(
                        constraints.maxWidth,
                        constraints.maxHeight,
                      );
                      return GestureDetector(
                        key: const Key('measure_canvas'),
                        behavior: HitTestBehavior.opaque,
                        onPanStart: _referenceMm == null
                            ? null
                            : (details) {
                                final point = _measurementPoint(
                                  details.localPosition,
                                  canvasSize,
                                );
                                setState(() {
                                  _start = point;
                                  _end = point;
                                });
                              },
                        onPanUpdate: _referenceMm == null
                            ? null
                            : (details) => setState(
                                () => _end = _measurementPoint(
                                  details.localPosition,
                                  canvasSize,
                                ),
                              ),
                        child: CustomPaint(
                          painter: _PhotoMeasurePainter(
                            image: _image,
                            start: _start,
                            end: _end,
                          ),
                          child: _image == null
                              ? Center(
                                  child: _error == null
                                      ? const CircularProgressIndicator(
                                          color: Colors.white,
                                        )
                                      : Text(
                                          _error!,
                                          style: const TextStyle(
                                            color: Colors.white,
                                          ),
                                        ),
                                )
                              : const SizedBox.expand(),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            if (_referenceMm == null)
              _ReferencePicker(
                customController: _customReferenceController,
                onCard: () => _selectReference('Standard card', 85.6),
                onCoin: () => _selectReference('€1 coin', 23.25),
                onCustom: _selectCustomReference,
              ),
            if (_error != null && _image != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                child: Text(
                  _error!,
                  style: const TextStyle(color: AppColors.coral),
                ),
              ),
            if (_referenceMm != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
                child: Row(
                  children: [
                    if (_step == _MeasureStep.height &&
                        _lineLength != null) ...[
                      TextButton(
                        key: const Key('measure_depth_button'),
                        onPressed: _measureDepth,
                        child: const Text(
                          'Add depth',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],
                    Expanded(
                      child: FilledButton(
                        key: const Key('measure_next_button'),
                        onPressed: _lineLength == null ? null : _next,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.lime,
                          foregroundColor: AppColors.ink,
                        ),
                        child: Text(_actionLabel),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ReferencePicker extends StatelessWidget {
  const _ReferencePicker({
    required this.customController,
    required this.onCard,
    required this.onCoin,
    required this.onCustom,
  });

  final TextEditingController customController;
  final VoidCallback onCard;
  final VoidCallback onCoin;
  final VoidCallback onCustom;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Choose the reference beside the object',
            style: TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  key: const Key('reference_card'),
                  onPressed: onCard,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white30),
                  ),
                  child: const Text('Payment card'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  key: const Key('reference_coin'),
                  onPressed: onCoin,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white30),
                  ),
                  child: const Text('€1 coin'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: customController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: 'Custom size',
                    suffixText: 'mm',
                    hintStyle: TextStyle(color: Colors.white38),
                    suffixStyle: TextStyle(color: Colors.white60),
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Use custom reference',
                onPressed: onCustom,
                color: Colors.white,
                icon: const Icon(Icons.arrow_forward_rounded),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

Rect _imageDestination(Size size, ui.Image image) {
  final scale = math.min(size.width / image.width, size.height / image.height);
  return Rect.fromCenter(
    center: size.center(Offset.zero),
    width: image.width * scale,
    height: image.height * scale,
  );
}

class _EdgeSnapper {
  const _EdgeSnapper({
    required this.width,
    required this.height,
    required this.luminance,
  });

  final int width;
  final int height;
  final Uint8List luminance;

  static Future<_EdgeSnapper?> fromImage(ui.Image image) async {
    final bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    if (bytes == null) return null;
    final rgba = bytes.buffer.asUint8List(
      bytes.offsetInBytes,
      bytes.lengthInBytes,
    );
    final luminance = Uint8List(image.width * image.height);
    var source = 0;
    for (var target = 0; target < luminance.length; target++) {
      final r = rgba[source];
      final g = rgba[source + 1];
      final b = rgba[source + 2];
      luminance[target] = ((r * 299 + g * 587 + b * 114) ~/ 1000)
          .clamp(0, 255)
          .toInt();
      source += 4;
    }
    return _EdgeSnapper(
      width: image.width,
      height: image.height,
      luminance: luminance,
    );
  }

  Offset snap(Offset point, {required double radius}) {
    if (width < 3 || height < 3) return point;
    final centerX = point.dx.round().clamp(1, width - 2).toInt();
    final centerY = point.dy.round().clamp(1, height - 2).toInt();
    final searchRadius = radius.round().clamp(2, 34).toInt();
    final minX = math.max(1, centerX - searchRadius);
    final maxX = math.min(width - 2, centerX + searchRadius);
    final minY = math.max(1, centerY - searchRadius);
    final maxY = math.min(height - 2, centerY + searchRadius);

    var bestScore = 0.0;
    var bestX = centerX;
    var bestY = centerY;
    for (var y = minY; y <= maxY; y++) {
      for (var x = minX; x <= maxX; x++) {
        final index = y * width + x;
        final gx = (luminance[index + 1] - luminance[index - 1]).abs();
        final gy = (luminance[index + width] - luminance[index - width]).abs();
        final edge = gx + gy;
        if (edge < 30) continue;
        final dx = x - point.dx;
        final dy = y - point.dy;
        final score = edge - math.sqrt(dx * dx + dy * dy) * 4.2;
        if (score > bestScore) {
          bestScore = score;
          bestX = x;
          bestY = y;
        }
      }
    }

    if (bestScore < 34) return point;
    return Offset(bestX.toDouble(), bestY.toDouble());
  }
}

class _PhotoMeasurePainter extends CustomPainter {
  const _PhotoMeasurePainter({this.image, this.start, this.end});

  final ui.Image? image;
  final Offset? start;
  final Offset? end;

  @override
  void paint(Canvas canvas, Size size) {
    final image = this.image;
    if (image != null) {
      final destination = _imageDestination(size, image);
      canvas.drawImageRect(
        image,
        Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
        destination,
        Paint(),
      );
    } else {
      canvas.drawColor(const Color(0xFF263140), BlendMode.src);
    }
    final start = this.start;
    final end = this.end;
    if (start == null || end == null) return;
    final line = Paint()
      ..color = AppColors.lime
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(start, end, line);
    final point = Paint()..color = Colors.white;
    canvas.drawCircle(start, 7, point);
    canvas.drawCircle(end, 7, point);
    canvas.drawCircle(start, 3, Paint()..color = AppColors.ink);
    canvas.drawCircle(end, 3, Paint()..color = AppColors.ink);
  }

  @override
  bool shouldRepaint(covariant _PhotoMeasurePainter oldDelegate) {
    return oldDelegate.image != image ||
        oldDelegate.start != start ||
        oldDelegate.end != end;
  }
}
