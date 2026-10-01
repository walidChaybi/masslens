import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../../core/theme/app_theme.dart';
import '../../../l10n/l10n.dart';
import '../data/app_ad_service.dart';
import '../data/monetization_config.dart';

class NativeAdCard extends StatefulWidget {
  const NativeAdCard({
    required this.enabled,
    required this.placement,
    this.height = 120,
    this.medium = false,
    this.onPaidEvent,
    super.key,
  });

  final bool enabled;
  final String placement;
  final double height;
  final bool medium;
  final PaidAdReporter? onPaidEvent;

  @override
  State<NativeAdCard> createState() => _NativeAdCardState();
}

class _NativeAdCardState extends State<NativeAdCard>
    with AutomaticKeepAliveClientMixin {
  NativeAd? _ad;
  bool _loaded = false;
  bool _adError = false;
  final GlobalKey _adKey = GlobalKey();

  @override
  bool get wantKeepAlive => _loaded;

  @override
  void initState() {
    super.initState();
    if (widget.enabled) _load();
  }

  @override
  void didUpdateWidget(covariant NativeAdCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.medium != oldWidget.medium) {
      _disposeAd();
      if (widget.enabled) _load();
      return;
    }
    if (widget.enabled && !oldWidget.enabled) _load();
    if (!widget.enabled && oldWidget.enabled) _disposeAd();
  }

  void _load() {
    if (_ad != null || !AdMobConfig.hasNativeConfiguration) return;
    _adError = false;
    _ad = NativeAd(
      adUnitId: AdMobConfig.nativeAdUnitId,
      request: const AdRequest(),
      listener: NativeAdListener(
        onAdLoaded: (_) {
          if (mounted) {
            setState(() => _loaded = true);
            updateKeepAlive();
            if (kDebugMode) {
              debugPrint('MassLens native ad loaded: ${widget.placement}');
            }
          }
        },
        onAdFailedToLoad: (ad, error) {
          if (kDebugMode) {
            debugPrint(
              'MassLens native ad failed: ${widget.placement}, ${error.domain}, code ${error.code}',
            );
          }
          ad.dispose();
          if (mounted) {
            setState(() {
              _ad = null;
              _adError = true;
            });
            // Retry after a delay.
            Future.delayed(const Duration(seconds: 30), () {
              if (mounted && widget.enabled && _ad == null) {
                _adError = false;
                _load();
              }
            });
          }
        },
        onPaidEvent: (ad, value, precision, currency) {
          widget.onPaidEvent?.call(
            widget.placement,
            value,
            precision,
            currency,
          );
        },
      ),
      nativeTemplateStyle: NativeTemplateStyle(
        templateType: widget.medium ? TemplateType.medium : TemplateType.small,
        mainBackgroundColor: context.palette.surface,
        cornerRadius: 18,
        callToActionTextStyle: NativeTemplateTextStyle(
          // The call to action is a filled button: its label has to contrast
          // with its own fill, not with the card behind it.
          textColor: widget.medium
              ? context.palette.onLime
              : context.palette.onInk,
          backgroundColor: widget.medium
              ? context.palette.lime
              : context.palette.ink,
          size: widget.medium ? 15 : 13,
        ),
        primaryTextStyle: NativeTemplateTextStyle(
          textColor: context.palette.ink,
          size: 14,
        ),
        secondaryTextStyle: NativeTemplateTextStyle(
          textColor: context.palette.inkMuted,
          size: 12,
        ),
      ),
    )..load();
  }

  void _disposeAd() {
    _ad?.dispose();
    _ad = null;
    _loaded = false;
    _adError = false;
  }

  @override
  void dispose() {
    _disposeAd();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required by AutomaticKeepAliveClientMixin.
    if (!widget.enabled || !_loaded || _ad == null || _adError) {
      if (!widget.enabled || !kDebugMode) return const SizedBox.shrink();
      return Container(
        key: Key('native_ad_loading_${widget.placement}'),
        height: widget.height,
        decoration: BoxDecoration(
          color: context.palette.surface.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.palette.line),
        ),
        alignment: Alignment.center,
        child: Text(
          _adError
              ? context.l10n.nativeTestRetrying
              : context.l10n.nativeTestLoading,
          style: TextStyle(
            color: context.palette.inkMuted,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }
    return RepaintBoundary(
      child: Semantics(
        label: context.l10n.nativeSponsored,
        child: Container(
          key: _adKey,
          height: widget.height,
          decoration: BoxDecoration(
            color: context.palette.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.palette.line),
          ),
          clipBehavior: Clip.antiAlias,
          child: AdWidget(ad: _ad!),
        ),
      ),
    );
  }
}
