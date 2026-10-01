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
import '../../monetization/presentation/premium_cta.dart';
import '../../monetization/presentation/rewarded_scan_sheet.dart';
import '../../nutrition/presentation/nutrition_screen.dart';
import '../../reminders/presentation/meal_reminder_widgets.dart';
import '../../scan/presentation/scan_screen.dart';
import '../../settings/presentation/settings_screen.dart';

enum _AppDestination { aiScan, nutrition, history, guide, settings }

extension on _AppDestination {
  String label(AppLocalizations l10n) => switch (this) {
    _AppDestination.aiScan => l10n.shellAiWeightScan,
    _AppDestination.nutrition => l10n.shellNutrition,
    _AppDestination.history => l10n.shellHistory,
    _AppDestination.guide => l10n.shellCaptureGuide,
    _AppDestination.settings => l10n.shellSettings,
  };

  /// Short, single-line label for the bottom navigation bar.
  String shortLabel(AppLocalizations l10n) => switch (this) {
    _AppDestination.aiScan => l10n.navScanShort,
    _AppDestination.nutrition => l10n.shellNutrition,
    _AppDestination.history => l10n.shellHistory,
    _AppDestination.guide => l10n.navGuideShort,
    _AppDestination.settings => l10n.shellSettings,
  };

  String get navKey => switch (this) {
    _AppDestination.aiScan => 'nav_ai_scan',
    _AppDestination.nutrition => 'nav_nutrition',
    _AppDestination.history => 'nav_history',
    _AppDestination.guide => 'nav_guide',
    _AppDestination.settings => 'nav_settings',
  };

  IconData get icon => switch (this) {
    _AppDestination.aiScan => Icons.center_focus_strong_outlined,
    _AppDestination.nutrition => Icons.restaurant_outlined,
    _AppDestination.history => Icons.history_rounded,
    _AppDestination.guide => Icons.menu_book_outlined,
    _AppDestination.settings => Icons.tune_rounded,
  };

  IconData get selectedIcon => switch (this) {
    _AppDestination.aiScan => Icons.center_focus_strong_rounded,
    _AppDestination.nutrition => Icons.restaurant_rounded,
    _AppDestination.history => Icons.history_rounded,
    _AppDestination.guide => Icons.menu_book_rounded,
    _AppDestination.settings => Icons.settings_rounded,
  };
}

/// Destinations shown in the bottom bar (settings lives in the drawer only).
const _barDestinations = [
  _AppDestination.aiScan,
  _AppDestination.nutrition,
  _AppDestination.history,
  _AppDestination.guide,
];

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  _AppDestination _destination = _AppDestination.aiScan;
  bool _drawerTransitionBusy = false;
  bool _drawerOpen = false;
  bool _exitConfirmationVisible = false;
  bool _remindersSynced = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_remindersSynced) return;
    _remindersSynced = true;
    // Alarms are cleared by force-stop; re-apply with the current language.
    unawaited(
      AppScope.of(context).mealReminders.resync(mealReminderText(context.l10n)),
    );
  }

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

  Future<void> _openScan({bool startWithGallery = false}) async {
    final appController = AppScope.of(context);
    final monetization = appController.monetization;
    if (monetization.access.isAuthoritative &&
        monetization.access.scanAccessEnforced &&
        !monetization.access.canScan) {
      final added = await showRewardedScanSheet(context);
      if (!mounted || !added || !monetization.access.canScan) return;
    }
    if (!mounted) return;
    final completed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => ScanScreen(startWithGallery: startWithGallery),
      ),
    );
    if (completed == true) {
      await monetization.onResultScreenClosed();
      await appController.maybeRequestPostScanReview();
    }
  }

  Future<void> _openNutritionScan({bool startWithGallery = false}) async {
    final appController = AppScope.of(context);
    final monetization = appController.monetization;
    if (monetization.access.isAuthoritative &&
        monetization.access.scanAccessEnforced &&
        !monetization.access.canScan) {
      final added = await showRewardedScanSheet(context);
      if (!mounted || !added || !monetization.access.canScan) return;
    }
    if (!mounted) return;
    final completed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => NutritionScanScreen(startWithGallery: startWithGallery),
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

  Future<void> _closeDrawerThen(Future<void> Function() action) async {
    Navigator.of(context).pop();
    await Future<void>.delayed(const Duration(milliseconds: 260));
    if (!mounted) return;
    await action();
  }

  Future<void> _openDrawerUpgrade() => _closeDrawerThen(() async {
    await showPremiumAccessSheet(context);
  });

  Future<void> _openDrawerWatchAd() => _closeDrawerThen(() async {
    await showRewardedScanSheet(context);
  });

  Future<void> _handleDestinationSelected(
    _AppDestination destination, {
    bool fromDrawer = false,
  }) async {
    if (fromDrawer) {
      Navigator.of(context).pop();
    }
    if (_destination == destination || _drawerTransitionBusy) return;
    final monetization = AppScope.of(context).monetization;
    _drawerTransitionBusy = true;
    try {
      if (fromDrawer) {
        // Let the drawer finish closing before presenting a full-screen ad.
        await Future<void>.delayed(const Duration(milliseconds: 260));
      }
      if (!mounted) return;
      if (destination == _AppDestination.aiScan) {
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
      HomeScreen(
        onMeasure: _openScan,
        onGallery: () => _openScan(startWithGallery: true),
        onViewHistory: () => _selectDestination(_AppDestination.history),
        onOpenNutrition: () => _selectDestination(_AppDestination.nutrition),
      ),
      NutritionScreen(
        onScan: _openNutritionScan,
        onGallery: () => _openNutritionScan(startWithGallery: true),
      ),
      HistoryScreen(onScan: _openScan),
      GuideScreen(onScan: _openScan),
      const SettingsScreen(),
    ];
    final selectedIndex = _AppDestination.values.indexOf(_destination);
    final barIndex = _barDestinations.indexOf(_destination);

    return PopScope<void>(
      canPop: _drawerOpen,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) unawaited(_confirmExit());
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: systemUiOverlayStyleFor(Theme.of(context).brightness),
        child: Scaffold(
          key: _scaffoldKey,
          onDrawerChanged: (isOpened) {
            if (mounted) setState(() => _drawerOpen = isOpened);
          },
          drawer: NavigationDrawer(
            key: const Key('app_navigation_drawer'),
            backgroundColor: context.palette.surface,
            indicatorColor: context.palette.lime,
            indicatorShape: const StadiumBorder(),
            selectedIndex: _destination.index,
            onDestinationSelected: (index) {
              unawaited(
                _handleDestinationSelected(
                  _AppDestination.values[index],
                  fromDrawer: true,
                ),
              );
            },
            children: [
              const _DrawerHeader(),
              const SizedBox(height: 6),
              for (final destination in _AppDestination.values) ...[
                if (destination == _AppDestination.settings)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 28, vertical: 8),
                    child: Divider(),
                  ),
                NavigationDrawerDestination(
                  key: Key(destination.navKey),
                  icon: Icon(destination.icon),
                  selectedIcon: Icon(destination.selectedIcon),
                  label: Text(destination.label(l10n)),
                ),
              ],
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: DrawerMonetizationFooter(
                  monetization: AppScope.of(context).monetization,
                  onUpgrade: () => unawaited(_openDrawerUpgrade()),
                  onWatchAd: () => unawaited(_openDrawerWatchAd()),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 10, 28, 24),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(top: 1),
                      child: Icon(
                        Icons.info_outline_rounded,
                        size: 15,
                        color: context.palette.inkMuted,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l10n.shellMeasurementNotice,
                        style: TextStyle(
                          color: context.palette.inkMuted,
                          fontSize: 11.5,
                          height: 1.45,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: barIndex < 0 ? 0 : barIndex,
            onDestinationSelected: (index) {
              unawaited(_handleDestinationSelected(_barDestinations[index]));
            },
            destinations: [
              for (final destination in _barDestinations)
                NavigationDestination(
                  icon: Icon(destination.icon),
                  selectedIcon: Icon(destination.selectedIcon),
                  label: destination.shortLabel(l10n),
                  tooltip: destination.label(l10n),
                ),
            ],
          ),
          body: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                SliverAppBar(
                  floating: true,
                  pinned: false,
                  toolbarHeight: 64,
                  titleSpacing: 2,
                  clipBehavior: Clip.none,
                  leading: Builder(
                    builder: (context) => IconButton(
                      key: const Key('open_navigation'),
                      tooltip: l10n.shellOpenNavigationMenu,
                      onPressed: () => Scaffold.of(context).openDrawer(),
                      icon: const Icon(Icons.menu_rounded),
                    ),
                  ),
                  // Each screen owns its own headline; keep the app bar branded.
                  title: MassLensLogo(
                    compact: true,
                    markSize: 34,
                    showWordmark: MediaQuery.sizeOf(context).width >= 360,
                  ),
                ),
              ];
            },
            body: IndexedStack(index: selectedIndex, children: screens),
          ),
        ),
      ),
    );
  }
}

class _DrawerHeader extends StatelessWidget {
  const _DrawerHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [context.palette.inkRaised, context.palette.inkDeep],
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: InstrumentCorners(
                color: context.palette.lime.withValues(alpha: 0.55),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: context.palette.lime,
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: Text(
                          'M',
                          style: TextStyle(
                            color: context.palette.onLime,
                            fontSize: 21,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Flexible(
                        child: Text(
                          'MassLens',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    context.l10n.shellChooseMode,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: context.palette.onInkMuted,
                      fontSize: 12,
                      height: 1.3,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
