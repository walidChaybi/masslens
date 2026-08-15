import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mass_lens/app/app_controller.dart';
import 'package:mass_lens/core/theme/app_theme.dart';
import 'package:mass_lens/features/measurements/data/measurement_store.dart';
import 'package:mass_lens/features/shell/presentation/app_shell.dart';
import 'package:mass_lens/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('root Android Back asks before exiting and No keeps app open', (
    tester,
  ) async {
    var systemExitCalls = 0;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'SystemNavigator.pop') systemExitCalls += 1;
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    final controller = await _pumpShell(tester);
    addTearDown(controller.dispose);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('exit_confirmation_dialog')), findsOneWidget);
    expect(find.text('Exit MassLens?'), findsOneWidget);
    expect(find.text('Are you sure you want to exit the app?'), findsOneWidget);

    await tester.tap(find.byKey(const Key('exit_confirmation_no')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('exit_confirmation_dialog')), findsNothing);
    expect(find.byKey(const Key('digital_scale_screen')), findsOneWidget);
    expect(systemExitCalls, 0);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('exit_confirmation_ok')));
    await tester.pumpAndSettle();

    expect(systemExitCalls, 1);
  });

  testWidgets('exit confirmation is localized in French and Spanish', (
    tester,
  ) async {
    for (final entry in const [
      (
        Locale('fr'),
        'Quitter MassLens ?',
        'Voulez-vous vraiment quitter l’application ?',
        'Non',
      ),
      (
        Locale('es'),
        '¿Salir de MassLens?',
        '¿Seguro que quieres salir de la aplicación?',
        'No',
      ),
    ]) {
      final controller = await _pumpShell(tester, locale: entry.$1);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(find.text(entry.$2), findsOneWidget);
      expect(find.text(entry.$3), findsOneWidget);
      expect(find.text(entry.$4), findsOneWidget);
      expect(find.text('OK'), findsOneWidget);

      await tester.tap(find.byKey(const Key('exit_confirmation_no')));
      await tester.pumpAndSettle();
      controller.dispose();
    }
  });

  testWidgets('Back closes the navigation drawer without showing exit prompt', (
    tester,
  ) async {
    final controller = await _pumpShell(tester);
    addTearDown(controller.dispose);

    await tester.tap(find.byKey(const Key('open_navigation')));
    await tester.pumpAndSettle();
    final scaffold = tester.state<ScaffoldState>(find.byType(Scaffold).first);
    expect(scaffold.isDrawerOpen, isTrue);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(scaffold.isDrawerOpen, isFalse);
    expect(find.byKey(const Key('exit_confirmation_dialog')), findsNothing);
  });

  testWidgets('Back pops a nested route before asking to exit', (tester) async {
    final controller = await _pumpShell(tester);
    addTearDown(controller.dispose);
    final shellContext = tester.element(find.byType(AppShell));
    Navigator.of(shellContext).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => const Scaffold(
          body: Center(child: Text('Nested route', key: Key('nested_route'))),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('nested_route')), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('nested_route')), findsNothing);
    expect(find.byKey(const Key('exit_confirmation_dialog')), findsNothing);
    expect(find.byKey(const Key('digital_scale_screen')), findsOneWidget);
  });

  testWidgets('exit dialog fits compact Samsung-style safe content', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(360, 640));
    final controller = await _pumpShell(tester, textScaleFactor: 1.5);
    addTearDown(controller.dispose);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('exit_confirmation_dialog')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Future<AppController> _pumpShell(
  WidgetTester tester, {
  Locale locale = const Locale('en'),
  double textScaleFactor = 1,
}) async {
  final controller = AppController(
    measurementStore: const MeasurementStore(),
    onboardingComplete: true,
  );
  await tester.pumpWidget(
    AppScope(
      controller: controller,
      child: MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: buildAppTheme(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScaleFactor),
            padding: const EdgeInsets.only(bottom: 48),
            viewPadding: const EdgeInsets.only(bottom: 48),
          ),
          child: child!,
        ),
        home: const AppShell(),
      ),
    ),
  );
  await tester.pump();
  return controller;
}
