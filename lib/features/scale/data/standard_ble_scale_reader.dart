import 'dart:async';
import 'dart:typed_data';

import 'package:universal_ble/universal_ble.dart';

import '../domain/scale_device.dart';
import '../domain/scale_reader.dart';
import '../domain/scale_reading.dart';

/// Reads Bluetooth SIG Weight Scale Service measurements.
///
/// Only the standard service (0x181D) and Weight Measurement characteristic
/// (0x2A9D) are supported. Vendor-specific scale protocols deliberately remain
/// outside this reader.
final class StandardBleScaleReader implements ScaleReader {
  StandardBleScaleReader() {
    _availabilitySubscription = UniversalBle.availabilityStream.listen(
      _handleAvailability,
      onError: (Object error) => _report(
        ScaleReaderError(
          ScaleReaderErrorCode.unknown,
          'Bluetooth availability could not be monitored.',
          cause: error,
        ),
      ),
    );
  }

  static const weightScaleServiceUuid = '0000181d-0000-1000-8000-00805f9b34fb';
  static const weightMeasurementCharacteristicUuid =
      '00002a9d-0000-1000-8000-00805f9b34fb';

  final _stateController = StreamController<ScaleReaderSnapshot>.broadcast(
    sync: true,
  );
  final _deviceController = StreamController<List<ScaleDevice>>.broadcast(
    sync: true,
  );
  final _readingController = StreamController<ScaleReading>.broadcast(
    sync: true,
  );
  final _errorController = StreamController<ScaleReaderError>.broadcast(
    sync: true,
  );
  final Map<String, ScaleDevice> _knownDevices = {};

  ScaleReaderSnapshot _snapshot = const ScaleReaderSnapshot.idle();
  StreamSubscription<AvailabilityState>? _availabilitySubscription;
  StreamSubscription<BleDevice>? _scanSubscription;
  StreamSubscription<bool>? _connectionSubscription;
  StreamSubscription<Uint8List>? _valueSubscription;
  Timer? _scanTimer;
  ScaleDevice? _connectedDevice;
  String? _subscribedServiceUuid;
  String? _subscribedCharacteristicUuid;
  bool _explicitDisconnect = false;
  bool _scanStarted = false;
  bool _disposed = false;
  int _operationGeneration = 0;

  @override
  ScaleReaderSnapshot get snapshot => _snapshot;

  @override
  List<ScaleDevice> get knownDevices => _sortedDeviceSnapshot();

  @override
  Stream<ScaleReaderSnapshot> get states => _stateController.stream;

  @override
  Stream<List<ScaleDevice>> get devices => _deviceController.stream;

  @override
  Stream<ScaleReading> get readings => _readingController.stream;

  @override
  Stream<ScaleReaderError> get errors => _errorController.stream;

  @override
  Future<void> startScan({
    Duration timeout = const Duration(seconds: 12),
  }) async {
    _ensureUsable();
    if (_connectedDevice != null ||
        {
          ScaleReaderPhase.connecting,
          ScaleReaderPhase.discovering,
          ScaleReaderPhase.subscribing,
          ScaleReaderPhase.disconnecting,
        }.contains(_snapshot.phase)) {
      throw _emitError(
        const ScaleReaderError(
          ScaleReaderErrorCode.invalidState,
          'Disconnect the current scale before scanning.',
        ),
      );
    }

    final generation = ++_operationGeneration;
    await stopScan();
    if (!_isCurrent(generation)) return;
    _emit(
      const ScaleReaderSnapshot(phase: ScaleReaderPhase.requestingPermission),
    );

    try {
      await _requestPermissions();
      await _requirePoweredOnBluetooth();
      if (!_isCurrent(generation)) return;

      _scanSubscription = UniversalBle.scanStream.listen(
        _handleScanResult,
        onError: (Object error) => _failNonThrowing(
          _mapError(
            error,
            ScaleReaderErrorCode.scanFailed,
            'Bluetooth scanning failed.',
          ),
        ),
      );

      _emit(const ScaleReaderSnapshot(phase: ScaleReaderPhase.scanning));
      await UniversalBle.startScan(
        scanFilter: ScanFilter(withServices: [weightScaleServiceUuid]),
      );
      _scanStarted = true;
      if (!_isCurrent(generation)) {
        await stopScan();
        return;
      }

      try {
        final systemDevices = await UniversalBle.getSystemDevices(
          withServices: [weightScaleServiceUuid],
        );
        for (final device in systemDevices) {
          _handleScanResult(device);
        }
      } on Object catch (error) {
        _report(
          _mapError(
            error,
            ScaleReaderErrorCode.scanFailed,
            'Already-connected scales could not be queried.',
          ),
        );
      }

      if (timeout > Duration.zero) {
        _scanTimer = Timer(timeout, () => unawaited(stopScan()));
      }
    } on ScaleReaderError catch (error) {
      await stopScan();
      _failNonThrowing(error);
      rethrow;
    } on Object catch (error) {
      final mapped = _mapError(
        error,
        ScaleReaderErrorCode.scanFailed,
        'Bluetooth scanning could not start.',
      );
      await stopScan();
      _failNonThrowing(mapped);
      throw mapped;
    }
  }

  @override
  Future<void> stopScan() async {
    _scanTimer?.cancel();
    _scanTimer = null;
    final subscription = _scanSubscription;
    _scanSubscription = null;
    await subscription?.cancel();

    if (_scanStarted) {
      _scanStarted = false;
      try {
        await UniversalBle.stopScan();
      } on Object catch (error) {
        if (!_disposed) {
          _report(
            _mapError(
              error,
              ScaleReaderErrorCode.scanFailed,
              'Bluetooth scanning could not stop cleanly.',
            ),
          );
        }
      }
    }

    if (!_disposed && _snapshot.phase == ScaleReaderPhase.scanning) {
      _emit(const ScaleReaderSnapshot.idle());
    }
  }

  @override
  Future<void> connect(
    ScaleDevice device, {
    Duration timeout = const Duration(seconds: 30),
  }) async {
    _ensureUsable();
    if (_connectedDevice?.id == device.id && _snapshot.isConnected) return;

    final generation = ++_operationGeneration;
    await stopScan();
    if (_connectedDevice != null) await _cleanupConnection(disconnect: true);
    if (!_isCurrent(generation)) return;

    _connectedDevice = _knownDevices[device.id] ?? device;
    _emit(
      ScaleReaderSnapshot(
        phase: ScaleReaderPhase.connecting,
        connectedDevice: _connectedDevice,
      ),
    );

    try {
      await _requestPermissions();
      await _requirePoweredOnBluetooth();
      if (!_isCurrent(generation)) return;

      _connectionSubscription = UniversalBle.connectionStream(device.id).listen(
        (connected) {
          if (!connected && !_explicitDisconnect && !_disposed) {
            unawaited(_handleUnexpectedDisconnect(device));
          }
        },
        onError: (Object error) => _report(
          _mapError(
            error,
            ScaleReaderErrorCode.connectionFailed,
            'The scale connection stream failed.',
          ),
        ),
      );
      await UniversalBle.connect(device.id, timeout: timeout);
      if (!_isCurrent(generation)) return;

      _emit(
        ScaleReaderSnapshot(
          phase: ScaleReaderPhase.discovering,
          connectedDevice: _connectedDevice,
        ),
      );
      final services = await UniversalBle.discoverServices(
        device.id,
        timeout: timeout,
      );
      if (!_isCurrent(generation)) return;

      final service = _findWeightScaleService(services);
      final characteristic = _findWeightMeasurementCharacteristic(service);
      final supportsIndications = characteristic.properties.contains(
        CharacteristicProperty.indicate,
      );
      final supportsNotifications = characteristic.properties.contains(
        CharacteristicProperty.notify,
      );
      if (!supportsIndications && !supportsNotifications) {
        throw const ScaleReaderError(
          ScaleReaderErrorCode.subscriptionFailed,
          'The Weight Measurement characteristic cannot indicate or notify.',
        );
      }

      _emit(
        ScaleReaderSnapshot(
          phase: ScaleReaderPhase.subscribing,
          connectedDevice: _connectedDevice,
        ),
      );
      _subscribedServiceUuid = service.uuid;
      _subscribedCharacteristicUuid = characteristic.uuid;
      _valueSubscription =
          UniversalBle.characteristicValueStream(
            device.id,
            characteristic.uuid,
          ).listen(
            _handleMeasurement,
            onError: (Object error) => _report(
              _mapError(
                error,
                ScaleReaderErrorCode.subscriptionFailed,
                'Weight updates stopped unexpectedly.',
              ),
            ),
          );

      if (supportsIndications) {
        await UniversalBle.subscribeIndications(
          device.id,
          service.uuid,
          characteristic.uuid,
          timeout: timeout,
        );
      } else {
        await UniversalBle.subscribeNotifications(
          device.id,
          service.uuid,
          characteristic.uuid,
          timeout: timeout,
        );
      }
      if (!_isCurrent(generation)) return;

      _emit(
        ScaleReaderSnapshot(
          phase: ScaleReaderPhase.connected,
          connectedDevice: _connectedDevice,
        ),
      );
    } on ScaleReaderError catch (error) {
      await _cleanupConnection(disconnect: true);
      _failNonThrowing(error);
      rethrow;
    } on Object catch (error) {
      final mapped = _mapError(
        error,
        ScaleReaderErrorCode.connectionFailed,
        'The weight scale could not be connected.',
      );
      await _cleanupConnection(disconnect: true);
      _failNonThrowing(mapped);
      throw mapped;
    }
  }

  @override
  Future<void> disconnect() async {
    if (_disposed) return;
    ++_operationGeneration;
    await stopScan();
    final device = _connectedDevice;
    if (device == null) {
      _emit(const ScaleReaderSnapshot.idle());
      return;
    }

    _emit(
      ScaleReaderSnapshot(
        phase: ScaleReaderPhase.disconnecting,
        connectedDevice: device,
      ),
    );
    await _cleanupConnection(disconnect: true);
    if (!_disposed) _emit(const ScaleReaderSnapshot.idle());
  }

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    ++_operationGeneration;
    _disposed = true;
    _scanTimer?.cancel();
    _scanTimer = null;
    await _scanSubscription?.cancel();
    _scanSubscription = null;
    if (_scanStarted) {
      _scanStarted = false;
      try {
        await UniversalBle.stopScan();
      } on Object {
        // Disposal is best-effort; all local listeners are still released.
      }
    }
    await _cleanupConnection(disconnect: true);
    await _availabilitySubscription?.cancel();
    _availabilitySubscription = null;
    _snapshot = const ScaleReaderSnapshot(phase: ScaleReaderPhase.disposed);
    await _stateController.close();
    await _deviceController.close();
    await _readingController.close();
    await _errorController.close();
  }

  Future<void> _requestPermissions() async {
    var granted = await UniversalBle.hasPermissions();
    if (!granted) {
      await UniversalBle.requestPermissions();
      granted = await UniversalBle.hasPermissions();
    }
    if (!granted) {
      throw const ScaleReaderError(
        ScaleReaderErrorCode.permissionDenied,
        'Bluetooth permission is required to find a weight scale.',
      );
    }
  }

  Future<void> _requirePoweredOnBluetooth() async {
    final availability = await UniversalBle.getBluetoothAvailabilityState();
    switch (availability) {
      case AvailabilityState.poweredOn:
        return;
      case AvailabilityState.poweredOff:
        throw const ScaleReaderError(
          ScaleReaderErrorCode.bluetoothPoweredOff,
          'Turn on Bluetooth to use a weight scale.',
        );
      case AvailabilityState.unsupported:
        throw const ScaleReaderError(
          ScaleReaderErrorCode.bluetoothUnsupported,
          'Bluetooth Low Energy is not supported on this device.',
        );
      case AvailabilityState.unauthorized:
        throw const ScaleReaderError(
          ScaleReaderErrorCode.permissionDenied,
          'Bluetooth access is not authorized.',
        );
      case AvailabilityState.unknown:
      case AvailabilityState.resetting:
        throw const ScaleReaderError(
          ScaleReaderErrorCode.bluetoothPoweredOff,
          'Bluetooth is not ready yet.',
        );
    }
  }

  void _handleScanResult(BleDevice result) {
    if (_disposed) return;
    final services = result.services
        .map(BleUuidParser.stringOrNull)
        .whereType<String>()
        .toList();
    if (services.isNotEmpty &&
        !services.any(
          (service) =>
              BleUuidParser.compareStrings(service, weightScaleServiceUuid),
        )) {
      return;
    }
    final seenAt = result.timestampDateTime?.toUtc() ?? DateTime.now().toUtc();
    final previous = _knownDevices[result.deviceId];
    _knownDevices[result.deviceId] = ScaleDevice(
      id: result.deviceId,
      name: result.name ?? previous?.name,
      rssi: result.rssi ?? previous?.rssi,
      lastSeenAt: seenAt,
      advertisedServiceIds: services.isEmpty
          ? previous?.advertisedServiceIds ?? const []
          : services,
    );
    _deviceController.add(_sortedDeviceSnapshot());
  }

  BleService _findWeightScaleService(List<BleService> services) {
    for (final service in services) {
      if (BleUuidParser.compareStrings(service.uuid, weightScaleServiceUuid)) {
        return service;
      }
    }
    throw const ScaleReaderError(
      ScaleReaderErrorCode.serviceNotFound,
      'This device does not expose the standard Weight Scale Service.',
    );
  }

  BleCharacteristic _findWeightMeasurementCharacteristic(BleService service) {
    for (final characteristic in service.characteristics) {
      if (BleUuidParser.compareStrings(
        characteristic.uuid,
        weightMeasurementCharacteristicUuid,
      )) {
        return characteristic;
      }
    }
    throw const ScaleReaderError(
      ScaleReaderErrorCode.characteristicNotFound,
      'The scale has no standard Weight Measurement characteristic.',
    );
  }

  void _handleMeasurement(Uint8List value) {
    final device = _connectedDevice;
    if (_disposed || device == null) return;
    try {
      _readingController.add(
        WeightScaleMeasurementParser.parse(
          value,
          deviceId: device.id,
          deviceName: device.name,
        ),
      );
    } on WeightScaleParseException catch (error) {
      _report(
        ScaleReaderError(
          ScaleReaderErrorCode.malformedMeasurement,
          error.message,
          cause: error,
        ),
      );
    }
  }

  Future<void> _handleUnexpectedDisconnect(ScaleDevice device) async {
    if (_explicitDisconnect || _disposed || _connectedDevice?.id != device.id) {
      return;
    }
    ++_operationGeneration;
    await _cleanupConnection(disconnect: false);
    _failNonThrowing(
      ScaleReaderError(
        ScaleReaderErrorCode.deviceDisconnected,
        '${device.displayName} disconnected.',
      ),
    );
  }

  Future<void> _cleanupConnection({required bool disconnect}) async {
    final device = _connectedDevice;
    _explicitDisconnect = true;
    try {
      final service = _subscribedServiceUuid;
      final characteristic = _subscribedCharacteristicUuid;
      if (device != null && service != null && characteristic != null) {
        try {
          await UniversalBle.unsubscribe(device.id, service, characteristic);
        } on Object {
          // A remote disconnect can make unsubscribe impossible.
        }
      }
      await _valueSubscription?.cancel();
      _valueSubscription = null;
      _subscribedServiceUuid = null;
      _subscribedCharacteristicUuid = null;
      if (disconnect && device != null) {
        try {
          await UniversalBle.disconnect(
            device.id,
            timeout: const Duration(seconds: 8),
          );
        } on Object {
          // UniversalBle disconnect is best-effort and local state still clears.
        }
      }
      await _connectionSubscription?.cancel();
      _connectionSubscription = null;
      _connectedDevice = null;
    } finally {
      _explicitDisconnect = false;
    }
  }

  void _handleAvailability(AvailabilityState availability) {
    if (_disposed) return;
    if (availability == AvailabilityState.poweredOn) {
      if (_snapshot.phase == ScaleReaderPhase.unavailable) {
        _emit(const ScaleReaderSnapshot.idle());
      }
      return;
    }

    final error = switch (availability) {
      AvailabilityState.unsupported => const ScaleReaderError(
        ScaleReaderErrorCode.bluetoothUnsupported,
        'Bluetooth Low Energy is not supported on this device.',
      ),
      AvailabilityState.unauthorized => const ScaleReaderError(
        ScaleReaderErrorCode.permissionDenied,
        'Bluetooth access is not authorized.',
      ),
      AvailabilityState.poweredOff => const ScaleReaderError(
        ScaleReaderErrorCode.bluetoothPoweredOff,
        'Bluetooth is turned off.',
      ),
      AvailabilityState.unknown || AvailabilityState.resetting => null,
      AvailabilityState.poweredOn => null,
    };
    if (error == null) return;
    _report(error);
    _emit(
      ScaleReaderSnapshot(
        phase: ScaleReaderPhase.unavailable,
        message: error.message,
      ),
    );
    if (_scanSubscription != null || _connectedDevice != null) {
      unawaited(_stopForUnavailableBluetooth());
    }
  }

  Future<void> _stopForUnavailableBluetooth() async {
    ++_operationGeneration;
    await stopScan();
    await _cleanupConnection(disconnect: false);
  }

  List<ScaleDevice> _sortedDeviceSnapshot() {
    final result = _knownDevices.values.toList()
      ..sort((left, right) {
        final bySignal = (right.rssi ?? -1000).compareTo(left.rssi ?? -1000);
        if (bySignal != 0) return bySignal;
        return left.displayName.compareTo(right.displayName);
      });
    return List.unmodifiable(result);
  }

  bool _isCurrent(int generation) =>
      !_disposed && generation == _operationGeneration;

  void _ensureUsable() {
    if (_disposed) {
      throw const ScaleReaderError(
        ScaleReaderErrorCode.invalidState,
        'This scale reader has been disposed.',
      );
    }
  }

  void _emit(ScaleReaderSnapshot value) {
    if (_disposed || _stateController.isClosed) return;
    _snapshot = value;
    _stateController.add(value);
  }

  void _report(ScaleReaderError error) {
    if (_disposed || _errorController.isClosed) return;
    _errorController.add(error);
  }

  ScaleReaderError _emitError(ScaleReaderError error) {
    _report(error);
    return error;
  }

  void _failNonThrowing(ScaleReaderError error) {
    if (_disposed) return;
    _report(error);
    _emit(
      ScaleReaderSnapshot(
        phase: ScaleReaderPhase.error,
        message: error.message,
      ),
    );
  }

  ScaleReaderError _mapError(
    Object error,
    ScaleReaderErrorCode fallbackCode,
    String fallbackMessage,
  ) {
    if (error is ScaleReaderError) return error;
    if (error is UniversalBleException) {
      final code = switch (error.code) {
        UniversalBleErrorCode.bluetoothUnauthorized ||
        UniversalBleErrorCode.bluetoothNotAllowed ||
        UniversalBleErrorCode.accessDenied =>
          ScaleReaderErrorCode.permissionDenied,
        UniversalBleErrorCode.bluetoothNotEnabled =>
          ScaleReaderErrorCode.bluetoothPoweredOff,
        UniversalBleErrorCode.bluetoothNotAvailable ||
        UniversalBleErrorCode.notSupported =>
          ScaleReaderErrorCode.bluetoothUnsupported,
        UniversalBleErrorCode.serviceNotFound =>
          ScaleReaderErrorCode.serviceNotFound,
        UniversalBleErrorCode.characteristicNotFound =>
          ScaleReaderErrorCode.characteristicNotFound,
        UniversalBleErrorCode.characteristicDoesNotSupportIndicate ||
        UniversalBleErrorCode.characteristicDoesNotSupportNotify =>
          ScaleReaderErrorCode.subscriptionFailed,
        _ => fallbackCode,
      };
      return ScaleReaderError(code, fallbackMessage, cause: error);
    }
    return ScaleReaderError(fallbackCode, fallbackMessage, cause: error);
  }
}
