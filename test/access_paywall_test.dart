import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mass_lens/app/app_controller.dart';
import 'package:mass_lens/core/theme/app_theme.dart';
import 'package:mass_lens/features/legal/presentation/legal_screen.dart';
import 'package:mass_lens/features/measurements/data/measurement_store.dart';
import 'package:mass_lens/features/monetization/application/monetization_controller.dart';
import 'package:mass_lens/features/monetization/data/app_ad_service.dart';
import 'package:mass_lens/features/monetization/data/monetization_api.dart';
import 'package:mass_lens/features/monetization/data/play_billing_service.dart';
import 'package:mass_lens/features/monetization/domain/access_status.dart';
import 'package:mass_lens/features/monetization/presentation/access_paywall.dart';
import 'package:mass_lens/features/monetization/presentation/rewarded_scan_sheet.dart';
import 'package:mass_lens/l10n/l10n.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('store price enables one purchase after loading', (tester) async {
    final fixture = _PaywallFixture(loading: true, price: '');
    addTearDown(fixture.controller.dispose);
    await fixture.monetization.initialize();
    await tester.pumpWidget(_testApp(fixture.controller));
    await tester.pump();

    final purchase = find.byKey(const Key('buy_lifetime_unlock'));
    expect(purchase, findsOneWidget);
    expect(tester.widget<FilledButton>(purchase).onPressed, isNull);
    expect(find.byKey(const Key('paywall_scale_hero')), findsNothing);
    expect(find.byKey(const Key('paywall_luggage_hero')), findsOneWidget);
    expect(find.text('2–4 kg'), findsOneWidget);
    expect(find.textContaining('40 AI scans/day'), findsNothing);

    fixture.billing.setProduct(price: '12,99 €');
    await tester.pump();

    expect(find.byKey(const Key('paywall_store_price')), findsOneWidget);
    expect(find.textContaining('12,99 €'), findsOneWidget);
    expect(tester.widget<FilledButton>(purchase).onPressed, isNotNull);

    fixture.billing.setProduct(
      price: '',
      message: 'Store temporarily unavailable.',
    );
    await tester.pump();

    expect(tester.widget<FilledButton>(purchase).onPressed, isNull);
    expect(find.textContaining('12,99 €'), findsNothing);
    expect(find.text('Store temporarily unavailable.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'unsupported billing leaves purchase disabled and skip available',
    (tester) async {
      final controller = AppController(
        measurementStore: const MeasurementStore(),
      );
      addTearDown(controller.dispose);
      var skipped = false;
      await tester.pumpWidget(
        _testApp(
          controller,
          child: AccessPaywall(showSkip: true, onSkip: () => skipped = true),
        ),
      );
      await tester.pump();

      expect(
        tester
            .widget<FilledButton>(find.byKey(const Key('buy_lifetime_unlock')))
            .onPressed,
        isNull,
      );
      await tester.tap(find.byKey(const Key('paywall_skip')));
      expect(skipped, isTrue);
    },
  );

  for (final restore in [false, true]) {
    testWidgets(
      'delayed ${restore ? 'restore' : 'purchase'} entitlement closes the sheet once',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(390, 844));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final fixture = _PaywallFixture();
        addTearDown(fixture.controller.dispose);
        await fixture.monetization.initialize();
        final results = <bool>[];
        await tester.pumpWidget(
          _testApp(
            fixture.controller,
            child: Builder(
              builder: (context) => Center(
                child: FilledButton(
                  key: const Key('open_test_paywall'),
                  onPressed: () async {
                    results.add(await showPremiumAccessSheet(context));
                  },
                  child: const Text('Open paywall'),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.byKey(const Key('open_test_paywall')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));

        final action = find.byKey(
          Key(restore ? 'restore_lifetime_purchases' : 'buy_lifetime_unlock'),
        );
        await tester.ensureVisible(action);
        await tester.tap(action);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(fixture.billing.buyCount, restore ? 0 : 1);
        expect(fixture.billing.restoreCount, restore ? 1 : 0);
        expect(results, isEmpty);
        expect(find.byType(AccessPaywall), findsOneWidget);

        // Play returns from starting the action before stream verification.
        await fixture.billing.grantLifetime();
        await tester.pump();
        await tester.pumpAndSettle();

        expect(results, [true]);
        expect(find.byType(AccessPaywall), findsNothing);
        expect(find.byKey(const Key('open_test_paywall')), findsOneWidget);

        // Repeated store/access notifications must not pop the underlying route.
        await fixture.billing.grantLifetime();
        await tester.pump();
        expect(results, [true]);
        expect(find.byKey(const Key('open_test_paywall')), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('terms and privacy open their matching legal documents', (
    tester,
  ) async {
    final controller = AppController(
      measurementStore: const MeasurementStore(),
    );
    addTearDown(controller.dispose);
    await tester.pumpWidget(_testApp(controller));
    await tester.pump();

    for (final entry in const [
      ('paywall_terms', LegalDocument.termsOfUse),
      ('paywall_privacy', LegalDocument.privacyPolicy),
    ]) {
      final link = find.byKey(Key(entry.$1));
      await tester.ensureVisible(link);
      await tester.tap(link);
      await tester.pumpAndSettle();

      expect(
        tester.widget<LegalScreen>(find.byType(LegalScreen)).initialDocument,
        entry.$2,
      );
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.byType(AccessPaywall), findsOneWidget);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'lifetime offer shows only the store price with no gift discount',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final fixture = _PaywallFixture();
      addTearDown(fixture.controller.dispose);
      await fixture.monetization.initialize();
      await tester.pumpWidget(_testApp(fixture.controller));
      await tester.pump();

      expect(find.byKey(const Key('paywall_gift_badge')), findsNothing);
      expect(find.text('30% off'), findsNothing);
      expect(find.textContaining('Your prize'), findsNothing);
      expect(find.text('Unlock lifetime access'), findsOneWidget);
      expect(find.byKey(const Key('paywall_store_price')), findsOneWidget);
      expect(find.text(r'$9.99'), findsOneWidget);
      expect(find.byKey(const Key('paywall_gift_was_price')), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'compact paywall scrolls with large text above navigation insets',
    (tester) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));
      for (final configuration in const [
        (Size(360, 520), 1.5),
        (Size(320, 568), 2.0),
      ]) {
        await tester.binding.setSurfaceSize(configuration.$1);
        final fixture = _PaywallFixture();
        addTearDown(fixture.controller.dispose);
        await fixture.monetization.initialize();
        await tester.pumpWidget(
          _testApp(
            fixture.controller,
            textScaler: TextScaler.linear(configuration.$2),
            insets: const EdgeInsets.only(top: 24, bottom: 48),
          ),
        );
        await tester.pump();

        final purchase = find.byKey(const Key('buy_lifetime_unlock'));
        expect(purchase.hitTestable(), findsOneWidget);
        final purchaseRect = tester.getRect(purchase);
        expect(
          purchaseRect.bottom,
          lessThanOrEqualTo(configuration.$1.height - 48),
        );
        expect(purchaseRect.left, greaterThanOrEqualTo(0));
        expect(purchaseRect.right, lessThanOrEqualTo(configuration.$1.width));
        expect(tester.takeException(), isNull);

        final scroll = find.byKey(const Key('paywall_scroll'));
        expect(scroll, findsOneWidget);
        await tester.drag(scroll, const Offset(0, -500));
        await tester.pumpAndSettle();
        expect(purchase.hitTestable(), findsOneWidget);
        expect(tester.takeException(), isNull);

        await tester.pumpWidget(const SizedBox());
      }
    },
  );
}

Widget _testApp(
  AppController controller, {
  Widget child = const AccessPaywall(showSkip: true),
  TextScaler textScaler = TextScaler.noScaling,
  EdgeInsets insets = EdgeInsets.zero,
}) => AppScope(
  controller: controller,
  child: MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    theme: buildAppTheme(),
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: textScaler, padding: insets, viewPadding: insets),
      child: child!,
    ),
    home: Scaffold(body: child),
  ),
);

class _PaywallFixture {
  _PaywallFixture({bool loading = false, String price = r'$9.99'}) {
    api = _FakeMonetizationApi();
    billing = _FakeBillingService(api: api, loading: loading, price: price);
    monetization = MonetizationController.forTesting(
      api: api,
      adService: _FakeAdService(),
      billingService: billing,
    );
    controller = AppController(
      measurementStore: const MeasurementStore(),
      onboardingComplete: true,
      appUnlockedThisSession: true,
      monetizationController: monetization,
    );
  }

  late final _FakeMonetizationApi api;
  late final _FakeBillingService billing;
  late final MonetizationController monetization;
  late final AppController controller;
}

class _FakeMonetizationApi extends MonetizationApi {
  _FakeMonetizationApi() : super(apiUrl: 'https://example.invalid');

  bool hasLifetime = false;

  @override
  Future<AccessStatus> getAccess(String clientId) async =>
      AccessStatus.fromJson({
        'hasLifetime': hasLifetime,
        'scanAccessEnforced': true,
        'adsEnabled': false,
      });
}

class _FakeBillingService extends PlayBillingService {
  _FakeBillingService({
    required _FakeMonetizationApi api,
    required bool loading,
    required String price,
  }) : _fakeApi = api,
       _loading = loading,
       _price = price,
       super(api: api);

  final _FakeMonetizationApi _fakeApi;
  bool _loading;
  String _price;
  double? _rawPrice = 9.99;
  final String _currencyCode = 'USD';
  String? _billingMessage;
  Future<void> Function()? _entitlementChanged;
  VoidCallback? _changed;
  int buyCount = 0;
  int restoreCount = 0;

  @override
  bool get storeAvailable => true;
  @override
  bool get loadingProduct => _loading;
  @override
  bool get productQueryCompleted => !_loading;
  @override
  String get lifetimePriceLabel => _price;
  @override
  double? get lifetimeRawPrice => _rawPrice;
  @override
  String get lifetimeCurrencyCode => _currencyCode;
  @override
  String? get message => _billingMessage;

  @override
  Future<void> initialize({
    required String clientId,
    Future<void> Function()? onEntitlementChanged,
    VoidCallback? onChanged,
  }) async {
    _entitlementChanged = onEntitlementChanged;
    _changed = onChanged;
  }

  void setProduct({required String price, String? message, double? rawPrice}) {
    _loading = false;
    _price = price;
    _rawPrice = rawPrice ?? (price.isEmpty ? null : _rawPrice);
    _billingMessage = message;
    _changed?.call();
  }

  @override
  Future<void> refreshProductDetails() async {}

  @override
  Future<bool> buyLifetime() async {
    buyCount += 1;
    return true;
  }

  @override
  Future<void> restorePurchases() async {
    restoreCount += 1;
  }

  Future<void> grantLifetime() async {
    _fakeApi.hasLifetime = true;
    await _entitlementChanged?.call();
    _changed?.call();
  }

  @override
  void dispose() {
    _entitlementChanged = null;
    _changed = null;
  }
}

class _FakeAdService extends AppAdService {
  @override
  Future<void> updatePlan({
    required bool adsAllowed,
    required AdPolicy policy,
  }) async {}

  @override
  void dispose() {}
}
