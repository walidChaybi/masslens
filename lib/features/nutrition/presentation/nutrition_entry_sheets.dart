import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../l10n/display_labels.dart';
import '../../../l10n/l10n.dart';
import '../../measurements/domain/measurement.dart';
import '../domain/nutrition_log.dart';

Future<NutritionLogEntry?> showNutritionManualEditor(
  BuildContext context, {
  NutritionLogEntry? existing,
  required DateTime initialDateTime,
}) {
  return showModalBottomSheet<NutritionLogEntry>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _ManualEntrySheet(
      existing: existing,
      initialDateTime: existing?.loggedAt ?? initialDateTime,
    ),
  );
}

Future<NutritionLogEntry?> showNutritionScanImport(
  BuildContext context, {
  required Measurement measurement,
  required DateTime initialDateTime,
}) {
  return showModalBottomSheet<NutritionLogEntry>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _ScanEntrySheet(
      measurement: measurement,
      initialDateTime: initialDateTime,
    ),
  );
}

class _ScanEntrySheet extends StatefulWidget {
  const _ScanEntrySheet({
    required this.measurement,
    required this.initialDateTime,
  });

  final Measurement measurement;
  final DateTime initialDateTime;

  @override
  State<_ScanEntrySheet> createState() => _ScanEntrySheetState();
}

class _ScanEntrySheetState extends State<_ScanEntrySheet> {
  late DateTime _loggedAt;
  late MealType _mealType;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loggedAt = widget.initialDateTime;
    _mealType = _defaultMealType(_loggedAt);
  }

  @override
  Widget build(BuildContext context) {
    final totals = widget.measurement.nutritionTotals;
    return SafeArea(
      top: false,
      maintainBottomViewPadding: true,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          0,
          20,
          20 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                context.l10n.nutritionAddFromScanTitle,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 6),
              Text(
                widget.measurement.mealLabel ?? widget.measurement.objectLabel,
              ),
              const SizedBox(height: 16),
              _ReadOnlyNutrition(totals: totals),
              const SizedBox(height: 16),
              _DateTimeMealFields(
                loggedAt: _loggedAt,
                mealType: _mealType,
                onDateChanged: (value) => setState(() => _loggedAt = value),
                onMealChanged: (value) => setState(() => _mealType = value),
              ),
              if (_error != null) ...[
                const SizedBox(height: 10),
                Text(_error!, style: TextStyle(color: context.palette.coral)),
              ],
              const SizedBox(height: 18),
              FilledButton(
                key: const Key('nutrition_save_scan_entry'),
                onPressed: _save,
                child: Text(context.l10n.commonSave),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _save() {
    if (_loggedAt.isAfter(DateTime.now())) {
      setState(() => _error = context.l10n.nutritionFutureDate);
      return;
    }
    Navigator.pop(
      context,
      NutritionLogEntry.fromMeasurement(
        id: _newNutritionId(),
        loggedAt: _loggedAt,
        mealType: _mealType,
        measurement: widget.measurement,
      ),
    );
  }
}

class _ManualEntrySheet extends StatefulWidget {
  const _ManualEntrySheet({this.existing, required this.initialDateTime});

  final NutritionLogEntry? existing;
  final DateTime initialDateTime;

  @override
  State<_ManualEntrySheet> createState() => _ManualEntrySheetState();
}

class _ManualEntrySheetState extends State<_ManualEntrySheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _labelController;
  late final TextEditingController _weightController;
  late final TextEditingController _caloriesController;
  late final TextEditingController _proteinController;
  late final TextEditingController _carbsController;
  late final TextEditingController _fatController;
  late DateTime _loggedAt;
  late MealType _mealType;
  String? _formError;

  @override
  void initState() {
    super.initState();
    final entry = widget.existing;
    _loggedAt = entry?.loggedAt ?? widget.initialDateTime;
    _mealType = entry?.mealType ?? _defaultMealType(_loggedAt);
    _labelController = TextEditingController(text: entry?.label ?? '');
    _weightController = TextEditingController(
      text: _editableNumber(entry?.weightGrams),
    );
    _caloriesController = TextEditingController(
      text: _editableNumber(entry?.nutrition.caloriesKcal),
    );
    _proteinController = TextEditingController(
      text: _editableNumber(entry?.nutrition.proteinGrams),
    );
    _carbsController = TextEditingController(
      text: _editableNumber(entry?.nutrition.carbsGrams),
    );
    _fatController = TextEditingController(
      text: _editableNumber(entry?.nutrition.fatGrams),
    );
  }

  @override
  void dispose() {
    _labelController.dispose();
    _weightController.dispose();
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SafeArea(
      top: false,
      maintainBottomViewPadding: true,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          0,
          20,
          20 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  widget.existing == null
                      ? l10n.nutritionAddManualTitle
                      : l10n.nutritionEditEntryTitle,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  key: const Key('nutrition_label_field'),
                  controller: _labelController,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    labelText: l10n.nutritionLabel,
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? l10n.nutritionRequiredLabel
                      : null,
                ),
                const SizedBox(height: 12),
                _DateTimeMealFields(
                  loggedAt: _loggedAt,
                  mealType: _mealType,
                  onDateChanged: (value) => setState(() => _loggedAt = value),
                  onMealChanged: (value) => setState(() => _mealType = value),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _weightController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: l10n.nutritionWeightOptional,
                    suffixText: 'g',
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) => _optionalPositiveValidator(value, l10n),
                ),
                const SizedBox(height: 12),
                _NumberField(
                  key: const Key('nutrition_calories_field'),
                  controller: _caloriesController,
                  label: l10n.nutritionCaloriesInput,
                  suffix: l10n.nutritionCaloriesUnit,
                ),
                const SizedBox(height: 12),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final fields = [
                      _NumberField(
                        controller: _proteinController,
                        label: l10n.nutritionProtein,
                        suffix: 'g',
                      ),
                      _NumberField(
                        controller: _carbsController,
                        label: l10n.nutritionCarbs,
                        suffix: 'g',
                      ),
                      _NumberField(
                        controller: _fatController,
                        label: l10n.nutritionFat,
                        suffix: 'g',
                      ),
                    ];
                    if (constraints.maxWidth < 430) {
                      return Column(
                        children: [
                          fields[0],
                          const SizedBox(height: 10),
                          fields[1],
                          const SizedBox(height: 10),
                          fields[2],
                        ],
                      );
                    }
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: fields[0]),
                        const SizedBox(width: 8),
                        Expanded(child: fields[1]),
                        const SizedBox(width: 8),
                        Expanded(child: fields[2]),
                      ],
                    );
                  },
                ),
                if (_formError != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    _formError!,
                    style: TextStyle(color: context.palette.coral),
                  ),
                ],
                const SizedBox(height: 18),
                FilledButton(
                  key: const Key('nutrition_save_manual_entry'),
                  onPressed: _save,
                  child: Text(l10n.commonSave),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _save() {
    setState(() => _formError = null);
    if (!_formKey.currentState!.validate()) return;
    if (_loggedAt.isAfter(DateTime.now())) {
      setState(() => _formError = context.l10n.nutritionFutureDate);
      return;
    }
    final nutrition = NutritionTotals(
      caloriesKcal: _parseNumber(_caloriesController.text) ?? 0,
      proteinGrams: _parseNumber(_proteinController.text) ?? 0,
      carbsGrams: _parseNumber(_carbsController.text) ?? 0,
      fatGrams: _parseNumber(_fatController.text) ?? 0,
    );
    if (nutrition.caloriesKcal == 0 &&
        nutrition.proteinGrams == 0 &&
        nutrition.carbsGrams == 0 &&
        nutrition.fatGrams == 0) {
      setState(() => _formError = context.l10n.nutritionAtLeastOneValue);
      return;
    }
    final existing = widget.existing;
    final entry = existing == null
        ? NutritionLogEntry.create(
            id: _newNutritionId(),
            loggedAt: _loggedAt,
            mealType: _mealType,
            label: _labelController.text,
            weightGrams: _parseNumber(_weightController.text),
            nutrition: nutrition,
          )
        : existing.copyWith(
            loggedAt: _loggedAt,
            mealType: _mealType,
            label: _labelController.text,
            weightGrams: _parseNumber(_weightController.text),
            nutrition: nutrition,
          );
    Navigator.pop(context, entry);
  }
}

class _NumberField extends StatelessWidget {
  const _NumberField({
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
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        suffixText: suffix,
        border: const OutlineInputBorder(),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) return null;
        final parsed = _parseNumber(value);
        return parsed == null || parsed < 0
            ? context.l10n.nutritionInvalidNumber
            : null;
      },
    );
  }
}

class _DateTimeMealFields extends StatelessWidget {
  const _DateTimeMealFields({
    required this.loggedAt,
    required this.mealType,
    required this.onDateChanged,
    required this.onMealChanged,
  });

  final DateTime loggedAt;
  final MealType mealType;
  final ValueChanged<DateTime> onDateChanged;
  final ValueChanged<MealType> onMealChanged;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<MealType>(
          initialValue: mealType,
          decoration: InputDecoration(
            labelText: context.l10n.nutritionMeal,
            border: const OutlineInputBorder(),
          ),
          items: [
            for (final type in MealType.values)
              DropdownMenuItem(
                value: type,
                child: Text(localizedMealType(context.l10n, type)),
              ),
          ],
          onChanged: (value) {
            if (value != null) onMealChanged(value);
          },
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final dateButton = OutlinedButton.icon(
              onPressed: () async {
                final today = nutritionDay(DateTime.now());
                final picked = await showDatePicker(
                  context: context,
                  initialDate: loggedAt.isAfter(today) ? today : loggedAt,
                  firstDate: DateTime(2020),
                  lastDate: today,
                );
                if (picked == null) return;
                onDateChanged(
                  DateTime(
                    picked.year,
                    picked.month,
                    picked.day,
                    loggedAt.hour,
                    loggedAt.minute,
                  ),
                );
              },
              icon: const Icon(Icons.calendar_today_outlined),
              label: Text(DateFormat.yMd(locale).format(loggedAt)),
            );
            final timeButton = OutlinedButton.icon(
              onPressed: () async {
                final picked = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.fromDateTime(loggedAt),
                );
                if (picked == null) return;
                onDateChanged(
                  DateTime(
                    loggedAt.year,
                    loggedAt.month,
                    loggedAt.day,
                    picked.hour,
                    picked.minute,
                  ),
                );
              },
              icon: const Icon(Icons.schedule_rounded),
              label: Text(DateFormat.jm(locale).format(loggedAt)),
            );
            if (constraints.maxWidth < 360) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [dateButton, const SizedBox(height: 8), timeButton],
              );
            }
            return Row(
              children: [
                Expanded(child: dateButton),
                const SizedBox(width: 8),
                Expanded(child: timeButton),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _ReadOnlyNutrition extends StatelessWidget {
  const _ReadOnlyNutrition({required this.totals});

  final NutritionTotals totals;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    final formatter = NumberFormat('0.#', locale);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.palette.navySoft,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '${context.l10n.nutritionKcal(formatter.format(totals.caloriesKcal))} · '
        '${context.l10n.nutritionProteinShort} '
        '${context.l10n.nutritionGrams(formatter.format(totals.proteinGrams))} · '
        '${context.l10n.nutritionCarbsShort} '
        '${context.l10n.nutritionGrams(formatter.format(totals.carbsGrams))} · '
        '${context.l10n.nutritionFatShort} '
        '${context.l10n.nutritionGrams(formatter.format(totals.fatGrams))}',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: context.palette.ink,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

MealType _defaultMealType(DateTime value) {
  if (value.hour < 11) return MealType.breakfast;
  if (value.hour < 15) return MealType.lunch;
  if (value.hour < 21) return MealType.dinner;
  return MealType.snack;
}

String _newNutritionId() =>
    'nutrition-${DateTime.now().microsecondsSinceEpoch}';

double? _parseNumber(String value) {
  final normalized = value.trim().replaceAll(',', '.');
  if (normalized.isEmpty) return null;
  final parsed = double.tryParse(normalized);
  return parsed?.isFinite == true ? parsed : null;
}

String _editableNumber(double? value) {
  if (value == null) return '';
  return value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toStringAsFixed(1);
}

String? _optionalPositiveValidator(String? value, AppLocalizations l10n) {
  if (value == null || value.trim().isEmpty) return null;
  final parsed = _parseNumber(value);
  return parsed == null || parsed <= 0 ? l10n.nutritionInvalidNumber : null;
}

/// Shared meal-type and date/time pickers for other diary entry sheets.
class NutritionDateTimeMealFields extends StatelessWidget {
  const NutritionDateTimeMealFields({
    required this.loggedAt,
    required this.mealType,
    required this.onDateChanged,
    required this.onMealChanged,
    super.key,
  });

  final DateTime loggedAt;
  final MealType mealType;
  final ValueChanged<DateTime> onDateChanged;
  final ValueChanged<MealType> onMealChanged;

  @override
  Widget build(BuildContext context) => _DateTimeMealFields(
    loggedAt: loggedAt,
    mealType: mealType,
    onDateChanged: onDateChanged,
    onMealChanged: onMealChanged,
  );
}

MealType defaultNutritionMealType(DateTime value) => _defaultMealType(value);

String newNutritionEntryId() => _newNutritionId();

double? parseNutritionNumber(String value) => _parseNumber(value);
