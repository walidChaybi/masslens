import 'dart:async';

import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'monetization_config.dart';

class AppAdService {
  AppAdService();

  bool _initialized = false;
  bool _adsAllowedForPlan = false;
  bool _canRequestAds = false;
  bool _privacyOptionsRequired = false;
  InterstitialAd? _interstitial;
  RewardedAd? _rewarded;
  int _completedScans = 0;

  bool get canRequestAds =>
      AdMobConfig.hasCompleteConfiguration &&
      _adsAllowedForPlan &&
      _canRequestAds;
  bool get rewardedReady => canRequestAds && _rewarded != null;
  bool get privacyOptionsRequired => _privacyOptionsRequired;

  Future<void> updatePlan({required bool adsAllowed}) async {
    _adsAllowedForPlan = adsAllowed;
    if (!adsAllowed) {
      _disposeLoadedAds();
      return;
    }
    if (!AdMobConfig.hasCompleteConfiguration) return;
    if (!_initialized) await _initialize();
    if (canRequestAds) {
      _loadInterstitial();
      _loadRewarded();
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
    if (_canRequestAds) await MobileAds.instance.initialize();
  }

  Future<void> showPrivacyOptions() async {
    if (!_privacyOptionsRequired) return;
    await ConsentForm.showPrivacyOptionsForm((_) {});
    _canRequestAds = await ConsentInformation.instance.canRequestAds();
  }

  void _loadInterstitial() {
    if (!canRequestAds || _interstitial != null) return;
    InterstitialAd.load(
      adUnitId: AdMobConfig.interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) => _interstitial = ad,
        onAdFailedToLoad: (_) => _interstitial = null,
      ),
    );
  }

  void _loadRewarded() {
    if (!canRequestAds || _rewarded != null) return;
    RewardedAd.load(
      adUnitId: AdMobConfig.rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) => _rewarded = ad,
        onAdFailedToLoad: (_) => _rewarded = null,
      ),
    );
  }

  /// Interstitials are shown only after a completed scan and only every third
  /// completion, which is a natural break in the workflow.
  Future<void> recordCompletedScanAndMaybeShowInterstitial() async {
    if (!canRequestAds) return;
    _completedScans += 1;
    if (_completedScans % 3 != 0 || _interstitial == null) return;
    final ad = _interstitial!;
    _interstitial = null;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _loadInterstitial();
      },
      onAdFailedToShowFullScreenContent: (ad, _) {
        ad.dispose();
        _loadInterstitial();
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
    _interstitial?.dispose();
    _rewarded?.dispose();
    _interstitial = null;
    _rewarded = null;
  }

  void dispose() => _disposeLoadedAds();
}
