import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../domain/measurement.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/l10n.dart';

/// A deterministic, brand-styled card used for the system share sheet.
///
/// This widget is meant to be rendered inside a `RepaintBoundary` and captured
/// as a PNG (see `scan_screen.dart` / `measurement_detail_screen.dart`).
class MeasurementShareCard extends StatelessWidget {
  const MeasurementShareCard({
    required this.measurement,
    required this.unitSystem,
    required this.localeName,
    this.funComparisonText,
    super.key,
  });

  final Measurement measurement;
  final UnitSystem unitSystem;
  final String localeName;

  /// Already localized, e.g. "≈ 2 × smartphone".
  final String? funComparisonText;

  @override
  Widget build(BuildContext context) {
    if (measurement.isFoodPlate) {
      return _FoodMeasurementShareCard(
        measurement: measurement,
        unitSystem: unitSystem,
        localeName: localeName,
      );
    }

    return _ObjectMeasurementShareCard(
      measurement: measurement,
      unitSystem: unitSystem,
      localeName: localeName,
      funComparisonText: funComparisonText,
    );
  }
}

class _ObjectMeasurementShareCard extends StatelessWidget {
  const _ObjectMeasurementShareCard({
    required this.measurement,
    required this.unitSystem,
    required this.localeName,
    this.funComparisonText,
  });

  final Measurement measurement;
  final UnitSystem unitSystem;
  final String localeName;
  final String? funComparisonText;

  @override
  Widget build(BuildContext context) {
    final file = File(measurement.imagePath);
    return Container(
      width: 1080,
      height: 650,
      padding: const EdgeInsets.all(44),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(34),
        border: Border.all(color: AppColors.line, width: 3),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: SizedBox(
              width: 340,
              height: 340,
              child: file.existsSync()
                  ? Image.file(file, fit: BoxFit.cover)
                  : Container(
                      color: AppColors.navySoft,
                      alignment: Alignment.center,
                      child: const Icon(Icons.inventory_2_outlined, size: 90),
                    ),
            ),
          ),
          const SizedBox(width: 46),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'MassLens',
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 56,
                    height: 1,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1.2,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  measurement.objectLabel,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 44,
                    height: 1.1,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  formatWeight(
                    measurement.estimateGrams,
                    unitSystem,
                    localeName: localeName,
                  ),
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 82,
                    height: 0.95,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -2,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '${formatWeight(measurement.lowerBoundGrams, unitSystem, localeName: localeName)} — ${formatWeight(measurement.upperBoundGrams, unitSystem, localeName: localeName)}',
                  style: TextStyle(
                    color: AppColors.inkMuted,
                    fontSize: 30,
                    height: 1.2,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 18),
                if (funComparisonText != null)
                  Text(
                    funComparisonText!,
                    style: TextStyle(
                      color: AppColors.limeDark,
                      fontSize: 28,
                      height: 1.25,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FoodMeasurementShareCard extends StatelessWidget {
  const _FoodMeasurementShareCard({
    required this.measurement,
    required this.unitSystem,
    required this.localeName,
  });

  final Measurement measurement;
  final UnitSystem unitSystem;
  final String localeName;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final file = File(measurement.imagePath);
    final nutrition = measurement.nutritionTotals;
    final visibleItems = measurement.foodComponents.take(3).toList();
    final hiddenItemCount =
        measurement.foodComponents.length - visibleItems.length;
    final number = NumberFormat('0', localeName);
    final decimal = NumberFormat('0.0', localeName);

    return Container(
      key: const Key('food_share_card'),
      width: 1080,
      height: 650,
      padding: const EdgeInsets.all(44),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(34),
        border: Border.all(color: AppColors.line, width: 3),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 340,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: SizedBox(
                    width: 340,
                    height: 340,
                    child: file.existsSync()
                        ? Image.file(file, fit: BoxFit.cover)
                        : Container(
                            color: AppColors.navySoft,
                            alignment: Alignment.center,
                            child: const Icon(
                              Icons.restaurant_rounded,
                              size: 90,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.lime,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    measurement.hasPartialNutrition
                        ? l10n.scanPartialTotal
                        : l10n.scanCompleteTotal,
                    style: const TextStyle(
                      color: AppColors.ink,
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 46),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'MassLens · ${l10n.scanFoodScale}',
                  style: const TextStyle(
                    color: AppColors.limeDark,
                    fontSize: 25,
                    height: 1,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  measurement.mealLabel ?? measurement.objectLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 42,
                    height: 1.08,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  formatWeight(
                    measurement.totalEstimateGrams,
                    unitSystem,
                    localeName: localeName,
                  ),
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 72,
                    height: 0.95,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${formatWeight(measurement.totalLowerBoundGrams, unitSystem, localeName: localeName)} — '
                  '${formatWeight(measurement.totalUpperBoundGrams, unitSystem, localeName: localeName)}',
                  style: const TextStyle(
                    color: AppColors.inkMuted,
                    fontSize: 23,
                    height: 1.2,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 18),
                if (measurement.hasNutritionData) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        number.format(nutrition.caloriesKcal),
                        key: const Key('food_share_calories'),
                        style: const TextStyle(
                          color: AppColors.ink,
                          fontSize: 50,
                          height: 0.9,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 3),
                        child: Text(
                          'kcal',
                          style: TextStyle(
                            color: AppColors.inkMuted,
                            fontSize: 23,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '${l10n.scanProtein} ${decimal.format(nutrition.proteinGrams)} g   ·   '
                    '${l10n.scanCarbs} ${decimal.format(nutrition.carbsGrams)} g   ·   '
                    '${l10n.scanFat} ${decimal.format(nutrition.fatGrams)} g',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.ink,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ] else
                  Text(
                    l10n.scanNutritionMissing,
                    style: const TextStyle(
                      color: AppColors.inkMuted,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                const SizedBox(height: 18),
                Text(
                  [
                    for (final item in visibleItems)
                      '${item.label} · ${formatWeight(item.effectiveGrams, unitSystem, localeName: localeName)}',
                    if (hiddenItemCount > 0) '+$hiddenItemCount',
                  ].join('   •   '),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.limeDark,
                    fontSize: 21,
                    height: 1.3,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                Text(
                  'USDA FoodData Central · ${l10n.scanFoodDisclaimer}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.inkMuted,
                    fontSize: 16,
                    height: 1.3,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
