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
    rateLimitMax: 1000,
    rateLimitWindowSec: 60,
    databasePath: 'data/test_auth.sqlite',
  );

  final runtime = createAppRuntime(config: config);
  final handler = runtime.handler;

  tearDownAll(() async {
    await runtime.close();
  });

  group('auth middleware', () {
    test('returns 401 for missing API key on protected route', () async {
      final response = await _sendRequest(
        handler: handler,
        method: 'GET',
        path: '/v1/feature-flags',
      );

      expect(response.statusCode, 401);
      expect(_errorCode(response.jsonBody), 'unauthorized');
    });

    test('returns 401 for invalid API key', () async {
      final response = await _sendRequest(
        handler: handler,
        method: 'GET',
        path: '/v1/feature-flags',
        apiKey: 'wrong-key',
      );

      expect(response.statusCode, 401);
      expect(_errorCode(response.jsonBody), 'unauthorized');
    });
  });

  group('feature flags tiers', () {
    test('returns Sandbox flags', () async {
      final response = await _sendRequest(
        handler: handler,
        method: 'GET',
        path: '/v1/feature-flags',
        apiKey: 'key_sandbox',
      );

      expect(response.statusCode, 200);
      expect(response.jsonBody['tier'], 'Sandbox');
      final features = response.jsonBody['features']! as Map<String, Object?>;
      expect(features['oauth'], false);
      expect(features['advancedReports'], false);
    });

    test('returns Standard flags', () async {
      final response = await _sendRequest(
        handler: handler,
        method: 'GET',
        path: '/v1/feature-flags',
        apiKey: 'key_standard',
      );

      expect(response.statusCode, 200);
      expect(response.jsonBody['tier'], 'Standard');
      final features = response.jsonBody['features']! as Map<String, Object?>;
      expect(features['oauth'], true);
      expect(features['advancedReports'], false);
    });

    test('returns Enhanced flags', () async {
      final response = await _sendRequest(
        handler: handler,
        method: 'GET',
        path: '/v1/feature-flags',
        apiKey: 'key_enhanced',
      );

      expect(response.statusCode, 200);
      expect(response.jsonBody['tier'], 'Enhanced');
      final features = response.jsonBody['features']! as Map<String, Object?>;
      expect(features['oauth'], true);
      expect(features['advancedReports'], true);
    });

    test('returns Enterprise flags', () async {
      final response = await _sendRequest(
        handler: handler,
        method: 'GET',
        path: '/v1/feature-flags',
        apiKey: 'key_enterprise',
      );

      expect(response.statusCode, 200);
      expect(response.jsonBody['tier'], 'Enterprise');
      final features = response.jsonBody['features']! as Map<String, Object?>;
      expect(features['oauth'], true);
      expect(features['advancedReports'], true);
      expect(features['ssoSaml'], true);
    });
  });
}

Future<_ResponseData> _sendRequest({
  required Handler handler,
  required String method,
  required String path,
  String? apiKey,
}) async {
  final request = Request(
    method,
    Uri.parse('http://localhost$path'),
    headers: <String, String>{if (apiKey != null) 'X-API-Key': apiKey},
  );

  final response = await handler(request);
  final body = await response.readAsString();
  final jsonBody = body.isEmpty
      ? <String, Object?>{}
      : jsonDecode(body) as Map<String, Object?>;

  return _ResponseData(statusCode: response.statusCode, jsonBody: jsonBody);
}

String _errorCode(Map<String, Object?> payload) {
  final error = payload['error']! as Map<String, Object?>;
  return error['code']! as String;
}

class _ResponseData {
  const _ResponseData({required this.statusCode, required this.jsonBody});

  final int statusCode;
  final Map<String, Object?> jsonBody;
}
