import 'package:dart_backend_tech_test/shared/usecase/usecase.dart';
import 'package:dart_backend_tech_test/src/notes/domain/entities/note.dart';
import 'package:dart_backend_tech_test/src/notes/domain/repository/notes_repository.dart';

class GetNoteByIdUseCase implements UseCase<Note?, ObjectParams<String>> {
  const GetNoteByIdUseCase({required NotesRepository notesRepository})
      : _notesRepository = notesRepository;

  final NotesRepository _notesRepository;

  @override
  Future<Note?> call(ObjectParams<String> params) {
    return _notesRepository.getById(params.value);
  }
}
