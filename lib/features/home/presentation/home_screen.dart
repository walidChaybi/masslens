import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../app/app_controller.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_components.dart';
import '../../../l10n/l10n.dart';
import '../../../l10n/display_labels.dart';
import '../../measurements/domain/measurement.dart';
import '../../measurements/presentation/measurement_detail_screen.dart';
import '../../monetization/presentation/access_card.dart';
import '../../monetization/presentation/native_ad_card.dart';
import '../../monetization/presentation/rewarded_scan_sheet.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    required this.onMeasure,
    required this.onGallery,
    required this.onViewHistory,
    this.onOpenNutrition = _noop,
    super.key,
  });

  final ValueChanged<ScanMode> onMeasure;
  final ValueChanged<ScanMode> onGallery;
  final VoidCallback onViewHistory;
  final VoidCallback onOpenNutrition;

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final l10n = context.l10n;
    final access = controller.monetization.access;
    final recent = controller.measurements.firstOrNull;
    final horizontalPadding = math.max(
      20.0,
      (MediaQuery.sizeOf(context).width - 720) / 2,
    );

    final canEarnReward = access.adsEnabled && access.canEarnReward;
    return SafeArea(
      maintainBottomViewPadding: true,
      child: ListView(
        padding: EdgeInsets.fromLTRB(
          horizontalPadding,
          28,
          horizontalPadding,
          32,
        ),
        children: [
          _HomeHeader(
            title: l10n.homeAiWeight,
            scanLabel: canEarnReward && access.isAuthoritative
                ? l10n.homeScansLeftGetOne(access.remainingScans)
                : localizedScanUsage(l10n, access),
            canEarnReward: canEarnReward,
            onTap: () => showRewardedScanSheet(context),
          ),
          const SizedBox(height: 24),
          _HomeCapturePanel(onMeasure: onMeasure, onGallery: onGallery),
          const SizedBox(height: 14),
          _NutritionEntryCard(onTap: onOpenNutrition),
          if (recent != null) ...[
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.homeLatestEstimate,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                TextButton(
                  onPressed: onViewHistory,
                  child: Text(l10n.homeHistory),
                ),
              ],
            ),
            const SizedBox(height: 10),
            MeasurementCard(
              measurement: recent,
              unitSystem: controller.unitSystem,
              compact: true,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => MeasurementDetailScreen(measurement: recent),
                ),
              ),
            ),
          ],
          const SizedBox(height: 14),
          NativeAdCard(
            enabled: controller.monetization.canRequestNativeAds,
            placement: 'ai_home',
            height: 100,
            onPaidEvent: controller.monetization.reportPaidAd,
          ),
          const SizedBox(height: 12),
          AccessCard(
            access: access,
            rewardedAdReady: controller.monetization.rewardedAdReady,
            onManage: () => showRewardedScanSheet(context),
            onRewardedAd: () => showRewardedScanSheet(context),
          ),
        ],
      ),
    );
  }
}

void _noop() {}

class _NutritionEntryCard extends StatelessWidget {
  const _NutritionEntryCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final summary = AppScope.of(
      context,
    ).nutritionDiary.daySummary(DateTime.now());
    final l10n = context.l10n;
    return Card(
      key: const Key('home_nutrition_button'),
      color: AppColors.ink,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.lime,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.insights_rounded, color: AppColors.ink),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.nutritionHomeTitle,
                      style: Theme.of(
                        context,
                      ).textTheme.titleMedium?.copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      summary.hasEntries
                          ? l10n.nutritionHomeTodayCalories(
                              summary.totals.caloriesKcal.round(),
                            )
                          : l10n.nutritionHomeBody,
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_rounded, color: AppColors.lime),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({
    required this.title,
    required this.scanLabel,
    required this.canEarnReward,
    required this.onTap,
  });

  final String title;
  final String scanLabel;
  final bool canEarnReward;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final badge = InkWell(
          key: canEarnReward
              ? const Key('home_reward_cta')
              : const Key('home_scan_balance'),
          borderRadius: BorderRadius.circular(99),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: canEarnReward ? AppColors.lime : Colors.transparent,
              borderRadius: BorderRadius.circular(99),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (canEarnReward) ...[
                  const Icon(
                    Icons.play_arrow_rounded,
                    size: 16,
                    color: AppColors.ink,
                  ),
                  const SizedBox(width: 3),
                ],
                Flexible(
                  child: Text(
                    scanLabel,
                    key: const Key('scan_balance'),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                    style: TextStyle(
                      color: canEarnReward ? AppColors.ink : AppColors.inkMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
        final titleWidget = Text(
          title,
          style: Theme.of(context).textTheme.headlineLarge,
        );

        if (constraints.maxWidth < 380) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              titleWidget,
              const SizedBox(height: 10),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: math.min(260.0, constraints.maxWidth),
                  ),
                  child: badge,
                ),
              ),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: titleWidget),
            const SizedBox(width: 12),
            Flexible(child: badge),
          ],
        );
      },
    );
  }
}

class _HomeCapturePanel extends StatefulWidget {
  const _HomeCapturePanel({required this.onMeasure, required this.onGallery});

  final ValueChanged<ScanMode> onMeasure;
  final ValueChanged<ScanMode> onGallery;

  @override
  State<_HomeCapturePanel> createState() => _HomeCapturePanelState();
}

class _HomeCapturePanelState extends State<_HomeCapturePanel> {
  ScanMode _mode = ScanMode.object;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SegmentedButton<ScanMode>(
            key: const Key('home_scan_mode_selector'),
            expandedInsets: EdgeInsets.zero,
            segments: [
              ButtonSegment(
                value: ScanMode.object,
                label: Text(l10n.homeModeObject),
                icon: const Icon(Icons.inventory_2_outlined),
              ),
              ButtonSegment(
                value: ScanMode.foodPlate,
                label: Text(l10n.homeModeFoodMacros),
                icon: const Icon(Icons.restaurant_outlined),
              ),
            ],
            selected: {_mode},
            onSelectionChanged: (selection) {
              setState(() => _mode = selection.single);
            },
            showSelectedIcon: false,
          ),
          const SizedBox(height: 12),
          const AspectRatio(aspectRatio: 16 / 9, child: _QuietViewfinder()),
          if (_mode == ScanMode.foodPlate) ...[
            const SizedBox(height: 10),
            Text(
              l10n.homeFoodModeHint,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.inkMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 12),
          FilledButton.icon(
            key: const Key('home_scan_button'),
            onPressed: () => widget.onMeasure(_mode),
            icon: const Icon(Icons.photo_camera_outlined),
            label: Text(
              _mode == ScanMode.foodPlate
                  ? l10n.homeScanFood
                  : l10n.homeScanObject,
            ),
          ),
          const SizedBox(height: 4),
          TextButton.icon(
            key: const Key('home_gallery_button'),
            onPressed: () => widget.onGallery(_mode),
            icon: const Icon(Icons.photo_library_outlined),
            label: Text(l10n.homePhoto),
          ),
        ],
      ),
    );
  }
}

class _QuietViewfinder extends StatelessWidget {
  const _QuietViewfinder();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _QuietViewfinderPainter(),
      child: const SizedBox.expand(),
    );
  }
}

class _QuietViewfinderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(6)),
      Paint()..color = const Color(0xFFEFF4F3),
    );

    final gridPaint = Paint()
      ..color = AppColors.ink.withValues(alpha: 0.08)
      ..strokeWidth = 1;
    for (var i = 1; i < 3; i++) {
      final x = size.width * i / 3;
      final y = size.height * i / 3;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final cornerPaint = Paint()
      ..color = AppColors.ink
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    const inset = 16.0;
    const length = 28.0;
    for (final origin in [
      Offset(inset, inset),
      Offset(size.width - inset, inset),
      Offset(inset, size.height - inset),
      Offset(size.width - inset, size.height - inset),
    ]) {
      final xSign = origin.dx < size.width / 2 ? 1.0 : -1.0;
      final ySign = origin.dy < size.height / 2 ? 1.0 : -1.0;
      canvas.drawLine(origin, origin + Offset(length * xSign, 0), cornerPaint);
      canvas.drawLine(origin, origin + Offset(0, length * ySign), cornerPaint);
    }

    final center = size.center(Offset.zero);
    canvas.drawCircle(
      center,
      15,
      Paint()
        ..color = AppColors.surface
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      center,
      15,
      Paint()
        ..color = AppColors.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6,
    );
    canvas.drawCircle(center, 3, Paint()..color = AppColors.limeDark);
  }

  @override
  bool shouldRepaint(covariant _QuietViewfinderPainter oldDelegate) => false;
}
