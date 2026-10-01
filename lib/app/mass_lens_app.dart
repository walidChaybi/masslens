import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
  late bool _appUnlocked;
  late ThemeMode _themeMode;

  /// The brightness the app is actually painting, for the system bars.
  ///
  /// This runs outside [MaterialApp], so the platform value is read from the
  /// dispatcher rather than from a [MediaQuery] ancestor.
  Brightness get _effectiveBrightness => switch (_themeMode) {
    ThemeMode.light => Brightness.light,
    ThemeMode.dark => Brightness.dark,
    ThemeMode.system =>
      WidgetsBinding.instance.platformDispatcher.platformBrightness,
  };

  @override
  void initState() {
    super.initState();
    _appUnlocked = widget.controller.appUnlockedThisSession;
    _themeMode = widget.controller.themeMode;
    widget.controller.addListener(_handleControllerChanged);
    WidgetsBinding.instance.addObserver(this);
    if (widget.controller.monetization.enabled) {
      // Consent and inventory warm up without blocking the first app frame.
      // Cold launches never show an app-open ad; those are reserved for a
      // genuine return from the background during this running session.
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
    _appUnlocked = widget.controller.appUnlockedThisSession;
    _themeMode = widget.controller.themeMode;
    widget.controller.addListener(_handleControllerChanged);
  }

  void _handleControllerChanged() {
    final unlocked = widget.controller.appUnlockedThisSession;
    final themeMode = widget.controller.themeMode;
    if (!mounted) return;
    if (unlocked == _appUnlocked && themeMode == _themeMode) return;
    setState(() {
      _appUnlocked = unlocked;
      _themeMode = themeMode;
    });
  }

  Future<void> _initializeAdsForLaunch() async {
    await widget.controller.initializeMonetization();
    // Clear a pause marker left by a killed process without turning a cold
    // start into a second full-screen prompt immediately after UMP consent.
    await widget.controller.consumePreviousBackgroundDuration();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Ads and activity transitions often reset the system UI overlay.
      SystemChrome.setSystemUIOverlayStyle(
        systemUiOverlayStyleFor(_effectiveBrightness),
      );
      final backgroundedAt = _backgroundedAt;
      _backgroundedAt = null;
      if (backgroundedAt != null) {
        if (widget.controller.appUnlockedThisSession) {
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
        darkTheme: buildAppDarkTheme(),
        themeMode: _themeMode,
        builder: (context, child) {
          final mediaQuery = MediaQuery.of(context);
          // One UI sometimes reports padding.bottom == 0 while viewPadding
          // still holds the nav-bar height; SafeArea needs the larger value.
          final bottomInset = math.max(
            mediaQuery.padding.bottom,
            mediaQuery.viewPadding.bottom,
          );
          return AnnotatedRegion<SystemUiOverlayStyle>(
            value: systemUiOverlayStyleFor(Theme.of(context).brightness),
            child: MediaQuery(
              data: mediaQuery.copyWith(
                padding: mediaQuery.padding.copyWith(bottom: bottomInset),
              ),
              child: Stack(
                children: [
                  ?child,
                  if (_checkingResumeAd)
                    Positioned.fill(
                      child: ColoredBox(
                        color: context.palette.canvas,
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
        home: _appUnlocked
            ? const AppShell()
            : OnboardingScreen(
                initialPage: widget.controller.welcomeComplete ? 3 : 0,
              ),
      ),
    );
  }
}
