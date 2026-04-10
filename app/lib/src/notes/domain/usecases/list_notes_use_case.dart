import 'package:dart_backend_tech_test/shared/error/app_exception.dart';
import 'package:dart_backend_tech_test/shared/usecase/usecase.dart';
import 'package:dart_backend_tech_test/src/notes/domain/entities/note.dart';
import 'package:dart_backend_tech_test/src/notes/domain/entities/notes_page.dart';
import 'package:dart_backend_tech_test/src/notes/domain/repository/notes_repository.dart';

class ListNotesInput {
  const ListNotesInput({required this.page, required this.limit});

  final int page;
  final int limit;
}

class ListNotesUseCase implements UseCase<NotesPage, ListNotesInput> {
  const ListNotesUseCase({required NotesRepository notesRepository})
      : _notesRepository = notesRepository;

  final NotesRepository _notesRepository;

  @override
  Future<NotesPage> call(ListNotesInput params) async {
    if (params.page < 1 || params.limit < 1 || params.limit > 100) {
      throw const BadRequestException(
        'Pagination parameters must be valid positive integers.',
      );
    }

    final List<Note> notes = await _notesRepository.list();
    final int start = (params.page - 1) * params.limit;
    final List<Note> items =
        notes.skip(start).take(params.limit).toList(growable: false);

    return NotesPage(
      page: params.page,
      limit: params.limit,
      total: notes.length,
      items: items,
    );
  }
}
