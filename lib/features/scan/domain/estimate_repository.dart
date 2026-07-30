import '../../measurements/domain/measurement.dart';

class EstimateRequest {
  const EstimateRequest({
    required this.imagePath,
    required this.category,
    required this.structure,
  });

  final String imagePath;
  final String category;
  final String structure;
}

abstract interface class EstimateRepository {
  Future<Measurement> analyze(EstimateRequest request);
}
