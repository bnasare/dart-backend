import 'dart:convert';
import 'dart:io';

import 'package:dart_backend_tech_test/shared/error/app_exception.dart';
import 'package:dart_backend_tech_test/shared/http/json_response.dart';
import 'package:dart_backend_tech_test/shared/http/request_context.dart';
import 'package:shelf/shelf.dart';

Middleware errorHandlerMiddleware() {
  return (Handler innerHandler) {
    return (Request request) async {
      try {
        return await Future<Response>.sync(() => innerHandler(request));
      } on AppException catch (error) {
        stderr.writeln(
          jsonEncode(<String, Object?>{
            'event': 'handled_exception',
            'code': error.code,
            'statusCode': error.statusCode,
            'message': error.message,
            'requestId': request.context[RequestContext.requestId],
          }),
        );
        return jsonResponse(error.statusCode, error.toErrorResponse().toJson());
      } catch (error, stackTrace) {
        stderr.writeln(
          jsonEncode(<String, Object?>{
            'event': 'unhandled_exception',
            'message': error.toString(),
            'requestId': request.context[RequestContext.requestId],
            'stackTrace': stackTrace.toString(),
          }),
        );

        const internalError = InternalServerException();
        return jsonResponse(
          internalError.statusCode,
          internalError.toErrorResponse().toJson(),
        );
      }
    };
  };
}
