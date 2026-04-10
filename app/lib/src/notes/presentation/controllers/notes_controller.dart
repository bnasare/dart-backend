import 'dart:convert';

import 'package:dart_backend_tech_test/shared/error/app_exception.dart';
import 'package:dart_backend_tech_test/shared/http/json_response.dart';
import 'package:dart_backend_tech_test/shared/usecase/usecase.dart';
import 'package:dart_backend_tech_test/src/notes/domain/usecases/create_note_use_case.dart';
import 'package:dart_backend_tech_test/src/notes/domain/usecases/delete_note_use_case.dart';
import 'package:dart_backend_tech_test/src/notes/domain/usecases/get_note_by_id_use_case.dart';
import 'package:dart_backend_tech_test/src/notes/domain/usecases/list_notes_use_case.dart';
import 'package:dart_backend_tech_test/src/notes/domain/usecases/update_note_use_case.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

class NotesController {
  const NotesController({
    required CreateNoteUseCase createNoteUseCase,
    required ListNotesUseCase listNotesUseCase,
    required GetNoteByIdUseCase getNoteByIdUseCase,
    required UpdateNoteUseCase updateNoteUseCase,
    required DeleteNoteUseCase deleteNoteUseCase,
  })  : _createNoteUseCase = createNoteUseCase,
        _listNotesUseCase = listNotesUseCase,
        _getNoteByIdUseCase = getNoteByIdUseCase,
        _updateNoteUseCase = updateNoteUseCase,
        _deleteNoteUseCase = deleteNoteUseCase;

  final CreateNoteUseCase _createNoteUseCase;
  final ListNotesUseCase _listNotesUseCase;
  final GetNoteByIdUseCase _getNoteByIdUseCase;
  final UpdateNoteUseCase _updateNoteUseCase;
  final DeleteNoteUseCase _deleteNoteUseCase;

  Router get router {
    final router = Router();

    router.get('/', _list);
    router.post('/', _create);
    router.get('/<id>', _get);
    router.put('/<id>', _update);
    router.delete('/<id>', _delete);

    return router;
  }

  Future<Response> _list(Request request) async {
    final query = request.requestedUri.queryParameters;
    final page = _parseIntQuery(query['page'], defaultValue: 1, name: 'page');
    final limit = _parseIntQuery(
      query['limit'],
      defaultValue: 20,
      name: 'limit',
    );
    final result = await _listNotesUseCase(
      ListNotesInput(page: page, limit: limit),
    );
    return jsonResponse(200, result.toJson());
  }

  Future<Response> _create(Request request) async {
    final payload = await _readPayload(request);
    final note = await _createNoteUseCase(
      CreateNoteInput(
        title: _readRequiredString(payload, 'title'),
        content: _readOptionalString(payload, 'content'),
      ),
    );
    return jsonResponse(201, note.toJson());
  }

  Future<Response> _get(Request request, String id) async {
    final note = await _getNoteByIdUseCase(ObjectParams<String>(id));
    if (note == null) {
      throw NotFoundException('Note with id $id was not found.');
    }

    return jsonResponse(200, note.toJson());
  }

  Future<Response> _update(Request request, String id) async {
    final payload = await _readPayload(request);
    final note = await _updateNoteUseCase(
      UpdateNoteInput(
        id: id,
        title: _readRequiredString(payload, 'title'),
        content: _readOptionalString(payload, 'content'),
      ),
    );
    if (note == null) {
      throw NotFoundException('Note with id $id was not found.');
    }

    return jsonResponse(200, note.toJson());
  }

  Future<Response> _delete(Request request, String id) async {
    final deleted = await _deleteNoteUseCase(ObjectParams<String>(id));
    if (!deleted) {
      throw NotFoundException('Note with id $id was not found.');
    }

    return Response(204);
  }

  Future<Map<String, Object?>> _readPayload(Request request) async {
    final body = await request.readAsString();
    if (body.trim().isEmpty) {
      throw const BadRequestException('Request body cannot be empty.');
    }

    final Object? decoded;
    try {
      decoded = jsonDecode(body);
    } on FormatException {
      throw const BadRequestException('Request body must be valid JSON.');
    }

    if (decoded is! Map<String, Object?>) {
      throw const BadRequestException('Request body must be a JSON object.');
    }

    return decoded;
  }

  String _readRequiredString(Map<String, Object?> payload, String key) {
    final value = payload[key];
    if (value == null) {
      throw BadRequestException('$key is required.');
    }
    return value.toString();
  }

  String _readOptionalString(Map<String, Object?> payload, String key) {
    return (payload[key] ?? '').toString();
  }

  int _parseIntQuery(
    String? rawValue, {
    required int defaultValue,
    required String name,
  }) {
    if (rawValue == null) {
      return defaultValue;
    }

    final parsed = int.tryParse(rawValue);
    if (parsed == null) {
      throw BadRequestException('$name must be a valid integer.');
    }

    return parsed;
  }
}
