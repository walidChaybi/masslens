import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../app/app_controller.dart';
import '../../../core/theme/app_theme.dart';
import '../../measurements/domain/measurement.dart';
import '../../monetization/presentation/rewarded_scan_sheet.dart';
import '../data/cloudflare_estimate_repository.dart';
import '../data/estimate_repository_factory.dart';
import '../data/photo_picker.dart';
import '../data/scan_image_processor.dart';
import '../domain/estimate_repository.dart';
import '../domain/measurement_capture.dart';
import '../domain/measured_dimensions.dart';
import 'capture/measurement_launcher.dart';

class ScanScreen extends StatefulWidget {
  ScanScreen({
    EstimateRepository? estimateRepository,
    PhotoPicker? photoPicker,
    MeasurementLauncher? measurementLauncher,
    this.autoStart = true,
    this.startWithGallery = false,
    super.key,
  }) : estimateRepository = estimateRepository ?? buildEstimateRepository(),
       photoPicker = photoPicker ?? DevicePhotoPicker(),
       measurementLauncher =
           measurementLauncher ?? const DeviceMeasurementLauncher();

  final EstimateRepository estimateRepository;
  final PhotoPicker photoPicker;
  final MeasurementLauncher measurementLauncher;
  final bool autoStart;
  final bool startWithGallery;

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  static const _materials = [
    'Unknown',
    'Plastic',
    'Metal',
    'Glass/Ceramic',
    'Wood',
    'Cardboard/Paper',
    'Fabric',
    'Food/Liquid',
    'Mixed',
  ];
  static const _fillStates = [
    'Unknown',
    'Solid',
    'Empty',
    'Partly filled',
    'Full',
  ];
  static const _references = ['None', 'Ruler', 'Standard card'];
  static const _axes = ['Width', 'Height', 'Depth'];

  final _dimensionController = TextEditingController();
  String? _imagePath;
  String? _secondaryImagePath;
  MeasuredDimensions? _measuredDimensions;
  String _material = 'Unknown';
  String _fillState = 'Unknown';
  String _referenceObject = 'None';
  String _dimensionAxis = 'Width';
  String _dimensionUnit = 'cm';
  bool _isPicking = false;
  bool _isAnalyzing = false;
  int _analysisStep = 0;
  int _analysisRun = 0;
  Timer? _analysisTimer;
  Measurement? _result;
  String? _error;
  String? _requestId;
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    if (widget.autoStart) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (widget.startWithGallery) {
          unawaited(_captureFromGallery());
        } else {
          unawaited(_captureMeasured());
        }
      });
    }
  }

  @override
  void dispose() {
    _analysisTimer?.cancel();
    _dimensionController.dispose();
    super.dispose();
  }

  Future<void> _captureMeasured() async {
    if (_isPicking) return;
    setState(() {
      _isPicking = true;
      _error = null;
      _requestId = null;
    });
    try {
      final capture = await widget.measurementLauncher.launch(context);
      if (!mounted || capture == null) return;
      _acceptCapture(capture);
    } on Object {
      if (mounted) {
        setState(() => _error = 'Measurement camera could not be opened.');
      }
    } finally {
      if (mounted) setState(() => _isPicking = false);
    }
  }

  Future<void> _captureFromGallery() async {
    if (_isPicking) return;
    setState(() {
      _isPicking = true;
      _error = null;
    });
    try {
      final imagePath = await widget.photoPicker.pick(PhotoSource.gallery);
      if (!mounted || imagePath == null) return;
      MeasuredDimensions? dimensions;
      if (File(imagePath).existsSync()) {
        dimensions = await launchPhotoMeasurement(context, imagePath);
        if (!mounted) return;
      }
      _acceptCapture(
        MeasurementCapture(imagePath: imagePath, dimensions: dimensions),
      );
    } on Object {
      if (mounted) {
        setState(() => _error = 'The selected photo could not be opened.');
      }
    } finally {
      if (mounted) setState(() => _isPicking = false);
    }
  }

  void _acceptCapture(MeasurementCapture capture) {
    setState(() {
      _imagePath = capture.imagePath;
      _secondaryImagePath = null;
      _measuredDimensions = capture.dimensions;
      _result = null;
      _saved = false;
      _error = null;
    });
  }

  Future<void> _editMeasurement() async {
    final imagePath = _imagePath;
    if (imagePath == null || !File(imagePath).existsSync()) return;
    final measured = await launchPhotoMeasurement(context, imagePath);
    if (mounted && measured != null) {
      setState(() {
        _measuredDimensions = measured;
        _requestId = null;
      });
    }
  }

  Future<void> _pickSecondary(PhotoSource source) async {
    if (_isPicking) return;
    setState(() => _isPicking = true);
    try {
      final path = await widget.photoPicker.pick(source);
      if (mounted && path != null) {
        setState(() {
          _secondaryImagePath = path;
          _requestId = null;
        });
      }
    } on Object {
      if (mounted) {
        setState(() => _error = 'The second photo could not be opened.');
      }
    } finally {
      if (mounted) setState(() => _isPicking = false);
    }
  }

  Future<void> _showSecondAnglePicker() async {
    final source = await showModalBottomSheet<PhotoSource>(
      context: context,
      showDragHandle: true,
      builder: (context) => const _SecondAngleSheet(),
    );
    if (source != null && mounted) await _pickSecondary(source);
  }

  KnownDimensionInput? _knownDimension() {
    if (_measuredDimensions != null) return null;
    final text = _dimensionController.text.trim().replaceAll(',', '.');
    if (text.isEmpty) return null;
    final value = double.tryParse(text);
    if (value == null || !value.isFinite || value <= 0) {
      throw const FormatException();
    }
    return KnownDimensionInput(
      axis: _dimensionAxis,
      value: value,
      unit: _dimensionUnit,
    );
  }

  Future<void> _analyze() async {
    final imagePath = _imagePath;
    if (imagePath == null || _isAnalyzing) return;
    KnownDimensionInput? knownDimension;
    try {
      knownDimension = _knownDimension();
    } on FormatException {
      setState(() => _error = 'Enter a dimension greater than zero.');
      return;
    }
    if (widget.estimateRepository is CloudflareEstimateRepository) {
      try {
        final processor = const ScanImageProcessor();
        final warnings = <ScanImageWarning>[
          ...await processor.inspect(imagePath),
          if (_secondaryImagePath case final secondary?)
            ...await processor.inspect(secondary),
        ];
        if (!mounted) return;
        if (warnings.isNotEmpty) {
          final useAnyway = await _showScanCoach(warnings.toSet().toList());
          if (!mounted || !useAnyway) {
            if (mounted && !useAnyway) unawaited(_captureMeasured());
            return;
          }
        }
      } on ScanImageException catch (error) {
        if (mounted) setState(() => _error = error.message);
        return;
      }
    }

    final monetization = AppScope.of(context).monetization;
    final isIdempotentRetry = _requestId != null;
    await monetization.refreshAccess();
    if (!mounted) return;
    if (!monetization.access.canScan && !isIdempotentRetry) {
      final added = await showRewardedScanSheet(context);
      if (!mounted || !added) return;
      await monetization.refreshAccess();
      if (!mounted || !monetization.access.canScan) return;
    }

    _requestId ??= ScanRequestId.create();
    final run = ++_analysisRun;
    setState(() {
      _isAnalyzing = true;
      _analysisStep = 0;
      _error = null;
    });
    _startProgress(run);
    try {
      var result = await widget.estimateRepository.analyze(
        EstimateRequest(
          imagePath: imagePath,
          requestId: _requestId!,
          secondaryImagePath: _secondaryImagePath,
          material: _material,
          fillState: _fillState,
          referenceObject: _referenceObject,
          knownDimension: knownDimension,
          measuredDimensions: _measuredDimensions,
        ),
      );
      if (!mounted || run != _analysisRun) return;
      final measured = _measuredDimensions;
      if (measured != null) {
        final measurementNote =
            '${measured.formatSummary()} measured with ${measured.sourceLabel}';
        result = result.copyWith(
          dimensions: measured.mergeWith(result.dimensions),
          assumptions: [
            measurementNote,
            ...result.assumptions.where((item) => item != measurementNote),
          ],
        );
      }
      setState(() {
        _analysisTimer?.cancel();
        _result = result;
        _isAnalyzing = false;
        _analysisStep = 3;
        _requestId = null;
      });
      unawaited(AppScope.of(context).monetization.refreshAccess());
    } on CloudflareEstimateException catch (error) {
      if (!mounted || run != _analysisRun) return;
      setState(() {
        _analysisTimer?.cancel();
        _isAnalyzing = false;
        _error = error.isScanLimitReached
            ? 'You have used your available scans.'
            : error.message;
      });
      if (error.isScanLimitReached) {
        await AppScope.of(context).monetization.refreshAccess();
        if (mounted) {
          final added = await showRewardedScanSheet(context);
          if (added && mounted) unawaited(_analyze());
        }
      }
    } on Object {
      if (mounted && run == _analysisRun) {
        setState(() {
          _analysisTimer?.cancel();
          _isAnalyzing = false;
          _error = 'Analysis stopped. Check the connection and try again.';
        });
      }
    }
  }

  Future<bool> _showScanCoach(List<ScanImageWarning> warnings) async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Scan Coach'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final warning in warnings) ...[
                Text('• ${warning.message}'),
                const SizedBox(height: 8),
              ],
              const Text('No scan is used until you continue to analysis.'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Retake'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Use anyway'),
            ),
          ],
        ),
      ) ??
      false;

  void _startProgress(int run) {
    _analysisTimer?.cancel();
    _analysisTimer = Timer.periodic(const Duration(milliseconds: 600), (timer) {
      if (!mounted || run != _analysisRun || !_isAnalyzing) {
        timer.cancel();
        return;
      }
      if (_analysisStep >= 2) {
        timer.cancel();
        return;
      }
      setState(() => _analysisStep++);
    });
  }

  Future<void> _save() async {
    final result = _result;
    if (result == null || _saved) return;
    await AppScope.of(context).addMeasurement(result);
    if (!mounted) return;
    setState(() => _saved = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Saved to your private history.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _reset() {
    _analysisRun++;
    _analysisTimer?.cancel();
    setState(() {
      _imagePath = null;
      _secondaryImagePath = null;
      _measuredDimensions = null;
      _material = 'Unknown';
      _fillState = 'Unknown';
      _referenceObject = 'None';
      _dimensionAxis = 'Width';
      _dimensionUnit = 'cm';
      _dimensionController.clear();
      _isAnalyzing = false;
      _result = null;
      _error = null;
      _saved = false;
      _requestId = null;
    });
  }

  Future<void> _showDetails() {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) {
          void update(VoidCallback change) {
            setState(() {
              change();
              _requestId = null;
            });
            setSheetState(() {});
          }

          return SafeArea(
            top: false,
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                20,
                0,
                20,
                20 + MediaQuery.viewInsetsOf(context).bottom,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Optional details',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 18),
                  const _SheetLabel('Material'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final item in _materials)
                        ChoiceChip(
                          key: Key('material_$item'),
                          label: Text(item),
                          selected: _material == item,
                          onSelected: (_) => update(() => _material = item),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const _SheetLabel('Fill'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final item in _fillStates)
                        ChoiceChip(
                          key: Key('fill_state_$item'),
                          label: Text(item),
                          selected: _fillState == item,
                          onSelected: (_) => update(() => _fillState = item),
                        ),
                    ],
                  ),
                  if (_measuredDimensions == null) ...[
                    const SizedBox(height: 20),
                    const _SheetLabel('Known size'),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _dimensionAxis,
                            items: [
                              for (final item in _axes)
                                DropdownMenuItem(
                                  value: item,
                                  child: Text(item),
                                ),
                            ],
                            onChanged: (value) => update(
                              () => _dimensionAxis = value ?? _dimensionAxis,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            key: const Key('known_dimension_field'),
                            controller: _dimensionController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            onChanged: (_) => _requestId = null,
                            decoration: InputDecoration(
                              suffixText: _dimensionUnit,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SegmentedButton<String>(
                          segments: const [
                            ButtonSegment(value: 'cm', label: Text('cm')),
                            ButtonSegment(value: 'in', label: Text('in')),
                          ],
                          selected: {_dimensionUnit},
                          onSelectionChanged: (value) =>
                              update(() => _dimensionUnit = value.single),
                          showSelectedIcon: false,
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const _SheetLabel('Visible reference'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        for (final item in _references)
                          ChoiceChip(
                            key: Key('reference_$item'),
                            label: Text(item),
                            selected: _referenceObject == item,
                            onSelected: (_) =>
                                update(() => _referenceObject = item),
                          ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 20),
                  OutlinedButton.icon(
                    key: const Key('add_second_photo_button'),
                    onPressed: () async {
                      Navigator.of(sheetContext).pop();
                      await _showSecondAnglePicker();
                    },
                    icon: Icon(
                      _secondaryImagePath == null
                          ? Icons.add_a_photo_outlined
                          : Icons.refresh_rounded,
                    ),
                    label: Text(
                      _secondaryImagePath == null
                          ? 'Add second angle'
                          : 'Replace second angle',
                    ),
                  ),
                  const SizedBox(height: 8),
                  FilledButton(
                    onPressed: () => Navigator.of(sheetContext).pop(),
                    child: const Text('Done'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = _result != null
        ? 'Estimate'
        : _isAnalyzing
        ? 'Analyzing'
        : _imagePath == null
        ? 'New estimate'
        : 'Review';
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Close',
          onPressed: () => Navigator.of(context).pop(_result != null),
          icon: const Icon(Icons.close_rounded),
        ),
        title: Text(title),
        actions: [
          if (_imagePath != null && !_isAnalyzing)
            TextButton(onPressed: _reset, child: const Text('Start over')),
          const SizedBox(width: 8),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        child: _result != null
            ? _ResultView(
                key: const ValueKey('result'),
                measurement: _result!,
                unitSystem: AppScope.of(context).unitSystem,
                saved: _saved,
                onSave: _save,
                onReset: _reset,
              )
            : _isAnalyzing
            ? _AnalysisView(
                key: const ValueKey('analysis'),
                imagePath: _imagePath!,
                step: _analysisStep,
              )
            : _imagePath == null
            ? _CaptureView(
                key: const ValueKey('capture'),
                busy: _isPicking,
                error: _error,
                onMeasure: _captureMeasured,
                onGallery: _captureFromGallery,
              )
            : _ReviewView(
                key: const ValueKey('review'),
                imagePath: _imagePath!,
                secondImagePath: _secondaryImagePath,
                measured: _measuredDimensions,
                error: _error,
                onEditMeasurement: _editMeasurement,
                onClearMeasurement: () =>
                    setState(() => _measuredDimensions = null),
                onDetails: _showDetails,
                onAnalyze: _analyze,
              ),
      ),
    );
  }
}

class _CaptureView extends StatelessWidget {
  const _CaptureView({
    required this.busy,
    required this.error,
    required this.onMeasure,
    required this.onGallery,
    super.key,
  });

  final bool busy;
  final String? error;
  final VoidCallback onMeasure;
  final VoidCallback onGallery;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 36, 24, 28),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight - 64,
              maxWidth: 640,
            ),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Measure an object',
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                  const SizedBox(height: 24),
                  const AspectRatio(aspectRatio: 16 / 10, child: _ScanFrame()),
                  const Spacer(),
                  if (error != null) ...[
                    _InlineError(error!),
                    const SizedBox(height: 12),
                  ],
                  FilledButton.icon(
                    key: const Key('open_camera_button'),
                    onPressed: busy ? null : onMeasure,
                    icon: busy
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.photo_camera_outlined),
                    label: const Text('Measure'),
                  ),
                  TextButton.icon(
                    key: const Key('gallery_button'),
                    onPressed: busy ? null : onGallery,
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text('Photo'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ScanFrame extends StatelessWidget {
  const _ScanFrame();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _ScanFramePainter(),
      child: const SizedBox.expand(),
    );
  }
}

class _ScanFramePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(8)),
      Paint()..color = AppColors.surface,
    );
    final border = Paint()
      ..color = AppColors.line
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(8)),
      border,
    );

    final guide = Paint()
      ..color = AppColors.ink.withValues(alpha: 0.09)
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(size.width / 2, 18),
      Offset(size.width / 2, size.height - 18),
      guide,
    );
    canvas.drawLine(
      Offset(18, size.height / 2),
      Offset(size.width - 18, size.height / 2),
      guide,
    );

    final line = Paint()
      ..color = AppColors.ink
      ..strokeWidth = 2.3
      ..strokeCap = StrokeCap.round;
    final accent = Paint()
      ..color = AppColors.limeDark
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    final a = Offset(size.width * 0.28, size.height * 0.58);
    final b = Offset(size.width * 0.72, size.height * 0.58);
    final c = Offset(size.width * 0.72, size.height * 0.30);
    canvas.drawLine(a, b, accent);
    canvas.drawLine(b, c, line);
    for (final point in [a, b, c]) {
      canvas.drawCircle(point, 8, Paint()..color = AppColors.surface);
      canvas.drawCircle(point, 8, line..style = PaintingStyle.stroke);
      line.style = PaintingStyle.fill;
      canvas.drawCircle(point, 2.5, line);
    }
  }

  @override
  bool shouldRepaint(covariant _ScanFramePainter oldDelegate) => false;
}

class _ReviewView extends StatelessWidget {
  const _ReviewView({
    required this.imagePath,
    required this.secondImagePath,
    required this.measured,
    required this.error,
    required this.onEditMeasurement,
    required this.onClearMeasurement,
    required this.onDetails,
    required this.onAnalyze,
    super.key,
  });

  final String imagePath;
  final String? secondImagePath;
  final MeasuredDimensions? measured;
  final String? error;
  final VoidCallback onEditMeasurement;
  final VoidCallback onClearMeasurement;
  final VoidCallback onDetails;
  final VoidCallback onAnalyze;

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = math.max(
      20.0,
      (MediaQuery.sizeOf(context).width - 720) / 2,
    );
    return ListView(
      padding: EdgeInsets.fromLTRB(horizontalPadding, 8, horizontalPadding, 30),
      children: [
        Text(
          'Confirm the object',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 14),
        Align(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: AspectRatio(
              aspectRatio: 16 / 10,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  File(imagePath),
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    color: AppColors.navySoft,
                    alignment: Alignment.center,
                    child: const Icon(Icons.photo_outlined, size: 48),
                  ),
                ),
              ),
            ),
          ),
        ),
        if (measured case final dimensions?) ...[
          const SizedBox(height: 10),
          _MeasurementRow(
            measured: dimensions,
            onEdit: onEditMeasurement,
            onClear: onClearMeasurement,
          ),
        ],
        if (secondImagePath != null) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              ClipRRect(
                key: const Key('second_photo_preview'),
                borderRadius: BorderRadius.circular(6),
                child: Image.file(
                  File(secondImagePath!),
                  width: 42,
                  height: 42,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    width: 42,
                    height: 42,
                    color: AppColors.navySoft,
                    child: const Icon(Icons.photo_outlined),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              const Text('Second angle added'),
            ],
          ),
        ],
        const SizedBox(height: 14),
        if (error != null) ...[
          const SizedBox(height: 12),
          _InlineError(error!),
        ],
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                key: const Key('add_details_button'),
                onPressed: onDetails,
                icon: const Icon(Icons.tune_rounded),
                label: const Text('Details'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton.icon(
                key: const Key('analyze_button'),
                onPressed: onAnalyze,
                icon: const Icon(Icons.auto_awesome_rounded),
                label: const Text('Estimate'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MeasurementRow extends StatelessWidget {
  const _MeasurementRow({
    required this.measured,
    required this.onEdit,
    required this.onClear,
  });

  final MeasuredDimensions measured;
  final VoidCallback onEdit;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.limeDark.withValues(alpha: 0.35)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  measured.formatSummary(),
                  key: const Key('measured_summary'),
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                Text(
                  measured.sourceLabel,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontSize: 11),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Edit dimensions',
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined, size: 20),
          ),
          IconButton(
            tooltip: 'Remove dimensions',
            onPressed: onClear,
            icon: const Icon(Icons.close_rounded, size: 20),
          ),
        ],
      ),
    );
  }
}

class _AnalysisView extends StatelessWidget {
  const _AnalysisView({required this.imagePath, required this.step, super.key});

  final String imagePath;
  final int step;

  @override
  Widget build(BuildContext context) {
    const labels = ['Reading shape', 'Estimating material', 'Building range'];
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 36),
      child: Column(
        children: [
          const Spacer(),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(
              File(imagePath),
              width: 180,
              height: 180,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(
                width: 180,
                height: 180,
                color: AppColors.navySoft,
                child: const Icon(Icons.inventory_2_outlined, size: 48),
              ),
            ),
          ),
          const SizedBox(height: 28),
          Text(
            labels[step.clamp(0, 2)],
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          const LinearProgressIndicator(minHeight: 4),
          const Spacer(),
        ],
      ),
    );
  }
}

class _ResultView extends StatelessWidget {
  const _ResultView({
    required this.measurement,
    required this.unitSystem,
    required this.saved,
    required this.onSave,
    required this.onReset,
    super.key,
  });

  final Measurement measurement;
  final UnitSystem unitSystem;
  final bool saved;
  final VoidCallback onSave;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = math.max(
      20.0,
      (MediaQuery.sizeOf(context).width - 720) / 2,
    );
    return ListView(
      padding: EdgeInsets.fromLTRB(horizontalPadding, 8, horizontalPadding, 34),
      children: [
        Align(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: AspectRatio(
              aspectRatio: 16 / 10,
              child: ClipRRect(
                key: const Key('result_photo'),
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  File(measurement.imagePath),
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    color: AppColors.navySoft,
                    child: const Icon(Icons.inventory_2_outlined, size: 52),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          measurement.objectLabel,
          key: const Key('result_object_label'),
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 18),
        Text(
          formatWeight(measurement.estimateGrams, unitSystem),
          key: const Key('result_weight'),
          style: const TextStyle(
            color: AppColors.ink,
            fontSize: 44,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'LIKELY RANGE',
          style: TextStyle(
            color: AppColors.inkMuted,
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
          ),
        ),
        Text(
          '${formatWeight(measurement.lowerBoundGrams, unitSystem)} – '
          '${formatWeight(measurement.upperBoundGrams, unitSystem)}',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 18),
        _ResultFact(
          label: 'Dimensions',
          value: formatDimensions(measurement.dimensions, unitSystem),
        ),
        _ResultFact(label: 'Confidence', value: measurement.confidence.name),
        const SizedBox(height: 8),
        ExpansionTile(
          tilePadding: EdgeInsets.zero,
          childrenPadding: const EdgeInsets.only(bottom: 12),
          title: const Text('How this was estimated'),
          children: [
            for (final assumption in measurement.assumptions)
              Padding(
                padding: const EdgeInsets.only(bottom: 7),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text('• $assumption'),
                ),
              ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: onReset,
                child: const Text('Try another'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton(
                key: const Key('save_result_button'),
                onPressed: saved ? null : onSave,
                child: Text(saved ? 'Saved' : 'Save'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ResultFact extends StatelessWidget {
  const _ResultFact({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.coral.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(message, style: const TextStyle(color: AppColors.coral)),
    );
  }
}

class _SheetLabel extends StatelessWidget {
  const _SheetLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(label, style: Theme.of(context).textTheme.titleMedium);
  }
}

class _SecondAngleSheet extends StatelessWidget {
  const _SecondAngleSheet();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Second angle',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: () => Navigator.pop(context, PhotoSource.camera),
              icon: const Icon(Icons.photo_camera_outlined),
              label: const Text('Take photo'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              key: const Key('second_photo_gallery_button'),
              onPressed: () => Navigator.pop(context, PhotoSource.gallery),
              icon: const Icon(Icons.photo_library_outlined),
              label: const Text('Choose photo'),
            ),
          ],
        ),
      ),
    );
  }
}
