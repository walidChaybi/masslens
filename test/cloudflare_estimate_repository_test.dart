import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as image_library;
import 'package:mass_lens/features/measurements/domain/measurement.dart';
import 'package:mass_lens/features/scan/data/cloudflare_estimate_repository.dart';
import 'package:mass_lens/features/scan/domain/estimate_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('Cloudflare request sends photo views and compact hints only', () async {
    SharedPreferences.setMockInitialValues({});
    final directory = await Directory.systemTemp.createTemp('masslens-test-');
    final image = File('${directory.path}/object.jpg');
    await image.writeAsBytes(
      image_library.encodeJpg(image_library.Image(width: 320, height: 320)),
    );
    final sideImage = File('${directory.path}/object-side.jpg');
    await sideImage.writeAsBytes(
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
      final measurement = await repository.analyze(
        EstimateRequest(
          imagePath: image.path,
          secondaryImagePath: sideImage.path,
          requestId: 'request_identifier_flutter_test',
          material: 'Metal',
          responseLocale: 'fr',
          knownDimension: const KnownDimensionInput(
            axis: 'Length',
            value: 32,
            unit: 'cm',
          ),
        ),
      );

      final body = await received.future;
      expect(body.containsKey('measuredDimensions'), isFalse);
      expect(body['knownDimension'], {
        'axis': 'Length',
        'value': 32,
        'unit': 'cm',
      });
      expect(body['material'], 'Metal');
      expect(body['scanMode'], 'object');
      expect(body.containsKey('containerType'), isFalse);
      expect(body['responseLocale'], 'fr');
      expect((body['images'] as List), hasLength(2));
      expect(measurement.analysisLocale, 'fr');
    } finally {
      await server.close(force: true);
      await directory.delete(recursive: true);
    }
  });

  test(
    'food request sends mode and container and maps food response',
    () async {
      SharedPreferences.setMockInitialValues({});
      final directory = await Directory.systemTemp.createTemp('masslens-food-');
      final image = File('${directory.path}/meal.jpg');
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
            'meal_label': 'Pasta dinner',
            'confidence': 'high',
            'items': [
              {
                'label': 'Cooked pasta',
                'estimate_grams': 250,
                'lower_bound_grams': 200,
                'upper_bound_grams': 300,
                'confidence': 'high',
                'nutrition': {
                  'fdc_id': 168927,
                  'description': 'Pasta, cooked',
                  'data_type': 'SR Legacy',
                  'calories_kcal_per_100g': 158,
                  'protein_grams_per_100g': 5.8,
                  'carbs_grams_per_100g': 30.9,
                  'fat_grams_per_100g': 0.9,
                },
              },
            ],
            'assumptions': [
              'Standard plate',
              'Pasta is cooked',
              'No hidden food',
            ],
          }),
        );
        await request.response.close();
      });

      try {
        final repository = CloudflareEstimateRepository(
          apiUrl: 'http://127.0.0.1:${server.port}/estimate',
        );
        final measurement = await repository.analyze(
          EstimateRequest(
            imagePath: image.path,
            requestId: 'food_request_identifier_flutter_test',
            scanMode: ScanMode.foodPlate,
            containerType: 'Dinner plate',
            knownDimension: const KnownDimensionInput(
              axis: 'Diameter',
              value: 26,
              unit: 'cm',
            ),
          ),
        );

        final body = await received.future;
        expect(body['scanMode'], 'food_plate');
        expect(body['containerType'], 'Dinner plate');
        expect(body['knownDimension'], {
          'axis': 'Diameter',
          'value': 26,
          'unit': 'cm',
        });
        expect(measurement.scanMode, ScanMode.foodPlate);
        expect(measurement.mealLabel, 'Pasta dinner');
        expect(measurement.nutritionTotals.caloriesKcal, 395);
      } finally {
        await server.close(force: true);
        await directory.delete(recursive: true);
      }
    },
  );
}
