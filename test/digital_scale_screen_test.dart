import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mass_lens/app/app_controller.dart';
import 'package:mass_lens/core/theme/app_theme.dart';
import 'package:mass_lens/features/measurements/data/measurement_store.dart';
import 'package:mass_lens/features/monetization/application/monetization_controller.dart';
import 'package:mass_lens/features/monetization/data/app_ad_service.dart';
import 'package:mass_lens/features/monetization/data/monetization_api.dart';
import 'package:mass_lens/features/monetization/domain/access_status.dart';
import 'package:mass_lens/features/scale/domain/scale_device.dart';
import 'package:mass_lens/features/scale/domain/scale_reader.dart';
import 'package:mass_lens/features/scale/domain/scale_reading.dart';
import 'package:mass_lens/features/scale/presentation/digital_scale_screen.dart';
import 'package:mass_lens/l10n/l10n.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

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

  testWidgets('compact scale keeps reward CTA above the full native ad', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(360, 640));
    tester.view.padding = const FakeViewPadding(bottom: 48);
    tester.view.viewPadding = const FakeViewPadding(bottom: 48);
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
      tester.view.resetPadding();
      tester.view.resetViewPadding();
    });
    final monetization = MonetizationController.forTesting(
      api: _AdsEnabledMonetizationApi(),
      adService: _AdsEnabledAppAdService(),
    );
    await monetization.initialize();

    await _pumpScale(
      tester,
      _FakeScaleReader(),
      monetizationController: monetization,
    );

    final controlsRect = tester.getRect(
      find.byKey(const Key('scale_unit_button')),
    );
    final rewardRect = tester.getRect(
      find.byKey(const Key('scale_reward_cta')),
    );
    final nativeRect = tester.getRect(
      find.byKey(const Key('native_ad_loading_scale_first_screen')),
    );
    final screenRect = tester.getRect(
      find.byKey(const Key('digital_scale_screen')),
    );
    final viewPadding = MediaQuery.viewPaddingOf(
      tester.element(find.byKey(const Key('digital_scale_screen'))),
    );

    expect(rewardRect.top, greaterThanOrEqualTo(controlsRect.bottom));
    expect(nativeRect.top, greaterThanOrEqualTo(rewardRect.bottom));
    expect(nativeRect.height, 100);
    expect(nativeRect.width, screenRect.width - 32);
    expect(
      nativeRect.bottom,
      lessThanOrEqualTo(screenRect.bottom - viewPadding.bottom),
    );
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(const Key('scale_reward_cta')));
    await tester.pumpAndSettle();
    expect(find.text('Watch one ad. Get one scan.'), findsOneWidget);
  });
}

Future<void> _pumpScale(
  WidgetTester tester,
  _FakeScaleReader reader, {
  MonetizationController? monetizationController,
}) async {
  final controller = AppController(
    measurementStore: const MeasurementStore(),
    onboardingComplete: true,
    monetizationController: monetizationController,
  );
  addTearDown(controller.dispose);
  await tester.pumpWidget(
    AppScope(
      controller: controller,
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: buildAppTheme(),
        home: Scaffold(
          body: DigitalScaleScreen(onOpenAiScan: () {}, reader: reader),
        ),
      ),
    ),
  );
  await tester.pump();
}

final class _AdsEnabledMonetizationApi extends MonetizationApi {
  _AdsEnabledMonetizationApi() : super(apiUrl: 'https://example.invalid');

  @override
  Future<AccessStatus> getAccess(String clientId) async => const AccessStatus(
    starterScansRemaining: 3,
    rewardedScans: 0,
    legacyScans: 0,
    remainingScans: 3,
    rewardBalanceCap: 3,
    scanAccessEnforced: true,
    adsEnabled: true,
    isAuthoritative: true,
    analysisModel: 'gpt-5-nano',
    adPolicy: AdPolicy(),
  );
}

final class _AdsEnabledAppAdService extends AppAdService {
  @override
  bool get canRequestAds => true;

  @override
  bool get canRequestNativeAds => true;

  @override
  bool get rewardedReady => true;

  @override
  Future<void> updatePlan({
    required bool adsAllowed,
    required AdPolicy policy,
  }) async {}

  @override
  void dispose() {}
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
