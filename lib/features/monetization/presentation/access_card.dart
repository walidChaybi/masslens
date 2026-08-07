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
    final progress = access.freeScanLimit <= 0
        ? 0.0
        : (access.freeScansUsed / access.freeScanLimit).clamp(0.0, 1.0);
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
                  color: access.hasPaidCredits
                      ? AppColors.lime
                      : Colors.white12,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  access.balanceName,
                  style: TextStyle(
                    color: access.hasPaidCredits ? AppColors.ink : Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: onManage,
                style: TextButton.styleFrom(foregroundColor: AppColors.lime),
                child: const Text('Buy scans'),
              ),
            ],
          ),
          Text(
            access.billingEnforced
                ? '${access.remainingScans} scans remaining'
                : 'Plans ready for setup',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 21,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              minHeight: 7,
              value: access.billingEnforced ? progress : 0,
              backgroundColor: Colors.white12,
              valueColor: const AlwaysStoppedAnimation(AppColors.lime),
            ),
          ),
          if (access.billingEnforced) ...[
            const SizedBox(height: 8),
            Text(
              '${access.freeScansRemaining} free · '
              '${access.bonusCredits} bonus · '
              '${access.purchasedCredits} purchased',
              style: const TextStyle(color: Colors.white60, fontSize: 11.5),
            ),
          ],
          if (!access.hasPaidCredits &&
              access.billingEnforced &&
              access.remainingScans <= 0) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Need one more scan?',
                    style: TextStyle(color: Colors.white70, fontSize: 12.5),
                  ),
                ),
                TextButton.icon(
                  onPressed: rewardedAdReady ? onRewardedAd : null,
                  icon: const Icon(Icons.play_circle_outline_rounded, size: 18),
                  label: Text(rewardedAdReady ? 'Watch ad' : 'Ad loading'),
                  style: TextButton.styleFrom(foregroundColor: AppColors.lime),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
