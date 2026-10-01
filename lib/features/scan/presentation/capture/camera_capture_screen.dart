import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../../../../l10n/l10n.dart';
import '../../../measurements/domain/measurement.dart';

class CameraCaptureScreen extends StatefulWidget {
  const CameraCaptureScreen({this.scanMode = ScanMode.object, super.key});

  final ScanMode scanMode;

  @override
  State<CameraCaptureScreen> createState() => _CameraCaptureScreenState();
}

class _CameraCaptureScreenState extends State<CameraCaptureScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  String? _error;
  bool _capturing = false;
  bool _torch = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_openCamera());
  }

  Future<void> _openCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) throw CameraException('missing', 'No camera');
      final rear = cameras.where(
        (camera) => camera.lensDirection == CameraLensDirection.back,
      );
      final controller = CameraController(
        rear.isEmpty ? cameras.first : rear.first,
        ResolutionPreset.high,
        enableAudio: false,
      );
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() => _controller = controller);
    } on CameraException catch (error) {
      if (mounted) setState(() => _error = _friendlyError(error));
    } on Object {
      if (mounted) setState(() => _error = context.l10n.cameraUnavailable);
    }
  }

  String _friendlyError(CameraException error) {
    if (error.code.toLowerCase().contains('access')) {
      return context.l10n.cameraAccessNeeded;
    }
    return context.l10n.cameraUnavailableDevice;
  }

  Future<void> _capture() async {
    final controller = _controller;
    if (controller == null || _capturing) return;
    setState(() => _capturing = true);
    try {
      final image = await controller.takePicture();
      if (mounted) Navigator.of(context).pop(image.path);
    } on CameraException {
      if (mounted) {
        setState(() {
          _capturing = false;
          _error = context.l10n.cameraCaptureFailed;
        });
      }
    }
  }

  Future<void> _toggleTorch() async {
    final controller = _controller;
    if (controller == null) return;
    try {
      _torch = !_torch;
      await controller.setFlashMode(_torch ? FlashMode.torch : FlashMode.off);
      if (mounted) setState(() {});
    } on CameraException {
      _torch = false;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _controller;
    if (controller == null) return;
    if (state == AppLifecycleState.inactive) {
      _controller = null;
      unawaited(controller.dispose());
    } else if (state == AppLifecycleState.resumed) {
      unawaited(_openCamera());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_controller?.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final isFoodPlate = widget.scanMode == ScanMode.foodPlate;
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        maintainBottomViewPadding: true,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (controller != null && controller.value.isInitialized)
              // CameraPreview already owns the portrait reciprocal ratio and
              // Android rotation. Wrapping it in the sensor's landscape ratio
              // stretches the preview on portrait devices such as the S23.
              Center(child: CameraPreview(controller))
            else
              Center(
                child: _error == null
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Padding(
                        padding: const EdgeInsets.all(32),
                        child: Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      ),
              ),
            Positioned(
              left: 12,
              right: 12,
              top: 8,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _CameraIconButton(
                    tooltip: context.l10n.cameraCloseTooltip,
                    icon: Icons.close_rounded,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  _CameraIconButton(
                    tooltip: _torch
                        ? context.l10n.cameraTorchOffTooltip
                        : context.l10n.cameraTorchOnTooltip,
                    icon: _torch
                        ? Icons.flash_on_rounded
                        : Icons.flash_off_rounded,
                    onPressed: controller == null ? null : _toggleTorch,
                  ),
                ],
              ),
            ),
            if (isFoodPlate) ...[
              Positioned(
                key: const Key('camera_food_label'),
                top: 12,
                left: 72,
                right: 72,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.58),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.restaurant_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                        const SizedBox(width: 7),
                        Flexible(
                          child: Text(
                            context.l10n.scanFoodScale,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 84,
                left: 28,
                right: 28,
                bottom: 126,
                child: _FoodPlateGuide(helper: context.l10n.scanPhotographMeal),
              ),
            ] else
              const Center(child: _CameraReticle()),
            Positioned(
              left: 0,
              right: 0,
              bottom: 28,
              child: Center(
                child: Semantics(
                  button: true,
                  label: context.l10n.cameraTakePhotoSemantics,
                  child: GestureDetector(
                    key: const Key('camera_shutter_button'),
                    onTap: controller == null ? null : _capture,
                    child: Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        border: Border.all(color: Colors.white54, width: 5),
                      ),
                      child: _capturing
                          ? const Padding(
                              padding: EdgeInsets.all(22),
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                              ),
                            )
                          : null,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FoodPlateGuide extends StatelessWidget {
  const _FoodPlateGuide({required this.helper});

  final String helper;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: CustomPaint(
            painter: const _CornerReticlePainter(),
            child: const SizedBox.expand(key: Key('camera_food_plate_guide')),
          ),
        ),
        const SizedBox(height: 14),
        Container(
          key: const Key('camera_food_helper'),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.58),
            borderRadius: BorderRadius.circular(99),
          ),
          child: Text(
            helper,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _CornerReticlePainter extends CustomPainter {
  const _CornerReticlePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    const length = 28.0;
    void corner(Offset origin, double xDir, double yDir) {
      canvas.drawLine(origin, origin + Offset(length * xDir, 0), paint);
      canvas.drawLine(origin, origin + Offset(0, length * yDir), paint);
    }

    corner(Offset.zero, 1, 1);
    corner(Offset(size.width, 0), -1, 1);
    corner(Offset(0, size.height), 1, -1);
    corner(Offset(size.width, size.height), -1, -1);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CameraIconButton extends StatelessWidget {
  const _CameraIconButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton.filled(
      tooltip: tooltip,
      onPressed: onPressed,
      style: IconButton.styleFrom(
        backgroundColor: Colors.black.withValues(alpha: 0.45),
        foregroundColor: Colors.white,
      ),
      icon: Icon(icon),
    );
  }
}

class _CameraReticle extends StatelessWidget {
  const _CameraReticle();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 1.5),
      ),
      child: const Icon(Icons.add_rounded, color: Colors.white, size: 20),
    );
  }
}
