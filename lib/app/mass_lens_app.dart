import 'dart:async';

import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.controller.onboardingComplete &&
        widget.controller.monetization.enabled) {
      _checkingResumeAd = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(_initializeAdsForLaunch());
      });
    }
  }

  Future<void> _initializeAdsForLaunch() async {
    await widget.controller.initializeMonetization();
    final backgroundTime = widget.controller.takePreviousBackgroundDuration();
    if (backgroundTime != null) {
      await widget.controller.handleAppResumed(backgroundTime);
    }
    if (mounted) setState(() => _checkingResumeAd = false);
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
        home: const AppShell(),
      ),
    );
  }
}
