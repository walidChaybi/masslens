import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

import '../../../app/app_controller.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_components.dart';
import '../../measurements/domain/measurement.dart';
import '../../measurements/presentation/measurement_detail_screen.dart';
import '../data/estimate_repository_factory.dart';
import '../data/photo_picker.dart';
import '../domain/estimate_repository.dart';

class ScanScreen extends StatefulWidget {
  ScanScreen({
    EstimateRepository? estimateRepository,
    PhotoPicker? photoPicker,
    super.key,
  }) : estimateRepository = estimateRepository ?? buildEstimateRepository(),
       photoPicker = photoPicker ?? DevicePhotoPicker();

  final EstimateRepository estimateRepository;
  final PhotoPicker photoPicker;

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  static const _categories = [
    'Auto',
    'Food',
    'Parcel',
    'Furniture',
    'Electronics',
    'Other',
  ];
  static const _structures = ['Unknown', 'Solid', 'Hollow'];

  String? _imagePath;
  String? _secondaryImagePath;
  String _category = 'Auto';
  String _structure = 'Unknown';
  bool _isPicking = false;
  bool _isAnalyzing = false;
  int _analysisStep = 0;
  Measurement? _result;
  String? _error;
  bool _saved = false;
  int _analysisRun = 0;

  Future<void> _pick(PhotoSource source, {bool secondary = false}) async {
    if (_isPicking) return;
    setState(() {
      _isPicking = true;
      _error = null;
    });
    try {
      final path = await widget.photoPicker.pick(source);
      if (!mounted || path == null) return;
      setState(() {
        if (secondary) {
          _secondaryImagePath = path;
        } else {
          _imagePath = path;
          _secondaryImagePath = null;
        }
        _result = null;
        _saved = false;
      });
    } on Object {
      if (!mounted) return;
      setState(() {
        _error =
            'The photo could not be opened. Check camera or photo access and '
            'try again.';
      });
    } finally {
      if (mounted) setState(() => _isPicking = false);
    }
  }

  Future<void> _showSecondAnglePicker() async {
    final source = await showModalBottomSheet<PhotoSource>(
      context: context,
      showDragHandle: true,
      builder: (context) => const _SecondAngleSourceSheet(),
    );
    if (source == null || !mounted) return;
    await _pick(source, secondary: true);
  }

  Future<void> _analyze() async {
    final imagePath = _imagePath;
    if (imagePath == null || _isAnalyzing) return;
    final run = ++_analysisRun;
    setState(() {
      _isAnalyzing = true;
      _analysisStep = 0;
      _error = null;
    });
    unawaited(_advanceProgress(run));

    try {
      final result = await widget.estimateRepository.analyze(
        EstimateRequest(
          imagePath: imagePath,
          secondaryImagePath: _secondaryImagePath,
          category: _category,
          structure: _structure,
        ),
      );
      if (!mounted || run != _analysisRun) return;
      setState(() {
        _result = result;
        _isAnalyzing = false;
        _analysisStep = 3;
      });
    } on Object {
      if (!mounted || run != _analysisRun) return;
      setState(() {
        _isAnalyzing = false;
        _error =
            'Analysis stopped unexpectedly. Check connection, then try again.';
      });
    }
  }

  Future<void> _advanceProgress(int run) async {
    await Future<void>.delayed(const Duration(milliseconds: 520));
    if (!mounted || run != _analysisRun || !_isAnalyzing) return;
    setState(() => _analysisStep = 1);
    await Future<void>.delayed(const Duration(milliseconds: 620));
    if (!mounted || run != _analysisRun || !_isAnalyzing) return;
    setState(() => _analysisStep = 2);
  }

  void _reset() {
    _analysisRun++;
    setState(() {
      _imagePath = null;
      _secondaryImagePath = null;
      _category = 'Auto';
      _structure = 'Unknown';
      _isAnalyzing = false;
      _result = null;
      _error = null;
      _saved = false;
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
        content: Text('Estimate saved to your private history.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Close',
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close_rounded),
        ),
        title: Text(
          _result != null
              ? 'Your estimate'
              : _isAnalyzing
              ? 'Analyzing'
              : _imagePath == null
              ? 'New estimate'
              : _secondaryImagePath == null
              ? 'Review photo'
              : 'Review photos',
        ),
        actions: [
          if (_imagePath != null && !_isAnalyzing)
            TextButton(onPressed: _reset, child: const Text('Start over')),
          const SizedBox(width: 8),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        child: _result != null
            ? _buildResult(context, _result!)
            : _isAnalyzing
            ? _AnalysisView(
                key: const ValueKey('analysis'),
                imagePath: _imagePath!,
                photoCount: _secondaryImagePath == null ? 1 : 2,
                step: _analysisStep,
                engineLabel: EstimateEngineConfig.analysisModeLabel,
                privacyLabel: EstimateEngineConfig.analysisPrivacyLabel,
              )
            : _imagePath == null
            ? _CaptureView(
                key: const ValueKey('capture'),
                isPicking: _isPicking,
                error: _error,
                onCamera: () => _pick(PhotoSource.camera),
                onGallery: () => _pick(PhotoSource.gallery),
              )
            : _buildReview(context),
      ),
    );
  }

  Widget _buildReview(BuildContext context) {
    return ListView(
      key: const ValueKey('review'),
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 34),
      children: [
        Text(
          'Confirm the object',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 7),
        Text(
          'A little context reduces the guesswork and narrows the range.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 18),
        AspectRatio(
          aspectRatio: 4 / 3,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.file(
                  File(_imagePath!),
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: AppColors.navySoft,
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.broken_image_outlined,
                      size: 52,
                      color: AppColors.inkMuted,
                    ),
                  ),
                ),
                const InstrumentCorners(),
                Positioned(
                  left: 16,
                  bottom: 16,
                  child: StatusPill(
                    label: 'Primary view',
                    icon: Icons.looks_one_outlined,
                    background: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        _SecondAngleCard(
          imagePath: _secondaryImagePath,
          isPicking: _isPicking,
          onAddOrReplace: _showSecondAnglePicker,
          onRemove: () => setState(() => _secondaryImagePath = null),
        ),
        const SizedBox(height: 24),
        Text('Object category', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 4),
        Text(
          'Choose the closest match, or let the demo engine infer it.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final category in _categories)
              ChoiceChip(
                label: Text(category),
                selected: _category == category,
                onSelected: (_) => setState(() => _category = category),
              ),
          ],
        ),
        const SizedBox(height: 24),
        Text(
          'Internal structure',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 4),
        Text(
          'This changes the assumed material fill and expected density.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 12),
        SegmentedButton<String>(
          segments: [
            for (final structure in _structures)
              ButtonSegment<String>(
                value: structure,
                label: Text(structure),
                icon: Icon(switch (structure) {
                  'Solid' => Icons.square_rounded,
                  'Hollow' => Icons.check_box_outline_blank_rounded,
                  _ => Icons.help_outline_rounded,
                }),
              ),
          ],
          selected: {_structure},
          onSelectionChanged: (value) {
            setState(() => _structure = value.single);
          },
          showSelectedIcon: false,
        ),
        if (_error != null) ...[
          const SizedBox(height: 18),
          _ErrorBanner(message: _error!),
        ],
        const SizedBox(height: 26),
        FilledButton.icon(
          key: const Key('analyze_button'),
          onPressed: _analyze,
          icon: const Icon(Icons.auto_awesome_rounded),
          label: const Text('Estimate weight and size'),
        ),
        const SizedBox(height: 12),
        Text(
          EstimateEngineConfig.reviewFootnote,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.inkMuted,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildResult(BuildContext context, Measurement result) {
    return ListView(
      key: const ValueKey('result'),
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 36),
      children: [
        MeasurementSummary(
          measurement: result,
          unitSystem: AppScope.of(context).unitSystem,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _reset,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Try another'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                key: const Key('save_result_button'),
                onPressed: _saved ? null : _save,
                icon: Icon(
                  _saved ? Icons.check_rounded : Icons.bookmark_add_outlined,
                ),
                label: Text(_saved ? 'Saved' : 'Save result'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextButton.icon(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.home_outlined),
          label: const Text('Return home'),
        ),
      ],
    );
  }
}

class _CaptureView extends StatelessWidget {
  const _CaptureView({
    required this.isPicking,
    required this.error,
    required this.onCamera,
    required this.onGallery,
    super.key,
  });

  final bool isPicking;
  final String? error;
  final VoidCallback onCamera;
  final VoidCallback onGallery;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 34),
      children: [
        const Eyebrow('Step 1 of 3'),
        const SizedBox(height: 9),
        Text(
          'Frame one clear object.',
          style: Theme.of(context).textTheme.headlineLarge,
        ),
        const SizedBox(height: 8),
        Text(
          'Use an uncluttered background and keep every edge visible.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 22),
        AspectRatio(
          aspectRatio: 4 / 5,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.ink,
              borderRadius: BorderRadius.circular(32),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned.fill(
                  child: CustomPaint(painter: const _CameraGridPainter()),
                ),
                Container(
                  width: 122,
                  height: 154,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.12),
                    ),
                  ),
                  child: const Icon(
                    Icons.inventory_2_outlined,
                    color: AppColors.aqua,
                    size: 62,
                  ),
                ),
                const Positioned.fill(
                  child: Padding(
                    padding: EdgeInsets.all(26),
                    child: InstrumentCorners(),
                  ),
                ),
                const Positioned(
                  top: 24,
                  child: StatusPill(
                    label: 'One object · all edges visible',
                    icon: Icons.center_focus_strong_rounded,
                    background: AppColors.lime,
                  ),
                ),
                const Positioned(
                  bottom: 26,
                  child: Text(
                    'GOOD LIGHT  •  SIMPLE BACKGROUND',
                    style: TextStyle(
                      color: Colors.white60,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.1,
                    ),
                  ),
                ),
                if (isPicking)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.ink.withValues(alpha: 0.72),
                        borderRadius: BorderRadius.circular(32),
                      ),
                      alignment: Alignment.center,
                      child: const CircularProgressIndicator(
                        color: AppColors.lime,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: 16),
          _ErrorBanner(message: error!),
        ],
        const SizedBox(height: 20),
        FilledButton.icon(
          key: const Key('camera_button'),
          onPressed: isPicking ? null : onCamera,
          icon: const Icon(Icons.photo_camera_outlined),
          label: const Text('Take a photo'),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          key: const Key('gallery_button'),
          onPressed: isPicking ? null : onGallery,
          icon: const Icon(Icons.photo_library_outlined),
          label: const Text('Choose from gallery'),
        ),
      ],
    );
  }
}

class _SecondAngleCard extends StatelessWidget {
  const _SecondAngleCard({
    required this.imagePath,
    required this.isPicking,
    required this.onAddOrReplace,
    required this.onRemove,
  });

  final String? imagePath;
  final bool isPicking;
  final VoidCallback onAddOrReplace;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final path = imagePath;
    return Material(
      color: AppColors.aqua.withValues(alpha: 0.09),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: const BorderSide(color: AppColors.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: path == null
          ? InkWell(
              key: const Key('add_second_photo_button'),
              onTap: isPicking ? null : onAddOrReplace,
              child: const Padding(
                padding: EdgeInsets.all(15),
                child: Row(
                  children: [
                    _SecondAngleIcon(icon: Icons.add_a_photo_outlined),
                    SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Add a second angle',
                            style: TextStyle(
                              color: AppColors.ink,
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            'Optional · show the same object from the side or top',
                            style: TextStyle(
                              color: AppColors.inkMuted,
                              fontSize: 11.5,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.inkMuted,
                    ),
                  ],
                ),
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  ClipRRect(
                    key: const Key('second_photo_preview'),
                    borderRadius: BorderRadius.circular(16),
                    child: SizedBox(
                      width: 76,
                      height: 76,
                      child: Image.file(
                        File(path),
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(
                          color: AppColors.navySoft,
                          child: const Icon(
                            Icons.photo_outlined,
                            color: AppColors.inkMuted,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 13),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Second angle added',
                          style: TextStyle(
                            color: AppColors.ink,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Used to improve depth and shape estimates.',
                          style: TextStyle(
                            color: AppColors.inkMuted,
                            fontSize: 11.5,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        key: const Key('replace_second_photo_button'),
                        tooltip: 'Replace second angle',
                        onPressed: isPicking ? null : onAddOrReplace,
                        icon: const Icon(Icons.refresh_rounded),
                      ),
                      IconButton(
                        key: const Key('remove_second_photo_button'),
                        tooltip: 'Remove second angle',
                        onPressed: isPicking ? null : onRemove,
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}

class _SecondAngleIcon extends StatelessWidget {
  const _SecondAngleIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.ink,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Icon(icon, color: AppColors.lime, size: 21),
    );
  }
}

class _SecondAngleSourceSheet extends StatelessWidget {
  const _SecondAngleSourceSheet();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Add a second angle',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 7),
            Text(
              'Photograph the same object from the side or above. Keep the '
              'whole object visible.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              key: const Key('second_photo_camera_button'),
              onPressed: () => Navigator.pop(context, PhotoSource.camera),
              icon: const Icon(Icons.photo_camera_outlined),
              label: const Text('Take second photo'),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              key: const Key('second_photo_gallery_button'),
              onPressed: () => Navigator.pop(context, PhotoSource.gallery),
              icon: const Icon(Icons.photo_library_outlined),
              label: const Text('Choose from gallery'),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnalysisView extends StatefulWidget {
  const _AnalysisView({
    required this.imagePath,
    required this.photoCount,
    required this.step,
    required this.engineLabel,
    required this.privacyLabel,
    super.key,
  });

  final String imagePath;
  final int photoCount;
  final int step;
  final String engineLabel;
  final String privacyLabel;

  @override
  State<_AnalysisView> createState() => _AnalysisViewState();
}

class _AnalysisViewState extends State<_AnalysisView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1750),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final labels = [
      'Checking photo quality',
      widget.photoCount == 2 ? 'Comparing both angles' : 'Finding object edges',
      'Matching volume and density',
    ];
    final step = widget.step.clamp(0, labels.length - 1);

    return ListView(
      key: const ValueKey('analysis_content'),
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 34),
      children: [
        Eyebrow(widget.engineLabel),
        const SizedBox(height: 9),
        Text(
          'Scanning photo',
          style: Theme.of(context).textTheme.headlineLarge,
        ),
        const SizedBox(height: 18),
        AspectRatio(
          aspectRatio: 4 / 5,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.ink,
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: AppColors.ink.withValues(alpha: 0.18),
                  blurRadius: 28,
                  offset: const Offset(0, 15),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(32),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.file(
                    File(widget.imagePath),
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      color: AppColors.ink,
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.inventory_2_outlined,
                        color: AppColors.aqua,
                        size: 64,
                      ),
                    ),
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.ink.withValues(alpha: 0.1),
                          AppColors.ink.withValues(alpha: 0.55),
                        ],
                        stops: const [0.32, 1],
                      ),
                    ),
                  ),
                  AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) => CustomPaint(
                      painter: _ScanSweepPainter(progress: _controller.value),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.all(22),
                    child: InstrumentCorners(color: Colors.white),
                  ),
                  Positioned(
                    left: 20,
                    right: 20,
                    bottom: 20,
                    child: Row(
                      children: [
                        StatusPill(
                          label: widget.photoCount == 2
                              ? '2 angles included'
                              : '1 photo included',
                          icon: widget.photoCount == 2
                              ? Icons.compare_rounded
                              : Icons.photo_outlined,
                          background: AppColors.aqua,
                        ),
                        const Spacer(),
                        Text(
                          '${step + 1}/3',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 26),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: Text(
            labels[step],
            key: ValueKey(step),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'MassLens returns a range and confidence level so the estimate stays '
          'honest about uncertainty.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 22),
        Center(
          child: StatusPill(
            label: widget.privacyLabel,
            icon: EstimateEngineConfig.isAiEnabled
                ? Icons.cloud_upload_outlined
                : Icons.lock_outline_rounded,
          ),
        ),
      ],
    );
  }
}

class _ScanSweepPainter extends CustomPainter {
  const _ScanSweepPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..strokeWidth = 1;
    for (var index = 1; index < 6; index++) {
      final y = size.height * index / 6;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final sweepY = size.height * progress;
    final bandHeight = size.height * 0.16;
    final bandRect = Rect.fromLTRB(
      0,
      sweepY - bandHeight / 2,
      size.width,
      sweepY + bandHeight / 2,
    );
    final bandPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.transparent,
          AppColors.aqua.withValues(alpha: 0.08),
          AppColors.lime.withValues(alpha: 0.34),
          Colors.transparent,
        ],
        stops: const [0, 0.35, 0.52, 1],
      ).createShader(bandRect);
    canvas.drawRect(bandRect, bandPaint);

    final linePaint = Paint()
      ..color = AppColors.lime.withValues(alpha: 0.92)
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(16, sweepY),
      Offset(size.width - 16, sweepY),
      linePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ScanSweepPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.coral.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.coral.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline_rounded, color: AppColors.coral),
          const SizedBox(width: 10),
          Expanded(child: Text(message)),
        ],
      ),
    );
  }
}

class _CameraGridPainter extends CustomPainter {
  const _CameraGridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.055)
      ..strokeWidth = 1;
    for (var index = 1; index < 4; index++) {
      final x = size.width * index / 4;
      final y = size.height * index / 4;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    final glow = Paint()
      ..shader = RadialGradient(
        colors: [AppColors.aqua.withValues(alpha: 0.22), Colors.transparent],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Offset.zero & size, glow);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
