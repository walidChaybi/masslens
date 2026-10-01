import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../l10n/l10n.dart';
import '../../measurements/domain/measurement.dart';
import '../../nutrition/domain/nutrition_log.dart';
import '../../nutrition/presentation/nutrition_entry_sheets.dart';
import '../data/barcode_lookup_service.dart';
import '../domain/food_product.dart';

enum BarcodeSheetAction { logged, enterManually, scanAgain }

class BarcodeSheetOutcome {
  const BarcodeSheetOutcome.logged(NutritionLogEntry this.entry, this.product)
    : action = BarcodeSheetAction.logged;

  const BarcodeSheetOutcome.enterManually()
    : action = BarcodeSheetAction.enterManually,
      entry = null,
      product = null;

  const BarcodeSheetOutcome.scanAgain()
    : action = BarcodeSheetAction.scanAgain,
      entry = null,
      product = null;

  final BarcodeSheetAction action;
  final NutritionLogEntry? entry;
  final FoodProduct? product;
}

/// Looks up [barcode] (unless [product] is already known) and lets the user
/// choose a portion before adding the product to the diary.
Future<BarcodeSheetOutcome?> showBarcodeProductSheet(
  BuildContext context, {
  required String barcode,
  required BarcodeLookupService service,
  required DateTime initialDateTime,
  FoodProduct? product,
}) {
  return showModalBottomSheet<BarcodeSheetOutcome>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => BarcodeProductSheet(
      barcode: barcode,
      service: service,
      initialDateTime: initialDateTime,
      product: product,
    ),
  );
}

class BarcodeProductSheet extends StatefulWidget {
  const BarcodeProductSheet({
    required this.barcode,
    required this.service,
    required this.initialDateTime,
    this.product,
    super.key,
  });

  final String barcode;
  final BarcodeLookupService service;
  final DateTime initialDateTime;
  final FoodProduct? product;

  @override
  State<BarcodeProductSheet> createState() => _BarcodeProductSheetState();
}

class _BarcodeProductSheetState extends State<BarcodeProductSheet> {
  final _gramsController = TextEditingController();
  BarcodeLookupStatus? _status;
  FoodProduct? _product;
  late DateTime _loggedAt;
  late MealType _mealType;
  String? _error;
  bool _lookupStarted = false;

  @override
  void initState() {
    super.initState();
    _loggedAt = widget.initialDateTime;
    _mealType = defaultNutritionMealType(_loggedAt);
    final known = widget.product;
    if (known != null) _showProduct(known);
    _gramsController.addListener(() => setState(() {}));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_product == null && !_lookupStarted) {
      _lookupStarted = true;
      _lookup();
    }
  }

  @override
  void dispose() {
    _gramsController.dispose();
    super.dispose();
  }

  Future<void> _lookup() async {
    if (_status != null) setState(() => _status = null);
    final result = await widget.service.lookup(
      widget.barcode,
      languageCode: Localizations.localeOf(context).languageCode,
    );
    if (!mounted) return;
    final product = result.product;
    if (product != null) {
      _showProduct(product);
      setState(() {});
    } else {
      setState(() => _status = result.status);
    }
  }

  void _showProduct(FoodProduct product) {
    _product = product;
    _status = BarcodeLookupStatus.found;
    _gramsController.text = _editable(product.servingGrams ?? 100);
  }

  double? get _grams {
    final value = parseNutritionNumber(_gramsController.text);
    if (value == null || value <= 0 || value > 5000) return null;
    return value;
  }

  void _save() {
    final product = _product;
    final grams = _grams;
    if (product == null) return;
    if (grams == null) {
      setState(() => _error = context.l10n.nutritionInvalidNumber);
      return;
    }
    if (_loggedAt.isAfter(DateTime.now())) {
      setState(() => _error = context.l10n.nutritionFutureDate);
      return;
    }
    try {
      final entry = NutritionLogEntry.create(
        id: newNutritionEntryId(),
        loggedAt: _loggedAt,
        mealType: _mealType,
        label: product.diaryLabel,
        nutrition: product.nutritionFor(grams),
        weightGrams: grams,
        isPartial: product.hasPartialNutrition,
      );
      Navigator.of(context).pop(BarcodeSheetOutcome.logged(entry, product));
    } on FormatException {
      setState(() => _error = context.l10n.nutritionAtLeastOneValue);
    }
  }

  @override
  Widget build(BuildContext context) {
    final product = _product;
    final Widget body = switch (_status) {
      null => _LoadingState(barcode: widget.barcode),
      BarcodeLookupStatus.found when product != null => _foundState(product),
      BarcodeLookupStatus.unavailable => _MessageState(
        key: const Key('barcode_unavailable'),
        icon: Icons.wifi_off_rounded,
        title: context.l10n.barcodeUnavailableTitle,
        body: context.l10n.barcodeUnavailableBody,
        primaryLabel: context.l10n.barcodeRetry,
        onPrimary: _lookup,
        secondaryLabel: context.l10n.barcodeEnterManually,
        onSecondary: () => Navigator.of(
          context,
        ).pop(const BarcodeSheetOutcome.enterManually()),
      ),
      _ => _MessageState(
        key: const Key('barcode_not_found'),
        icon: Icons.search_off_rounded,
        title: context.l10n.barcodeNotFoundTitle,
        body: context.l10n.barcodeNotFoundBody(widget.barcode),
        primaryLabel: context.l10n.barcodeEnterManually,
        onPrimary: () => Navigator.of(
          context,
        ).pop(const BarcodeSheetOutcome.enterManually()),
        secondaryLabel: context.l10n.barcodeScanAgain,
        onSecondary: () =>
            Navigator.of(context).pop(const BarcodeSheetOutcome.scanAgain()),
      ),
    };
    return SafeArea(
      top: false,
      maintainBottomViewPadding: true,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          0,
          20,
          20 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SingleChildScrollView(child: body),
      ),
    );
  }

  Widget _foundState(FoodProduct product) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final number = NumberFormat('0.#', locale);
    final grams = _grams;
    final unit = product.unit;
    String amount(double value) => '${number.format(value)} $unit';
    final presets = <(Key, String, double)>[
      if (product.servingGrams case final serving?)
        (
          const Key('barcode_portion_serving'),
          l10n.barcodeServing(amount(serving)),
          serving,
        ),
      (const Key('barcode_portion_100'), amount(100), 100),
      if (product.packageGrams case final pack?
          when pack != product.servingGrams && pack != 100)
        (
          const Key('barcode_portion_pack'),
          l10n.barcodeWholePack(amount(pack)),
          pack,
        ),
    ];
    return Column(
      key: const Key('barcode_product_found'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          product.name,
          key: const Key('barcode_product_name'),
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        if (product.brand case final brand?) ...[
          const SizedBox(height: 2),
          Text(brand, style: TextStyle(color: context.palette.inkMuted)),
        ],
        const SizedBox(height: 10),
        Text(
          '${l10n.barcodePer100(unit)} · '
          '${_summary(context, product.per100g.forWeight(100), number)}',
          style: TextStyle(color: context.palette.inkMuted, fontSize: 13),
        ),
        const SizedBox(height: 16),
        Text(
          l10n.barcodeYourPortion,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final (key, label, value) in presets)
              ChoiceChip(
                key: key,
                label: Text(label),
                selected: grams != null && (grams - value).abs() < 0.01,
                onSelected: (_) => _gramsController.text = _editable(value),
              ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          key: const Key('barcode_grams_field'),
          controller: _gramsController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: l10n.barcodeAmountEaten,
            suffixText: unit,
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          key: const Key('barcode_portion_totals'),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: context.palette.navySoft,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            grams == null
                ? '—'
                : _summary(context, product.nutritionFor(grams), number),
            style: TextStyle(
              color: context.palette.ink,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        if (product.hasPartialNutrition) ...[
          const SizedBox(height: 8),
          Text(
            l10n.barcodePartialNutrition,
            style: TextStyle(color: context.palette.inkMuted, fontSize: 12),
          ),
        ],
        const SizedBox(height: 16),
        NutritionDateTimeMealFields(
          loggedAt: _loggedAt,
          mealType: _mealType,
          onDateChanged: (value) => setState(() => _loggedAt = value),
          onMealChanged: (value) => setState(() => _mealType = value),
        ),
        if (_error != null) ...[
          const SizedBox(height: 10),
          Text(_error!, style: TextStyle(color: context.palette.coral)),
        ],
        const SizedBox(height: 18),
        FilledButton(
          key: const Key('barcode_add_to_diary'),
          onPressed: _save,
          child: Text(l10n.barcodeAddToDiary),
        ),
        const SizedBox(height: 10),
        Text(
          product.source == FoodProductSource.usda
              ? l10n.barcodeSourceUsda
              : l10n.barcodeSourceOpenFoodFacts,
          key: const Key('barcode_source_attribution'),
          style: TextStyle(color: context.palette.inkMuted, fontSize: 11),
        ),
      ],
    );
  }

  String _summary(
    BuildContext context,
    NutritionTotals totals,
    NumberFormat number,
  ) {
    final l10n = context.l10n;
    return '${l10n.nutritionKcal(number.format(totals.caloriesKcal))} · '
        '${l10n.nutritionProteinShort} '
        '${l10n.nutritionGrams(number.format(totals.proteinGrams))} · '
        '${l10n.nutritionCarbsShort} '
        '${l10n.nutritionGrams(number.format(totals.carbsGrams))} · '
        '${l10n.nutritionFatShort} '
        '${l10n.nutritionGrams(number.format(totals.fatGrams))}';
  }

  static String _editable(double value) => value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toStringAsFixed(1);
}

class _LoadingState extends StatelessWidget {
  const _LoadingState({required this.barcode});

  final String barcode;

  @override
  Widget build(BuildContext context) {
    return Padding(
      key: const Key('barcode_loading'),
      padding: const EdgeInsets.symmetric(vertical: 36),
      child: Column(
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(context.l10n.barcodeLookingUp, textAlign: TextAlign.center),
          const SizedBox(height: 4),
          Text(barcode, style: TextStyle(color: context.palette.inkMuted)),
        ],
      ),
    );
  }
}

class _MessageState extends StatelessWidget {
  const _MessageState({
    required this.icon,
    required this.title,
    required this.body,
    required this.primaryLabel,
    required this.onPrimary,
    required this.secondaryLabel,
    required this.onSecondary,
    super.key,
  });

  final IconData icon;
  final String title;
  final String body;
  final String primaryLabel;
  final VoidCallback onPrimary;
  final String secondaryLabel;
  final VoidCallback onSecondary;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(icon, size: 40, color: context.palette.inkMuted),
        const SizedBox(height: 12),
        Text(
          title,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Text(body, textAlign: TextAlign.center),
        const SizedBox(height: 20),
        FilledButton(onPressed: onPrimary, child: Text(primaryLabel)),
        const SizedBox(height: 8),
        TextButton(onPressed: onSecondary, child: Text(secondaryLabel)),
      ],
    );
  }
}
