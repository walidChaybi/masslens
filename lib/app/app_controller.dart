import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/services/installation_id_store.dart';
import '../features/measurements/data/measurement_store.dart';
import '../features/measurements/domain/measurement.dart';
import '../features/monetization/application/monetization_controller.dart';

class AppController extends ChangeNotifier {
  AppController({
    required MeasurementStore measurementStore,
    List<Measurement> measurements = const [],
    bool onboardingComplete = false,
    bool onboardingInterstitialShown = false,
    UnitSystem unitSystem = UnitSystem.metric,
    DateTime? previousBackgroundedAt,
    MonetizationController? monetizationController,
  }) : _measurementStore = measurementStore,
       _measurements = List<Measurement>.from(measurements),
       _onboardingComplete = onboardingComplete,
       _onboardingInterstitialShown = onboardingInterstitialShown,
       _unitSystem = unitSystem,
       _previousBackgroundedAt = previousBackgroundedAt,
       monetization =
           monetizationController ?? MonetizationController.disabled() {
    monetization.addListener(notifyListeners);
  }

  static const _onboardingKey = 'mass_lens.onboarding_complete';
  static const _onboardingSeenKey = 'mass_lens.onboarding_seen';
  static const _onboardingInterstitialKey =
      'mass_lens.onboarding_interstitial_shown';
  static const _forceOnboarding = bool.fromEnvironment(
    'MASSLENS_FORCE_ONBOARDING',
  );
  static const _unitKey = 'mass_lens.unit_system';
  static const _backgroundedAtKey = 'mass_lens.backgrounded_at_ms';

  final MeasurementStore _measurementStore;
  final MonetizationController monetization;
  final List<Measurement> _measurements;
  bool _onboardingComplete;
  bool _onboardingInterstitialShown;
  UnitSystem _unitSystem;
  DateTime? _previousBackgroundedAt;
  Future<void> _backgroundPersistence = Future<void>.value();

  List<Measurement> get measurements => List.unmodifiable(_measurements);
  bool get onboardingComplete => _onboardingComplete;
  bool get onboardingInterstitialShown => _onboardingInterstitialShown;
  UnitSystem get unitSystem => _unitSystem;

  static Future<AppController> bootstrap({
    MeasurementStore store = const MeasurementStore(),
  }) async {
    var onboardingComplete = false;
    var onboardingInterstitialShown = false;
    var unitSystem = UnitSystem.metric;
    DateTime? previousBackgroundedAt;
    try {
      final preferences = await SharedPreferences.getInstance();
      final savedOnboarding = preferences.getBool(_onboardingKey);
      final onboardingSeen = preferences.getBool(_onboardingSeenKey) ?? false;
      final existingInstallation = InstallationIdStore.hasExisting(preferences);
      // A genuinely fresh install sees onboarding during this launch only.
      // Persisting `seen` now means closing midway never replays the guide.
      // Existing installation IDs also preserve the legacy-upgrade behavior.
      onboardingComplete =
          savedOnboarding == true || onboardingSeen || existingInstallation;
      if (onboardingComplete) {
        if (savedOnboarding != true) {
          await preferences.setBool(_onboardingKey, true);
        }
        if (!onboardingSeen) {
          await preferences.setBool(_onboardingSeenKey, true);
        }
      } else {
        await preferences.setBool(_onboardingKey, false);
        await preferences.setBool(_onboardingSeenKey, true);
      }
      onboardingInterstitialShown =
          preferences.getBool(_onboardingInterstitialKey) ?? false;
      unitSystem = UnitSystem.values.byName(
        preferences.getString(_unitKey) ?? UnitSystem.metric.name,
      );
      final backgroundedAtMs = preferences.getInt(_backgroundedAtKey);
      if (backgroundedAtMs != null) {
        previousBackgroundedAt = DateTime.fromMillisecondsSinceEpoch(
          backgroundedAtMs,
        );
      }
    } on Object {
      // Defaults keep the app operational if preferences are unavailable.
    }

    return AppController(
      measurementStore: store,
      measurements: await store.load(),
      onboardingComplete: kDebugMode && _forceOnboarding
          ? false
          : onboardingComplete,
      onboardingInterstitialShown: onboardingInterstitialShown,
      unitSystem: unitSystem,
      previousBackgroundedAt: previousBackgroundedAt,
      monetizationController: MonetizationController.create(),
    );
  }

  Future<void> initializeMonetization() => monetization.initialize();

  Future<void> handleAppResumed(Duration backgroundTime) =>
      monetization.handleAppResumed(backgroundTime);

  Future<Duration?> consumePreviousBackgroundDuration() async {
    final previous = _previousBackgroundedAt;
    _previousBackgroundedAt = null;
    if (previous == null) return null;
    return consumeBackgroundDuration(previous);
  }

  /// Consumes only the exact pause record being resumed. If another pause has
  /// already written a newer timestamp, it is preserved and the stale resume
  /// cannot trigger an app-open ad.
  Future<Duration?> consumeBackgroundDuration(DateTime backgroundedAt) {
    final result = _backgroundPersistence.then(
      (_) => _consumeBackgroundDuration(backgroundedAt),
    );
    _backgroundPersistence = result.then<void>((_) {});
    return result;
  }

  Future<Duration?> _consumeBackgroundDuration(DateTime backgroundedAt) async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final expected = backgroundedAt.millisecondsSinceEpoch;
      if (preferences.getInt(_backgroundedAtKey) != expected) return null;
      if (!await preferences.remove(_backgroundedAtKey)) return null;
      final duration = DateTime.now().difference(backgroundedAt);
      return duration.isNegative ? Duration.zero : duration;
    } on Object {
      // Failing closed avoids replaying the same app-open opportunity on a
      // later launch when persistence cannot be consumed safely.
      return null;
    }
  }

  Future<void> recordBackgrounded(DateTime time) {
    final result = _backgroundPersistence.then(
      (_) => _recordBackgrounded(time),
    );
    _backgroundPersistence = result;
    return result;
  }

  Future<void> _recordBackgrounded(DateTime time) async {
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setInt(_backgroundedAtKey, time.millisecondsSinceEpoch);
    } on Object {
      // Resume ads are optional if lifecycle persistence is unavailable.
    }
  }

  Future<void> completeOnboarding() async {
    if (_onboardingComplete) return;
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setBool(_onboardingKey, true);
    } on Object {
      // The current session can continue even if persistence fails.
    }
    _onboardingComplete = true;
    notifyListeners();
    unawaited(monetization.initialize());
  }

  Future<void> markOnboardingInterstitialShown() async {
    if (_onboardingInterstitialShown) return;
    _onboardingInterstitialShown = true;
    notifyListeners();
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setBool(_onboardingInterstitialKey, true);
    } on Object {
      // The in-memory guard still prevents a duplicate in this session.
    }
  }

  Future<void> clearOnboardingInterstitialShownAfterFailedDisplay() async {
    if (!_onboardingInterstitialShown) return;
    _onboardingInterstitialShown = false;
    notifyListeners();
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.remove(_onboardingInterstitialKey);
    } on Object {
      // A stale true is safer than replaying an ad that may have appeared.
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

  @override
  void dispose() {
    monetization
      ..removeListener(notifyListeners)
      ..dispose();
    super.dispose();
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
