import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'billing_config.dart';
import 'monetization_api.dart';

/// Google Play Billing, using the same `in_app_purchase` flow as Flip 7:
/// check the store, listen to [purchaseStream], query product details, then
/// [buyNonConsumable] / [restorePurchases]. Lifetime entitlement is still
/// granted only after Worker verification.
class PlayBillingService {
  PlayBillingService({
    required MonetizationApi api,
    InAppPurchase? inAppPurchase,
  }) : _api = api,
       _inAppPurchaseOverride = inAppPurchase;

  final MonetizationApi _api;
  final InAppPurchase? _inAppPurchaseOverride;
  InAppPurchase? _inAppPurchase;

  StreamSubscription<List<PurchaseDetails>>? _subscription;
  final _products = <String, ProductDetails>{};
  ProductDetails? _lifetimeProduct;
  bool _storeAvailable = false;
  bool _loadingProduct = false;
  bool _productQueryCompleted = false;
  bool _recoveringOwnedPurchase = false;
  String? _message;
  String _clientId = '';
  Future<void> Function()? _onEntitlementChanged;
  void Function()? _onChanged;

  ProductDetails? get lifetimeProduct => _lifetimeProduct;
  bool get storeAvailable => _storeAvailable;
  bool get loadingProduct => _loadingProduct;
  bool get productQueryCompleted => _productQueryCompleted;
  String? get message => _message;
  String get lifetimePriceLabel => _lifetimeProduct?.price ?? '';
  double? get lifetimeRawPrice {
    final product = _lifetimeProduct;
    if (product == null || product.rawPrice <= 0) return null;
    return product.rawPrice;
  }

  String get lifetimeCurrencyCode => _lifetimeProduct?.currencyCode ?? '';

  Future<void> initialize({
    required String clientId,
    Future<void> Function()? onEntitlementChanged,
    void Function()? onChanged,
  }) async {
    _clientId = clientId;
    _onEntitlementChanged = onEntitlementChanged;
    _onChanged = onChanged;
    if (!BillingConfig.supported) {
      _productQueryCompleted = true;
      _onChanged?.call();
      return;
    }

    _inAppPurchase = _inAppPurchaseOverride ?? InAppPurchase.instance;
    final inAppPurchase = _inAppPurchase!;
    _storeAvailable = await inAppPurchase.isAvailable();
    if (!_storeAvailable) {
      _productQueryCompleted = true;
      _message = 'Google Play Billing is unavailable on this device.';
      debugPrint('[IAP] Store not available');
      _onChanged?.call();
      return;
    }

    _subscription ??= inAppPurchase.purchaseStream.listen(
      _handlePurchaseUpdates,
      onDone: () => unawaited(_subscription?.cancel()),
      onError: (Object error) {
        debugPrint('[IAP] purchaseStream error: $error');
        _message = 'Purchase updates failed: $error';
        _onChanged?.call();
      },
    );
    await refreshProductDetails();
    _onChanged?.call();
    unawaited(_retryUnverifiedPurchase());
    unawaited(restorePurchases());
  }

  Future<void> refreshProductDetails() async {
    if (!BillingConfig.supported) {
      _productQueryCompleted = true;
      return;
    }
    var inAppPurchase = _inAppPurchase;
    if (inAppPurchase == null) {
      _inAppPurchase = _inAppPurchaseOverride ?? InAppPurchase.instance;
      inAppPurchase = _inAppPurchase;
    }
    if (inAppPurchase == null) return;
    if (!_storeAvailable) {
      _storeAvailable = await inAppPurchase.isAvailable();
      if (!_storeAvailable) {
        _productQueryCompleted = true;
        _message = 'Google Play Billing is unavailable on this device.';
        return;
      }
    }

    _loadingProduct = true;
    _onChanged?.call();
    try {
      final response = await inAppPurchase.queryProductDetails(
        BillingConfig.allProductIds,
      );
      if (response.notFoundIDs.isNotEmpty) {
        debugPrint('[IAP] Products not found: ${response.notFoundIDs}');
      }
      if (response.error != null) {
        debugPrint('[IAP] queryProductDetails error: ${response.error}');
        _message = response.error!.message;
      }

      _products
        ..clear()
        ..addEntries(
          response.productDetails
              .where((details) => BillingConfig.isLifetimeProductId(details.id))
              .map((details) => MapEntry(details.id, details)),
        );
      for (final details in _products.values) {
        debugPrint('[IAP] Loaded ${details.id} — ${details.price}');
      }

      _lifetimeProduct = _products[BillingConfig.lifetimeProductId];

      if (_lifetimeProduct != null &&
          _lifetimeProduct!.price.trim().isNotEmpty) {
        _message = null;
        debugPrint(
          '[IAP] Lifetime loaded: ${_lifetimeProduct!.title} — ${_lifetimeProduct!.price}',
        );
      } else {
        _lifetimeProduct = null;
        _message =
            'Play could not find product ${BillingConfig.lifetimeProductId}.';
      }
    } on Object catch (error) {
      debugPrint('[IAP] queryProductDetails failed: $error');
      _lifetimeProduct = null;
      _message = 'Could not load the store price.';
    } finally {
      _loadingProduct = false;
      _productQueryCompleted = true;
      _onChanged?.call();
    }
  }

  Future<bool> buyLifetime() async {
    final product = _lifetimeProduct;
    final inAppPurchase = _inAppPurchase;
    if (product == null || inAppPurchase == null) {
      debugPrint('[IAP] Cannot buy lifetime — product details not loaded');
      _message = 'Lifetime unlock is not available right now.';
      return false;
    }
    debugPrint('[IAP] Buying ${product.id} at ${product.price}');
    final purchaseParam = PurchaseParam(productDetails: product);
    return inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
  }

  Future<void> restorePurchases() async {
    if (!BillingConfig.supported || !_storeAvailable) return;
    await _inAppPurchase?.restorePurchases();
  }

  Future<void> _handlePurchaseUpdates(List<PurchaseDetails> purchases) async {
    final inAppPurchase = _inAppPurchase;
    if (inAppPurchase == null) return;
    for (final purchase in purchases) {
      // Play emits errors without purchase details (and with an empty product
      // ID), including ITEM_ALREADY_OWNED. Handle these before filtering SKUs.
      if (purchase.status == PurchaseStatus.error) {
        if (purchase.productID.isNotEmpty &&
            !BillingConfig.isLifetimeProductId(purchase.productID)) {
          continue;
        }
        if (purchase.error?.message == 'BillingResponse.itemAlreadyOwned') {
          if (_recoveringOwnedPurchase) continue;
          _recoveringOwnedPurchase = true;
          _message = 'Restoring purchases…';
          _onChanged?.call();
          try {
            // The error itself proves no entitlement. Restored purchases must
            // go through _verifyPurchase before access is granted.
            await restorePurchases();
          } on Object {
            _message = 'Could not restore purchases. Please try again.';
          } finally {
            _recoveringOwnedPurchase = false;
            _onChanged?.call();
          }
        } else {
          _message = purchase.error?.message ?? 'Purchase failed.';
          _onChanged?.call();
        }
        continue;
      }
      if (!BillingConfig.isLifetimeProductId(purchase.productID)) continue;
      switch (purchase.status) {
        case PurchaseStatus.pending:
          _message = 'Purchase pending…';
          _onChanged?.call();
          break;
        case PurchaseStatus.error:
          // Handled above, including errors without a product ID.
          break;
        case PurchaseStatus.canceled:
          debugPrint('[IAP] Purchase cancelled');
          _message = 'Purchase canceled.';
          if (purchase.pendingCompletePurchase) {
            await inAppPurchase.completePurchase(purchase);
          }
          _onChanged?.call();
          break;
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          final verified = await _verifyPurchase(purchase);
          // Always acknowledge the purchase with Google to prevent the
          // "You already own this item" deadlock when backend verification
          // fails temporarily. Unverified purchases are retried via
          // restorePurchases() on next launch and via retryUnverifiedPurchase().
          if (purchase.pendingCompletePurchase) {
            await inAppPurchase.completePurchase(purchase);
          }
          if (!verified) {
            await _persistUnverifiedPurchase(purchase);
          }
          _onChanged?.call();
          break;
      }
    }
  }

  Future<bool> _verifyPurchase(PurchaseDetails purchase) async {
    final token = purchase.verificationData.serverVerificationData;
    if (token.isEmpty || _clientId.isEmpty) return false;
    try {
      final result = await _api.verifyLifetimePurchase(
        clientId: _clientId,
        productId: purchase.productID,
        purchaseToken: token,
      );
      if (result.hasLifetime) {
        _message = null;
        await _onEntitlementChanged?.call();
        return true;
      }
    } on MonetizationApiException catch (error) {
      _message = error.message;
    } on Object catch (error) {
      _message = 'Could not verify purchase: $error';
    }
    return false;
  }

  static const _unverifiedPurchaseKey = 'mass_lens.unverified_purchase_token';

  Future<void> _persistUnverifiedPurchase(PurchaseDetails purchase) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _unverifiedPurchaseKey,
        purchase.verificationData.serverVerificationData,
      );
    } catch (e) {
      debugPrint('[IAP] Failed to persist unverified purchase: $e');
    }
  }

  Future<void> _retryUnverifiedPurchase() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_unverifiedPurchaseKey);
      if (token == null || token.isEmpty || _clientId.isEmpty) return;

      final result = await _api.verifyLifetimePurchase(
        clientId: _clientId,
        productId: BillingConfig.lifetimeProductId,
        purchaseToken: token,
      );
      if (result.hasLifetime) {
        await prefs.remove(_unverifiedPurchaseKey);
        await _onEntitlementChanged?.call();
      }
    } catch (e) {
      debugPrint('[IAP] Failed to retry unverified purchase: $e');
    }
  }

  void dispose() {
    unawaited(_subscription?.cancel());
    _subscription = null;
  }
}
