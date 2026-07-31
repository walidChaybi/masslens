import 'dart:io';

import 'package:flutter/material.dart';

import '../../../app/app_controller.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_components.dart';
import '../domain/measurement.dart';

class MeasurementDetailScreen extends StatelessWidget {
  const MeasurementDetailScreen({required this.measurement, super.key});

  final Measurement measurement;

  Future<void> _delete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete this estimate?'),
        content: const Text(
          'The saved result and its private image copy will be removed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.coral),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await AppScope.of(context).deleteMeasurement(measurement);
    if (context.mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved estimate'),
        actions: [
          IconButton(
            tooltip: 'Delete estimate',
            onPressed: () => _delete(context),
            icon: const Icon(Icons.delete_outline_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 34),
        children: [
          MeasurementSummary(
            measurement: measurement,
            unitSystem: AppScope.of(context).unitSystem,
          ),
        ],
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
    final file = File(measurement.imagePath);
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
                        color: AppColors.navySoft,
                        child: const Icon(
                          Icons.inventory_2_outlined,
                          size: 64,
                          color: AppColors.inkMuted,
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
                    measurement.category.toUpperCase(),
                    style: const TextStyle(
                      color: AppColors.limeDark,
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
            StatusPill(label: measurement.isDemo ? 'Demo' : 'AI estimate'),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: AppColors.ink,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'ESTIMATED WEIGHT',
                style: TextStyle(
                  color: Colors.white60,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.3,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                formatWeight(measurement.estimateGrams, unitSystem),
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
                      color: AppColors.lime,
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: ConfidenceBadge(level: measurement.confidence),
                  ),
                  const Spacer(),
                  const Icon(Icons.show_chart_rounded, color: AppColors.aqua),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _ResultSection(
          title: 'Likely range',
          icon: Icons.linear_scale_rounded,
          child: Text(
            '${formatWeight(measurement.lowerBoundGrams, unitSystem)} — '
            '${formatWeight(measurement.upperBoundGrams, unitSystem)}',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
        ),
        const SizedBox(height: 12),
        _ResultSection(
          title: 'Estimated dimensions',
          icon: Icons.straighten_rounded,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                formatDimensions(measurement.dimensions, unitSystem),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 5),
              Text(
                'Width × height × depth',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _ResultSection(
          title: 'Assumptions',
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
            color: AppColors.lime.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(22),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline_rounded, color: AppColors.ink),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'This is an informed visual estimate, not a sensor reading. '
                  'Do not use it for safety-critical decisions.',
                  style: TextStyle(
                    color: AppColors.ink,
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
                Icon(icon, size: 19, color: AppColors.limeDark),
                const SizedBox(width: 8),
                Text(
                  title.toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.inkMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
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
        color: AppColors.navySoft,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(
              Icons.check_circle_outline_rounded,
              size: 16,
              color: AppColors.limeDark,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.ink,
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
