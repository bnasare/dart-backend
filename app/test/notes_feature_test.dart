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
    databasePath: 'data/test_notes.sqlite',
  );

  final runtime = createAppRuntime(config: config);
  final handler = runtime.handler;

  tearDownAll(() async {
    await runtime.close();
  });

  group('notes feature', () {
    test('creates and fetches a note', () async {
      final createResponse = await _sendRequest(
        handler: handler,
        method: 'POST',
        path: '/v1/notes',
        body: <String, Object?>{'title': 'First note', 'content': 'Hello'},
      );

      expect(createResponse.statusCode, 201);
      final createPayload = createResponse.jsonBody;
      expect(createPayload['id'], isA<String>());
      expect(createPayload['title'], 'First note');
      expect(createPayload['content'], 'Hello');

      final noteId = createPayload['id']! as String;
      final getResponse = await _sendRequest(
        handler: handler,
        method: 'GET',
        path: '/v1/notes/$noteId',
      );
      expect(getResponse.statusCode, 200);
      expect(getResponse.jsonBody['id'], noteId);
    });

    test('lists notes with pagination', () async {
      await _sendRequest(
        handler: handler,
        method: 'POST',
        path: '/v1/notes',
        body: <String, Object?>{'title': 'Paginated note A', 'content': 'A'},
      );
      await _sendRequest(
        handler: handler,
        method: 'POST',
        path: '/v1/notes',
        body: <String, Object?>{'title': 'Paginated note B', 'content': 'B'},
      );

      final response = await _sendRequest(
        handler: handler,
        method: 'GET',
        path: '/v1/notes?page=1&limit=1',
      );

      expect(response.statusCode, 200);
      expect(response.jsonBody['page'], 1);
      expect(response.jsonBody['limit'], 1);
      expect(response.jsonBody['total'], greaterThanOrEqualTo(2));
      final items = response.jsonBody['items']! as List<Object?>;
      expect(items.length, 1);
    });

    test('updates a note with full payload', () async {
      final createResponse = await _sendRequest(
        handler: handler,
        method: 'POST',
        path: '/v1/notes',
        body: <String, Object?>{'title': 'Old title', 'content': 'Old content'},
      );

      final noteId = createResponse.jsonBody['id']! as String;

      final updateResponse = await _sendRequest(
        handler: handler,
        method: 'PUT',
        path: '/v1/notes/$noteId',
        body: <String, Object?>{'title': 'New title', 'content': 'New content'},
      );

      expect(updateResponse.statusCode, 200);
      expect(updateResponse.jsonBody['title'], 'New title');
      expect(updateResponse.jsonBody['content'], 'New content');
    });

    test('deletes a note and returns not found afterwards', () async {
      final createResponse = await _sendRequest(
        handler: handler,
        method: 'POST',
        path: '/v1/notes',
        body: <String, Object?>{'title': 'Delete me', 'content': 'Soon gone'},
      );

      final noteId = createResponse.jsonBody['id']! as String;
      final deleteResponse = await _sendRequest(
        handler: handler,
        method: 'DELETE',
        path: '/v1/notes/$noteId',
      );
      expect(deleteResponse.statusCode, 204);

      final getResponse = await _sendRequest(
        handler: handler,
        method: 'GET',
        path: '/v1/notes/$noteId',
      );
      expect(getResponse.statusCode, 404);
      expect(_readErrorCode(getResponse.jsonBody), 'not_found');
    });

    test('rejects invalid note payloads', () async {
      final missingTitleResponse = await _sendRequest(
        handler: handler,
        method: 'POST',
        path: '/v1/notes',
        body: <String, Object?>{'content': 'No title'},
      );
      expect(missingTitleResponse.statusCode, 400);
      expect(_readErrorCode(missingTitleResponse.jsonBody), 'bad_request');

      final tooLongContent = 'x' * 10001;
      final longContentResponse = await _sendRequest(
        handler: handler,
        method: 'POST',
        path: '/v1/notes',
        body: <String, Object?>{
          'title': 'Valid title',
          'content': tooLongContent,
        },
      );
      expect(longContentResponse.statusCode, 400);
      expect(_readErrorCode(longContentResponse.jsonBody), 'bad_request');
    });

    test('rejects malformed JSON body', () async {
      final response = await _sendRequest(
        handler: handler,
        method: 'POST',
        path: '/v1/notes',
        rawRequestBody: '{"title": "broken",',
      );

      expect(response.statusCode, 400);
      expect(_readErrorCode(response.jsonBody), 'bad_request');
    });

    test('rejects invalid pagination query values', () async {
      final response = await _sendRequest(
        handler: handler,
        method: 'GET',
        path: '/v1/notes?page=abc&limit=10',
      );

      expect(response.statusCode, 400);
      expect(_readErrorCode(response.jsonBody), 'bad_request');
    });
  });
}

Future<_ResponseData> _sendRequest({
  required Handler handler,
  required String method,
  required String path,
  Map<String, Object?>? body,
  String? rawRequestBody,
}) async {
  if (body != null && rawRequestBody != null) {
    throw ArgumentError('Provide either body or rawRequestBody, not both.');
  }

  final requestBody =
      rawRequestBody ?? (body == null ? null : jsonEncode(body));
  final request = Request(
    method,
    Uri.parse('http://localhost$path'),
    headers: <String, String>{
      'X-API-Key': 'key_sandbox',
      if (requestBody != null) 'content-type': 'application/json',
    },
    body: requestBody,
  );

  final response = await handler(request);
  final responseBody = await response.readAsString();
  final jsonBody = responseBody.isEmpty
      ? <String, Object?>{}
      : jsonDecode(responseBody) as Map<String, Object?>;

  return _ResponseData(statusCode: response.statusCode, jsonBody: jsonBody);
}

String _readErrorCode(Map<String, Object?> payload) {
  final error = payload['error']! as Map<String, Object?>;
  return error['code']! as String;
}

class _ResponseData {
  const _ResponseData({required this.statusCode, required this.jsonBody});

  final int statusCode;
  final Map<String, Object?> jsonBody;
}
