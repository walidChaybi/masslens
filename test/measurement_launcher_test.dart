import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mass_lens/features/scan/domain/measured_dimensions.dart';
import 'package:mass_lens/features/scan/presentation/capture/measurement_launcher.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('com.masslens.mass_lens/ar_measure');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() {
    messenger.setMockMethodCallHandler(channel, null);
  });

  test('AR bridge decodes a completed native measurement', () async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      expect(call.method, 'startArMeasurement');
      return <String, Object>{
        'status': 'completed',
        'imagePath': '/tmp/ar-capture.jpg',
        'dimensions': <String, Object>{
          'widthMm': 420.0,
          'heightMm': 210.0,
          'depthMm': 95.0,
          'method': 'arcore_depth',
        },
      };
    });

    final outcome = await const ArMeasurementBridge().start();

    expect(outcome.cancelled, isFalse);
    expect(outcome.shouldFallback, isFalse);
    expect(outcome.capture?.imagePath, '/tmp/ar-capture.jpg');
    expect(outcome.capture?.dimensions?.method, MeasurementMethod.arCoreDepth);
    expect(outcome.capture?.dimensions?.depthMm, 95);
  });

  test('AR bridge keeps cancellation distinct from fallback', () async {
    messenger.setMockMethodCallHandler(
      channel,
      (_) async => <String, Object>{'status': 'cancelled'},
    );
    final cancelled = await const ArMeasurementBridge().start();
    expect(cancelled.cancelled, isTrue);
    expect(cancelled.shouldFallback, isFalse);

    messenger.setMockMethodCallHandler(
      channel,
      (_) async => <String, Object>{'status': 'fallback'},
    );
    final fallback = await const ArMeasurementBridge().start();
    expect(fallback.cancelled, isFalse);
    expect(fallback.shouldFallback, isTrue);
  });

  test('AR bridge falls back for malformed native dimensions', () async {
    messenger.setMockMethodCallHandler(
      channel,
      (_) async => <String, Object>{
        'status': 'completed',
        'imagePath': '/tmp/ar-capture.jpg',
        'dimensions': <String, Object>{
          'widthMm': 0.0,
          'heightMm': 210.0,
          'method': 'arcore_plane',
        },
      },
    );

    final outcome = await const ArMeasurementBridge().start();
    expect(outcome.shouldFallback, isTrue);
  });
}
