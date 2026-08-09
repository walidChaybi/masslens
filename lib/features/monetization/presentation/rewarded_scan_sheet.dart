import 'dart:async';

import 'package:flutter/material.dart';

import '../../../app/app_controller.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_components.dart';

Future<bool> showRewardedScanSheet(BuildContext context) async =>
    await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: AppColors.canvas,
      builder: (_) => const _RewardedScanBody(),
    ) ??
    false;

class _RewardedScanBody extends StatefulWidget {
  const _RewardedScanBody();

  @override
  State<_RewardedScanBody> createState() => _RewardedScanBodyState();
}

class _RewardedScanBodyState extends State<_RewardedScanBody> {
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
        content: Text(
          monetization.message ?? 'The scan credit is still syncing.',
        ),
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
          content: Text(
            monetization.message ?? 'No pending scan credit was added.',
          ),
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

  String _retryText(Duration duration) {
    final seconds = (duration.inMilliseconds / 1000).ceil();
    if (seconds >= 60) return '${(seconds / 60).ceil()} min';
    return '$seconds sec';
  }

  @override
  Widget build(BuildContext context) {
    final monetization = AppScope.of(context).monetization;
    final access = monetization.access;
    final busy = _watching || _checking || monetization.rewardActionBusy;
    final retryAfter = monetization.rewardRetryAfter;
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
          const Eyebrow('Ads fund real AI analysis'),
          const SizedBox(height: 8),
          Text(
            'Watch one ad.\nGet one scan.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 10),
          const Text(
            'Finish the ad and MassLens adds one scan. No subscription, '
            'purchase, or fabricated result.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.inkMuted, height: 1.45),
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border.all(color: AppColors.line),
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
                        access.usageLabel,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        access.breakdownLabel,
                        style: const TextStyle(
                          color: AppColors.inkMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  'Max ${access.rewardBalanceCap}',
                  style: const TextStyle(
                    color: AppColors.inkMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
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
                color: AppColors.lime.withValues(alpha: 0.18),
                border: Border.all(
                  color: AppColors.limeDark.withValues(alpha: 0.35),
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.sync_rounded, size: 22),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Scan credit sync pending',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Safe to close. We will keep checking for 24 hours.',
                          style: TextStyle(
                            color: AppColors.inkMuted,
                            fontSize: 11.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    key: const Key('check_reward_status'),
                    onPressed: busy ? null : _check,
                    child: Text(_checking ? 'Checking' : 'Check'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              key: const Key('watch_ad_for_scan'),
              onPressed: canWatch ? _watch : null,
              icon: Icon(
                busy
                    ? Icons.shield_outlined
                    : monetization.rewardStartBlocked
                    ? Icons.schedule_rounded
                    : Icons.play_circle_outline_rounded,
              ),
              label: Text(
                busy
                    ? 'Adding your scan…'
                    : monetization.rewardStartBlocked
                    ? 'Another ad in ${_retryText(retryAfter)}'
                    : !monetization.canRequestAds
                    ? 'Rewarded ads unavailable'
                    : monetization.rewardedAdReady
                    ? 'Watch an ad · Get 1 scan'
                    : 'Rewarded ad is loading',
              ),
            ),
          ),
          if (!access.adsEnabled) ...[
            const SizedBox(height: 12),
            Text(
              access.legacyScans > 0
                  ? 'Use your ad-free scan credit before earning more scans.'
                  : 'Rewarded ads are not available for this access state.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.inkMuted, fontSize: 12),
            ),
          ] else if (!monetization.canRequestAds) ...[
            const SizedBox(height: 12),
            const Text(
              'Ads are unavailable because of consent or configuration. '
              'Existing scans and non-AI features remain available.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.inkMuted, fontSize: 12),
            ),
            if (monetization.privacyOptionsRequired)
              TextButton(
                onPressed: busy
                    ? null
                    : () => monetization.showPrivacyOptions(),
                child: const Text('Privacy choices'),
              ),
          ] else if (!monetization.rewardedAdReady && !busy) ...[
            const SizedBox(height: 10),
            TextButton.icon(
              key: const Key('retry_rewarded_ad'),
              onPressed: _retryAd,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try loading again'),
            ),
          ],
        ],
      ),
    );
  }
}
