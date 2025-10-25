// lib/features/notes/domain/models/note_model.dart

import 'package:uuid/uuid.dart';

enum NoteType { text, structured }

class Note {
  final String id;
  String title;
  String content;
  String icon;
  final DateTime createdAt;
  DateTime modifiedAt;

  // ==> HAPUS 'final' DARI SINI <==
  NoteType type; // Sekarang tidak final lagi
  List<String> fieldDefinitions;
  List<Map<String, String>> dataEntries;

  Note({
    String? id,
    required this.title,
    this.content = '',
    this.icon = '🗒️',
    DateTime? createdAt,
    DateTime? modifiedAt,
    this.type = NoteType.text,
    this.fieldDefinitions = const [],
    this.dataEntries = const [],
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now(),
       modifiedAt = modifiedAt ?? DateTime.now();

  // ... (fromJson dan toJson tetap sama) ...
  factory Note.fromJson(Map<String, dynamic> json) {
    NoteType noteType =
        NoteType.values[json['type'] as int? ?? NoteType.text.index];

    List<String> fields = [];
    if (json['fieldDefinitions'] != null) {
      fields = List<String>.from(json['fieldDefinitions'] as List);
    }

    List<Map<String, String>> entries = [];
    if (json['dataEntries'] != null) {
      entries = (json['dataEntries'] as List)
          .map((entry) => Map<String, String>.from(entry))
          .toList();
    }

    return Note(
      id: json['id'] as String,
      title: json['title'] as String,
      content: json['content'] as String? ?? '', // Handle null content
      icon:
          json['icon'] as String? ??
          (noteType == NoteType.structured ? '📊' : '🗒️'), // Icon default beda
      createdAt: DateTime.parse(json['createdAt'] as String),
      modifiedAt: DateTime.parse(json['modifiedAt'] as String),
      type: noteType,
      fieldDefinitions: fields,
      dataEntries: entries,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'icon': icon,
      'createdAt': createdAt.toIso8601String(),
      'modifiedAt': modifiedAt.toIso8601String(),
      'type': type.index, // Simpan index enum
      'fieldDefinitions': fieldDefinitions,
      'dataEntries': dataEntries,
    };
  }
}
