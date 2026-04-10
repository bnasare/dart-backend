import 'dart:io';

import 'package:dart_backend_tech_test/shared/error/app_exception.dart';
import 'package:shelf/shelf.dart';

class DocsController {
  const DocsController();

  Future<Response> handleOpenApi(Request request) async {
    final specFile = _resolveOpenApiFile();
    if (!await specFile.exists()) {
      throw const NotFoundException('OpenAPI specification was not found.');
    }

    final spec = await specFile.readAsString();
    return Response.ok(
      spec,
      headers: <String, String>{
        'content-type': 'application/yaml; charset=utf-8',
      },
    );
  }

  Future<Response> handleDocs(Request request) async {
    return Response.ok(
      _swaggerUiHtml,
      headers: <String, String>{
        'content-type': 'text/html; charset=utf-8',
      },
    );
  }

  File _resolveOpenApiFile() {
    final fromAppDir = File('openapi.yaml');
    if (fromAppDir.existsSync()) {
      return fromAppDir;
    }

    return File('app/openapi.yaml');
  }
}

const String _swaggerUiHtml = '''
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <title>API Docs</title>
    <link
      rel="stylesheet"
      href="https://unpkg.com/swagger-ui-dist@5/swagger-ui.css"
    />
    <style>
      html, body {
        margin: 0;
        padding: 0;
      }
    </style>
  </head>
  <body>
    <div id="swagger-ui"></div>
    <script src="https://unpkg.com/swagger-ui-dist@5/swagger-ui-bundle.js"></script>
    <script>
      window.ui = SwaggerUIBundle({
        url: '/openapi.yaml',
        dom_id: '#swagger-ui',
      });
    </script>
  </body>
</html>
''';
