import 'package:dart_backend_tech_test/core/config/app_config.dart';
import 'package:dart_backend_tech_test/shared/error/app_exception.dart';
import 'package:dart_backend_tech_test/shared/http/request_context.dart';
import 'package:shelf/shelf.dart';

Middleware authMiddleware({required AppConfig config}) {
  return (Handler innerHandler) {
    return (Request request) async {
      if (!config.isProtectedPath(request.url.path)) {
        return innerHandler(request);
      }

      final apiKey = request.headers['X-API-Key'];
      if (apiKey == null) {
        throw const UnauthorizedException('Missing API key.');
      }

      final tier = config.tierForApiKey(apiKey);
      if (tier == null) {
        throw const UnauthorizedException('Invalid API key.');
      }

      final nextRequest = request.change(
        context: <String, Object?>{
          ...request.context,
          RequestContext.apiKey: apiKey,
          RequestContext.tier: tier,
        },
      );

      return innerHandler(nextRequest);
    };
  };
}
