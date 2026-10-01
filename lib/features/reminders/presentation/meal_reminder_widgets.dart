import 'package:flutter/material.dart';

import '../../../app/app_controller.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/l10n.dart';
import '../application/meal_reminder_controller.dart';

MealReminderText mealReminderText(AppLocalizations l10n) => MealReminderText(
  title: l10n.mealReminderNotificationTitle,
  body: l10n.mealReminderNotificationBody,
  channelName: l10n.mealReminderChannelName,
);

String formatMealReminderTime(BuildContext context, int hour, int minute) =>
    MaterialLocalizations.of(context).formatTimeOfDay(
      TimeOfDay(hour: hour, minute: minute),
      alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
    );

/// Picks a time, asks for notification permission and schedules the reminder.
Future<void> pickAndEnableMealReminder(BuildContext context) async {
  final reminders = AppScope.of(context).mealReminders;
  final l10n = context.l10n;
  final picked = await showTimePicker(
    context: context,
    initialTime: TimeOfDay(hour: reminders.hour, minute: reminders.minute),
    helpText: l10n.mealReminderTime,
  );
  if (picked == null || !context.mounted) return;
  final result = await reminders.enable(
    hour: picked.hour,
    minute: picked.minute,
    text: mealReminderText(l10n),
  );
  if (!context.mounted) return;
  final message = switch (result) {
    MealReminderEnableResult.enabled => l10n.mealReminderEnabled(
      formatMealReminderTime(context, picked.hour, picked.minute),
    ),
    MealReminderEnableResult.permissionDenied =>
      l10n.mealReminderPermissionDenied,
  };
  ScaffoldMessenger.maybeOf(context)?.showSnackBar(
    SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
  );
}

/// Settings rows: on/off switch plus the reminder time.
class MealReminderSettingsRows extends StatelessWidget {
  const MealReminderSettingsRows({super.key});

  @override
  Widget build(BuildContext context) {
    final reminders = AppScope.of(context).mealReminders;
    final l10n = context.l10n;
    final time = formatMealReminderTime(
      context,
      reminders.hour,
      reminders.minute,
    );
    return Column(
      children: [
        InkWell(
          onTap: reminders.busy
              ? null
              : () => _toggle(context, reminders, !reminders.enabled),
          child: Padding(
            padding: const EdgeInsets.all(17),
            child: Row(
              children: [
                const _ReminderIcon(icon: Icons.notifications_active_outlined),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.mealReminderTitle,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        reminders.enabled
                            ? l10n.mealReminderOnBody(time)
                            : l10n.mealReminderOffBody,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Switch(
                  key: const Key('meal_reminder_switch'),
                  value: reminders.enabled,
                  activeTrackColor: context.palette.limeDark,
                  onChanged: reminders.busy
                      ? null
                      : (value) => _toggle(context, reminders, value),
                ),
              ],
            ),
          ),
        ),
        if (reminders.enabled) ...[
          const Divider(),
          InkWell(
            key: const Key('meal_reminder_time'),
            onTap: () => pickAndEnableMealReminder(context),
            child: Padding(
              padding: const EdgeInsets.all(17),
              child: Row(
                children: [
                  const _ReminderIcon(icon: Icons.schedule_rounded),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Text(
                      l10n.mealReminderTime,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  Text(time, style: Theme.of(context).textTheme.titleMedium),
                  Icon(Icons.chevron_right_rounded, color: context.palette.ink),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _toggle(
    BuildContext context,
    MealReminderController reminders,
    bool value,
  ) async {
    if (value) {
      await pickAndEnableMealReminder(context);
    } else {
      await reminders.disable();
    }
  }
}

/// One-time card on the food log after the first meal is saved.
class MealReminderPromptCard extends StatelessWidget {
  const MealReminderPromptCard({super.key});

  @override
  Widget build(BuildContext context) {
    final reminders = AppScope.of(context).mealReminders;
    final l10n = context.l10n;
    return Container(
      key: const Key('meal_reminder_prompt'),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.palette.limeLight,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.palette.lime),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.notifications_active_rounded,
                color: context.palette.ink,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  l10n.mealReminderPromptTitle,
                  style: TextStyle(
                    color: context.palette.ink,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            l10n.mealReminderPromptBody,
            style: TextStyle(color: context.palette.ink, height: 1.4),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              FilledButton(
                key: const Key('meal_reminder_prompt_enable'),
                onPressed: reminders.busy
                    ? null
                    : () => pickAndEnableMealReminder(context),
                style: FilledButton.styleFrom(
                  backgroundColor: context.palette.ink,
                  foregroundColor: context.palette.onInk,
                ),
                child: Text(l10n.mealReminderPromptAction),
              ),
              TextButton(
                key: const Key('meal_reminder_prompt_dismiss'),
                onPressed: reminders.dismissPrompt,
                style: TextButton.styleFrom(
                  foregroundColor: context.palette.ink,
                ),
                child: Text(l10n.mealReminderPromptDismiss),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReminderIcon extends StatelessWidget {
  const _ReminderIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: context.palette.ink.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Icon(icon, color: context.palette.ink, size: 20),
    );
  }
}
