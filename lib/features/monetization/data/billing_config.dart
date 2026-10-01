import 'package:flutter/foundation.dart';

abstract final class BillingConfig {
  static const lifetimeProductId = 'masslens_lifetime_unlimited';
  static const allProductIds = {lifetimeProductId};

  static bool get supported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  static bool isLifetimeProductId(String productId) =>
      productId == lifetimeProductId;
}
