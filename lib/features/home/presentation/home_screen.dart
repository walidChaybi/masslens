import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../app/app_controller.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_components.dart';
import '../../../l10n/display_labels.dart';
import '../../../l10n/l10n.dart';
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

  final VoidCallback onMeasure;
  final VoidCallback onGallery;
  final VoidCallback onViewHistory;
  final VoidCallback onOpenNutrition;

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final l10n = context.l10n;
    final access = controller.monetization.access;
    final recent = controller.measurements
        .where((measurement) => !measurement.isFoodPlate)
        .firstOrNull;
    final horizontalPadding = math.max(
      20.0,
      (MediaQuery.sizeOf(context).width - 720) / 2,
    );

    final canEarnReward =
        !access.debugUnlimited && access.adsEnabled && access.canEarnReward;
    return SafeArea(
      maintainBottomViewPadding: true,
      child: ListView(
        padding: EdgeInsets.fromLTRB(
          horizontalPadding,
          6,
          horizontalPadding,
          32,
        ),
        children: [
          _ScanHero(
            scanLabel: access.debugUnlimited
                ? l10n.accessUnlimitedScans
                : localizedScanUsage(l10n, access),
            canEarnReward: canEarnReward,
            onBalanceTap: () => showRewardedScanSheet(context),
            onMeasure: onMeasure,
            onGallery: onGallery,
          ),
          if (recent != null) ...[
            const SizedBox(height: 26),
            Row(
              children: [
                Expanded(child: Eyebrow(l10n.homeLatestEstimate)),
                TextButton(
                  onPressed: onViewHistory,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(l10n.homeHistory),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_forward_rounded, size: 18),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
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
          const SizedBox(height: 16),
          NativeAdCard(
            enabled: controller.monetization.canRequestNativeAds,
            placement: 'ai_home',
            height: 120,
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

/// The whole "scan" story in one dark instrument panel: what it does, a
/// viewfinder with capture tips, and the two ways to start.
class _ScanHero extends StatelessWidget {
  const _ScanHero({
    required this.scanLabel,
    required this.canEarnReward,
    required this.onBalanceTap,
    required this.onMeasure,
    required this.onGallery,
  });

  final String scanLabel;
  final bool canEarnReward;
  final VoidCallback onBalanceTap;
  final VoidCallback onMeasure;
  final VoidCallback onGallery;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [context.palette.inkRaised, context.palette.inkDeep],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.22),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Eyebrow(
                    l10n.homeAiWeight,
                    color: context.palette.lime,
                  ),
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: _BalanceChip(
                    label: scanLabel,
                    highlighted: canEarnReward,
                    onTap: onBalanceTap,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              l10n.homeHeroTitle,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 27,
                height: 1.08,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.homeHeroBody,
              style: TextStyle(
                color: context.palette.onInkMuted,
                fontSize: 13.5,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 176,
              child: _Viewfinder(
                tips: [
                  (Icons.crop_free_rounded, l10n.homeTipWhole),
                  (Icons.wb_sunny_outlined, l10n.homeTipLight),
                  (Icons.straighten_rounded, l10n.homeTipReference),
                ],
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              key: const Key('home_scan_button'),
              onPressed: onMeasure,
              style: FilledButton.styleFrom(
                backgroundColor: context.palette.lime,
                foregroundColor: context.palette.onLime,
                minimumSize: const Size.fromHeight(56),
                shape: const StadiumBorder(),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              icon: const Icon(Icons.photo_camera_rounded),
              label: Text(l10n.homeScanObject),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              key: const Key('home_gallery_button'),
              onPressed: onGallery,
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(48),
                shape: StadiumBorder(
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.22)),
                ),
                textStyle: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              icon: const Icon(Icons.photo_library_outlined, size: 20),
              label: Text(l10n.homePhoto),
            ),
          ],
        ),
      ),
    );
  }
}

class _BalanceChip extends StatelessWidget {
  const _BalanceChip({
    required this.label,
    required this.highlighted,
    required this.onTap,
  });

  final String label;
  final bool highlighted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = highlighted ? context.palette.onLime : Colors.white;
    return Material(
      color: highlighted
          ? context.palette.lime
          : Colors.white.withValues(alpha: 0.10),
      shape: const StadiumBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: highlighted
            ? const Key('home_reward_cta')
            : const Key('home_scan_balance'),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 7, 12, 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                highlighted ? Icons.play_arrow_rounded : Icons.bolt_rounded,
                size: 16,
                color: highlighted
                    ? context.palette.onLime
                    : context.palette.lime,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  key: const Key('scan_balance'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: foreground,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Viewfinder extends StatelessWidget {
  const _Viewfinder({required this.tips});

  final List<(IconData, String)> tips;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _ViewfinderPainter())),
          Positioned.fill(
            child: InstrumentCorners(
              color: context.palette.lime.withValues(alpha: 0.9),
            ),
          ),
          Positioned(
            left: 12,
            right: 12,
            bottom: 12,
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final tip in tips) _TipChip(icon: tip.$1, label: tip.$2),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TipChip extends StatelessWidget {
  const _TipChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 5, 10, 5),
      decoration: BoxDecoration(
        color: context.palette.inkDeep.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: context.palette.lime),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ViewfinderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(0, -0.2),
          radius: 0.9,
          colors: [Color(0xFF22385A), Color(0xFF0A1322)],
        ).createShader(rect),
    );

    // Faint measuring grid.
    final grid = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..strokeWidth = 1;
    const step = 22.0;
    for (var x = step; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }
    for (var y = step; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    // Static scan beam with a soft trailing glow.
    final beamY = size.height * 0.40;
    final glowRect = Rect.fromLTRB(28, beamY - 34, size.width - 28, beamY);
    canvas.drawRect(
      glowRect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.lime.withValues(alpha: 0),
            AppColors.lime.withValues(alpha: 0.16),
          ],
        ).createShader(glowRect),
    );
    final beamRect = Rect.fromLTRB(28, beamY - 1, size.width - 28, beamY + 1);
    canvas.drawRect(
      beamRect,
      Paint()
        ..shader = LinearGradient(
          colors: [
            AppColors.lime.withValues(alpha: 0),
            AppColors.lime,
            AppColors.lime.withValues(alpha: 0),
          ],
        ).createShader(beamRect),
    );

    // Reticle.
    final center = Offset(size.width / 2, beamY);
    canvas.drawCircle(
      center,
      17,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.75)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    canvas.drawCircle(center, 3.5, Paint()..color = AppColors.lime);
    final tick = Paint()
      ..color = Colors.white.withValues(alpha: 0.75)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(center.translate(0, -25), center.translate(0, -20), tick);
    canvas.drawLine(center.translate(0, 20), center.translate(0, 25), tick);
    canvas.drawLine(center.translate(-25, 0), center.translate(-20, 0), tick);
    canvas.drawLine(center.translate(20, 0), center.translate(25, 0), tick);
  }

  @override
  bool shouldRepaint(covariant _ViewfinderPainter oldDelegate) => false;
}
