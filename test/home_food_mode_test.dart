import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mass_lens/app/app_controller.dart';
import 'package:mass_lens/core/theme/app_theme.dart';
import 'package:mass_lens/features/home/presentation/home_screen.dart';
import 'package:mass_lens/features/measurements/data/measurement_store.dart';
import 'package:mass_lens/l10n/l10n.dart';

void main() {
  testWidgets('AI Weight Scan stays object-only and does not offer food mode', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    var scanned = 0;
    var gallery = 0;
    final controller = AppController(
      measurementStore: const MeasurementStore(),
      onboardingComplete: true,
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
            body: HomeScreen(
              onMeasure: () => scanned += 1,
              onGallery: () => gallery += 1,
              onViewHistory: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byKey(const Key('home_scan_mode_selector')), findsNothing);
    expect(find.text('Scan object'), findsOneWidget);
    expect(find.text('Scan food plate'), findsNothing);
    expect(find.text('Food & macros'), findsNothing);

    await tester.tap(find.byKey(const Key('home_scan_button')));
    await tester.tap(find.byKey(const Key('home_gallery_button')));

    expect(scanned, 1);
    expect(gallery, 1);
  });
}
