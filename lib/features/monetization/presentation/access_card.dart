import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../l10n/l10n.dart';
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
    final l10n = context.l10n;
    final canEarn = access.adsEnabled && access.canEarnReward;
    final balanceText = access.isAuthoritative
        ? l10n.accessScansAvailable(access.remainingScans)
        : l10n.accessLoadingBalance;
    return Material(
      key: const Key('compact_access_card'),
      color: AppColors.ink,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onManage,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(
                  color: AppColors.lime,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.center_focus_strong_rounded,
                  color: AppColors.ink,
                  size: 20,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      balanceText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      access.isAuthoritative
                          ? l10n.accessBreakdown(
                              access.starterScansRemaining,
                              access.rewardedScans,
                              access.legacyScans,
                            )
                          : l10n.accessStarterThenAd,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 10.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (canEarn)
                FilledButton.icon(
                  key: const Key('access_watch_ad'),
                  onPressed: rewardedAdReady ? onRewardedAd : onManage,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 38),
                    padding: const EdgeInsets.symmetric(horizontal: 11),
                    backgroundColor: AppColors.lime,
                    foregroundColor: AppColors.ink,
                    textStyle: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  icon: const Icon(Icons.play_arrow_rounded, size: 18),
                  label: Text(l10n.accessGetOne),
                )
              else
                const Icon(Icons.chevron_right_rounded, color: Colors.white54),
            ],
          ),
        ),
      ),
    );
  }
}
