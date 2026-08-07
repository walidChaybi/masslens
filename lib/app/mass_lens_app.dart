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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(widget.controller.showAppOpenAdIfAvailable());
    }
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
        home: const AppShell(),
      ),
    );
  }
}
