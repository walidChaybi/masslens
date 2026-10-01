import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../l10n/l10n.dart';
import '../application/nutrition_diary_controller.dart';
import '../domain/nutrition_log.dart';
import '../../measurements/domain/measurement.dart';

class NutritionTrendsView extends StatefulWidget {
  const NutritionTrendsView({
    required this.diary,
    required this.endingOn,
    super.key,
  });

  final NutritionDiaryController diary;
  final DateTime endingOn;

  @override
  State<NutritionTrendsView> createState() => _NutritionTrendsViewState();
}

class _NutritionTrendsViewState extends State<NutritionTrendsView> {
  int _trendDays = 7;

  @override
  Widget build(BuildContext context) {
    final summary = widget.diary.periodSummary(
      endingOn: widget.endingOn,
      dayCount: _trendDays,
    );
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.nutritionTrendsTitle,
          style: TextStyle(
            color: context.palette.ink,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          key: const Key('nutrition_period_selector'),
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final days in [7, 30])
              ChoiceChip(
                label: Text(
                  days == 7
                      ? l10n.nutritionSevenDays
                      : l10n.nutritionThirtyDays,
                ),
                selected: _trendDays == days,
                showCheckmark: false,
                selectedColor: context.palette.ink,
                backgroundColor: context.palette.navySoft,
                labelStyle: TextStyle(
                  color: _trendDays == days
                      ? context.palette.onInk
                      : context.palette.ink,
                ),
                onSelected: (_) => setState(() => _trendDays = days),
              ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                value: NumberFormat(
                  '0',
                  Localizations.localeOf(context).toLanguageTag(),
                ).format(summary.averageOnLoggedDays.caloriesKcal),
                label: l10n.nutritionAverageLoggedDays,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatCard(
                value: '${summary.loggedDays}',
                label: l10n.nutritionLoggedDays,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _ChartCard(
          title: l10n.nutritionCaloriesTrend,
          child: _CaloriesBarChart(summary: summary),
        ),
        const SizedBox(height: 14),
        _ChartCard(
          title: l10n.nutritionMacroTrend,
          child: _MacroLineChart(summary: summary),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.palette.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.palette.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              color: context.palette.ink,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(color: context.palette.inkMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 12, 14),
      decoration: BoxDecoration(
        color: context.palette.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.palette.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: context.palette.ink,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(height: 230, child: child),
        ],
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
                FlLine(color: context.palette.line, strokeWidth: 1),
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
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 10,
                        color: context.palette.inkMuted,
                      ),
                    ),
                  );
                },
              ),
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
                        ? context.palette.ink
                        : context.palette.line,
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
                FlLine(color: context.palette.line, strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
          titlesData: const FlTitlesData(
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: true, reservedSize: 38),
            ),
            bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          lineBarsData: [
            line(context.palette.aqua, spots((t) => t.proteinGrams)),
            line(context.palette.carbs, spots((t) => t.carbsGrams)),
            line(context.palette.coral, spots((t) => t.fatGrams)),
          ],
        ),
      ),
    );
  }
}
