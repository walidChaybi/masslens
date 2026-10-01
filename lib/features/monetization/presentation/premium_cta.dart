import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../l10n/l10n.dart';
import '../application/monetization_controller.dart';

const _premiumGold = Color(0xFFE8C36A);
const _premiumInk = Color(0xFF16101F);
const _premiumHighlight = Color(0xFF3A2A12);

class PremiumUpgradeButton extends StatelessWidget {
  const PremiumUpgradeButton({
    required this.onPressed,
    this.priceLabel = '',
    super.key,
  });

  final VoidCallback? onPressed;
  final String priceLabel;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final caption = priceLabel.trim().isEmpty
        ? l10n.paywallOneTimeCaption
        : '$priceLabel · ${l10n.paywallOneTimeCaption}';
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_premiumInk, _premiumHighlight],
            ),
            border: Border.all(color: _premiumGold, width: 1.4),
            boxShadow: [
              BoxShadow(
                color: _premiumGold.withValues(alpha: 0.32),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: _premiumGold,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.diamond_rounded,
                    color: _premiumInk,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.drawerUpgradeUnlimited,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        caption,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _premiumGold,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_rounded,
                  color: _premiumGold,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class WatchAdScanButton extends StatelessWidget {
  const WatchAdScanButton({required this.onPressed, super.key});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    // Painted by hand (not a themed FilledButton) so no global button style
    // can ever turn it into dark-text-on-dark-navy again.
    final enabled = onPressed != null;
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: Material(
        color: context.palette.surfaceElevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: context.palette.line),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 52),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 14, 8),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: context.palette.lime,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.play_arrow_rounded,
                      color: context.palette.onLime,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      context.l10n.rewardWatchForOne,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: context.palette.ink,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: context.palette.inkMuted,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class DrawerMonetizationFooter extends StatelessWidget {
  const DrawerMonetizationFooter({
    required this.monetization,
    required this.onUpgrade,
    required this.onWatchAd,
    super.key,
  });

  final MonetizationController monetization;
  final VoidCallback onUpgrade;
  final VoidCallback onWatchAd;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final access = monetization.access;
    if (access.hasLifetime) {
      return Container(
        key: const Key('drawer_unlimited_active'),
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: _premiumInk,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _premiumGold.withValues(alpha: 0.7)),
        ),
        child: Row(
          children: [
            const Icon(Icons.diamond_rounded, color: _premiumGold, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                l10n.accessLifetimeActive,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 13.5,
                ),
              ),
            ),
            const Icon(Icons.check_circle_rounded, color: _premiumGold),
          ],
        ),
      );
    }

    final showWatchAd = access.canEarnReward;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PremiumUpgradeButton(
          key: const Key('drawer_upgrade_unlimited'),
          onPressed: onUpgrade,
          priceLabel: monetization.lifetimePriceLabel,
        ),
        if (showWatchAd) ...[
          const SizedBox(height: 10),
          WatchAdScanButton(
            key: const Key('drawer_watch_ad'),
            onPressed: onWatchAd,
          ),
        ],
      ],
    );
  }
}
