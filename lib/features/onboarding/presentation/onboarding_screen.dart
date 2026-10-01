import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../app/app_controller.dart';
import '../../../l10n/l10n.dart';
import '../../monetization/data/app_ad_service.dart';
import '../../monetization/presentation/access_paywall.dart';
import '../../monetization/presentation/native_ad_card.dart';

const _onboardingCanvas = Color(0xFFF7F8FC);
const _onboardingInk = Color(0xFF090B10);
const _heroAsset = 'assets/onboarding/masslens_hero.webp';
const _mugAsset = 'assets/onboarding/teal_mug.webp';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({
    this.initialPage = 0,
    this.replay = false,
    super.key,
  });

  final int initialPage;

  /// Replays the three capture pages as a walkthrough opened from Settings.
  ///
  /// A replay is informational only: no ads, no paywall page, no review
  /// prompt, and it never re-marks onboarding complete. It pops when finished.
  final bool replay;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  late final PageController _pageController;

  late int _page;
  bool _assetsPrecached = false;
  bool _completionBusy = false;

  @override
  void initState() {
    super.initState();
    _page = widget.initialPage;
    _pageController = PageController(initialPage: widget.initialPage);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.replay) return;
      unawaited(AppScope.of(context).initializeMonetization());
      if (widget.initialPage >= 3) {
        unawaited(AppScope.of(context).markWelcomeComplete());
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_assetsPrecached) {
      _assetsPrecached = true;
      unawaited(precacheImage(const AssetImage(_heroAsset), context));
      unawaited(precacheImage(const AssetImage(_mugAsset), context));
      unawaited(precacheImage(const AssetImage(luggageScanAsset), context));
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
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
    if (_completionBusy) return;
    if (_page < 2) {
      await _showPage(_page + 1);
    }
  }

  Future<void> _finishOnboarding({required bool showInterstitial}) async {
    if (_completionBusy || !mounted) return;
    setState(() => _completionBusy = true);
    final controller = AppScope.of(context);
    if (showInterstitial) {
      await controller.monetization.showOnboardingCompletionInterstitial();
    }
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
    if (page == 3 && !widget.replay) {
      unawaited(AppScope.of(context).markWelcomeComplete());
    }
  }

  Future<void> _goBack() async {
    if (_page == 0 || _completionBusy) return;
    await _showPage(_page - 1);
  }

  @override
  Widget build(BuildContext context) {
    final monetization = AppScope.of(context).monetization;
    final adsEnabled = !widget.replay && monetization.canRequestNativeAds;
    final PaidAdReporter reportPaidAd = monetization.reportPaidAd;
    return PopScope<void>(
      canPop: _page == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) unawaited(_goBack());
      },
      child: Scaffold(
        backgroundColor: _page == 3 ? paywallBlue : _onboardingCanvas,
        body: SafeArea(
          top: _page != 3,
          bottom: _page != 3,
          maintainBottomViewPadding: true,
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
                    showDescription: true,
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
                    showDescription: false,
                  ),
                  _ContentPage(
                    key: const Key('onboarding_page_3'),
                    step: 3,
                    title: context.l10n.onboardingLightTitle,
                    body: context.l10n.onboardingLightBody,
                    action: widget.replay
                        ? context.l10n.commonDone
                        : context.l10n.onboardingLightCta,
                    visual: const _LightingVisual(),
                    onPressed: widget.replay
                        ? () => Navigator.of(context).maybePop()
                        : () => _showPage(3),
                    adEnabled: adsEnabled,
                    adPlacement: 'onboarding_light',
                    onAdPaidEvent: reportPaidAd,
                    showDescription: false,
                  ),
                  if (!widget.replay)
                    _OnboardingPaywallPage(
                      key: const Key('onboarding_page_paywall'),
                      onFinished: _finishOnboarding,
                      busy: _completionBusy,
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

class _OnboardingPaywallPage extends StatelessWidget {
  const _OnboardingPaywallPage({
    required this.onFinished,
    required this.busy,
    super.key,
  });

  final Future<void> Function({required bool showInterstitial}) onFinished;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    if (busy) {
      return const Center(child: CircularProgressIndicator());
    }
    return AccessPaywall(
      showSkip: true,
      onSkip: () => unawaited(onFinished(showInterstitial: true)),
      onUnlocked: () => unawaited(onFinished(showInterstitial: false)),
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
    this.adEnabled = false,
    this.adPlacement,
    this.onAdPaidEvent,
    this.showDescription = true,
    super.key,
  });

  final int step;
  final String title;
  final String body;
  final String action;
  final Widget visual;
  final VoidCallback? onPressed;
  final bool adEnabled;
  final String? adPlacement;
  final PaidAdReporter? onAdPaidEvent;
  final bool showDescription;

  @override
  Widget build(BuildContext context) {
    final placement = adPlacement;
    final showAd = adEnabled && placement != null;
    return Semantics(
      label: context.l10n.onboardingStepOfTotal(step, 3),
      explicitChildNodes: true,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxHeight < 700;
          final visualHeight = math.min(
            compact ? 320.0 : 430.0,
            math.max(220.0, constraints.maxHeight - (showAd ? 252 : 132)),
          );
          final content = <Widget>[
            SizedBox(height: visualHeight, child: visual),
            if (showDescription) ...[
              SizedBox(
                height: showAd
                    ? 20
                    : compact
                    ? 22
                    : 32,
              ),
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
              const SizedBox(height: 12),
              Text(
                body,
                key: const Key('onboarding_estimate_notice'),
                style: const TextStyle(
                  color: Color(0xFF455268),
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
            ] else ...[
              const SizedBox(height: 8),
            ],
          ];
          final button = _OnboardingButton(
            key: const Key('onboarding_continue'),
            label: action,
            onPressed: onPressed,
          );
          if (showAd) {
            final adSize = constraints.maxWidth - 48;
            return Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 18, 24, 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ...content,
                        const SizedBox(height: 20),
                        Center(
                          child: SizedBox(
                            width: adSize,
                            child: NativeAdCard(
                              enabled: adEnabled,
                              placement: placement,
                              height: 120,
                              onPaidEvent: onAdPaidEvent,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
                  child: SizedBox(width: double.infinity, child: button),
                ),
              ],
            );
          }
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
                    ...content,
                    const Spacer(),
                    const SizedBox(height: 26),
                    button,
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
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;

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
          disabledForegroundColor: Colors.white70,
          shape: const StadiumBorder(),
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        child: Text(label),
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
            ).copyWith(),
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
