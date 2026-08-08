import 'package:flutter/material.dart';

import '../../../app/app_controller.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_components.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _page = 0;

  static const _pages = [
    _OnboardingData(
      eyebrow: 'Visual estimation',
      title: 'Measure what\nyou cannot weigh.',
      description:
          'Capture an object and get a useful weight range, dimensions, and '
          'the assumptions behind the estimate.',
      icon: Icons.center_focus_strong_rounded,
    ),
    _OnboardingData(
      eyebrow: 'Honest by design',
      title: 'A range, not a\nmade-up exact number.',
      description:
          'MassLens shows confidence and uncertainty because a photograph is '
          'an estimate—not a physical scale.',
      icon: Icons.stacked_line_chart_rounded,
    ),
    _OnboardingData(
      eyebrow: 'Private first',
      title: 'Your objects stay\nyours.',
      description:
          'Photos are stripped of metadata and sent securely for real AI '
          'analysis. Saved history remains private on your device.',
      icon: Icons.lock_outline_rounded,
    ),
    _OnboardingData(
      eyebrow: 'Ads fund every scan',
      title: 'No subscription.\nNo scan packs.',
      description:
          'Your first AI scan is included. After that, one verified rewarded '
          'ad earns one real AI scan.',
      icon: Icons.play_circle_outline_rounded,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _advance() async {
    if (_page < _pages.length - 1) {
      await _pageController.nextPage(
        duration: const Duration(milliseconds: 360),
        curve: Curves.easeOutCubic,
      );
      return;
    }
    if (!mounted) return;
    await AppScope.of(context).completeOnboarding();
  }

  @override
  Widget build(BuildContext context) {
    final data = _pages[_page];
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 14, 22, 20),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const MassLensLogo(compact: true),
                  TextButton(
                    onPressed: () => AppScope.of(context).completeOnboarding(),
                    child: const Text('Skip'),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Expanded(
                child: PageView.builder(
                  key: const Key('onboarding_pages'),
                  controller: _pageController,
                  itemCount: _pages.length,
                  onPageChanged: (value) => setState(() => _page = value),
                  itemBuilder: (context, index) {
                    return _OnboardingPage(data: _pages[index], index: index);
                  },
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  for (var index = 0; index < _pages.length; index++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      width: index == _page ? 30 : 8,
                      height: 8,
                      margin: const EdgeInsets.only(right: 7),
                      decoration: BoxDecoration(
                        color: index == _page ? AppColors.ink : AppColors.line,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  const Spacer(),
                  FilledButton.icon(
                    key: const Key('onboarding_continue'),
                    onPressed: _advance,
                    icon: Icon(
                      _page == _pages.length - 1
                          ? Icons.check_rounded
                          : Icons.arrow_forward_rounded,
                    ),
                    iconAlignment: IconAlignment.end,
                    label: Text(
                      _page == _pages.length - 1
                          ? 'Start measuring'
                          : 'Continue',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: Text(
                  _page == 0
                      ? 'No account needed'
                      : data.eyebrow == 'Private first'
                      ? 'You control saved history'
                      : 'Designed for responsible estimates',
                  key: ValueKey(_page),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({required this.data, required this.index});

  final _OnboardingData data;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _OnboardingVisual(icon: data.icon, index: index),
        ),
        const SizedBox(height: 28),
        Eyebrow(data.eyebrow),
        const SizedBox(height: 12),
        Text(data.title, style: Theme.of(context).textTheme.displayMedium),
        const SizedBox(height: 14),
        Text(
          data.description,
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: AppColors.inkMuted),
        ),
      ],
    );
  }
}

class _OnboardingVisual extends StatelessWidget {
  const _OnboardingVisual({required this.icon, required this.index});

  final IconData icon;
  final int index;

  @override
  Widget build(BuildContext context) {
    final accent = switch (index) {
      1 => AppColors.aqua,
      2 => AppColors.lime,
      _ => AppColors.lime,
    };
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.ink,
        borderRadius: BorderRadius.circular(32),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(painter: const _TechnicalGridPainter()),
          ),
          Positioned(
            top: 24,
            right: 24,
            child: StatusPill(
              icon: index == 2 ? Icons.shield_outlined : Icons.bolt_rounded,
              label: index == 2 ? 'Private' : 'Instant',
              background: Colors.white.withValues(alpha: 0.12),
              foreground: Colors.white,
            ),
          ),
          Center(
            child: Container(
              width: 180,
              height: 220,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
                borderRadius: BorderRadius.circular(28),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(icon, color: accent, size: 76),
                  const Positioned.fill(
                    child: Padding(
                      padding: EdgeInsets.all(8),
                      child: InstrumentCorners(color: Colors.white),
                    ),
                  ),
                  Positioned(
                    bottom: 24,
                    left: 22,
                    right: 22,
                    child: Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      alignment: Alignment.centerLeft,
                      child: FractionallySizedBox(
                        widthFactor: index == 0
                            ? 0.74
                            : index == 1
                            ? 0.56
                            : 0.88,
                        child: Container(
                          decoration: BoxDecoration(
                            color: accent,
                            borderRadius: BorderRadius.circular(99),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 22,
            bottom: 22,
            child: Text(
              '0${index + 1} / 03',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TechnicalGridPainter extends CustomPainter {
  const _TechnicalGridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.055)
      ..strokeWidth = 1;
    for (var x = 0.0; x < size.width; x += 28) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), linePaint);
    }
    for (var y = 0.0; y < size.height; y += 28) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }
    final circlePaint = Paint()
      ..color = AppColors.lime.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.48),
      size.shortestSide * 0.38,
      circlePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _OnboardingData {
  const _OnboardingData({
    required this.eyebrow,
    required this.title,
    required this.description,
    required this.icon,
  });

  final String eyebrow;
  final String title;
  final String description;
  final IconData icon;
}
