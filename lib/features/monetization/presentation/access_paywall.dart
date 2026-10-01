import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/app_controller.dart';
import '../../../l10n/l10n.dart';
import '../../legal/presentation/legal_screen.dart';
import '../application/monetization_controller.dart';

const luggageScanAsset = 'assets/paywall/luggage_scan.webp';
const paywallMarkAsset = 'assets/paywall/photo_estimates_mark.png';
const photoEstimateHeroAsset = 'assets/onboarding/teal_mug.webp';
const paywallBlue = Color(0xFF0963F5);
const paywallSurface = Color(0xFFFFFDF8);
const _ink = Color(0xFF14233D);
const _muted = Color(0xFF596A80);
const _ice = Color(0xFFE8F0FF);
const _lime = Color(0xFFE1FFB7);

/// The same lifetime purchase screen is used at launch and in the upgrade sheet.
class AccessPaywall extends StatefulWidget {
  const AccessPaywall({
    this.showSkip = false,
    this.onSkip,
    this.onUnlocked,
    super.key,
  });

  final bool showSkip;
  final VoidCallback? onSkip;
  final VoidCallback? onUnlocked;

  @override
  State<AccessPaywall> createState() => _AccessPaywallState();
}

class _AccessPaywallState extends State<AccessPaywall> {
  MonetizationController? _monetization;
  bool _checking = false;
  bool _buying = false;
  bool _restoring = false;
  bool _awaitingEntitlement = false;
  bool _completed = false;
  bool _completionScheduled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_loadStorePrice());
      for (final asset in [
        photoEstimateHeroAsset,
        paywallMarkAsset,
        luggageScanAsset,
      ]) {
        unawaited(precacheImage(AssetImage(asset), context));
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final monetization = AppScope.of(context).monetization;
    if (identical(monetization, _monetization)) return;
    _monetization?.removeListener(_handleEntitlement);
    _monetization = monetization;
    monetization.addListener(_handleEntitlement);
  }

  @override
  void dispose() {
    _monetization?.removeListener(_handleEntitlement);
    super.dispose();
  }

  void _handleEntitlement() {
    // Play's purchase/restore call can return before stream verification finishes.
    if (!mounted ||
        !_awaitingEntitlement ||
        _completed ||
        _completionScheduled ||
        !(_monetization?.hasLifetime ?? false)) {
      return;
    }
    _completionScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _completionScheduled = false;
      if (mounted && (_monetization?.hasLifetime ?? false)) {
        _complete(unlocked: true);
      }
    });
  }

  Future<void> _loadStorePrice() async {
    final monetization = _monetization!;
    await monetization.initialize();
    if (!mounted) return;
    await monetization.refreshBillingProduct();
  }

  bool get _busy => _checking || _buying || _restoring;

  void _complete({required bool unlocked}) {
    if (_completed) return;
    final callback = unlocked ? widget.onUnlocked : widget.onSkip;
    if (callback == null) return;
    _completed = true;
    callback();
  }

  Future<void> _check() async {
    if (_busy) return;
    setState(() => _checking = true);
    final monetization = _monetization!;
    final added = await monetization.reconcileRewardAttempts();
    if (!mounted) return;
    setState(() => _checking = false);
    if (added) {
      _complete(unlocked: true);
    } else if (!monetization.hasPendingReward) {
      _showMessage(context.l10n.rewardNoCreditAdded);
    }
  }

  Future<void> _buyLifetime() async {
    if (_busy) return;
    setState(() {
      _buying = true;
      _awaitingEntitlement = true;
    });
    final monetization = _monetization!;
    try {
      await monetization.buyLifetime();
    } on Object {
      if (mounted) _showMessage(context.l10n.paywallPurchaseUnavailable);
      return;
    } finally {
      if (mounted) setState(() => _buying = false);
    }
    if (!mounted) return;
    if (monetization.hasLifetime) {
      _complete(unlocked: true);
    } else if (monetization.billingMessage case final message?) {
      _showMessage(message);
    }
  }

  Future<void> _restore() async {
    if (_busy) return;
    setState(() {
      _restoring = true;
      _awaitingEntitlement = true;
    });
    final monetization = _monetization!;
    try {
      await monetization.restorePurchases();
    } on Object {
      if (mounted) _showMessage(context.l10n.paywallPurchaseUnavailable);
      return;
    } finally {
      if (mounted) setState(() => _restoring = false);
    }
    if (!mounted) return;
    if (monetization.hasLifetime) {
      _complete(unlocked: true);
    } else if ((monetization.billingMessage ?? monetization.message)
        case final message?) {
      _showMessage(message);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  void _openLegal(LegalDocument document) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => LegalScreen(initialDocument: document),
      ),
    );
  }

  bool _canBuy(MonetizationController monetization, bool busy) =>
      !busy &&
      monetization.billingSupported &&
      !monetization.billingLoadingProduct &&
      monetization.lifetimePriceLabel.isNotEmpty;

  String _buttonLabel(
    AppLocalizations l10n,
    MonetizationController monetization,
  ) {
    if (monetization.billingLoadingProduct) {
      return l10n.accessLifetimeLoadingPrice;
    }
    if (monetization.lifetimePriceLabel.isNotEmpty) {
      return l10n.paywallUnlockLifetime;
    }
    if (monetization.billingSupported &&
        !monetization.billingProductQueryCompleted) {
      return l10n.accessLifetimeLoadingPrice;
    }
    return l10n.paywallPurchaseUnavailable;
  }

  Widget _footerDetails(
    AppLocalizations l10n,
    MonetizationController monetization,
    bool busy,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!monetization.hasLifetime) ...[
          const SizedBox(height: 9),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.verified_user_outlined, size: 13, color: _muted),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  l10n.paywallPurchaseTrust,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: _muted,
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ],
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (monetization.billingSupported)
              _FooterLink(
                key: const Key('restore_lifetime_purchases'),
                onPressed: busy ? null : _restore,
                label: l10n.accessRestorePurchases,
                loading: _restoring,
              ),
            _FooterLink(
              key: const Key('paywall_terms'),
              onPressed: busy
                  ? null
                  : () => _openLegal(LegalDocument.termsOfUse),
              label: l10n.paywallTerms,
            ),
            _FooterLink(
              key: const Key('paywall_privacy'),
              onPressed: busy
                  ? null
                  : () => _openLegal(LegalDocument.privacyPolicy),
              label: l10n.paywallPrivacy,
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final monetization = AppScope.of(context).monetization;
    final l10n = context.l10n;
    final busy = _busy || monetization.rewardActionBusy;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: paywallSurface,
        systemNavigationBarIconBrightness: Brightness.dark,
        systemNavigationBarContrastEnforced: false,
      ),
      child: Material(
        color: paywallBlue,
        child: SafeArea(
          bottom: false,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxHeight < 780;
              final compactFooter =
                  MediaQuery.textScalerOf(context).scale(14) > 19 ||
                  constraints.maxHeight < 500;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: ColoredBox(
                      color: paywallSurface,
                      child: SingleChildScrollView(
                        key: const Key('paywall_scroll'),
                        child: ColoredBox(
                          color: paywallBlue,
                          child: Column(
                            children: [
                              _PaywallHeader(
                                compact: compact,
                                onClose:
                                    (widget.showSkip ||
                                            widget.onSkip != null) &&
                                        !busy
                                    ? () => _complete(unlocked: false)
                                    : null,
                                showClose:
                                    widget.showSkip || widget.onSkip != null,
                              ),
                              Container(
                                width: double.infinity,
                                decoration: const BoxDecoration(
                                  color: paywallSurface,
                                  borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(29),
                                  ),
                                ),
                                child: _ContentWidth(
                                  padding: EdgeInsets.fromLTRB(
                                    24,
                                    compact ? 14 : 18,
                                    24,
                                    10,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Text(
                                        l10n.paywallFeatureHeading,
                                        style: const TextStyle(
                                          color: _muted,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 1.2,
                                          height: 1.3,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      _FeatureList(compact: compact),
                                      if (!monetization.hasLifetime) ...[
                                        if (compactFooter) ...[
                                          const SizedBox(height: 18),
                                          _LifetimeOffer(
                                            monetization: monetization,
                                          ),
                                        ],
                                        if (monetization
                                                .lifetimePriceLabel
                                                .isEmpty &&
                                            monetization.billingMessage !=
                                                null) ...[
                                          const SizedBox(height: 6),
                                          Text(
                                            monetization.billingMessage!,
                                            key: const Key(
                                              'paywall_billing_message',
                                            ),
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(
                                              color: _muted,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ],
                                      ],
                                      if (compactFooter)
                                        _footerDetails(
                                          l10n,
                                          monetization,
                                          busy,
                                        ),
                                      if (monetization.hasPendingReward) ...[
                                        const SizedBox(height: 10),
                                        _PendingRewardBanner(
                                          busy: busy,
                                          checking: _checking,
                                          onCheck: _check,
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  ColoredBox(
                    color: paywallSurface,
                    child: SafeArea(
                      top: false,
                      maintainBottomViewPadding: true,
                      child: _ContentWidth(
                        padding: EdgeInsets.fromLTRB(
                          24,
                          8,
                          24,
                          compact ? 4 : 8,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (monetization.hasLifetime)
                              Container(
                                key: const Key('paywall_lifetime_active'),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE7F3D5),
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: Text(
                                  l10n.accessLifetimeUnlocked,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: _ink,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              )
                            else ...[
                              if (!compactFooter) ...[
                                _LifetimeOffer(monetization: monetization),
                                const SizedBox(height: 10),
                              ],
                              FilledButton(
                                key: const Key('buy_lifetime_unlock'),
                                onPressed: _canBuy(monetization, busy)
                                    ? _buyLifetime
                                    : null,
                                style: FilledButton.styleFrom(
                                  minimumSize: const Size.fromHeight(54),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 15,
                                  ),
                                  backgroundColor: paywallBlue,
                                  foregroundColor: Colors.white,
                                  disabledBackgroundColor: const Color(
                                    0xFFDCE7FB,
                                  ),
                                  disabledForegroundColor: const Color(
                                    0xFF49638B,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  textStyle: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    height: 1.2,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    if (_buying) ...[
                                      const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      ),
                                      const SizedBox(width: 9),
                                    ],
                                    Flexible(
                                      child: Text(
                                        _buttonLabel(l10n, monetization),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                    if (_canBuy(monetization, busy)) ...[
                                      const SizedBox(width: 9),
                                      const Icon(
                                        Icons.arrow_forward_rounded,
                                        size: 18,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                            if (!compactFooter)
                              _footerDetails(l10n, monetization, busy),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ContentWidth extends StatelessWidget {
  const _ContentWidth({required this.child, required this.padding});
  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 460),
      child: Padding(padding: padding, child: child),
    ),
  );
}

class _PaywallHeader extends StatelessWidget {
  const _PaywallHeader({
    required this.compact,
    required this.showClose,
    this.onClose,
  });
  final bool compact;
  final bool showClose;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return _ContentWidth(
      padding: EdgeInsets.fromLTRB(24, 2, 24, compact ? 18 : 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(7),
                child: Image.asset(
                  paywallMarkAsset,
                  width: 24,
                  height: 24,
                  excludeFromSemantics: true,
                ),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  l10n.appTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (showClose)
                IconButton(
                  key: const Key('paywall_skip'),
                  onPressed: onClose,
                  tooltip: l10n.paywallContinueFree,
                  icon: const Icon(
                    Icons.close_rounded,
                    color: Colors.white,
                    size: 23,
                  ),
                )
              else
                const SizedBox(height: 44),
            ],
          ),
          SizedBox(height: compact ? 6 : 12),
          Text(
            l10n.paywallHeadline,
            key: const Key('paywall_headline'),
            style: TextStyle(
              color: Colors.white,
              fontSize: compact ? 32 : 37,
              height: 1.07,
              fontWeight: FontWeight.w800,
              letterSpacing: -1.2,
            ),
          ),
          Text(
            l10n.paywallHeadlineRest,
            style: TextStyle(
              color: _lime,
              fontSize: compact ? 32 : 37,
              height: 1.07,
              fontWeight: FontWeight.w800,
              letterSpacing: -1.2,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            l10n.paywallHeroSubtitle,
            style: const TextStyle(
              color: Color(0xFFE1EDFF),
              fontSize: 13,
              height: 1.45,
            ),
          ),
          SizedBox(height: compact ? 9 : 14),
          _PaywallGallery(compact: compact),
        ],
      ),
    );
  }
}

class _PaywallGallery extends StatelessWidget {
  const _PaywallGallery({required this.compact});
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return LayoutBuilder(
      builder: (context, constraints) {
        final photoHeight = (constraints.maxWidth * (compact ? .43 : .47))
            .clamp(115.0, 180.0);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 34),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 49,
                    child: Transform.rotate(
                      angle: -7 * math.pi / 180,
                      child: _ImageCard(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              height: photoHeight,
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  Image.asset(
                                    luggageScanAsset,
                                    key: const Key('paywall_luggage_hero'),
                                    fit: BoxFit.cover,
                                    alignment: const Alignment(.65, 0),
                                    excludeFromSemantics: true,
                                  ),
                                  Positioned(
                                    left: 6,
                                    top: 7,
                                    right: 6,
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: _ImageLabel(
                                        label: l10n.paywallPhotoScanLabel,
                                      ),
                                    ),
                                  ),
                                  const Positioned(
                                    left: 30,
                                    right: 12,
                                    top: 34,
                                    bottom: 10,
                                    child: CustomPaint(
                                      painter: _ScanCornersPainter(),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(8, 6, 5, 6),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    l10n.paywallLuggageWeight,
                                    style: const TextStyle(
                                      color: _ink,
                                      fontSize: 20,
                                      height: 1.1,
                                      letterSpacing: -.6,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    l10n.paywallEstimateExample,
                                    style: const TextStyle(
                                      color: _muted,
                                      fontSize: 10,
                                      height: 1.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 3),
                  Expanded(
                    flex: 56,
                    child: Transform.translate(
                      offset: const Offset(0, 20),
                      child: Transform.rotate(
                        angle: 6 * math.pi / 180,
                        child: _ImageCard(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                height: photoHeight + 5,
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    Image.asset(
                                      photoEstimateHeroAsset,
                                      key: const Key('paywall_photo_hero'),
                                      fit: BoxFit.cover,
                                      semanticLabel: l10n.paywallPhotoScanLabel,
                                    ),
                                    Positioned(
                                      left: 6,
                                      top: 7,
                                      right: 6,
                                      child: Align(
                                        alignment: Alignment.centerLeft,
                                        child: _ImageLabel(
                                          label: l10n.paywallPhotoScanLabel
                                              .toUpperCase(),
                                          light: true,
                                          icon: Icons.photo_camera_outlined,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 8,
                                ),
                                child: Text(
                                  l10n.paywallEstimateExample,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Color(0xFF354E6C),
                                    fontSize: 11,
                                    height: 1.2,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Text(
              l10n.paywallIllustrativeReadings,
              style: const TextStyle(
                color: Color(0xFFE1EDFF),
                fontSize: 10,
                height: 1.2,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ImageCard extends StatelessWidget {
  const _ImageCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: const [
        BoxShadow(
          color: Color(0x40003680),
          blurRadius: 18,
          offset: Offset(0, 9),
        ),
      ],
    ),
    child: Padding(
      padding: const EdgeInsets.all(4),
      child: ClipRRect(borderRadius: BorderRadius.circular(16), child: child),
    ),
  );
}

class _ImageLabel extends StatelessWidget {
  const _ImageLabel({required this.label, this.light = false, this.icon});
  final String label;
  final bool light;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
    decoration: BoxDecoration(
      color: light ? const Color(0xF2FFFFFF) : const Color(0xE611243D),
      borderRadius: BorderRadius.circular(5),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 12, color: const Color(0xFF07449C)),
          const SizedBox(width: 3),
        ],
        Flexible(
          child: Text(
            label,
            style: TextStyle(
              color: light ? const Color(0xFF07449C) : Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.w800,
              height: 1.2,
              letterSpacing: .2,
            ),
          ),
        ),
      ],
    ),
  );
}

class _ScanCornersPainter extends CustomPainter {
  const _ScanCornersPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = _lime
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    const length = 18.0;
    for (final origin in [
      Offset.zero,
      Offset(size.width, 0),
      Offset(0, size.height),
      Offset(size.width, size.height),
    ]) {
      final dx = origin.dx == 0 ? length : -length;
      final dy = origin.dy == 0 ? length : -length;
      canvas.drawPath(
        Path()
          ..moveTo(origin.dx + dx, origin.dy)
          ..lineTo(origin.dx, origin.dy)
          ..lineTo(origin.dx, origin.dy + dy),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ScanCornersPainter oldDelegate) => false;
}

class _FeatureList extends StatelessWidget {
  const _FeatureList({required this.compact});
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final items = [
      (
        Icons.photo_camera_outlined,
        l10n.paywallFeatureLifetime,
        l10n.paywallFeatureLifetimeSub,
      ),
      (
        Icons.document_scanner_outlined,
        l10n.paywallFeatureObjects,
        l10n.paywallFeatureObjectsSub,
      ),
      (
        Icons.restaurant_outlined,
        l10n.paywallFeatureNutrition,
        l10n.paywallFeatureNutritionSub,
      ),
    ];
    return Column(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) SizedBox(height: compact ? 9 : 12),
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: i == 0 ? const Color(0xFFE7F3D5) : _ice,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  items[i].$1,
                  color: i == 0 ? const Color(0xFF3F741B) : paywallBlue,
                  size: 20,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      items[i].$2,
                      style: const TextStyle(
                        color: _ink,
                        fontSize: 14,
                        height: 1.25,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      items[i].$3,
                      style: const TextStyle(
                        color: _muted,
                        fontSize: 11,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _LifetimeOffer extends StatelessWidget {
  const _LifetimeOffer({required this.monetization});
  final MonetizationController monetization;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final price = monetization.lifetimePriceLabel;
    final loading =
        monetization.billingSupported &&
        (monetization.billingLoadingProduct ||
            !monetization.billingProductQueryCompleted);
    final details = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.paywallLifetimeOffer,
          style: const TextStyle(
            color: _ink,
            fontSize: 14,
            fontWeight: FontWeight.w800,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          l10n.paywallOneTimeCaption,
          style: const TextStyle(color: _muted, fontSize: 11, height: 1.4),
        ),
      ],
    );
    final priceWidget = Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          price.isNotEmpty
              ? price
              : loading
              ? l10n.accessLifetimeLoadingPrice
              : l10n.paywallPurchaseUnavailable,
          key: const Key('paywall_store_price'),
          textAlign: TextAlign.end,
          style: TextStyle(
            color: paywallBlue,
            fontSize: price.isNotEmpty ? 24 : 11,
            height: 1.2,
            fontWeight: price.isNotEmpty ? FontWeight.w800 : FontWeight.w600,
            letterSpacing: price.isNotEmpty ? -.7 : 0,
          ),
        ),
      ],
    );
    return Container(
      key: const Key('paywall_lifetime_offer'),
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F6FF),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: paywallBlue, width: 1.5),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (MediaQuery.textScalerOf(context).scale(14) > 19 ||
              constraints.maxWidth < 280) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [details, const SizedBox(height: 6), priceWidget],
            );
          }
          return Row(
            children: [
              Expanded(flex: 3, child: details),
              const SizedBox(width: 10),
              Flexible(flex: 2, child: priceWidget),
            ],
          );
        },
      ),
    );
  }
}

class _FooterLink extends StatelessWidget {
  const _FooterLink({
    required this.label,
    required this.onPressed,
    this.loading = false,
    super.key,
  });
  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) => TextButton(
    onPressed: onPressed,
    style: TextButton.styleFrom(
      foregroundColor: _muted,
      minimumSize: const Size(44, 44),
      padding: const EdgeInsets.symmetric(horizontal: 7),
      textStyle: const TextStyle(fontSize: 11),
    ),
    child: loading
        ? const SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : Text(label),
  );
}

class _PendingRewardBanner extends StatelessWidget {
  const _PendingRewardBanner({
    required this.busy,
    required this.checking,
    required this.onCheck,
  });
  final bool busy;
  final bool checking;
  final VoidCallback onCheck;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      key: const Key('reward_sync_pending'),
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
      decoration: BoxDecoration(
        color: _ice,
        border: Border.all(color: const Color(0xFFD0DFF9)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.sync_rounded, size: 18, color: paywallBlue),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              l10n.rewardSyncPending,
              style: const TextStyle(
                color: _ink,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
          TextButton(
            key: const Key('check_reward_status'),
            onPressed: busy ? null : onCheck,
            child: Text(checking ? l10n.rewardChecking : l10n.rewardCheck),
          ),
        ],
      ),
    );
  }
}
