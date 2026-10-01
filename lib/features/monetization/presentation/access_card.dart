import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../l10n/display_labels.dart';
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
    final unlimited = access.hasLifetime || access.debugUnlimited;
    final canEarn = !unlimited && access.canEarnReward;
    final balance = Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: context.palette.lime,
            shape: BoxShape.circle,
          ),
          child: Icon(
            unlimited
                ? Icons.all_inclusive_rounded
                : Icons.center_focus_strong_rounded,
            color: context.palette.onLime,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            localizedScanUsage(l10n, access),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        if (unlimited)
          Icon(Icons.check_circle_rounded, color: context.palette.lime),
      ],
    );
    final action = FilledButton.icon(
      key: const Key('access_watch_ad'),
      onPressed: rewardedAdReady ? onRewardedAd : onManage,
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 44),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        backgroundColor: context.palette.lime,
        foregroundColor: context.palette.onLime,
        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
      ),
      icon: const Icon(Icons.play_arrow_rounded, size: 18),
      label: Text(l10n.accessGetFreeScan),
    );
    return Material(
      key: const Key('compact_access_card'),
      color: context.palette.inkRaised,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onManage,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final stack =
                  constraints.maxWidth < 300 ||
                  MediaQuery.textScalerOf(context).scale(12) > 15;
              if (canEarn && stack) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [balance, const SizedBox(height: 12), action],
                );
              }
              return Row(
                children: [
                  Expanded(child: balance),
                  if (canEarn) ...[const SizedBox(width: 12), action],
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
