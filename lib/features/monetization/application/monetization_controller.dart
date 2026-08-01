import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:in_app_purchase_android/billing_client_wrappers.dart';

import '../../../core/services/installation_id_store.dart';
import '../data/app_ad_service.dart';
import '../data/monetization_api.dart';
import '../data/monetization_config.dart';
import '../domain/access_status.dart';

class MonetizationController extends ChangeNotifier {
  MonetizationController._({
    required this.enabled,
    required MonetizationApi? api,
    required AppAdService adService,
  }) : _api = api,
       _adService = adService;

  factory MonetizationController.create() => MonetizationController._(
    enabled: MonetizationConfig.backendConfigured,
    api: MonetizationConfig.backendConfigured
        ? MonetizationApi(apiUrl: MonetizationConfig.apiUrl)
        : null,
    adService: AppAdService(),
  );

  factory MonetizationController.disabled() => MonetizationController._(
    enabled: false,
    api: null,
    adService: AppAdService(),
  );

  final bool enabled;
  final MonetizationApi? _api;
  final AppAdService _adService;
  final InAppPurchase _store = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;

  AccessStatus _access = const AccessStatus.fallback();
  Map<String, ProductDetails> _products = const {};
  String _clientId = '';
  String? _message;
  bool _initialized = false;
  bool _loading = false;
  bool _purchasePending = false;
  bool _storeAvailable = false;
  GooglePlayPurchaseDetails? _activeGooglePurchase;

  AccessStatus get access => _access;
  List<PlanDefinition> get plans => MonetizationConfig.plans;
  String? get message => _message;
  bool get loading => _loading;
  bool get purchasePending => _purchasePending;
  bool get storeAvailable => _storeAvailable;
  bool get canRequestAds => _adService.canRequestAds && _access.adsEnabled;
  bool get rewardedAdReady => _adService.rewardedReady;
  bool get privacyOptionsRequired => _adService.privacyOptionsRequired;

  String? priceFor(String productId) => _products[productId]?.price;

  Future<void> initialize() async {
    if (_initialized || !enabled) return;
    _initialized = true;
    _clientId = await InstallationIdStore.getOrCreate();
    _purchaseSubscription = _store.purchaseStream.listen(
      _handlePurchases,
      onError: (Object error) {
        _message = 'Google Play Billing error: $error';
        _purchasePending = false;
        notifyListeners();
      },
    );
    await Future.wait([refreshAccess(), _loadProducts()]);
    if (_access.isPaid && _storeAvailable) {
      // Rehydrates the Google purchase needed for seamless plan changes.
      await _store.restorePurchases(applicationUserName: _clientId);
    }
  }

  Future<void> refreshAccess() async {
    if (!enabled || _clientId.isEmpty || _api == null) return;
    try {
      final access = await _api.getAccess(_clientId);
      _access = access;
      _message = null;
      notifyListeners();
      await _adService.updatePlan(adsAllowed: access.adsEnabled);
      notifyListeners();
    } on Object catch (error) {
      // Keep the last known access. The Worker still enforces every scan.
      _message = 'Could not refresh plan: $error';
      notifyListeners();
    }
  }

  Future<void> _loadProducts() async {
    if (!Platform.isAndroid) return;
    try {
      _storeAvailable = await _store.isAvailable();
      if (!_storeAvailable) {
        _message = 'Google Play Billing is unavailable on this device.';
        notifyListeners();
        return;
      }
      final response = await _store.queryProductDetails(
        MonetizationConfig.productIds,
      );
      _products = {
        for (final product in response.productDetails) product.id: product,
      };
      if (response.error case final error?) {
        _message = error.message;
      } else if (response.notFoundIDs.isNotEmpty) {
        _message = 'Plans are not active in Google Play yet.';
      }
    } on Object catch (error) {
      _storeAvailable = false;
      _message = 'Could not load Google Play plans: $error';
    }
    notifyListeners();
  }

  Future<void> purchase(String productId) async {
    final product = _products[productId];
    if (!_storeAvailable || product == null) {
      _message = 'This plan is not available in Google Play yet.';
      notifyListeners();
      return;
    }
    _purchasePending = true;
    _message = null;
    notifyListeners();
    final currentPurchase = _activeGooglePurchase;
    final purchaseParam =
        currentPurchase != null && _access.isPaid && _access.planId != productId
        ? GooglePlayPurchaseParam(
            productDetails: product,
            applicationUserName: _clientId,
            changeSubscriptionParam: ChangeSubscriptionParam(
              oldPurchaseDetails: currentPurchase,
              replacementMode: ReplacementMode.withTimeProration,
            ),
          )
        : PurchaseParam(
            productDetails: product,
            applicationUserName: _clientId,
          );
    final started = await _store.buyNonConsumable(purchaseParam: purchaseParam);
    if (!started) {
      _purchasePending = false;
      _message = 'Google Play could not start the purchase.';
      notifyListeners();
    }
  }

  Future<void> restorePurchases() async {
    if (!_storeAvailable) {
      _message = 'Google Play Billing is unavailable.';
      notifyListeners();
      return;
    }
    _loading = true;
    _message = null;
    notifyListeners();
    try {
      await _store.restorePurchases(applicationUserName: _clientId);
      _message = 'Restore requested. Active plans will appear automatically.';
    } on Object catch (error) {
      _message = 'Could not restore purchases: $error';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> _handlePurchases(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      switch (purchase.status) {
        case PurchaseStatus.pending:
          _purchasePending = true;
          _message = 'Purchase pending in Google Play.';
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          await _verifyAndFinish(purchase);
        case PurchaseStatus.error:
          _purchasePending = false;
          _message = purchase.error?.message ?? 'The purchase failed.';
        case PurchaseStatus.canceled:
          _purchasePending = false;
          _message = 'Purchase canceled.';
      }
    }
    notifyListeners();
  }

  Future<void> _verifyAndFinish(PurchaseDetails purchase) async {
    if (_api == null) return;
    try {
      // On Android this server verification value is the Google purchase token.
      final token = purchase.verificationData.serverVerificationData;
      if (token.isEmpty) throw StateError('Google did not return a token.');
      _access = await _api.verifyPurchase(
        clientId: _clientId,
        productId: purchase.productID,
        purchaseToken: token,
      );
      if (purchase is GooglePlayPurchaseDetails) {
        _activeGooglePurchase = purchase;
      }
      if (purchase.pendingCompletePurchase) {
        await _store.completePurchase(purchase);
      }
      _purchasePending = false;
      _message = '${_access.planName} is active.';
      await _adService.updatePlan(adsAllowed: _access.adsEnabled);
    } on Object catch (error) {
      // Never acknowledge or grant a purchase that the Worker did not verify.
      _purchasePending = false;
      _message = 'Purchase verification failed: $error';
    }
  }

  Future<void> onScanCompleted() async {
    await refreshAccess();
    await _adService.recordCompletedScanAndMaybeShowInterstitial();
  }

  Future<bool> watchAdForScan() async {
    if (!_access.adsEnabled) return false;
    final earned = await _adService.showRewarded(clientId: _clientId);
    if (!earned) {
      _message = 'A rewarded ad is not ready yet. Try again shortly.';
      notifyListeners();
      return false;
    }

    _message = 'Reward earned. Confirming it securely…';
    notifyListeners();
    final previousRemaining = _access.remainingScans;
    for (final delay in const [1, 2, 4, 6]) {
      await Future<void>.delayed(Duration(seconds: delay));
      await refreshAccess();
      if (_access.remainingScans > previousRemaining) {
        _message = 'One bonus scan was added.';
        notifyListeners();
        return true;
      }
    }
    _message = 'Your reward is still processing. Pull to refresh shortly.';
    notifyListeners();
    return false;
  }

  Future<void> showPrivacyOptions() async {
    await _adService.showPrivacyOptions();
    notifyListeners();
  }

  void clearMessage() {
    _message = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _purchaseSubscription?.cancel();
    _adService.dispose();
    super.dispose();
  }
}
