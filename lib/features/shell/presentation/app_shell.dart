import 'package:flutter/material.dart';

import '../../../app/app_controller.dart';
import '../../../core/theme/app_theme.dart';
import '../../guide/presentation/guide_screen.dart';
import '../../history/presentation/history_screen.dart';
import '../../home/presentation/home_screen.dart';
import '../../monetization/presentation/paywall_sheet.dart';
import '../../scan/presentation/scan_screen.dart';
import '../../settings/presentation/settings_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  Future<void> _openScan() async {
    final monetization = AppScope.of(context).monetization;
    await monetization.refreshAccess();
    if (!mounted) return;
    if (!monetization.access.canScan) {
      await showMassLensPaywall(context);
      return;
    }
    final completed = await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute<bool>(builder: (_) => ScanScreen()));
    if (completed == true) await monetization.onScanCompleted();
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(
        onScan: _openScan,
        onViewHistory: () => setState(() => _index = 1),
      ),
      HistoryScreen(onScan: _openScan),
      GuideScreen(onScan: _openScan),
      const SettingsScreen(),
    ];

    return Scaffold(
      extendBody: false,
      body: IndexedStack(index: _index, children: screens),
      bottomNavigationBar: BottomAppBar(
        height: 76,
        padding: EdgeInsets.zero,
        color: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shadowColor: AppColors.ink.withValues(alpha: 0.15),
        child: Row(
          children: [
            Expanded(
              child: _NavigationItem(
                key: const Key('nav_home'),
                icon: Icons.home_outlined,
                selectedIcon: Icons.home_rounded,
                label: 'Home',
                selected: _index == 0,
                onTap: () => setState(() => _index = 0),
              ),
            ),
            Expanded(
              child: _NavigationItem(
                key: const Key('nav_history'),
                icon: Icons.history_rounded,
                selectedIcon: Icons.inventory_2_rounded,
                label: 'History',
                selected: _index == 1,
                onTap: () => setState(() => _index = 1),
              ),
            ),
            Expanded(child: _ScanNavigationItem(onTap: _openScan)),
            Expanded(
              child: _NavigationItem(
                key: const Key('nav_guide'),
                icon: Icons.menu_book_outlined,
                selectedIcon: Icons.menu_book_rounded,
                label: 'Guide',
                selected: _index == 2,
                onTap: () => setState(() => _index = 2),
              ),
            ),
            Expanded(
              child: _NavigationItem(
                key: const Key('nav_settings'),
                icon: Icons.tune_rounded,
                selectedIcon: Icons.settings_rounded,
                label: 'Settings',
                selected: _index == 3,
                onTap: () => setState(() => _index = 3),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScanNavigationItem extends StatelessWidget {
  const _ScanNavigationItem({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      key: const Key('shell_scan_button'),
      onTap: onTap,
      radius: 32,
      child: Semantics(
        button: true,
        label: 'Start a new estimate',
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.ink,
                borderRadius: BorderRadius.all(Radius.circular(13)),
              ),
              child: SizedBox(
                key: Key('shell_scan_icon'),
                width: 40,
                height: 34,
                child: Icon(
                  Icons.center_focus_strong_rounded,
                  size: 21,
                  color: AppColors.lime,
                ),
              ),
            ),
            SizedBox(height: 3),
            Text(
              'Scan',
              style: TextStyle(
                color: AppColors.ink,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavigationItem extends StatelessWidget {
  const _NavigationItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: onTap,
      radius: 34,
      child: Semantics(
        button: true,
        selected: selected,
        label: label,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 38,
              height: 31,
              decoration: BoxDecoration(
                color: selected ? AppColors.lime : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                selected ? selectedIcon : icon,
                size: 21,
                color: selected ? AppColors.ink : AppColors.inkMuted,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                color: selected ? AppColors.ink : AppColors.inkMuted,
                fontSize: 10,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
