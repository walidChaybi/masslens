import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app/app_controller.dart';
import 'app/mass_lens_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Color(0xFFFFFDF8),
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  final controller = await AppController.bootstrap();
  runApp(MassLensApp(controller: controller));
  unawaited(controller.initializeMonetization(showAppOpenAdOnStart: true));
}
