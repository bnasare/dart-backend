import 'error_response.dart';

abstract class AppException implements Exception {
  const AppException({
    required this.code,
    required this.message,
    required this.statusCode,
    this.details = const <String, Object?>{},
  });

  final String code;
  final String message;
  final int statusCode;
  final Map<String, Object?> details;

  ErrorResponse toErrorResponse() {
    return ErrorResponse(code: code, message: message, details: details);
  }

  @override
  String toString() => message;
}

class BadRequestException extends AppException {
  const BadRequestException(
    String message, {
    super.details = const <String, Object?>{},
  }) : super(code: 'bad_request', message: message, statusCode: 400);
}

class UnauthorizedException extends AppException {
  const UnauthorizedException(String message)
      : super(code: 'unauthorized', message: message, statusCode: 401);
}

class NotFoundException extends AppException {
  const NotFoundException(String message)
      : super(code: 'not_found', message: message, statusCode: 404);
}

class InternalServerException extends AppException {
  const InternalServerException()
      : super(
          code: 'internal_server_error',
          message: 'Something went wrong.',
          statusCode: 500,
        );
}
