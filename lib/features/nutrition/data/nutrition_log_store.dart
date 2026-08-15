import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/nutrition_log.dart';

class NutritionLogStore {
  const NutritionLogStore();

  static const storageKey = 'mass_lens.nutrition_log.v1';

  Future<List<NutritionLogEntry>> load() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final encoded = preferences.getString(storageKey);
      if (encoded == null || encoded.isEmpty) return [];
      final decoded = jsonDecode(encoded);
      if (decoded is! List) return [];
      final entries = <NutritionLogEntry>[];
      for (final value in decoded) {
        if (value is! Map) continue;
        try {
          entries.add(
            NutritionLogEntry.fromJson(Map<String, Object?>.from(value)),
          );
        } on Object {
          // Preserve valid local records when a single entry is malformed.
        }
      }
      entries.sort((a, b) => b.loggedAt.compareTo(a.loggedAt));
      return entries;
    } on Object {
      return [];
    }
  }

  Future<void> saveAll(List<NutritionLogEntry> entries) async {
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(
        storageKey,
        jsonEncode(entries.map((entry) => entry.toJson()).toList()),
      );
    } on Object {
      // The in-memory diary remains available for the current session.
    }
  }

  Future<void> clear() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.remove(storageKey);
    } on Object {
      // The in-memory diary still clears even when persistence is unavailable.
    }
  }
}
