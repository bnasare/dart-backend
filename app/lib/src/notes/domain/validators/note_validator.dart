import 'package:dart_backend_tech_test/shared/error/app_exception.dart';

String validateNoteTitle(String rawTitle) {
  final title = rawTitle.trim();
  if (title.isEmpty || title.length > 120) {
    throw const BadRequestException(
      'Title must be between 1 and 120 characters.',
    );
  }

  return title;
}

String validateNoteContent(String rawContent) {
  if (rawContent.length > 10000) {
    throw const BadRequestException(
      'Content must be at most 10000 characters.',
    );
  }

  return rawContent;
}
