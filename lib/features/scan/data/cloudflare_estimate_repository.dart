import 'dart:convert';
import 'dart:io';

import '../../../core/services/installation_id_store.dart';
import '../../measurements/domain/measurement.dart';
import '../domain/estimate_repository.dart';
import 'ai_estimate_payload.dart';
import 'scan_image_processor.dart';

class CloudflareEstimateRepository implements EstimateRepository {
  CloudflareEstimateRepository({
    required this.apiUrl,
    this.timeout = const Duration(seconds: 60),
    this.imageProcessor = const ScanImageProcessor(),
  });

  final String apiUrl;
  final Duration timeout;
  final ScanImageProcessor imageProcessor;

  @override
  Future<Measurement> analyze(EstimateRequest request) async {
    final uri = _validatedApiUri();
    final imagePaths = [request.imagePath, ?request.secondaryImagePath];
    final images = <Map<String, String>>[];
    for (final imagePath in imagePaths) {
      final prepared = await imageProcessor.prepare(imagePath);
      images.add({
        'imageBase64': base64Encode(prepared.bytes),
        'mimeType': prepared.mimeType,
      });
    }

    final payload = await _postJson(
      uri,
      {
        'images': images,
        'material': request.material,
        'fillState': request.fillState,
        'referenceObject': request.referenceObject,
        if (request.knownDimension case final knownDimension?)
          'knownDimension': knownDimension.toJson(),
      },
      clientId: await InstallationIdStore.getOrCreate(),
      requestId: request.requestId.isEmpty
          ? ScanRequestId.create()
          : request.requestId,
    );

    return measurementFromAiEstimatePayload(payload, request.imagePath);
  }

  Uri _validatedApiUri() {
    if (apiUrl.trim().isEmpty) {
      throw const CloudflareEstimateException(
        'MASSLENS_API_URL is not configured.',
      );
    }

    final uri = Uri.tryParse(apiUrl.trim());
    final isLocalhost = uri?.host == 'localhost' || uri?.host == '127.0.0.1';
    if (uri == null ||
        !uri.hasAuthority ||
        (uri.scheme != 'https' && !(uri.scheme == 'http' && isLocalhost))) {
      throw const CloudflareEstimateException(
        'MASSLENS_API_URL must be an HTTPS URL.',
      );
    }
    return uri;
  }

  Future<Map<String, Object?>> _postJson(
    Uri uri,
    Map<String, Object?> body, {
    required String clientId,
    required String requestId,
  }) async {
    final client = HttpClient()..connectionTimeout = timeout;
    try {
      final request = await client.postUrl(uri).timeout(timeout);
      request.headers
        ..set(HttpHeaders.contentTypeHeader, ContentType.json.mimeType)
        ..set('X-MassLens-Client-ID', clientId)
        ..set('X-MassLens-Request-ID', requestId);
      request.write(jsonEncode(body));

      final response = await request.close().timeout(timeout);
      final responseText = await utf8.decodeStream(response).timeout(timeout);
      Object? decoded;
      try {
        decoded = jsonDecode(responseText);
      } on FormatException {
        throw CloudflareEstimateException(
          'Cloud AI returned invalid data (${response.statusCode}).',
        );
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        final message = decoded is Map
            ? _errorMessage(Map<String, Object?>.from(decoded))
            : 'Cloud AI request failed.';
        throw CloudflareEstimateException(
          'Cloud AI request failed (${response.statusCode}): $message',
          statusCode: response.statusCode,
          code: decoded is Map
              ? _errorCode(Map<String, Object?>.from(decoded))
              : null,
        );
      }

      return mapFromUnknownPayload(decoded);
    } on CloudflareEstimateException {
      rethrow;
    } on Object catch (error) {
      throw CloudflareEstimateException('Cloud AI request failed: $error');
    } finally {
      client.close(force: true);
    }
  }

  static String _errorMessage(Map<String, Object?> decoded) {
    final error = decoded['error'];
    if (error is Map) {
      final message = error['message'];
      if (message is String && message.trim().isNotEmpty) {
        return message.trim();
      }
    }
    return 'No error message was returned.';
  }

  static String? _errorCode(Map<String, Object?> decoded) {
    final error = decoded['error'];
    if (error is Map && error['code'] is String) {
      return error['code'] as String;
    }
    return null;
  }
}

class CloudflareEstimateException implements Exception {
  const CloudflareEstimateException(this.message, {this.statusCode, this.code});

  final String message;
  final int? statusCode;
  final String? code;

  bool get isScanLimitReached =>
      statusCode == 402 || code == 'scan_limit_reached';

  @override
  String toString() => message;
}
