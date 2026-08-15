import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/app_controller.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_components.dart';
import '../../../l10n/l10n.dart';
import '../../guide/presentation/guide_screen.dart';
import '../../history/presentation/history_screen.dart';
import '../../home/presentation/home_screen.dart';
import '../../measurements/domain/measurement.dart';
import '../../scale/presentation/digital_scale_screen.dart';
import '../../scan/presentation/scan_screen.dart';
import '../../settings/presentation/settings_screen.dart';

enum _AppDestination { digitalScale, aiScan, history, guide, settings }

extension on _AppDestination {
  String label(AppLocalizations l10n) => switch (this) {
    _AppDestination.digitalScale => l10n.shellDigitalScale,
    _AppDestination.aiScan => l10n.shellAiWeightScan,
    _AppDestination.history => l10n.shellHistory,
    _AppDestination.guide => l10n.shellCaptureGuide,
    _AppDestination.settings => l10n.shellSettings,
  };
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  _AppDestination _destination = _AppDestination.digitalScale;
  bool _drawerTransitionBusy = false;
  bool _drawerOpen = false;
  bool _exitConfirmationVisible = false;

  Future<void> _confirmExit() async {
    if (_exitConfirmationVisible || !mounted) return;
    _exitConfirmationVisible = true;
    final l10n = context.l10n;
    try {
      final shouldExit = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        useSafeArea: true,
        builder: (dialogContext) => AlertDialog(
          key: const Key('exit_confirmation_dialog'),
          scrollable: true,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 24,
          ),
          title: Text(l10n.shellExitTitle),
          content: Text(l10n.shellExitBody),
          actions: [
            TextButton(
              key: const Key('exit_confirmation_no'),
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(l10n.commonNo),
            ),
            FilledButton(
              key: const Key('exit_confirmation_ok'),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(l10n.commonOk),
            ),
          ],
        ),
      );
      if (shouldExit == true && mounted) {
        await SystemNavigator.pop();
      }
    } finally {
      _exitConfirmationVisible = false;
    }
  }

  Future<void> _openScan({
    ScanMode scanMode = ScanMode.object,
    bool startWithGallery = false,
  }) async {
    final appController = AppScope.of(context);
    final monetization = appController.monetization;
    final completed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) =>
            ScanScreen(scanMode: scanMode, startWithGallery: startWithGallery),
      ),
    );
    if (completed == true) {
      await monetization.onResultScreenClosed();
      await appController.maybeRequestPostScanReview();
    }
  }

  void _selectDestination(_AppDestination destination) {
    if (_destination == destination) return;
    setState(() => _destination = destination);
  }

  Future<void> _selectDrawerDestination(_AppDestination destination) async {
    Navigator.of(context).pop();
    if (_destination == destination || _drawerTransitionBusy) return;
    final monetization = AppScope.of(context).monetization;
    _drawerTransitionBusy = true;
    try {
      // Let the drawer finish closing before presenting a full-screen ad.
      await Future<void>.delayed(const Duration(milliseconds: 260));
      if (!mounted) return;
      if (destination == _AppDestination.aiScan ||
          destination == _AppDestination.digitalScale) {
        await monetization.showDrawerModeInterstitial(
          aiScan: destination == _AppDestination.aiScan,
        );
      } else if (destination == _AppDestination.history) {
        await monetization.showDrawerHistoryInterstitial();
      }
      if (mounted) setState(() => _destination = destination);
    } finally {
      _drawerTransitionBusy = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final screens = [
      DigitalScaleScreen(
        onOpenAiScan: () => _selectDestination(_AppDestination.aiScan),
        onOpenMenu: () => _scaffoldKey.currentState?.openDrawer(),
      ),
      HomeScreen(
        onMeasure: (mode) => _openScan(scanMode: mode),
        onGallery: (mode) => _openScan(scanMode: mode, startWithGallery: true),
        onViewHistory: () => _selectDestination(_AppDestination.history),
      ),
      HistoryScreen(onScan: _openScan),
      GuideScreen(onScan: _openScan),
      const SettingsScreen(),
    ];
    final selectedIndex = _AppDestination.values.indexOf(_destination);

    return PopScope<void>(
      canPop: _drawerOpen,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) unawaited(_confirmExit());
      },
      child: Scaffold(
        key: _scaffoldKey,
        onDrawerChanged: (isOpened) {
          if (mounted) setState(() => _drawerOpen = isOpened);
        },
        appBar: _destination == _AppDestination.digitalScale
            ? null
            : AppBar(
                leading: Builder(
                  builder: (context) => IconButton(
                    key: const Key('open_navigation'),
                    tooltip: l10n.shellOpenNavigationMenu,
                    onPressed: () => Scaffold.of(context).openDrawer(),
                    icon: const Icon(Icons.menu_rounded),
                  ),
                ),
                title: Text(_destination.label(l10n)),
              ),
        drawer: NavigationDrawer(
          key: const Key('app_navigation_drawer'),
          selectedIndex: selectedIndex,
          onDestinationSelected: (index) {
            unawaited(_selectDrawerDestination(_AppDestination.values[index]));
          },
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 22, 24, 12),
              child: MassLensLogo(),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 18),
              child: Text(
                l10n.shellChooseMode,
                style: const TextStyle(
                  color: AppColors.inkMuted,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ),
            const Divider(),
            const SizedBox(height: 8),
            NavigationDrawerDestination(
              key: const Key('nav_digital_scale'),
              icon: const Icon(Icons.scale_outlined),
              selectedIcon: const Icon(Icons.scale_rounded),
              label: Text(l10n.shellDigitalScale),
            ),
            NavigationDrawerDestination(
              key: const Key('nav_ai_scan'),
              icon: const Icon(Icons.center_focus_strong_outlined),
              selectedIcon: const Icon(Icons.center_focus_strong_rounded),
              label: Text(l10n.shellAiWeightScan),
            ),
            NavigationDrawerDestination(
              key: const Key('nav_history'),
              icon: const Icon(Icons.history_rounded),
              selectedIcon: const Icon(Icons.inventory_2_rounded),
              label: Text(l10n.shellHistory),
            ),
            NavigationDrawerDestination(
              key: const Key('nav_guide'),
              icon: const Icon(Icons.menu_book_outlined),
              selectedIcon: const Icon(Icons.menu_book_rounded),
              label: Text(l10n.shellCaptureGuide),
            ),
            NavigationDrawerDestination(
              key: const Key('nav_settings'),
              icon: const Icon(Icons.tune_rounded),
              selectedIcon: const Icon(Icons.settings_rounded),
              label: Text(l10n.shellSettings),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 24, 28, 20),
              child: Text(
                l10n.shellMeasurementNotice,
                style: const TextStyle(
                  color: AppColors.inkMuted,
                  fontSize: 11.5,
                  height: 1.45,
                ),
              ),
            ),
          ],
        ),
        body: IndexedStack(index: selectedIndex, children: screens),
      ),
    );
  }
}
