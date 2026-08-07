import '../../scan/data/estimate_repository_factory.dart';
import '../domain/access_status.dart';

abstract final class MonetizationConfig {
  static const packs = <ScanPackDefinition>[
    ScanPackDefinition(
      productId: 'masslens_100_scans',
      name: 'Basic',
      scanCredits: 100,
      subtitle: 'One-time pack',
    ),
    ScanPackDefinition(
      productId: 'masslens_500_scans',
      name: 'Max',
      scanCredits: 500,
      subtitle: 'Save about 20% per scan',
      recommended: true,
    ),
  ];

  static String get apiUrl => EstimateEngineConfig.cloudflareApiUrl;
  static bool get backendConfigured => apiUrl.trim().isNotEmpty;
  static Set<String> get productIds =>
      packs.map((pack) => pack.productId).toSet();
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

  static const _nativeTest = 'ca-app-pub-3940256099942544/2247696110';
  static const _rewardedTest = 'ca-app-pub-3940256099942544/5224354917';
  static const _appOpenTest = 'ca-app-pub-3940256099942544/9257395921';

  static String get nativeAdUnitId =>
      useTestIds ? _nativeTest : _nativeProduction;
  static String get rewardedAdUnitId =>
      useTestIds ? _rewardedTest : _rewardedProduction;
  static String get appOpenAdUnitId =>
      useTestIds ? _appOpenTest : _appOpenProduction;

  static bool get hasNativeConfiguration =>
      enabled && nativeAdUnitId.isNotEmpty;
  static bool get hasRewardedConfiguration =>
      enabled && rewardedAdUnitId.isNotEmpty;
  static bool get hasAppOpenConfiguration =>
      enabled && appOpenAdUnitId.isNotEmpty;
  static bool get hasAnyConfiguration =>
      hasNativeConfiguration ||
      hasRewardedConfiguration ||
      hasAppOpenConfiguration;
}
