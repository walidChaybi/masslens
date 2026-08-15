import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../app/app_controller.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/l10n.dart';
import '../../monetization/data/app_ad_service.dart';
import '../../monetization/presentation/native_ad_card.dart';

const _onboardingCanvas = Color(0xFFF7F8FC);
const _onboardingInk = Color(0xFF090B10);
const _heroAsset = 'assets/onboarding/masslens_hero.webp';
const _mugAsset = 'assets/onboarding/teal_mug.webp';
const _balanceAsset = 'assets/onboarding/balance.webp';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  late final AnimationController _particleController;

  int _page = 0;
  int _preparationRun = 0;
  bool _assetsPrecached = false;
  bool _reduceMotion = false;
  bool _preparing = false;
  bool _preparationComplete = false;
  bool _scanAccessFinished = false;
  bool _scanAccessReady = false;
  bool _adSupportFinished = false;
  bool _adSupportReady = false;
  bool _completionBusy = false;

  @override
  void initState() {
    super.initState();
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4200),
    )..repeat();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.of(context).disableAnimations;
    if (_reduceMotion) {
      _particleController.stop();
      _particleController.value = 0.42;
    } else if (_page == 3 && !_particleController.isAnimating) {
      _particleController.repeat();
    } else if (_page != 3) {
      _particleController.stop();
    }
    if (!_assetsPrecached) {
      _assetsPrecached = true;
      unawaited(precacheImage(const AssetImage(_heroAsset), context));
      unawaited(precacheImage(const AssetImage(_mugAsset), context));
      unawaited(precacheImage(const AssetImage(_balanceAsset), context));
    }
  }

  @override
  void dispose() {
    _preparationRun += 1;
    _pageController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  Future<void> _showPage(int page) async {
    if (!mounted || !_pageController.hasClients) return;
    await _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _advance() async {
    if (_completionBusy || _preparing) return;
    if (_page < 3) {
      await _showPage(_page + 1);
      return;
    }
    if (_page == 4) {
      await _finishOnboarding();
    }
  }

  Future<void> _finishOnboarding() async {
    if (_completionBusy || !mounted) return;
    setState(() => _completionBusy = true);
    final controller = AppScope.of(context);
    // The explicit "let's go" tap is the transition into the app, which is
    // where the single onboarding interstitial belongs. A missing ad never
    // blocks entry.
    await controller.monetization.showOnboardingCompletionInterstitial();
    if (!mounted) return;
    if (!controller.onboardingReviewPromptHandled) {
      final requestReview = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => const _OnboardingReviewDialog(),
      );
      if (!mounted) return;
      await controller.handleOnboardingReview(
        requestReview: requestReview ?? false,
      );
    }
    if (mounted) await controller.completeOnboarding();
  }

  void _handlePageChanged(int page) {
    setState(() => _page = page);
    if (page == 3) {
      if (!_reduceMotion && !_particleController.isAnimating) {
        _particleController.repeat();
      }
      unawaited(_prepareExperience());
    } else {
      _particleController.stop();
    }
  }

  Future<void> _prepareExperience() async {
    if (_preparationComplete) {
      await Future<void>.delayed(const Duration(milliseconds: 250));
      if (mounted && _page == 3) await _showPage(4);
      return;
    }
    if (_preparing) return;
    final run = ++_preparationRun;
    setState(() {
      _preparing = true;
      _scanAccessFinished = false;
      _scanAccessReady = false;
      _adSupportFinished = false;
      _adSupportReady = false;
    });

    final minimumDisplay = Future<void>.delayed(
      const Duration(milliseconds: 1200),
    );
    final controller = AppScope.of(context);
    try {
      await controller.initializeMonetization();
    } on Object {
      // The status rows below reflect whatever state initialization reached.
    }

    if (!mounted || run != _preparationRun) return;
    setState(() {
      _scanAccessFinished = true;
      _scanAccessReady = controller.monetization.access.isAuthoritative;
      _adSupportFinished = true;
      _adSupportReady = controller.monetization.canRequestAds;
    });
    await minimumDisplay;
    if (!mounted || run != _preparationRun || _page != 3) return;
    setState(() {
      _preparing = false;
      _preparationComplete = true;
    });
    await _showPage(4);
  }

  Future<void> _goBack() async {
    if (_page == 0 || _completionBusy) return;
    if (_page == 3) {
      _preparationRun += 1;
      setState(() => _preparing = false);
    }
    await _showPage(_page == 4 ? 2 : _page - 1);
  }

  @override
  Widget build(BuildContext context) {
    final monetization = AppScope.of(context).monetization;
    final adsEnabled = monetization.canRequestNativeAds;
    final PaidAdReporter reportPaidAd = monetization.reportPaidAd;
    return PopScope<void>(
      canPop: _page == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) unawaited(_goBack());
      },
      child: Scaffold(
        backgroundColor: _onboardingCanvas,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: PageView(
                key: const Key('onboarding_pages'),
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: _handlePageChanged,
                children: [
                  _ContentPage(
                    key: const Key('onboarding_page_1'),
                    step: 1,
                    title: context.l10n.onboardingHeroTitle,
                    body: context.l10n.onboardingHeroBody,
                    action: context.l10n.onboardingHeroCta,
                    visual: const _HeroVisual(),
                    onPressed: _advance,
                    adEnabled: adsEnabled,
                    adPlacement: 'onboarding_intro',
                    onAdPaidEvent: reportPaidAd,
                  ),
                  _ContentPage(
                    key: const Key('onboarding_page_2'),
                    step: 2,
                    title: context.l10n.onboardingFramingTitle,
                    body: context.l10n.onboardingFramingBody,
                    action: context.l10n.onboardingFramingCta,
                    visual: const _FramingVisual(),
                    onPressed: _advance,
                    adEnabled: adsEnabled,
                    adPlacement: 'onboarding_framing',
                    onAdPaidEvent: reportPaidAd,
                  ),
                  _ContentPage(
                    key: const Key('onboarding_page_3'),
                    step: 3,
                    title: context.l10n.onboardingLightTitle,
                    body: context.l10n.onboardingLightBody,
                    action: context.l10n.onboardingLightCta,
                    visual: const _LightingVisual(),
                    onPressed: _advance,
                    adEnabled: adsEnabled,
                    adPlacement: 'onboarding_light',
                    onAdPaidEvent: reportPaidAd,
                  ),
                  _PreparingPage(
                    key: const Key('onboarding_page_4'),
                    animation: _particleController,
                    scanFinished: _scanAccessFinished,
                    scanReady: _scanAccessReady,
                    adFinished: _adSupportFinished,
                    adReady: _adSupportReady,
                  ),
                  _ContentPage(
                    key: const Key('onboarding_page_5'),
                    step: 5,
                    title: context.l10n.onboardingReadyTitle,
                    body: context.l10n.onboardingReadyBody,
                    action: context.l10n.onboardingReadyCta,
                    visual: const _ReadyVisual(),
                    onPressed: _completionBusy ? null : _advance,
                    actionBusy: _completionBusy,
                    adEnabled: adsEnabled,
                    adPlacement: 'onboarding_ready',
                    onAdPaidEvent: reportPaidAd,
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

class _ContentPage extends StatelessWidget {
  const _ContentPage({
    required this.step,
    required this.title,
    required this.body,
    required this.action,
    required this.visual,
    required this.onPressed,
    this.actionBusy = false,
    this.adEnabled = false,
    this.adPlacement,
    this.onAdPaidEvent,
    super.key,
  });

  final int step;
  final String title;
  final String body;
  final String action;
  final Widget visual;
  final VoidCallback? onPressed;
  final bool actionBusy;
  final bool adEnabled;
  final String? adPlacement;
  final PaidAdReporter? onAdPaidEvent;

  @override
  Widget build(BuildContext context) {
    final placement = adPlacement;
    final showAd = adEnabled && placement != null;
    return Semantics(
      label: context.l10n.onboardingStepOfTotal(step, 5),
      explicitChildNodes: true,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxHeight < 700;
          var visualHeight = switch (step) {
            1 => compact ? 250.0 : 430.0,
            5 => compact ? 220.0 : 360.0,
            _ => compact ? 270.0 : 400.0,
          };
          // The visual gives up space for the native ad so the continue
          // button stays above the fold.
          if (showAd) visualHeight -= compact ? 70.0 : 120.0;
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 18, 24, 22),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight - 40,
              ),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(height: visualHeight, child: visual),
                    SizedBox(height: compact ? 22 : 32),
                    Text(
                      title,
                      style: TextStyle(
                        color: _onboardingInk,
                        fontSize: compact ? 34 : 42,
                        height: 1.06,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1.1,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      body,
                      style: const TextStyle(
                        color: Color(0xFF252832),
                        fontSize: 17,
                        height: 1.45,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const Spacer(),
                    if (showAd) ...[
                      const SizedBox(height: 18),
                      NativeAdCard(
                        enabled: adEnabled,
                        placement: placement,
                        height: compact ? 88 : 108,
                        onPaidEvent: onAdPaidEvent,
                      ),
                    ],
                    const SizedBox(height: 26),
                    _OnboardingButton(
                      key: const Key('onboarding_continue'),
                      label: action,
                      onPressed: onPressed,
                      busy: actionBusy,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _OnboardingButton extends StatelessWidget {
  const _OnboardingButton({
    required this.label,
    required this.onPressed,
    this.busy = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 64,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.black87,
          shape: const StadiumBorder(),
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        child: busy
            ? const SizedBox.square(
                dimension: 22,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.4,
                ),
              )
            : Text(label),
      ),
    );
  }
}

class _OnboardingReviewDialog extends StatelessWidget {
  const _OnboardingReviewDialog();

  @override
  Widget build(BuildContext context) {
    return PopScope<void>(
      canPop: false,
      child: AlertDialog(
        key: const Key('onboarding_review_prompt'),
        icon: const Icon(
          Icons.star_rounded,
          color: Color(0xFFFFB020),
          size: 38,
        ),
        title: Text(
          context.l10n.onboardingReviewTitle,
          textAlign: TextAlign.center,
        ),
        content: Text(
          context.l10n.onboardingReviewBody,
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.spaceBetween,
        actions: [
          TextButton(
            key: const Key('onboarding_review_later'),
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(context.l10n.onboardingReviewLater),
          ),
          FilledButton(
            key: const Key('onboarding_review_now'),
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
            ),
            child: Text(context.l10n.onboardingReviewAction),
          ),
        ],
      ),
    );
  }
}

class _HeroVisual extends StatelessWidget {
  const _HeroVisual();

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    final kilograms = NumberFormat('0.0', locale).format(1.2);
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: Stack(
        fit: StackFit.expand,
        children: [
          const ColoredBox(color: Color(0xFFF0F3FA)),
          Image.asset(
            _heroAsset,
            fit: BoxFit.contain,
            alignment: Alignment.center,
          ),
          const Positioned(
            left: 22,
            top: 18,
            child: _WeightBubble(label: '≈ 380 g', color: Color(0xFFD7F0EC)),
          ),
          Positioned(
            right: 18,
            top: 72,
            child: _WeightBubble(
              label: '≈ $kilograms kg',
              color: const Color(0xFFFFD8E5),
            ),
          ),
          const Positioned(
            right: 30,
            bottom: 24,
            child: _WeightBubble(label: '≈ 240 g', color: Color(0xFFFFE4A3)),
          ),
        ],
      ),
    );
  }
}

class _WeightBubble extends StatelessWidget {
  const _WeightBubble({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 9),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _FramingVisual extends StatelessWidget {
  const _FramingVisual();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        Expanded(
          child: _ObjectExample(
            background: Colors.white,
            good: true,
            scale: 0.72,
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Divider(color: Color(0xFFCED1D9), thickness: 2),
        ),
        Expanded(
          child: _ObjectExample(
            background: Colors.white,
            good: false,
            scale: 1.48,
          ),
        ),
      ],
    );
  }
}

class _LightingVisual extends StatelessWidget {
  const _LightingVisual();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        Expanded(
          child: _ObjectExample(
            background: Colors.white,
            good: true,
            scale: 0.72,
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Divider(color: Color(0xFFCED1D9), thickness: 2),
        ),
        Expanded(
          child: _ObjectExample(
            background: Color(0xFFEA5A43),
            good: false,
            scale: 0.72,
          ),
        ),
      ],
    );
  }
}

class _ObjectExample extends StatelessWidget {
  const _ObjectExample({
    required this.background,
    required this.good,
    required this.scale,
  });

  final Color background;
  final bool good;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: ColoredBox(
              color: background,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Transform.scale(
                    scale: scale,
                    child: Image.asset(_mugAsset, fit: BoxFit.contain),
                  ),
                  CustomPaint(painter: const _ScannerCornersPainter()),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        _GlossyBadge(good: good),
      ],
    );
  }
}

class _GlossyBadge extends StatelessWidget {
  const _GlossyBadge({required this.good});

  final bool good;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: good
              ? const [Color(0xFF8BF094), Color(0xFF18A95A)]
              : const [Color(0xFFFFB3C1), Color(0xFFD54867)],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x28000000),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Icon(
        good ? Icons.check_rounded : Icons.close_rounded,
        color: Colors.white,
        size: 38,
        weight: 900,
      ),
    );
  }
}

class _ScannerCornersPainter extends CustomPainter {
  const _ScannerCornersPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;
    final left = size.width * 0.17;
    final right = size.width * 0.83;
    final top = size.height * 0.16;
    final bottom = size.height * 0.84;
    final arm = math.min(size.width, size.height) * 0.14;
    for (final path in [
      Path()
        ..moveTo(left + arm, top)
        ..lineTo(left, top)
        ..lineTo(left, top + arm),
      Path()
        ..moveTo(right - arm, top)
        ..lineTo(right, top)
        ..lineTo(right, top + arm),
      Path()
        ..moveTo(left, bottom - arm)
        ..lineTo(left, bottom)
        ..lineTo(left + arm, bottom),
      Path()
        ..moveTo(right, bottom - arm)
        ..lineTo(right, bottom)
        ..lineTo(right - arm, bottom),
    ]) {
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PreparingPage extends StatelessWidget {
  const _PreparingPage({
    required this.animation,
    required this.scanFinished,
    required this.scanReady,
    required this.adFinished,
    required this.adReady,
    super.key,
  });

  final Animation<double> animation;
  final bool scanFinished;
  final bool scanReady;
  final bool adFinished;
  final bool adReady;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: context.l10n.onboardingStepOfTotal(4, 5),
      explicitChildNodes: true,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 34, 24, 22),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight - 56,
              ),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      context.l10n.onboardingPreparingTitle,
                      style: const TextStyle(
                        color: _onboardingInk,
                        fontSize: 42,
                        height: 1.06,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1.1,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      context.l10n.onboardingPreparingBody,
                      style: const TextStyle(
                        color: Color(0xFF252832),
                        fontSize: 17,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 42),
                    _PreparationRow(
                      label: context.l10n.onboardingScanAccessLabel,
                      finished: scanFinished,
                      successful: scanReady,
                    ),
                    const SizedBox(height: 22),
                    _PreparationRow(
                      label: context.l10n.onboardingAdSupportLabel,
                      finished: adFinished,
                      successful: adReady,
                    ),
                    const SizedBox(height: 26),
                    Expanded(
                      child: SizedBox(
                        height: 300,
                        child: AnimatedBuilder(
                          animation: animation,
                          builder: (context, _) => CustomPaint(
                            painter: _ParticlePainter(animation.value),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PreparationRow extends StatelessWidget {
  const _PreparationRow({
    required this.label,
    required this.finished,
    required this.successful,
  });

  final String label;
  final bool finished;
  final bool successful;

  @override
  Widget build(BuildContext context) {
    final color = finished && !successful ? AppColors.coral : _onboardingInk;
    final status = !finished
        ? context.l10n.onboardingPreparingStatus
        : successful
        ? context.l10n.onboardingReadyStatus
        : context.l10n.onboardingRetryStatus;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: finished
                  ? Icon(
                      successful ? Icons.check_circle : Icons.error_outline,
                      key: ValueKey(successful),
                      color: successful ? const Color(0xFF2AAA68) : color,
                    )
                  : const SizedBox.square(
                      key: ValueKey('loading'),
                      dimension: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.4),
                    ),
            ),
          ],
        ),
        const SizedBox(height: 9),
        Text(status, style: TextStyle(color: color, fontSize: 13)),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          minHeight: 7,
          borderRadius: BorderRadius.circular(99),
          value: finished ? 1 : null,
          backgroundColor: const Color(0xFFE4E6EC),
          color: finished && !successful ? AppColors.coral : _onboardingInk,
        ),
      ],
    );
  }
}

class _ParticlePainter extends CustomPainter {
  const _ParticlePainter(this.progress);

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    const color = Color(0xFF43B77A);
    final center = Offset(size.width / 2, size.height * 0.58);
    for (var index = 0; index < 34; index += 1) {
      final seed = index * 1.73;
      final angle = seed + progress * math.pi * 2 * (index.isEven ? 1 : -0.7);
      final ring = 24 + (index % 8) * 14.0;
      final wave = math.sin(progress * math.pi * 2 + seed) * 8;
      final point =
          center + Offset(math.cos(angle), math.sin(angle)) * (ring + wave);
      final radius = 3.5 + (index % 5) * 1.8;
      canvas.drawCircle(
        point,
        radius,
        Paint()..color = color.withValues(alpha: 0.72 + (index % 3) * 0.08),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _ReadyVisual extends StatelessWidget {
  const _ReadyVisual();

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xFFF1F3F8),
              borderRadius: BorderRadius.circular(30),
            ),
          ),
        ),
        FractionallySizedBox(
          widthFactor: 0.72,
          heightFactor: 0.72,
          child: Image.asset(_balanceAsset, fit: BoxFit.contain),
        ),
        Positioned(
          bottom: 18,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xFFDBF7B1),
              borderRadius: BorderRadius.circular(99),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
              child: Text(
                context.l10n.onboardingThreeStarterScans,
                style: const TextStyle(
                  color: _onboardingInk,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
