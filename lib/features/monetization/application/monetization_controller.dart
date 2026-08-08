import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/services/installation_id_store.dart';
import '../data/app_ad_service.dart';
import '../data/monetization_api.dart';
import '../data/monetization_config.dart';
import '../domain/access_status.dart';

class MonetizationController extends ChangeNotifier {
  MonetizationController._({
    required this.enabled,
    required MonetizationApi? api,
    required AppAdService adService,
  }) : _api = api,
       _adService = adService;

  factory MonetizationController.create() {
    final api = MonetizationConfig.backendConfigured
        ? MonetizationApi(apiUrl: MonetizationConfig.apiUrl)
        : null;
    late MonetizationController controller;
    final adService = AppAdService(
      onPaidEvent: (placement, value, precision, currency) {
        controller.reportPaidAd(placement, value, precision, currency);
      },
    );
    controller = MonetizationController._(
      enabled: api != null,
      api: api,
      adService: adService,
    );
    return controller;
  }

  factory MonetizationController.disabled() => MonetizationController._(
    enabled: false,
    api: null,
    adService: AppAdService(),
  );

  static const _completedScanCountKey =
      'mass_lens.completed_scan_count_for_ads';

  final bool enabled;
  final MonetizationApi? _api;
  final AppAdService _adService;

  AccessStatus _access = const AccessStatus.fallback();
  String _clientId = '';
  String? _message;
  bool _initialized = false;
  bool _loading = false;
  int _completedScanCount = 0;

  AccessStatus get access => _access;
  String? get message => _message;
  bool get loading => _loading;
  bool get canRequestAds => _adService.canRequestAds && _access.adsEnabled;
  bool get canRequestNativeAds =>
      _adService.canRequestNativeAds && _access.adsEnabled;
  bool get rewardedAdReady => _adService.rewardedReady;
  bool get privacyOptionsRequired => _adService.privacyOptionsRequired;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    if (!enabled) {
      notifyListeners();
      return;
    }

    _clientId = await InstallationIdStore.getOrCreate();
    try {
      final preferences = await SharedPreferences.getInstance();
      _completedScanCount = preferences.getInt(_completedScanCountKey) ?? 0;
    } on Object {
      // Ad cadence can safely restart if local preferences are unavailable.
    }
    await refreshAccess();
  }

  Future<void> refreshAccess() async {
    if (!enabled || _clientId.isEmpty || _api == null) return;
    _loading = true;
    notifyListeners();
    try {
      final access = await _api.getAccess(_clientId);
      _access = access;
      _message = null;
      await _adService.updatePlan(
        adsAllowed: access.adsEnabled,
        policy: access.adPolicy,
      );
    } on Object catch (error) {
      // The Worker remains the authority; stale data never grants an AI scan.
      _message = 'Could not refresh scan access: $error';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> onScanCompleted() async {
    _completedScanCount += 1;
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setInt(_completedScanCountKey, _completedScanCount);
    } on Object {
      // Continue with this session's cadence if persistence is unavailable.
    }
    await _adService.showInterstitialAfterScan(_completedScanCount);
    await refreshAccess();
  }

  Future<bool> watchAdForScan() async {
    if (!_access.adsEnabled) {
      _message = 'Ads are unavailable. Your existing scans are still safe.';
      notifyListeners();
      return false;
    }
    if (!_access.canEarnReward) {
      _message =
          'You can hold up to ${_access.rewardBalanceCap} rewarded scans.';
      notifyListeners();
      return false;
    }
    final earned = await _adService.showRewarded(clientId: _clientId);
    if (!earned) {
      _message = 'A rewarded ad is not ready. Try again shortly.';
      notifyListeners();
      return false;
    }

    _message = 'Reward earned. Confirming it securely…';
    notifyListeners();
    final previousRewarded = _access.rewardedScans;
    for (final delay in const [1, 2, 4, 6]) {
      await Future<void>.delayed(Duration(seconds: delay));
      await refreshAccess();
      if (_access.rewardedScans > previousRewarded) {
        _message = 'One scan was added.';
        notifyListeners();
        return true;
      }
    }
    _message = 'Your verified reward is still processing. Try refresh shortly.';
    notifyListeners();
    return false;
  }

  Future<void> handleAppResumed(Duration backgroundTime) async {
    if (backgroundTime <
        Duration(seconds: _access.adPolicy.appOpenCooldownSeconds)) {
      return;
    }
    await _adService.showAppOpenAfterLongBackground(backgroundTime);
  }

  void reportPaidAd(
    String placement,
    double valueMicros,
    PrecisionType precision,
    String currencyCode,
  ) {
    final api = _api;
    if (api == null || _clientId.isEmpty) return;
    unawaited(
      api
          .reportAdRevenue(
            clientId: _clientId,
            placement: placement,
            valueMicros: valueMicros,
            precision: precision.name,
            currencyCode: currencyCode,
          )
          .onError((_, _) {}),
    );
  }

  Future<void> showPrivacyOptions() async {
    await _adService.showPrivacyOptions();
    notifyListeners();
  }

  void clearMessage() {
    _message = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _adService.dispose();
    super.dispose();
  }
}
