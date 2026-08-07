class AccessStatus {
  const AccessStatus({
    required this.freeScanLimit,
    required this.freeScansUsed,
    required this.bonusCredits,
    required this.purchasedCredits,
    required this.creditDebt,
    required this.remainingScans,
    required this.hasPaidCredits,
    required this.adsEnabled,
    required this.billingEnforced,
    required this.isAuthoritative,
    this.freeResetsAt,
  });

  const AccessStatus.fallback()
    : freeScanLimit = 3,
      freeScansUsed = 0,
      bonusCredits = 0,
      purchasedCredits = 0,
      creditDebt = 0,
      remainingScans = 3,
      hasPaidCredits = false,
      adsEnabled = true,
      billingEnforced = false,
      isAuthoritative = false,
      freeResetsAt = null;

  factory AccessStatus.fromJson(Map<String, Object?> json) {
    return AccessStatus(
      freeScanLimit: (json['scanLimit'] as num?)?.toInt() ?? 3,
      freeScansUsed: (json['scansUsed'] as num?)?.toInt() ?? 0,
      bonusCredits: (json['bonusCredits'] as num?)?.toInt() ?? 0,
      purchasedCredits: (json['purchasedCredits'] as num?)?.toInt() ?? 0,
      creditDebt: (json['creditDebt'] as num?)?.toInt() ?? 0,
      remainingScans: (json['remainingScans'] as num?)?.toInt() ?? 0,
      hasPaidCredits: json['isPaid'] as bool? ?? false,
      adsEnabled: json['adsEnabled'] as bool? ?? false,
      billingEnforced: json['billingEnforced'] as bool? ?? false,
      isAuthoritative: true,
      freeResetsAt: DateTime.tryParse(json['periodEndsAt'] as String? ?? ''),
    );
  }

  final int freeScanLimit;
  final int freeScansUsed;
  final int bonusCredits;
  final int purchasedCredits;
  final int creditDebt;
  final int remainingScans;
  final bool hasPaidCredits;
  final bool adsEnabled;
  final bool billingEnforced;
  final bool isAuthoritative;
  final DateTime? freeResetsAt;

  int get freeScansRemaining =>
      (freeScanLimit - freeScansUsed).clamp(0, freeScanLimit);

  String get balanceName => hasPaidCredits ? 'Scan credits' : 'Free';

  /// If the access service is temporarily unreachable, the Worker remains the
  /// final authority. We do not lock an otherwise valid customer out locally.
  bool get canScan =>
      !isAuthoritative || !billingEnforced || remainingScans > 0;

  String get usageLabel {
    if (!billingEnforced) return 'Billing preview';
    return '$remainingScans scan${remainingScans == 1 ? '' : 's'} left';
  }
}

class ScanPackDefinition {
  const ScanPackDefinition({
    required this.productId,
    required this.name,
    required this.scanCredits,
    required this.subtitle,
    this.recommended = false,
  });

  final String productId;
  final String name;
  final int scanCredits;
  final String subtitle;
  final bool recommended;
}
