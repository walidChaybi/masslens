import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as image_library;
import 'package:mass_lens/features/scan/data/cloudflare_estimate_repository.dart';
import 'package:mass_lens/features/scan/domain/estimate_repository.dart';
import 'package:mass_lens/features/scan/domain/measured_dimensions.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('Cloudflare request includes serialized measured dimensions', () async {
    SharedPreferences.setMockInitialValues({});
    final directory = await Directory.systemTemp.createTemp('masslens-test-');
    final image = File('${directory.path}/object.jpg');
    await image.writeAsBytes(
      image_library.encodeJpg(image_library.Image(width: 320, height: 320)),
    );
    final received = Completer<Map<String, Object?>>();
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) async {
      final body = jsonDecode(await utf8.decodeStream(request)) as Map;
      received.complete(Map<String, Object?>.from(body));
      request.response.headers.contentType = ContentType.json;
      request.response.write(
        jsonEncode({
          'object_label': 'Measured parcel',
          'category': 'Parcel',
          'estimate_grams': 1250,
          'lower_bound_grams': 950,
          'upper_bound_grams': 1550,
          'confidence': 'medium',
          'dimensions_mm': {'width': 999, 'height': 999, 'depth': 180},
          'assumptions': ['Material inferred from image'],
        }),
      );
      await request.response.close();
    });

    try {
      final repository = CloudflareEstimateRepository(
        apiUrl: 'http://127.0.0.1:${server.port}/estimate',
      );
      await repository.analyze(
        EstimateRequest(
          imagePath: image.path,
          requestId: 'request_identifier_flutter_test',
          measuredDimensions: const MeasuredDimensions(
            widthMm: 320,
            heightMm: 210,
            method: MeasurementMethod.arCorePlane,
          ),
        ),
      );

      final body = await received.future;
      expect(body['measuredDimensions'], {
        'widthMm': 320.0,
        'heightMm': 210.0,
        'method': 'arcore_plane',
      });
      expect((body['images'] as List), hasLength(1));
    } finally {
      await server.close(force: true);
      await directory.delete(recursive: true);
    }
  });
}
