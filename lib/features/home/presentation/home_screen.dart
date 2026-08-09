import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../app/app_controller.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_components.dart';
import '../../measurements/presentation/measurement_detail_screen.dart';
import '../../monetization/presentation/access_card.dart';
import '../../monetization/presentation/native_ad_card.dart';
import '../../monetization/presentation/rewarded_scan_sheet.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    required this.onMeasure,
    required this.onGallery,
    required this.onViewHistory,
    super.key,
  });

  final VoidCallback onMeasure;
  final VoidCallback onGallery;
  final VoidCallback onViewHistory;

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  'AI weight',
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
              ),
              InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => showRewardedScanSheet(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
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
                      Text(
                        canEarnReward && access.isAuthoritative
                            ? '${access.remainingScans} left · Get +1'
                            : access.usageLabel,
                        key: const Key('scan_balance'),
                        style: TextStyle(
                          color: canEarnReward
                              ? AppColors.ink
                              : AppColors.inkMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _HomeCapturePanel(onMeasure: onMeasure, onGallery: onGallery),
          if (recent != null) ...[
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Latest estimate',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                TextButton(
                  onPressed: onViewHistory,
                  child: const Text('History'),
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

class _HomeCapturePanel extends StatelessWidget {
  const _HomeCapturePanel({required this.onMeasure, required this.onGallery});

  final VoidCallback onMeasure;
  final VoidCallback onGallery;

  @override
  Widget build(BuildContext context) {
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
          const AspectRatio(aspectRatio: 16 / 9, child: _QuietViewfinder()),
          const SizedBox(height: 12),
          FilledButton.icon(
            key: const Key('home_scan_button'),
            onPressed: onMeasure,
            icon: const Icon(Icons.photo_camera_outlined),
            label: const Text('Scan object'),
          ),
          const SizedBox(height: 4),
          TextButton.icon(
            key: const Key('home_gallery_button'),
            onPressed: onGallery,
            icon: const Icon(Icons.photo_library_outlined),
            label: const Text('Photo'),
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
