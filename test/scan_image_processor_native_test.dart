import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mass_lens/features/scan/data/scan_image_processor.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('com.masslens.mass_lens/scan_image');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  late Directory directory;
  late File source;

  setUp(() async {
    ScanImageProcessor.debugUseNativePath = true;
    ScanImageProcessor.debugClearCache();
    directory = await Directory.systemTemp.createTemp('scan-native-');
    source = File('${directory.path}/photo.jpg');
    await source.writeAsBytes([0xff, 0xd8, 0xff]);
  });

  tearDown(() async {
    ScanImageProcessor.debugUseNativePath = null;
    ScanImageProcessor.debugClearCache();
    messenger.setMockMethodCallHandler(channel, null);
    await directory.delete(recursive: true);
  });

  test('uses native preparation once for inspect and prepare', () async {
    var calls = 0;
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls++;
      expect(call.method, 'prepare');
      expect((call.arguments as Map)['path'], source.path);
      final output = File('${directory.path}/prepared-$calls.jpg');
      await output.writeAsBytes([1, 2, 3, 4]);
      return {
        'path': output.path,
        'width': 1024,
        'height': 768,
        'dark': true,
        'blurry': false,
      };
    });

    const processor = ScanImageProcessor();
    final warnings = await processor.inspect(source.path);
    final prepared = await processor.prepare(source.path);

    expect(calls, 1);
    expect(warnings, [ScanImageWarning.dark]);
    expect(prepared.bytes, [1, 2, 3, 4]);
    expect(prepared.mimeType, 'image/jpeg');
    expect(File('${directory.path}/prepared-1.jpg').existsSync(), isFalse);
  });

  test('maps native errors and does not cache failures', () async {
    var calls = 0;
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls++;
      throw PlatformException(code: calls == 1 ? 'tooSmall' : 'corrupt');
    });

    const processor = ScanImageProcessor();
    await expectLater(
      processor.prepare(source.path),
      throwsA(
        isA<ScanImageException>().having(
          (e) => e.code,
          'code',
          ScanImageErrorCode.tooSmall,
        ),
      ),
    );
    await expectLater(
      processor.prepare(source.path),
      throwsA(
        isA<ScanImageException>().having(
          (e) => e.code,
          'code',
          ScanImageErrorCode.corrupt,
        ),
      ),
    );
    expect(calls, 2);
  });

  test('reports a missing photo without calling native code', () async {
    var calls = 0;
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls++;
      return null;
    });

    await expectLater(
      const ScanImageProcessor().prepare('${directory.path}/nope.jpg'),
      throwsA(
        isA<ScanImageException>().having(
          (e) => e.code,
          'code',
          ScanImageErrorCode.missing,
        ),
      ),
    );
    expect(calls, 0);
  });
}
