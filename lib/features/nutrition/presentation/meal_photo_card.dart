import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../l10n/display_labels.dart';
import '../../../l10n/l10n.dart';
import '../domain/nutrition_log.dart';

enum NutritionEntryAction { edit, delete }

class MealPhotoCard extends StatelessWidget {
  const MealPhotoCard({
    required this.entry,
    required this.imagePath,
    required this.onEdit,
    required this.onDelete,
    super.key,
  });

  final NutritionLogEntry entry;
  final String? imagePath;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final calories = NumberFormat('0', locale);
    final grams = NumberFormat('0', locale);
    return Container(
      key: Key('nutrition_meal_card_${entry.id}'),
      decoration: BoxDecoration(
        color: context.palette.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.palette.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: 4 / 3,
            child: imagePath == null
                ? ColoredBox(
                    color: context.palette.navySoft,
                    child: Icon(
                      Icons.restaurant_rounded,
                      color: context.palette.inkMuted,
                      size: 42,
                    ),
                  )
                : Image.file(
                    File(imagePath!),
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => ColoredBox(
                      color: context.palette.navySoft,
                      child: Icon(
                        Icons.restaurant_rounded,
                        color: context.palette.inkMuted,
                        size: 42,
                      ),
                    ),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 8, 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.label,
                        style: TextStyle(
                          color: context.palette.ink,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${localizedMealType(l10n, entry.mealType)} · ${DateFormat.jm(locale).format(entry.loggedAt)}',
                        style: TextStyle(
                          color: context.palette.inkMuted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        l10n.nutritionKcal(
                          calories.format(entry.nutrition.caloriesKcal),
                        ),
                        style: TextStyle(
                          color: context.palette.ink,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        children: [
                          _MacroChip(
                            color: context.palette.aqua,
                            label:
                                '${l10n.nutritionProteinShort} ${grams.format(entry.nutrition.proteinGrams)}',
                          ),
                          _MacroChip(
                            color: context.palette.carbs,
                            label:
                                '${l10n.nutritionCarbsShort} ${grams.format(entry.nutrition.carbsGrams)}',
                          ),
                          _MacroChip(
                            color: context.palette.coral,
                            label:
                                '${l10n.nutritionFatShort} ${grams.format(entry.nutrition.fatGrams)}',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<NutritionEntryAction>(
                  tooltip: l10n.nutritionEntryActions,
                  color: context.palette.navySoft,
                  onSelected: (action) {
                    if (action == NutritionEntryAction.edit) {
                      onEdit();
                    } else {
                      onDelete();
                    }
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: NutritionEntryAction.edit,
                      child: Text(l10n.nutritionEdit),
                    ),
                    PopupMenuItem(
                      value: NutritionEntryAction.delete,
                      child: Text(l10n.commonDelete),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MacroChip extends StatelessWidget {
  const _MacroChip({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}
