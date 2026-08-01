import '../../scan/data/estimate_repository_factory.dart';
import '../domain/access_status.dart';

abstract final class MonetizationConfig {
  static const plans = <PlanDefinition>[
    PlanDefinition(
      productId: 'masslens_50_monthly',
      name: 'Basic',
      scanLimit: 50,
      subtitle: 'For occasional projects',
    ),
    PlanDefinition(
      productId: 'masslens_100_monthly',
      name: 'Plus',
      scanLimit: 100,
      subtitle: 'For regular use',
      recommended: true,
    ),
    PlanDefinition(
      productId: 'masslens_max_monthly',
      name: 'Max',
      scanLimit: 300,
      subtitle: 'For heavy use',
    ),
  ];

  static String get apiUrl => EstimateEngineConfig.cloudflareApiUrl;
  static bool get backendConfigured => apiUrl.trim().isNotEmpty;
  static Set<String> get productIds =>
      plans.map((plan) => plan.productId).toSet();
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
  );
  static const _interstitialProduction = String.fromEnvironment(
    'ADMOB_INTERSTITIAL_AD_UNIT_ID',
  );
  static const _rewardedProduction = String.fromEnvironment(
    'ADMOB_REWARDED_AD_UNIT_ID',
  );

  static const _nativeTest = 'ca-app-pub-3940256099942544/2247696110';
  static const _interstitialTest = 'ca-app-pub-3940256099942544/1033173712';
  static const _rewardedTest = 'ca-app-pub-3940256099942544/5224354917';

  static String get nativeAdUnitId =>
      useTestIds ? _nativeTest : _nativeProduction;
  static String get interstitialAdUnitId =>
      useTestIds ? _interstitialTest : _interstitialProduction;
  static String get rewardedAdUnitId =>
      useTestIds ? _rewardedTest : _rewardedProduction;

  static bool get hasCompleteConfiguration =>
      enabled &&
      nativeAdUnitId.isNotEmpty &&
      interstitialAdUnitId.isNotEmpty &&
      rewardedAdUnitId.isNotEmpty;
}
