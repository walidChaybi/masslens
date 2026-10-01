import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mass_lens/features/monetization/domain/access_status.dart';
import 'package:mass_lens/features/monetization/presentation/access_card.dart';
import 'package:mass_lens/l10n/display_labels.dart';
import 'package:mass_lens/l10n/l10n.dart';

void main() {
  testWidgets('scan balance and action fit narrow screens in every language', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    for (final locale in AppLocalizations.supportedLocales) {
      for (final scale in [1.0, 1.6]) {
        final access = AccessStatus.fromJson({
          'scanAccessEnforced': true,
          'remainingScans': 0,
          'adsEnabled': true,
        });
        await tester.pumpWidget(
          MaterialApp(
            locale: locale,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(scale)),
              child: child!,
            ),
            home: Scaffold(
              body: Padding(
                padding: const EdgeInsets.all(20),
                child: AccessCard(
                  access: access,
                  onManage: () {},
                  onRewardedAd: () {},
                  rewardedAdReady: true,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final l10n = await AppLocalizations.delegate.load(locale);
        expect(find.text(l10n.accessScansLeft(0)), findsOneWidget);
        expect(find.text(l10n.accessGetFreeScan), findsOneWidget);
        expect(tester.takeException(), isNull);
        final button = tester.getRect(find.byKey(const Key('access_watch_ad')));
        expect(button.left, greaterThanOrEqualTo(20));
        expect(button.right, lessThanOrEqualTo(300));
      }
    }
  });

  test(
    'debug unlimited status is consistent in shared balance labels',
    () async {
      final access = AccessStatus.fromJson({
        'scanAccessEnforced': true,
        'remainingScans': 0,
        'debugUnlimited': true,
        'adsEnabled': true,
      });
      for (final locale in AppLocalizations.supportedLocales) {
        final l10n = await AppLocalizations.delegate.load(locale);
        expect(localizedScanUsage(l10n, access), l10n.accessUnlimitedScans);
      }
      expect(access.canScan, isTrue);
      expect(access.adsEnabled, isTrue);
    },
  );
}
