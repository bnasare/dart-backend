import 'package:dart_backend_tech_test/core/config/app_config.dart';
import 'package:dart_backend_tech_test/shared/error/app_exception.dart';
import 'package:dart_backend_tech_test/shared/http/json_response.dart';
import 'package:dart_backend_tech_test/shared/http/request_context.dart';
import 'package:dart_backend_tech_test/shared/middleware/error_handler_middleware.dart';
import 'package:dart_backend_tech_test/shared/middleware/logging_middleware.dart';
import 'package:dart_backend_tech_test/src/auth/presentation/middleware/auth_middleware.dart';
import 'package:dart_backend_tech_test/src/docs/presentation/controllers/docs_controller.dart';
import 'package:dart_backend_tech_test/src/feature_flags/presentation/controllers/feature_flags_controller.dart';
import 'package:dart_backend_tech_test/src/notes/data/repository_impl/notes_repository_impl.dart';
import 'package:dart_backend_tech_test/src/notes/domain/usecases/create_note_use_case.dart';
import 'package:dart_backend_tech_test/src/notes/domain/usecases/delete_note_use_case.dart';
import 'package:dart_backend_tech_test/src/notes/domain/usecases/get_note_by_id_use_case.dart';
import 'package:dart_backend_tech_test/src/notes/domain/usecases/list_notes_use_case.dart';
import 'package:dart_backend_tech_test/src/notes/domain/usecases/update_note_use_case.dart';
import 'package:dart_backend_tech_test/src/notes/presentation/controllers/notes_controller.dart';
import 'package:dart_backend_tech_test/src/rate_limit/presentation/middleware/rate_limit_middleware.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

Handler createHandler({required AppConfig config}) {
  return createAppRuntime(config: config).handler;
}

AppRuntime createAppRuntime({required AppConfig config}) {
  const docsController = DocsController();
  const featureFlagsController = FeatureFlagsController();
  final notesRepository = NotesRepositoryImpl.fromPath(config.databasePath);
  final notesController = NotesController(
    createNoteUseCase: CreateNoteUseCase(notesRepository: notesRepository),
    listNotesUseCase: ListNotesUseCase(notesRepository: notesRepository),
    getNoteByIdUseCase: GetNoteByIdUseCase(notesRepository: notesRepository),
    updateNoteUseCase: UpdateNoteUseCase(notesRepository: notesRepository),
    deleteNoteUseCase: DeleteNoteUseCase(notesRepository: notesRepository),
  );
  final router = Router(notFoundHandler: _notFoundHandler);

  router.get('/health', _handleHealth);
  router.get('/openapi.yaml', docsController.handleOpenApi);
  router.get('/docs', docsController.handleDocs);
  router.get('/v1/feature-flags', featureFlagsController.handleGet);
  router.mount('/v1/notes', notesController.router.call);

  final pipeline = const Pipeline()
      .addMiddleware(loggingMiddleware())
      .addMiddleware(_configMiddleware(config))
      .addMiddleware(errorHandlerMiddleware())
      .addMiddleware(authMiddleware(config: config))
      .addMiddleware(rateLimitMiddleware(config: config));

  return AppRuntime(
    handler: pipeline.addHandler(router.call),
    onClose: notesRepository.close,
  );
}

class AppRuntime {
  AppRuntime({
    required this.handler,
    required Future<void> Function() onClose,
  }) : _onClose = onClose;

  final Handler handler;
  final Future<void> Function() _onClose;
  bool _closed = false;

  Future<void> close() async {
    if (_closed) {
      return;
    }

    _closed = true;
    await _onClose();
  }
}

Middleware _configMiddleware(AppConfig config) {
  return (Handler innerHandler) {
    return (Request request) {
      final nextRequest = request.change(
        context: <String, Object?>{
          ...request.context,
          RequestContext.appConfig: config,
        },
      );
      return innerHandler(nextRequest);
    };
  };
}

Future<Response> _handleHealth(Request request) async {
  return jsonResponse(200, <String, Object?>{'status': 'ok'});
}

Future<Response> _notFoundHandler(Request request) async {
  throw NotFoundException('Route ${request.requestedUri.path} was not found.');
}
