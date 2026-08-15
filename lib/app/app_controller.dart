import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/services/app_review_service.dart';
import '../core/services/installation_id_store.dart';
import '../features/measurements/data/measurement_store.dart';
import '../features/measurements/domain/measurement.dart';
import '../features/monetization/application/monetization_controller.dart';

class AppController extends ChangeNotifier {
  AppController({
    required MeasurementStore measurementStore,
    List<Measurement> measurements = const [],
    bool onboardingComplete = false,
    bool onboardingReviewPromptHandled = false,
    bool postScanReviewRequested = false,
    UnitSystem unitSystem = UnitSystem.metric,
    DateTime? previousBackgroundedAt,
    MonetizationController? monetizationController,
    AppReviewService? appReviewService,
  }) : _measurementStore = measurementStore,
       _measurements = List<Measurement>.from(measurements),
       _onboardingComplete = onboardingComplete,
       _onboardingReviewPromptHandled = onboardingReviewPromptHandled,
       _postScanReviewRequested = postScanReviewRequested,
       _unitSystem = unitSystem,
       _previousBackgroundedAt = previousBackgroundedAt,
       _appReviewService = appReviewService ?? PlayAppReviewService(),
       monetization =
           monetizationController ?? MonetizationController.disabled() {
    monetization.addListener(notifyListeners);
  }

  static const _onboardingKey = 'mass_lens.onboarding_complete';
  static const _onboardingSeenKey = 'mass_lens.onboarding_seen';
  static const _onboardingReviewPromptKey =
      'mass_lens.onboarding_review_prompt_handled';
  static const _postScanReviewRequestedKey =
      'mass_lens.post_scan_review_requested';
  static const _forceOnboarding = bool.fromEnvironment(
    'MASSLENS_FORCE_ONBOARDING',
  );
  static const _unitKey = 'mass_lens.unit_system';
  static const _backgroundedAtKey = 'mass_lens.backgrounded_at_ms';

  final MeasurementStore _measurementStore;
  final AppReviewService _appReviewService;
  final MonetizationController monetization;
  final List<Measurement> _measurements;
  bool _onboardingComplete;
  bool _onboardingReviewPromptHandled;
  bool _postScanReviewRequested;
  UnitSystem _unitSystem;
  DateTime? _previousBackgroundedAt;
  Future<void> _backgroundPersistence = Future<void>.value();

  List<Measurement> get measurements => List.unmodifiable(_measurements);
  bool get onboardingComplete => _onboardingComplete;
  bool get onboardingReviewPromptHandled => _onboardingReviewPromptHandled;
  bool get postScanReviewRequested => _postScanReviewRequested;
  UnitSystem get unitSystem => _unitSystem;

  static Future<AppController> bootstrap({
    MeasurementStore store = const MeasurementStore(),
  }) async {
    var onboardingComplete = false;
    var onboardingReviewPromptHandled = false;
    var postScanReviewRequested = false;
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
      onboardingReviewPromptHandled =
          preferences.getBool(_onboardingReviewPromptKey) ?? false;
      postScanReviewRequested =
          preferences.getBool(_postScanReviewRequestedKey) ?? false;
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
      onboardingReviewPromptHandled: onboardingReviewPromptHandled,
      postScanReviewRequested: postScanReviewRequested,
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

  /// Records the one-time onboarding prompt before invoking Google Play.
  ///
  /// The review UI is optional and quota-controlled by Google. Persisting the
  /// decision first prevents a relaunch or double tap from asking twice, while
  /// a platform failure still lets onboarding finish normally.
  Future<bool> handleOnboardingReview({required bool requestReview}) async {
    if (_onboardingReviewPromptHandled) return false;
    _onboardingReviewPromptHandled = true;
    notifyListeners();
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setBool(_onboardingReviewPromptKey, true);
    } on Object {
      // The in-memory guard still prevents duplicates during this launch.
    }
    if (!requestReview) return false;
    return _appReviewService.requestReview().timeout(
      const Duration(seconds: 4),
      onTimeout: () => false,
    );
  }

  /// Requests the native Google in-app review sheet after the user has
  /// successfully completed enough scans.
  ///
  /// This is intentionally fire-and-forget friendly: missing Play Store,
  /// review quota, or plugin errors never block scans or navigation.
  Future<void> maybeRequestPostScanReview() async {
    if (_postScanReviewRequested) return;
    if (monetization.completedScanCount < 3) return;

    // Persist first so a crash/quota no-op never results in repeat prompts.
    _postScanReviewRequested = true;
    notifyListeners();
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setBool(_postScanReviewRequestedKey, true);
    } on Object {
      // Offline or missing storage still keeps the in-memory guard.
    }

    unawaited(() async {
      try {
        await _appReviewService.requestReview().timeout(
          const Duration(seconds: 4),
        );
      } on Object {
        // Best effort only.
      }
    }());
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

  Future<void> updateMeasurement(Measurement measurement) async {
    final index = _measurements.indexWhere((item) => item.id == measurement.id);
    if (index == -1) return;
    _measurements[index] = measurement;
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
