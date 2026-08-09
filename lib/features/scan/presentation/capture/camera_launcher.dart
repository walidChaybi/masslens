import 'package:flutter/material.dart';

import 'camera_capture_screen.dart';

abstract interface class CameraLauncher {
  Future<String?> launch(BuildContext context);
}

class DeviceCameraLauncher implements CameraLauncher {
  const DeviceCameraLauncher();

  @override
  Future<String?> launch(BuildContext context) {
    return Navigator.of(context).push<String>(
      MaterialPageRoute<String>(builder: (_) => const CameraCaptureScreen()),
    );
  }
}
