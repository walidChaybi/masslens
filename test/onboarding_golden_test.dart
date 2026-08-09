import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mass_lens/app/app_controller.dart';
import 'package:mass_lens/app/mass_lens_app.dart';
import 'package:mass_lens/features/measurements/data/measurement_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('all five first-open screens keep their visual contract', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(390, 844));
    final controller = AppController(
      measurementStore: const _FakeMeasurementStore(),
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(MassLensApp(controller: controller));
    await tester.pumpAndSettle();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 150)),
    );
    await tester.pump();
    await _matchScreen(tester, 1);

    await _continue(tester);
    await _matchScreen(tester, 2);

    await _continue(tester);
    await _matchScreen(tester, 3);

    await _continue(tester);
    await tester.pump(const Duration(milliseconds: 250));
    await _matchScreen(tester, 4);

    await tester.pump(const Duration(milliseconds: 1500));
    await tester.pumpAndSettle();
    await _matchScreen(tester, 5);
  });
}

Future<void> _matchScreen(WidgetTester tester, int page) async {
  await expectLater(
    find.byType(MaterialApp),
    matchesGoldenFile('goldens/onboarding_$page.png'),
  );
}

Future<void> _continue(WidgetTester tester) async {
  final button = find.byKey(const Key('onboarding_continue'));
  await tester.ensureVisible(button);
  await tester.tap(button);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

class _FakeMeasurementStore extends MeasurementStore {
  const _FakeMeasurementStore();
}
