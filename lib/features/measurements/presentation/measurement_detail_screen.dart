import 'dart:ui' as ui;
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../app/app_controller.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_components.dart';
import '../../../l10n/display_labels.dart';
import '../../../l10n/l10n.dart';
import 'share_card.dart';
import '../domain/fun_weight_comparisons.dart';
import '../domain/measurement.dart';

class MeasurementDetailScreen extends StatefulWidget {
  const MeasurementDetailScreen({required this.measurement, super.key});

  final Measurement measurement;

  Future<void> _delete(BuildContext context) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.detailDeleteTitle),
        content: Text(l10n.detailDeleteBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(
              backgroundColor: context.palette.coral,
            ).copyWith(),
            child: Text(l10n.commonDelete),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await AppScope.of(context).deleteMeasurement(measurement);
    if (context.mounted) Navigator.of(context).pop();
  }

  @override
  State<MeasurementDetailScreen> createState() =>
      _MeasurementDetailScreenState();
}

class _MeasurementDetailScreenState extends State<MeasurementDetailScreen> {
  final _shareCardKey = GlobalKey();
  bool _sharing = false;

  Future<void> _share() async {
    if (_sharing) return;
    final measurement = widget.measurement;
    final unitSystem = AppScope.of(context).unitSystem;
    final localeName = Localizations.localeOf(context).toLanguageTag();
    setState(() => _sharing = true);
    try {
      await Future<void>.delayed(Duration.zero);
      final renderObject = _shareCardKey.currentContext?.findRenderObject();
      if (renderObject is! RenderRepaintBoundary) return;
      final boundary = renderObject;

      final image = await boundary.toImage(pixelRatio: 2.4);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData?.buffer.asUint8List();
      if (bytes == null) return;

      final file = File(
        '${(await getTemporaryDirectory()).path}/masslens_share_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await file.writeAsBytes(bytes);

      final weightText = formatWeight(
        measurement.totalEstimateGrams,
        unitSystem,
        localeName: localeName,
      );

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          text:
              '${measurement.mealLabel ?? measurement.objectLabel} — $weightText',
        ),
      );
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.detailSavedEstimate),
        actions: [
          IconButton(
            tooltip: l10n.detailDeleteTooltip,
            onPressed: () => widget._delete(context),
            icon: const Icon(Icons.delete_outline_rounded),
          ),
          const SizedBox(width: 8),
          IconButton(
            key: const Key('share_saved_result_button'),
            tooltip: l10n.commonShare,
            onPressed: _sharing ? null : _share,
            icon: const Icon(Icons.share_rounded),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        maintainBottomViewPadding: true,
        child: Stack(
          children: [
            ListView(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 34),
              children: [
                MeasurementSummary(
                  measurement: widget.measurement,
                  unitSystem: AppScope.of(context).unitSystem,
                ),
              ],
            ),
            Positioned(
              left: -12000,
              top: 0,
              child: RepaintBoundary(
                key: _shareCardKey,
                child: MeasurementShareCard(
                  measurement: widget.measurement,
                  unitSystem: AppScope.of(context).unitSystem,
                  localeName: Localizations.localeOf(context).toLanguageTag(),
                  funComparisonText: widget.measurement.isFoodPlate
                      ? null
                      : switch (buildFunWeightComparisons(
                          widget.measurement.estimateGrams,
                        )) {
                          final fun? => localizedFunWeightComparison(l10n, fun),
                          null => null,
                        },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MeasurementSummary extends StatelessWidget {
  const MeasurementSummary({
    required this.measurement,
    required this.unitSystem,
    super.key,
  });

  final Measurement measurement;
  final UnitSystem unitSystem;

  @override
  Widget build(BuildContext context) {
    if (measurement.isFoodPlate) {
      return _FoodMeasurementSummary(
        measurement: measurement,
        unitSystem: unitSystem,
      );
    }

    final file = File(measurement.imagePath);
    final l10n = context.l10n;
    final localeName = Localizations.localeOf(context).toLanguageTag();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AspectRatio(
          key: const Key('result_photo'),
          aspectRatio: 4 / 3,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Stack(
              fit: StackFit.expand,
              children: [
                file.existsSync()
                    ? Image.file(file, fit: BoxFit.cover)
                    : Container(
                        color: context.palette.navySoft,
                        child: Icon(
                          Icons.inventory_2_outlined,
                          size: 64,
                          color: context.palette.inkMuted,
                        ),
                      ),
                const InstrumentCorners(),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    localizedCategory(l10n, measurement.category).toUpperCase(),
                    style: TextStyle(
                      color: context.palette.limeDark,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    measurement.objectLabel,
                    key: const Key('result_object_label'),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            StatusPill(label: l10n.detailAiEstimate),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: context.palette.ink,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.detailEstimatedWeight,
                style: const TextStyle(
                  color: Colors.white60,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.3,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                formatWeight(
                  measurement.estimateGrams,
                  unitSystem,
                  localeName: localeName,
                ),
                key: const Key('result_weight'),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 46,
                  height: 1,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -2,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(height: 13),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 11,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: context.palette.lime,
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: ConfidenceBadge(level: measurement.confidence),
                  ),
                  const Spacer(),
                  Icon(Icons.show_chart_rounded, color: context.palette.aqua),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _ResultSection(
          title: l10n.detailLikelyRange,
          icon: Icons.linear_scale_rounded,
          child: Text(
            '${formatWeight(measurement.lowerBoundGrams, unitSystem, localeName: localeName)} — '
            '${formatWeight(measurement.upperBoundGrams, unitSystem, localeName: localeName)}',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
        ),
        const SizedBox(height: 12),
        if (buildFunWeightComparisons(measurement.estimateGrams)
            case final fun?)
          Text(
            localizedFunWeightComparison(l10n, fun),
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        const SizedBox(height: 12),
        if (measurement.dimensions case final dimensions?) ...[
          _ResultSection(
            title: l10n.detailAiVisualSize,
            icon: Icons.straighten_rounded,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  formatApproximateDimensions(
                    dimensions,
                    unitSystem,
                    localeName: localeName,
                  ),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 5),
                Text(
                  l10n.detailDimensionOrder,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
        _ResultSection(
          title: l10n.detailAssumptions,
          icon: Icons.tune_rounded,
          child: Column(
            children: [
              for (
                var index = 0;
                index < measurement.assumptions.length;
                index++
              ) ...[
                if (index > 0) const SizedBox(height: 8),
                _AssumptionItem(label: measurement.assumptions[index]),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: context.palette.lime.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline_rounded, color: context.palette.ink),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  l10n.detailSafetyNotice,
                  style: TextStyle(
                    color: context.palette.ink,
                    height: 1.45,
                    fontSize: 12.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FoodMeasurementSummary extends StatelessWidget {
  const _FoodMeasurementSummary({
    required this.measurement,
    required this.unitSystem,
  });

  final Measurement measurement;
  final UnitSystem unitSystem;

  @override
  Widget build(BuildContext context) {
    final file = File(measurement.imagePath);
    final l10n = context.l10n;
    final localeName = Localizations.localeOf(context).toLanguageTag();
    final number = NumberFormat('0', localeName);
    final decimal = NumberFormat('0.0', localeName);
    final nutrition = measurement.nutritionTotals;
    final calorieLowerBound = measurement.calorieLowerBoundKcal;
    final calorieUpperBound = measurement.calorieUpperBoundKcal;
    final assumptions = measurement.assumptions.take(3).toList(growable: false);

    return Column(
      key: const Key('food_measurement_summary'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AspectRatio(
          key: const Key('result_photo'),
          aspectRatio: 4 / 3,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Stack(
              fit: StackFit.expand,
              children: [
                file.existsSync()
                    ? Image.file(file, fit: BoxFit.cover)
                    : Container(
                        color: context.palette.navySoft,
                        child: Icon(
                          Icons.restaurant_rounded,
                          size: 64,
                          color: context.palette.inkMuted,
                        ),
                      ),
                const InstrumentCorners(),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.scanFoodScale.toUpperCase(),
                    style: TextStyle(
                      color: context.palette.limeDark,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    measurement.mealLabel ?? measurement.objectLabel,
                    key: const Key('result_object_label'),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            StatusPill(
              label: l10n.detailAiEstimate,
              icon: Icons.auto_awesome_rounded,
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: context.palette.ink,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.scanFoodTotalWeight.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white60,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.3,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                formatWeight(
                  measurement.totalEstimateGrams,
                  unitSystem,
                  localeName: localeName,
                ),
                key: const Key('result_weight'),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 46,
                  height: 1,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -2,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '${formatWeight(measurement.totalLowerBoundGrams, unitSystem, localeName: localeName)} — '
                '${formatWeight(measurement.totalUpperBoundGrams, unitSystem, localeName: localeName)}',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 13),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 11,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: context.palette.lime,
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: ConfidenceBadge(level: measurement.confidence),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.restaurant_menu_rounded,
                    color: context.palette.aqua,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _ResultSection(
          title: l10n.scanNutrition,
          icon: Icons.donut_large_rounded,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: measurement.hasNutritionData
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                number.format(nutrition.caloriesKcal),
                                key: const Key('food_total_calories'),
                                style: TextStyle(
                                  color: context.palette.ink,
                                  fontSize: 42,
                                  height: 0.95,
                                  fontWeight: FontWeight.w900,
                                  fontFeatures: [FontFeature.tabularFigures()],
                                ),
                              ),
                              const SizedBox(width: 7),
                              Padding(
                                padding: const EdgeInsets.only(bottom: 3),
                                child: Text(
                                  'kcal',
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(fontWeight: FontWeight.w800),
                                ),
                              ),
                            ],
                          )
                        : Text(
                            l10n.scanNutritionMissing,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                  ),
                  const SizedBox(width: 10),
                  StatusPill(
                    label: measurement.hasPartialNutrition
                        ? l10n.scanPartialTotal
                        : l10n.scanCompleteTotal,
                    background: measurement.hasPartialNutrition
                        ? context.palette.aqua.withValues(alpha: 0.25)
                        : context.palette.lime.withValues(alpha: 0.45),
                  ),
                ],
              ),
              if (calorieLowerBound != null && calorieUpperBound != null) ...[
                const SizedBox(height: 10),
                Text(
                  '${l10n.scanLikelyRange}: '
                  '${number.format(calorieLowerBound)}–${number.format(calorieUpperBound)} kcal',
                  style: TextStyle(
                    color: context.palette.inkMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
              if (measurement.hasNutritionData) ...[
                const SizedBox(height: 18),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _NutritionMetric(
                      label: l10n.scanProtein,
                      value: '${decimal.format(nutrition.proteinGrams)} g',
                    ),
                    _NutritionMetric(
                      label: l10n.scanCarbs,
                      value: '${decimal.format(nutrition.carbsGrams)} g',
                    ),
                    _NutritionMetric(
                      label: l10n.scanFat,
                      value: '${decimal.format(nutrition.fatGrams)} g',
                    ),
                  ],
                ),
              ],
              if (measurement.hasPartialNutrition) ...[
                const SizedBox(height: 14),
                Text(
                  l10n.scanNutritionMissing,
                  style: TextStyle(
                    color: context.palette.inkMuted,
                    fontSize: 12,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        _ResultSection(
          title: l10n.scanFoodComponents,
          icon: Icons.ramen_dining_rounded,
          child: Column(
            children: [
              for (
                var index = 0;
                index < measurement.foodComponents.length;
                index++
              ) ...[
                if (index > 0) const Divider(height: 28),
                _FoodComponentSummary(
                  index: index,
                  component: measurement.foodComponents[index],
                  unitSystem: unitSystem,
                  localeName: localeName,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        _ResultSection(
          title: l10n.detailAssumptions,
          icon: Icons.tune_rounded,
          child: Column(
            children: [
              for (var index = 0; index < assumptions.length; index++) ...[
                if (index > 0) const SizedBox(height: 8),
                _AssumptionItem(label: assumptions[index]),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: context.palette.lime.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline_rounded, color: context.palette.ink),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  l10n.scanFoodDisclaimer,
                  key: const Key('food_disclaimer'),
                  style: TextStyle(
                    color: context.palette.ink,
                    height: 1.45,
                    fontSize: 12.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FoodComponentSummary extends StatelessWidget {
  const _FoodComponentSummary({
    required this.index,
    required this.component,
    required this.unitSystem,
    required this.localeName,
  });

  final int index;
  final FoodComponent component;
  final UnitSystem unitSystem;
  final String localeName;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final number = NumberFormat('0', localeName);
    final decimal = NumberFormat('0.0', localeName);
    final nutrition = component.effectiveNutrition;

    return Semantics(
      container: true,
      label: component.label,
      child: Column(
        key: ValueKey('food_detail_component_$index'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  component.label,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                formatWeight(
                  component.effectiveGrams,
                  unitSystem,
                  localeName: localeName,
                ),
                style: TextStyle(
                  color: context.palette.ink,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            '${l10n.scanOriginalAiRange}: '
            '${formatWeight(component.lowerBoundGrams, unitSystem, localeName: localeName)} — '
            '${formatWeight(component.upperBoundGrams, unitSystem, localeName: localeName)}',
            style: TextStyle(
              color: context.palette.inkMuted,
              fontSize: 11.5,
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            '${l10n.scanConfidence}: ${localizedConfidence(l10n, component.confidence)}',
            style: TextStyle(
              color: context.palette.inkMuted,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (component.userAdjustedGrams != null) ...[
            const SizedBox(height: 5),
            Row(
              children: [
                Icon(
                  Icons.edit_rounded,
                  size: 13,
                  color: context.palette.limeDark,
                ),
                const SizedBox(width: 5),
                Text(
                  l10n.scanEditAmount,
                  style: TextStyle(
                    color: context.palette.limeDark,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          if (nutrition == null)
            Text(
              l10n.scanNutritionMissing,
              key: ValueKey('food_detail_weight_only_$index'),
              style: TextStyle(
                color: context.palette.inkMuted,
                fontSize: 12,
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            )
          else ...[
            Wrap(
              spacing: 12,
              runSpacing: 5,
              children: [
                Text(
                  '${number.format(nutrition.caloriesKcal)} kcal',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                Text(
                  '${l10n.scanProtein} ${decimal.format(nutrition.proteinGrams)} g',
                ),
                Text(
                  '${l10n.scanCarbs} ${decimal.format(nutrition.carbsGrams)} g',
                ),
                Text('${l10n.scanFat} ${decimal.format(nutrition.fatGrams)} g'),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              l10n.scanUsdaSource.toUpperCase(),
              style: TextStyle(
                color: context.palette.inkMuted,
                fontSize: 9.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              component.nutrition!.description,
              style: TextStyle(
                color: context.palette.ink,
                fontSize: 12,
                height: 1.35,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${component.nutrition!.dataType} · FDC ${component.nutrition!.fdcId}',
              style: TextStyle(
                color: context.palette.inkMuted,
                fontSize: 10.5,
                height: 1.3,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _NutritionMetric extends StatelessWidget {
  const _NutritionMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 92),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: context.palette.navySoft,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: context.palette.inkMuted,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              color: context.palette.ink,
              fontSize: 14,
              fontWeight: FontWeight.w900,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultSection extends StatelessWidget {
  const _ResultSection({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 19, color: context.palette.limeDark),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title.toUpperCase(),
                    style: TextStyle(
                      color: context.palette.inkMuted,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.1,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 13),
            child,
          ],
        ),
      ),
    );
  }
}

class _AssumptionItem extends StatelessWidget {
  const _AssumptionItem({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: context.palette.navySoft,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(
              Icons.check_circle_outline_rounded,
              size: 16,
              color: context.palette.limeDark,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: context.palette.ink,
                fontSize: 12,
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
