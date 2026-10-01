import 'package:flutter/material.dart';

import '../../../measurements/domain/measurement.dart';
import 'camera_capture_screen.dart';

abstract interface class CameraLauncher {
  Future<String?> launch(
    BuildContext context, {
    ScanMode scanMode = ScanMode.object,
  });
}

class DeviceCameraLauncher implements CameraLauncher {
  const DeviceCameraLauncher();

  @override
  Future<String?> launch(
    BuildContext context, {
    ScanMode scanMode = ScanMode.object,
  }) {
    return Navigator.of(context).push<String>(
      MaterialPageRoute<String>(
        builder: (_) => CameraCaptureScreen(scanMode: scanMode),
      ),
    );
  }
}
