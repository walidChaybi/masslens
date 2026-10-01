import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mass_lens/features/measurements/domain/measurement.dart';
import 'package:mass_lens/features/monetization/domain/access_status.dart';
import 'package:mass_lens/features/scan/presentation/scan_analysis_view.dart';
import 'package:mass_lens/l10n/l10n.dart';

void main() {
  test('server-approved debug access permits scans with an empty wallet', () {
    final access = AccessStatus.fromJson({
      'debugUnlimited': true,
      'scanAccessEnforced': true,
      'remainingScans': 0,
      'hasLifetime': false,
      'adsEnabled': true,
    });
    expect(access.canScan, isTrue);
    expect(access.hasLifetime, isFalse);
    expect(access.adsEnabled, isTrue);
    expect(
      AccessStatus.fromJson({
        'scanAccessEnforced': true,
        'remainingScans': 0,
      }).canScan,
      isFalse,
    );
  });

  testWidgets('analysis fills the screen and renders the extracted subject', (
    tester,
  ) async {
    const channel = MethodChannel('com.masslens.mass_lens/subject_cutout');
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (_) async => 'assets/onboarding/teal_mug.webp',
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        null,
      ),
    );
    await tester.binding.setSurfaceSize(const Size(360, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    var closed = false;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: ScanAnalysisView(
            imagePath: 'assets/onboarding/masslens_hero.webp',
            step: 1,
            scanMode: ScanMode.object,
            onClose: () => closed = true,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(
      tester.getSize(find.byKey(const Key('fullscreen_scan_analysis'))),
      const Size(360, 640),
    );
    expect(find.byType(ImageFiltered), findsOneWidget);
    expect(find.byType(ShaderMask), findsOneWidget);
    await tester.tap(find.byIcon(Icons.close_rounded));
    expect(closed, isTrue);
    expect(tester.takeException(), isNull);
  });
}
