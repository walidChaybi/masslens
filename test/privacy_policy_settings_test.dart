import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mass_lens/app/app_controller.dart';
import 'package:mass_lens/core/theme/app_theme.dart';
import 'package:mass_lens/features/measurements/data/measurement_store.dart';
import 'package:mass_lens/features/settings/presentation/settings_screen.dart';
import 'package:mass_lens/l10n/l10n.dart';

void main() {
  testWidgets('settings exposes the required privacy policy link', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
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
          home: const Scaffold(body: SettingsScreen()),
        ),
      ),
    );

    final policyLink = find.text('Privacy policy');
    await tester.scrollUntilVisible(policyLink, 300);
    await tester.tap(policyLink);
    await tester.pump();

    expect(
      find.text('Add the privacy-policy URL in the release configuration.'),
      findsOneWidget,
    );
  });
}
