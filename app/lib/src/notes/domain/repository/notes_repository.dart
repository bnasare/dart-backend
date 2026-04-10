import 'package:dart_backend_tech_test/src/notes/domain/entities/note.dart';

abstract class NotesRepository {
  Future<Note> create({required String title, required String content});

  Future<List<Note>> list();

  Future<Note?> getById(String id);

  Future<Note?> update({
    required String id,
    required String title,
    required String content,
  });

  Future<bool> delete(String id);
}
