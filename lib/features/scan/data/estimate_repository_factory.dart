import '../domain/estimate_repository.dart';
import 'cloudflare_estimate_repository.dart';
import 'demo_estimate_repository.dart';

abstract final class EstimateEngineConfig {
  static const estimateEngine = String.fromEnvironment(
    'ESTIMATE_ENGINE',
    defaultValue: 'demo',
  );
  static const cloudflareApiUrl = String.fromEnvironment('MASSLENS_API_URL');
  static const cloudModelLabel = String.fromEnvironment(
    'CLOUD_MODEL_LABEL',
    defaultValue: 'gpt-5.4-mini',
  );

  static bool get isCloudflareEnabled => estimateEngine == 'cloudflare';
  static bool get isAiEnabled => isCloudflareEnabled;

  static String get analysisModeLabel {
    if (isCloudflareEnabled) return 'Secure cloud AI';
    return 'Local demo';
  }

  static String get cloudUploadLabel {
    if (isCloudflareEnabled) return 'Via secure API';
    return 'Off';
  }

  static String get productionModelLabel {
    if (isCloudflareEnabled) return cloudModelLabel;
    return 'Not connected';
  }

  static String get reviewFootnote {
    if (isCloudflareEnabled) return 'AI mode · Photo sent via secure API';
    return 'Demo mode · No image leaves this device';
  }

  static String get analysisPrivacyLabel =>
      isAiEnabled ? 'Photo upload enabled' : 'Image stays on device';
}

EstimateRepository buildEstimateRepository() {
  if (EstimateEngineConfig.isCloudflareEnabled) {
    return CloudflareEstimateRepository(
      apiUrl: EstimateEngineConfig.cloudflareApiUrl,
    );
  }

  return const DemoEstimateRepository();
}
