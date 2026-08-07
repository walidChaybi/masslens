import 'dart:io';

import 'package:flutter/material.dart';

import '../../features/measurements/domain/measurement.dart';
import '../theme/app_theme.dart';

class MassLensLogo extends StatelessWidget {
  const MassLensLogo({this.compact = false, super.key});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final size = compact ? 38.0 : 52.0;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: AppColors.ink,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Text(
                'M',
                style: TextStyle(
                  color: AppColors.lime,
                  fontSize: compact ? 19 : 26,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
              Positioned(
                left: 7,
                top: 7,
                child: _CornerMark(size: compact ? 7 : 9),
              ),
              Positioned(
                right: 7,
                bottom: 7,
                child: RotatedBox(
                  quarterTurns: 2,
                  child: _CornerMark(size: compact ? 7 : 9),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 11),
        Text(
          'MassLens',
          style: TextStyle(
            color: AppColors.ink,
            fontSize: compact ? 18 : 22,
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }
}

class _CornerMark extends StatelessWidget {
  const _CornerMark({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        border: Border(
          left: BorderSide(color: Colors.white, width: 1.5),
          top: BorderSide(color: Colors.white, width: 1.5),
        ),
      ),
    );
  }
}

class Eyebrow extends StatelessWidget {
  const Eyebrow(this.text, {this.color = AppColors.limeDark, super.key});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        color: color,
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 0,
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle({
    required this.title,
    this.actionLabel,
    this.onAction,
    super.key,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleLarge),
        ),
        if (actionLabel != null)
          TextButton(onPressed: onAction, child: Text(actionLabel!)),
      ],
    );
  }
}

class StatusPill extends StatelessWidget {
  const StatusPill({
    required this.label,
    this.icon,
    this.background = AppColors.navySoft,
    this.foreground = AppColors.ink,
    super.key,
  });

  final String label;
  final IconData? icon;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: foreground),
            const SizedBox(width: 5),
          ],
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: foreground,
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

class MeasurementCard extends StatelessWidget {
  const MeasurementCard({
    required this.measurement,
    required this.unitSystem,
    this.onTap,
    this.compact = false,
    super.key,
  });

  final Measurement measurement;
  final UnitSystem unitSystem;
  final VoidCallback? onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final imageFile = File(measurement.imagePath);
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(compact ? 12 : 14),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: SizedBox(
                  width: compact ? 64 : 76,
                  height: compact ? 64 : 76,
                  child: imageFile.existsSync()
                      ? Image.file(imageFile, fit: BoxFit.cover)
                      : Container(
                          color: AppColors.navySoft,
                          child: const Icon(
                            Icons.inventory_2_outlined,
                            color: AppColors.inkMuted,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      measurement.objectLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formatMeasurementDate(measurement.createdAt),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    if (!compact) ...[
                      const SizedBox(height: 8),
                      ConfidenceBadge(level: measurement.confidence),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    formatWeight(measurement.estimateGrams, unitSystem),
                    style: const TextStyle(
                      color: AppColors.ink,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.inkMuted,
                    size: 22,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ConfidenceBadge extends StatelessWidget {
  const ConfidenceBadge({required this.level, super.key});

  final ConfidenceLevel level;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (level) {
      ConfidenceLevel.low => ('Low confidence', AppColors.coral),
      ConfidenceLevel.medium => ('Medium confidence', AppColors.limeDark),
      ConfidenceLevel.high => ('High confidence', const Color(0xFF168B78)),
    };
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class EmptyPanel extends StatelessWidget {
  const EmptyPanel({
    required this.icon,
    required this.title,
    required this.message,
    this.action,
    super.key,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(26, 32, 26, 28),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.navySoft,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.ink),
          ),
          const SizedBox(height: 16),
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 7),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (action != null) ...[const SizedBox(height: 20), action!],
        ],
      ),
    );
  }
}

class InstrumentCorners extends StatelessWidget {
  const InstrumentCorners({this.color = AppColors.lime, super.key});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _InstrumentCornersPainter(color),
        size: Size.infinite,
      ),
    );
  }
}

class _InstrumentCornersPainter extends CustomPainter {
  const _InstrumentCornersPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    const inset = 18.0;
    const length = 32.0;

    final path = Path()
      ..moveTo(inset, inset + length)
      ..lineTo(inset, inset)
      ..lineTo(inset + length, inset)
      ..moveTo(size.width - inset - length, inset)
      ..lineTo(size.width - inset, inset)
      ..lineTo(size.width - inset, inset + length)
      ..moveTo(inset, size.height - inset - length)
      ..lineTo(inset, size.height - inset)
      ..lineTo(inset + length, size.height - inset)
      ..moveTo(size.width - inset - length, size.height - inset)
      ..lineTo(size.width - inset, size.height - inset)
      ..lineTo(size.width - inset, size.height - inset - length);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _InstrumentCornersPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
