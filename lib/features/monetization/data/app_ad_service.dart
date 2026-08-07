import 'dart:async';

import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'monetization_config.dart';

class AppAdService {
  AppAdService();

  bool _initialized = false;
  bool _adsAllowedForPlan = false;
  bool _canRequestAds = false;
  bool _privacyOptionsRequired = false;
  bool _appOpenLoading = false;
  bool _appOpenShowing = false;
  bool _appOpenShowPending = false;
  RewardedAd? _rewarded;
  AppOpenAd? _appOpenAd;
  DateTime? _appOpenLoadedAt;

  bool get canRequestAds =>
      AdMobConfig.hasAnyConfiguration &&
      _adsAllowedForPlan &&
      (_canRequestAds || AdMobConfig.useTestIds);
  bool get canRequestNativeAds =>
      canRequestAds && AdMobConfig.hasNativeConfiguration;
  bool get canRequestAppOpenAds =>
      canRequestAds && AdMobConfig.hasAppOpenConfiguration;
  bool get rewardedReady =>
      canRequestAds &&
      AdMobConfig.hasRewardedConfiguration &&
      _rewarded != null;
  bool get privacyOptionsRequired => _privacyOptionsRequired;

  Future<void> updatePlan({required bool adsAllowed}) async {
    _adsAllowedForPlan = adsAllowed;
    if (!adsAllowed) {
      _disposeLoadedAds();
      return;
    }
    if (!AdMobConfig.hasAnyConfiguration) return;
    if (!_initialized) await _initialize();
    if (canRequestAds) {
      _loadRewarded();
      _loadAppOpen();
    }
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
        // Cached consent can still legally allow requests when the update fails.
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
    }
  }

  Future<void> showPrivacyOptions() async {
    if (!_privacyOptionsRequired) return;
    await ConsentForm.showPrivacyOptionsForm((_) {});
    _canRequestAds = await ConsentInformation.instance.canRequestAds();
    if (_canRequestAds) {
      _loadRewarded();
      _loadAppOpen();
    } else {
      _disposeLoadedAds();
    }
  }

  void _loadRewarded() {
    if (!canRequestAds ||
        !AdMobConfig.hasRewardedConfiguration ||
        _rewarded != null) {
      return;
    }
    RewardedAd.load(
      adUnitId: AdMobConfig.rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) => _rewarded = ad,
        onAdFailedToLoad: (_) => _rewarded = null,
      ),
    );
  }

  void _loadAppOpen() {
    if (!canRequestAppOpenAds || _appOpenAd != null || _appOpenLoading) {
      return;
    }
    _appOpenLoading = true;
    AppOpenAd.load(
      adUnitId: AdMobConfig.appOpenAdUnitId,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          _appOpenLoading = false;
          _appOpenAd = ad;
          _appOpenLoadedAt = DateTime.now();
          if (_appOpenShowPending) unawaited(showAppOpenIfAvailable());
        },
        onAdFailedToLoad: (_) {
          _appOpenLoading = false;
          _appOpenShowPending = false;
          _appOpenAd = null;
          _appOpenLoadedAt = null;
        },
      ),
    );
  }

  bool get _appOpenFresh {
    final loadedAt = _appOpenLoadedAt;
    if (loadedAt == null) return false;
    return DateTime.now().difference(loadedAt) < const Duration(hours: 4);
  }

  DateTime? _lastAppOpenDismissedAt;

  Future<void> showAppOpenIfAvailable() async {
    if (!canRequestAppOpenAds || _appOpenShowing) return;

    // Prevent infinite loops when returning from the ad itself,
    // and prevent spamming if the user quickly switches apps.
    if (_lastAppOpenDismissedAt != null &&
        DateTime.now().difference(_lastAppOpenDismissedAt!) <
            const Duration(seconds: 15)) {
      return;
    }

    if (_appOpenAd == null || !_appOpenFresh) {
      _appOpenShowPending = true;
      _appOpenAd?.dispose();
      _appOpenAd = null;
      _appOpenLoadedAt = null;
      _loadAppOpen();
      return;
    }

    final ad = _appOpenAd!;
    _appOpenAd = null;
    _appOpenLoadedAt = null;
    _appOpenShowPending = false;
    _appOpenShowing = true;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _appOpenShowing = false;
        _lastAppOpenDismissedAt = DateTime.now();
        _loadAppOpen();
      },
      onAdFailedToShowFullScreenContent: (ad, _) {
        ad.dispose();
        _appOpenShowing = false;
        _lastAppOpenDismissedAt = DateTime.now();
        _loadAppOpen();
      },
    );
    await ad.show();
  }

  Future<bool> showRewarded({required String clientId}) async {
    if (!rewardedReady) {
      _loadRewarded();
      return false;
    }
    final ad = _rewarded!;
    _rewarded = null;
    await ad.setServerSideOptions(
      ServerSideVerificationOptions(userId: clientId),
    );
    final earned = Completer<bool>();
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        if (!earned.isCompleted) earned.complete(false);
        _loadRewarded();
      },
      onAdFailedToShowFullScreenContent: (ad, _) {
        ad.dispose();
        if (!earned.isCompleted) earned.complete(false);
        _loadRewarded();
      },
    );
    await ad.show(
      onUserEarnedReward: (_, _) {
        if (!earned.isCompleted) earned.complete(true);
      },
    );
    return earned.future;
  }

  void _disposeLoadedAds() {
    _rewarded?.dispose();
    _rewarded = null;
    _appOpenAd?.dispose();
    _appOpenAd = null;
    _appOpenLoadedAt = null;
    _appOpenLoading = false;
    _appOpenShowing = false;
    _appOpenShowPending = false;
  }

  void dispose() => _disposeLoadedAds();
}
