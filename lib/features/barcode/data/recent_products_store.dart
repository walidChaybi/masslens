import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/food_product.dart';

/// Products the user logged by barcode, newest first, for one-tap re-logging.
/// Stored only on this device.
class RecentProductsStore {
  const RecentProductsStore();

  static const storageKey = 'mass_lens.recent_food_products.v1';
  static const maxProducts = 15;

  Future<List<FoodProduct>> load() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final encoded = preferences.getString(storageKey);
      if (encoded == null || encoded.isEmpty) return [];
      final decoded = jsonDecode(encoded);
      if (decoded is! List) return [];
      return decoded
          .map(FoodProduct.tryFromJson)
          .whereType<FoodProduct>()
          .take(maxProducts)
          .toList(growable: false);
    } on Object {
      return [];
    }
  }

  Future<List<FoodProduct>> remember(FoodProduct product) async {
    final current = await load();
    final updated = [
      product,
      ...current.where((item) => item.barcode != product.barcode),
    ].take(maxProducts).toList(growable: false);
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(
        storageKey,
        jsonEncode(updated.map((item) => item.toJson()).toList()),
      );
    } on Object {
      // Recent products are a convenience; logging still succeeded.
    }
    return updated;
  }

  Future<void> clear() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.remove(storageKey);
    } on Object {
      // Nothing else to clear.
    }
  }
}
