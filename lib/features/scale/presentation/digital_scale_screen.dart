import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../monetization/presentation/native_ad_card.dart';

import '../../../app/app_controller.dart';
import '../../../core/theme/app_theme.dart';
import '../../measurements/domain/measurement.dart';
import '../data/standard_ble_scale_reader.dart';
import '../domain/scale_device.dart';
import '../domain/scale_reader.dart';
import '../domain/scale_reading.dart';
import '../domain/touch_pressure_demo.dart';

enum _ScaleMode { touchDemo, bluetooth }

class DigitalScaleScreen extends StatefulWidget {
  const DigitalScaleScreen({
    required this.onOpenAiScan,
    this.onOpenMenu,
    this.reader,
    super.key,
  });

  final VoidCallback onOpenAiScan;
  final VoidCallback? onOpenMenu;
  final ScaleReader? reader;

  @override
  State<DigitalScaleScreen> createState() => _DigitalScaleScreenState();
}

class _DigitalScaleScreenState extends State<DigitalScaleScreen> {
  late final ScaleReader _reader;
  late final bool _ownsReader;
  late ScaleReaderSnapshot _readerSnapshot;
  late List<ScaleDevice> _devices;
  StreamSubscription<ScaleReaderSnapshot>? _stateSubscription;
  StreamSubscription<List<ScaleDevice>>? _deviceSubscription;
  StreamSubscription<ScaleReading>? _readingSubscription;
  StreamSubscription<Object>? _errorSubscription;

  _ScaleMode _mode = _ScaleMode.touchDemo;
  ScaleReading? _latestReading;
  double _touchTargetPressure = 0;
  double _displayedTouchPressure = 0;
  double _tareOffsetGrams = 0;
  bool _fingerDown = false;
  bool _hasScanned = false;
  bool _showBluetoothPanel = false;
  String? _localError;
  Timer? _pressureTimer;

  @override
  void initState() {
    super.initState();
    _ownsReader = widget.reader == null;
    _reader = widget.reader ?? StandardBleScaleReader();
    _readerSnapshot = _reader.snapshot;
    _devices = _reader.knownDevices;
    _stateSubscription = _reader.states.listen((snapshot) {
      if (!mounted) return;
      setState(() => _readerSnapshot = snapshot);
    });
    _deviceSubscription = _reader.devices.listen((devices) {
      if (!mounted) return;
      setState(() => _devices = devices);
    });
    _readingSubscription = _reader.readings.listen((reading) {
      if (!mounted || reading.weightGrams == null) return;
      setState(() {
        _latestReading = reading;
        _localError = null;
      });
    });
    _errorSubscription = _reader.errors.cast<Object>().listen((error) {
      if (!mounted) return;
      setState(() => _localError = _friendlyError(error));
    });
  }

  @override
  void dispose() {
    unawaited(_stateSubscription?.cancel());
    unawaited(_deviceSubscription?.cancel());
    unawaited(_readingSubscription?.cancel());
    unawaited(_errorSubscription?.cancel());
    _pressureTimer?.cancel();
    if (_ownsReader) unawaited(_reader.dispose());
    super.dispose();
  }

  Future<void> _startScan() async {
    setState(() {
      _mode = _ScaleMode.bluetooth;
      _hasScanned = true;
      _localError = null;
    });
    try {
      await _reader.startScan(timeout: const Duration(seconds: 12));
    } on Object catch (error) {
      if (!mounted) return;
      setState(() => _localError = _friendlyError(error));
    }
  }

  Future<void> _connect(ScaleDevice device) async {
    setState(() => _localError = null);
    try {
      await _reader.connect(device);
      if (!mounted) return;
      setState(() => _tareOffsetGrams = 0);
    } on Object catch (error) {
      if (!mounted) return;
      setState(() => _localError = _friendlyError(error));
    }
  }

  Future<void> _disconnect() async {
    try {
      await _reader.disconnect();
    } on Object catch (error) {
      if (!mounted) return;
      setState(() => _localError = _friendlyError(error));
    }
    if (!mounted) return;
    setState(() {
      _latestReading = null;
      _tareOffsetGrams = 0;
    });
  }

  void _updateTouchPressure(PointerEvent event) {
    if (_mode != _ScaleMode.touchDemo) return;
    final normalized = TouchPressureDemo.normalize(
      pressure: event.pressure,
      minimum: event.pressureMin,
      maximum: event.pressureMax,
    );
    // Most phones report no touch pressure at all, which would leave the demo
    // stuck at zero — fall back to a simulated press so the scale visibly
    // "weighs" the touch.
    final pressure = normalized > 0
        ? normalized
        : TouchPressureDemo.simulatedPressStrength;
    setState(() {
      _fingerDown = true;
      _touchTargetPressure = pressure;
      if (pressure < _displayedTouchPressure) {
        _displayedTouchPressure = pressure;
      }
    });
    _startPressureRamp();
  }

  void _releaseTouch() {
    if (_mode != _ScaleMode.touchDemo) return;
    _pressureTimer?.cancel();
    setState(() {
      _fingerDown = false;
      _touchTargetPressure = 0;
    });
    final releaseStart = _displayedTouchPressure;
    const tick = Duration(milliseconds: 25);
    var elapsedMs = 0;
    _pressureTimer = Timer.periodic(tick, (timer) {
      if (!mounted || _fingerDown) {
        timer.cancel();
        return;
      }
      elapsedMs += tick.inMilliseconds;
      final progress = (elapsedMs / 300).clamp(0.0, 1.0);
      final eased = 1 - math.pow(1 - progress, 3).toDouble();
      setState(() => _displayedTouchPressure = releaseStart * (1 - eased));
      if (progress >= 1) {
        timer.cancel();
        setState(() => _displayedTouchPressure = 0);
      }
    });
  }

  void _startPressureRamp() {
    if (_pressureTimer?.isActive ?? false) return;
    // A real consumer scale needs time to load, overshoot, and settle. Keep the
    // curve deterministic so the simulator is believable and testable.
    const tick = Duration(milliseconds: 50);
    final startPressure = _displayedTouchPressure;
    var elapsedMs = 0;
    _pressureTimer = Timer.periodic(tick, (timer) {
      if (!mounted || !_fingerDown) {
        timer.cancel();
        return;
      }
      elapsedMs += tick.inMilliseconds;
      setState(() {
        final seconds = elapsedMs / 1000;
        if (seconds >= 2.35) {
          _displayedTouchPressure = _touchTargetPressure;
          timer.cancel();
          return;
        }
        final target = _touchTargetPressure;
        if (seconds <= 1.45) {
          final t = (seconds / 1.45).clamp(0.0, 1.0);
          final smoothStep = t * t * (3 - 2 * t);
          _displayedTouchPressure =
              startPressure + (target - startPressure) * smoothStep;
          return;
        }
        final settlingTime = seconds - 1.45;
        final overshoot =
            target *
            0.018 *
            math.exp(-3.4 * settlingTime) *
            math.sin(10.5 * settlingTime);
        final resolutionJitter =
            target *
            0.00025 *
            math.sin(elapsedMs / tick.inMilliseconds * 2.1) *
            (1 - settlingTime / 0.9).clamp(0.0, 1.0);
        _displayedTouchPressure = (target + overshoot + resolutionJitter)
            .clamp(0.0, target * 1.02)
            .toDouble();
      });
    });
  }

  void _tareScale(double rawGrams) {
    if (rawGrams <= 0) return;
    setState(() => _tareOffsetGrams = rawGrams);
  }

  void _activateTouchMode() {
    _pressureTimer?.cancel();
    setState(() {
      _mode = _ScaleMode.touchDemo;
      _showBluetoothPanel = false;
      _fingerDown = false;
      _touchTargetPressure = 0;
      _displayedTouchPressure = 0;
      _tareOffsetGrams = 0;
    });
  }

  void _openBluetoothPanel() {
    _pressureTimer?.cancel();
    setState(() {
      _mode = _ScaleMode.bluetooth;
      _showBluetoothPanel = true;
      _fingerDown = false;
      _touchTargetPressure = 0;
      _displayedTouchPressure = 0;
      _tareOffsetGrams = 0;
    });
  }

  void _toggleBluetoothPanel() {
    if (_mode == _ScaleMode.bluetooth && _showBluetoothPanel) {
      _activateTouchMode();
    } else {
      _openBluetoothPanel();
    }
  }

  void _closeBluetoothPanel() {
    if (_readerSnapshot.phase == ScaleReaderPhase.connected) {
      setState(() => _showBluetoothPanel = false);
    } else {
      _activateTouchMode();
    }
  }

  void _toggleUnits() {
    final controller = AppScope.of(context);
    final next = controller.unitSystem == UnitSystem.metric
        ? UnitSystem.imperial
        : UnitSystem.metric;
    unawaited(controller.setUnitSystem(next));
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final bluetoothConnected =
        _readerSnapshot.phase == ScaleReaderPhase.connected;
    final rawGrams = _mode == _ScaleMode.touchDemo
        ? _displayedTouchPressure * TouchPressureDemo.maximumDemoGrams
        : _latestReading?.weightGrams ?? 0;
    final adjustedGrams = rawGrams > _tareOffsetGrams
        ? rawGrams - _tareOffsetGrams
        : 0.0;
    final display = _formatScaleWeight(adjustedGrams, controller.unitSystem);

    return Material(
      key: const Key('digital_scale_screen'),
      color: const Color(0xFFE0E5ED),
      child: Stack(
        children: [
          const Positioned.fill(child: _ScaleStageBackground()),
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                _ScaleTopBar(
                  onOpenMenu: widget.onOpenMenu,
                  onOpenAiScan: widget.onOpenAiScan,
                  onOpenBluetooth: _toggleBluetoothPanel,
                  bluetoothConnected: bluetoothConnected,
                ),
                Expanded(
                  child: _ScaleReadout(
                    mode: _mode,
                    value: display.value,
                    unit: display.unit,
                    normalizedPressure: _displayedTouchPressure,
                    fingerDown: _fingerDown,
                    bluetoothConnected: bluetoothConnected,
                    onPointerDown: _updateTouchPressure,
                    onPointerMove: _updateTouchPressure,
                    onPointerUp: _releaseTouch,
                    onPointerCancel: _releaseTouch,
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(28, 4, 28, 4),
                  child: _ScaleBottomControls(
                    unitLabel: controller.unitSystem == UnitSystem.metric
                        ? 'UNIT'
                        : 'LB/OZ',
                    tareEnabled: rawGrams > 0,
                    onUnit: _toggleUnits,
                    onTare: () => _tareScale(rawGrams),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    6,
                    16,
                    MediaQuery.viewPaddingOf(context).bottom + 12,
                  ),
                  child: NativeAdCard(
                    enabled: controller.monetization.canRequestNativeAds,
                    placement: 'scale_first_screen',
                    height: 100,
                    onPaidEvent: controller.monetization.reportPaidAd,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: MediaQuery.viewPaddingOf(context).bottom + 18,
            child: AnimatedSlide(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              offset: _showBluetoothPanel ? Offset.zero : const Offset(0, 1.15),
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 180),
                opacity: _showBluetoothPanel ? 1 : 0,
                child: IgnorePointer(
                  ignoring: !_showBluetoothPanel,
                  child: _BluetoothOverlay(
                    onClose: _closeBluetoothPanel,
                    child: _BluetoothPanel(
                      snapshot: _readerSnapshot,
                      devices: _devices,
                      hasScanned: _hasScanned,
                      localError: _localError,
                      onScan: _startScan,
                      onConnect: _connect,
                      onDisconnect: _disconnect,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _friendlyError(Object error) {
    final message = error.toString().replaceFirst(
      RegExp(r'^.*Exception:\s*'),
      '',
    );
    if (message.toLowerCase().contains('permission')) {
      return 'Nearby devices permission is required to find a scale.';
    }
    if (message.toLowerCase().contains('powered')) {
      return 'Turn on Bluetooth, then search again.';
    }
    return message.isEmpty ? 'Could not communicate with this scale.' : message;
  }
}

({String value, String unit}) _formatScaleWeight(
  double grams,
  UnitSystem unitSystem,
) {
  if (unitSystem == UnitSystem.imperial) {
    final ounces = grams / 28.349523125;
    if (ounces < 16) {
      return (value: ounces.toStringAsFixed(2), unit: 'oz');
    }
    return (value: (ounces / 16).toStringAsFixed(3), unit: 'lb');
  }
  if (grams < 1000) {
    return (
      value: grams < 10 ? grams.toStringAsFixed(1) : grams.toStringAsFixed(0),
      unit: 'g',
    );
  }
  return (value: (grams / 1000).toStringAsFixed(3), unit: 'kg');
}

class _ScaleReadout extends StatelessWidget {
  const _ScaleReadout({
    required this.mode,
    required this.value,
    required this.unit,
    required this.normalizedPressure,
    required this.fingerDown,
    required this.bluetoothConnected,
    required this.onPointerDown,
    required this.onPointerMove,
    required this.onPointerUp,
    required this.onPointerCancel,
  });

  final _ScaleMode mode;
  final String value;
  final String unit;
  final double normalizedPressure;
  final bool fingerDown;
  final bool bluetoothConnected;
  final void Function(PointerEvent) onPointerDown;
  final void Function(PointerEvent) onPointerMove;
  final VoidCallback onPointerUp;
  final VoidCallback onPointerCancel;

  @override
  Widget build(BuildContext context) {
    final isDemo = mode == _ScaleMode.touchDemo;
    final status = isDemo
        ? 'SIMULATOR · NOT A MEASUREMENT'
        : bluetoothConnected
        ? 'LIVE · BLUETOOTH SCALE'
        : 'BLUETOOTH · NOT CONNECTED';

    return Semantics(
      label: isDemo
          ? 'Touch scale simulator, not a physical measurement'
          : bluetoothConnected
          ? 'Live Bluetooth scale reading'
          : 'Bluetooth scale disconnected',
      value: '$value $unit',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final height = constraints.maxHeight.isFinite
              ? constraints.maxHeight
              : 560.0;
          final displayWidth = math
              .min(constraints.maxWidth * 0.78, 340.0)
              .toDouble();
          final displayHeight = displayWidth * 0.38;
          final touchAreaHeight = math
              .max(100.0, math.min(200.0, (height - displayHeight) * 0.50))
              .toDouble();

          // The whole readout area acts as the weighing surface: pressing
          // anywhere on it (including the LCD) registers a touch, like
          // placing an object on the phone.
          return Listener(
            key: const Key('scale_touch_surface'),
            behavior: HitTestBehavior.opaque,
            onPointerDown: isDemo ? onPointerDown : null,
            onPointerMove: isDemo ? onPointerMove : null,
            onPointerUp: isDemo ? (_) => onPointerUp() : null,
            onPointerCancel: isDemo ? (_) => onPointerCancel() : null,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Touch area — the top gray zone where users press.
                SizedBox(
                  width: double.infinity,
                  height: touchAreaHeight,
                  child: Center(
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 160),
                      opacity: isDemo && !fingerDown ? 0.94 : 0.38,
                      child: Icon(
                        isDemo
                            ? Icons.touch_app_rounded
                            : bluetoothConnected
                            ? Icons.bluetooth_connected_rounded
                            : Icons.bluetooth_disabled_rounded,
                        color: Colors.white,
                        size: math.min(86, touchAreaHeight * 0.45).toDouble(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Rectangular LCD-style digital display.
                _DigitalDisplay(
                  width: displayWidth,
                  height: displayHeight,
                  value: value,
                  unit: unit,
                  normalizedPressure: normalizedPressure,
                  fingerDown: fingerDown,
                  bluetoothConnected: bluetoothConnected,
                ),
                const SizedBox(height: 14),
                Text(
                  status,
                  style: TextStyle(
                    color: AppColors.ink.withValues(alpha: 0.62),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.15,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _DigitalDisplay extends StatelessWidget {
  const _DigitalDisplay({
    required this.width,
    required this.height,
    required this.value,
    required this.unit,
    required this.normalizedPressure,
    required this.fingerDown,
    required this.bluetoothConnected,
  });

  final double width;
  final double height;
  final String value;
  final String unit;
  final double normalizedPressure;
  final bool fingerDown;
  final bool bluetoothConnected;

  @override
  Widget build(BuildContext context) {
    final pressure = normalizedPressure.clamp(0.0, 1.0).toDouble();
    final glow = bluetoothConnected ? 0.28 : pressure * 0.40;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: const Color(0xFF1A1F2B),
        border: Border.all(color: const Color(0xFF3A4050), width: 2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0B2A34).withValues(alpha: 0.20 + glow),
            blurRadius: 20 + (pressure * 24),
            spreadRadius: 1 + (pressure * 4),
          ),
          const BoxShadow(
            color: Color(0xFF0D1117),
            blurRadius: 1,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Stack(
        children: [
          // Subtle inner bevel / screen bezel.
          Positioned.fill(
            child: Container(
              margin: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF0F1318), Color(0xFF161C26)],
                ),
              ),
            ),
          ),
          // Weight value + unit.
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.bottomRight,
                      child: Text(
                        value,
                        maxLines: 1,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontFamilyFallback: const ['Courier'],
                          color: const Color(0xFF4AE68A),
                          fontSize: height * 0.48,
                          height: 1.0,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 2.0,
                          shadows: [
                            Shadow(
                              color: const Color(
                                0xFF4AE68A,
                              ).withValues(alpha: 0.45),
                              blurRadius: 12,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    unit,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontFamilyFallback: const ['Courier'],
                      color: const Color(0xFF4AE68A).withValues(alpha: 0.70),
                      fontSize: height * 0.22,
                      height: 1.0,
                      fontWeight: FontWeight.w500,
                      shadows: [
                        Shadow(
                          color: const Color(
                            0xFF4AE68A,
                          ).withValues(alpha: 0.30),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScaleStageBackground extends StatelessWidget {
  const _ScaleStageBackground();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _ScaleStagePainter());
  }
}

class _ScaleStagePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final topPaint = Paint()..color = const Color(0xFFE0E5ED);
    canvas.drawRect(Offset.zero & size, topPaint);

    final lowerPath = Path()
      ..moveTo(0, size.height * 0.58)
      ..lineTo(size.width * 0.5, size.height * 0.68)
      ..lineTo(size.width, size.height * 0.58)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(lowerPath, Paint()..color = const Color(0xFFF8FDFE));

    final rimPaint = Paint()
      ..color = AppColors.ink
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    final rimPath = Path()
      ..moveTo(-2, size.height * 0.58)
      ..lineTo(size.width * 0.5, size.height * 0.68)
      ..lineTo(size.width + 2, size.height * 0.58);
    canvas.drawPath(rimPath, rimPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ScaleTopBar extends StatelessWidget {
  const _ScaleTopBar({
    required this.onOpenMenu,
    required this.onOpenAiScan,
    required this.onOpenBluetooth,
    required this.bluetoothConnected,
  });

  final VoidCallback? onOpenMenu;
  final VoidCallback onOpenAiScan;
  final VoidCallback onOpenBluetooth;
  final bool bluetoothConnected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 4),
      child: Row(
        children: [
          _TopIconButton(
            key: const Key('open_navigation'),
            tooltip: 'Open navigation menu',
            icon: Icons.menu_rounded,
            onPressed: onOpenMenu,
          ),
          const Spacer(),
          _TopIconButton(
            key: const Key('open_ai_scan_button'),
            tooltip: 'AI weight scan',
            icon: Icons.center_focus_strong_rounded,
            onPressed: onOpenAiScan,
          ),
          const SizedBox(width: 18),
          _TopIconButton(
            key: const Key('open_bluetooth_panel'),
            tooltip: 'Bluetooth scale',
            icon: bluetoothConnected
                ? Icons.bluetooth_connected_rounded
                : Icons.bluetooth_disabled_rounded,
            onPressed: onOpenBluetooth,
          ),
        ],
      ),
    );
  }
}

class _TopIconButton extends StatelessWidget {
  const _TopIconButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
    super.key,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon),
      color: AppColors.ink,
      disabledColor: AppColors.ink.withValues(alpha: 0.32),
      iconSize: 36,
      style: IconButton.styleFrom(
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        minimumSize: const Size.square(50),
      ),
    );
  }
}

class _ScaleBottomControls extends StatelessWidget {
  const _ScaleBottomControls({
    required this.unitLabel,
    required this.tareEnabled,
    required this.onUnit,
    required this.onTare,
  });

  final String unitLabel;
  final bool tareEnabled;
  final VoidCallback onUnit;
  final VoidCallback onTare;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _RoundScaleButton(
          key: const Key('scale_unit_button'),
          label: unitLabel,
          size: 80,
          onPressed: onUnit,
        ),
        _RoundScaleButton(
          key: const Key('scale_tare_button'),
          label: 'TARE',
          size: 80,
          onPressed: tareEnabled ? onTare : null,
        ),
      ],
    );
  }
}

class _RoundScaleButton extends StatelessWidget {
  const _RoundScaleButton({
    required this.label,
    required this.onPressed,
    this.size = 96,
    super.key,
  });

  final String label;
  final double size;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.ink.withValues(alpha: 0.19),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            shape: const CircleBorder(),
            padding: EdgeInsets.zero,
            backgroundColor: const Color(0xFFF8FDFE),
            foregroundColor: AppColors.ink,
            disabledForegroundColor: AppColors.ink.withValues(alpha: 0.32),
            side: BorderSide(color: AppColors.ink.withValues(alpha: 0.55)),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: size * 0.26,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BluetoothOverlay extends StatelessWidget {
  const _BluetoothOverlay({required this.onClose, required this.child});

  final VoidCallback onClose;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.62,
      ),
      child: Material(
        color: Colors.transparent,
        child: SingleChildScrollView(
          child: Stack(
            children: [
              Padding(padding: const EdgeInsets.only(top: 10), child: child),
              Positioned(
                top: 0,
                right: 8,
                child: IconButton.filled(
                  tooltip: 'Close Bluetooth panel',
                  onPressed: onClose,
                  icon: const Icon(Icons.close_rounded),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.ink,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BluetoothPanel extends StatelessWidget {
  const _BluetoothPanel({
    required this.snapshot,
    required this.devices,
    required this.hasScanned,
    required this.localError,
    required this.onScan,
    required this.onConnect,
    required this.onDisconnect,
  });

  final ScaleReaderSnapshot snapshot;
  final List<ScaleDevice> devices;
  final bool hasScanned;
  final String? localError;
  final Future<void> Function() onScan;
  final Future<void> Function(ScaleDevice) onConnect;
  final Future<void> Function() onDisconnect;

  bool get _busy => {
    ScaleReaderPhase.requestingPermission,
    ScaleReaderPhase.scanning,
    ScaleReaderPhase.connecting,
    ScaleReaderPhase.discovering,
    ScaleReaderPhase.subscribing,
    ScaleReaderPhase.disconnecting,
  }.contains(snapshot.phase);

  @override
  Widget build(BuildContext context) {
    final connected = snapshot.phase == ScaleReaderPhase.connected;
    final message = localError ?? snapshot.message;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _NoticeIcon(
                icon: connected
                    ? Icons.bluetooth_connected_rounded
                    : Icons.bluetooth_searching_rounded,
                color: connected ? AppColors.aqua : AppColors.lime,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      connected
                          ? snapshot.connectedDevice?.displayName ??
                                'Bluetooth scale'
                          : _phaseLabel(snapshot.phase),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      connected
                          ? 'Receiving standard Weight Scale measurements'
                          : 'Supports BLE Weight Scale Service (0x181D)',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              if (_busy)
                const SizedBox.square(
                  dimension: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
            ],
          ),
          if (message != null && message.isNotEmpty) ...[
            const SizedBox(height: 13),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: localError != null
                    ? AppColors.coral.withValues(alpha: 0.1)
                    : AppColors.navySoft,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                message,
                style: TextStyle(
                  color: localError != null
                      ? const Color(0xFF9B3B31)
                      : AppColors.inkMuted,
                  fontSize: 12.5,
                  height: 1.4,
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          if (connected)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                key: const Key('disconnect_scale_button'),
                onPressed: _busy ? null : onDisconnect,
                icon: const Icon(Icons.link_off_rounded),
                label: const Text('Disconnect scale'),
              ),
            )
          else ...[
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                key: const Key('search_scales_button'),
                onPressed: _busy ? null : onScan,
                icon: const Icon(Icons.bluetooth_searching_rounded),
                label: Text(
                  snapshot.phase == ScaleReaderPhase.scanning
                      ? 'Searching…'
                      : 'Find compatible scales',
                ),
              ),
            ),
            if (devices.isNotEmpty) ...[
              const SizedBox(height: 18),
              Text(
                'AVAILABLE SCALES',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.inkMuted,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 8),
              for (final device in devices)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Material(
                    color: AppColors.navySoft,
                    borderRadius: BorderRadius.circular(16),
                    child: ListTile(
                      key: Key('scale_device_${device.id}'),
                      minTileHeight: 60,
                      leading: const Icon(Icons.scale_outlined),
                      title: Text(device.displayName),
                      subtitle: Text(
                        device.rssi == null
                            ? 'Compatible scale'
                            : 'Signal ${device.rssi} dBm',
                      ),
                      trailing: const Icon(Icons.arrow_forward_rounded),
                      onTap: _busy ? null : () => onConnect(device),
                    ),
                  ),
                ),
            ] else if (hasScanned && !_busy) ...[
              const SizedBox(height: 14),
              const Text(
                'No standard scale found. Make sure the scale is awake and '
                'not connected to another app, then try again.',
                style: TextStyle(
                  color: AppColors.inkMuted,
                  fontSize: 12.5,
                  height: 1.45,
                ),
              ),
            ],
          ],
          const SizedBox(height: 12),
          const Text(
            'Many kitchen scales use private manufacturer protocols. Those '
            'need a model-specific integration even if they appear in phone '
            'Bluetooth settings.',
            style: TextStyle(
              color: AppColors.inkMuted,
              fontSize: 11.5,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

String _phaseLabel(ScaleReaderPhase phase) => switch (phase) {
  ScaleReaderPhase.idle => 'No scale connected',
  ScaleReaderPhase.requestingPermission => 'Requesting permission',
  ScaleReaderPhase.scanning => 'Searching nearby',
  ScaleReaderPhase.connecting => 'Connecting',
  ScaleReaderPhase.discovering => 'Checking compatibility',
  ScaleReaderPhase.subscribing => 'Starting live readings',
  ScaleReaderPhase.connected => 'Scale connected',
  ScaleReaderPhase.disconnecting => 'Disconnecting',
  ScaleReaderPhase.unavailable => 'Bluetooth unavailable',
  ScaleReaderPhase.error => 'Connection needs attention',
  ScaleReaderPhase.disposed => 'Reader closed',
};

class _NoticeIcon extends StatelessWidget {
  const _NoticeIcon({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icon, color: AppColors.ink, size: 22),
    );
  }
}
