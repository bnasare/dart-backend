import 'dart:convert';

import 'package:dart_backend_tech_test/app.dart';
import 'package:dart_backend_tech_test/core/config/app_config.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

void main() {
  group('rate limiting', () {
    test('enforces max requests and returns Retry-After', () async {
      final runtime = _buildRuntime(rateLimitMax: 2, rateLimitWindowSec: 60);
      addTearDown(() => runtime.close());
      final handler = runtime.handler;

      final first = await _sendRequest(handler: handler, apiKey: 'key_sandbox');
      expect(first.statusCode, 200);
      expect(first.headers['X-RateLimit-Remaining'], '1');

      final second =
          await _sendRequest(handler: handler, apiKey: 'key_sandbox');
      expect(second.statusCode, 200);
      expect(second.headers['X-RateLimit-Remaining'], '0');

      final third = await _sendRequest(handler: handler, apiKey: 'key_sandbox');
      expect(third.statusCode, 429);
      expect(_errorCode(third.jsonBody), 'rate_limit_exceeded');
      expect(third.headers['X-RateLimit-Remaining'], '0');
      final retryAfter = int.tryParse(third.headers['Retry-After'] ?? '');
      expect(retryAfter, isNotNull);
      expect(retryAfter, inInclusiveRange(0, 60));
    });

    test('tracks usage independently per API key', () async {
      final runtime = _buildRuntime(rateLimitMax: 1, rateLimitWindowSec: 60);
      addTearDown(() => runtime.close());
      final handler = runtime.handler;

      final sandboxFirst = await _sendRequest(
        handler: handler,
        apiKey: 'key_sandbox',
      );
      expect(sandboxFirst.statusCode, 200);

      final sandboxSecond = await _sendRequest(
        handler: handler,
        apiKey: 'key_sandbox',
      );
      expect(sandboxSecond.statusCode, 429);

      final standardRequest = await _sendRequest(
        handler: handler,
        apiKey: 'key_standard',
      );
      expect(standardRequest.statusCode, 200);
    });
  });
}

AppRuntime _buildRuntime({
  required int rateLimitMax,
  required int rateLimitWindowSec,
}) {
  final uniqueDbPath =
      'data/test_rate_limit_${DateTime.now().microsecondsSinceEpoch}.sqlite';

  final config = AppConfig(
    port: 8080,
    apiKeys: const <String>[
      'key_sandbox',
      'key_standard',
      'key_enhanced',
      'key_enterprise',
    ],
    rateLimitMax: rateLimitMax,
    rateLimitWindowSec: rateLimitWindowSec,
    databasePath: uniqueDbPath,
  );

  return createAppRuntime(config: config);
}

Future<_ResponseData> _sendRequest({
  required Handler handler,
  required String apiKey,
}) async {
  final request = Request(
    'GET',
    Uri.parse('http://localhost/v1/feature-flags'),
    headers: <String, String>{'X-API-Key': apiKey},
  );

  final response = await handler(request);
  final body = await response.readAsString();
  final jsonBody = body.isEmpty
      ? <String, Object?>{}
      : jsonDecode(body) as Map<String, Object?>;

  return _ResponseData(
    statusCode: response.statusCode,
    jsonBody: jsonBody,
    headers: response.headers,
  );
}

String _errorCode(Map<String, Object?> payload) {
  final error = payload['error']! as Map<String, Object?>;
  return error['code']! as String;
}

class _ResponseData {
  const _ResponseData({
    required this.statusCode,
    required this.jsonBody,
    required this.headers,
  });

  final int statusCode;
  final Map<String, Object?> jsonBody;
  final Map<String, String> headers;
}
