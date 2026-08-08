import 'dart:io';
import 'dart:isolate';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as img;

enum ScanImageWarning { dark, blurry }

extension ScanImageWarningText on ScanImageWarning {
  String get message => switch (this) {
    ScanImageWarning.dark =>
      'The photo is dark. More even light will improve material recognition.',
    ScanImageWarning.blurry =>
      'The photo looks blurry. Hold the phone steady and keep the object sharp.',
  };
}

class PreparedScanImage {
  const PreparedScanImage({required this.bytes, required this.warnings});

  final Uint8List bytes;
  final List<ScanImageWarning> warnings;
  String get mimeType => 'image/jpeg';
}

class ScanImageProcessor {
  const ScanImageProcessor();

  Future<List<ScanImageWarning>> inspect(String path) async =>
      (await prepare(path)).warnings;

  Future<PreparedScanImage> prepare(String path) async {
    final file = File(path);
    if (!await file.exists()) {
      throw const ScanImageException('The photo could not be found.');
    }
    final bytes = await file.readAsBytes();
    try {
      return await Isolate.run(() => _prepareBytes(bytes));
    } on ScanImageException {
      rethrow;
    } on Object {
      throw const ScanImageException(
        'This photo is corrupt or unsupported. Retake it as a JPEG image.',
      );
    }
  }
}

PreparedScanImage _prepareBytes(Uint8List sourceBytes) {
  var image = img.decodeImage(sourceBytes);
  if (image == null) {
    throw const ScanImageException(
      'This photo is corrupt or unsupported. Retake it as a JPEG image.',
    );
  }
  image = img.bakeOrientation(image);
  if (image.width < 320 || image.height < 320) {
    throw const ScanImageException(
      'This photo is too small. Use an image at least 320 × 320 pixels.',
    );
  }

  final qualitySample = image.width > 256 || image.height > 256
      ? img.copyResize(
          image,
          width: image.width >= image.height ? 256 : null,
          height: image.height > image.width ? 256 : null,
          interpolation: img.Interpolation.average,
        )
      : image;
  final warnings = _qualityWarnings(qualitySample);

  final longestSide = math.max(image.width, image.height);
  if (longestSide > 1024) {
    image = img.copyResize(
      image,
      width: image.width >= image.height ? 1024 : null,
      height: image.height > image.width ? 1024 : null,
      interpolation: img.Interpolation.cubic,
    );
  }
  // Re-encoding removes EXIF/GPS metadata before anything is uploaded.
  return PreparedScanImage(
    bytes: Uint8List.fromList(img.encodeJpg(image, quality: 82)),
    warnings: warnings,
  );
}

List<ScanImageWarning> _qualityWarnings(img.Image image) {
  final luminance = List<double>.filled(image.width * image.height, 0);
  var total = 0.0;
  var offset = 0;
  for (final pixel in image) {
    final value =
        0.2126 * pixel.r.toDouble() +
        0.7152 * pixel.g.toDouble() +
        0.0722 * pixel.b.toDouble();
    luminance[offset++] = value;
    total += value;
  }

  final laplacians = <double>[];
  for (var y = 1; y < image.height - 1; y++) {
    for (var x = 1; x < image.width - 1; x++) {
      final center = luminance[y * image.width + x];
      laplacians.add(
        4 * center -
            luminance[y * image.width + x - 1] -
            luminance[y * image.width + x + 1] -
            luminance[(y - 1) * image.width + x] -
            luminance[(y + 1) * image.width + x],
      );
    }
  }
  final mean =
      laplacians.fold<double>(0, (sum, item) => sum + item) /
      math.max(1, laplacians.length);
  final variance =
      laplacians.fold<double>(
        0,
        (sum, item) => sum + math.pow(item - mean, 2).toDouble(),
      ) /
      math.max(1, laplacians.length);

  return [
    if (total / luminance.length < 45) ScanImageWarning.dark,
    if (variance < 55) ScanImageWarning.blurry,
  ];
}

class ScanImageException implements Exception {
  const ScanImageException(this.message);

  final String message;

  @override
  String toString() => message;
}
