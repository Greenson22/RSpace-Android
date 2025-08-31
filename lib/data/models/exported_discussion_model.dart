// lib/data/models/exported_discussion_model.dart

import 'discussion_model.dart';

class ExportedSubject {
  final String name;
  final String icon; // >> BARU: Tambahkan ikon subjek
  final List<Discussion> discussions;

  ExportedSubject({
    required this.name,
    required this.icon, // >> BARU
    required this.discussions,
  });
}

class ExportedTopic {
  final String name;
  final String icon; // >> BARU: Tambahkan ikon topik
  final List<ExportedSubject> subjects;

  ExportedTopic({
    required this.name,
    required this.icon, // >> BARU
    required this.subjects,
  });
}
