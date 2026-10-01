import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/app_controller.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_components.dart';
import '../../../l10n/l10n.dart';
import '../../../l10n/display_labels.dart';
import '../../barcode/data/recent_products_store.dart';
import '../../legal/presentation/legal_screen.dart';
import '../../measurements/domain/measurement.dart';
import '../../monetization/presentation/rewarded_scan_sheet.dart';
import '../../onboarding/presentation/onboarding_screen.dart';
import '../../reminders/presentation/meal_reminder_widgets.dart';
import '../../scan/data/estimate_repository_factory.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const _playListingUrl =
      'https://play.google.com/store/apps/details'
      '?id=com.lilai.masslens.photoestimates';

  /// Google Play's own review sheet first, then the listing.
  ///
  /// Play decides whether the in-app sheet appears — a spent quota or a missing
  /// Play Store returns false — so the listing keeps the tap from doing
  /// nothing at all.
  Future<void> _rateApp(BuildContext context) async {
    final l10n = context.l10n;
    final shown = await AppScope.of(context).requestAppReview();
    if (shown || !context.mounted) return;

    var opened = false;
    try {
      opened = await launchUrl(
        Uri.parse(_playListingUrl),
        mode: LaunchMode.externalApplication,
      );
    } on Object {
      // A missing platform URL handler is reported with the message below.
    }
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.settingsRateAppUnavailable),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _replayWalkthrough(BuildContext context) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => const OnboardingScreen(replay: true),
      ),
    );
  }

  Future<void> _clearHistory(BuildContext context) async {
    final controller = AppScope.of(context);
    final l10n = context.l10n;
    if (controller.measurements.isEmpty) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.settingsClearHistoryTitle),
        content: Text(
          l10n.settingsClearHistoryBody(controller.measurements.length),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(
              backgroundColor: context.palette.coral,
            ),
            child: Text(l10n.settingsClearHistoryAction),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await controller.clearHistory();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.settingsHistoryCleared),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _clearNutritionHistory(BuildContext context) async {
    final controller = AppScope.of(context);
    final l10n = context.l10n;
    final count = controller.nutritionDiary.entries.length;
    if (count == 0) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.settingsClearNutritionTitle),
        content: Text(l10n.settingsClearNutritionBody(count)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(
              backgroundColor: context.palette.coral,
            ),
            child: Text(l10n.settingsClearNutritionAction),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await controller.nutritionDiary.clear();
    await const RecentProductsStore().clear();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.settingsNutritionCleared),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final monetization = controller.monetization;
    final l10n = context.l10n;
    return SafeArea(
      maintainBottomViewPadding: true,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          Eyebrow(l10n.settingsEyebrow),
          const SizedBox(height: 8),
          Text(
            l10n.settingsTitle,
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          const SizedBox(height: 24),
          _SettingsHeader(title: l10n.settingsMeasurement),
          const SizedBox(height: 10),
          _SettingsCard(
            children: [
              Padding(
                padding: const EdgeInsets.all(17),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SettingLabel(
                      icon: Icons.straighten_rounded,
                      title: l10n.settingsUnits,
                      subtitle: l10n.settingsUnitsBody,
                    ),
                    const SizedBox(height: 16),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final showIcons = constraints.maxWidth >= 320;
                        return SegmentedButton<UnitSystem>(
                          expandedInsets: EdgeInsets.zero,
                          segments: [
                            ButtonSegment(
                              value: UnitSystem.metric,
                              label: Text(l10n.settingsMetric),
                              icon: showIcons
                                  ? const Icon(Icons.scale_outlined)
                                  : null,
                            ),
                            ButtonSegment(
                              value: UnitSystem.imperial,
                              label: Text(l10n.settingsImperial),
                              icon: showIcons
                                  ? const Icon(Icons.monitor_weight_outlined)
                                  : null,
                            ),
                          ],
                          selected: {controller.unitSystem},
                          onSelectionChanged: (selection) {
                            controller.setUnitSystem(selection.single);
                          },
                          showSelectedIcon: false,
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _SettingsHeader(title: l10n.settingsAppearance),
          const SizedBox(height: 10),
          _SettingsCard(
            children: [
              Padding(
                padding: const EdgeInsets.all(17),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SettingLabel(
                      icon: Icons.brightness_6_outlined,
                      title: l10n.settingsTheme,
                      subtitle: l10n.settingsThemeBody,
                    ),
                    const SizedBox(height: 16),
                    SegmentedButton<ThemeMode>(
                      key: const Key('settings_theme_mode'),
                      expandedInsets: EdgeInsets.zero,
                      segments: [
                        ButtonSegment(
                          value: ThemeMode.system,
                          label: Text(l10n.settingsThemeSystem),
                        ),
                        ButtonSegment(
                          value: ThemeMode.light,
                          label: Text(l10n.settingsThemeLight),
                        ),
                        ButtonSegment(
                          value: ThemeMode.dark,
                          label: Text(l10n.settingsThemeDark),
                        ),
                      ],
                      selected: {controller.themeMode},
                      onSelectionChanged: (selection) {
                        controller.setThemeMode(selection.single);
                      },
                      showSelectedIcon: false,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _SettingsHeader(title: l10n.settingsEngine),
          const SizedBox(height: 10),
          _SettingsCard(
            children: [
              _SettingRow(
                icon: Icons.science_outlined,
                title: l10n.settingsAnalysisMode,
                value: l10n.settingsAnalysisSecureCloudAi,
              ),
              const Divider(),
              _SettingRow(
                icon: EstimateEngineConfig.isAiEnabled
                    ? Icons.cloud_upload_outlined
                    : Icons.cloud_off_outlined,
                title: l10n.settingsCloudUploads,
                value: l10n.settingsCloudViaSecureApi,
              ),
              const Divider(),
              _SettingRow(
                icon: Icons.auto_awesome_outlined,
                title: l10n.settingsProductionModel,
                value: EstimateEngineConfig.productionModelLabel,
              ),
            ],
          ),
          const SizedBox(height: 24),
          _SettingsHeader(title: l10n.settingsReminders),
          const SizedBox(height: 10),
          const _SettingsCard(children: [MealReminderSettingsRows()]),
          const SizedBox(height: 24),
          _SettingsHeader(title: l10n.settingsScanCredits),
          const SizedBox(height: 10),
          _SettingsCard(
            children: [
              _ActionRow(
                icon: Icons.all_inclusive_rounded,
                title: l10n.settingsEarnAiScans,
                subtitle: l10n.settingsEarnAiScansBody(
                  localizedScanUsage(l10n, monetization.access),
                ),
                color: context.palette.ink,
                onTap: () => showRewardedScanSheet(context),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _SettingsHeader(title: l10n.settingsPrivacy),
          const SizedBox(height: 10),
          _SettingsCard(
            children: [
              _ActionRow(
                icon: Icons.gavel_rounded,
                title: l10n.legalTitle,
                subtitle: l10n.legalSettingsBody,
                color: context.palette.ink,
                onTap: () {
                  Navigator.of(context).push<void>(
                    MaterialPageRoute<void>(
                      builder: (_) => const LegalScreen(),
                    ),
                  );
                },
              ),
              const Divider(),
              _SettingRow(
                icon: Icons.lock_outline_rounded,
                title: l10n.settingsSavedPhotos,
                value: l10n.settingsPrivateStorage,
              ),
              if (monetization.privacyOptionsRequired) ...[
                const Divider(),
                _ActionRow(
                  icon: Icons.privacy_tip_outlined,
                  title: l10n.settingsAdPrivacyChoices,
                  subtitle: l10n.settingsReviewConsent,
                  color: context.palette.ink,
                  onTap: monetization.showPrivacyOptions,
                ),
              ],
              const Divider(),
              _ActionRow(
                icon: Icons.delete_sweep_outlined,
                title: l10n.settingsClearHistory,
                subtitle: controller.measurements.isEmpty
                    ? l10n.settingsNoSavedEstimates
                    : l10n.settingsSavedCount(controller.measurements.length),
                color: context.palette.coral,
                onTap: () => _clearHistory(context),
              ),
              const Divider(),
              _ActionRow(
                icon: Icons.no_meals_outlined,
                title: l10n.settingsClearNutrition,
                subtitle: controller.nutritionDiary.entries.isEmpty
                    ? l10n.settingsNoNutritionEntries
                    : l10n.settingsNutritionCount(
                        controller.nutritionDiary.entries.length,
                      ),
                color: context.palette.coral,
                onTap: () => _clearNutritionHistory(context),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _SettingsHeader(title: l10n.settingsHelp),
          const SizedBox(height: 10),
          _SettingsCard(
            children: [
              _ActionRow(
                key: const Key('settings_replay_walkthrough'),
                icon: Icons.school_outlined,
                title: l10n.settingsReplayWalkthrough,
                subtitle: l10n.settingsReplayWalkthroughBody,
                color: context.palette.ink,
                onTap: () => _replayWalkthrough(context),
              ),
              const Divider(),
              _ActionRow(
                key: const Key('settings_rate_app'),
                icon: Icons.star_outline_rounded,
                title: l10n.settingsRateApp,
                subtitle: l10n.settingsRateAppBody,
                color: context.palette.ink,
                onTap: () => _rateApp(context),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _SettingsHeader(title: l10n.settingsAbout),
          const SizedBox(height: 10),
          _SettingsCard(
            children: [
              _SettingRow(
                icon: Icons.info_outline_rounded,
                title: l10n.appTitle,
                value: l10n.settingsVersion,
              ),
              const Divider(),
              Padding(
                padding: const EdgeInsets.all(17),
                child: Text(
                  l10n.settingsSafetyBody,
                  style: TextStyle(
                    color: context.palette.inkMuted,
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
        color: context.palette.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.palette.line),
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
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
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
    super.key,
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
  const _SettingIcon({required this.icon, this.color});

  final IconData icon;

  /// Defaults to the palette's primary ink.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final color = this.color ?? context.palette.ink;
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
