import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../../core/theme/app_theme.dart';
import '../data/monetization_config.dart';

class NativeAdCard extends StatefulWidget {
  const NativeAdCard({required this.enabled, super.key});

  final bool enabled;

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
          if (mounted) setState(() => _loaded = true);
        },
        onAdFailedToLoad: (ad, error) {
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
      ),
      nativeTemplateStyle: NativeTemplateStyle(
        templateType: TemplateType.small,
        mainBackgroundColor: AppColors.surface,
        cornerRadius: 18,
        callToActionTextStyle: NativeTemplateTextStyle(
          textColor: Colors.white,
          backgroundColor: AppColors.ink,
          size: 13,
        ),
        primaryTextStyle: NativeTemplateTextStyle(
          textColor: AppColors.ink,
          size: 14,
        ),
        secondaryTextStyle: NativeTemplateTextStyle(
          textColor: AppColors.inkMuted,
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
      return const SizedBox.shrink();
    }
    return RepaintBoundary(
      child: Semantics(
        label: 'Sponsored content',
        child: Container(
          key: _adKey,
          height: 108,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.line),
          ),
          clipBehavior: Clip.antiAlias,
          child: AdWidget(ad: _ad!),
        ),
      ),
    );
  }
}
