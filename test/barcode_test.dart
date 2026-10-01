import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mass_lens/app/app_controller.dart';
import 'package:mass_lens/features/barcode/data/barcode_lookup_service.dart';
import 'package:mass_lens/features/barcode/data/recent_products_store.dart';
import 'package:mass_lens/features/barcode/domain/food_product.dart';
import 'package:mass_lens/features/measurements/data/measurement_store.dart';
import 'package:mass_lens/features/measurements/domain/measurement.dart';
import 'package:mass_lens/features/nutrition/application/nutrition_diary_controller.dart';
import 'package:mass_lens/features/nutrition/data/nutrition_log_store.dart';
import 'package:mass_lens/features/nutrition/presentation/nutrition_screen.dart';
import 'package:mass_lens/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _nutella = FoodProduct(
  barcode: '3017620422003',
  name: 'Nutella',
  brand: 'Ferrero',
  per100g: NutritionPer100g(
    caloriesKcal: 539,
    proteinGrams: 6.3,
    carbsGrams: 57.5,
    fatGrams: 30.9,
  ),
  source: FoodProductSource.openFoodFacts,
  servingGrams: 15,
  packageGrams: 400,
);

Map<String, Object?> _offResponse({
  Map<String, Object?> nutriments = const {
    'energy-kcal_100g': 539,
    'proteins_100g': 6.3,
    'carbohydrates_100g': 57.5,
    'fat_100g': 30.9,
  },
  Map<String, Object?> extra = const {},
}) => {
  'code': '3017620422003',
  'status': 1,
  'product': {
    'product_name': 'Nutella',
    'product_name_fr': 'Pâte à tartiner Nutella',
    'brands': 'Ferrero, Nutella',
    'nutriments': nutriments,
    'serving_quantity': '15',
    'product_quantity': 400,
    'product_quantity_unit': 'g',
    ...extra,
  },
};

class _FakeSource implements FoodProductSourceClient {
  _FakeSource(this.result, {this.fails = false});

  final FoodProduct? result;
  final bool fails;
  int calls = 0;

  @override
  Future<FoodProduct?> lookup(
    String barcode, {
    required String languageCode,
  }) async {
    calls += 1;
    if (fails) throw StateError('offline');
    return result;
  }
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('normalizeBarcode', () {
    test('accepts valid EAN-13, UPC-A and EAN-8 codes', () {
      expect(normalizeBarcode('3017620422003'), '3017620422003');
      expect(normalizeBarcode('3017 6204-22003'), '3017620422003');
      expect(normalizeBarcode('009800800056'), '009800800056');
      expect(normalizeBarcode('96385074'), '96385074');
    });

    test('rejects wrong check digits and lengths', () {
      expect(normalizeBarcode('3017620422004'), isNull);
      expect(normalizeBarcode('12345'), isNull);
      expect(normalizeBarcode('abcdefghijklm'), isNull);
    });

    test('expands UPC-E to UPC-A', () {
      expect(expandUpcE('04252614'), '042100005264');
      expect(normalizeBarcode('04252614'), '042100005264');
    });
  });

  group('Open Food Facts parsing', () {
    test('maps label nutrition, localized name, brand and sizes', () {
      final product = foodProductFromOpenFoodFacts(
        _offResponse(),
        barcode: '3017620422003',
        languageCode: 'fr',
      )!;
      expect(product.name, 'Pâte à tartiner Nutella');
      expect(product.brand, 'Ferrero');
      expect(product.per100g.caloriesKcal, 539);
      expect(product.per100g.fatGrams, 30.9);
      expect(product.servingGrams, 15);
      expect(product.packageGrams, 400);
      expect(product.isLiquid, isFalse);
      expect(product.hasPartialNutrition, isFalse);
      expect(product.source, FoodProductSource.openFoodFacts);
    });

    test('converts kJ when kcal is missing and flags missing macros', () {
      final product = foodProductFromOpenFoodFacts(
        _offResponse(
          nutriments: const {'energy_100g': 1799, 'fat_100g': '30,9'},
          extra: const {'product_quantity_unit': 'ml'},
        ),
        barcode: '3017620422003',
      )!;
      expect(product.per100g.caloriesKcal, closeTo(430, 0.5));
      expect(product.per100g.fatGrams, 30.9);
      expect(product.hasPartialNutrition, isTrue);
      expect(product.isLiquid, isTrue);
      expect(product.unit, 'ml');
    });

    test('returns null for unknown or implausible products', () {
      expect(
        foodProductFromOpenFoodFacts(const {
          'status': 0,
          'status_verbose': 'product not found',
        }, barcode: '3017620422003'),
        isNull,
      );
      expect(
        foodProductFromOpenFoodFacts(
          _offResponse(nutriments: const {'energy-kcal_100g': 5390}),
          barcode: '3017620422003',
        ),
        isNull,
      );
      expect(
        foodProductFromOpenFoodFacts(
          _offResponse(nutriments: const {'proteins_100g': 5}),
          barcode: '3017620422003',
        ),
        isNull,
      );
    });

    test('requests only needed fields and identifies the app', () async {
      late Uri requested;
      late Map<String, String> sentHeaders;
      final client = OpenFoodFactsClient(
        getJson: (uri, headers) async {
          requested = uri;
          sentHeaders = headers;
          return (200, _offResponse());
        },
      );
      final product = await client.lookup('3017620422003', languageCode: 'es');
      expect(product?.name, 'Nutella');
      expect(requested.host, 'world.openfoodfacts.org');
      expect(requested.path, '/api/v2/product/3017620422003.json');
      expect(requested.queryParameters['fields'], contains('nutriments'));
      expect(requested.queryParameters['fields'], contains('product_name_es'));
      expect(sentHeaders['user-agent'], startsWith('MassLens'));
    });
  });

  group('BarcodeLookupService', () {
    test('falls back to the USDA source when Open Food Facts misses', () async {
      final off = _FakeSource(null);
      final usda = _FakeSource(_nutella);
      final service = BarcodeLookupService(sources: [off, usda]);
      final result = await service.lookup('3017620422003');
      expect(result.status, BarcodeLookupStatus.found);
      expect(result.product?.name, 'Nutella');

      // Found products are cached for the session.
      await service.lookup('3017620422003');
      expect(off.calls, 1);
      expect(usda.calls, 1);
    });

    test('distinguishes not found from unavailable', () async {
      final notFound = BarcodeLookupService(
        sources: [_FakeSource(null), _FakeSource(null)],
      );
      expect(
        (await notFound.lookup('3017620422003')).status,
        BarcodeLookupStatus.notFound,
      );
      final offline = BarcodeLookupService(
        sources: [_FakeSource(null, fails: true), _FakeSource(null)],
      );
      expect(
        (await offline.lookup('3017620422003')).status,
        BarcodeLookupStatus.unavailable,
      );
    });

    test('worker client reads the USDA fallback payload', () async {
      late Uri requested;
      final client = MassLensBarcodeClient(
        apiUrl: 'https://api.example/estimate',
        clientId: () async => 'client_identifier_000000001',
        getJson: (uri, headers) async {
          requested = uri;
          expect(headers['X-MassLens-Client-ID'], isNotEmpty);
          return (
            200,
            {
              'status': 'found',
              'product': {..._nutella.toJson(), 'source': 'usda'},
            },
          );
        },
      );
      final product = await client.lookup('3017620422003', languageCode: 'en');
      expect(
        requested.toString(),
        'https://api.example/food/barcode?code=3017620422003',
      );
      expect(product?.source, FoodProductSource.usda);
      expect(product?.servingGrams, 15);
    });
  });

  test('recent products are deduplicated, newest first', () async {
    const store = RecentProductsStore();
    await store.remember(_nutella);
    const other = FoodProduct(
      barcode: '5449000000996',
      name: 'Cola',
      per100g: NutritionPer100g(
        caloriesKcal: 42,
        proteinGrams: 0,
        carbsGrams: 10.6,
        fatGrams: 0,
      ),
      source: FoodProductSource.openFoodFacts,
      isLiquid: true,
    );
    await store.remember(other);
    final products = await store.remember(_nutella);
    expect(products.map((item) => item.barcode), [
      '3017620422003',
      '5449000000996',
    ]);
    final reloaded = await store.load();
    expect(reloaded.last.isLiquid, isTrue);
    expect(reloaded.first.diaryLabel, 'Nutella (Ferrero)');
  });

  testWidgets('scanning a barcode logs the chosen portion for free', (
    tester,
  ) async {
    final controller = _controller();
    addTearDown(controller.dispose);
    await _pump(
      tester,
      controller,
      Scaffold(
        body: NutritionScreen(
          barcodeScanner: (_) async => '3017620422003',
          barcodeLookupService: BarcodeLookupService(
            sources: [_FakeSource(_nutella)],
          ),
        ),
      ),
    );

    final scanButton = find.byKey(const Key('nutrition_scan_barcode'));
    await tester.ensureVisible(scanButton);
    await tester.tap(scanButton);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('barcode_product_found')), findsOneWidget);
    expect(find.byKey(const Key('barcode_source_attribution')), findsOneWidget);
    // Defaults to one serving (15 g); choose 30 g instead.
    await tester.enterText(find.byKey(const Key('barcode_grams_field')), '30');
    await tester.pump();
    final add = find.byKey(const Key('barcode_add_to_diary'));
    await tester.ensureVisible(add);
    await tester.tap(add);
    await tester.pumpAndSettle();

    final entries = controller.nutritionDiary.entries;
    expect(entries, hasLength(1));
    expect(entries.single.label, 'Nutella (Ferrero)');
    expect(entries.single.weightGrams, 30);
    expect(entries.single.nutrition.caloriesKcal, closeTo(161.7, 0.01));
    expect(entries.single.nutrition.fatGrams, closeTo(9.27, 0.01));

    final recent = await const RecentProductsStore().load();
    expect(recent.single.barcode, '3017620422003');

    // The product can now be re-logged from "Recent products".
    final addFood = find.byKey(const Key('nutrition_add_food'));
    await tester.ensureVisible(addFood);
    await tester.tap(addFood);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('nutrition_add_recent_product')),
      findsOneWidget,
    );
  });

  testWidgets('unknown barcode offers manual entry', (tester) async {
    final controller = _controller();
    addTearDown(controller.dispose);
    await _pump(
      tester,
      controller,
      Scaffold(
        body: NutritionScreen(
          barcodeScanner: (_) async => '3017620422003',
          barcodeLookupService: BarcodeLookupService(
            sources: [_FakeSource(null)],
          ),
        ),
      ),
    );

    final scanButton = find.byKey(const Key('nutrition_scan_barcode'));
    await tester.ensureVisible(scanButton);
    await tester.tap(scanButton);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('barcode_not_found')), findsOneWidget);
    await tester.tap(find.text('Enter manually'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('nutrition_label_field')), findsOneWidget);
    expect(controller.nutritionDiary.entries, isEmpty);
  });
}

AppController _controller() => AppController(
  measurementStore: const MeasurementStore(),
  nutritionDiaryController: NutritionDiaryController(
    store: const NutritionLogStore(),
  ),
);

Future<void> _pump(
  WidgetTester tester,
  AppController controller,
  Widget home,
) async {
  tester.view.physicalSize = const Size(540, 960);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    AppScope(
      controller: controller,
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: home,
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
}
