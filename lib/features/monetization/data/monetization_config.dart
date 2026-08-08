import 'package:flutter/foundation.dart';

import '../../scan/data/estimate_repository_factory.dart';

abstract final class MonetizationConfig {
  static String get apiUrl => EstimateEngineConfig.cloudflareApiUrl;
  static bool get backendConfigured => apiUrl.trim().isNotEmpty;

  static void validateProduction() {
    if (!kReleaseMode) return;
    if (!backendConfigured) {
      throw StateError('MASSLENS_API_URL is required for release builds.');
    }
    if (!AdMobConfig.enabled ||
        AdMobConfig.useTestIds ||
        !AdMobConfig.productionConfigurationValid) {
      throw StateError(
        'Release builds require enabled production AdMob IDs for native, '
        'rewarded, interstitial, and app-open ads.',
      );
    }
  }
}

abstract final class AdMobConfig {
  /// Ads remain completely disabled unless this is explicitly enabled at
  /// build time. This makes test and review builds deterministic.
  static const enabled = bool.fromEnvironment(
    'ADMOB_ENABLED',
    defaultValue: false,
  );
  static const useTestIds = bool.fromEnvironment(
    'ADMOB_USE_TEST_IDS',
    defaultValue: true,
  );
  static const debugRewardedUsesProductionId = bool.fromEnvironment(
    'ADMOB_DEBUG_REWARDED_SSV',
    defaultValue: false,
  );
  static const _testDeviceIdsValue = String.fromEnvironment(
    'ADMOB_TEST_DEVICE_IDS',
  );

  static const _nativeProduction = String.fromEnvironment(
    'ADMOB_NATIVE_AD_UNIT_ID',
    defaultValue: 'ca-app-pub-7681170430097585/1035038854',
  );
  static const _rewardedProduction = String.fromEnvironment(
    'ADMOB_REWARDED_AD_UNIT_ID',
    defaultValue: 'ca-app-pub-7681170430097585/3756662851',
  );
  static const _appOpenProduction = String.fromEnvironment(
    'ADMOB_APP_OPEN_AD_UNIT_ID',
    defaultValue: 'ca-app-pub-7681170430097585/3116075891',
  );
  static const _interstitialProduction = String.fromEnvironment(
    'ADMOB_INTERSTITIAL_AD_UNIT_ID',
  );

  static const _nativeTest = 'ca-app-pub-3940256099942544/2247696110';
  static const _rewardedTest = 'ca-app-pub-3940256099942544/5224354917';
  static const _appOpenTest = 'ca-app-pub-3940256099942544/9257395921';
  static const _interstitialTest = 'ca-app-pub-3940256099942544/1033173712';

  static String get nativeAdUnitId =>
      useTestIds ? _nativeTest : _nativeProduction;
  static String get rewardedAdUnitId =>
      useTestIds && !(kDebugMode && debugRewardedUsesProductionId)
      ? _rewardedTest
      : _rewardedProduction;
  static String get appOpenAdUnitId =>
      useTestIds ? _appOpenTest : _appOpenProduction;
  static String get interstitialAdUnitId =>
      useTestIds ? _interstitialTest : _interstitialProduction;

  static bool get hasNativeConfiguration =>
      enabled && nativeAdUnitId.isNotEmpty;
  static bool get hasRewardedConfiguration =>
      enabled && rewardedAdUnitId.isNotEmpty;
  static bool get hasAppOpenConfiguration =>
      enabled && appOpenAdUnitId.isNotEmpty;
  static bool get hasInterstitialConfiguration =>
      enabled && interstitialAdUnitId.isNotEmpty;
  static bool get hasAnyConfiguration =>
      hasNativeConfiguration ||
      hasRewardedConfiguration ||
      hasAppOpenConfiguration ||
      hasInterstitialConfiguration;

  static List<String> get testDeviceIds => _testDeviceIdsValue
      .split(',')
      .map((value) => value.trim())
      .where((value) => value.isNotEmpty)
      .toList(growable: false);

  static bool get productionConfigurationValid =>
      !enabled ||
      useTestIds ||
      (nativeAdUnitId.isNotEmpty &&
          rewardedAdUnitId.isNotEmpty &&
          appOpenAdUnitId.isNotEmpty &&
          interstitialAdUnitId.isNotEmpty);
}
