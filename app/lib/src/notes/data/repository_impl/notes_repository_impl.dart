import 'package:drift/drift.dart';
import 'package:dart_backend_tech_test/src/notes/data/database/notes_database.dart';
import 'package:dart_backend_tech_test/src/notes/domain/entities/note.dart'
    as domain;
import 'package:dart_backend_tech_test/src/notes/domain/repository/notes_repository.dart';
import 'package:uuid/uuid.dart';

class NotesRepositoryImpl implements NotesRepository {
  NotesRepositoryImpl({
    required NotesDatabase database,
    Uuid? uuid,
  })  : _database = database,
        _uuid = uuid ?? const Uuid();

  factory NotesRepositoryImpl.fromPath(
    String databasePath, {
    Uuid? uuid,
  }) {
    return NotesRepositoryImpl(
      database: NotesDatabase.fromPath(databasePath),
      uuid: uuid,
    );
  }

  final NotesDatabase _database;
  final Uuid _uuid;

  @override
  Future<domain.Note> create({
    required String title,
    required String content,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final id = _uuid.v4();
    await _database.into(_database.notes).insert(
          NotesCompanion.insert(
            id: id,
            title: title,
            content: content,
            createdAt: now,
            updatedAt: now,
          ),
        );
    return (await getById(id))!;
  }

  @override
  Future<List<domain.Note>> list() async {
    final rows = await (_database.select(_database.notes)
          ..orderBy(<OrderingTerm Function($NotesTable)>[
            (table) => OrderingTerm.asc(table.createdAt),
          ]))
        .get();
    return rows.map(_toDomain).toList(growable: false);
  }

  @override
  Future<domain.Note?> getById(String id) async {
    final row = await (_database.select(_database.notes)
          ..where((table) => table.id.equals(id)))
        .getSingleOrNull();
    return row == null ? null : _toDomain(row);
  }

  @override
  Future<domain.Note?> update({
    required String id,
    required String title,
    required String content,
  }) async {
    final updatedRows = await (_database.update(_database.notes)
          ..where((table) => table.id.equals(id)))
        .write(
      NotesCompanion(
        title: Value<String>(title),
        content: Value<String>(content),
        updatedAt: Value<int>(DateTime.now().millisecondsSinceEpoch),
      ),
    );
    if (updatedRows == 0) {
      return null;
    }
    return getById(id);
  }

  @override
  Future<bool> delete(String id) async {
    final deletedRows = await (_database.delete(_database.notes)
          ..where((table) => table.id.equals(id)))
        .go();
    return deletedRows > 0;
  }

  Future<void> close() {
    return _database.close();
  }

  domain.Note _toDomain(Note row) {
    return domain.Note(
      id: row.id,
      title: row.title,
      content: row.content,
      createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAt),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(row.updatedAt),
    );
  }
}
