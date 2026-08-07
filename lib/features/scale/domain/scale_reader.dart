import 'scale_device.dart';
import 'scale_reading.dart';

enum ScaleReaderPhase {
  idle,
  requestingPermission,
  scanning,
  connecting,
  discovering,
  subscribing,
  connected,
  disconnecting,
  unavailable,
  error,
  disposed,
}

enum ScaleReaderErrorCode {
  permissionDenied,
  bluetoothPoweredOff,
  bluetoothUnsupported,
  scanFailed,
  connectionFailed,
  serviceNotFound,
  characteristicNotFound,
  subscriptionFailed,
  malformedMeasurement,
  deviceDisconnected,
  invalidState,
  unknown,
}

final class ScaleReaderError implements Exception {
  const ScaleReaderError(this.code, this.message, {this.cause});

  final ScaleReaderErrorCode code;
  final String message;
  final Object? cause;

  @override
  String toString() => 'ScaleReaderError(${code.name}): $message';
}

/// Immutable state suitable for forwarding from a ChangeNotifier.
final class ScaleReaderSnapshot {
  const ScaleReaderSnapshot({
    required this.phase,
    this.connectedDevice,
    this.message,
  });

  const ScaleReaderSnapshot.idle()
    : phase = ScaleReaderPhase.idle,
      connectedDevice = null,
      message = null;

  final ScaleReaderPhase phase;
  final ScaleDevice? connectedDevice;
  final String? message;

  bool get isConnected => phase == ScaleReaderPhase.connected;

  bool get isBusy => switch (phase) {
    ScaleReaderPhase.requestingPermission ||
    ScaleReaderPhase.scanning ||
    ScaleReaderPhase.connecting ||
    ScaleReaderPhase.discovering ||
    ScaleReaderPhase.subscribing ||
    ScaleReaderPhase.disconnecting => true,
    _ => false,
  };
}

abstract interface class ScaleReader {
  ScaleReaderSnapshot get snapshot;
  List<ScaleDevice> get knownDevices;

  Stream<ScaleReaderSnapshot> get states;
  Stream<List<ScaleDevice>> get devices;
  Stream<ScaleReading> get readings;
  Stream<ScaleReaderError> get errors;

  Future<void> startScan({Duration timeout = const Duration(seconds: 12)});
  Future<void> stopScan();
  Future<void> connect(
    ScaleDevice device, {
    Duration timeout = const Duration(seconds: 30),
  });
  Future<void> disconnect();
  Future<void> dispose();
}
