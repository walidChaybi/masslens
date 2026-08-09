import 'package:flutter/material.dart';

import '../../../app/app_controller.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_components.dart';
import '../../../l10n/display_labels.dart';
import '../../../l10n/l10n.dart';
import '../../measurements/presentation/measurement_detail_screen.dart';
import '../../monetization/presentation/native_ad_card.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({required this.onScan, super.key});

  final VoidCallback onScan;

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String? _filterCategory;

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final l10n = context.l10n;
    final categories = controller.measurements
        .map((item) => item.category)
        .toSet()
        .toList();
    if (_filterCategory != null && !categories.contains(_filterCategory)) {
      _filterCategory = null;
    }
    final filterOptions = <String?>[null, ...categories];
    final visible = _filterCategory == null
        ? controller.measurements
        : controller.measurements
              .where((item) => item.category == _filterCategory)
              .toList();

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            sliver: SliverList.list(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Eyebrow(l10n.historyEyebrow),
                          const SizedBox(height: 8),
                          Text(
                            l10n.historyTitle,
                            style: Theme.of(context).textTheme.headlineLarge,
                          ),
                        ],
                      ),
                    ),
                    IconButton.filledTonal(
                      tooltip: l10n.historyNewEstimate,
                      onPressed: widget.onScan,
                      icon: const Icon(Icons.add_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                _HistoryStats(
                  total: controller.measurements.length,
                  categories: controller.measurements
                      .map((item) => item.category)
                      .toSet()
                      .length,
                ),
                if (controller.measurements.isNotEmpty) ...[
                  const SizedBox(height: 22),
                  SizedBox(
                    height: 42,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: filterOptions.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final filter = filterOptions[index];
                        return ChoiceChip(
                          label: Text(
                            filter == null
                                ? l10n.historyAll
                                : localizedCategory(l10n, filter),
                          ),
                          selected: filter == _filterCategory,
                          onSelected: (_) =>
                              setState(() => _filterCategory = filter),
                        );
                      },
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                if (visible.isEmpty)
                  EmptyPanel(
                    icon: Icons.inventory_2_outlined,
                    title: controller.measurements.isEmpty
                        ? l10n.historyNothingSaved
                        : l10n.historyNoCategoryEstimates(
                            localizedCategory(l10n, _filterCategory!),
                          ),
                    message: controller.measurements.isEmpty
                        ? l10n.historyEmptyBody
                        : l10n.historyFilteredEmptyBody,
                    action: FilledButton.icon(
                      onPressed: widget.onScan,
                      icon: const Icon(Icons.center_focus_strong_rounded),
                      label: Text(l10n.historyStartEstimate),
                    ),
                  )
                else
                  for (var index = 0; index < visible.length; index++) ...[
                    MeasurementCard(
                      measurement: visible[index],
                      unitSystem: controller.unitSystem,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => MeasurementDetailScreen(
                            measurement: visible[index],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 11),
                    if (index == 1) ...[
                      NativeAdCard(
                        enabled: controller.monetization.canRequestNativeAds,
                        placement: 'history_after_second',
                        onPaidEvent: controller.monetization.reportPaidAd,
                      ),
                      const SizedBox(height: 11),
                    ],
                  ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryStats extends StatelessWidget {
  const _HistoryStats({required this.total, required this.categories});

  final int total;
  final int categories;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: AppColors.ink,
        borderRadius: BorderRadius.circular(24),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final divider = Container(
            width: 1,
            height: 38,
            margin: const EdgeInsets.symmetric(horizontal: 18),
            color: Colors.white.withValues(alpha: 0.15),
          );
          final localBadge = StatusPill(
            label: l10n.historyLocalBadge,
            icon: Icons.lock_outline_rounded,
            background: AppColors.lime,
          );
          if (constraints.maxWidth < 360) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _Stat(
                        value: '$total',
                        label: l10n.historySavedStat,
                      ),
                    ),
                    divider,
                    Expanded(
                      child: _Stat(
                        value: '$categories',
                        label: l10n.historyCategoriesStat,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                localBadge,
              ],
            );
          }
          return Row(
            children: [
              _Stat(value: '$total', label: l10n.historySavedStat),
              divider,
              _Stat(value: '$categories', label: l10n.historyCategoriesStat),
              const Spacer(),
              localBadge,
            ],
          );
        },
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white60, fontSize: 11),
        ),
      ],
    );
  }
}
