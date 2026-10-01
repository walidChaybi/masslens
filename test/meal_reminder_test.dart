import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mass_lens/app/app_controller.dart';
import 'package:mass_lens/features/measurements/data/measurement_store.dart';
import 'package:mass_lens/features/nutrition/application/nutrition_diary_controller.dart';
import 'package:mass_lens/features/nutrition/data/nutrition_log_store.dart';
import 'package:mass_lens/features/nutrition/domain/nutrition_log.dart';
import 'package:mass_lens/features/nutrition/presentation/nutrition_screen.dart';
import 'package:mass_lens/features/measurements/domain/measurement.dart';
import 'package:mass_lens/features/reminders/application/meal_reminder_controller.dart';
import 'package:mass_lens/features/settings/presentation/settings_screen.dart';
import 'package:mass_lens/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeReminderPlatform implements MealReminderPlatform {
  FakeReminderPlatform({this.granted = true});

  bool granted;
  bool permissionRequested = false;
  final enabledAt = <(int, int, String)>[];
  int disableCalls = 0;
  final loggedMeals = <DateTime>[];

  @override
  Future<bool> canNotify() async => false;

  @override
  Future<bool> requestPermission() async {
    permissionRequested = true;
    return granted;
  }

  @override
  Future<bool> enable({
    required int hour,
    required int minute,
    required MealReminderText text,
  }) async {
    enabledAt.add((hour, minute, text.title));
    return granted;
  }

  @override
  Future<void> disable() async => disableCalls++;

  @override
  Future<void> mealLogged(DateTime at) async => loggedMeals.add(at);
}

const _text = MealReminderText(
  title: 'Log it',
  body: 'Body',
  channelName: 'Meals',
);

NutritionLogEntry _entry(String id) => NutritionLogEntry.create(
  id: id,
  loggedAt: DateTime.now(),
  mealType: MealType.lunch,
  label: 'Salad',
  nutrition: const NutritionTotals(
    caloriesKcal: 320,
    proteinGrams: 12,
    carbsGrams: 30,
    fatGrams: 14,
  ),
);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('enabling asks permission, schedules and persists', () async {
    final platform = FakeReminderPlatform();
    final reminders = MealReminderController(platform: platform);
    addTearDown(reminders.dispose);

    final result = await reminders.enable(hour: 19, minute: 15, text: _text);

    expect(result, MealReminderEnableResult.enabled);
    expect(platform.permissionRequested, isTrue);
    expect(platform.enabledAt.single, (19, 15, 'Log it'));
    expect(reminders.enabled, isTrue);
    expect(reminders.shouldOfferPrompt, isFalse);

    final reloaded = await MealReminderController.load(platform: platform);
    addTearDown(reloaded.dispose);
    expect(reloaded.enabled, isTrue);
    expect((reloaded.hour, reloaded.minute), (19, 15));
  });

  test('denied permission keeps reminders off and stops prompting', () async {
    final platform = FakeReminderPlatform(granted: false);
    final reminders = MealReminderController(platform: platform);
    addTearDown(reminders.dispose);

    final result = await reminders.enable(hour: 12, minute: 30, text: _text);

    expect(result, MealReminderEnableResult.permissionDenied);
    expect(platform.enabledAt, isEmpty);
    expect(reminders.enabled, isFalse);
    expect(reminders.shouldOfferPrompt, isFalse);
  });

  test('disable cancels and resync only reschedules when enabled', () async {
    final platform = FakeReminderPlatform();
    final reminders = MealReminderController(platform: platform);
    addTearDown(reminders.dispose);

    await reminders.resync(_text);
    expect(platform.enabledAt, isEmpty);

    await reminders.enable(hour: 8, minute: 0, text: _text);
    await reminders.resync(_text);
    expect(platform.enabledAt, hasLength(2));

    await reminders.disable();
    expect(platform.disableCalls, 1);
    expect(reminders.enabled, isFalse);
  });

  test('logging a meal tells the reminder scheduler', () async {
    final platform = FakeReminderPlatform();
    final controller = AppController(
      measurementStore: const MeasurementStore(),
      nutritionDiaryController: NutritionDiaryController(
        store: const NutritionLogStore(),
        entries: [_entry('existing')],
      ),
      mealReminderController: MealReminderController(platform: platform),
    );
    addTearDown(controller.dispose);
    expect(platform.loggedMeals, isEmpty);

    await controller.nutritionDiary.add(_entry('new'));
    expect(platform.loggedMeals, hasLength(1));

    await controller.nutritionDiary.delete('new');
    expect(platform.loggedMeals, hasLength(1));
  });

  testWidgets('food log offers the reminder once a meal exists', (
    tester,
  ) async {
    final platform = FakeReminderPlatform();
    final controller = _controller(platform, entries: [_entry('a')]);
    addTearDown(controller.dispose);
    await _pump(tester, controller, const Scaffold(body: NutritionScreen()));

    expect(find.byKey(const Key('meal_reminder_prompt')), findsOneWidget);
    await tester.tap(find.byKey(const Key('meal_reminder_prompt_dismiss')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('meal_reminder_prompt')), findsNothing);
    expect(controller.mealReminders.shouldOfferPrompt, isFalse);
  });

  testWidgets('no reminder prompt before the first meal', (tester) async {
    final controller = _controller(FakeReminderPlatform());
    addTearDown(controller.dispose);
    await _pump(tester, controller, const Scaffold(body: NutritionScreen()));

    expect(find.byKey(const Key('meal_reminder_prompt')), findsNothing);
  });

  testWidgets('settings switch turns the reminder on and off', (tester) async {
    final platform = FakeReminderPlatform();
    final controller = _controller(platform);
    addTearDown(controller.dispose);
    await _pump(tester, controller, const Scaffold(body: SettingsScreen()));

    await tester.scrollUntilVisible(
      find.byKey(const Key('meal_reminder_switch')),
      300,
    );
    await tester.tap(find.byKey(const Key('meal_reminder_switch')));
    await tester.pumpAndSettle();
    // Accept the default time in the picker.
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(controller.mealReminders.enabled, isTrue);
    expect(platform.enabledAt.single.$1, 12);
    expect(platform.enabledAt.single.$2, 30);
    expect(find.byKey(const Key('meal_reminder_time')), findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('meal_reminder_switch')));
    await tester.tap(find.byKey(const Key('meal_reminder_switch')));
    await tester.pumpAndSettle();
    expect(controller.mealReminders.enabled, isFalse);
    expect(platform.disableCalls, 1);
  });
}

AppController _controller(
  MealReminderPlatform platform, {
  List<NutritionLogEntry> entries = const [],
}) => AppController(
  measurementStore: const MeasurementStore(),
  measurements: const <Measurement>[],
  nutritionDiaryController: NutritionDiaryController(
    store: const NutritionLogStore(),
    entries: entries,
  ),
  mealReminderController: MealReminderController(platform: platform),
);

Future<void> _pump(
  WidgetTester tester,
  AppController controller,
  Widget home,
) async {
  tester.view.physicalSize = const Size(540, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    AppScope(
      controller: controller,
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: home,
      ),
    ),
  );
  await tester.pumpAndSettle();
}
