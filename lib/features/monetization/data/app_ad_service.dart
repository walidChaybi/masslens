import 'dart:async';

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

class AppAdService {
  AppAdService({this.onPaidEvent, this.onStateChanged});

  final PaidAdReporter? onPaidEvent;
  final void Function()? onStateChanged;

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
  RewardedAd? _rewarded;
  AppOpenAd? _appOpenAd;
  InterstitialAd? _interstitial;
  DateTime? _appOpenLoadedAt;
  DateTime? _lastAppOpenShownAt;
  DateTime? _lastInterstitialShownAt;
  Completer<void>? _appOpenLoadWaiter;
  AdPolicy _policy = const AdPolicy();

  bool get canRequestAds =>
      AdMobConfig.hasAnyConfiguration &&
      _adsAllowed &&
      (_canRequestAds || AdMobConfig.useTestIds);
  bool get canRequestNativeAds =>
      canRequestAds && AdMobConfig.hasNativeConfiguration;
  bool get rewardedReady =>
      canRequestAds &&
      AdMobConfig.hasRewardedConfiguration &&
      _rewarded != null;
  bool get privacyOptionsRequired => _privacyOptionsRequired;

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
    if (!AdMobConfig.hasAnyConfiguration) return;
    if (!_initialized) await _initialize();
    if (canRequestAds) _preloadAll();
  }

  Future<void> _initialize() async {
    if (_initialized) return;
    _initialized = true;
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
    _loadInterstitial();
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

  void _loadInterstitial() {
    if (!canRequestAds ||
        !AdMobConfig.hasInterstitialConfiguration ||
        _interstitial != null ||
        _interstitialLoading) {
      return;
    }
    _interstitialLoading = true;
    InterstitialAd.load(
      adUnitId: AdMobConfig.interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialLoading = false;
          _interstitial = ad;
          onStateChanged?.call();
        },
        onAdFailedToLoad: (_) {
          _interstitialLoading = false;
          _interstitial = null;
          onStateChanged?.call();
        },
      ),
    );
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
    if (!canRequestAds || _interstitialShowing) return false;
    if (!_policy.shouldShowInterstitial(
      completedScanCount: completedScanCount,
      now: DateTime.now(),
      lastShownAt: _lastInterstitialShownAt,
    )) {
      return false;
    }
    final ad = _interstitial;
    if (ad == null) {
      _loadInterstitial();
      return false;
    }
    _interstitial = null;
    _interstitialShowing = true;
    ad.onPaidEvent = (ad, value, precision, currency) {
      onPaidEvent?.call('interstitial', value, precision, currency);
    };
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) => _finishInterstitial(ad),
      onAdFailedToShowFullScreenContent: (ad, _) => _finishInterstitial(ad),
    );
    await ad.show();
    _lastInterstitialShownAt = DateTime.now();
    return true;
  }

  void _finishInterstitial(InterstitialAd ad) {
    ad.dispose();
    _interstitialShowing = false;
    _loadInterstitial();
  }

  bool get _appOpenFresh {
    final loadedAt = _appOpenLoadedAt;
    return loadedAt != null &&
        DateTime.now().difference(loadedAt) < const Duration(hours: 4);
  }

  Future<bool> showAppOpenAfterLongBackground(Duration backgroundTime) async {
    if (!canRequestAds || _appOpenShowing) return false;
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
    await ad.show();
    _lastAppOpenShownAt = DateTime.now();
    return true;
  }

  void _finishAppOpen(AppOpenAd ad) {
    ad.dispose();
    _appOpenShowing = false;
    _loadAppOpen();
  }

  Future<bool> showRewarded({required void Function() onClientEarned}) async {
    if (!rewardedReady) {
      _loadRewarded();
      return false;
    }
    final ad = _rewarded!;
    _rewarded = null;
    ad.onPaidEvent = (ad, value, precision, currency) {
      onPaidEvent?.call('rewarded', value, precision, currency);
    };
    final dismissed = Completer<bool>();
    var didEarn = false;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        if (!dismissed.isCompleted) dismissed.complete(didEarn);
        _loadRewarded();
      },
      onAdFailedToShowFullScreenContent: (ad, _) {
        ad.dispose();
        if (!dismissed.isCompleted) dismissed.complete(false);
        _loadRewarded();
      },
    );
    await ad.show(
      onUserEarnedReward: (_, _) {
        if (didEarn) return;
        didEarn = true;
        onClientEarned();
      },
    );
    return dismissed.future;
  }

  void _disposeLoadedAds() {
    _rewarded?.dispose();
    _rewarded = null;
    _rewardedLoading = false;
    _interstitial?.dispose();
    _interstitial = null;
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
