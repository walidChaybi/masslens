import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../domain/access_status.dart';

class AccessCard extends StatelessWidget {
  const AccessCard({
    required this.access,
    required this.onManage,
    required this.onRewardedAd,
    required this.rewardedAdReady,
    super.key,
  });

  final AccessStatus access;
  final VoidCallback onManage;
  final VoidCallback onRewardedAd;
  final bool rewardedAdReady;

  @override
  Widget build(BuildContext context) {
    final balanceCapacity = access.rewardBalanceCap + 1;
    final progress = (access.remainingScans / balanceCapacity).clamp(0.0, 1.0);
    final canEarn = access.adsEnabled && access.canEarnReward;
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: AppColors.ink,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: access.remainingScans > 0
                      ? AppColors.lime
                      : Colors.white12,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  access.remainingScans > 0 ? 'READY' : 'EARN A SCAN',
                  style: TextStyle(
                    color: access.remainingScans > 0
                        ? AppColors.ink
                        : Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: onManage,
                tooltip: 'How scan access works',
                color: AppColors.lime,
                icon: const Icon(Icons.info_outline_rounded),
              ),
            ],
          ),
          Text(
            access.usageLabel,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 21,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            access.breakdownLabel,
            style: const TextStyle(color: Colors.white60, fontSize: 11.5),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              minHeight: 7,
              value: progress,
              backgroundColor: Colors.white12,
              valueColor: const AlwaysStoppedAnimation(AppColors.lime),
            ),
          ),
          if (canEarn) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                key: const Key('access_watch_ad'),
                onPressed: rewardedAdReady ? onRewardedAd : onManage,
                icon: const Icon(Icons.play_circle_outline_rounded, size: 18),
                label: Text(
                  rewardedAdReady
                      ? 'Watch an ad · Get 1 scan'
                      : 'Rewarded ad is loading',
                ),
                style: TextButton.styleFrom(foregroundColor: AppColors.lime),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
