import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as image_library;
import 'package:mass_lens/features/scan/data/scan_image_processor.dart';

void main() {
  test('normalizes a large photo to metadata-free bounded JPEG', () async {
    final directory = await Directory.systemTemp.createTemp('scan-image-');
    addTearDown(() => directory.delete(recursive: true));
    final source = image_library.Image(width: 1200, height: 600);
    for (var y = 0; y < source.height; y++) {
      for (var x = 0; x < source.width; x++) {
        source.setPixelRgb(x, y, (x + y) % 255, 180, 220);
      }
    }
    final file = File('${directory.path}/large.png');
    await file.writeAsBytes(image_library.encodePng(source));

    final prepared = await const ScanImageProcessor().prepare(file.path);
    final decoded = image_library.decodeJpg(prepared.bytes);
    expect(prepared.mimeType, 'image/jpeg');
    expect(decoded, isNotNull);
    expect(decoded!.width, 1024);
    expect(decoded.height, 512);
  });

  test('warns before upload when a photo is dark and blurry', () async {
    final directory = await Directory.systemTemp.createTemp('scan-image-');
    addTearDown(() => directory.delete(recursive: true));
    final image = image_library.Image(width: 400, height: 400)
      ..clear(image_library.ColorRgb8(10, 10, 10));
    final file = File('${directory.path}/dark.jpg');
    await file.writeAsBytes(image_library.encodeJpg(image));

    final warnings = await const ScanImageProcessor().inspect(file.path);
    expect(warnings, contains(ScanImageWarning.dark));
    expect(warnings, contains(ScanImageWarning.blurry));
  });

  test('rejects corrupt and undersized photos', () async {
    final directory = await Directory.systemTemp.createTemp('scan-image-');
    addTearDown(() => directory.delete(recursive: true));
    final corrupt = File('${directory.path}/corrupt.jpg');
    await corrupt.writeAsBytes([1, 2, 3]);
    final small = File('${directory.path}/small.jpg');
    await small.writeAsBytes(
      image_library.encodeJpg(image_library.Image(width: 200, height: 200)),
    );

    expect(
      () => const ScanImageProcessor().prepare(corrupt.path),
      throwsA(isA<ScanImageException>()),
    );
    expect(
      () => const ScanImageProcessor().prepare(small.path),
      throwsA(isA<ScanImageException>()),
    );
  });
}
