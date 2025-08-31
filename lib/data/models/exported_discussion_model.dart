// lib/data/models/exported_discussion_model.dart

import 'discussion_model.dart';

class ExportedSubject {
  final String name;
  final List<Discussion> discussions;

  ExportedSubject({required this.name, required this.discussions});
}

class ExportedTopic {
  final String name;
  final List<ExportedSubject> subjects;

  ExportedTopic({required this.name, required this.subjects});
}
