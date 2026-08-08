import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mass_lens/app/app_controller.dart';
import 'package:mass_lens/core/theme/app_theme.dart';
import 'package:mass_lens/features/measurements/data/measurement_store.dart';
import 'package:mass_lens/features/scale/domain/scale_device.dart';
import 'package:mass_lens/features/scale/domain/scale_reader.dart';
import 'package:mass_lens/features/scale/domain/scale_reading.dart';
import 'package:mass_lens/features/scale/presentation/digital_scale_screen.dart';

void main() {
  testWidgets('touch surface visualizes pressure and returns to zero', (
    tester,
  ) async {
    final reader = _FakeScaleReader();
    await _pumpScale(tester, reader);
    final position = tester.getCenter(
      find.byKey(const Key('scale_touch_surface')),
    );

    await tester.sendEventToBinding(
      PointerDownEvent(
        pointer: 1,
        position: position,
        pressure: 0.5,
        pressureMin: 0,
        pressureMax: 1,
      ),
    );
    await tester.pump();
    expect(find.text('1.000'), findsNothing);

    await tester.pump(const Duration(milliseconds: 900));
    expect(find.text('1.000'), findsNothing);

    await tester.pump(const Duration(milliseconds: 1500));
    expect(find.text('1.000'), findsOneWidget);

    await tester.sendEventToBinding(
      PointerUpEvent(pointer: 1, position: position),
    );
    await tester.pump();
    expect(find.text('0.0'), findsNothing);
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.text('0.0'), findsOneWidget);
  });

  testWidgets('connects a standard scale and displays its live reading', (
    tester,
  ) async {
    final reader = _FakeScaleReader();
    await _pumpScale(tester, reader);

    await tester.tap(find.byKey(const Key('open_bluetooth_panel')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('search_scales_button')));
    await tester.pumpAndSettle();

    expect(find.text('Bench scale'), findsOneWidget);
    await tester.tap(find.byKey(const Key('scale_device_scale-1')));
    await tester.pumpAndSettle();

    expect(find.text('LIVE · BLUETOOTH SCALE'), findsOneWidget);
    expect(find.text('1.000'), findsOneWidget);
    expect(find.text('kg'), findsOneWidget);
  });
}

Future<void> _pumpScale(WidgetTester tester, _FakeScaleReader reader) async {
  final controller = AppController(
    measurementStore: const MeasurementStore(),
    onboardingComplete: true,
  );
  await tester.pumpWidget(
    AppScope(
      controller: controller,
      child: MaterialApp(
        theme: buildAppTheme(),
        home: Scaffold(
          body: DigitalScaleScreen(onOpenAiScan: () {}, reader: reader),
        ),
      ),
    ),
  );
  await tester.pump();
}

final class _FakeScaleReader implements ScaleReader {
  final _states = StreamController<ScaleReaderSnapshot>.broadcast(sync: true);
  final _devices = StreamController<List<ScaleDevice>>.broadcast(sync: true);
  final _readings = StreamController<ScaleReading>.broadcast(sync: true);
  final _errors = StreamController<ScaleReaderError>.broadcast(sync: true);

  ScaleReaderSnapshot _snapshot = const ScaleReaderSnapshot.idle();
  List<ScaleDevice> _knownDevices = const [];

  @override
  List<ScaleDevice> get knownDevices => _knownDevices;

  @override
  ScaleReaderSnapshot get snapshot => _snapshot;

  @override
  Stream<List<ScaleDevice>> get devices => _devices.stream;

  @override
  Stream<ScaleReaderError> get errors => _errors.stream;

  @override
  Stream<ScaleReading> get readings => _readings.stream;

  @override
  Stream<ScaleReaderSnapshot> get states => _states.stream;

  @override
  Future<void> startScan({
    Duration timeout = const Duration(seconds: 12),
  }) async {
    _emit(const ScaleReaderSnapshot(phase: ScaleReaderPhase.scanning));
    _knownDevices = [
      ScaleDevice(
        id: 'scale-1',
        name: 'Bench scale',
        rssi: -42,
        lastSeenAt: DateTime.utc(2026, 8, 5),
        advertisedServiceIds: const ['181d'],
      ),
    ];
    _devices.add(_knownDevices);
    _emit(const ScaleReaderSnapshot.idle());
  }

  @override
  Future<void> connect(
    ScaleDevice device, {
    Duration timeout = const Duration(seconds: 30),
  }) async {
    _emit(
      ScaleReaderSnapshot(
        phase: ScaleReaderPhase.connected,
        connectedDevice: device,
      ),
    );
    _readings.add(
      ScaleReading(
        status: ScaleReadingStatus.successful,
        weightGrams: 1000,
        transmittedUnit: ScaleMeasurementUnit.siKilograms,
        source: ScaleReadingSource.standardBluetoothWeightScale,
        deviceId: device.id,
        deviceName: device.name,
        receivedAt: DateTime.utc(2026, 8, 5),
        rawWeight: 200,
        rawFlags: 0,
      ),
    );
  }

  @override
  Future<void> disconnect() async {
    _emit(const ScaleReaderSnapshot.idle());
  }

  @override
  Future<void> stopScan() async {
    _emit(const ScaleReaderSnapshot.idle());
  }

  void _emit(ScaleReaderSnapshot snapshot) {
    _snapshot = snapshot;
    _states.add(snapshot);
  }

  @override
  Future<void> dispose() async {
    await _states.close();
    await _devices.close();
    await _readings.close();
    await _errors.close();
  }
}
