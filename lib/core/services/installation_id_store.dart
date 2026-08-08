import 'dart:convert';
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

/// A random, app-install scoped identifier used to associate server-side
/// quotas and purchases without collecting an email address or device ID.
abstract final class InstallationIdStore {
  static const _preferenceKey = 'masslens_api_installation_id';

  /// Distinguishes an upgraded installation from a genuinely fresh install
  /// without creating a new identifier as a side effect.
  static bool hasExisting(SharedPreferences preferences) {
    final existing = preferences.getString(_preferenceKey);
    return existing != null && existing.isNotEmpty;
  }

  static Future<String> getOrCreate() async {
    final preferences = await SharedPreferences.getInstance();
    final existing = preferences.getString(_preferenceKey);
    if (existing != null && existing.isNotEmpty) return existing;

    final random = Random.secure();
    final bytes = List<int>.generate(18, (_) => random.nextInt(256));
    final created = base64UrlEncode(bytes).replaceAll('=', '');
    await preferences.setString(_preferenceKey, created);
    return created;
  }
}
