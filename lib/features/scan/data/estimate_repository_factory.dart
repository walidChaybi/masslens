import '../domain/estimate_repository.dart';
import 'cloudflare_estimate_repository.dart';

abstract final class EstimateEngineConfig {
  static const cloudflareApiUrl = String.fromEnvironment(
    'MASSLENS_API_URL',
    defaultValue: 'https://masslens-api.masslens.workers.dev/estimate',
  );
  static const cloudModelLabel = String.fromEnvironment(
    'CLOUD_MODEL_LABEL',
    defaultValue: 'gpt-5-nano',
  );

  static bool get isAiEnabled => true;

  static String get analysisModeLabel => 'Secure cloud AI';

  static String get cloudUploadLabel => 'Via secure API';

  static String get productionModelLabel => cloudModelLabel;

  static String get reviewFootnote => 'AI analysis · Secure photo upload';

  static String get analysisPrivacyLabel => 'Photo upload enabled';
}

EstimateRepository buildEstimateRepository() =>
    CloudflareEstimateRepository(apiUrl: EstimateEngineConfig.cloudflareApiUrl);
