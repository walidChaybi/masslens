import 'package:flutter/material.dart';

import '../../../app/app_controller.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_components.dart';
import '../../measurements/presentation/measurement_detail_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({required this.onScan, super.key});

  final VoidCallback onScan;

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String _filter = 'All';

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final categories = {
      'All',
      ...controller.measurements.map((item) => item.category),
    }.toList();
    if (!categories.contains(_filter)) _filter = 'All';
    final visible = _filter == 'All'
        ? controller.measurements
        : controller.measurements
              .where((item) => item.category == _filter)
              .toList();

    return SafeArea(
      bottom: false,
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
            sliver: SliverList.list(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Eyebrow('Private on-device log'),
                          const SizedBox(height: 8),
                          Text(
                            'Measurement history',
                            style: Theme.of(context).textTheme.headlineLarge,
                          ),
                        ],
                      ),
                    ),
                    IconButton.filledTonal(
                      tooltip: 'New estimate',
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
                      itemCount: categories.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final filter = categories[index];
                        return ChoiceChip(
                          label: Text(filter),
                          selected: filter == _filter,
                          onSelected: (_) => setState(() => _filter = filter),
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
                        ? 'Nothing saved yet'
                        : 'No $_filter estimates',
                    message: controller.measurements.isEmpty
                        ? 'Save a result after your first photo estimate and '
                              'it will appear here.'
                        : 'Choose another filter or make a new estimate.',
                    action: FilledButton.icon(
                      onPressed: widget.onScan,
                      icon: const Icon(Icons.center_focus_strong_rounded),
                      label: const Text('Start estimate'),
                    ),
                  )
                else
                  for (final measurement in visible) ...[
                    MeasurementCard(
                      measurement: measurement,
                      unitSystem: controller.unitSystem,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) =>
                              MeasurementDetailScreen(measurement: measurement),
                        ),
                      ),
                    ),
                    const SizedBox(height: 11),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: AppColors.ink,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          _Stat(value: '$total', label: 'Saved'),
          Container(
            width: 1,
            height: 38,
            margin: const EdgeInsets.symmetric(horizontal: 24),
            color: Colors.white.withValues(alpha: 0.15),
          ),
          _Stat(value: '$categories', label: 'Categories'),
          const Spacer(),
          const StatusPill(
            label: 'Local',
            icon: Icons.lock_outline_rounded,
            background: AppColors.lime,
          ),
        ],
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
