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
      key: const Key('history_screen'),
      maintainBottomViewPadding: true,
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
                            style: Theme.of(
                              context,
                            ).textTheme.headlineLarge?.copyWith(fontSize: 28),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    IconButton.filled(
                      tooltip: l10n.historyNewEstimate,
                      onPressed: widget.onScan,
                      style: IconButton.styleFrom(
                        backgroundColor: context.palette.lime,
                        foregroundColor: context.palette.onLime,
                        fixedSize: const Size.square(52),
                      ),
                      icon: const Icon(Icons.add_rounded, size: 26),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
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
                      onTap: () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => MeasurementDetailScreen(
                              measurement: visible[index],
                            ),
                          ),
                        );
                        if (!mounted) return;
                        await controller.monetization.onHistoryDetailClosed();
                      },
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
      padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [context.palette.inkRaised, context.palette.inkDeep],
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _StatValue(value: '$total', label: l10n.historySavedStat),
          ),
          Container(
            width: 1,
            height: 40,
            margin: const EdgeInsets.symmetric(horizontal: 14),
            color: Colors.white.withValues(alpha: 0.12),
          ),
          Expanded(
            child: _StatValue(
              value: '$categories',
              label: l10n.historyCategoriesStat,
            ),
          ),
          const SizedBox(width: 8),
          StatusPill(
            label: l10n.historyLocalBadge,
            icon: Icons.lock_outline_rounded,
            background: Colors.white.withValues(alpha: 0.10),
            foreground: context.palette.lime,
          ),
        ],
      ),
    );
  }
}

class _StatValue extends StatelessWidget {
  const _StatValue({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            height: 1.05,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: context.palette.onInkMuted,
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
