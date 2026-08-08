class AdPolicy {
  const AdPolicy({
    this.interstitialEvery = 2,
    this.interstitialCooldownSeconds = 180,
    this.appOpenCooldownSeconds = 14400,
  });

  factory AdPolicy.fromJson(Map<String, Object?> json) => AdPolicy(
    interstitialEvery: _boundedInt(json['interstitialEvery'], 1, 100, 2),
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
    required this.scanAccessEnforced,
    required this.adsEnabled,
    required this.isAuthoritative,
    required this.analysisModel,
    required this.adPolicy,
  });

  const AccessStatus.fallback()
    : starterScansRemaining = 1,
      rewardedScans = 0,
      legacyScans = 0,
      remainingScans = 1,
      rewardBalanceCap = 3,
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
  final bool scanAccessEnforced;
  final bool adsEnabled;
  final bool isAuthoritative;
  final String analysisModel;
  final AdPolicy adPolicy;

  bool get canScan =>
      !isAuthoritative || !scanAccessEnforced || remainingScans > 0;
  bool get canEarnReward => rewardedScans < rewardBalanceCap;

  String get usageLabel {
    if (!isAuthoritative) return 'Checking scans…';
    if (!scanAccessEnforced) return 'Access preview';
    return '$remainingScans scan${remainingScans == 1 ? '' : 's'} left';
  }

  String get breakdownLabel {
    final parts = <String>[
      if (starterScansRemaining > 0) '$starterScansRemaining starter',
      if (rewardedScans > 0) '$rewardedScans rewarded',
      if (legacyScans > 0) '$legacyScans legacy',
    ];
    return parts.isEmpty ? 'No scans available' : parts.join(' · ');
  }
}
