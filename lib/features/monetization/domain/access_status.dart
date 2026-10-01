import 'package:flutter/foundation.dart';

class AdPolicy {
  const AdPolicy({
    this.interstitialEvery = 2,
    this.historyInterstitialEvery = 2,
    this.interstitialCooldownSeconds = 180,
    this.appOpenCooldownSeconds = 14400,
  });

  factory AdPolicy.fromJson(Map<String, Object?> json) => AdPolicy(
    interstitialEvery: _boundedInt(json['interstitialEvery'], 1, 100, 2),
    historyInterstitialEvery: _boundedInt(
      json['historyInterstitialEvery'],
      2,
      100,
      2,
    ),
    interstitialCooldownSeconds: _boundedInt(
      json['interstitialCooldownSeconds'],
      30,
      86400,
      180,
    ),
    appOpenCooldownSeconds: _boundedInt(
      json['appOpenCooldownSeconds'],
      300,
      86400,
      14400,
    ),
  );

  final int interstitialEvery;
  final int historyInterstitialEvery;
  final int interstitialCooldownSeconds;
  final int appOpenCooldownSeconds;

  bool shouldShowInterstitial({
    required int completedScanCount,
    required DateTime now,
    DateTime? lastShownAt,
  }) =>
      completedScanCount > 0 &&
      completedScanCount % interstitialEvery == 0 &&
      (lastShownAt == null ||
          now.difference(lastShownAt) >=
              Duration(seconds: interstitialCooldownSeconds));

  bool isHistoryInterstitialBreak(int completedDetailViews) =>
      completedDetailViews > 0 &&
      completedDetailViews % historyInterstitialEvery == 0;

  bool shouldShowAppOpen({
    required Duration backgroundTime,
    required DateTime now,
    DateTime? lastShownAt,
  }) {
    final cooldown = Duration(seconds: appOpenCooldownSeconds);
    return backgroundTime >= cooldown &&
        (lastShownAt == null || now.difference(lastShownAt) >= cooldown);
  }
}

int _boundedInt(Object? value, int minimum, int maximum, int fallback) =>
    value is num ? value.toInt().clamp(minimum, maximum) : fallback;

class AccessStatus {
  const AccessStatus({
    required this.starterScansRemaining,
    required this.rewardedScans,
    required this.legacyScans,
    required this.remainingScans,
    required this.rewardBalanceCap,
    required this.hasLifetime,
    this.debugUnlimited = false,
    required this.scanAccessEnforced,
    required this.adsEnabled,
    required this.isAuthoritative,
    required this.analysisModel,
    required this.adPolicy,
  });

  const AccessStatus.fallback()
    : starterScansRemaining = 2,
      rewardedScans = 0,
      legacyScans = 0,
      remainingScans = 2,
      rewardBalanceCap = 3,
      hasLifetime = false,
      debugUnlimited = false,
      scanAccessEnforced = false,
      adsEnabled = false,
      isAuthoritative = false,
      analysisModel = 'gpt-5-nano',
      adPolicy = const AdPolicy();

  factory AccessStatus.fromJson(Map<String, Object?> json) {
    final policy = json['adPolicy'];
    return AccessStatus(
      starterScansRemaining:
          (json['starterScansRemaining'] as num?)?.toInt() ?? 0,
      rewardedScans: (json['rewardedScans'] as num?)?.toInt() ?? 0,
      legacyScans: (json['legacyScans'] as num?)?.toInt() ?? 0,
      remainingScans: (json['remainingScans'] as num?)?.toInt() ?? 0,
      rewardBalanceCap: (json['rewardBalanceCap'] as num?)?.toInt() ?? 3,
      hasLifetime: json['hasLifetime'] as bool? ?? false,
      debugUnlimited: kDebugMode && json['debugUnlimited'] == true,
      scanAccessEnforced: json['scanAccessEnforced'] as bool? ?? false,
      adsEnabled: json['adsEnabled'] as bool? ?? false,
      isAuthoritative: true,
      analysisModel: json['analysisModel'] as String? ?? 'gpt-5-nano',
      adPolicy: policy is Map
          ? AdPolicy.fromJson(Map<String, Object?>.from(policy))
          : const AdPolicy(),
    );
  }

  final int starterScansRemaining;
  final int rewardedScans;
  final int legacyScans;
  final int remainingScans;
  final int rewardBalanceCap;
  final bool hasLifetime;
  final bool debugUnlimited;
  final bool scanAccessEnforced;
  final bool adsEnabled;
  final bool isAuthoritative;
  final String analysisModel;
  final AdPolicy adPolicy;

  /// AI access fails closed until the production Worker confirms both the
  /// enforced wallet contract and a positive balance or lifetime unlock.
  bool get canScan =>
      isAuthoritative &&
      scanAccessEnforced &&
      (hasLifetime || debugUnlimited || remainingScans > 0);
  bool get canEarnReward =>
      !hasLifetime && adsEnabled && rewardedScans < rewardBalanceCap;
}
