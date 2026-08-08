import 'package:flutter/material.dart';

import '../../../app/app_controller.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_components.dart';
import '../../measurements/domain/measurement.dart';
import '../../monetization/presentation/rewarded_scan_sheet.dart';
import '../../scan/data/estimate_repository_factory.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _clearHistory(BuildContext context) async {
    final controller = AppScope.of(context);
    if (controller.measurements.isEmpty) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Clear all history?'),
        content: Text(
          '${controller.measurements.length} saved estimate'
          '${controller.measurements.length == 1 ? '' : 's'} and private '
          'image copies will be deleted from this device.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.coral),
            child: const Text('Clear history'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await controller.clearHistory();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Measurement history cleared.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final monetization = controller.monetization;
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          const Eyebrow('Preferences and privacy'),
          const SizedBox(height: 8),
          Text('Settings', style: Theme.of(context).textTheme.headlineLarge),
          const SizedBox(height: 24),
          const _SettingsHeader(title: 'Measurement'),
          const SizedBox(height: 10),
          _SettingsCard(
            children: [
              Padding(
                padding: const EdgeInsets.all(17),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _SettingLabel(
                      icon: Icons.straighten_rounded,
                      title: 'Units',
                      subtitle: 'All values are stored canonically in metric.',
                    ),
                    const SizedBox(height: 16),
                    SegmentedButton<UnitSystem>(
                      expandedInsets: EdgeInsets.zero,
                      segments: const [
                        ButtonSegment(
                          value: UnitSystem.metric,
                          label: Text('Metric'),
                          icon: Icon(Icons.scale_outlined),
                        ),
                        ButtonSegment(
                          value: UnitSystem.imperial,
                          label: Text('Imperial'),
                          icon: Icon(Icons.monitor_weight_outlined),
                        ),
                      ],
                      selected: {controller.unitSystem},
                      onSelectionChanged: (selection) {
                        controller.setUnitSystem(selection.single);
                      },
                      showSelectedIcon: false,
                    ),
                  ],
                ),
              ),
              const Divider(),
              const _SettingRow(
                icon: Icons.bluetooth_rounded,
                title: 'Bluetooth scale support',
                value: 'Standard BLE WSS',
              ),
            ],
          ),
          const SizedBox(height: 24),
          const _SettingsHeader(title: 'Engine'),
          const SizedBox(height: 10),
          _SettingsCard(
            children: [
              _SettingRow(
                icon: Icons.science_outlined,
                title: 'Analysis mode',
                value: EstimateEngineConfig.analysisModeLabel,
              ),
              const Divider(),
              _SettingRow(
                icon: EstimateEngineConfig.isAiEnabled
                    ? Icons.cloud_upload_outlined
                    : Icons.cloud_off_outlined,
                title: 'Cloud uploads',
                value: EstimateEngineConfig.cloudUploadLabel,
              ),
              const Divider(),
              _SettingRow(
                icon: Icons.auto_awesome_outlined,
                title: 'Production model',
                value: EstimateEngineConfig.productionModelLabel,
              ),
            ],
          ),
          const SizedBox(height: 24),
          const _SettingsHeader(title: 'Scan credits'),
          const SizedBox(height: 10),
          _SettingsCard(
            children: [
              _ActionRow(
                icon: Icons.play_circle_outline_rounded,
                title: 'Earn AI scans',
                subtitle:
                    '${monetization.access.usageLabel} · watch one ad for one scan',
                color: AppColors.ink,
                onTap: () => showRewardedScanSheet(context),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const _SettingsHeader(title: 'Privacy'),
          const SizedBox(height: 10),
          _SettingsCard(
            children: [
              const _SettingRow(
                icon: Icons.lock_outline_rounded,
                title: 'Saved photos',
                value: 'Private storage',
              ),
              const Divider(),
              const Padding(
                padding: EdgeInsets.all(17),
                child: _SettingLabel(
                  icon: Icons.view_in_ar_outlined,
                  title: 'AR measurement',
                  subtitle:
                      'Uses Google Play Services for AR (ARCore), provided by '
                      'Google LLC and governed by the Google Privacy Policy.',
                ),
              ),
              if (monetization.privacyOptionsRequired) ...[
                const Divider(),
                _ActionRow(
                  icon: Icons.privacy_tip_outlined,
                  title: 'Ad privacy choices',
                  subtitle: 'Review or change consent',
                  color: AppColors.ink,
                  onTap: monetization.showPrivacyOptions,
                ),
              ],
              const Divider(),
              _ActionRow(
                icon: Icons.delete_sweep_outlined,
                title: 'Clear measurement history',
                subtitle: controller.measurements.isEmpty
                    ? 'No saved estimates'
                    : '${controller.measurements.length} saved',
                color: AppColors.coral,
                onTap: () => _clearHistory(context),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const _SettingsHeader(title: 'About'),
          const SizedBox(height: 10),
          const _SettingsCard(
            children: [
              _SettingRow(
                icon: Icons.info_outline_rounded,
                title: 'MassLens',
                value: 'MVP 1.0.0',
              ),
              Divider(),
              Padding(
                padding: EdgeInsets.all(17),
                child: Text(
                  'A compatible Bluetooth scale provides physical readings. '
                  'Touch mode is an interactive simulator and AI scans are '
                  'real visual estimates. Never use MassLens for medical dosing, legal '
                  'trade, or other safety-critical decisions.',
                  style: TextStyle(
                    color: AppColors.inkMuted,
                    fontSize: 12.5,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SettingsHeader extends StatelessWidget {
  const _SettingsHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(title, style: Theme.of(context).textTheme.titleLarge);
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }
}

class _SettingLabel extends StatelessWidget {
  const _SettingLabel({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _SettingIcon(icon: icon),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 3),
              Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
      ],
    );
  }
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(17),
      child: Row(
        children: [
          _SettingIcon(icon: icon),
          const SizedBox(width: 13),
          Expanded(
            child: Text(title, style: Theme.of(context).textTheme.titleMedium),
          ),
          const SizedBox(width: 10),
          Text(value, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(17),
        child: Row(
          children: [
            _SettingIcon(icon: icon, color: color),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(
                      context,
                    ).textTheme.titleMedium?.copyWith(color: color),
                  ),
                  const SizedBox(height: 3),
                  Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: color),
          ],
        ),
      ),
    );
  }
}

class _SettingIcon extends StatelessWidget {
  const _SettingIcon({required this.icon, this.color = AppColors.ink});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }
}
