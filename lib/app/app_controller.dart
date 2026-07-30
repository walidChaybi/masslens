import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../features/measurements/data/measurement_store.dart';
import '../features/measurements/domain/measurement.dart';

class AppController extends ChangeNotifier {
  AppController({
    required MeasurementStore measurementStore,
    List<Measurement> measurements = const [],
    bool onboardingComplete = false,
    UnitSystem unitSystem = UnitSystem.metric,
  }) : _measurementStore = measurementStore,
       _measurements = List<Measurement>.from(measurements),
       _onboardingComplete = onboardingComplete,
       _unitSystem = unitSystem;

  static const _onboardingKey = 'mass_lens.onboarding_complete';
  static const _unitKey = 'mass_lens.unit_system';

  final MeasurementStore _measurementStore;
  final List<Measurement> _measurements;
  bool _onboardingComplete;
  UnitSystem _unitSystem;

  List<Measurement> get measurements => List.unmodifiable(_measurements);
  bool get onboardingComplete => _onboardingComplete;
  UnitSystem get unitSystem => _unitSystem;

  static Future<AppController> bootstrap({
    MeasurementStore store = const MeasurementStore(),
  }) async {
    var onboardingComplete = false;
    var unitSystem = UnitSystem.metric;
    try {
      final preferences = await SharedPreferences.getInstance();
      onboardingComplete = preferences.getBool(_onboardingKey) ?? false;
      unitSystem = UnitSystem.values.byName(
        preferences.getString(_unitKey) ?? UnitSystem.metric.name,
      );
    } on Object {
      // Defaults keep the app operational if preferences are unavailable.
    }

    return AppController(
      measurementStore: store,
      measurements: await store.load(),
      onboardingComplete: onboardingComplete,
      unitSystem: unitSystem,
    );
  }

  Future<void> completeOnboarding() async {
    _onboardingComplete = true;
    notifyListeners();
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setBool(_onboardingKey, true);
    } on Object {
      // The current session can continue even if persistence fails.
    }
  }

  Future<void> setUnitSystem(UnitSystem value) async {
    if (_unitSystem == value) return;
    _unitSystem = value;
    notifyListeners();
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(_unitKey, value.name);
    } on Object {
      // Keep the selected value for this session.
    }
  }

  Future<void> addMeasurement(Measurement measurement) async {
    if (_measurements.any((item) => item.id == measurement.id)) return;
    final persisted = await _measurementStore.persistImage(measurement);
    _measurements.insert(0, persisted);
    notifyListeners();
    await _measurementStore.saveAll(_measurements);
  }

  Future<void> deleteMeasurement(Measurement measurement) async {
    _measurements.removeWhere((item) => item.id == measurement.id);
    notifyListeners();
    await _measurementStore.deleteImage(measurement);
    await _measurementStore.saveAll(_measurements);
  }

  Future<void> clearHistory() async {
    final deleted = List<Measurement>.from(_measurements);
    _measurements.clear();
    notifyListeners();
    for (final measurement in deleted) {
      await _measurementStore.deleteImage(measurement);
    }
    await _measurementStore.saveAll(_measurements);
  }
}

class AppScope extends InheritedNotifier<AppController> {
  const AppScope({
    required AppController controller,
    required super.child,
    super.key,
  }) : super(notifier: controller);

  static AppController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'No AppScope found above this context.');
    return scope!.notifier!;
  }
}
