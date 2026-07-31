import 'package:flutter/material.dart';

import '../../../app/app_controller.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_components.dart';
import '../../measurements/presentation/measurement_detail_screen.dart';
import '../../scan/data/estimate_repository_factory.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    required this.onScan,
    required this.onViewHistory,
    super.key,
  });

  final VoidCallback onScan;
  final VoidCallback onViewHistory;

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final recent = controller.measurements.take(2).toList();

    return SafeArea(
      bottom: false,
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
            sliver: SliverList.list(
              children: [
                Row(
                  children: [
                    const MassLensLogo(compact: true),
                    const Spacer(),
                    StatusPill(
                      label: EstimateEngineConfig.analysisModeLabel,
                      icon: EstimateEngineConfig.isAiEnabled
                          ? Icons.auto_awesome_outlined
                          : Icons.science_outlined,
                      background: AppColors.navySoft,
                    ),
                    const SizedBox(width: 8),
                    IconButton.filledTonal(
                      tooltip: 'Measurement guide',
                      onPressed: () => _showAccuracySheet(context),
                      icon: const Icon(Icons.info_outline_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                const Eyebrow('AI-assisted measurement'),
                const SizedBox(height: 9),
                Text(
                  'What are we\nmeasuring today?',
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                const SizedBox(height: 22),
                _ScanHero(onScan: onScan),
                const SizedBox(height: 28),
                const SectionTitle(title: 'Choose a mode'),
                const SizedBox(height: 13),
                SizedBox(
                  height: 174,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    clipBehavior: Clip.none,
                    children: [
                      _ModeCard(
                        icon: Icons.photo_camera_outlined,
                        title: 'Photo estimate',
                        subtitle: 'Available now',
                        accent: AppColors.lime,
                        onTap: onScan,
                      ),
                      const SizedBox(width: 12),
                      const _ModeCard(
                        icon: Icons.view_in_ar_outlined,
                        title: 'Guided scan',
                        subtitle: 'AR · Coming next',
                        accent: AppColors.aqua,
                      ),
                      const SizedBox(width: 12),
                      const _ModeCard(
                        icon: Icons.straighten_rounded,
                        title: 'Smart ruler',
                        subtitle: 'AR · Coming next',
                        accent: Color(0xFFFFD36A),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                SectionTitle(
                  title: 'Recent estimates',
                  actionLabel: recent.isEmpty ? null : 'View all',
                  onAction: onViewHistory,
                ),
                const SizedBox(height: 13),
                if (recent.isEmpty)
                  EmptyPanel(
                    icon: Icons.history_rounded,
                    title: 'Your workbench is clear',
                    message:
                        'Your saved estimates will appear here, ready to '
                        'compare or revisit.',
                    action: OutlinedButton.icon(
                      onPressed: onScan,
                      icon: const Icon(Icons.add_a_photo_outlined),
                      label: const Text('Make first estimate'),
                    ),
                  )
                else
                  for (final measurement in recent) ...[
                    MeasurementCard(
                      measurement: measurement,
                      unitSystem: controller.unitSystem,
                      compact: true,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) =>
                              MeasurementDetailScreen(measurement: measurement),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                const SizedBox(height: 28),
                const _TrustCard(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAccuracySheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      builder: (context) => const SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(24, 4, 24, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Eyebrow('Accuracy note'),
              SizedBox(height: 10),
              Text(
                'A camera estimates. A scale measures.',
                style: TextStyle(
                  color: AppColors.ink,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.7,
                ),
              ),
              SizedBox(height: 13),
              Text(
                'One photo cannot reveal hidden contents or exact density. '
                'MassLens reports a range and confidence level instead of '
                'pretending the result is physically exact.',
                style: TextStyle(
                  color: AppColors.inkMuted,
                  fontSize: 15,
                  height: 1.5,
                ),
              ),
              SizedBox(height: 18),
              _InfoRow(
                icon: Icons.wb_sunny_outlined,
                text: 'Use bright, even light and a simple background.',
              ),
              SizedBox(height: 12),
              _InfoRow(
                icon: Icons.crop_free_rounded,
                text: 'Keep the complete object visible in the frame.',
              ),
              SizedBox(height: 12),
              _InfoRow(
                icon: Icons.category_outlined,
                text: 'Confirm category and structure to narrow the range.',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScanHero extends StatelessWidget {
  const _ScanHero({required this.onScan});

  final VoidCallback onScan;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 294,
      decoration: BoxDecoration(
        color: AppColors.ink,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.14),
            blurRadius: 30,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: const _HeroPainter())),
          const Positioned(
            top: 22,
            left: 22,
            child: StatusPill(
              label: 'Quick estimate',
              icon: Icons.bolt_rounded,
              background: AppColors.lime,
            ),
          ),
          Positioned(
            top: 72,
            left: 22,
            right: 22,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Point. Capture.\nUnderstand.',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 30,
                          height: 1.03,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1,
                        ),
                      ),
                      SizedBox(height: 11),
                      Text(
                        'Get a weight range and\nconfidence in a few taps.',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 94,
                  height: 94,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 62,
                        height: 62,
                        decoration: const BoxDecoration(
                          color: AppColors.aqua,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.inventory_2_outlined,
                          color: AppColors.ink,
                          size: 28,
                        ),
                      ),
                      const Positioned(
                        right: 0,
                        top: 8,
                        child: StatusPill(
                          label: '±',
                          background: AppColors.lime,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 18,
            right: 18,
            bottom: 18,
            child: FilledButton.icon(
              key: const Key('home_scan_button'),
              onPressed: onScan,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.ink,
              ),
              icon: const Icon(Icons.center_focus_strong_rounded),
              label: const Text('Start a photo estimate'),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroPainter extends CustomPainter {
  const _HeroPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.055)
      ..strokeWidth = 1;
    for (var x = -size.height; x < size.width; x += 34) {
      canvas.drawLine(
        Offset(x, size.height),
        Offset(x + size.height, 0),
        linePaint,
      );
    }
    final glowPaint = Paint()
      ..shader =
          RadialGradient(
            colors: [
              AppColors.aqua.withValues(alpha: 0.3),
              AppColors.aqua.withValues(alpha: 0),
            ],
          ).createShader(
            Rect.fromCircle(
              center: Offset(size.width * 0.86, size.height * 0.42),
              radius: 130,
            ),
          );
    canvas.drawCircle(
      Offset(size.width * 0.86, size.height * 0.42),
      130,
      glowPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 154,
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: AppColors.ink),
                ),
                const Spacer(),
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontSize: 11),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TrustCard extends StatelessWidget {
  const _TrustCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.lime.withValues(alpha: 0.34),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.limeDark.withValues(alpha: 0.18)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.verified_user_outlined, color: AppColors.ink),
          SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Built for useful estimates',
                  style: TextStyle(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'MassLens always shows uncertainty. Never use estimates for '
                  'medical dosing, safety limits, or regulated shipping.',
                  style: TextStyle(
                    color: AppColors.ink,
                    height: 1.45,
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColors.limeDark),
        const SizedBox(width: 12),
        Expanded(child: Text(text)),
      ],
    );
  }
}
