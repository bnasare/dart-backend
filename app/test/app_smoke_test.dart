import 'dart:convert';

import 'package:dart_backend_tech_test/app.dart';
import 'package:dart_backend_tech_test/core/config/app_config.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

void main() {
  const config = AppConfig(
    port: 8080,
    apiKeys: <String>[
      'key_sandbox',
      'key_standard',
      'key_enhanced',
      'key_enterprise',
    ],
    rateLimitMax: 60,
    rateLimitWindowSec: 60,
    databasePath: 'data/test_smoke.sqlite',
  );

  final runtime = createAppRuntime(config: config);
  final handler = runtime.handler;

  tearDownAll(() async {
    await runtime.close();
  });

  group('createHandler', () {
    test('returns health response without authentication', () async {
      final response = await handler(
        Request('GET', Uri.parse('http://localhost/health')),
      );

      expect(response.statusCode, 200);
      expect(jsonDecode(await response.readAsString()), <String, Object?>{
        'status': 'ok',
      });
    });

    test('returns json error envelope for unauthorized routes', () async {
      final response = await handler(
        Request('GET', Uri.parse('http://localhost/v1/feature-flags')),
      );

      final payload =
          jsonDecode(await response.readAsString()) as Map<String, Object?>;

      expect(response.statusCode, 401);
      expect(payload['error'], isA<Map<String, Object?>>());
      expect(
        (payload['error'] as Map<String, Object?>)['code'],
        'unauthorized',
      );
    });

    test('returns json not found envelope for unknown routes', () async {
      final response = await handler(
        Request('GET', Uri.parse('http://localhost/unknown')),
      );

      final payload =
          jsonDecode(await response.readAsString()) as Map<String, Object?>;

      expect(response.statusCode, 404);
      expect((payload['error'] as Map<String, Object?>)['code'], 'not_found');
    });

    test('serves openapi spec without authentication', () async {
      final response = await handler(
        Request('GET', Uri.parse('http://localhost/openapi.yaml')),
      );

      final body = await response.readAsString();
      expect(response.statusCode, 200);
      expect(response.headers['content-type'], contains('application/yaml'));
      expect(body, contains('openapi: 3.0.3'));
      expect(body, contains('/v1/notes'));
    });

    test('serves swagger docs page without authentication', () async {
      final response = await handler(
        Request('GET', Uri.parse('http://localhost/docs')),
      );

      final body = await response.readAsString();
      expect(response.statusCode, 200);
      expect(response.headers['content-type'], contains('text/html'));
      expect(body, contains('SwaggerUIBundle'));
      expect(body, contains('/openapi.yaml'));
    });
  });
}
