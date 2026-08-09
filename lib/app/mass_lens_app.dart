import 'dart:async';

import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../features/onboarding/presentation/onboarding_screen.dart';
import '../features/shell/presentation/app_shell.dart';
import '../l10n/l10n.dart';
import 'app_controller.dart';

class MassLensApp extends StatefulWidget {
  const MassLensApp({required this.controller, super.key});

  final AppController controller;

  @override
  State<MassLensApp> createState() => _MassLensAppState();
}

class _MassLensAppState extends State<MassLensApp> with WidgetsBindingObserver {
  DateTime? _backgroundedAt;
  bool _checkingResumeAd = false;
  late bool _onboardingComplete;

  @override
  void initState() {
    super.initState();
    _onboardingComplete = widget.controller.onboardingComplete;
    widget.controller.addListener(_handleControllerChanged);
    WidgetsBinding.instance.addObserver(this);
    if (widget.controller.monetization.enabled && _onboardingComplete) {
      _checkingResumeAd = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(_initializeAdsForLaunch());
      });
    }
  }

  @override
  void didUpdateWidget(covariant MassLensApp oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (identical(oldWidget.controller, widget.controller)) return;
    oldWidget.controller.removeListener(_handleControllerChanged);
    _onboardingComplete = widget.controller.onboardingComplete;
    widget.controller.addListener(_handleControllerChanged);
  }

  void _handleControllerChanged() {
    final complete = widget.controller.onboardingComplete;
    if (!mounted || complete == _onboardingComplete) return;
    setState(() => _onboardingComplete = complete);
  }

  Future<void> _initializeAdsForLaunch() async {
    // New users initialize consent and ad inventory on the explicit
    // "Almost ready" step, so an SDK-owned consent form never interrupts the
    // educational pages. Completed users still initialize on launch.
    final allowLaunchAd = _onboardingComplete;
    try {
      await widget.controller.initializeMonetization();
      final backgroundTime = await widget.controller
          .consumePreviousBackgroundDuration();
      if (allowLaunchAd && backgroundTime != null) {
        await widget.controller.handleAppResumed(backgroundTime);
      }
    } finally {
      if (mounted) setState(() => _checkingResumeAd = false);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final backgroundedAt = _backgroundedAt;
      _backgroundedAt = null;
      if (backgroundedAt != null) {
        if (widget.controller.onboardingComplete) {
          unawaited(_handleResume(backgroundedAt));
        } else {
          // Still consume onboarding pauses so they can never become a later
          // app-open opportunity after onboarding is completed.
          unawaited(
            widget.controller.consumeBackgroundDuration(backgroundedAt),
          );
        }
      }
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      _backgroundedAt ??= DateTime.now();
      unawaited(widget.controller.recordBackgrounded(_backgroundedAt!));
    }
  }

  Future<void> _handleResume(DateTime backgroundedAt) async {
    if (mounted) setState(() => _checkingResumeAd = true);
    final backgroundTime = await widget.controller.consumeBackgroundDuration(
      backgroundedAt,
    );
    if (backgroundTime != null) {
      await widget.controller.handleAppResumed(backgroundTime);
    }
    if (mounted) setState(() => _checkingResumeAd = false);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleControllerChanged);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      controller: widget.controller,
      child: MaterialApp(
        onGenerateTitle: (context) => context.l10n.appTitle,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        localeResolutionCallback: (locale, supportedLocales) {
          final languageCode = locale?.languageCode;
          for (final supported in supportedLocales) {
            if (supported.languageCode == languageCode) return supported;
          }
          return const Locale('en');
        },
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        builder: (context, child) => Stack(
          children: [
            ?child,
            if (_checkingResumeAd)
              const Positioned.fill(
                child: ColoredBox(
                  color: AppColors.canvas,
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
          ],
        ),
        home: _onboardingComplete ? const AppShell() : const OnboardingScreen(),
      ),
    );
  }
}
