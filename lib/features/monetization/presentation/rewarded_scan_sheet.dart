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
  bool _busy = false;

  Future<void> _watch() async {
    setState(() => _busy = true);
    final monetization = AppScope.of(context).monetization;
    final added = await monetization.watchAdForScan();
    if (!mounted) return;
    setState(() => _busy = false);
    if (added) {
      Navigator.of(context).pop(true);
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          monetization.message ?? 'The verified reward is still processing.',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final monetization = AppScope.of(context).monetization;
    final access = monetization.access;
    final canWatch =
        !_busy &&
        access.adsEnabled &&
        access.canEarnReward &&
        monetization.rewardedAdReady;
    return Padding(
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
            'Your reward is granted only after AdMob verifies it. No '
            'subscription, purchase, or fabricated result.',
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
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              key: const Key('watch_ad_for_scan'),
              onPressed: canWatch ? _watch : null,
              icon: _busy
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.play_circle_outline_rounded),
              label: Text(
                _busy
                    ? 'Confirming reward…'
                    : monetization.rewardedAdReady
                    ? 'Watch an ad · Get 1 scan'
                    : 'Rewarded ad is loading',
              ),
            ),
          ),
          if (!access.adsEnabled) ...[
            const SizedBox(height: 12),
            const Text(
              'Ads are unavailable because of consent, configuration, or '
              'inventory. Existing scans and non-AI features remain available.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.inkMuted, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
}
