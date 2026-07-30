import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../features/onboarding/presentation/onboarding_screen.dart';
import '../features/shell/presentation/app_shell.dart';
import 'app_controller.dart';

class MassLensApp extends StatelessWidget {
  const MassLensApp({required this.controller, super.key});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return AppScope(
      controller: controller,
      child: MaterialApp(
        title: 'MassLens',
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        home: const _AppGate(),
      ),
    );
  }
}

class _AppGate extends StatelessWidget {
  const _AppGate();

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 320),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child: controller.onboardingComplete
          ? const AppShell(key: ValueKey('app_shell'))
          : const OnboardingScreen(key: ValueKey('onboarding')),
    );
  }
}
