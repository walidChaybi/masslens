import 'package:flutter/material.dart';

import '../../../app/app_controller.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_components.dart';
import '../../guide/presentation/guide_screen.dart';
import '../../history/presentation/history_screen.dart';
import '../../home/presentation/home_screen.dart';
import '../../scale/presentation/digital_scale_screen.dart';
import '../../scan/presentation/scan_screen.dart';
import '../../settings/presentation/settings_screen.dart';

enum _AppDestination { digitalScale, aiScan, history, guide, settings }

extension on _AppDestination {
  String get label => switch (this) {
    _AppDestination.digitalScale => 'Digital Scale',
    _AppDestination.aiScan => 'AI Weight Scan',
    _AppDestination.history => 'History',
    _AppDestination.guide => 'Capture Guide',
    _AppDestination.settings => 'Settings',
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

  Future<void> _openScan({bool startWithGallery = false}) async {
    final monetization = AppScope.of(context).monetization;
    final completed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => ScanScreen(startWithGallery: startWithGallery),
      ),
    );
    if (completed == true) await monetization.onResultScreenClosed();
  }

  void _selectDestination(_AppDestination destination) {
    if (_destination == destination) return;
    setState(() => _destination = destination);
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      DigitalScaleScreen(
        onOpenAiScan: () => _selectDestination(_AppDestination.aiScan),
        onOpenMenu: () => _scaffoldKey.currentState?.openDrawer(),
      ),
      HomeScreen(
        onMeasure: _openScan,
        onGallery: () => _openScan(startWithGallery: true),
        onViewHistory: () => _selectDestination(_AppDestination.history),
      ),
      HistoryScreen(onScan: _openScan),
      GuideScreen(onScan: _openScan),
      const SettingsScreen(),
    ];
    final selectedIndex = _AppDestination.values.indexOf(_destination);

    return Scaffold(
      key: _scaffoldKey,
      appBar: _destination == _AppDestination.digitalScale
          ? null
          : AppBar(
              leading: Builder(
                builder: (context) => IconButton(
                  key: const Key('open_navigation'),
                  tooltip: 'Open navigation menu',
                  onPressed: () => Scaffold.of(context).openDrawer(),
                  icon: const Icon(Icons.menu_rounded),
                ),
              ),
              title: Text(_destination.label),
            ),
      drawer: NavigationDrawer(
        key: const Key('app_navigation_drawer'),
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) {
          Navigator.of(context).pop();
          _selectDestination(_AppDestination.values[index]);
        },
        children: const [
          Padding(
            padding: EdgeInsets.fromLTRB(24, 22, 24, 12),
            child: MassLensLogo(),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(24, 0, 24, 18),
            child: Text(
              'Choose how you want to measure.',
              style: TextStyle(
                color: AppColors.inkMuted,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
          Divider(),
          SizedBox(height: 8),
          NavigationDrawerDestination(
            key: Key('nav_digital_scale'),
            icon: Icon(Icons.scale_outlined),
            selectedIcon: Icon(Icons.scale_rounded),
            label: Text('Digital Scale'),
          ),
          NavigationDrawerDestination(
            key: Key('nav_ai_scan'),
            icon: Icon(Icons.center_focus_strong_outlined),
            selectedIcon: Icon(Icons.center_focus_strong_rounded),
            label: Text('AI Weight Scan'),
          ),
          NavigationDrawerDestination(
            key: Key('nav_history'),
            icon: Icon(Icons.history_rounded),
            selectedIcon: Icon(Icons.inventory_2_rounded),
            label: Text('History'),
          ),
          NavigationDrawerDestination(
            key: Key('nav_guide'),
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book_rounded),
            label: Text('Capture Guide'),
          ),
          NavigationDrawerDestination(
            key: Key('nav_settings'),
            icon: Icon(Icons.tune_rounded),
            selectedIcon: Icon(Icons.settings_rounded),
            label: Text('Settings'),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(28, 24, 28, 20),
            child: Text(
              'Bluetooth readings are measurements. Touch mode is a simulator; '
              'AI scans are real visual estimates.',
              style: TextStyle(
                color: AppColors.inkMuted,
                fontSize: 11.5,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
      body: IndexedStack(index: selectedIndex, children: screens),
    );
  }
}
