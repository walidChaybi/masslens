import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mass_lens/app/app_controller.dart';
import 'package:mass_lens/app/mass_lens_app.dart';
import 'package:mass_lens/core/services/installation_id_store.dart';
import 'package:mass_lens/core/theme/app_theme.dart';
import 'package:mass_lens/features/home/presentation/home_screen.dart';
import 'package:mass_lens/features/measurements/data/measurement_store.dart';
import 'package:mass_lens/features/measurements/domain/measurement.dart';
import 'package:mass_lens/features/scan/data/photo_picker.dart';
import 'package:mass_lens/features/scan/domain/estimate_repository.dart';
import 'package:mass_lens/features/scan/domain/measurement_capture.dart';
import 'package:mass_lens/features/scan/domain/measured_dimensions.dart';
import 'package:mass_lens/features/scan/presentation/capture/measurement_launcher.dart';
import 'package:mass_lens/features/scan/presentation/scan_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('opens directly on the labeled touch scale', (tester) async {
    final controller = AppController(
      measurementStore: const MeasurementStore(),
      onboardingComplete: true,
    );
    await tester.pumpWidget(MassLensApp(controller: controller));
    await tester.pump();

    expect(find.byKey(const Key('digital_scale_screen')), findsOneWidget);
    expect(find.text('SIMULATOR · NOT A MEASUREMENT'), findsOneWidget);
    expect(find.byKey(const Key('scale_touch_surface')), findsOneWidget);
    expect(find.byKey(const Key('shell_scan_button')), findsNothing);
  });

  testWidgets('incomplete onboarding is shown once before the app shell', (
    tester,
  ) async {
    final controller = AppController(
      measurementStore: const _FakeMeasurementStore(),
    );
    await tester.pumpWidget(MassLensApp(controller: controller));
    await tester.pump();

    expect(find.byKey(const Key('onboarding_pages')), findsOneWidget);
    expect(find.byKey(const Key('digital_scale_screen')), findsNothing);

    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();

    expect(controller.onboardingComplete, isTrue);
    expect(find.byKey(const Key('onboarding_pages')), findsNothing);
    expect(find.byKey(const Key('digital_scale_screen')), findsOneWidget);
  });

  test(
    'bootstrap skips restored onboarding for an upgraded installation',
    () async {
      SharedPreferences.setMockInitialValues({
        'masslens_api_installation_id': 'legacy_installation_identifier',
      });
      final controller = await AppController.bootstrap(
        store: const _FakeMeasurementStore(),
      );
      addTearDown(controller.dispose);

      expect(controller.onboardingComplete, isTrue);
      final preferences = await SharedPreferences.getInstance();
      expect(preferences.getBool('mass_lens.onboarding_complete'), isTrue);
    },
  );

  test(
    'fresh onboarding remains incomplete after an installation ID is created',
    () async {
      final first = await AppController.bootstrap(
        store: const _FakeMeasurementStore(),
      );
      addTearDown(first.dispose);
      expect(first.onboardingComplete, isFalse);

      await InstallationIdStore.getOrCreate();
      final relaunched = await AppController.bootstrap(
        store: const _FakeMeasurementStore(),
      );
      addTearDown(relaunched.dispose);
      expect(relaunched.onboardingComplete, isFalse);
    },
  );

  testWidgets('left navigation exposes AI scan, history, and settings', (
    tester,
  ) async {
    final controller = AppController(
      measurementStore: const _FakeMeasurementStore(),
      onboardingComplete: true,
    );
    await tester.pumpWidget(MassLensApp(controller: controller));

    await tester.tap(find.byKey(const Key('open_navigation')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('nav_digital_scale')), findsOneWidget);
    expect(find.byKey(const Key('nav_ai_scan')), findsOneWidget);

    await tester.tap(find.byKey(const Key('nav_history')));
    await tester.pumpAndSettle();
    expect(find.text('Measurement history'), findsOneWidget);
    expect(find.text('Nothing saved yet'), findsOneWidget);

    await tester.tap(find.byKey(const Key('open_navigation')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('nav_settings')));
    await tester.pumpAndSettle();
    expect(find.text('PREFERENCES AND PRIVACY'), findsOneWidget);
    expect(find.text('Secure cloud AI'), findsOneWidget);

    await tester.tap(find.byKey(const Key('open_navigation')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('nav_ai_scan')));
    await tester.pumpAndSettle();
    expect(find.text('AI weight'), findsOneWidget);
    expect(find.byKey(const Key('home_scan_button')), findsOneWidget);
  });

  testWidgets('scan access sheet is rewarded-only with no purchase products', (
    tester,
  ) async {
    final controller = AppController(
      measurementStore: const _FakeMeasurementStore(),
      onboardingComplete: true,
    );
    await tester.pumpWidget(MassLensApp(controller: controller));

    await tester.tap(find.byKey(const Key('open_navigation')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('nav_settings')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Earn AI scans'), 300);
    await tester.tap(find.text('Earn AI scans'));
    await tester.pumpAndSettle();

    expect(find.text('Watch one ad.\nGet one scan.'), findsOneWidget);
    expect(find.textContaining('No subscription'), findsOneWidget);
    expect(find.textContaining('100 scans'), findsNothing);
    expect(find.textContaining('500 scans'), findsNothing);
    expect(find.textContaining('One-time pack'), findsNothing);
    expect(find.text('Buy scans'), findsNothing);
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
            autoStart: false,
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

    await tester.tap(find.byKey(const Key('add_details_button')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const Key('add_second_photo_button')),
      250,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.byKey(const Key('add_second_photo_button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('second_photo_gallery_button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('second_photo_preview')), findsOneWidget);

    await tester.tap(find.byKey(const Key('add_details_button')));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byKey(const Key('material_Metal')).last,
      250,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.byKey(const Key('material_Metal')).last);
    await tester.scrollUntilVisible(
      find.byKey(const Key('fill_state_Partly filled')).last,
      250,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.byKey(const Key('fill_state_Partly filled')).last);
    await tester.scrollUntilVisible(
      find.byKey(const Key('known_dimension_field')).last,
      250,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.enterText(
      find.byKey(const Key('known_dimension_field')).last,
      '12.5',
    );
    await tester.scrollUntilVisible(
      find.byKey(const Key('reference_Standard card')).last,
      250,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.byKey(const Key('reference_Standard card')).last);

    await tester.tap(find.text('Done').last);
    await tester.pumpAndSettle();

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

  testWidgets('AR capture preserves measured axes through analysis', (
    tester,
  ) async {
    final controller = AppController(
      measurementStore: const _FakeMeasurementStore(),
      onboardingComplete: true,
    );
    final estimateRepository = _FakeEstimateRepository();
    final launcher = _FakeMeasurementLauncher(
      const MeasurementCapture(
        imagePath: '/tmp/ar-object.jpg',
        dimensions: MeasuredDimensions(
          widthMm: 410,
          heightMm: 205,
          method: MeasurementMethod.arCoreDepth,
        ),
      ),
    );
    await tester.pumpWidget(
      AppScope(
        controller: controller,
        child: MaterialApp(
          theme: buildAppTheme(),
          home: ScanScreen(
            estimateRepository: estimateRepository,
            measurementLauncher: launcher,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(launcher.launchCount, 1);
    expect(find.text('41.0 × 20.5 cm'), findsOneWidget);
    expect(find.text('AR depth'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(const Key('analyze_button')),
      250,
    );
    await tester.tap(find.byKey(const Key('analyze_button')));
    await tester.pumpAndSettle();

    expect(estimateRepository.lastRequest?.measuredDimensions?.widthMm, 410);
    expect(estimateRepository.lastRequest?.measuredDimensions?.heightMm, 205);
    expect(find.text('41.0 × 20.5 × 18.0 cm'), findsOneWidget);
  });

  testWidgets('measurement cancellation returns to the quiet capture view', (
    tester,
  ) async {
    final controller = AppController(
      measurementStore: const _FakeMeasurementStore(),
      onboardingComplete: true,
    );
    final launcher = _FakeMeasurementLauncher(null);
    await tester.pumpWidget(
      AppScope(
        controller: controller,
        child: MaterialApp(
          theme: buildAppTheme(),
          home: ScanScreen(
            estimateRepository: _FakeEstimateRepository(),
            measurementLauncher: launcher,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(launcher.launchCount, 1);
    expect(find.text('Measure an object'), findsOneWidget);
    expect(find.text('Measurement camera could not be opened.'), findsNothing);
  });

  testWidgets('minimal AI entry fits compact and large Android viewports', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final controller = AppController(
      measurementStore: const _FakeMeasurementStore(),
      onboardingComplete: true,
    );

    for (final size in const [Size(360, 640), Size(1280, 800)]) {
      await tester.binding.setSurfaceSize(size);
      await tester.pumpWidget(
        AppScope(
          controller: controller,
          child: MaterialApp(
            theme: buildAppTheme(),
            home: Scaffold(
              body: HomeScreen(
                onMeasure: () {},
                onGallery: () {},
                onViewHistory: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('AI weight'), findsOneWidget);
      expect(find.byKey(const Key('scan_balance')), findsOneWidget);
      expect(find.byKey(const Key('home_scan_button')), findsOneWidget);
      expect(find.byKey(const Key('home_gallery_button')), findsOneWidget);
      expect(find.text('How it works'), findsNothing);
    }
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

class _FakeMeasurementLauncher implements MeasurementLauncher {
  _FakeMeasurementLauncher(this.capture);

  final MeasurementCapture? capture;
  int launchCount = 0;

  @override
  Future<MeasurementCapture?> launch(BuildContext context) async {
    launchCount++;
    return capture;
  }
}
