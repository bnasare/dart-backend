import 'dart:io';

import 'package:dart_backend_tech_test/app.dart';
import 'package:dart_backend_tech_test/core/config/app_config.dart';
import 'package:shelf/shelf_io.dart' as io;

Future<void> main(List<String> args) async {
  final config = AppConfig.fromEnvironment(Platform.environment);
  final handler = createHandler(config: config);
  final server = await io.serve(handler, InternetAddress.anyIPv4, config.port);

  print('Server listening on port ${server.port}');
}
