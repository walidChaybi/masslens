import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/measurement.dart';

class MeasurementStore {
  const MeasurementStore();

  static const _historyKey = 'mass_lens.measurement_history.v1';
  static const _demoMigrationKey = 'mass_lens.ai_demo_history_removed.v1';

  Future<List<Measurement>> load() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final encoded = preferences.getString(_historyKey);
      final demoMigrationComplete =
          preferences.getBool(_demoMigrationKey) ?? false;
      if (encoded == null || encoded.isEmpty) {
        if (!demoMigrationComplete) {
          await preferences.setBool(_demoMigrationKey, true);
        }
        return [];
      }

      final decoded = jsonDecode(encoded) as List<dynamic>;
      final genuine = <Measurement>[];
      final oldDemoMeasurements = <Measurement>[];
      for (final item in decoded) {
        final json = Map<String, Object?>.from(item as Map);
        final measurement = Measurement.fromJson(json);
        // Historic demo records were explicitly marked. Missing flags came
        // from early demo-only releases, so remove those during this upgrade.
        if (!demoMigrationComplete && (json['isDemo'] as bool? ?? true)) {
          oldDemoMeasurements.add(measurement);
        } else {
          genuine.add(measurement);
        }
      }
      if (!demoMigrationComplete) {
        await preferences.setString(
          _historyKey,
          jsonEncode(genuine.map((item) => item.toJson()).toList()),
        );
        await preferences.setBool(_demoMigrationKey, true);
        for (final measurement in oldDemoMeasurements) {
          await deleteImage(measurement);
        }
      }
      genuine.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return genuine;
    } on Object {
      return [];
    }
  }

  Future<Measurement> persistImage(Measurement measurement) async {
    try {
      final source = File(measurement.imagePath);
      if (!await source.exists()) return measurement;

      final documents = await getApplicationDocumentsDirectory();
      final imageDirectory = Directory(
        '${documents.path}${Platform.pathSeparator}measurement_images',
      );
      await imageDirectory.create(recursive: true);

      final dotIndex = source.path.lastIndexOf('.');
      final extension = dotIndex == -1
          ? '.jpg'
          : source.path.substring(dotIndex);
      final destination = File(
        '${imageDirectory.path}${Platform.pathSeparator}'
        '${measurement.id}$extension',
      );
      if (source.absolute.path != destination.absolute.path) {
        await source.copy(destination.path);
      }
      return measurement.copyWith(imagePath: destination.path);
    } on Object {
      return measurement;
    }
  }

  Future<void> saveAll(List<Measurement> measurements) async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final encoded = jsonEncode(
        measurements.map((measurement) => measurement.toJson()).toList(),
      );
      await preferences.setString(_historyKey, encoded);
    } on Object {
      // The in-memory app remains usable if local persistence is unavailable.
    }
  }

  Future<void> deleteImage(Measurement measurement) async {
    try {
      final documents = await getApplicationDocumentsDirectory();
      final privatePrefix =
          '${documents.path}${Platform.pathSeparator}measurement_images';
      final file = File(measurement.imagePath);
      if (file.absolute.path.startsWith(privatePrefix) && await file.exists()) {
        await file.delete();
      }
    } on Object {
      // History deletion should still succeed when a stale image is missing.
    }
  }
}
