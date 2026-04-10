import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';

part 'notes_database.g.dart';

class Notes extends Table {
  TextColumn get id => text()();

  TextColumn get title => text()();

  TextColumn get content => text()();

  IntColumn get createdAt => integer()();

  IntColumn get updatedAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}

@DriftDatabase(tables: <Type>[Notes])
class NotesDatabase extends _$NotesDatabase {
  NotesDatabase._(super.executor);

  factory NotesDatabase.fromPath(String databasePath) {
    if (databasePath == ':memory:') {
      return NotesDatabase._(NativeDatabase.memory());
    }

    final file = File(databasePath);
    file.parent.createSync(recursive: true);
    return NotesDatabase._(NativeDatabase(file));
  }

  @override
  int get schemaVersion => 1;
}
