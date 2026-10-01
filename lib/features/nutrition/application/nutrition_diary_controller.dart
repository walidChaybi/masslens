import 'package:flutter/foundation.dart';

import '../../measurements/domain/measurement.dart';
import '../data/nutrition_log_store.dart';
import '../domain/nutrition_goals.dart';
import '../domain/nutrition_log.dart';

class NutritionDiaryController extends ChangeNotifier {
  NutritionDiaryController({
    required NutritionLogStore store,
    List<NutritionLogEntry> entries = const [],
    NutritionGoals? goals,
  }) : _store = store,
       _entries = List<NutritionLogEntry>.from(entries)
         ..sort((a, b) => b.loggedAt.compareTo(a.loggedAt)),
       _goals = goals ?? NutritionGoals.defaults();

  factory NutritionDiaryController.empty() =>
      NutritionDiaryController(store: const NutritionLogStore());

  final NutritionLogStore _store;
  final List<NutritionLogEntry> _entries;
  NutritionGoals _goals;

  List<NutritionLogEntry> get entries => List.unmodifiable(_entries);

  NutritionGoals get goals => _goals;

  int streak({DateTime? now}) => nutritionLoggingStreak(_entries, now: now);

  NutritionDaySummary daySummary(DateTime day) =>
      summarizeNutritionDay(_entries, day);

  NutritionPeriodSummary periodSummary({
    required DateTime endingOn,
    required int dayCount,
  }) => summarizeNutritionPeriod(
    _entries,
    endingOn: endingOn,
    dayCount: dayCount,
  );

  Future<void> add(NutritionLogEntry entry) async {
    entry.validate();
    if (_entries.any((existing) => existing.id == entry.id)) return;
    _entries.add(entry);
    _sortAndNotify();
    await _store.saveAll(_entries);
  }

  Future<NutritionLogEntry> addMeasurement({
    required String id,
    required DateTime loggedAt,
    required MealType mealType,
    required Measurement measurement,
  }) async {
    final entry = NutritionLogEntry.fromMeasurement(
      id: id,
      loggedAt: loggedAt,
      mealType: mealType,
      measurement: measurement,
    );
    await add(entry);
    return entry;
  }

  Future<void> update(NutritionLogEntry entry) async {
    entry.validate();
    final index = _entries.indexWhere((existing) => existing.id == entry.id);
    if (index == -1) return;
    _entries[index] = entry;
    _sortAndNotify();
    await _store.saveAll(_entries);
  }

  Future<void> delete(String id) async {
    final before = _entries.length;
    _entries.removeWhere((entry) => entry.id == id);
    if (_entries.length == before) return;
    notifyListeners();
    await _store.saveAll(_entries);
  }

  Future<void> updateGoals(NutritionGoals goals) async {
    _goals = goals;
    notifyListeners();
    await _store.saveGoals(goals);
  }

  Future<void> clear() async {
    if (_entries.isEmpty) return;
    _entries.clear();
    notifyListeners();
    await _store.clear();
  }

  void _sortAndNotify() {
    _entries.sort((a, b) => b.loggedAt.compareTo(a.loggedAt));
    notifyListeners();
  }
}
