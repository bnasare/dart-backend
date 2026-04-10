import 'dart:io';

import 'package:dart_backend_tech_test/src/notes/data/repository_impl/notes_repository_impl.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

void main() {
  test('persists notes across repository instances with sqlite', () async {
    final tempDir = await Directory.systemTemp.createTemp('notes_repo_test_');
    final databasePath = path.join(tempDir.path, 'notes.sqlite');

    final firstRepo = NotesRepositoryImpl.fromPath(databasePath);
    final created = await firstRepo.create(
      title: 'Persistent note',
      content: 'Stored on disk',
    );
    await firstRepo.close();

    final secondRepo = NotesRepositoryImpl.fromPath(databasePath);
    final fetched = await secondRepo.getById(created.id);
    expect(fetched, isNotNull);
    expect(fetched!.title, 'Persistent note');
    expect(fetched.content, 'Stored on disk');

    await secondRepo.close();
    await tempDir.delete(recursive: true);
  });
}
