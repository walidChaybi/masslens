import 'package:flutter/material.dart';

import '../../../app/app_controller.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_components.dart';
import '../domain/access_status.dart';

Future<void> showMassLensPaywall(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: AppColors.canvas,
    builder: (_) =>
        const FractionallySizedBox(heightFactor: 0.94, child: _PaywallBody()),
  );
}

class _PaywallBody extends StatelessWidget {
  const _PaywallBody();

  @override
  Widget build(BuildContext context) {
    final monetization = AppScope.of(context).monetization;
    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
          children: [
            const Center(child: MassLensLogo(compact: true)),
            const SizedBox(height: 20),
            const Center(child: Eyebrow('One-time packs · no subscription')),
            const SizedBox(height: 8),
            Text(
              'Add scans when\nyou need them',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: 12),
            const Text(
              'Each pack is a single Google Play purchase with no renewal. '
              'Your OpenAI key is never inside the app.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.inkMuted, height: 1.45),
            ),
            const SizedBox(height: 22),
            if (!monetization.access.hasPaidCredits &&
                monetization.access.billingEnforced &&
                monetization.access.remainingScans <= 0) ...[
              _RewardedScanCard(
                ready: monetization.rewardedAdReady,
                onPressed: () async {
                  final added = await monetization.watchAdForScan();
                  if (!context.mounted) return;
                  if (added) {
                    Navigator.of(context).pop();
                    return;
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        monetization.message ??
                            'The reward is still processing.',
                      ),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              const Row(
                children: [
                  Expanded(child: Divider()),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'OR BUY A PACK',
                      style: TextStyle(
                        color: AppColors.inkMuted,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 16),
            ],
            for (final pack in monetization.packs) ...[
              _ScanPackCard(
                pack: pack,
                price: monetization.priceFor(pack.productId),
                enabled:
                    monetization.storeAvailable &&
                    monetization.priceFor(pack.productId) != null,
                onPressed: () => monetization.purchase(pack.productId),
              ),
              const SizedBox(height: 12),
            ],
            if (!monetization.access.billingEnforced)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.navySoft,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.build_circle_outlined, size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Billing preview is safe: scan limits remain disabled '
                        'until the Play products and Worker secret are ready.',
                        style: TextStyle(fontSize: 12.5, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
            if (monetization.message case final message?) ...[
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.coral,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const Text(
              'One-time purchase. No recurring charge. Purchased scans do not '
              'expire. Until account recovery is added, clearing app data or '
              'changing devices can prevent recovery of unused scans.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.inkMuted,
                fontSize: 11.5,
                height: 1.45,
              ),
            ),
          ],
        ),
        if (monetization.purchasePending)
          const ColoredBox(
            color: Color(0x66132238),
            child: Center(
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(22),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      ),
                      SizedBox(width: 14),
                      Text('Waiting for Google Play…'),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _RewardedScanCard extends StatelessWidget {
  const _RewardedScanCard({required this.ready, required this.onPressed});

  final bool ready;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: AppColors.navySoft,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          const Icon(Icons.play_circle_outline_rounded, size: 28),
          const SizedBox(width: 13),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Need one more scan?',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                SizedBox(height: 3),
                Text(
                  'Watch one ad to receive one bonus scan.',
                  style: TextStyle(color: AppColors.inkMuted, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          FilledButton(
            onPressed: ready ? onPressed : null,
            child: Text(ready ? 'Watch' : 'Loading'),
          ),
        ],
      ),
    );
  }
}

class _ScanPackCard extends StatelessWidget {
  const _ScanPackCard({
    required this.pack,
    required this.price,
    required this.enabled,
    required this.onPressed,
  });

  final ScanPackDefinition pack;
  final String? price;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: pack.recommended ? AppColors.ink : AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: pack.recommended ? AppColors.ink : AppColors.line,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 49,
            height: 49,
            decoration: BoxDecoration(
              color: pack.recommended ? AppColors.lime : AppColors.navySoft,
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.center,
            child: Text(
              '${pack.scanCredits}',
              style: const TextStyle(
                color: AppColors.ink,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        pack.name,
                        style: TextStyle(
                          color: pack.recommended
                              ? Colors.white
                              : AppColors.ink,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    if (pack.recommended) ...[
                      const SizedBox(width: 8),
                      const Text(
                        'BEST VALUE',
                        style: TextStyle(
                          color: AppColors.lime,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  '${pack.scanCredits} scans · ${pack.subtitle}',
                  style: TextStyle(
                    color: pack.recommended
                        ? Colors.white70
                        : AppColors.inkMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          FilledButton(
            onPressed: enabled ? onPressed : null,
            style: FilledButton.styleFrom(
              minimumSize: const Size(82, 46),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              backgroundColor: pack.recommended
                  ? AppColors.lime
                  : AppColors.ink,
              foregroundColor: pack.recommended ? AppColors.ink : Colors.white,
              disabledBackgroundColor: pack.recommended
                  ? AppColors.lime.withValues(alpha: 0.35)
                  : AppColors.navySoft,
            ),
            child: Text(price ?? 'Soon'),
          ),
        ],
      ),
    );
  }
}
