import 'dart:collection';

import 'package:dart_backend_tech_test/core/config/app_config.dart';
import 'package:dart_backend_tech_test/shared/http/json_response.dart';
import 'package:dart_backend_tech_test/shared/http/request_context.dart';
import 'package:shelf/shelf.dart';

class _Bucket {
  _Bucket({required this.remaining, required this.windowStartedAt});

  int remaining;
  DateTime windowStartedAt;
}

Middleware rateLimitMiddleware({required AppConfig config}) {
  final Map<String, _Bucket> buckets = HashMap<String, _Bucket>();

  return (Handler innerHandler) {
    return (Request request) async {
      if (!config.isProtectedPath(request.url.path)) {
        return innerHandler(request);
      }

      final apiKey = request.context[RequestContext.apiKey] as String?;
      if (apiKey == null) {
        return innerHandler(request);
      }

      final now = DateTime.now();
      final bucket = buckets.putIfAbsent(
        apiKey,
        () => _Bucket(remaining: config.rateLimitMax, windowStartedAt: now),
      );

      final elapsedSeconds = now.difference(bucket.windowStartedAt).inSeconds;
      if (elapsedSeconds >= config.rateLimitWindowSec) {
        bucket
          ..remaining = config.rateLimitMax
          ..windowStartedAt = now;
      }

      if (bucket.remaining <= 0) {
        final retryAfter = config.rateLimitWindowSec -
            now.difference(bucket.windowStartedAt).inSeconds;
        final safeRetryAfter = retryAfter.clamp(0, config.rateLimitWindowSec);
        return jsonResponse(
          429,
          <String, Object?>{
            'error': <String, Object?>{
              'code': 'rate_limit_exceeded',
              'message': 'Rate limit exceeded.',
            },
          },
          headers: <String, String>{
            'Retry-After': safeRetryAfter.toString(),
            'X-RateLimit-Limit': '${config.rateLimitMax}',
            'X-RateLimit-Remaining': '0',
          },
        );
      }

      bucket.remaining -= 1;
      final response = await innerHandler(request);
      return response.change(
        headers: <String, String>{
          ...response.headers,
          'X-RateLimit-Limit': '${config.rateLimitMax}',
          'X-RateLimit-Remaining': '${bucket.remaining}',
        },
      );
    };
  };
}
