import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

import '../../../app/app_controller.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_components.dart';
import '../../measurements/domain/measurement.dart';
import '../../measurements/presentation/measurement_detail_screen.dart';
import '../data/demo_estimate_repository.dart';
import '../data/photo_picker.dart';
import '../domain/estimate_repository.dart';

class ScanScreen extends StatefulWidget {
  ScanScreen({
    EstimateRepository? estimateRepository,
    PhotoPicker? photoPicker,
    super.key,
  }) : estimateRepository =
           estimateRepository ?? const DemoEstimateRepository(),
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
  String _category = 'Auto';
  String _structure = 'Unknown';
  bool _isPicking = false;
  bool _isAnalyzing = false;
  int _analysisStep = 0;
  Measurement? _result;
  String? _error;
  bool _saved = false;
  int _analysisRun = 0;

  Future<void> _pick(PhotoSource source) async {
    if (_isPicking) return;
    setState(() {
      _isPicking = true;
      _error = null;
    });
    try {
      final path = await widget.photoPicker.pick(source);
      if (!mounted || path == null) return;
      setState(() {
        _imagePath = path;
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
        _error = 'Analysis stopped unexpectedly. Your photo is still here.';
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
              : 'Review photo',
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
                step: _analysisStep,
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
                    label: 'Object centered',
                    icon: Icons.check_rounded,
                    background: AppColors.lime.withValues(alpha: 0.92),
                  ),
                ),
              ],
            ),
          ),
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
        const Text(
          'Demo mode · No image leaves this device',
          textAlign: TextAlign.center,
          style: TextStyle(
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

class _AnalysisView extends StatelessWidget {
  const _AnalysisView({required this.imagePath, required this.step, super.key});

  final String imagePath;
  final int step;

  @override
  Widget build(BuildContext context) {
    const labels = [
      'Checking photo quality',
      'Identifying object and material',
      'Calculating a plausible range',
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 34),
      child: Column(
        children: [
          const Spacer(),
          SizedBox(
            width: 210,
            height: 210,
            child: Stack(
              fit: StackFit.expand,
              children: [
                ClipOval(
                  child: Image.file(
                    File(imagePath),
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      color: AppColors.navySoft,
                      child: const Icon(Icons.inventory_2_outlined, size: 64),
                    ),
                  ),
                ),
                CircularProgressIndicator(
                  value: (step + 1) / 3,
                  strokeWidth: 8,
                  strokeCap: StrokeCap.round,
                  color: AppColors.lime,
                  backgroundColor: AppColors.line,
                ),
                Center(
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      color: AppColors.ink,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.auto_awesome_rounded,
                      color: AppColors.lime,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 34),
          const Eyebrow('Demo analysis in progress'),
          const SizedBox(height: 10),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: Text(
              labels[step.clamp(0, labels.length - 1)],
              key: ValueKey(step),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'The production build will combine visual understanding with '
            'geometry and density priors.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const Spacer(),
          const StatusPill(
            label: 'Image stays on device',
            icon: Icons.lock_outline_rounded,
          ),
        ],
      ),
    );
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
