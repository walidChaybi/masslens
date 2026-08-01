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
            const Center(child: Eyebrow('More scans · no ads')),
            const SizedBox(height: 8),
            Text(
              'Choose the plan that\nfits your projects',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: 12),
            const Text(
              'Every plan is verified securely by Google Play. '
              'Your OpenAI key is never inside the app.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.inkMuted, height: 1.45),
            ),
            const SizedBox(height: 22),
            for (final plan in monetization.plans) ...[
              _PlanCard(
                plan: plan,
                price: monetization.priceFor(plan.productId),
                selected: monetization.access.planId == plan.productId,
                enabled:
                    monetization.storeAvailable &&
                    monetization.priceFor(plan.productId) != null,
                onPressed: () => monetization.purchase(plan.productId),
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
            const SizedBox(height: 12),
            TextButton(
              onPressed: monetization.loading
                  ? null
                  : monetization.restorePurchases,
              child: const Text('Restore purchases'),
            ),
            const Text(
              'Subscriptions renew automatically through Google Play unless '
              'canceled. Scan allowance resets each billing period. Max is '
              'capped at 300 scans/month to keep the service reliable.',
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

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.plan,
    required this.price,
    required this.selected,
    required this.enabled,
    required this.onPressed,
  });

  final PlanDefinition plan;
  final String? price;
  final bool selected;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: plan.recommended ? AppColors.ink : AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: plan.recommended ? AppColors.ink : AppColors.line,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 49,
            height: 49,
            decoration: BoxDecoration(
              color: plan.recommended ? AppColors.lime : AppColors.navySoft,
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.center,
            child: Text(
              '${plan.scanLimit}',
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
                        plan.name,
                        style: TextStyle(
                          color: plan.recommended
                              ? Colors.white
                              : AppColors.ink,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    if (plan.recommended) ...[
                      const SizedBox(width: 8),
                      const Text(
                        'POPULAR',
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
                  '${plan.scanLimit} scans/month · ${plan.subtitle}',
                  style: TextStyle(
                    color: plan.recommended
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
            onPressed: selected || !enabled ? null : onPressed,
            style: FilledButton.styleFrom(
              minimumSize: const Size(82, 46),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              backgroundColor: plan.recommended
                  ? AppColors.lime
                  : AppColors.ink,
              foregroundColor: plan.recommended ? AppColors.ink : Colors.white,
              disabledBackgroundColor: plan.recommended
                  ? AppColors.lime.withValues(alpha: 0.35)
                  : AppColors.navySoft,
            ),
            child: Text(selected ? 'Active' : price ?? 'Soon'),
          ),
        ],
      ),
    );
  }
}
