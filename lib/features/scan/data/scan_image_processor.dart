import 'dart:io';
import 'dart:isolate';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;

enum ScanImageWarning { dark, blurry }

enum ScanImageErrorCode { missing, corrupt, tooSmall }

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

  static const _channel = MethodChannel('com.masslens.mass_lens/scan_image');

  /// One preparation per photo: [inspect] and [prepare] share the result, so a
  /// scan no longer decodes the same photo two to four times.
  static final _cache = <String, Future<PreparedScanImage>>{};
  static const _cacheSize = 4;

  /// Dart fallback work runs one photo at a time (never concurrent isolates).
  static Future<void> _fallbackTail = Future<void>.value();

  /// Test hook: force the native (Android) path on or off.
  @visibleForTesting
  static bool? debugUseNativePath;

  @visibleForTesting
  static void debugClearCache() => _cache.clear();

  static bool get _useNativePath =>
      debugUseNativePath ?? (!kIsWeb && Platform.isAndroid);

  Future<List<ScanImageWarning>> inspect(String path) async =>
      (await prepare(path)).warnings;

  Future<PreparedScanImage> prepare(String path) {
    final cached = _cache[path];
    if (cached != null) return cached;
    if (_cache.length >= _cacheSize) _cache.remove(_cache.keys.first);
    final future = _prepareUncached(path);
    _cache[path] = future;
    future.then<void>(
      (_) {},
      onError: (Object _) {
        // Failed attempts are not cached so the user can retry.
        if (identical(_cache[path], future)) _cache.remove(path);
      },
    );
    return future;
  }

  Future<PreparedScanImage> _prepareUncached(String path) async {
    final file = File(path);
    if (!await file.exists()) {
      throw const ScanImageException(
        ScanImageErrorCode.missing,
        'The photo could not be found.',
      );
    }
    if (_useNativePath) {
      try {
        return await _prepareNative(path);
      } on MissingPluginException {
        // No native handler (e.g. plugin not registered): use the Dart path.
      }
    }
    final bytes = await file.readAsBytes();
    try {
      return await _serialized(() => Isolate.run(() => _prepareBytes(bytes)));
    } on ScanImageException {
      rethrow;
    } on Object {
      throw _corrupt;
    }
  }

  /// Android: decode, resize, re-encode and score the photo on a native worker
  /// thread. Keeping this heavy work out of the Dart isolate group avoids the
  /// main-thread ANRs (dart::IsolateGroup::IncreaseMutatorCount).
  Future<PreparedScanImage> _prepareNative(String path) async {
    final Map<String, Object?>? result;
    try {
      result = await _channel.invokeMapMethod<String, Object?>('prepare', {
        'path': path,
      });
    } on PlatformException catch (error) {
      throw switch (error.code) {
        'missing' => const ScanImageException(
          ScanImageErrorCode.missing,
          'The photo could not be found.',
        ),
        'tooSmall' => _tooSmall,
        _ => _corrupt,
      };
    }
    final outputPath = result?['path'];
    if (outputPath is! String) throw _corrupt;
    final output = File(outputPath);
    final Uint8List bytes;
    try {
      bytes = await output.readAsBytes();
    } on Object {
      throw _corrupt;
    } finally {
      try {
        await output.delete();
      } on Object {
        // Native side also cleans up stale prepared files.
      }
    }
    return PreparedScanImage(
      bytes: bytes,
      warnings: [
        if (result?['dark'] == true) ScanImageWarning.dark,
        if (result?['blurry'] == true) ScanImageWarning.blurry,
      ],
    );
  }

  static Future<T> _serialized<T>(Future<T> Function() task) {
    final run = _fallbackTail.then((_) => task());
    _fallbackTail = run.then<void>((_) {}, onError: (Object _) {});
    return run;
  }
}

const _corrupt = ScanImageException(
  ScanImageErrorCode.corrupt,
  'This photo is corrupt or unsupported. Retake it as a JPEG image.',
);

const _tooSmall = ScanImageException(
  ScanImageErrorCode.tooSmall,
  'This photo is too small. Use an image at least 320 × 320 pixels.',
);

PreparedScanImage _prepareBytes(Uint8List sourceBytes) {
  var image = img.decodeImage(sourceBytes);
  if (image == null) {
    throw const ScanImageException(
      ScanImageErrorCode.corrupt,
      'This photo is corrupt or unsupported. Retake it as a JPEG image.',
    );
  }
  image = img.bakeOrientation(image);
  if (image.width < 320 || image.height < 320) {
    throw const ScanImageException(
      ScanImageErrorCode.tooSmall,
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
  const ScanImageException(this.code, this.message);

  final ScanImageErrorCode code;
  final String message;

  @override
  String toString() => message;
}
