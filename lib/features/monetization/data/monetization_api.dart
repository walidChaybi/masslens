import 'dart:convert';
import 'dart:io';

import '../domain/access_status.dart';

class MonetizationApi {
  const MonetizationApi({
    required this.apiUrl,
    this.timeout = const Duration(seconds: 20),
  });

  final String apiUrl;
  final Duration timeout;

  Future<AccessStatus> getAccess(String clientId) async {
    final payload = await _request('GET', '/access', clientId: clientId);
    return AccessStatus.fromJson(payload);
  }

  Future<AccessStatus> verifyPurchase({
    required String clientId,
    required String productId,
    required String purchaseToken,
  }) async {
    final payload = await _request(
      'POST',
      '/billing/verify',
      clientId: clientId,
      body: {'productId': productId, 'purchaseToken': purchaseToken},
    );
    return AccessStatus.fromJson(payload);
  }

  Uri _endpoint(String path) {
    final configured = Uri.tryParse(apiUrl.trim());
    if (configured == null || !configured.hasAuthority) {
      throw const MonetizationApiException(
        'The MassLens billing service is not configured.',
      );
    }
    return configured.replace(path: path, query: null, fragment: null);
  }

  Future<Map<String, Object?>> _request(
    String method,
    String path, {
    required String clientId,
    Map<String, Object?>? body,
  }) async {
    final client = HttpClient()..connectionTimeout = timeout;
    try {
      final uri = _endpoint(path);
      final request = method == 'POST'
          ? await client.postUrl(uri).timeout(timeout)
          : await client.getUrl(uri).timeout(timeout);
      request.headers
        ..set(HttpHeaders.acceptHeader, ContentType.json.mimeType)
        ..set('X-MassLens-Client-ID', clientId);
      if (body != null) {
        request.headers.contentType = ContentType.json;
        request.write(jsonEncode(body));
      }
      final response = await request.close().timeout(timeout);
      final text = await utf8.decodeStream(response).timeout(timeout);
      final decoded = jsonDecode(text);
      if (decoded is! Map) {
        throw const MonetizationApiException(
          'The billing service returned invalid data.',
        );
      }
      final map = Map<String, Object?>.from(decoded);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        final error = map['error'];
        final message = error is Map && error['message'] is String
            ? error['message'] as String
            : 'The billing request failed.';
        throw MonetizationApiException(
          message,
          statusCode: response.statusCode,
        );
      }
      return map;
    } on MonetizationApiException {
      rethrow;
    } on Object catch (error) {
      throw MonetizationApiException('Could not reach billing: $error');
    } finally {
      client.close(force: true);
    }
  }
}

class MonetizationApiException implements Exception {
  const MonetizationApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}
