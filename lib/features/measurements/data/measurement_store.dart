import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/measurement.dart';

class MeasurementStore {
  const MeasurementStore();

  static const _historyKey = 'mass_lens.measurement_history.v1';

  Future<List<Measurement>> load() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final encoded = preferences.getString(_historyKey);
      if (encoded == null || encoded.isEmpty) return [];

      final decoded = jsonDecode(encoded) as List<dynamic>;
      return decoded
          .map(
            (item) =>
                Measurement.fromJson(Map<String, Object?>.from(item as Map)),
          )
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
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
