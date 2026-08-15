import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../app/app_controller.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_components.dart';
import '../../../l10n/l10n.dart';
import '../../measurements/domain/measurement.dart';
import '../application/nutrition_diary_controller.dart';
import '../domain/nutrition_log.dart';

enum _NutritionView { day, trends }

enum _EntryAction { edit, delete }

class NutritionScreen extends StatefulWidget {
  const NutritionScreen({super.key});

  @override
  State<NutritionScreen> createState() => _NutritionScreenState();
}

class _NutritionScreenState extends State<NutritionScreen> {
  DateTime _selectedDay = nutritionDay(DateTime.now());
  _NutritionView _view = _NutritionView.day;
  int _trendDays = 7;

  bool get _isToday =>
      nutritionDayKey(_selectedDay) == nutritionDayKey(DateTime.now());

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final diary = controller.nutritionDiary;
    final day = diary.daySummary(_selectedDay);
    final horizontalPadding = math.max(
      20.0,
      (MediaQuery.sizeOf(context).width - 720) / 2,
    );

    return SafeArea(
      key: const Key('nutrition_screen'),
      child: ListView(
        padding: EdgeInsets.fromLTRB(
          horizontalPadding,
          18,
          horizontalPadding,
          36,
        ),
        children: [
          _NutritionHeader(totalEntries: diary.entries.length),
          const SizedBox(height: 20),
          SegmentedButton<_NutritionView>(
            key: const Key('nutrition_view_selector'),
            expandedInsets: EdgeInsets.zero,
            showSelectedIcon: false,
            segments: [
              ButtonSegment(
                value: _NutritionView.day,
                icon: const Icon(Icons.today_outlined),
                label: Text(context.l10n.nutritionDayTab),
              ),
              ButtonSegment(
                value: _NutritionView.trends,
                icon: const Icon(Icons.show_chart_rounded),
                label: Text(context.l10n.nutritionTrendsTab),
              ),
            ],
            selected: {_view},
            onSelectionChanged: (value) {
              setState(() => _view = value.single);
            },
          ),
          const SizedBox(height: 18),
          if (_view == _NutritionView.day)
            ..._buildDay(context, controller, day)
          else
            ..._buildTrends(context, diary),
          const SizedBox(height: 18),
          _PrivacyNotice(text: context.l10n.nutritionDisclaimer),
        ],
      ),
    );
  }

  List<Widget> _buildDay(
    BuildContext context,
    AppController controller,
    NutritionDaySummary summary,
  ) {
    final l10n = context.l10n;
    return [
      _DayNavigator(
        day: _selectedDay,
        isToday: _isToday,
        onPrevious: () {
          setState(() {
            _selectedDay = DateTime(
              _selectedDay.year,
              _selectedDay.month,
              _selectedDay.day - 1,
            );
          });
        },
        onNext: _isToday
            ? null
            : () {
                setState(() {
                  _selectedDay = DateTime(
                    _selectedDay.year,
                    _selectedDay.month,
                    _selectedDay.day + 1,
                  );
                });
              },
      ),
      const SizedBox(height: 14),
      _DailySummaryCard(summary: summary),
      if (summary.hasPartialData) ...[
        const SizedBox(height: 10),
        _PartialNotice(text: l10n.nutritionPartialNotice),
      ],
      const SizedBox(height: 18),
      _SectionActionHeader(
        title: l10n.nutritionMealsTitle,
        action: FilledButton.tonalIcon(
          key: const Key('nutrition_add_food'),
          onPressed: () => _showAddChoices(context, controller),
          icon: const Icon(Icons.add_rounded),
          label: Text(l10n.nutritionAddFood),
        ),
      ),
      const SizedBox(height: 12),
      if (!summary.hasEntries)
        EmptyPanel(
          icon: Icons.restaurant_menu_rounded,
          title: l10n.nutritionNoEntriesTitle,
          message: l10n.nutritionNoEntriesBody,
          action: FilledButton.icon(
            onPressed: () => _showAddChoices(context, controller),
            icon: const Icon(Icons.add_rounded),
            label: Text(l10n.nutritionAddFood),
          ),
        )
      else
        for (final mealType in MealType.values) ...[
          if (summary.entries.any((entry) => entry.mealType == mealType)) ...[
            _MealSection(
              mealType: mealType,
              entries: summary.entries
                  .where((entry) => entry.mealType == mealType)
                  .toList(growable: false),
              onEdit: (entry) => _editEntry(context, controller, entry),
              onDelete: (entry) => _deleteEntry(context, controller, entry),
            ),
            const SizedBox(height: 14),
          ],
        ],
    ];
  }

  List<Widget> _buildTrends(
    BuildContext context,
    NutritionDiaryController diary,
  ) {
    final summary = diary.periodSummary(
      endingOn: _selectedDay,
      dayCount: _trendDays,
    );
    final l10n = context.l10n;
    return [
      _SectionActionHeader(
        title: l10n.nutritionTrendsTitle,
        action: SegmentedButton<int>(
          key: const Key('nutrition_period_selector'),
          showSelectedIcon: false,
          segments: [
            ButtonSegment(value: 7, label: Text(l10n.nutritionSevenDays)),
            ButtonSegment(value: 30, label: Text(l10n.nutritionThirtyDays)),
          ],
          selected: {_trendDays},
          onSelectionChanged: (value) {
            setState(() => _trendDays = value.single);
          },
        ),
      ),
      const SizedBox(height: 14),
      _TrendStats(summary: summary),
      const SizedBox(height: 14),
      _ChartCard(
        title: l10n.nutritionCaloriesTrend,
        child: _CaloriesBarChart(summary: summary),
      ),
      const SizedBox(height: 14),
      _ChartCard(
        title: l10n.nutritionMacroTrend,
        legend: const _MacroLegend(),
        child: _MacroLineChart(summary: summary),
      ),
      if (summary.hasPartialData) ...[
        const SizedBox(height: 10),
        _PartialNotice(text: l10n.nutritionTrendPartialNotice),
      ],
    ];
  }

  Future<void> _showAddChoices(
    BuildContext context,
    AppController controller,
  ) async {
    final choice = await showModalBottomSheet<_AddChoice>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                context.l10n.nutritionAddFood,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 16),
              _AddChoiceTile(
                key: const Key('nutrition_add_from_scan'),
                icon: Icons.photo_camera_back_outlined,
                title: context.l10n.nutritionFromScans,
                body: context.l10n.nutritionFromScansBody,
                onTap: () => Navigator.pop(sheetContext, _AddChoice.scan),
              ),
              const SizedBox(height: 10),
              _AddChoiceTile(
                key: const Key('nutrition_add_manual'),
                icon: Icons.edit_note_rounded,
                title: context.l10n.nutritionManual,
                body: context.l10n.nutritionManualBody,
                onTap: () => Navigator.pop(sheetContext, _AddChoice.manual),
              ),
            ],
          ),
        ),
      ),
    );
    if (!context.mounted || choice == null) return;
    if (choice == _AddChoice.scan) {
      await _addFromScan(context, controller);
    } else {
      final entry = await _showManualEditor(context);
      if (entry != null) await controller.nutritionDiary.add(entry);
    }
  }

  Future<void> _addFromScan(
    BuildContext context,
    AppController controller,
  ) async {
    final scans = controller.measurements
        .where(
          (measurement) =>
              measurement.isFoodPlate && measurement.hasNutritionData,
        )
        .toList(growable: false);
    if (scans.isEmpty) {
      if (!context.mounted) return;
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(context.l10n.nutritionNoScansTitle),
          content: Text(context.l10n.nutritionNoScansBody),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(context.l10n.commonOk),
            ),
          ],
        ),
      );
      return;
    }
    final measurement = await showModalBottomSheet<Measurement>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(sheetContext).height * 0.72,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
                child: Text(
                  context.l10n.nutritionChooseScan,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  itemCount: scans.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (_, index) => MeasurementCard(
                    measurement: scans[index],
                    unitSystem: controller.unitSystem,
                    compact: true,
                    onTap: () => Navigator.pop(sheetContext, scans[index]),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (!context.mounted || measurement == null) return;
    final entry = await showModalBottomSheet<NutritionLogEntry>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _ScanEntrySheet(
        measurement: measurement,
        initialDateTime: _entryDateTime(),
      ),
    );
    if (entry != null) await controller.nutritionDiary.add(entry);
  }

  Future<NutritionLogEntry?> _showManualEditor(
    BuildContext context, {
    NutritionLogEntry? existing,
  }) {
    return showModalBottomSheet<NutritionLogEntry>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _ManualEntrySheet(
        existing: existing,
        initialDateTime: existing?.loggedAt ?? _entryDateTime(),
      ),
    );
  }

  Future<void> _editEntry(
    BuildContext context,
    AppController controller,
    NutritionLogEntry entry,
  ) async {
    final updated = await _showManualEditor(context, existing: entry);
    if (updated != null) await controller.nutritionDiary.update(updated);
  }

  Future<void> _deleteEntry(
    BuildContext context,
    AppController controller,
    NutritionLogEntry entry,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.l10n.nutritionDeleteTitle),
        content: Text(context.l10n.nutritionDeleteBody(entry.label)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(context.l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(context.l10n.commonDelete),
          ),
        ],
      ),
    );
    if (confirmed == true) await controller.nutritionDiary.delete(entry.id);
  }

  DateTime _entryDateTime() {
    final now = DateTime.now();
    if (_isToday) return now;
    return DateTime(
      _selectedDay.year,
      _selectedDay.month,
      _selectedDay.day,
      12,
    );
  }
}

enum _AddChoice { scan, manual }

class _NutritionHeader extends StatelessWidget {
  const _NutritionHeader({required this.totalEntries});

  final int totalEntries;

  @override
  Widget build(BuildContext context) {
    final title = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Eyebrow(context.l10n.nutritionEyebrow),
        const SizedBox(height: 7),
        Text(
          context.l10n.nutritionTitle,
          style: Theme.of(context).textTheme.headlineLarge,
        ),
      ],
    );
    final badge = StatusPill(
      label: context.l10n.nutritionLocalBadge,
      icon: Icons.lock_outline_rounded,
      background: AppColors.lime,
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 380) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [title, const SizedBox(height: 12), badge],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: title),
            const SizedBox(width: 12),
            badge,
          ],
        );
      },
    );
  }
}

class _SectionActionHeader extends StatelessWidget {
  const _SectionActionHeader({required this.title, required this.action});

  final String title;
  final Widget action;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final titleWidget = Text(
          title,
          style: Theme.of(context).textTheme.titleLarge,
        );
        if (constraints.maxWidth < 390) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [titleWidget, const SizedBox(height: 10), action],
          );
        }
        return Row(
          children: [
            Expanded(child: titleWidget),
            const SizedBox(width: 10),
            action,
          ],
        );
      },
    );
  }
}

class _DayNavigator extends StatelessWidget {
  const _DayNavigator({
    required this.day,
    required this.isToday,
    required this.onPrevious,
    required this.onNext,
  });

  final DateTime day;
  final bool isToday;
  final VoidCallback onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          children: [
            IconButton(
              tooltip: context.l10n.nutritionPreviousDay,
              onPressed: onPrevious,
              icon: const Icon(Icons.chevron_left_rounded),
            ),
            Expanded(
              child: Column(
                children: [
                  Text(
                    isToday
                        ? context.l10n.nutritionToday
                        : DateFormat.EEEE(locale).format(day),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    DateFormat.yMMMd(locale).format(day),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: context.l10n.nutritionNextDay,
              onPressed: onNext,
              icon: const Icon(Icons.chevron_right_rounded),
            ),
          ],
        ),
      ),
    );
  }
}

class _DailySummaryCard extends StatelessWidget {
  const _DailySummaryCard({required this.summary});

  final NutritionDaySummary summary;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.ink,
        borderRadius: BorderRadius.circular(20),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final ring = SizedBox(
            width: 156,
            height: 156,
            child: _MacroRing(totals: summary.totals),
          );
          final macros = _MacroCards(totals: summary.totals);
          if (constraints.maxWidth < 430) {
            return Column(children: [ring, const SizedBox(height: 16), macros]);
          }
          return Row(
            children: [
              ring,
              const SizedBox(width: 18),
              Expanded(child: macros),
            ],
          );
        },
      ),
    );
  }
}

class _MacroRing extends StatelessWidget {
  const _MacroRing({required this.totals});

  final NutritionTotals totals;

  @override
  Widget build(BuildContext context) {
    final macroCalories = [
      totals.proteinGrams * 4,
      totals.carbsGrams * 4,
      totals.fatGrams * 9,
    ];
    final hasMacros = macroCalories.any((value) => value > 0);
    final formatter = NumberFormat(
      '0',
      Localizations.localeOf(context).toLanguageTag(),
    );
    final semantics = context.l10n.nutritionMacroRingSemantics(
      totals.caloriesKcal.round(),
      totals.proteinGrams.round(),
      totals.carbsGrams.round(),
      totals.fatGrams.round(),
    );
    return Semantics(
      label: semantics,
      child: Stack(
        alignment: Alignment.center,
        children: [
          PieChart(
            PieChartData(
              startDegreeOffset: -90,
              centerSpaceRadius: 52,
              sectionsSpace: hasMacros ? 3 : 0,
              sections: hasMacros
                  ? [
                      PieChartSectionData(
                        value: macroCalories[0],
                        color: AppColors.aqua,
                        radius: 17,
                        showTitle: false,
                      ),
                      PieChartSectionData(
                        value: macroCalories[1],
                        color: AppColors.lime,
                        radius: 17,
                        showTitle: false,
                      ),
                      PieChartSectionData(
                        value: macroCalories[2],
                        color: AppColors.coral,
                        radius: 17,
                        showTitle: false,
                      ),
                    ]
                  : [
                      PieChartSectionData(
                        value: 1,
                        color: Colors.white.withValues(alpha: 0.12),
                        radius: 17,
                        showTitle: false,
                      ),
                    ],
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                formatter.format(totals.caloriesKcal),
                style: Theme.of(
                  context,
                ).textTheme.headlineMedium?.copyWith(color: Colors.white),
              ),
              Text(
                context.l10n.nutritionCaloriesUnit,
                style: const TextStyle(color: Colors.white70, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MacroCards extends StatelessWidget {
  const _MacroCards({required this.totals});

  final NutritionTotals totals;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _MacroCard(
          label: context.l10n.nutritionProtein,
          value: totals.proteinGrams,
          color: AppColors.aqua,
        ),
        _MacroCard(
          label: context.l10n.nutritionCarbs,
          value: totals.carbsGrams,
          color: AppColors.lime,
        ),
        _MacroCard(
          label: context.l10n.nutritionFat,
          value: totals.fatGrams,
          color: AppColors.coral,
        ),
      ],
    );
  }
}

class _MacroCard extends StatelessWidget {
  const _MacroCard({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat(
      '0.#',
      Localizations.localeOf(context).toLanguageTag(),
    );
    return Container(
      width: 112,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 4,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            context.l10n.nutritionGrams(formatter.format(value)),
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: Colors.white),
          ),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _MealSection extends StatelessWidget {
  const _MealSection({
    required this.mealType,
    required this.entries,
    required this.onEdit,
    required this.onDelete,
  });

  final MealType mealType;
  final List<NutritionLogEntry> entries;
  final ValueChanged<NutritionLogEntry> onEdit;
  final ValueChanged<NutritionLogEntry> onDelete;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 8),
          child: Text(
            _mealLabel(context, mealType),
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        for (var index = 0; index < entries.length; index++) ...[
          _NutritionEntryCard(
            entry: entries[index],
            onEdit: () => onEdit(entries[index]),
            onDelete: () => onDelete(entries[index]),
          ),
          if (index != entries.length - 1) const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _NutritionEntryCard extends StatelessWidget {
  const _NutritionEntryCard({
    required this.entry,
    required this.onEdit,
    required this.onDelete,
  });

  final NutritionLogEntry entry;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    final calories = NumberFormat(
      '0',
      locale,
    ).format(entry.nutrition.caloriesKcal);
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.navySoft,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.restaurant_rounded, color: AppColors.ink),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          entry.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      if (entry.isPartial) ...[
                        const SizedBox(width: 6),
                        StatusPill(
                          label: context.l10n.nutritionPartialShort,
                          background: AppColors.coral.withValues(alpha: 0.15),
                          foreground: AppColors.coral,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${DateFormat.jm(locale).format(entry.loggedAt)} · '
                    '${context.l10n.nutritionKcal(calories)} · '
                    '${context.l10n.nutritionMacroCompact(entry.nutrition.proteinGrams.round(), entry.nutrition.carbsGrams.round(), entry.nutrition.fatGrams.round())}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            PopupMenuButton<_EntryAction>(
              tooltip: context.l10n.nutritionEntryActions,
              onSelected: (action) {
                if (action == _EntryAction.edit) {
                  onEdit();
                } else {
                  onDelete();
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: _EntryAction.edit,
                  child: Text(context.l10n.nutritionEdit),
                ),
                PopupMenuItem(
                  value: _EntryAction.delete,
                  child: Text(context.l10n.commonDelete),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TrendStats extends StatelessWidget {
  const _TrendStats({required this.summary});

  final NutritionPeriodSummary summary;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    return Row(
      children: [
        Expanded(
          child: _TrendStatCard(
            value: NumberFormat(
              '0',
              locale,
            ).format(summary.averageOnLoggedDays.caloriesKcal),
            label: context.l10n.nutritionAverageLoggedDays,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _TrendStatCard(
            value: '${summary.loggedDays}',
            label: context.l10n.nutritionLoggedDays,
          ),
        ),
      ],
    );
  }
}

class _TrendStatCard extends StatelessWidget {
  const _TrendStatCard({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 3),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({required this.title, required this.child, this.legend});

  final String title;
  final Widget child;
  final Widget? legend;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 12, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final titleWidget = Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                );
                if (legend != null && constraints.maxWidth < 340) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [titleWidget, const SizedBox(height: 8), legend!],
                  );
                }
                return Row(
                  children: [
                    Expanded(child: titleWidget),
                    ?legend,
                  ],
                );
              },
            ),
            const SizedBox(height: 18),
            SizedBox(height: 230, child: child),
          ],
        ),
      ),
    );
  }
}

class _CaloriesBarChart extends StatelessWidget {
  const _CaloriesBarChart({required this.summary});

  final NutritionPeriodSummary summary;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    final maxCalories = summary.days.fold<double>(
      0,
      (maxValue, day) => math.max(maxValue, day.totals.caloriesKcal),
    );
    return Semantics(
      label: context.l10n.nutritionCaloriesChartSemantics(
        summary.days.length,
        summary.totals.caloriesKcal.round(),
      ),
      child: BarChart(
        BarChartData(
          minY: 0,
          maxY: maxCalories <= 0 ? 10 : maxCalories * 1.2,
          alignment: BarChartAlignment.spaceAround,
          gridData: FlGridData(
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) =>
                const FlLine(color: AppColors.line, strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: true, reservedSize: 42),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 34,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= summary.days.length) {
                    return const SizedBox.shrink();
                  }
                  if (summary.days.length > 7 &&
                      index != 0 &&
                      index != summary.days.length - 1 &&
                      index % 5 != 0) {
                    return const SizedBox.shrink();
                  }
                  final label = summary.days.length <= 7
                      ? DateFormat.E(locale).format(summary.days[index].day)
                      : DateFormat.Md(locale).format(summary.days[index].day);
                  return SideTitleWidget(
                    meta: meta,
                    child: Text(label, style: const TextStyle(fontSize: 10)),
                  );
                },
              ),
            ),
          ),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => AppColors.ink,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final day = summary.days[group.x].day;
                return BarTooltipItem(
                  '${DateFormat.MMMd(locale).format(day)}\n'
                  '${context.l10n.nutritionKcal(rod.toY.round().toString())}',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                );
              },
            ),
          ),
          barGroups: [
            for (var index = 0; index < summary.days.length; index++)
              BarChartGroupData(
                x: index,
                barRods: [
                  BarChartRodData(
                    toY: summary.days[index].totals.caloriesKcal,
                    color: summary.days[index].hasEntries
                        ? AppColors.ink
                        : AppColors.navySoft,
                    width: summary.days.length <= 7 ? 18 : 6,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(5),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _MacroLineChart extends StatelessWidget {
  const _MacroLineChart({required this.summary});

  final NutritionPeriodSummary summary;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    final maxMacro = summary.days.fold<double>(0, (maxValue, day) {
      return math.max(
        maxValue,
        math.max(
          day.totals.proteinGrams,
          math.max(day.totals.carbsGrams, day.totals.fatGrams),
        ),
      );
    });
    List<FlSpot> spots(double Function(NutritionTotals) select) => [
      for (var index = 0; index < summary.days.length; index++)
        FlSpot(index.toDouble(), select(summary.days[index].totals)),
    ];
    LineChartBarData line(Color color, List<FlSpot> values) => LineChartBarData(
      spots: values,
      color: color,
      barWidth: 3,
      isCurved: true,
      curveSmoothness: 0.25,
      dotData: FlDotData(show: summary.days.length <= 7),
      belowBarData: BarAreaData(show: false),
    );
    return Semantics(
      label: context.l10n.nutritionMacrosChartSemantics(summary.days.length),
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: (summary.days.length - 1).toDouble(),
          minY: 0,
          maxY: maxMacro <= 0 ? 10 : maxMacro * 1.2,
          gridData: FlGridData(
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) =>
                const FlLine(color: AppColors.line, strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: true, reservedSize: 38),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 34,
                getTitlesWidget: (value, meta) {
                  final index = value.round();
                  if (index < 0 || index >= summary.days.length) {
                    return const SizedBox.shrink();
                  }
                  if (summary.days.length > 7 &&
                      index != 0 &&
                      index != summary.days.length - 1 &&
                      index % 5 != 0) {
                    return const SizedBox.shrink();
                  }
                  final label = summary.days.length <= 7
                      ? DateFormat.E(locale).format(summary.days[index].day)
                      : DateFormat.Md(locale).format(summary.days[index].day);
                  return SideTitleWidget(
                    meta: meta,
                    child: Text(label, style: const TextStyle(fontSize: 10)),
                  );
                },
              ),
            ),
          ),
          lineBarsData: [
            line(AppColors.aqua, spots((value) => value.proteinGrams)),
            line(AppColors.limeDark, spots((value) => value.carbsGrams)),
            line(AppColors.coral, spots((value) => value.fatGrams)),
          ],
        ),
      ),
    );
  }
}

class _MacroLegend extends StatelessWidget {
  const _MacroLegend();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _LegendDot(
          color: AppColors.aqua,
          label: context.l10n.nutritionProteinShort,
        ),
        const SizedBox(width: 7),
        _LegendDot(
          color: AppColors.limeDark,
          label: context.l10n.nutritionCarbsShort,
        ),
        const SizedBox(width: 7),
        _LegendDot(
          color: AppColors.coral,
          label: context.l10n.nutritionFatShort,
        ),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 3),
        Text(label, style: const TextStyle(fontSize: 10)),
      ],
    );
  }
}

class _PartialNotice extends StatelessWidget {
  const _PartialNotice({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.coral.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.coral.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: AppColors.coral),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodySmall),
          ),
        ],
      ),
    );
  }
}

class _PrivacyNotice extends StatelessWidget {
  const _PrivacyNotice({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.lock_outline_rounded,
          size: 17,
          color: AppColors.inkMuted,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text, style: Theme.of(context).textTheme.bodySmall),
        ),
      ],
    );
  }
}

class _AddChoiceTile extends StatelessWidget {
  const _AddChoiceTile({
    required this.icon,
    required this.title,
    required this.body,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final String title;
  final String body;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Icon(icon, color: AppColors.ink),
        title: Text(title, style: Theme.of(context).textTheme.titleMedium),
        subtitle: Text(body),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      ),
    );
  }
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
    return Padding(
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
              Text(_error!, style: const TextStyle(color: AppColors.coral)),
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
    return Padding(
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
                  style: const TextStyle(color: AppColors.coral),
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
                child: Text(_mealLabel(context, type)),
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
        color: AppColors.navySoft,
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
          color: AppColors.ink,
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

String _mealLabel(BuildContext context, MealType type) => switch (type) {
  MealType.breakfast => context.l10n.nutritionBreakfast,
  MealType.lunch => context.l10n.nutritionLunch,
  MealType.dinner => context.l10n.nutritionDinner,
  MealType.snack => context.l10n.nutritionSnack,
};

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
