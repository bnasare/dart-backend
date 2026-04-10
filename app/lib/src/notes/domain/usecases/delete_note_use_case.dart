import 'package:dart_backend_tech_test/shared/usecase/usecase.dart';
import 'package:dart_backend_tech_test/src/notes/domain/repository/notes_repository.dart';

class DeleteNoteUseCase implements UseCase<bool, ObjectParams<String>> {
  const DeleteNoteUseCase({required NotesRepository notesRepository})
      : _notesRepository = notesRepository;

  final NotesRepository _notesRepository;

  @override
  Future<bool> call(ObjectParams<String> params) {
    return _notesRepository.delete(params.value);
  }
}
