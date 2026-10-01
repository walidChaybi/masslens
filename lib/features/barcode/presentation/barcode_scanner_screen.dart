import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/theme/app_theme.dart';
import '../../../l10n/l10n.dart';
import '../domain/food_product.dart';

/// Opens the camera barcode scanner. Resolves to a normalized barcode, or
/// null when the user backs out. Scanning is free and uses no scan credit.
Future<String?> scanFoodBarcode(BuildContext context) {
  return Navigator.of(context).push<String>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => const BarcodeScannerScreen(),
    ),
  );
}

class BarcodeScannerScreen extends StatefulWidget {
  const BarcodeScannerScreen({super.key});

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    formats: const [
      BarcodeFormat.ean13,
      BarcodeFormat.ean8,
      BarcodeFormat.upcA,
      BarcodeFormat.upcE,
    ],
  );
  bool _finished = false;
  bool _torchOn = false;

  @override
  void dispose() {
    unawaited(_controller.dispose());
    super.dispose();
  }

  void _handleDetect(BarcodeCapture capture) {
    if (_finished) return;
    for (final barcode in capture.barcodes) {
      final normalized = normalizeBarcode(barcode.rawValue ?? '');
      if (normalized == null) continue;
      _finish(normalized);
      return;
    }
  }

  void _finish(String barcode) {
    if (_finished || !mounted) return;
    _finished = true;
    unawaited(HapticFeedback.mediumImpact());
    Navigator.of(context).pop(barcode);
  }

  Future<void> _typeNumber() async {
    unawaited(_controller.stop());
    final code = await showBarcodeNumberDialog(context);
    if (!mounted) return;
    if (code != null) {
      _finish(code);
    } else {
      unawaited(_controller.start());
    }
  }

  Future<void> _toggleTorch() async {
    try {
      await _controller.toggleTorch();
      if (mounted) setState(() => _torchOn = !_torchOn);
    } on Object {
      // Devices without a flash simply keep the torch off.
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      key: const Key('barcode_scanner_screen'),
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(l10n.barcodeScanAction),
        actions: [
          IconButton(
            key: const Key('barcode_torch'),
            tooltip: l10n.barcodeTorch,
            onPressed: _toggleTorch,
            icon: Icon(
              _torchOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
            ),
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(controller: _controller, onDetect: _handleDetect),
          const IgnorePointer(child: _ScanFrame()),
          Positioned(
            left: 20,
            right: 20,
            bottom: 24,
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n.barcodeScannerHint,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      shadows: [Shadow(blurRadius: 8)],
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    key: const Key('barcode_type_number'),
                    onPressed: _typeNumber,
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: context.palette.ink,
                      minimumSize: const Size.fromHeight(52),
                      shape: const StadiumBorder(),
                    ),
                    icon: const Icon(Icons.dialpad_rounded),
                    label: Text(l10n.barcodeTypeNumber),
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

class _ScanFrame extends StatelessWidget {
  const _ScanFrame();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = (constraints.maxWidth * 0.78).clamp(220.0, 420.0);
        return Center(
          child: Container(
            width: width,
            height: width * 0.55,
            decoration: BoxDecoration(
              border: Border.all(color: context.palette.lime, width: 3),
              borderRadius: BorderRadius.circular(18),
            ),
          ),
        );
      },
    );
  }
}

/// Lets the user type the digits under the barcode when the camera cannot
/// read it. Resolves to a normalized barcode or null.
Future<String?> showBarcodeNumberDialog(BuildContext context) {
  return showDialog<String>(
    context: context,
    builder: (_) => const _BarcodeNumberDialog(),
  );
}

class _BarcodeNumberDialog extends StatefulWidget {
  const _BarcodeNumberDialog();

  @override
  State<_BarcodeNumberDialog> createState() => _BarcodeNumberDialogState();
}

class _BarcodeNumberDialogState extends State<_BarcodeNumberDialog> {
  final _textController = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _submit() {
    final code = normalizeBarcode(_textController.text);
    if (code == null) {
      setState(() => _error = context.l10n.barcodeInvalid);
      return;
    }
    Navigator.of(context).pop(code);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      title: Text(l10n.barcodeEnterTitle),
      content: TextField(
        key: const Key('barcode_number_field'),
        controller: _textController,
        autofocus: true,
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(14),
        ],
        onSubmitted: (_) => _submit(),
        decoration: InputDecoration(
          border: const OutlineInputBorder(),
          hintText: '3017620422003',
          errorText: _error,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.commonCancel),
        ),
        FilledButton(
          key: const Key('barcode_number_submit'),
          onPressed: _submit,
          child: Text(l10n.commonOk),
        ),
      ],
    );
  }
}
