import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mass_lens/core/theme/app_theme.dart';
import 'package:mass_lens/features/measurements/domain/measurement.dart';
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

Future<ui.Image> _letterboxImage(String path) async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  canvas.drawRect(
    const Rect.fromLTWH(0, 0, 400, 100),
    ui.Paint()..color = const Color(0xFF8A8F98),
  );
  return recorder.endRecording().toImage(400, 100);
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

  test('traced dimensions preserve measured axes and inferred depth', () {
    const measured = MeasuredDimensions(
      widthMm: 200,
      heightMm: 100,
      referenceLabel: 'Standard card',
    );
    final merged = measured.mergeWith(
      const DimensionsMm(width: 180, height: 90, depth: 50),
    );
    expect(merged.width, 200);
    expect(merged.height, 100);
    expect(merged.depth, 50);
  });

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
    expect(find.text('Trace the card’s long edge'), findsOneWidget);
    expect(
      find.text('Keep the reference and object in the same plane'),
      findsOneWidget,
    );

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
    expect(result!.referenceLabel, 'Card long edge');
    expect(result!.widthMm, greaterThan(20));
    expect(result!.widthMm, lessThan(85.6));
    expect(result!.heightMm, greaterThan(15));
    expect(result!.heightMm, lessThan(68.4));
    expect(result!.depthMm, isNull);
  });

  testWidgets('offers explicit long and short payment-card edges', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: PhotoMeasureScreen(imagePath: 'fake', decodeImage: _fakeImage),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Card long · 85.60'), findsOneWidget);
    expect(find.text('Card short · 53.98'), findsOneWidget);
    await tester.tap(find.byKey(const Key('reference_card_short')));
    await tester.pump();
    expect(find.text('Trace the card’s short edge'), findsOneWidget);
  });

  testWidgets('letterbox touches are clamped to the actual photo', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(360, 800));
    await tester.pumpWidget(
      const MaterialApp(
        home: PhotoMeasureScreen(
          imagePath: 'letterbox',
          decodeImage: _letterboxImage,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('reference_card')));
    await tester.pump();

    final canvas = find.byKey(const Key('measure_canvas'));
    final rect = tester.getRect(canvas);
    await tester.dragFrom(
      Offset(rect.center.dx, rect.top + 8),
      const Offset(0, 55),
    );
    await tester.pump();
    final next = tester.widget<FilledButton>(
      find.byKey(const Key('measure_next_button')),
    );
    expect(next.onPressed, isNotNull);
    await tester.tap(find.byKey(const Key('measure_next_button')));
    await tester.pump();

    expect(find.text('CALIBRATE'), findsOneWidget);
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
