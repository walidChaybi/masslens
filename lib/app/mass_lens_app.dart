import 'dart:async';

import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../features/onboarding/presentation/onboarding_screen.dart';
import '../features/shell/presentation/app_shell.dart';
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
    if (widget.controller.monetization.enabled) {
      _checkingResumeAd = _onboardingComplete;
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
    // Balance and consent initialization must also run before onboarding is
    // complete. Only the full-screen app-open placement is gated by onboarding.
    final allowLaunchAd = _onboardingComplete;
    try {
      await widget.controller.initializeMonetization();
      final backgroundTime = widget.controller.takePreviousBackgroundDuration();
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
      if (backgroundedAt != null && widget.controller.onboardingComplete) {
        unawaited(_handleResume(backgroundedAt));
      }
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      _backgroundedAt ??= DateTime.now();
      unawaited(widget.controller.recordBackgrounded(_backgroundedAt!));
    }
  }

  Future<void> _handleResume(DateTime backgroundedAt) async {
    if (mounted) setState(() => _checkingResumeAd = true);
    await widget.controller.handleAppResumed(
      DateTime.now().difference(backgroundedAt),
    );
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
        title: 'MassLens',
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
