import 'package:flutter_test/flutter_test.dart';
import 'package:mass_lens/app/app_controller.dart';
import 'package:mass_lens/features/measurements/data/measurement_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('cold-launch background timestamp is consumed exactly once', () async {
    final backgroundedAt = DateTime.now().subtract(const Duration(hours: 5));
    SharedPreferences.setMockInitialValues({
      'mass_lens.backgrounded_at_ms': backgroundedAt.millisecondsSinceEpoch,
    });
    final controller = AppController(
      measurementStore: const MeasurementStore(),
      previousBackgroundedAt: backgroundedAt,
    );
    addTearDown(controller.dispose);

    final results = await Future.wait([
      controller.consumePreviousBackgroundDuration(),
      controller.consumePreviousBackgroundDuration(),
    ]);

    expect(results.whereType<Duration>(), hasLength(1));
    expect(
      results.whereType<Duration>().single,
      greaterThanOrEqualTo(const Duration(hours: 5)),
    );
    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getInt('mass_lens.backgrounded_at_ms'), isNull);
    expect(await controller.consumePreviousBackgroundDuration(), isNull);
  });

  test('normal pause record is removed when its resume consumes it', () async {
    final controller = AppController(
      measurementStore: const MeasurementStore(),
    );
    addTearDown(controller.dispose);
    final backgroundedAt = DateTime.now().subtract(const Duration(minutes: 2));

    final recording = controller.recordBackgrounded(backgroundedAt);
    final consuming = controller.consumeBackgroundDuration(backgroundedAt);
    await recording;
    final preferences = await SharedPreferences.getInstance();
    final duration = await consuming;

    expect(duration, isNotNull);
    expect(duration!, greaterThanOrEqualTo(const Duration(minutes: 2)));
    expect(preferences.getInt('mass_lens.backgrounded_at_ms'), isNull);
  });

  test('stale resume cannot clear a newer pause record', () async {
    final controller = AppController(
      measurementStore: const MeasurementStore(),
    );
    addTearDown(controller.dispose);
    final stalePause = DateTime.now().subtract(const Duration(hours: 5));
    final newerPause = stalePause.add(const Duration(hours: 4));
    await controller.recordBackgrounded(stalePause);
    await controller.recordBackgrounded(newerPause);

    expect(await controller.consumeBackgroundDuration(stalePause), isNull);

    final preferences = await SharedPreferences.getInstance();
    expect(
      preferences.getInt('mass_lens.backgrounded_at_ms'),
      newerPause.millisecondsSinceEpoch,
    );
    expect(await controller.consumeBackgroundDuration(newerPause), isNotNull);
    expect(preferences.getInt('mass_lens.backgrounded_at_ms'), isNull);
  });

  test(
    'new pause recorded during consumption remains for its own resume',
    () async {
      final controller = AppController(
        measurementStore: const MeasurementStore(),
      );
      addTearDown(controller.dispose);
      final oldPause = DateTime.now().subtract(const Duration(hours: 5));
      final newPause = oldPause.add(const Duration(hours: 4));
      await controller.recordBackgrounded(oldPause);

      final oldConsumption = controller.consumeBackgroundDuration(oldPause);
      final newRecording = controller.recordBackgrounded(newPause);

      expect(await oldConsumption, isNotNull);
      await newRecording;
      final preferences = await SharedPreferences.getInstance();
      expect(
        preferences.getInt('mass_lens.backgrounded_at_ms'),
        newPause.millisecondsSinceEpoch,
      );
    },
  );
}
