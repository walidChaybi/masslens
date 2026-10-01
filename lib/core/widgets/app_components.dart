import 'dart:io';

import 'package:flutter/material.dart';

import '../../features/measurements/domain/measurement.dart';
import '../../l10n/display_labels.dart';
import '../../l10n/l10n.dart';
import '../theme/app_theme.dart';

class MassLensLogo extends StatelessWidget {
  const MassLensLogo({
    this.compact = false,
    this.showWordmark = true,
    this.markSize,
    super.key,
  });

  final bool compact;

  /// Hide the "MassLens" text to keep only the square mark (app bars).
  final bool showWordmark;

  /// Optional explicit mark size; defaults to 38 (compact) or 52.
  final double? markSize;

  @override
  Widget build(BuildContext context) {
    final size = markSize ?? (compact ? 38.0 : 52.0);
    final corner = size < 44 ? 7.0 : 9.0;
    final inset = size < 36 ? 5.0 : 7.0;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: AppColors.ink,
            borderRadius: BorderRadius.circular(size * 0.26),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Text(
                'M',
                style: TextStyle(
                  color: AppColors.lime,
                  fontSize: size * 0.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
              Positioned(
                left: inset,
                top: inset,
                child: _CornerMark(size: corner),
              ),
              Positioned(
                right: inset,
                bottom: inset,
                child: RotatedBox(
                  quarterTurns: 2,
                  child: _CornerMark(size: corner),
                ),
              ),
            ],
          ),
        ),
        if (showWordmark) ...[
          SizedBox(width: compact ? 9 : 11),
          Flexible(
            child: Text(
              'MassLens',
              maxLines: 1,
              overflow: TextOverflow.fade,
              softWrap: false,
              style: TextStyle(
                color: context.palette.ink,
                fontSize: compact ? 18 : 22,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
              ),
            ),
          ),
        ],
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
  const Eyebrow(this.text, {this.color, super.key});

  final String text;

  /// Defaults to the palette's lime accent.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        color: color ?? context.palette.limeDark,
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.2,
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
    this.background,
    this.foreground,
    super.key,
  });

  final String label;
  final IconData? icon;

  /// Both default to the palette's neutral pill colours.
  final Color? background;
  final Color? foreground;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final background = this.background ?? palette.navySoft;
    final foreground = this.foreground ?? palette.ink;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
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
              fontSize: 10,
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
    final l10n = context.l10n;
    final localeName = Localizations.localeOf(context).toLanguageTag();
    final weightParts = formatWeight(
      measurement.estimateGrams,
      unitSystem,
      localeName: localeName,
    ).split(' ');
    final weightNumber = weightParts[0];
    final weightUnit = weightParts.length > 1 ? weightParts[1] : '';

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: compact ? 64 : 76,
                  height: compact ? 64 : 76,
                  child: imageFile.existsSync()
                      ? Image.file(imageFile, fit: BoxFit.cover)
                      : Container(
                          color: context.palette.navySoft,
                          child: Icon(
                            Icons.inventory_2_outlined,
                            color: context.palette.inkMuted,
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
                      formatMeasurementDate(
                        measurement.createdAt,
                        localeName: localeName,
                        todayLabel: l10n.measurementToday,
                        yesterdayLabel: l10n.measurementYesterday,
                      ),
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
                    weightNumber,
                    style: TextStyle(
                      color: context.palette.ink,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (weightUnit.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: context.palette.limeLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        weightUnit,
                        style: TextStyle(
                          color: context.palette.ink,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
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
    final color = switch (level) {
      ConfidenceLevel.low => context.palette.coral,
      ConfidenceLevel.medium => context.palette.limeDark,
      ConfidenceLevel.high => context.palette.success,
    };
    final label = localizedConfidence(
      context.l10n,
      level,
      includeConfidence: true,
    );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
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
      ),
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
        color: context.palette.surface,
        border: Border.all(color: context.palette.line),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [context.palette.limeLight, context.palette.navySoft],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: context.palette.ink),
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
  const InstrumentCorners({this.color, super.key});

  /// Defaults to the palette's lime accent.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _InstrumentCornersPainter(color ?? context.palette.lime),
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
