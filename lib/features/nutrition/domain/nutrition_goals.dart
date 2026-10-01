class NutritionGoals {
  const NutritionGoals({
    required this.calorieGoalKcal,
    required this.proteinGrams,
    required this.carbsGrams,
    required this.fatGrams,
  });

  static const defaultCalories = 2200.0;
  static const proteinCalorieShare = 0.30;
  static const carbsCalorieShare = 0.40;
  static const fatCalorieShare = 0.30;

  factory NutritionGoals.defaults() =>
      NutritionGoals.fromCalorieGoal(defaultCalories);

  factory NutritionGoals.fromCalorieGoal(double calories) {
    final safe = calories.isFinite && calories > 0 ? calories : defaultCalories;
    return NutritionGoals(
      calorieGoalKcal: safe,
      proteinGrams: (safe * proteinCalorieShare) / 4,
      carbsGrams: (safe * carbsCalorieShare) / 4,
      fatGrams: (safe * fatCalorieShare) / 9,
    );
  }

  final double calorieGoalKcal;
  final double proteinGrams;
  final double carbsGrams;
  final double fatGrams;

  NutritionGoals copyWith({
    double? calorieGoalKcal,
    double? proteinGrams,
    double? carbsGrams,
    double? fatGrams,
  }) {
    return NutritionGoals(
      calorieGoalKcal: calorieGoalKcal ?? this.calorieGoalKcal,
      proteinGrams: proteinGrams ?? this.proteinGrams,
      carbsGrams: carbsGrams ?? this.carbsGrams,
      fatGrams: fatGrams ?? this.fatGrams,
    );
  }

  Map<String, Object?> toJson() => {
    'calorieGoalKcal': calorieGoalKcal,
    'proteinGrams': proteinGrams,
    'carbsGrams': carbsGrams,
    'fatGrams': fatGrams,
  };

  factory NutritionGoals.fromJson(Map<String, Object?> json) {
    double number(String key, double fallback) {
      final value = json[key];
      if (value is num && value.isFinite && value > 0) return value.toDouble();
      return fallback;
    }

    final calories = number('calorieGoalKcal', defaultCalories);
    final fallback = NutritionGoals.fromCalorieGoal(calories);
    return NutritionGoals(
      calorieGoalKcal: calories,
      proteinGrams: number('proteinGrams', fallback.proteinGrams),
      carbsGrams: number('carbsGrams', fallback.carbsGrams),
      fatGrams: number('fatGrams', fallback.fatGrams),
    );
  }
}

double remainingCalories({
  required double goalKcal,
  required double consumedKcal,
}) {
  final remaining = goalKcal - consumedKcal;
  return remaining > 0 ? remaining : 0;
}

double overGoalCalories({
  required double goalKcal,
  required double consumedKcal,
}) {
  final over = consumedKcal - goalKcal;
  return over > 0 ? over : 0;
}
