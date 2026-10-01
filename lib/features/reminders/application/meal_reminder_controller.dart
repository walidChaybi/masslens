import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Localized copy the native side shows in the notification.
class MealReminderText {
  const MealReminderText({
    required this.title,
    required this.body,
    required this.channelName,
  });

  final String title;
  final String body;
  final String channelName;
}

/// Bridge to the Android alarm + notification implementation.
abstract interface class MealReminderPlatform {
  Future<bool> canNotify();
  Future<bool> requestPermission();
  Future<bool> enable({
    required int hour,
    required int minute,
    required MealReminderText text,
  });
  Future<void> disable();
  Future<void> mealLogged(DateTime at);
}

class ChannelMealReminderPlatform implements MealReminderPlatform {
  const ChannelMealReminderPlatform();

  static const _channel = MethodChannel('com.masslens.mass_lens/reminders');

  Future<T?> _invoke<T>(String method, [Map<String, Object?>? args]) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return null;
    try {
      return await _channel.invokeMethod<T>(method, args);
    } on Object {
      // Reminders are optional: missing plugin, platform errors or an
      // uninitialized binding (unit tests) all mean "not available".
      return null;
    }
  }

  @override
  Future<bool> canNotify() async => await _invoke<bool>('status') ?? false;

  @override
  Future<bool> requestPermission() async =>
      await _invoke<bool>('requestPermission') ?? false;

  @override
  Future<bool> enable({
    required int hour,
    required int minute,
    required MealReminderText text,
  }) async =>
      await _invoke<bool>('enable', {
        'hour': hour,
        'minute': minute,
        'title': text.title,
        'body': text.body,
        'channelName': text.channelName,
      }) ??
      false;

  @override
  Future<void> disable() async {
    await _invoke<Object?>('disable');
  }

  @override
  Future<void> mealLogged(DateTime at) async {
    await _invoke<Object?>('mealLogged', {
      'atMillis': at.millisecondsSinceEpoch,
    });
  }
}

class _NoopMealReminderPlatform implements MealReminderPlatform {
  const _NoopMealReminderPlatform();

  @override
  Future<bool> canNotify() async => false;

  @override
  Future<bool> requestPermission() async => false;

  @override
  Future<bool> enable({
    required int hour,
    required int minute,
    required MealReminderText text,
  }) async => false;

  @override
  Future<void> disable() async {}

  @override
  Future<void> mealLogged(DateTime at) async {}
}

enum MealReminderEnableResult { enabled, permissionDenied }

/// One optional daily reminder to log meals.
class MealReminderController extends ChangeNotifier {
  MealReminderController({
    MealReminderPlatform platform = const ChannelMealReminderPlatform(),
    bool enabled = false,
    int hour = defaultHour,
    int minute = defaultMinute,
    bool promptHandled = false,
  }) : _platform = platform,
       _enabled = enabled,
       _hour = hour,
       _minute = minute,
       _promptHandled = promptHandled;

  /// Reminders unavailable (tests, unsupported platforms): never prompts.
  factory MealReminderController.disabled() => MealReminderController(
    platform: const _NoopMealReminderPlatform(),
    promptHandled: true,
  );

  static const defaultHour = 12;
  static const defaultMinute = 30;
  static const enabledKey = 'mass_lens.meal_reminder.enabled';
  static const hourKey = 'mass_lens.meal_reminder.hour';
  static const minuteKey = 'mass_lens.meal_reminder.minute';
  static const promptHandledKey = 'mass_lens.meal_reminder.prompt_handled';

  final MealReminderPlatform _platform;
  bool _enabled;
  int _hour;
  int _minute;
  bool _promptHandled;
  bool _busy = false;

  bool get enabled => _enabled;
  int get hour => _hour;
  int get minute => _minute;
  bool get busy => _busy;

  /// Whether the one-time "turn on reminders" card should still be offered.
  bool get shouldOfferPrompt => !_enabled && !_promptHandled;

  static Future<MealReminderController> load({
    MealReminderPlatform platform = const ChannelMealReminderPlatform(),
  }) async {
    try {
      final preferences = await SharedPreferences.getInstance();
      return MealReminderController(
        platform: platform,
        enabled: preferences.getBool(enabledKey) ?? false,
        hour: (preferences.getInt(hourKey) ?? defaultHour).clamp(0, 23),
        minute: (preferences.getInt(minuteKey) ?? defaultMinute).clamp(0, 59),
        promptHandled: preferences.getBool(promptHandledKey) ?? false,
      );
    } on Object {
      return MealReminderController(platform: platform);
    }
  }

  /// Asks for notification permission if needed, then schedules the reminder.
  Future<MealReminderEnableResult> enable({
    required int hour,
    required int minute,
    required MealReminderText text,
  }) async {
    if (_busy) return MealReminderEnableResult.permissionDenied;
    _busy = true;
    notifyListeners();
    try {
      final allowed =
          await _platform.canNotify() || await _platform.requestPermission();
      if (!allowed) {
        await _markPromptHandled();
        return MealReminderEnableResult.permissionDenied;
      }
      await _platform.enable(hour: hour, minute: minute, text: text);
      _enabled = true;
      _hour = hour;
      _minute = minute;
      _promptHandled = true;
      await _save();
      return MealReminderEnableResult.enabled;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<void> disable() async {
    await _platform.disable();
    _enabled = false;
    _promptHandled = true;
    notifyListeners();
    await _save();
  }

  Future<void> dismissPrompt() async {
    await _markPromptHandled();
    notifyListeners();
  }

  /// Re-applies the schedule (alarms are cleared by force-stop) and refreshes
  /// the notification copy for the current language.
  Future<void> resync(MealReminderText text) async {
    if (!_enabled) return;
    await _platform.enable(hour: _hour, minute: _minute, text: text);
  }

  Future<void> noteMealLogged(DateTime at) => _platform.mealLogged(at);

  Future<void> _markPromptHandled() async {
    if (_promptHandled) return;
    _promptHandled = true;
    await _save();
  }

  Future<void> _save() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setBool(enabledKey, _enabled);
      await preferences.setInt(hourKey, _hour);
      await preferences.setInt(minuteKey, _minute);
      await preferences.setBool(promptHandledKey, _promptHandled);
    } on Object {
      // Reminder preferences are optional.
    }
  }
}
