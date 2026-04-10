import 'dart:convert';
import 'dart:math';

import 'package:dart_backend_tech_test/shared/http/request_context.dart';
import 'package:dart_backend_tech_test/src/feature_flags/domain/entities/api_tier.dart';
import 'package:shelf/shelf.dart';
import 'package:uuid/uuid.dart';

Middleware loggingMiddleware() {
  final uuid = const Uuid();

  return (Handler innerHandler) {
    return (Request request) async {
      final requestId = uuid.v4();
      final enrichedRequest = request.change(
        context: <String, Object?>{
          ...request.context,
          RequestContext.requestId: requestId,
        },
      );
      final stopwatch = Stopwatch()..start();
      final response = await innerHandler(enrichedRequest);
      stopwatch.stop();

      final apiKey =
          enrichedRequest.context[RequestContext.apiKey] as String? ??
              enrichedRequest.headers['X-API-Key'];
      final Object? tierContext = enrichedRequest.context[RequestContext.tier];
      final String? tier = tierContext is ApiTier
          ? tierContext.label
          : tierContext is String
              ? tierContext
              : null;

      print(
        jsonEncode(<String, Object?>{
          'event': 'request_completed',
          'requestId': requestId,
          'method': enrichedRequest.method,
          'path': enrichedRequest.requestedUri.path,
          'statusCode': response.statusCode,
          'durationMs': stopwatch.elapsedMilliseconds,
          'apiKey': _maskApiKey(apiKey),
          'tier': tier,
        }),
      );

      return response.change(
        headers: <String, String>{
          ...response.headers,
          'x-request-id': requestId,
        },
      );
    };
  };
}

String? _maskApiKey(String? apiKey) {
  if (apiKey == null || apiKey.isEmpty) {
    return null;
  }

  final visibleCharacters = min(apiKey.length, 4);
  return '${apiKey.substring(0, visibleCharacters)}***';
}
