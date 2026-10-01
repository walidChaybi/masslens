import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mass_lens/app/app_controller.dart';
import 'package:mass_lens/app/mass_lens_app.dart';
import 'package:mass_lens/features/shell/presentation/app_shell.dart';
import 'package:mass_lens/features/measurements/data/measurement_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets(
    'MassLensApp promotes viewPadding.bottom into padding when padding is 0',
    (tester) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));
      addTearDown(tester.view.resetPadding);
      addTearDown(tester.view.resetViewPadding);
      await tester.binding.setSurfaceSize(const Size(360, 640));
      // One UI quirk: padding.bottom is 0 while viewPadding still has the nav.
      // FakeViewPadding is in physical pixels.
      final physicalBottomInset = 48 * tester.view.devicePixelRatio;
      tester.view.padding = FakeViewPadding.zero;
      tester.view.viewPadding = FakeViewPadding(bottom: physicalBottomInset);

      final controller = AppController(
        measurementStore: const MeasurementStore(),
        onboardingComplete: true,
        appUnlockedThisSession: true,
      );
      addTearDown(controller.dispose);
      await tester.pumpWidget(MassLensApp(controller: controller));
      await tester.pump();

      final mediaQuery = MediaQuery.of(tester.element(find.byType(AppShell)));
      expect(mediaQuery.viewPadding.bottom, 48);
      expect(mediaQuery.padding.bottom, 48);
    },
  );
}
