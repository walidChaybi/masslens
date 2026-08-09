import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mass_lens/features/monetization/data/monetization_api.dart';
import 'package:mass_lens/features/monetization/domain/reward_attempt.dart';

void main() {
  test(
    'reward attempt API sends the agreed IDs, event, and owner header',
    () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      final received =
          <({String method, String path, String clientId, String body})>[];
      server.listen((request) async {
        final body = await utf8.decoder.bind(request).join();
        received.add((
          method: request.method,
          path: request.uri.path,
          clientId: request.headers.value('X-MassLens-Client-ID') ?? '',
          body: body,
        ));
        final requestBody = body.isEmpty
            ? null
            : jsonDecode(body) as Map<String, Object?>;
        final attemptId = request.uri.pathSegments.length == 2
            ? request.uri.pathSegments.last
            : requestBody!['attemptId'] as String;
        final now = DateTime.utc(2026, 8, 8, 12).millisecondsSinceEpoch;
        request.response
          ..statusCode = request.method == 'POST'
              ? HttpStatus.created
              : HttpStatus.ok
          ..headers.contentType = ContentType.json
          ..write(
            jsonEncode({
              'attemptId': attemptId,
              'state': requestBody?['event'] == 'client_earned'
                  ? 'verified'
                  : 'pending',
              'createdAtMs': now,
              'updatedAtMs': now,
              'expiresAtMs': now + const Duration(hours: 24).inMilliseconds,
            }),
          );
        await request.response.close();
      });
      addTearDown(() => server.close(force: true));

      const attemptId = 'abcdefghijklmnopqrstuvwx';
      const clientId = 'install-owner-id';
      final api = MonetizationApi(
        apiUrl: 'http://${server.address.host}:${server.port}',
      );

      await api.recordRewardAttempt(
        clientId: clientId,
        attemptId: attemptId,
        event: RewardAttemptEvent.started,
      );
      final credited = await api.recordRewardAttempt(
        clientId: clientId,
        attemptId: attemptId,
        event: RewardAttemptEvent.clientEarned,
      );
      await api.getRewardAttempt(clientId: clientId, attemptId: attemptId);

      expect(credited.state, RewardAttemptServerState.verified);
      expect(received, hasLength(3));
      expect(received[0].method, 'POST');
      expect(received[0].path, '/reward-attempts');
      expect(received[0].clientId, clientId);
      expect(jsonDecode(received[0].body), {
        'attemptId': attemptId,
        'event': 'started',
      });
      expect(jsonDecode(received[1].body), {
        'attemptId': attemptId,
        'event': 'client_earned',
      });
      expect(received[2].method, 'GET');
      expect(received[2].path, '/reward-attempts/$attemptId');
      expect(received[2].clientId, clientId);
    },
  );
}
