import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../l10n/l10n.dart';

class NutritionScanCta extends StatelessWidget {
  const NutritionScanCta({
    required this.onScan,
    required this.onGallery,
    this.onBarcode,
    super.key,
  });

  final VoidCallback onScan;
  final VoidCallback onGallery;

  /// Free packaged-food logging; hidden when null.
  final VoidCallback? onBarcode;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton.icon(
          key: const Key('nutrition_scan_meal'),
          onPressed: onScan,
          style: FilledButton.styleFrom(
            backgroundColor: context.palette.lime,
            foregroundColor: context.palette.onLime,
            minimumSize: const Size.fromHeight(56),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: const StadiumBorder(),
            textStyle: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          icon: const Icon(Icons.photo_camera_rounded),
          label: Text(l10n.nutritionScanAMeal),
        ),
        if (onBarcode case final onBarcode?) ...[
          const SizedBox(height: 10),
          OutlinedButton(
            key: const Key('nutrition_scan_barcode'),
            onPressed: onBarcode,
            style: OutlinedButton.styleFrom(
              foregroundColor: context.palette.ink,
              minimumSize: const Size.fromHeight(52),
              shape: const StadiumBorder(),
              side: BorderSide(color: context.palette.ink, width: 1.4),
              textStyle: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 15,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.qr_code_scanner_rounded, size: 20),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    l10n.barcodeScanAction,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: context.palette.limeLight,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    l10n.barcodeFreeBadge,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: context.palette.limeDark,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 8),
        TextButton.icon(
          key: const Key('nutrition_open_gallery'),
          onPressed: onGallery,
          style: TextButton.styleFrom(
            foregroundColor: context.palette.inkMuted,
          ),
          icon: const Icon(Icons.photo_library_outlined),
          label: Text(l10n.nutritionOpenGallery),
        ),
      ],
    );
  }
}
