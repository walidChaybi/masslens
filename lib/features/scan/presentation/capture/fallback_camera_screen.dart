import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class FallbackCameraScreen extends StatefulWidget {
  const FallbackCameraScreen({super.key});

  @override
  State<FallbackCameraScreen> createState() => _FallbackCameraScreenState();
}

class _FallbackCameraScreenState extends State<FallbackCameraScreen>
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
      if (mounted) setState(() => _error = 'Camera is unavailable.');
    }
  }

  String _friendlyError(CameraException error) {
    if (error.code.toLowerCase().contains('access')) {
      return 'Camera access is needed to photograph the object.';
    }
    return 'Camera is unavailable on this device.';
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
          _error = 'The photo could not be captured. Try again.';
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
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (controller != null && controller.value.isInitialized)
              Center(
                child: AspectRatio(
                  aspectRatio: controller.value.aspectRatio,
                  child: CameraPreview(controller),
                ),
              )
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
                    tooltip: 'Close',
                    icon: Icons.close_rounded,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  _CameraIconButton(
                    tooltip: _torch ? 'Turn torch off' : 'Turn torch on',
                    icon: _torch
                        ? Icons.flash_on_rounded
                        : Icons.flash_off_rounded,
                    onPressed: controller == null ? null : _toggleTorch,
                  ),
                ],
              ),
            ),
            const Center(child: _CameraReticle()),
            Positioned(
              left: 0,
              right: 0,
              bottom: 28,
              child: Center(
                child: Semantics(
                  button: true,
                  label: 'Take photo',
                  child: GestureDetector(
                    key: const Key('fallback_shutter_button'),
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
