import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:mass_lens/features/monetization/data/billing_config.dart';
import 'package:mass_lens/features/monetization/data/monetization_api.dart';
import 'package:mass_lens/features/monetization/data/play_billing_service.dart';

class FakeStore implements InAppPurchase {
  final updates = StreamController<List<PurchaseDetails>>.broadcast();
  int restores = 0;
  Set<String> queriedIds = {};
  List<ProductDetails> products = [];
  String? purchasedId;
  final completed = <PurchaseDetails>[];
  Future<void> Function()? onRestore;

  @override
  Stream<List<PurchaseDetails>> get purchaseStream => updates.stream;
  @override
  Future<bool> isAvailable() async => true;
  @override
  Future<ProductDetailsResponse> queryProductDetails(Set<String> ids) async {
    queriedIds = Set.of(ids);
    return ProductDetailsResponse(productDetails: products, notFoundIDs: []);
  }

  @override
  Future<bool> buyNonConsumable({required PurchaseParam purchaseParam}) async {
    purchasedId = purchaseParam.productDetails.id;
    return true;
  }

  @override
  Future<void> restorePurchases({String? applicationUserName}) async {
    restores++;
    await onRestore?.call();
  }

  @override
  Future<void> completePurchase(PurchaseDetails purchase) async {
    completed.add(purchase);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeApi extends MonetizationApi {
  FakeApi() : super(apiUrl: 'https://example.invalid');
  final tokens = <String>[];
  bool reject = false;
  @override
  Future<LifetimeVerifyResult> verifyLifetimePurchase({
    required String clientId,
    required String productId,
    required String purchaseToken,
  }) async {
    tokens.add(purchaseToken);
    if (reject) throw const MonetizationApiException('Verification failed');
    return const LifetimeVerifyResult(hasLifetime: true, status: 'restored');
  }
}

PurchaseDetails errorEvent({
  String productId = '',
  String message = 'BillingResponse.itemAlreadyOwned',
}) =>
    PurchaseDetails(
        productID: productId,
        verificationData: PurchaseVerificationData(
          localVerificationData: '',
          serverVerificationData: '',
          source: 'google_play',
        ),
        transactionDate: null,
        status: PurchaseStatus.error,
      )
      ..error = IAPError(
        source: 'google_play',
        code: 'purchase_error',
        message: message,
      );

PurchaseDetails restoredPurchase() => PurchaseDetails(
  productID: BillingConfig.lifetimeProductId,
  verificationData: PurchaseVerificationData(
    localVerificationData: '',
    serverVerificationData: 'test-purchase-token',
    source: 'google_play',
  ),
  transactionDate: null,
  status: PurchaseStatus.restored,
)..pendingCompletePurchase = true;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late FakeStore store;
  late FakeApi api;
  late PlayBillingService service;
  late int entitlementChanges;

  setUp(() async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    store = FakeStore();
    api = FakeApi();
    entitlementChanges = 0;
    service = PlayBillingService(api: api, inAppPurchase: store);
    await service.initialize(
      clientId: 'test-client-installation-id',
      onEntitlementChanged: () async {
        entitlementChanges++;
      },
    );
  });
  tearDown(() async {
    service.dispose();
    await store.updates.close();
    debugDefaultTargetPlatformOverride = null;
  });

  test('queries and purchases only the standard lifetime product', () async {
    store.products = [
      ProductDetails(
        id: BillingConfig.lifetimeProductId,
        title: 'Lifetime access',
        description: 'Unlimited scans without ads',
        price: r'$4.99',
        rawPrice: 4.99,
        currencyCode: 'USD',
      ),
    ];
    await service.refreshProductDetails();
    expect(store.queriedIds, {'masslens_lifetime_unlimited'});
    expect(await service.buyLifetime(), isTrue);
    expect(store.purchasedId, BillingConfig.lifetimeProductId);
  });

  test(
    'does not substitute a discounted product for a missing standard product',
    () async {
      store.products = [
        ProductDetails(
          id: 'masslens_lifetime_off_30',
          title: 'Legacy offer',
          description: 'Legacy offer',
          price: r'$3.49',
          rawPrice: 3.49,
          currencyCode: 'USD',
        ),
      ];
      await service.refreshProductDetails();
      expect(service.lifetimePriceLabel, isEmpty);
      expect(await service.buyLifetime(), isFalse);
      expect(store.purchasedId, isNull);
    },
  );

  test('empty-SKU already-owned error restores and verifies access', () async {
    final baseline = store.restores;
    final restored = restoredPurchase();
    store.onRestore = () async {
      store.updates.add([restored]);
    };
    store.updates.add([errorEvent()]);
    await Future<void>.delayed(Duration.zero);
    expect(store.restores, baseline + 1);
    expect(api.tokens, ['test-purchase-token']);
    expect(entitlementChanges, 1);
    expect(store.completed, [restored]);
    expect(service.message, isNull);
  });

  test('already-owned does not grant access when verification fails', () async {
    api.reject = true;
    store.onRestore = () async {
      store.updates.add([restoredPurchase()]);
    };
    store.updates.add([errorEvent(productId: BillingConfig.lifetimeProductId)]);
    await Future<void>.delayed(Duration.zero);
    expect(api.tokens, hasLength(1));
    expect(entitlementChanges, 0);
    // Purchases are acknowledged even when verification fails (avoids the
    // Play "already owned" deadlock); the token is kept for a later retry.
    expect(store.completed, hasLength(1));
    expect(service.message, 'Verification failed');
  });

  test('other empty-SKU errors are shown without restoring', () async {
    final baseline = store.restores;
    store.updates.add([
      errorEvent(message: 'BillingResponse.serviceUnavailable'),
    ]);
    await Future<void>.delayed(Duration.zero);
    expect(store.restores, baseline);
    expect(service.message, 'BillingResponse.serviceUnavailable');
    expect(api.tokens, isEmpty);
  });

  test('concurrent already-owned errors trigger one restore', () async {
    final baseline = store.restores;
    final pending = Completer<void>();
    store.onRestore = () => pending.future;
    store.updates.add([errorEvent()]);
    store.updates.add([errorEvent()]);
    await Future<void>.delayed(Duration.zero);
    expect(store.restores, baseline + 1);
    pending.complete();
    await Future<void>.delayed(Duration.zero);
    expect(entitlementChanges, 0);
  });

  test('restore failure is caught and a later retry is allowed', () async {
    final baseline = store.restores;
    store.onRestore = () async {
      throw StateError('Store unavailable');
    };
    store.updates.add([errorEvent()]);
    await Future<void>.delayed(Duration.zero);
    expect(service.message, 'Could not restore purchases. Please try again.');
    store.onRestore = () async {
      store.updates.add([restoredPurchase()]);
    };
    store.updates.add([errorEvent()]);
    await Future<void>.delayed(Duration.zero);
    expect(store.restores, baseline + 2);
    expect(entitlementChanges, 1);
  });
}
