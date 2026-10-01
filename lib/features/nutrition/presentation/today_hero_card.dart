import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../l10n/l10n.dart';
import '../../measurements/domain/measurement.dart';
import '../domain/nutrition_goals.dart';

class TodayHeroCard extends StatelessWidget {
  const TodayHeroCard({
    required this.consumed,
    required this.goals,
    required this.streak,
    required this.onEditGoals,
    super.key,
  });

  final NutritionTotals consumed;
  final NutritionGoals goals;
  final int streak;
  final VoidCallback onEditGoals;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final calories = NumberFormat('0', locale);
    final remaining = remainingCalories(
      goalKcal: goals.calorieGoalKcal,
      consumedKcal: consumed.caloriesKcal,
    );
    final over = overGoalCalories(
      goalKcal: goals.calorieGoalKcal,
      consumedKcal: consumed.caloriesKcal,
    );
    final progress = goals.calorieGoalKcal <= 0
        ? 0.0
        : (consumed.caloriesKcal / goals.calorieGoalKcal).clamp(0.0, 1.0);
    final remainingColor = over > 0 ? context.palette.amber : Colors.white;

    return Material(
      key: const Key('nutrition_hero_card'),
      color: context.palette.inkRaised,
      clipBehavior: Clip.antiAlias,
      elevation: 6,
      shadowColor: AppColors.ink.withValues(alpha: 0.35),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: InkWell(
        key: const Key('nutrition_edit_goals'),
        onTap: onEditGoals,
        borderRadius: BorderRadius.circular(28),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.nutritionCaloriesInput.toUpperCase(),
                      style: TextStyle(
                        color: context.palette.lime,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.4,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.local_fire_department_rounded,
                    size: 16,
                    color: streak > 0
                        ? context.palette.amber
                        : context.palette.onInkMuted,
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      streak <= 0
                          ? l10n.nutritionStreakZero
                          : l10n.nutritionStreak(streak),
                      key: const Key('nutrition_streak'),
                      style: TextStyle(
                        color: streak > 0
                            ? context.palette.amber
                            : context.palette.onInkMuted,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                calories.format(remaining),
                key: const Key('nutrition_remaining_kcal'),
                style: TextStyle(
                  color: remainingColor,
                  fontSize: 64,
                  height: 0.92,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                l10n.nutritionRemainingLabel,
                style: TextStyle(
                  color: remainingColor.withValues(alpha: 0.8),
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                over > 0
                    ? l10n.nutritionOverGoal(calories.format(over))
                    : l10n.nutritionEatenKcal(
                        calories.format(consumed.caloriesKcal),
                      ),
                style: TextStyle(
                  color: context.palette.onInkMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  minHeight: 7,
                  value: progress,
                  backgroundColor: Colors.white.withValues(alpha: 0.12),
                  color: over > 0
                      ? context.palette.amber
                      : context.palette.lime,
                ),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: _MacroGoalRing(
                      label: l10n.nutritionProteinShort,
                      color: context.palette.aqua,
                      consumed: consumed.proteinGrams,
                      goal: goals.proteinGrams,
                    ),
                  ),
                  Expanded(
                    child: _MacroGoalRing(
                      label: l10n.nutritionCarbsShort,
                      color: context.palette.carbs,
                      consumed: consumed.carbsGrams,
                      goal: goals.carbsGrams,
                    ),
                  ),
                  Expanded(
                    child: _MacroGoalRing(
                      label: l10n.nutritionFatShort,
                      color: context.palette.coral,
                      consumed: consumed.fatGrams,
                      goal: goals.fatGrams,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MacroGoalRing extends StatelessWidget {
  const _MacroGoalRing({
    required this.label,
    required this.color,
    required this.consumed,
    required this.goal,
  });

  final String label;
  final Color color;
  final double consumed;
  final double goal;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    final grams = NumberFormat('0', locale);
    final progress = goal <= 0 ? 0.0 : (consumed / goal).clamp(0.0, 1.0);
    return Column(
      children: [
        SizedBox(
          width: 72,
          height: 72,
          child: CustomPaint(
            painter: _RingPainter(progress: progress, color: color),
            child: Center(
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          context.l10n.nutritionOfGoalGrams(
            grams.format(consumed),
            grams.format(goal),
          ),
          textAlign: TextAlign.center,
          style: TextStyle(
            color: context.palette.onInkMuted,
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 5;
    final track = Paint()
      ..color = Colors.white.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;
    final fill = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, track);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      math.pi * 2 * progress,
      false,
      fill,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}
