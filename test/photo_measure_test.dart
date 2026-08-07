import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mass_lens/core/theme/app_theme.dart';
import 'package:mass_lens/features/measurements/domain/measurement.dart';
import 'package:mass_lens/features/scan/data/demo_estimate_repository.dart';
import 'package:mass_lens/features/scan/domain/estimate_repository.dart';
import 'package:mass_lens/features/scan/domain/measured_dimensions.dart';
import 'package:mass_lens/features/scan/presentation/capture/photo_measure_screen.dart';

Future<ui.Image> _fakeImage(String path) async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  canvas.drawRect(
    const Rect.fromLTWH(0, 0, 400, 300),
    ui.Paint()..color = const Color(0xFF8A8F98),
  );
  final picture = recorder.endRecording();
  return picture.toImage(400, 300);
}

void main() {
  test('calibration converts traced pixels to clamped millimeters', () {
    final calibration = MeasureCalibration.fromReference(
      referencePixelLength: 171.2,
      referenceMillimeters: 85.6,
    );

    expect(calibration, isNotNull);
    expect(calibration!.toMillimeters(171.2), closeTo(85.6, 0.05));
    expect(calibration.toMillimeters(85.6), closeTo(42.8, 0.05));
    expect(calibration.toMillimeters(0.1), MeasureCalibration.minMillimeters);
    expect(
      calibration.toMillimeters(100000),
      MeasureCalibration.maxMillimeters,
    );

    expect(
      MeasureCalibration.fromReference(
        referencePixelLength: 2,
        referenceMillimeters: 85.6,
      ),
      isNull,
    );
    expect(
      MeasureCalibration.fromReference(
        referencePixelLength: 120,
        referenceMillimeters: 0,
      ),
      isNull,
    );
  });

  test('measured dimensions serialize and summarize', () {
    const measured = MeasuredDimensions(
      widthMm: 142.4,
      heightMm: 90.1,
      depthMm: 61,
      referenceLabel: 'Standard card',
    );

    expect(measured.toJson(), {
      'widthMm': 142.4,
      'heightMm': 90.1,
      'depthMm': 61.0,
      'method': 'photo_reference',
      'referenceLabel': 'Standard card',
    });
    expect(measured.formatSummary(), '14.2 × 9.0 × 6.1 cm');

    const withoutDepth = MeasuredDimensions(
      widthMm: 142.4,
      heightMm: 90.1,
      referenceLabel: '€1 coin',
    );
    expect(withoutDepth.toJson().containsKey('depthMm'), isFalse);
    expect(withoutDepth.formatSummary(), '14.2 × 9.0 cm');
  });

  test('measured dimensions validate bounds and method names', () {
    expect(
      const MeasuredDimensions(widthMm: 5, heightMm: 5000).isValid,
      isTrue,
    );
    expect(
      const MeasuredDimensions(widthMm: 4.9, heightMm: 100).isValid,
      isFalse,
    );
    expect(
      () => const MeasuredDimensions(widthMm: 100, heightMm: 5001).toJson(),
      throwsFormatException,
    );
    expect(MeasurementMethod.fromWireName('arcore_plane').label, 'AR surface');
    expect(
      () => MeasuredDimensions.fromJson(const {
        'widthMm': 100,
        'heightMm': 100,
        'method': 'unknown',
      }),
      throwsFormatException,
    );
  });

  test(
    'demo repository adopts traced dimensions and raises confidence',
    () async {
      const repository = DemoEstimateRepository(analysisDelay: Duration.zero);
      final result = await repository.analyze(
        const EstimateRequest(
          imagePath: '/tmp/non-existent.jpg',
          measuredDimensions: MeasuredDimensions(
            widthMm: 200,
            heightMm: 100,
            depthMm: 50,
            referenceLabel: 'Standard card',
          ),
        ),
      );

      expect(result.confidence, ConfidenceLevel.medium);
      expect(result.dimensions.width, 200);
      expect(result.dimensions.height, 100);
      expect(result.dimensions.depth, 50);
      expect(
        result.assumptions,
        contains(
          '20.0 × 10.0 × 5.0 cm measured with Photo reference · Standard card',
        ),
      );

      final noDepth = await repository.analyze(
        const EstimateRequest(
          imagePath: '/tmp/non-existent.jpg',
          measuredDimensions: MeasuredDimensions(
            widthMm: 200,
            heightMm: 100,
            referenceLabel: 'Standard card',
          ),
        ),
      );
      expect(noDepth.dimensions.depth, greaterThan(0));
    },
  );

  testWidgets('trace reference, width, and height to produce a measurement', (
    tester,
  ) async {
    MeasuredDimensions? result;
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                result = await Navigator.of(context).push<MeasuredDimensions>(
                  MaterialPageRoute<MeasuredDimensions>(
                    builder: (_) => const PhotoMeasureScreen(
                      imagePath: 'fake',
                      decodeImage: _fakeImage,
                    ),
                  ),
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    // Reference step: pick the card and trace its long edge.
    await tester.tap(find.byKey(const Key('reference_card')));
    await tester.pumpAndSettle();
    expect(find.text('Standard card · 85.6 mm'), findsOneWidget);

    final canvas = find.byKey(const Key('measure_canvas'));
    final center = tester.getCenter(canvas);
    await tester.dragFrom(center - const Offset(80, 0), const Offset(160, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('measure_next_button')));
    await tester.pumpAndSettle();

    // Width step: trace a shorter line and read the live value.
    await tester.dragFrom(center - const Offset(50, 30), const Offset(100, 0));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('measure_live_value')), findsOneWidget);
    await tester.tap(find.byKey(const Key('measure_next_button')));
    await tester.pumpAndSettle();

    // Height step: trace vertically, then finish.
    await tester.dragFrom(center - const Offset(60, 20), const Offset(0, 80));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('measure_next_button')));
    await tester.pumpAndSettle();

    expect(result, isNotNull);
    expect(result!.referenceLabel, 'Standard card');
    expect(result!.widthMm, greaterThan(20));
    expect(result!.widthMm, lessThan(85.6));
    expect(result!.heightMm, greaterThan(15));
    expect(result!.heightMm, lessThan(68.4));
    expect(result!.depthMm, isNull);
  });

  testWidgets('skipping measurement returns null', (tester) async {
    MeasuredDimensions? result = const MeasuredDimensions(
      widthMm: 1,
      heightMm: 1,
      referenceLabel: 'sentinel',
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                result = await Navigator.of(context).push<MeasuredDimensions>(
                  MaterialPageRoute<MeasuredDimensions>(
                    builder: (_) => const PhotoMeasureScreen(
                      imagePath: 'fake',
                      decodeImage: _fakeImage,
                    ),
                  ),
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('measure_back_button')));
    await tester.pumpAndSettle();
    expect(result, isNull);
  });
}
