import 'dart:convert';

import 'package:shelf/shelf.dart';

Response jsonResponse(
  int statusCode,
  Map<String, Object?> payload, {
  Map<String, String>? headers,
}) {
  return Response(
    statusCode,
    body: jsonEncode(payload),
    headers: <String, String>{
      'content-type': 'application/json',
      if (headers != null) ...headers,
    },
  );
}
