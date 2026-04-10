import 'package:dart_backend_tech_test/shared/usecase/usecase.dart';
import 'package:dart_backend_tech_test/src/notes/domain/entities/note.dart';
import 'package:dart_backend_tech_test/src/notes/domain/repository/notes_repository.dart';
import 'package:dart_backend_tech_test/src/notes/domain/validators/note_validator.dart';

class UpdateNoteInput {
  const UpdateNoteInput({
    required this.id,
    required this.title,
    required this.content,
  });

  final String id;
  final String title;
  final String content;
}

class UpdateNoteUseCase implements UseCase<Note?, UpdateNoteInput> {
  const UpdateNoteUseCase({required NotesRepository notesRepository})
      : _notesRepository = notesRepository;

  final NotesRepository _notesRepository;

  @override
  Future<Note?> call(UpdateNoteInput params) {
    final title = validateNoteTitle(params.title);
    final content = validateNoteContent(params.content);
    return _notesRepository.update(
      id: params.id,
      title: title,
      content: content,
    );
  }
}
