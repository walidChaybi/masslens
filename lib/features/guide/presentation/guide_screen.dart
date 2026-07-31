import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_components.dart';

class GuideScreen extends StatelessWidget {
  const GuideScreen({required this.onScan, super.key});

  final VoidCallback onScan;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          const Eyebrow('Better input, better range'),
          const SizedBox(height: 8),
          Text(
            'Capture guide',
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Four simple choices make a visual estimate more useful.',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: AppColors.inkMuted),
          ),
          const SizedBox(height: 24),
          const _GuideHero(),
          const SizedBox(height: 22),
          const _GuideStep(
            number: '01',
            icon: Icons.center_focus_strong_rounded,
            title: 'Show the whole object',
            message:
                'Leave space around every edge. Avoid hands, labels, or other '
                'objects overlapping the target.',
            accent: AppColors.lime,
          ),
          const SizedBox(height: 12),
          const _GuideStep(
            number: '02',
            icon: Icons.wb_sunny_outlined,
            title: 'Use soft, even light',
            message:
                'Strong shadows hide shape. Bright daylight or a well-lit room '
                'usually gives the cleanest visual evidence.',
            accent: AppColors.aqua,
          ),
          const SizedBox(height: 12),
          const _GuideStep(
            number: '03',
            icon: Icons.layers_outlined,
            title: 'Tell us solid or hollow',
            message:
                'A suitcase and a block can occupy the same volume but weigh '
                'very differently. Structure narrows the density assumption.',
            accent: Color(0xFFFFD36A),
          ),
          const SizedBox(height: 12),
          const _GuideStep(
            number: '04',
            icon: Icons.credit_card_rounded,
            title: 'Add scale in phase two',
            message:
                'The production guided scan will use AR depth or a known-size '
                'reference to estimate physical dimensions.',
            accent: AppColors.navySoft,
          ),
          const SizedBox(height: 28),
          Text(
            'Understanding confidence',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          const _ConfidenceGuide(),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: onScan,
            icon: const Icon(Icons.photo_camera_outlined),
            label: const Text('Try a guided capture'),
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
          const Positioned(
            top: 20,
            child: StatusPill(
              label: 'Clear subject',
              icon: Icons.check_rounded,
              background: AppColors.lime,
            ),
          ),
          const Positioned(
            bottom: 18,
            child: Text(
              'ALL EDGES VISIBLE  •  SINGLE OBJECT',
              style: TextStyle(
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
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.line),
      ),
      child: const Column(
        children: [
          _ConfidenceRow(
            color: AppColors.coral,
            label: 'Low',
            detail: 'One photo, inferred scale or category',
          ),
          Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Divider(),
          ),
          _ConfidenceRow(
            color: AppColors.limeDark,
            label: 'Medium',
            detail: 'Category plus structure confirmed',
          ),
          Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Divider(),
          ),
          _ConfidenceRow(
            color: Color(0xFF168B78),
            label: 'High',
            detail: 'Future AR scan plus validated geometry',
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
