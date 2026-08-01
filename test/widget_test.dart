import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mass_lens/app/app_controller.dart';
import 'package:mass_lens/app/mass_lens_app.dart';
import 'package:mass_lens/core/theme/app_theme.dart';
import 'package:mass_lens/features/measurements/data/measurement_store.dart';
import 'package:mass_lens/features/measurements/domain/measurement.dart';
import 'package:mass_lens/features/scan/data/photo_picker.dart';
import 'package:mass_lens/features/scan/domain/estimate_repository.dart';
import 'package:mass_lens/features/scan/presentation/scan_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('onboarding opens the main measurement workspace', (
    tester,
  ) async {
    final controller = AppController(
      measurementStore: const MeasurementStore(),
    );
    await tester.pumpWidget(MassLensApp(controller: controller));

    expect(find.text('Measure what\nyou cannot weigh.'), findsOneWidget);
    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();

    expect(find.text('What are we\nmeasuring today?'), findsOneWidget);
    expect(find.byKey(const Key('shell_scan_button')), findsOneWidget);
    expect(
      tester.getSize(find.byKey(const Key('shell_scan_icon'))),
      const Size(40, 34),
    );
  });

  testWidgets('bottom navigation exposes history and settings', (tester) async {
    final controller = AppController(
      measurementStore: const _FakeMeasurementStore(),
      onboardingComplete: true,
    );
    await tester.pumpWidget(MassLensApp(controller: controller));

    await tester.tap(find.byKey(const Key('nav_history')));
    await tester.pumpAndSettle();
    expect(find.text('Measurement history'), findsOneWidget);
    expect(find.text('Nothing saved yet'), findsOneWidget);

    await tester.tap(find.byKey(const Key('nav_settings')));
    await tester.pumpAndSettle();
    expect(find.text('PREFERENCES AND PRIVACY'), findsOneWidget);
    expect(find.text('Local demo'), findsOneWidget);
  });

  testWidgets('photo flow analyzes and saves an estimate', (tester) async {
    final controller = AppController(
      measurementStore: const _FakeMeasurementStore(),
      onboardingComplete: true,
    );
    final photoPicker = _FakePhotoPicker();
    final estimateRepository = _FakeEstimateRepository();
    await tester.pumpWidget(
      AppScope(
        controller: controller,
        child: MaterialApp(
          theme: buildAppTheme(),
          home: ScanScreen(
            photoPicker: photoPicker,
            estimateRepository: estimateRepository,
          ),
        ),
      ),
    );

    await tester.scrollUntilVisible(
      find.byKey(const Key('gallery_button')),
      300,
    );
    await tester.tap(find.byKey(const Key('gallery_button')));
    await tester.pumpAndSettle();
    expect(find.text('Confirm the object'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.byKey(const Key('add_second_photo_button')),
      250,
    );
    await tester.tap(find.byKey(const Key('add_second_photo_button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('second_photo_gallery_button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('second_photo_preview')), findsOneWidget);

    await tester.scrollUntilVisible(
      find.byKey(const Key('material_Metal')).last,
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const Key('material_Metal')).last);
    await tester.scrollUntilVisible(
      find.byKey(const Key('fill_state_Partly filled')).last,
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const Key('fill_state_Partly filled')).last);
    await tester.scrollUntilVisible(
      find.byKey(const Key('known_dimension_field')).last,
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.enterText(
      find.byKey(const Key('known_dimension_field')).last,
      '12.5',
    );
    await tester.scrollUntilVisible(
      find.byKey(const Key('reference_Standard card')).last,
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const Key('reference_Standard card')).last);

    await tester.scrollUntilVisible(
      find.byKey(const Key('analyze_button')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const Key('analyze_button')));
    await tester.pumpAndSettle();
    expect(estimateRepository.lastRequest?.secondaryImagePath, isNotNull);
    expect(estimateRepository.lastRequest?.material, 'Metal');
    expect(estimateRepository.lastRequest?.fillState, 'Partly filled');
    expect(estimateRepository.lastRequest?.referenceObject, 'Standard card');
    expect(estimateRepository.lastRequest?.knownDimension?.axis, 'Width');
    expect(estimateRepository.lastRequest?.knownDimension?.value, 12.5);
    expect(estimateRepository.lastRequest?.knownDimension?.unit, 'cm');
    expect(find.text('Object category'), findsNothing);
    expect(find.byKey(const Key('result_weight')), findsOneWidget);
    expect(find.text('LIKELY RANGE'), findsOneWidget);
    final photoRect = tester.getRect(find.byKey(const Key('result_photo')));
    final labelRect = tester.getRect(
      find.byKey(const Key('result_object_label')),
    );
    expect(labelRect.top, greaterThanOrEqualTo(photoRect.bottom));

    await tester.scrollUntilVisible(
      find.byKey(const Key('save_result_button')),
      350,
    );
    final saveButton = tester.widget<FilledButton>(
      find.byKey(const Key('save_result_button')),
    );
    expect(saveButton.onPressed, isNotNull);
    saveButton.onPressed!();
    await tester.pumpAndSettle();
    expect(controller.measurements, hasLength(1));
    expect(find.text('Saved'), findsOneWidget);
  });
}

class _FakePhotoPicker implements PhotoPicker {
  int _pickCount = 0;

  @override
  Future<String?> pick(PhotoSource source) async {
    _pickCount++;
    return '/tmp/mass-lens-test-$_pickCount.jpg';
  }
}

class _FakeEstimateRepository implements EstimateRepository {
  EstimateRequest? lastRequest;

  @override
  Future<Measurement> analyze(EstimateRequest request) async {
    lastRequest = request;
    return Measurement(
      id: 'test-result',
      createdAt: DateTime(2026, 7, 30, 12),
      imagePath: request.imagePath,
      objectLabel: 'Test parcel',
      category: 'Parcel',
      estimateGrams: 2400,
      lowerBoundGrams: 2000,
      upperBoundGrams: 2800,
      confidence: ConfidenceLevel.medium,
      dimensions: const DimensionsMm(width: 300, height: 220, depth: 180),
      assumptions: const [
        'Known category',
        'Estimated material based on visible appearance because no manufacturer '
            'specification or physical scale reference was provided',
      ],
    );
  }
}

class _FakeMeasurementStore extends MeasurementStore {
  const _FakeMeasurementStore();

  @override
  Future<Measurement> persistImage(Measurement measurement) async {
    return measurement;
  }

  @override
  Future<void> saveAll(List<Measurement> measurements) async {}
}
