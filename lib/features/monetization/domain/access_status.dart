class AccessStatus {
  const AccessStatus({
    required this.planId,
    required this.planName,
    required this.scanLimit,
    required this.scansUsed,
    required this.bonusCredits,
    required this.remainingScans,
    required this.isPaid,
    required this.adsEnabled,
    required this.billingEnforced,
    required this.isAuthoritative,
    this.periodEndsAt,
  });

  const AccessStatus.fallback()
    : planId = 'free',
      planName = 'Free',
      scanLimit = 3,
      scansUsed = 0,
      bonusCredits = 0,
      remainingScans = 3,
      isPaid = false,
      adsEnabled = false,
      billingEnforced = false,
      isAuthoritative = false,
      periodEndsAt = null;

  factory AccessStatus.fromJson(Map<String, Object?> json) {
    return AccessStatus(
      planId: json['planId'] as String? ?? 'free',
      planName: json['planName'] as String? ?? 'Free',
      scanLimit: (json['scanLimit'] as num?)?.toInt() ?? 3,
      scansUsed: (json['scansUsed'] as num?)?.toInt() ?? 0,
      bonusCredits: (json['bonusCredits'] as num?)?.toInt() ?? 0,
      remainingScans: (json['remainingScans'] as num?)?.toInt() ?? 0,
      isPaid: json['isPaid'] as bool? ?? false,
      adsEnabled: json['adsEnabled'] as bool? ?? false,
      billingEnforced: json['billingEnforced'] as bool? ?? false,
      isAuthoritative: true,
      periodEndsAt: DateTime.tryParse(json['periodEndsAt'] as String? ?? ''),
    );
  }

  final String planId;
  final String planName;
  final int scanLimit;
  final int scansUsed;
  final int bonusCredits;
  final int remainingScans;
  final bool isPaid;
  final bool adsEnabled;
  final bool billingEnforced;
  final bool isAuthoritative;
  final DateTime? periodEndsAt;

  /// If the access service is temporarily unreachable, the Worker remains the
  /// final authority. We do not lock an otherwise valid customer out locally.
  bool get canScan =>
      !isAuthoritative || !billingEnforced || remainingScans > 0;

  String get usageLabel {
    if (!billingEnforced) return 'Billing preview';
    return '$remainingScans scan${remainingScans == 1 ? '' : 's'} left';
  }
}

class PlanDefinition {
  const PlanDefinition({
    required this.productId,
    required this.name,
    required this.scanLimit,
    required this.subtitle,
    this.recommended = false,
  });

  final String productId;
  final String name;
  final int scanLimit;
  final String subtitle;
  final bool recommended;
}
