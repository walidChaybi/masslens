import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mass_lens/app/app_controller.dart';
import 'package:mass_lens/core/theme/app_theme.dart';
import 'package:mass_lens/features/home/presentation/home_screen.dart';
import 'package:mass_lens/features/measurements/data/measurement_store.dart';
import 'package:mass_lens/features/measurements/domain/measurement.dart';
import 'package:mass_lens/l10n/l10n.dart';

void main() {
  testWidgets('home defaults to Object mode and forwards Object actions', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final scanModes = <ScanMode>[];
    final galleryModes = <ScanMode>[];
    final controller = AppController(
      measurementStore: const MeasurementStore(),
      onboardingComplete: true,
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      _TestApp(
        controller: controller,
        onMeasure: scanModes.add,
        onGallery: galleryModes.add,
      ),
    );
    await tester.pump();

    final selector = tester.widget<SegmentedButton<ScanMode>>(
      find.byKey(const Key('home_scan_mode_selector')),
    );
    expect(selector.selected, const <ScanMode>{ScanMode.object});
    expect(find.text('Scan object'), findsOneWidget);
    expect(find.text('Scan food plate'), findsNothing);

    await tester.tap(find.byKey(const Key('home_scan_button')));
    await tester.tap(find.byKey(const Key('home_gallery_button')));

    expect(scanModes, <ScanMode>[ScanMode.object]);
    expect(galleryModes, <ScanMode>[ScanMode.object]);
  });

  testWidgets('home switches to Food & macros and forwards food actions', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final scanModes = <ScanMode>[];
    final galleryModes = <ScanMode>[];
    final controller = AppController(
      measurementStore: const MeasurementStore(),
      onboardingComplete: true,
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      _TestApp(
        controller: controller,
        onMeasure: scanModes.add,
        onGallery: galleryModes.add,
      ),
    );
    await tester.pump();

    await tester.tap(find.text('Food & macros'));
    await tester.pump();

    final selector = tester.widget<SegmentedButton<ScanMode>>(
      find.byKey(const Key('home_scan_mode_selector')),
    );
    expect(selector.selected, const <ScanMode>{ScanMode.foodPlate});
    expect(find.text('Scan food plate'), findsOneWidget);
    expect(
      find.textContaining('estimate each food\'s weight, calories and macros'),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('home_scan_button')));
    await tester.tap(find.byKey(const Key('home_gallery_button')));

    expect(scanModes, <ScanMode>[ScanMode.foodPlate]);
    expect(galleryModes, <ScanMode>[ScanMode.foodPlate]);
  });
}

class _TestApp extends StatelessWidget {
  const _TestApp({
    required this.controller,
    required this.onMeasure,
    required this.onGallery,
  });

  final AppController controller;
  final ValueChanged<ScanMode> onMeasure;
  final ValueChanged<ScanMode> onGallery;

  @override
  Widget build(BuildContext context) {
    return AppScope(
      controller: controller,
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: buildAppTheme(),
        home: Scaffold(
          body: HomeScreen(
            onMeasure: onMeasure,
            onGallery: onGallery,
            onViewHistory: () {},
          ),
        ),
      ),
    );
  }
}
