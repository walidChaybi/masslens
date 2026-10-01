import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../app/app_controller.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_components.dart';
import '../../../l10n/display_labels.dart';
import '../../../l10n/l10n.dart';
import '../../barcode/data/barcode_lookup_service.dart';
import '../../barcode/data/recent_products_store.dart';
import '../../barcode/domain/food_product.dart';
import '../../barcode/presentation/barcode_product_sheet.dart';
import '../../barcode/presentation/barcode_scanner_screen.dart';
import '../../measurements/domain/measurement.dart';
import '../../reminders/presentation/meal_reminder_widgets.dart';
import '../domain/nutrition_log.dart';
import 'meal_photo_card.dart';
import 'nutrition_entry_sheets.dart';
import 'nutrition_goals_sheet.dart';
import 'nutrition_scan_cta.dart';
import 'nutrition_trends.dart';
import 'today_hero_card.dart';

class NutritionScreen extends StatefulWidget {
  const NutritionScreen({
    this.onScan,
    this.onGallery,
    this.barcodeLookupService,
    this.recentProductsStore = const RecentProductsStore(),
    this.barcodeScanner,
    super.key,
  });

  final VoidCallback? onScan;
  final VoidCallback? onGallery;

  /// Defaults to Open Food Facts + the MassLens USDA fallback.
  final BarcodeLookupService? barcodeLookupService;
  final RecentProductsStore recentProductsStore;

  /// Defaults to the camera scanner; replaced in tests.
  final Future<String?> Function(BuildContext context)? barcodeScanner;

  @override
  State<NutritionScreen> createState() => _NutritionScreenState();
}

class _NutritionScreenState extends State<NutritionScreen> {
  final DateTime _selectedDay = nutritionDay(DateTime.now());
  bool _showTrends = false;
  late final BarcodeLookupService _barcodeService =
      widget.barcodeLookupService ?? BarcodeLookupService.production();
  List<FoodProduct> _recentProducts = const [];

  @override
  void initState() {
    super.initState();
    _loadRecentProducts();
  }

  Future<void> _loadRecentProducts() async {
    final products = await widget.recentProductsStore.load();
    if (mounted) setState(() => _recentProducts = products);
  }

  bool get _isToday =>
      nutritionDayKey(_selectedDay) == nutritionDayKey(DateTime.now());

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final diary = controller.nutritionDiary;
    final day = diary.daySummary(_selectedDay);
    final horizontalPadding = math.max(
      20.0,
      (MediaQuery.sizeOf(context).width - 720) / 2,
    );

    return ColoredBox(
      color: context.palette.canvas,
      child: SafeArea(
        key: const Key('nutrition_screen'),
        maintainBottomViewPadding: true,
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            8,
            horizontalPadding,
            36,
          ),
          children: [
            Row(
              children: [
                Expanded(
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: _ViewSwitch(
                      key: const Key('nutrition_view_selector'),
                      showTrends: _showTrends,
                      todayLabel: l10nOrToday(context),
                      trendsLabel: context.l10n.nutritionTrendsTab,
                      onChanged: (trends) =>
                          setState(() => _showTrends = trends),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton.filled(
                  key: const Key('nutrition_add_food'),
                  tooltip: context.l10n.nutritionMoreActions,
                  style: IconButton.styleFrom(
                    backgroundColor: context.palette.lime,
                    foregroundColor: context.palette.onLime,
                    fixedSize: const Size.square(48),
                  ),
                  onPressed: () => _showAddChoices(context, controller),
                  icon: const Icon(Icons.add_rounded),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (_showTrends)
              NutritionTrendsView(diary: diary, endingOn: _selectedDay)
            else ...[
              TodayHeroCard(
                consumed: day.totals,
                goals: diary.goals,
                streak: diary.streak(),
                onEditGoals: () => _editGoals(controller),
              ),
              if (diary.entries.isNotEmpty &&
                  controller.mealReminders.shouldOfferPrompt) ...[
                const SizedBox(height: 14),
                const MealReminderPromptCard(),
              ],
              const SizedBox(height: 18),
              NutritionScanCta(
                onScan: widget.onScan ?? () {},
                onGallery: widget.onGallery ?? () {},
                onBarcode: () => _logBarcode(context, controller),
              ),
              const SizedBox(height: 22),
              if (!day.hasEntries)
                _EmptyDay()
              else ...[
                for (final mealType in MealType.values)
                  if (day.entries.any(
                    (entry) => entry.mealType == mealType,
                  )) ...[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8, left: 4),
                      child: Text(
                        localizedMealType(context.l10n, mealType),
                        style: TextStyle(
                          color: context.palette.inkMuted,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                    for (final entry in day.entries.where(
                      (item) => item.mealType == mealType,
                    )) ...[
                      MealPhotoCard(
                        entry: entry,
                        imagePath: _imageFor(controller, entry),
                        onEdit: () => _editEntry(context, controller, entry),
                        onDelete: () =>
                            _deleteEntry(context, controller, entry),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ],
              ],
              if (day.hasPartialData) ...[
                const SizedBox(height: 8),
                Text(
                  context.l10n.nutritionPartialNotice,
                  style: TextStyle(
                    color: context.palette.inkMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ],
            const SizedBox(height: 24),
            Text(
              context.l10n.nutritionDisclaimer,
              style: TextStyle(
                color: context.palette.inkMuted,
                fontSize: 11,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String l10nOrToday(BuildContext context) => context.l10n.nutritionToday;

  String? _imageFor(AppController controller, NutritionLogEntry entry) {
    final path = entry.imagePath;
    if (path != null && path.isNotEmpty) return path;
    final sourceId = entry.sourceMeasurementId;
    if (sourceId == null) return null;
    for (final measurement in controller.measurements) {
      if (measurement.id == sourceId) return measurement.imagePath;
    }
    return null;
  }

  Future<void> _editGoals(AppController controller) async {
    final updated = await showNutritionGoalsSheet(
      context,
      initial: controller.nutritionDiary.goals,
    );
    if (updated != null) {
      await controller.nutritionDiary.updateGoals(updated);
    }
  }

  Future<void> _showAddChoices(
    BuildContext context,
    AppController controller,
  ) async {
    final l10n = context.l10n;
    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: context.palette.surface,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              key: const Key('nutrition_add_barcode'),
              leading: const Icon(Icons.qr_code_scanner_rounded),
              title: Text(l10n.barcodeScanAction),
              subtitle: Text(l10n.barcodeScanActionBody),
              onTap: () => Navigator.pop(sheetContext, 'barcode'),
            ),
            if (_recentProducts.isNotEmpty)
              ListTile(
                key: const Key('nutrition_add_recent_product'),
                leading: const Icon(Icons.history_rounded),
                title: Text(l10n.barcodeRecentTitle),
                subtitle: Text(l10n.barcodeRecentBody),
                onTap: () => Navigator.pop(sheetContext, 'recent'),
              ),
            ListTile(
              key: const Key('nutrition_add_from_scan'),
              leading: const Icon(Icons.photo_camera_back_outlined),
              title: Text(l10n.nutritionFromScans),
              subtitle: Text(l10n.nutritionFromScansBody),
              onTap: () => Navigator.pop(sheetContext, 'scan'),
            ),
            ListTile(
              key: const Key('nutrition_add_manual'),
              leading: const Icon(Icons.edit_note_rounded),
              title: Text(l10n.nutritionManual),
              subtitle: Text(l10n.nutritionManualBody),
              onTap: () => Navigator.pop(sheetContext, 'manual'),
            ),
          ],
        ),
      ),
    );
    if (!context.mounted || choice == null) return;
    switch (choice) {
      case 'scan':
        await _addFromScan(context, controller);
      case 'barcode':
        await _logBarcode(context, controller);
      case 'recent':
        await _logRecentProduct(context, controller);
      default:
        await _addManual(context, controller);
    }
  }

  Future<void> _addManual(
    BuildContext context,
    AppController controller,
  ) async {
    final entry = await showNutritionManualEditor(
      context,
      initialDateTime: _entryDateTime(),
    );
    if (entry != null) await controller.nutritionDiary.add(entry);
  }

  /// Free barcode logging: scan, look up label nutrition, pick a portion.
  Future<void> _logBarcode(
    BuildContext context,
    AppController controller,
  ) async {
    final scanner = widget.barcodeScanner ?? scanFoodBarcode;
    var scanAgain = true;
    while (scanAgain) {
      scanAgain = false;
      final barcode = await scanner(context);
      if (!context.mounted || barcode == null) return;
      final outcome = await showBarcodeProductSheet(
        context,
        barcode: barcode,
        service: _barcodeService,
        initialDateTime: _entryDateTime(),
      );
      if (!context.mounted || outcome == null) return;
      if (outcome.action == BarcodeSheetAction.scanAgain) {
        scanAgain = true;
      } else if (outcome.action == BarcodeSheetAction.enterManually) {
        await _addManual(context, controller);
      } else {
        await _saveBarcodeOutcome(context, controller, outcome);
      }
    }
  }

  Future<void> _logRecentProduct(
    BuildContext context,
    AppController controller,
  ) async {
    final product = await showModalBottomSheet<FoodProduct>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.72,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                child: Text(
                  context.l10n.barcodeRecentTitle,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  padding: const EdgeInsets.only(bottom: 16),
                  children: [
                    for (final product in _recentProducts)
                      ListTile(
                        key: Key('recent_product_${product.barcode}'),
                        leading: const Icon(Icons.inventory_2_outlined),
                        title: Text(product.name),
                        subtitle: Text(
                          [
                            ?product.brand,
                            context.l10n.barcodeKcalPer100(
                              product.per100g.caloriesKcal.round().toString(),
                              product.unit,
                            ),
                          ].join(' · '),
                        ),
                        onTap: () => Navigator.pop(sheetContext, product),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (!context.mounted || product == null) return;
    final outcome = await showBarcodeProductSheet(
      context,
      barcode: product.barcode,
      service: _barcodeService,
      initialDateTime: _entryDateTime(),
      product: product,
    );
    if (!context.mounted || outcome == null) return;
    if (outcome.action == BarcodeSheetAction.logged) {
      await _saveBarcodeOutcome(context, controller, outcome);
    }
  }

  Future<void> _saveBarcodeOutcome(
    BuildContext context,
    AppController controller,
    BarcodeSheetOutcome outcome,
  ) async {
    final entry = outcome.entry;
    final product = outcome.product;
    if (entry == null || product == null) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    final message = context.l10n.nutritionScanLoggedMessage;
    await controller.nutritionDiary.add(entry);
    final recent = await widget.recentProductsStore.remember(product);
    if (mounted) setState(() => _recentProducts = recent);
    messenger?.showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _addFromScan(
    BuildContext context,
    AppController controller,
  ) async {
    final scans = controller.measurements
        .where(
          (measurement) =>
              measurement.isFoodPlate && measurement.hasNutritionData,
        )
        .toList(growable: false);
    if (scans.isEmpty) {
      if (!context.mounted) return;
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(context.l10n.nutritionNoScansTitle),
          content: Text(context.l10n.nutritionNoScansBody),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(context.l10n.commonOk),
            ),
          ],
        ),
      );
      return;
    }
    final measurement = await showModalBottomSheet<Measurement>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(sheetContext).height * 0.72,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
                child: Text(
                  context.l10n.nutritionChooseScan,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  itemCount: scans.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (_, index) => MeasurementCard(
                    measurement: scans[index],
                    unitSystem: controller.unitSystem,
                    compact: true,
                    onTap: () => Navigator.pop(sheetContext, scans[index]),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (!context.mounted || measurement == null) return;
    final entry = await showNutritionScanImport(
      context,
      measurement: measurement,
      initialDateTime: _entryDateTime(),
    );
    if (entry != null) await controller.nutritionDiary.add(entry);
  }

  Future<void> _editEntry(
    BuildContext context,
    AppController controller,
    NutritionLogEntry entry,
  ) async {
    final updated = await showNutritionManualEditor(
      context,
      existing: entry,
      initialDateTime: entry.loggedAt,
    );
    if (updated != null) await controller.nutritionDiary.update(updated);
  }

  Future<void> _deleteEntry(
    BuildContext context,
    AppController controller,
    NutritionLogEntry entry,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.l10n.nutritionDeleteTitle),
        content: Text(context.l10n.nutritionDeleteBody(entry.label)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(context.l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(context.l10n.commonDelete),
          ),
        ],
      ),
    );
    if (confirmed == true) await controller.nutritionDiary.delete(entry.id);
  }

  DateTime _entryDateTime() {
    final now = DateTime.now();
    if (_isToday) return now;
    return DateTime(
      _selectedDay.year,
      _selectedDay.month,
      _selectedDay.day,
      12,
    );
  }
}

class _EmptyDay extends StatelessWidget {
  const _EmptyDay();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      key: const Key('nutrition_empty_state'),
      padding: const EdgeInsets.fromLTRB(18, 22, 18, 22),
      decoration: BoxDecoration(
        color: context.palette.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.palette.line),
      ),
      child: Column(
        children: [
          AspectRatio(
            aspectRatio: 4 / 3,
            child: Container(
              decoration: BoxDecoration(
                color: context.palette.navySoft,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(
                Icons.restaurant_rounded,
                color: context.palette.inkMuted,
                size: 42,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.nutritionEmptyTitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: context.palette.ink,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.nutritionEmptyBody,
            textAlign: TextAlign.center,
            style: TextStyle(color: context.palette.inkMuted, height: 1.4),
          ),
        ],
      ),
    );
  }
}

/// Pill-shaped segmented switch between the daily log and the trends.
class _ViewSwitch extends StatelessWidget {
  const _ViewSwitch({
    required this.showTrends,
    required this.todayLabel,
    required this.trendsLabel,
    required this.onChanged,
    super.key,
  });

  final bool showTrends;
  final String todayLabel;
  final String trendsLabel;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: context.palette.navySoft,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: _SwitchSegment(
              label: todayLabel,
              selected: !showTrends,
              onTap: () => onChanged(false),
            ),
          ),
          Flexible(
            child: _SwitchSegment(
              label: trendsLabel,
              selected: showTrends,
              onTap: () => onChanged(true),
            ),
          ),
        ],
      ),
    );
  }
}

class _SwitchSegment extends StatelessWidget {
  const _SwitchSegment({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? context.palette.ink : Colors.transparent,
            borderRadius: BorderRadius.circular(99),
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: selected ? Colors.white : context.palette.inkMuted,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}
