import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mass_lens/app/app_controller.dart';
import 'package:mass_lens/app/launch_gate.dart';
import 'package:mass_lens/app/mass_lens_app.dart';
import 'package:mass_lens/features/measurements/data/measurement_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('paints the splash first, then the app once data loads', (
    tester,
  ) async {
    final loaded = Completer<AppController>();
    await tester.pumpWidget(LaunchGate(bootstrap: () => loaded.future));

    expect(find.byKey(const Key('launch_placeholder')), findsOneWidget);
    expect(find.byKey(const Key('home_scan_button')), findsNothing);

    final controller = AppController(
      measurementStore: const MeasurementStore(),
      onboardingComplete: true,
      appUnlockedThisSession: true,
    );
    loaded.complete(controller);
    await tester.pump();
    await tester.pump();

    expect(find.byKey(const Key('launch_placeholder')), findsNothing);
    expect(find.byKey(const Key('home_scan_button')), findsOneWidget);
  });

  testWidgets('falls back to an empty app if bootstrap fails', (tester) async {
    await tester.pumpWidget(
      LaunchGate(bootstrap: () async => throw StateError('boom')),
    );
    await tester.pump();
    await tester.pump();

    expect(find.byKey(const Key('launch_placeholder')), findsNothing);
    expect(find.byType(MassLensApp), findsOneWidget);
  });
}
