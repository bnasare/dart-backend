import 'package:dart_backend_tech_test/shared/usecase/usecase.dart';
import 'package:dart_backend_tech_test/src/notes/domain/entities/note.dart';
import 'package:dart_backend_tech_test/src/notes/domain/repository/notes_repository.dart';
import 'package:dart_backend_tech_test/src/notes/domain/validators/note_validator.dart';

class CreateNoteInput {
  const CreateNoteInput({required this.title, required this.content});

  final String title;
  final String content;
}

class CreateNoteUseCase implements UseCase<Note, CreateNoteInput> {
  const CreateNoteUseCase({required NotesRepository notesRepository})
      : _notesRepository = notesRepository;

  final NotesRepository _notesRepository;

  @override
  Future<Note> call(CreateNoteInput params) {
    final title = validateNoteTitle(params.title);
    final content = validateNoteContent(params.content);
    return _notesRepository.create(title: title, content: content);
  }
}
