import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_components.dart';
import '../../../l10n/l10n.dart';

class GuideScreen extends StatelessWidget {
  const GuideScreen({required this.onScan, super.key});

  final VoidCallback onScan;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          Eyebrow(l10n.guideEyebrow),
          const SizedBox(height: 8),
          Text(
            l10n.guideTitle,
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          const SizedBox(height: 8),
          Text(
            l10n.guideIntro,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: AppColors.inkMuted),
          ),
          const SizedBox(height: 24),
          const _GuideHero(),
          const SizedBox(height: 22),
          _GuideStep(
            number: '01',
            icon: Icons.center_focus_strong_rounded,
            title: l10n.guideWholeObjectTitle,
            message: l10n.guideWholeObjectBody,
            accent: AppColors.lime,
          ),
          const SizedBox(height: 12),
          _GuideStep(
            number: '02',
            icon: Icons.wb_sunny_outlined,
            title: l10n.guideLightingTitle,
            message: l10n.guideLightingBody,
            accent: AppColors.aqua,
          ),
          const SizedBox(height: 12),
          _GuideStep(
            number: '03',
            icon: Icons.layers_outlined,
            title: l10n.guideStructureTitle,
            message: l10n.guideStructureBody,
            accent: Color(0xFFFFD36A),
          ),
          const SizedBox(height: 12),
          _GuideStep(
            number: '04',
            icon: Icons.add_photo_alternate_outlined,
            title: l10n.guideSideViewTitle,
            message: l10n.guideSideViewBody,
            accent: AppColors.navySoft,
          ),
          const SizedBox(height: 28),
          Text(
            l10n.guideUnderstandingConfidence,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          const _ConfidenceGuide(),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: onScan,
            icon: const Icon(Icons.photo_camera_outlined),
            label: Text(l10n.guideTryCapture),
          ),
        ],
      ),
    );
  }
}

class _GuideHero extends StatelessWidget {
  const _GuideHero();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      height: 226,
      decoration: BoxDecoration(
        color: AppColors.ink,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Positioned.fill(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: InstrumentCorners(),
            ),
          ),
          Container(
            width: 112,
            height: 142,
            decoration: BoxDecoration(
              color: AppColors.aqua.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.aqua),
            ),
            child: const Icon(
              Icons.chair_alt_outlined,
              color: AppColors.aqua,
              size: 66,
            ),
          ),
          Positioned(
            top: 20,
            child: StatusPill(
              label: l10n.guideClearSubject,
              icon: Icons.check_rounded,
              background: AppColors.lime,
            ),
          ),
          Positioned(
            bottom: 18,
            child: Text(
              l10n.guideAllEdgesVisible,
              style: const TextStyle(
                color: Colors.white60,
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GuideStep extends StatelessWidget {
  const _GuideStep({
    required this.number,
    required this.icon,
    required this.title,
    required this.message,
    required this.accent,
  });

  final String number;
  final IconData icon;
  final String title;
  final String message;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(17),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: accent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: AppColors.ink),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      Text(
                        number,
                        style: const TextStyle(
                          color: AppColors.inkMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(message, style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConfidenceGuide extends StatelessWidget {
  const _ConfidenceGuide();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        children: [
          _ConfidenceRow(
            color: AppColors.coral,
            label: l10n.confidenceLow,
            detail: l10n.guideLowDetail,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Divider(),
          ),
          _ConfidenceRow(
            color: AppColors.limeDark,
            label: l10n.confidenceMedium,
            detail: l10n.guideMediumDetail,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Divider(),
          ),
          _ConfidenceRow(
            color: const Color(0xFF168B78),
            label: l10n.confidenceHigh,
            detail: l10n.guideHighDetail,
          ),
        ],
      ),
    );
  }
}

class _ConfidenceRow extends StatelessWidget {
  const _ConfidenceRow({
    required this.color,
    required this.label,
    required this.detail,
  });

  final Color color;
  final String label;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 58,
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.ink,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Expanded(
          child: Text(
            detail,
            style: const TextStyle(color: AppColors.inkMuted, fontSize: 12),
          ),
        ),
      ],
    );
  }
}
