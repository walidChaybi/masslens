import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../domain/access_status.dart';
import 'monetization_config.dart';

typedef PaidAdReporter =
    void Function(
      String placement,
      double valueMicros,
      PrecisionType precision,
      String currencyCode,
    );

typedef InterstitialAdLoader =
    Future<InterstitialAdHandle?> Function(String adUnitId);

/// Narrow adapter around the Mobile Ads interstitial so its lifecycle can be
/// exercised without loading the platform plugin in unit tests.
@visibleForTesting
abstract interface class InterstitialAdHandle {
  void configure({
    required VoidCallback onShown,
    required VoidCallback onDismissed,
    required VoidCallback onFailedToShow,
    required void Function(
      double valueMicros,
      PrecisionType precision,
      String currencyCode,
    )
    onPaidEvent,
  });

  Future<void> show();

  void dispose();
}

class AppAdService {
  AppAdService({
    this.onPaidEvent,
    this.onStateChanged,
    DateTime Function()? now,
    InterstitialAdLoader? interstitialAdLoader,
  }) : _now = now ?? DateTime.now,
       _interstitialAdLoader = interstitialAdLoader ?? _loadGoogleInterstitial,
       _testInterstitialConfiguration = false;

  @visibleForTesting
  AppAdService.forTesting({
    required InterstitialAdLoader interstitialAdLoader,
    this.onPaidEvent,
    this.onStateChanged,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now,
       _interstitialAdLoader = interstitialAdLoader,
       _testInterstitialConfiguration = true {
    _adsAllowed = true;
    _canRequestAds = true;
    _initialized = true;
  }

  final PaidAdReporter? onPaidEvent;
  final void Function()? onStateChanged;
  final DateTime Function() _now;
  final InterstitialAdLoader _interstitialAdLoader;
  final bool _testInterstitialConfiguration;

  bool _initialized = false;
  bool _disposed = false;
  bool _adsAllowed = false;
  bool _canRequestAds = false;
  bool _privacyOptionsRequired = false;
  bool _appOpenLoading = false;
  bool _appOpenShowing = false;
  bool _interstitialLoading = false;
  bool _interstitialShowing = false;
  bool _rewardedLoading = false;
  bool _rewardedShowing = false;
  RewardedAd? _rewarded;
  AppOpenAd? _appOpenAd;
  InterstitialAdHandle? _interstitial;
  InterstitialAdHandle? _activeInterstitial;
  DateTime? _appOpenLoadedAt;
  DateTime? _lastAppOpenShownAt;
  DateTime? _lastInterstitialShownAt;
  Completer<void>? _appOpenLoadWaiter;
  Completer<bool>? _interstitialLoadWaiter;
  Completer<bool>? _activeInterstitialResult;
  AdPolicy _policy = const AdPolicy();

  bool get canRequestAds =>
      (_testInterstitialConfiguration || AdMobConfig.hasAnyConfiguration) &&
      _adsAllowed &&
      (_canRequestAds || AdMobConfig.useTestIds);
  bool get canRequestNativeAds =>
      canRequestAds && AdMobConfig.hasNativeConfiguration;
  bool get rewardedReady =>
      canRequestAds &&
      AdMobConfig.hasRewardedConfiguration &&
      _rewarded != null &&
      !_anyFullScreenAdShowing;
  bool get interstitialLoading => _interstitialLoading;
  bool get interstitialReady =>
      canRequestAds &&
      _hasInterstitialConfiguration &&
      _interstitial != null &&
      !_anyFullScreenAdShowing &&
      !_interstitialShowing &&
      _interstitialCooldownElapsed(_now());
  bool get privacyOptionsRequired => _privacyOptionsRequired;

  bool get _hasInterstitialConfiguration =>
      _testInterstitialConfiguration ||
      AdMobConfig.hasInterstitialConfiguration;

  bool get _anyFullScreenAdShowing =>
      _appOpenShowing || _interstitialShowing || _rewardedShowing;

  Future<void> updatePlan({
    required bool adsAllowed,
    required AdPolicy policy,
  }) async {
    _adsAllowed = adsAllowed;
    _policy = policy;
    if (!adsAllowed) {
      _disposeLoadedAds();
      return;
    }
    if (!_testInterstitialConfiguration && !AdMobConfig.hasAnyConfiguration) {
      return;
    }
    if (!_initialized) await _initialize();
    if (canRequestAds) _preloadAll();
  }

  Future<void> _initialize() async {
    if (_initialized) return;
    _initialized = true;
    if (kDebugMode && AdMobConfig.useTestIds) {
      // Official Google sample units do not serve production advertising.
      // Keep debug ad testing independent of a production consent message.
      try {
        await MobileAds.instance.initialize();
        _canRequestAds = true;
        if (kDebugMode) debugPrint('MassLens: Google test ads initialized.');
      } on Object {
        _initialized = false;
        rethrow;
      }
      return;
    }
    final consentFinished = Completer<void>();
    ConsentInformation.instance.requestConsentInfoUpdate(
      ConsentRequestParameters(),
      () async {
        await ConsentForm.loadAndShowConsentFormIfRequired((_) {});
        if (!consentFinished.isCompleted) consentFinished.complete();
      },
      (_) {
        if (!consentFinished.isCompleted) consentFinished.complete();
      },
    );
    await consentFinished.future;
    _canRequestAds = await ConsentInformation.instance.canRequestAds();
    _privacyOptionsRequired =
        await ConsentInformation.instance
            .getPrivacyOptionsRequirementStatus() ==
        PrivacyOptionsRequirementStatus.required;
    if (_canRequestAds || AdMobConfig.useTestIds) {
      await MobileAds.instance.initialize();
      if (AdMobConfig.testDeviceIds.isNotEmpty) {
        await MobileAds.instance.updateRequestConfiguration(
          RequestConfiguration(testDeviceIds: AdMobConfig.testDeviceIds),
        );
      }
    }
  }

  Future<void> showPrivacyOptions() async {
    if (!_privacyOptionsRequired) return;
    await ConsentForm.showPrivacyOptionsForm((_) {});
    _canRequestAds = await ConsentInformation.instance.canRequestAds();
    if (canRequestAds) {
      _preloadAll();
    } else {
      _disposeLoadedAds();
    }
  }

  void _preloadAll() {
    _loadRewarded();
    unawaited(_loadInterstitial());
    _loadAppOpen();
  }

  void _loadRewarded() {
    if (_disposed ||
        !canRequestAds ||
        !AdMobConfig.hasRewardedConfiguration ||
        _rewarded != null ||
        _rewardedLoading) {
      return;
    }
    _rewardedLoading = true;
    RewardedAd.load(
      adUnitId: AdMobConfig.rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedLoading = false;
          _rewarded = ad;
          onStateChanged?.call();
        },
        onAdFailedToLoad: (_) {
          _rewardedLoading = false;
          _rewarded = null;
          onStateChanged?.call();
          Future<void>.delayed(const Duration(seconds: 20), () {
            if (!_disposed && _adsAllowed && _rewarded == null) {
              _loadRewarded();
            }
          });
        },
      ),
    );
  }

  Future<bool> _loadInterstitial() {
    if (_interstitial != null) return Future<bool>.value(true);
    final pending = _interstitialLoadWaiter;
    if (pending != null) return pending.future;
    if (_disposed ||
        !canRequestAds ||
        !_hasInterstitialConfiguration ||
        _interstitialShowing) {
      return Future<bool>.value(false);
    }
    _interstitialLoading = true;
    final waiter = Completer<bool>();
    _interstitialLoadWaiter = waiter;
    onStateChanged?.call();
    unawaited(_performInterstitialLoad(waiter));
    return waiter.future;
  }

  Future<void> _performInterstitialLoad(Completer<bool> waiter) async {
    InterstitialAdHandle? loaded;
    try {
      loaded = await _interstitialAdLoader(AdMobConfig.interstitialAdUnitId);
    } on Object {
      loaded = null;
    }
    if (!identical(_interstitialLoadWaiter, waiter) ||
        _disposed ||
        !_adsAllowed) {
      loaded?.dispose();
      return;
    }
    _interstitialLoadWaiter = null;
    _interstitialLoading = false;
    _interstitial = loaded;
    if (!waiter.isCompleted) waiter.complete(loaded != null);
    onStateChanged?.call();
  }

  Future<bool> waitForInterstitial({
    Duration timeout = const Duration(seconds: 4),
  }) async {
    if (interstitialReady) return true;
    if (_anyFullScreenAdShowing || !_interstitialCooldownElapsed(_now())) {
      return false;
    }
    try {
      await _loadInterstitial().timeout(timeout);
    } on TimeoutException {
      return false;
    }
    return interstitialReady;
  }

  void _loadAppOpen() {
    if (!canRequestAds ||
        !AdMobConfig.hasAppOpenConfiguration ||
        _appOpenAd != null ||
        _appOpenLoading) {
      return;
    }
    _appOpenLoading = true;
    _appOpenLoadWaiter = Completer<void>();
    AppOpenAd.load(
      adUnitId: AdMobConfig.appOpenAdUnitId,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          _appOpenLoading = false;
          _appOpenAd = ad;
          _appOpenLoadedAt = DateTime.now();
          _appOpenLoadWaiter?.complete();
          _appOpenLoadWaiter = null;
          onStateChanged?.call();
        },
        onAdFailedToLoad: (_) {
          _appOpenLoading = false;
          _appOpenAd = null;
          _appOpenLoadedAt = null;
          _appOpenLoadWaiter?.complete();
          _appOpenLoadWaiter = null;
          onStateChanged?.call();
        },
      ),
    );
  }

  Future<bool> showInterstitialAfterScan(int completedScanCount) async {
    if (!_policy.shouldShowInterstitial(
      completedScanCount: completedScanCount,
      now: _now(),
      lastShownAt: _lastInterstitialShownAt,
    )) {
      return false;
    }
    return _showInterstitial(placement: 'interstitial');
  }

  /// Shows on the final onboarding button, at the explicit transition into
  /// the app. It bypasses completed-scan cadence while sharing the regular
  /// interstitial's inventory, in-flight guard, and cooldown.
  Future<bool> showOnboardingInterstitial() =>
      _showInterstitial(placement: 'onboarding_interstitial');

  /// Shows at a user-initiated drawer transition between the two primary app
  /// modes. It shares inventory and the global interstitial cooldown.
  Future<bool> showDrawerModeInterstitial({required bool aiScan}) =>
      _showInterstitial(placement: 'drawer_ai_scan_interstitial');

  /// History is another content destination, but it is kept separate from
  /// settings and help so utility navigation stays interruption-free.
  Future<bool> showDrawerHistoryInterstitial() =>
      _showInterstitial(placement: 'drawer_history_interstitial');

  /// A second saved-result close is a genuine content break. Failed/no-fill
  /// attempts remain silent and the shared cooldown still caps frequency.
  Future<bool> showHistoryDetailInterstitial(int completedDetailViews) {
    if (!_policy.isHistoryInterstitialBreak(completedDetailViews)) {
      return Future<bool>.value(false);
    }
    return _showInterstitial(placement: 'history_detail_interstitial');
  }

  Future<bool> _showInterstitial({required String placement}) async {
    if (!canRequestAds ||
        _anyFullScreenAdShowing ||
        !_interstitialCooldownElapsed(_now())) {
      return false;
    }
    final ad = _interstitial;
    if (ad == null) {
      unawaited(_loadInterstitial());
      return false;
    }
    _interstitial = null;
    _activeInterstitial = ad;
    _interstitialShowing = true;
    final result = Completer<bool>();
    _activeInterstitialResult = result;
    var didShow = false;

    void recordShown() {
      if (!identical(_activeInterstitial, ad) || didShow) return;
      didShow = true;
      _lastInterstitialShownAt = _now();
      onStateChanged?.call();
    }

    try {
      ad.configure(
        onShown: recordShown,
        onDismissed: () {
          // Dismissal proves the ad was visible even if a platform omitted its
          // earlier showed callback.
          recordShown();
          _finishInterstitial(ad, shown: true);
        },
        onFailedToShow: () => _finishInterstitial(ad, shown: false),
        onPaidEvent: (value, precision, currency) {
          onPaidEvent?.call(placement, value, precision, currency);
        },
      );
      await ad.show();
    } on Object {
      _finishInterstitial(ad, shown: false);
    }
    return result.future;
  }

  bool _interstitialCooldownElapsed(DateTime now) {
    final lastShownAt = _lastInterstitialShownAt;
    if (lastShownAt == null) return true;
    return now.difference(lastShownAt) >=
        Duration(seconds: _policy.interstitialCooldownSeconds);
  }

  void _finishInterstitial(InterstitialAdHandle ad, {required bool shown}) {
    if (!identical(_activeInterstitial, ad)) return;
    final result = _activeInterstitialResult;
    _activeInterstitial = null;
    _activeInterstitialResult = null;
    ad.dispose();
    _interstitialShowing = false;
    if (result != null && !result.isCompleted) result.complete(shown);
    if (!_disposed && _adsAllowed) unawaited(_loadInterstitial());
    onStateChanged?.call();
  }

  bool get _appOpenFresh {
    final loadedAt = _appOpenLoadedAt;
    return loadedAt != null &&
        DateTime.now().difference(loadedAt) < const Duration(hours: 4);
  }

  Future<bool> showAppOpenAfterLongBackground(Duration backgroundTime) async {
    if (!canRequestAds || _anyFullScreenAdShowing) return false;
    if (!_policy.shouldShowAppOpen(
      backgroundTime: backgroundTime,
      now: DateTime.now(),
      lastShownAt: _lastAppOpenShownAt,
    )) {
      return false;
    }
    var ad = _appOpenAd;
    if (ad == null || !_appOpenFresh) {
      ad?.dispose();
      _appOpenAd = null;
      _appOpenLoadedAt = null;
      _loadAppOpen();
      try {
        await _appOpenLoadWaiter?.future.timeout(const Duration(seconds: 2));
      } on TimeoutException {
        return false;
      }
      ad = _appOpenAd;
      if (ad == null || !_appOpenFresh) return false;
    }
    _appOpenAd = null;
    _appOpenLoadedAt = null;
    _appOpenShowing = true;
    ad.onPaidEvent = (ad, value, precision, currency) {
      onPaidEvent?.call('app_open', value, precision, currency);
    };
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) => _finishAppOpen(ad),
      onAdFailedToShowFullScreenContent: (ad, _) => _finishAppOpen(ad),
    );
    try {
      await ad.show();
      _lastAppOpenShownAt = DateTime.now();
      return true;
    } on Object {
      _finishAppOpen(ad);
      return false;
    }
  }

  void _finishAppOpen(AppOpenAd ad) {
    ad.dispose();
    _appOpenShowing = false;
    _loadAppOpen();
  }

  Future<bool> showRewarded({required void Function() onClientEarned}) async {
    if (!rewardedReady || _anyFullScreenAdShowing) {
      _loadRewarded();
      return false;
    }
    final ad = _rewarded!;
    _rewarded = null;
    _rewardedShowing = true;
    ad.onPaidEvent = (ad, value, precision, currency) {
      onPaidEvent?.call('rewarded', value, precision, currency);
    };
    final dismissed = Completer<bool>();
    var didEarn = false;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _rewardedShowing = false;
        if (!dismissed.isCompleted) dismissed.complete(didEarn);
        _loadRewarded();
      },
      onAdFailedToShowFullScreenContent: (ad, _) {
        ad.dispose();
        _rewardedShowing = false;
        if (!dismissed.isCompleted) dismissed.complete(false);
        _loadRewarded();
      },
    );
    try {
      await ad.show(
        onUserEarnedReward: (_, _) {
          if (didEarn) return;
          didEarn = true;
          onClientEarned();
        },
      );
    } on Object {
      ad.dispose();
      _rewardedShowing = false;
      if (!dismissed.isCompleted) dismissed.complete(false);
      _loadRewarded();
    }
    return dismissed.future;
  }

  void _disposeLoadedAds() {
    _rewarded?.dispose();
    _rewarded = null;
    _rewardedLoading = false;
    _rewardedShowing = false;
    _interstitial?.dispose();
    _interstitial = null;
    _activeInterstitial?.dispose();
    _activeInterstitial = null;
    final activeResult = _activeInterstitialResult;
    _activeInterstitialResult = null;
    if (activeResult != null && !activeResult.isCompleted) {
      activeResult.complete(false);
    }
    final loadWaiter = _interstitialLoadWaiter;
    _interstitialLoadWaiter = null;
    if (loadWaiter != null && !loadWaiter.isCompleted) {
      loadWaiter.complete(false);
    }
    _interstitialLoading = false;
    _interstitialShowing = false;
    _appOpenAd?.dispose();
    _appOpenAd = null;
    _appOpenLoadedAt = null;
    _appOpenLoading = false;
    _appOpenShowing = false;
    _appOpenLoadWaiter?.complete();
    _appOpenLoadWaiter = null;
  }

  void dispose() {
    _disposed = true;
    _disposeLoadedAds();
  }
}

Future<InterstitialAdHandle?> _loadGoogleInterstitial(String adUnitId) {
  final loaded = Completer<InterstitialAdHandle?>();
  unawaited(
    InterstitialAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          if (!loaded.isCompleted) {
            loaded.complete(_GoogleInterstitialAdHandle(ad));
          } else {
            ad.dispose();
          }
        },
        onAdFailedToLoad: (_) {
          if (!loaded.isCompleted) loaded.complete(null);
        },
      ),
    ).onError((_, _) {
      if (!loaded.isCompleted) loaded.complete(null);
    }),
  );
  return loaded.future;
}

final class _GoogleInterstitialAdHandle implements InterstitialAdHandle {
  _GoogleInterstitialAdHandle(this._ad);

  final InterstitialAd _ad;

  @override
  void configure({
    required VoidCallback onShown,
    required VoidCallback onDismissed,
    required VoidCallback onFailedToShow,
    required void Function(
      double valueMicros,
      PrecisionType precision,
      String currencyCode,
    )
    onPaidEvent,
  }) {
    _ad.onPaidEvent = (_, value, precision, currency) {
      onPaidEvent(value, precision, currency);
    };
    _ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (_) => onShown(),
      onAdDismissedFullScreenContent: (_) => onDismissed(),
      onAdFailedToShowFullScreenContent: (_, _) => onFailedToShow(),
    );
  }

  @override
  Future<void> show() => _ad.show();

  @override
  void dispose() => _ad.dispose();
}
