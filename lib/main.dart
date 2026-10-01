import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app/launch_gate.dart';
import 'core/theme/app_theme.dart';
import 'features/monetization/data/monetization_config.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  MonetizationConfig.validateProduction();
  // System UI setup and local data loading no longer hold back the first
  // frame; LaunchGate paints the splash immediately.
  unawaited(
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]),
  );
  unawaited(SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge));
  // The saved appearance is not loaded yet; MassLensApp corrects the bars a
  // frame later if the user pinned light or dark.
  SystemChrome.setSystemUIOverlayStyle(
    systemUiOverlayStyleFor(
      WidgetsBinding.instance.platformDispatcher.platformBrightness,
    ),
  );
  runApp(const LaunchGate());
}
