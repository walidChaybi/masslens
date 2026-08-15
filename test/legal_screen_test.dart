import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mass_lens/core/theme/app_theme.dart';
import 'package:mass_lens/features/legal/presentation/legal_screen.dart';
import 'package:mass_lens/l10n/l10n.dart';

Widget _testApp({
  Locale locale = const Locale('en'),
  TextScaler textScaler = TextScaler.noScaling,
}) => MaterialApp(
  key: ValueKey(locale.languageCode),
  locale: locale,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  theme: buildAppTheme(),
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(textScaler: textScaler),
    child: child!,
  ),
  home: const LegalScreen(),
);

void main() {
  testWidgets('legal center switches between privacy and terms', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(_testApp());
    await tester.pumpAndSettle();

    expect(find.text('Photos and AI analysis'), findsOneWidget);
    expect(find.text('Estimates, nutrition, and safety'), findsNothing);
    expect(find.textContaining('Next Vision'), findsNothing);
    expect(find.textContaining('Calo'), findsNothing);

    await tester.tap(find.text('Terms of use'));
    await tester.pumpAndSettle();

    expect(find.text('Estimates, nutrition, and safety'), findsOneWidget);
    expect(find.text('Photos and AI analysis'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('legal center is localized in French and Spanish', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      _testApp(
        locale: const Locale('fr'),
        textScaler: const TextScaler.linear(1.5),
      ),
    );
    await tester.pumpAndSettle();
    await tester.drag(
      find.byKey(const Key('legal_document_scroll')),
      const Offset(0, -300),
    );
    await tester.pumpAndSettle();
    expect(find.text('Photos et analyse par IA'), findsOneWidget);
    expect(find.text('Conditions'), findsOneWidget);

    await tester.pumpWidget(
      _testApp(
        locale: const Locale('es'),
        textScaler: const TextScaler.linear(1.5),
      ),
    );
    await tester.pumpAndSettle();
    await tester.drag(
      find.byKey(const Key('legal_document_scroll')),
      const Offset(0, -300),
    );
    await tester.pumpAndSettle();
    expect(find.text('Fotos y análisis con IA'), findsOneWidget);
    expect(find.text('Condiciones'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
