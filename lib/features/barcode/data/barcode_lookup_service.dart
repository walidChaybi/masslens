import 'dart:convert';
import 'dart:io';

import '../../../core/services/installation_id_store.dart';
import '../../measurements/domain/measurement.dart';
import '../../scan/data/estimate_repository_factory.dart';
import '../domain/food_product.dart';

/// Performs a GET request and returns the HTTP status with the decoded JSON
/// body (null when the body is not JSON). Injected in tests.
typedef JsonGetter =
    Future<(int, Object?)> Function(Uri uri, Map<String, String> headers);

enum BarcodeLookupStatus { found, notFound, unavailable }

class BarcodeLookupResult {
  const BarcodeLookupResult._(this.status, this.product);

  const BarcodeLookupResult.found(FoodProduct product)
    : this._(BarcodeLookupStatus.found, product);

  const BarcodeLookupResult.notFound()
    : this._(BarcodeLookupStatus.notFound, null);

  const BarcodeLookupResult.unavailable()
    : this._(BarcodeLookupStatus.unavailable, null);

  final BarcodeLookupStatus status;
  final FoodProduct? product;
}

/// One database that may know a barcode. Returns null for "not found" and
/// throws when the source could not be reached.
abstract interface class FoodProductSourceClient {
  Future<FoodProduct?> lookup(String barcode, {required String languageCode});
}

/// Barcode lookups are free: they never use AI or scan credits. Open Food
/// Facts is queried directly from the device (its read limit is per IP), then
/// the MassLens Worker checks USDA branded foods as a fallback.
class BarcodeLookupService {
  BarcodeLookupService({required List<FoodProductSourceClient> sources})
    : _sources = List.unmodifiable(sources);

  factory BarcodeLookupService.production() {
    return BarcodeLookupService(
      sources: [
        OpenFoodFactsClient(getJson: httpGetJson),
        MassLensBarcodeClient(
          apiUrl: EstimateEngineConfig.cloudflareApiUrl,
          getJson: httpGetJson,
          clientId: InstallationIdStore.getOrCreate,
        ),
      ],
    );
  }

  final List<FoodProductSourceClient> _sources;
  final Map<String, FoodProduct> _cache = {};

  Future<BarcodeLookupResult> lookup(
    String barcode, {
    String languageCode = 'en',
  }) async {
    final normalized = normalizeBarcode(barcode);
    if (normalized == null) return const BarcodeLookupResult.notFound();
    final cached = _cache[normalized];
    if (cached != null) return BarcodeLookupResult.found(cached);

    var sourceFailed = false;
    for (final source in _sources) {
      try {
        final product = await source.lookup(
          normalized,
          languageCode: languageCode,
        );
        if (product != null) {
          _cache[normalized] = product;
          return BarcodeLookupResult.found(product);
        }
      } on Object {
        sourceFailed = true;
      }
    }
    return sourceFailed
        ? const BarcodeLookupResult.unavailable()
        : const BarcodeLookupResult.notFound();
  }
}

class OpenFoodFactsClient implements FoodProductSourceClient {
  OpenFoodFactsClient({required this.getJson});

  final JsonGetter getJson;

  /// Open Food Facts asks every app to identify itself. Set
  /// OFF_CONTACT_EMAIL at build time to add a contact address.
  static const _contact = String.fromEnvironment('OFF_CONTACT_EMAIL');
  static String get userAgent => _contact.isEmpty
      ? 'MassLens-PhotoEstimates/1.1 (Android; com.lilai.masslens.photoestimates)'
      : 'MassLens-PhotoEstimates/1.1 (Android; $_contact)';

  @override
  Future<FoodProduct?> lookup(
    String barcode, {
    required String languageCode,
  }) async {
    final language = const {'fr', 'es'}.contains(languageCode)
        ? languageCode
        : 'en';
    final uri = Uri.https(
      'world.openfoodfacts.org',
      '/api/v2/product/$barcode.json',
      {
        'fields': [
          'code',
          'product_name',
          'product_name_$language',
          'generic_name',
          'brands',
          'nutriments',
          'serving_quantity',
          'serving_quantity_unit',
          'product_quantity',
          'product_quantity_unit',
          'nutrition_data_per',
        ].join(','),
      },
    );
    final (status, body) = await getJson(uri, {
      HttpHeaders.userAgentHeader: userAgent,
      HttpHeaders.acceptHeader: 'application/json',
    });
    if (status == 404) return null;
    if (status < 200 || status >= 300) {
      throw HttpException('Open Food Facts returned $status');
    }
    return foodProductFromOpenFoodFacts(
      body,
      barcode: barcode,
      languageCode: language,
    );
  }
}

/// Maps an Open Food Facts v2 product response. Returns null when the product
/// is unknown or its label nutrition is missing or implausible.
FoodProduct? foodProductFromOpenFoodFacts(
  Object? decoded, {
  required String barcode,
  String languageCode = 'en',
}) {
  if (decoded is! Map) return null;
  final status = decoded['status'];
  if (status != 1 && status != '1') return null;
  final product = decoded['product'];
  if (product is! Map) return null;
  final nutriments = product['nutriments'];
  if (nutriments is! Map) return null;

  var calories = _offNumber(nutriments['energy-kcal_100g']);
  if (calories == null) {
    final kilojoules =
        _offNumber(nutriments['energy-kj_100g']) ??
        _offNumber(nutriments['energy_100g']);
    if (kilojoules != null) calories = kilojoules / 4.184;
  }
  final protein = _offNumber(nutriments['proteins_100g']);
  final carbs = _offNumber(nutriments['carbohydrates_100g']);
  final fat = _offNumber(nutriments['fat_100g']);
  if (calories == null) return null;

  final per100 = NutritionPer100g(
    caloriesKcal: calories,
    proteinGrams: protein ?? 0,
    carbsGrams: carbs ?? 0,
    fatGrams: fat ?? 0,
  );
  if (!isPlausiblePer100g(per100)) return null;

  final name =
      [
            product['product_name_$languageCode'],
            product['product_name'],
            product['generic_name'],
          ]
          .whereType<String>()
          .map((value) => value.trim())
          .firstWhere((value) => value.isNotEmpty, orElse: () => '');
  final brands = product['brands'];
  final brand = brands is String ? brands.split(',').first.trim() : null;
  final resolvedName = name.isNotEmpty
      ? name
      : (brand != null && brand.isNotEmpty ? brand : barcode);

  final servingUnit = '${product['serving_quantity_unit'] ?? ''}'.toLowerCase();
  final packageUnit = '${product['product_quantity_unit'] ?? ''}'.toLowerCase();
  final isLiquid =
      const {'ml', 'cl', 'l'}.contains(packageUnit) ||
      servingUnit == 'ml' ||
      '${product['nutrition_data_per'] ?? ''}'.toLowerCase() == '100ml';

  return FoodProduct(
    barcode: barcode,
    name: resolvedName,
    brand: brand == null || brand.isEmpty ? null : brand,
    per100g: per100,
    source: FoodProductSource.openFoodFacts,
    servingGrams: plausibleAmount(product['serving_quantity']),
    packageGrams: plausibleAmount(product['product_quantity']),
    isLiquid: isLiquid,
    hasPartialNutrition: protein == null || carbs == null || fat == null,
  );
}

double? _offNumber(Object? value) {
  final parsed = switch (value) {
    final num number => number.toDouble(),
    final String text => double.tryParse(text.trim().replaceAll(',', '.')),
    _ => null,
  };
  return parsed != null && parsed.isFinite && parsed >= 0 ? parsed : null;
}

/// USDA branded-food fallback through the MassLens Worker (`/food/barcode`).
class MassLensBarcodeClient implements FoodProductSourceClient {
  MassLensBarcodeClient({
    required this.apiUrl,
    required this.getJson,
    required this.clientId,
  });

  final String apiUrl;
  final JsonGetter getJson;
  final Future<String> Function() clientId;

  @override
  Future<FoodProduct?> lookup(
    String barcode, {
    required String languageCode,
  }) async {
    final base = Uri.tryParse(apiUrl.trim());
    if (base == null || !base.hasAuthority) return null;
    final uri = base.replace(
      path: '/food/barcode',
      queryParameters: {'code': barcode},
    );
    final (status, body) = await getJson(uri, {
      'X-MassLens-Client-ID': await clientId(),
      HttpHeaders.acceptHeader: 'application/json',
    });
    if (status == 404) return null;
    if (status < 200 || status >= 300 || body is! Map) {
      throw HttpException('Barcode service returned $status');
    }
    if (body['status'] != 'found') return null;
    return FoodProduct.tryFromJson(body['product']);
  }
}

Future<(int, Object?)> httpGetJson(Uri uri, Map<String, String> headers) async {
  const timeout = Duration(seconds: 10);
  final client = HttpClient()..connectionTimeout = timeout;
  try {
    final request = await client.getUrl(uri).timeout(timeout);
    headers.forEach(request.headers.set);
    final response = await request.close().timeout(timeout);
    final text = await utf8.decodeStream(response).timeout(timeout);
    Object? decoded;
    try {
      decoded = text.isEmpty ? null : jsonDecode(text);
    } on FormatException {
      decoded = null;
    }
    return (response.statusCode, decoded);
  } finally {
    client.close(force: true);
  }
}
