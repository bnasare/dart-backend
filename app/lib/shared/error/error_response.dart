class ErrorResponse {
  const ErrorResponse({
    required this.code,
    required this.message,
    this.details = const <String, Object?>{},
  });

  final String code;
  final String message;
  final Map<String, Object?> details;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'error': <String, Object?>{
        'code': code,
        'message': message,
        if (details.isNotEmpty) 'details': details,
      },
    };
  }
}
