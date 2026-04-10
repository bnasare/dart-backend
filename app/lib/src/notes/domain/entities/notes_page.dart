import 'package:dart_backend_tech_test/src/notes/domain/entities/note.dart';

class NotesPage {
  const NotesPage({
    required this.page,
    required this.limit,
    required this.total,
    required this.items,
  });

  final int page;
  final int limit;
  final int total;
  final List<Note> items;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'page': page,
      'limit': limit,
      'total': total,
      'items': items.map((Note note) => note.toJson()).toList(growable: false),
    };
  }
}
