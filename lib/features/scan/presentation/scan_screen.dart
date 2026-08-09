import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../app/app_controller.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/display_labels.dart';
import '../../../l10n/l10n.dart';
import '../../measurements/domain/measurement.dart';
import '../../monetization/presentation/rewarded_scan_sheet.dart';
import '../data/cloudflare_estimate_repository.dart';
import '../data/estimate_repository_factory.dart';
import '../data/photo_picker.dart';
import '../data/scan_image_processor.dart';
import '../domain/estimate_repository.dart';
import 'capture/camera_launcher.dart';

class ScanScreen extends StatefulWidget {
  ScanScreen({
    EstimateRepository? estimateRepository,
    PhotoPicker? photoPicker,
    CameraLauncher? cameraLauncher,
    this.autoStart = true,
    this.startWithGallery = false,
    super.key,
  }) : estimateRepository = estimateRepository ?? buildEstimateRepository(),
       photoPicker = photoPicker ?? DevicePhotoPicker(),
       cameraLauncher = cameraLauncher ?? const DeviceCameraLauncher();

  final EstimateRepository estimateRepository;
  final PhotoPicker photoPicker;
  final CameraLauncher cameraLauncher;
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
  static const _axes = ['Length', 'Width', 'Height'];

  final _dimensionController = TextEditingController();
  String? _imagePath;
  String? _secondaryImagePath;
  String _material = 'Unknown';
  String _fillState = 'Unknown';
  String _referenceObject = 'None';
  String _dimensionAxis = 'Length';
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
  bool _routePopAllowed = false;
  bool _routePopScheduled = false;

  @override
  void initState() {
    super.initState();
    if (widget.autoStart) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (widget.startWithGallery) {
          unawaited(_captureFromGallery());
        } else {
          unawaited(_capturePhoto());
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

  Future<void> _capturePhoto() async {
    if (_isPicking) return;
    setState(() {
      _isPicking = true;
      _error = null;
      _requestId = null;
    });
    try {
      final imagePath = await widget.cameraLauncher.launch(context);
      if (!mounted || imagePath == null) return;
      _acceptImage(imagePath);
    } on Object {
      if (mounted) {
        setState(() => _error = context.l10n.scanCameraOpenFailed);
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
      _acceptImage(imagePath);
    } on Object {
      if (mounted) {
        setState(() => _error = context.l10n.scanSelectedPhotoOpenFailed);
      }
    } finally {
      if (mounted) setState(() => _isPicking = false);
    }
  }

  void _acceptImage(String imagePath) {
    setState(() {
      _imagePath = imagePath;
      _secondaryImagePath = null;
      _result = null;
      _saved = false;
      _error = null;
    });
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
        setState(() => _error = context.l10n.scanSecondPhotoOpenFailed);
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
      setState(() => _error = context.l10n.scanDimensionPositive);
      return;
    }
    final isProductionCloudScan =
        widget.estimateRepository is CloudflareEstimateRepository;
    if (isProductionCloudScan) {
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
            if (mounted && !useAnyway) unawaited(_capturePhoto());
            return;
          }
        }
      } on ScanImageException catch (error) {
        if (mounted) {
          setState(() {
            _error = switch (error.code) {
              ScanImageErrorCode.missing => context.l10n.scanPhotoMissing,
              ScanImageErrorCode.corrupt => context.l10n.scanPhotoCorrupt,
              ScanImageErrorCode.tooSmall => context.l10n.scanPhotoTooSmall,
            };
          });
        }
        return;
      }
    }

    final isIdempotentRetry = _requestId != null;
    if (isProductionCloudScan) {
      final monetization = AppScope.of(context).monetization;
      await monetization.refreshAccess();
      if (!mounted) return;

      final accessUnavailable =
          monetization.message != null ||
          !monetization.access.isAuthoritative ||
          !monetization.access.scanAccessEnforced;
      if (accessUnavailable) {
        setState(() {
          _error = context.l10n.scanAccessUnverified;
        });
        return;
      }

      // A retry with the same request ID may replay a completed result whose
      // credit has already been consumed, so only a fresh request needs a
      // positive wallet balance here.
      if (!monetization.access.canScan && !isIdempotentRetry) {
        final added = await showRewardedScanSheet(context);
        if (!mounted || !added) return;
        await monetization.refreshAccess();
        if (!mounted ||
            monetization.message != null ||
            !monetization.access.canScan) {
          return;
        }
      }
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
      final result = await widget.estimateRepository.analyze(
        EstimateRequest(
          imagePath: imagePath,
          requestId: _requestId!,
          secondaryImagePath: _secondaryImagePath,
          material: _material,
          fillState: _fillState,
          referenceObject: _referenceObject,
          knownDimension: knownDimension,
          responseLocale: Localizations.localeOf(context).languageCode,
        ),
      );
      if (!mounted || run != _analysisRun) return;
      setState(() {
        _analysisTimer?.cancel();
        _result = result;
        _isAnalyzing = false;
        _analysisStep = 3;
        _requestId = null;
      });
      unawaited(AppScope.of(context).monetization.onScanCompleted());
    } on CloudflareEstimateException catch (error) {
      if (!mounted || run != _analysisRun) return;
      setState(() {
        _analysisTimer?.cancel();
        _isAnalyzing = false;
        _error = error.isScanLimitReached
            ? context.l10n.scanLimitReached
            : context.l10n.scanCloudFailure;
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
          _error = context.l10n.scanAnalysisStopped;
        });
      }
    }
  }

  Future<bool> _showScanCoach(List<ScanImageWarning> warnings) async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(context.l10n.scanCoachTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final warning in warnings) ...[
                Text(
                  '• ${switch (warning) {
                    ScanImageWarning.dark => context.l10n.scanPhotoDarkWarning,
                    ScanImageWarning.blurry => context.l10n.scanPhotoBlurryWarning,
                  }}',
                ),
                const SizedBox(height: 8),
              ],
              Text(context.l10n.scanCoachNoCredit),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(context.l10n.scanCoachRetake),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(context.l10n.scanCoachUseAnyway),
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
      SnackBar(
        content: Text(context.l10n.scanSavedPrivateHistory),
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
      _material = 'Unknown';
      _fillState = 'Unknown';
      _referenceObject = 'None';
      _dimensionAxis = 'Length';
      _dimensionUnit = 'cm';
      _dimensionController.clear();
      _isAnalyzing = false;
      _result = null;
      _error = null;
      _saved = false;
      _requestId = null;
    });
  }

  void _close() {
    if (_routePopScheduled || _routePopAllowed) return;
    final completed = _result != null;
    setState(() {
      _routePopAllowed = true;
      _routePopScheduled = true;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.of(context).pop<bool>(completed);
    });
  }

  void _handleRoutePop(bool didPop, bool? _) {
    if (didPop || _routePopScheduled) return;
    _close();
  }

  Future<void> _showDetails() {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) {
          final l10n = context.l10n;
          void update(VoidCallback change) {
            setState(() {
              change();
              _requestId = null;
            });
            setSheetState(() {});
          }

          return SafeArea(
            top: false,
            maintainBottomViewPadding: true,
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
                    l10n.scanOptionalDetails,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 18),
                  _SheetLabel(l10n.scanMaterial),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final item in _materials)
                        ChoiceChip(
                          key: Key('material_$item'),
                          label: Text(localizedMaterial(l10n, item)),
                          selected: _material == item,
                          onSelected: (_) => update(() => _material = item),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _SheetLabel(l10n.scanFill),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final item in _fillStates)
                        ChoiceChip(
                          key: Key('fill_state_$item'),
                          label: Text(localizedFillState(l10n, item)),
                          selected: _fillState == item,
                          onSelected: (_) => update(() => _fillState = item),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _SheetLabel(l10n.scanKnownSize),
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
                                child: Text(localizedDimensionAxis(l10n, item)),
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
                  _SheetLabel(l10n.scanVisibleReference),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final item in _references)
                        ChoiceChip(
                          key: Key('reference_$item'),
                          label: Text(localizedReferenceObject(l10n, item)),
                          selected: _referenceObject == item,
                          onSelected: (_) =>
                              update(() => _referenceObject = item),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: () => Navigator.of(sheetContext).pop(),
                    child: Text(l10n.commonDone),
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
    final l10n = context.l10n;
    final title = _result != null
        ? l10n.scanEstimate
        : _isAnalyzing
        ? l10n.scanAnalyzing
        : _imagePath == null
        ? l10n.scanNewEstimate
        : l10n.scanReview;
    return PopScope<bool>(
      canPop: _routePopAllowed,
      onPopInvokedWithResult: _handleRoutePop,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            tooltip: l10n.commonClose,
            onPressed: _close,
            icon: const Icon(Icons.close_rounded),
          ),
          title: Text(title),
          actions: [
            if (_imagePath != null && !_isAnalyzing)
              TextButton(onPressed: _reset, child: Text(l10n.commonStartOver)),
            const SizedBox(width: 8),
          ],
        ),
        body: SafeArea(
          top: false,
          maintainBottomViewPadding: true,
          child: AnimatedSwitcher(
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
                    onCapture: _capturePhoto,
                    onGallery: _captureFromGallery,
                  )
                : _ReviewView(
                    key: const ValueKey('review'),
                    imagePath: _imagePath!,
                    secondImagePath: _secondaryImagePath,
                    error: _error,
                    onAddSideView: _showSecondAnglePicker,
                    onRemoveSideView: () => setState(() {
                      _secondaryImagePath = null;
                      _requestId = null;
                    }),
                    onDetails: _showDetails,
                    onAnalyze: _analyze,
                  ),
          ),
        ),
      ),
    );
  }
}

class _CaptureView extends StatelessWidget {
  const _CaptureView({
    required this.busy,
    required this.error,
    required this.onCapture,
    required this.onGallery,
    super.key,
  });

  final bool busy;
  final String? error;
  final VoidCallback onCapture;
  final VoidCallback onGallery;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
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
                    l10n.scanPhotographObject,
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
                    onPressed: busy ? null : onCapture,
                    icon: busy
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.photo_camera_outlined),
                    label: Text(l10n.scanTakePhoto),
                  ),
                  TextButton.icon(
                    key: const Key('gallery_button'),
                    onPressed: busy ? null : onGallery,
                    icon: const Icon(Icons.photo_library_outlined),
                    label: Text(l10n.scanChooseGallery),
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

    final objectRect = Rect.fromCenter(
      center: size.center(Offset.zero),
      width: size.width * 0.28,
      height: size.height * 0.48,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(objectRect, const Radius.circular(18)),
      Paint()..color = AppColors.navySoft,
    );

    final cornerPaint = Paint()
      ..color = AppColors.limeDark
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;
    const inset = 22.0;
    final length = math.min(30.0, size.shortestSide * 0.16);
    for (final origin in [
      const Offset(inset, inset),
      Offset(size.width - inset, inset),
      Offset(inset, size.height - inset),
      Offset(size.width - inset, size.height - inset),
    ]) {
      final xDirection = origin.dx < size.width / 2 ? 1.0 : -1.0;
      final yDirection = origin.dy < size.height / 2 ? 1.0 : -1.0;
      canvas.drawLine(
        origin,
        origin + Offset(length * xDirection, 0),
        cornerPaint,
      );
      canvas.drawLine(
        origin,
        origin + Offset(0, length * yDirection),
        cornerPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ScanFramePainter oldDelegate) => false;
}

class _ReviewView extends StatelessWidget {
  const _ReviewView({
    required this.imagePath,
    required this.secondImagePath,
    required this.error,
    required this.onAddSideView,
    required this.onRemoveSideView,
    required this.onDetails,
    required this.onAnalyze,
    super.key,
  });

  final String imagePath;
  final String? secondImagePath;
  final String? error;
  final VoidCallback onAddSideView;
  final VoidCallback onRemoveSideView;
  final VoidCallback onDetails;
  final VoidCallback onAnalyze;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final horizontalPadding = math.max(
      20.0,
      (MediaQuery.sizeOf(context).width - 720) / 2,
    );
    return ListView(
      padding: EdgeInsets.fromLTRB(horizontalPadding, 8, horizontalPadding, 30),
      children: [
        Text(
          l10n.scanConfirmObject,
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
        const SizedBox(height: 12),
        _SideViewCard(
          imagePath: secondImagePath,
          onAddOrReplace: onAddSideView,
          onRemove: onRemoveSideView,
        ),
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
                label: Text(l10n.scanDetails),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton.icon(
                key: const Key('analyze_button'),
                onPressed: onAnalyze,
                icon: const Icon(Icons.auto_awesome_rounded),
                label: Text(l10n.scanEstimate),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SideViewCard extends StatelessWidget {
  const _SideViewCard({
    required this.imagePath,
    required this.onAddOrReplace,
    required this.onRemove,
  });

  final String? imagePath;
  final VoidCallback onAddOrReplace;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (imagePath == null)
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.navySoft,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(Icons.add_photo_alternate_outlined, size: 24),
            )
          else
            ClipRRect(
              key: const Key('second_photo_preview'),
              borderRadius: BorderRadius.circular(6),
              child: Image.file(
                File(imagePath!),
                width: 48,
                height: 48,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  width: 48,
                  height: 48,
                  color: AppColors.navySoft,
                  child: const Icon(Icons.photo_outlined),
                ),
              ),
            ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  imagePath == null
                      ? l10n.scanAddSideView
                      : l10n.scanSideViewAdded,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  imagePath == null
                      ? l10n.scanSideViewOptional
                      : l10n.scanSideViewBenefit,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontSize: 11),
                ),
              ],
            ),
          ),
          TextButton(
            key: const Key('add_second_photo_button'),
            onPressed: onAddOrReplace,
            child: Text(imagePath == null ? l10n.scanAdd : l10n.scanReplace),
          ),
          if (imagePath != null)
            IconButton(
              key: const Key('remove_second_photo_button'),
              tooltip: l10n.scanRemoveSideView,
              onPressed: onRemove,
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
    final l10n = context.l10n;
    final labels = [
      l10n.scanProgressShape,
      l10n.scanProgressMaterial,
      l10n.scanProgressRange,
    ];
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
    final l10n = context.l10n;
    final localeName = Localizations.localeOf(context).toLanguageTag();
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
          formatWeight(
            measurement.estimateGrams,
            unitSystem,
            localeName: localeName,
          ),
          key: const Key('result_weight'),
          style: const TextStyle(
            color: AppColors.ink,
            fontSize: 44,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          l10n.scanLikelyRange,
          style: const TextStyle(
            color: AppColors.inkMuted,
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
          ),
        ),
        Text(
          '${formatWeight(measurement.lowerBoundGrams, unitSystem, localeName: localeName)} – '
          '${formatWeight(measurement.upperBoundGrams, unitSystem, localeName: localeName)}',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 18),
        _ResultFact(
          label: l10n.scanAiVisualSize,
          value: formatApproximateDimensions(
            measurement.dimensions,
            unitSystem,
            localeName: localeName,
          ),
        ),
        _ResultFact(
          label: l10n.scanConfidence,
          value: localizedConfidence(l10n, measurement.confidence),
        ),
        const SizedBox(height: 8),
        ExpansionTile(
          tilePadding: EdgeInsets.zero,
          childrenPadding: const EdgeInsets.only(bottom: 12),
          title: Text(l10n.scanHowEstimated),
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
                child: Text(l10n.scanTryAnother),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton(
                key: const Key('save_result_button'),
                onPressed: saved ? null : onSave,
                child: Text(saved ? l10n.commonSaved : l10n.commonSave),
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
    final l10n = context.l10n;
    return SafeArea(
      top: false,
      maintainBottomViewPadding: true,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.scanSecondViewTitle,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 7),
            Text(
              l10n.scanSecondViewBody,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => Navigator.pop(context, PhotoSource.camera),
              icon: const Icon(Icons.photo_camera_outlined),
              label: Text(l10n.scanTakePhoto),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              key: const Key('second_photo_gallery_button'),
              onPressed: () => Navigator.pop(context, PhotoSource.gallery),
              icon: const Icon(Icons.photo_library_outlined),
              label: Text(l10n.scanChoosePhoto),
            ),
          ],
        ),
      ),
    );
  }
}
