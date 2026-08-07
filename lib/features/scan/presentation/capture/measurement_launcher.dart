import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/measurement_capture.dart';
import '../../domain/measured_dimensions.dart';
import 'fallback_camera_screen.dart';
import 'photo_measure_screen.dart';

abstract interface class MeasurementLauncher {
  Future<MeasurementCapture?> launch(BuildContext context);
}

class DeviceMeasurementLauncher implements MeasurementLauncher {
  const DeviceMeasurementLauncher({this.bridge = const ArMeasurementBridge()});

  final ArMeasurementBridge bridge;

  @override
  Future<MeasurementCapture?> launch(BuildContext context) async {
    if (Platform.isAndroid) {
      final outcome = await bridge.start();
      if (outcome.capture != null || outcome.cancelled) return outcome.capture;
    }
    if (!context.mounted) return null;
    final imagePath = await Navigator.of(context).push<String>(
      MaterialPageRoute<String>(builder: (_) => const FallbackCameraScreen()),
    );
    if (imagePath == null || !context.mounted) return null;
    final dimensions = await launchPhotoMeasurement(context, imagePath);
    return MeasurementCapture(imagePath: imagePath, dimensions: dimensions);
  }
}

class ArMeasurementOutcome {
  const ArMeasurementOutcome._({this.capture, this.cancelled = false});

  const ArMeasurementOutcome.completed(MeasurementCapture capture)
    : this._(capture: capture);
  const ArMeasurementOutcome.cancelled() : this._(cancelled: true);
  const ArMeasurementOutcome.fallback() : this._();

  final MeasurementCapture? capture;
  final bool cancelled;

  bool get shouldFallback => capture == null && !cancelled;
}

class ArMeasurementBridge {
  const ArMeasurementBridge();

  static const _channel = MethodChannel('com.masslens.mass_lens/ar_measure');

  Future<ArMeasurementOutcome> start() async {
    try {
      final response = await _channel.invokeMapMethod<Object?, Object?>(
        'startArMeasurement',
      );
      final status = response?['status'];
      if (status == 'cancelled') return const ArMeasurementOutcome.cancelled();
      if (status != 'completed') return const ArMeasurementOutcome.fallback();
      final imagePath = response?['imagePath'];
      final dimensions = response?['dimensions'];
      if (imagePath is! String || dimensions is! Map) {
        return const ArMeasurementOutcome.fallback();
      }
      return ArMeasurementOutcome.completed(
        MeasurementCapture(
          imagePath: imagePath,
          dimensions: MeasuredDimensions.fromJson(dimensions),
        ),
      );
    } on MissingPluginException {
      return const ArMeasurementOutcome.fallback();
    } on PlatformException catch (error) {
      if (error.code == 'cancelled') {
        return const ArMeasurementOutcome.cancelled();
      }
      return const ArMeasurementOutcome.fallback();
    } on FormatException {
      return const ArMeasurementOutcome.fallback();
    }
  }
}

Future<MeasuredDimensions?> launchPhotoMeasurement(
  BuildContext context,
  String imagePath,
) {
  return Navigator.of(context).push<MeasuredDimensions>(
    MaterialPageRoute<MeasuredDimensions>(
      builder: (_) => PhotoMeasureScreen(imagePath: imagePath),
    ),
  );
}
