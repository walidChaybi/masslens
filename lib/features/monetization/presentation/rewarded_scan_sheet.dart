import 'dart:async';

import 'package:flutter/material.dart';

import '../../../app/app_controller.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_components.dart';
import '../../../l10n/l10n.dart';
import '../../../l10n/display_labels.dart';
import '../application/monetization_controller.dart';
import 'access_paywall.dart';
import 'premium_cta.dart';

Future<bool> showRewardedScanSheet(BuildContext context) async =>
    await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: context.palette.canvas,
      builder: (_) => const _EarnScanSheet(),
    ) ??
    false;

Future<bool> showPremiumAccessSheet(BuildContext context) async =>
    await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: false,
      backgroundColor: paywallSurface,
      builder: (sheetContext) => SizedBox(
        height: MediaQuery.sizeOf(sheetContext).height * 0.94,
        child: AccessPaywall(
          onUnlocked: () => Navigator.of(sheetContext).pop(true),
          onSkip: () => Navigator.of(sheetContext).pop(false),
        ),
      ),
    ) ??
    false;

class _EarnScanSheet extends StatefulWidget {
  const _EarnScanSheet();

  @override
  State<_EarnScanSheet> createState() => _EarnScanSheetState();
}

class _EarnScanSheetState extends State<_EarnScanSheet> {
  bool _watching = false;
  bool _checking = false;
  Timer? _retryTicker;

  @override
  void initState() {
    super.initState();
    _retryTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _retryTicker?.cancel();
    super.dispose();
  }

  Future<void> _watch() async {
    if (_watching || _checking) return;
    setState(() => _watching = true);
    final monetization = AppScope.of(context).monetization;
    final added = await monetization.watchAdForScan();
    if (!mounted) return;
    setState(() => _watching = false);
    if (added) {
      Navigator.of(context).pop(true);
      return;
    }
    if (monetization.hasPendingReward) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_watchFailureText(context)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _check() async {
    if (_watching || _checking) return;
    setState(() => _checking = true);
    final monetization = AppScope.of(context).monetization;
    final added = await monetization.reconcileRewardAttempts();
    if (!mounted) return;
    setState(() => _checking = false);
    if (added) {
      Navigator.of(context).pop(true);
      return;
    }
    if (!monetization.hasPendingReward) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.rewardNoCreditAdded),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _retryAd() async {
    if (_watching || _checking) return;
    setState(() => _checking = true);
    await AppScope.of(context).monetization.refreshAccess();
    if (mounted) setState(() => _checking = false);
  }

  Future<void> _openPremiumPaywall() async {
    final unlocked = await showPremiumAccessSheet(context);
    if (!mounted) return;
    if (unlocked) Navigator.of(context).pop(true);
  }

  String _retryText(BuildContext context, Duration duration) {
    final seconds = (duration.inMilliseconds / 1000).ceil();
    if (seconds >= 60) {
      return context.l10n.rewardAnotherAdMinutes((seconds / 60).ceil());
    }
    return context.l10n.rewardAnotherAdSeconds(seconds);
  }

  String _watchFailureText(BuildContext context) {
    final monetization = AppScope.of(context).monetization;
    final access = monetization.access;
    final l10n = context.l10n;
    if (!access.adsEnabled) {
      return access.legacyScans > 0
          ? l10n.rewardUseLegacyFirst
          : l10n.rewardAccessStateUnavailable;
    }
    if (!monetization.canRequestAds) return l10n.rewardUnavailable;
    if (!access.canEarnReward) {
      return l10n.rewardMaxBalance(access.rewardBalanceCap);
    }
    if (monetization.rewardFlowState == RewardFlowState.failed) {
      return l10n.rewardNoCreditAdded;
    }
    if (monetization.rewardStartBlocked) {
      return _retryText(context, monetization.rewardRetryAfter);
    }
    if (!monetization.rewardedAdReady) return l10n.rewardLoading;
    return l10n.rewardNoCreditAdded;
  }

  @override
  Widget build(BuildContext context) {
    final monetization = AppScope.of(context).monetization;
    final access = monetization.access;
    final l10n = context.l10n;
    final busy = _watching || _checking || monetization.rewardActionBusy;
    final retryAfter = monetization.rewardRetryAfter;
    final usageLabel = localizedScanUsage(l10n, access);
    final breakdownLabel = access.debugUnlimited
        ? 'Debug · ∞'
        : access.hasLifetime
        ? l10n.accessLifetimeActive
        : l10n.accessBreakdown(
            access.starterScansRemaining,
            access.rewardedScans,
            access.legacyScans,
          );
    final canWatch =
        !busy &&
        access.adsEnabled &&
        access.canEarnReward &&
        monetization.canRequestAds &&
        monetization.rewardedAdReady &&
        !monetization.rewardStartBlocked;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        22,
        8,
        22,
        24 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const MassLensLogo(compact: true),
          const SizedBox(height: 18),
          Eyebrow(l10n.rewardAdsFundAnalysis),
          const SizedBox(height: 8),
          Text(
            l10n.rewardHeadline,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 10),
          Text(
            l10n.rewardBody,
            textAlign: TextAlign.center,
            style: TextStyle(color: context.palette.inkMuted, height: 1.45),
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.palette.surface,
              border: Border.all(color: context.palette.line),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(Icons.confirmation_number_outlined),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        usageLabel,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        breakdownLabel,
                        style: TextStyle(
                          color: context.palette.inkMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!access.debugUnlimited && !access.hasLifetime)
                  Flexible(
                    child: Text(
                      l10n.rewardMaxBalance(access.rewardBalanceCap),
                      style: TextStyle(
                        color: context.palette.inkMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          if (monetization.hasPendingReward) ...[
            Container(
              key: const Key('reward_sync_pending'),
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
              decoration: BoxDecoration(
                color: context.palette.lime.withValues(alpha: 0.18),
                border: Border.all(
                  color: context.palette.limeDark.withValues(alpha: 0.35),
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.sync_rounded, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.rewardSyncPending,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          l10n.rewardSafeToClose,
                          style: TextStyle(
                            color: context.palette.inkMuted,
                            fontSize: 11.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    key: const Key('check_reward_status'),
                    onPressed: busy ? null : _check,
                    child: Text(
                      _checking ? l10n.rewardChecking : l10n.rewardCheck,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          PremiumUpgradeButton(
            key: const Key('earn_unlock_unlimited'),
            onPressed: busy ? null : _openPremiumPaywall,
            priceLabel: monetization.lifetimePriceLabel,
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              key: const Key('watch_ad_for_scan'),
              onPressed: canWatch ? _watch : null,
              style: FilledButton.styleFrom(
                backgroundColor: context.palette.aqua,
                foregroundColor: context.palette.onLime,
                disabledBackgroundColor: context.palette.aqua.withValues(
                  alpha: 0.35,
                ),
                disabledForegroundColor: context.palette.onLime.withValues(
                  alpha: 0.55,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: Icon(
                busy
                    ? Icons.shield_outlined
                    : monetization.rewardStartBlocked
                    ? Icons.schedule_rounded
                    : Icons.play_circle_outline_rounded,
              ),
              label: Text(
                busy
                    ? l10n.rewardAdding
                    : monetization.rewardStartBlocked
                    ? _retryText(context, retryAfter)
                    : !monetization.canRequestAds
                    ? l10n.rewardUnavailable
                    : monetization.rewardedAdReady
                    ? l10n.rewardWatchForOne
                    : l10n.rewardLoading,
              ),
            ),
          ),
          if (!access.adsEnabled) ...[
            const SizedBox(height: 12),
            Text(
              access.legacyScans > 0
                  ? l10n.rewardUseLegacyFirst
                  : l10n.rewardAccessStateUnavailable,
              textAlign: TextAlign.center,
              style: TextStyle(color: context.palette.inkMuted, fontSize: 12),
            ),
          ] else if (!monetization.canRequestAds) ...[
            const SizedBox(height: 12),
            Text(
              l10n.rewardConsentUnavailable,
              textAlign: TextAlign.center,
              style: TextStyle(color: context.palette.inkMuted, fontSize: 12),
            ),
            if (monetization.privacyOptionsRequired)
              TextButton(
                onPressed: busy
                    ? null
                    : () => monetization.showPrivacyOptions(),
                child: Text(l10n.rewardPrivacyChoices),
              ),
          ] else if (!monetization.rewardedAdReady && !busy) ...[
            const SizedBox(height: 10),
            TextButton.icon(
              key: const Key('retry_rewarded_ad'),
              onPressed: _retryAd,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(l10n.rewardTryLoadingAgain),
            ),
          ],
        ],
      ),
    );
  }
}
