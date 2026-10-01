import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../l10n/l10n.dart';
import '../domain/nutrition_goals.dart';

Future<NutritionGoals?> showNutritionGoalsSheet(
  BuildContext context, {
  required NutritionGoals initial,
}) {
  return showModalBottomSheet<NutritionGoals>(
    context: context,
    isScrollControlled: true,
    backgroundColor: context.palette.surface,
    showDragHandle: true,
    builder: (_) => _GoalsSheet(initial: initial),
  );
}

class _GoalsSheet extends StatefulWidget {
  const _GoalsSheet({required this.initial});

  final NutritionGoals initial;

  @override
  State<_GoalsSheet> createState() => _GoalsSheetState();
}

class _GoalsSheetState extends State<_GoalsSheet> {
  late final TextEditingController _calories;
  late final TextEditingController _protein;
  late final TextEditingController _carbs;
  late final TextEditingController _fat;

  @override
  void initState() {
    super.initState();
    _calories = TextEditingController(
      text: widget.initial.calorieGoalKcal.round().toString(),
    );
    _protein = TextEditingController(
      text: widget.initial.proteinGrams.round().toString(),
    );
    _carbs = TextEditingController(
      text: widget.initial.carbsGrams.round().toString(),
    );
    _fat = TextEditingController(
      text: widget.initial.fatGrams.round().toString(),
    );
  }

  @override
  void dispose() {
    _calories.dispose();
    _protein.dispose();
    _carbs.dispose();
    _fat.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          0,
          20,
          20 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.nutritionDailyGoals,
              style: TextStyle(
                color: context.palette.ink,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 16),
            _GoalField(
              key: const Key('nutrition_goal_calories'),
              controller: _calories,
              label: l10n.nutritionCalorieGoal,
              suffix: l10n.nutritionCaloriesUnit,
            ),
            const SizedBox(height: 10),
            _GoalField(
              key: const Key('nutrition_goal_protein'),
              controller: _protein,
              label: l10n.nutritionProtein,
              suffix: 'g',
            ),
            const SizedBox(height: 10),
            _GoalField(
              key: const Key('nutrition_goal_carbs'),
              controller: _carbs,
              label: l10n.nutritionCarbs,
              suffix: 'g',
            ),
            const SizedBox(height: 10),
            _GoalField(
              key: const Key('nutrition_goal_fat'),
              controller: _fat,
              label: l10n.nutritionFat,
              suffix: 'g',
            ),
            const SizedBox(height: 18),
            FilledButton(
              key: const Key('nutrition_save_goals'),
              onPressed: _save,
              style: FilledButton.styleFrom(
                backgroundColor: context.palette.ink,
                foregroundColor: context.palette.onInk,
              ),
              child: Text(l10n.nutritionGoalsSave),
            ),
          ],
        ),
      ),
    );
  }

  void _save() {
    final calories = double.tryParse(_calories.text.trim());
    if (calories == null || calories <= 0) return;
    final defaults = NutritionGoals.fromCalorieGoal(calories);
    Navigator.pop(
      context,
      NutritionGoals(
        calorieGoalKcal: calories,
        proteinGrams:
            double.tryParse(_protein.text.trim()) ?? defaults.proteinGrams,
        carbsGrams: double.tryParse(_carbs.text.trim()) ?? defaults.carbsGrams,
        fatGrams: double.tryParse(_fat.text.trim()) ?? defaults.fatGrams,
      ),
    );
  }
}

class _GoalField extends StatelessWidget {
  const _GoalField({
    required this.controller,
    required this.label,
    required this.suffix,
    super.key,
  });

  final TextEditingController controller;
  final String label;
  final String suffix;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: TextStyle(color: context.palette.ink),
      decoration: InputDecoration(
        labelText: label,
        suffixText: suffix,
        labelStyle: TextStyle(color: context.palette.inkMuted),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: context.palette.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: context.palette.ink),
        ),
      ),
    );
  }
}
