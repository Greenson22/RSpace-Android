// lib/features/notes/domain/models/note_model.dart

import 'package:uuid/uuid.dart';

class Note {
  final String id;
  String title;
  String content;
  // ==> PROPERTI BARU DITAMBAHKAN <==
  String icon;
  final DateTime createdAt;
  DateTime modifiedAt;

  Note({
    String? id,
    required this.title,
    required this.content,
    // ==> TAMBAHAN DI KONSTRUKTOR <==
    this.icon = '🗒️',
    DateTime? createdAt,
    DateTime? modifiedAt,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now(),
       modifiedAt = modifiedAt ?? DateTime.now();

  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      id: json['id'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      // ==> BACA DARI JSON <==
      icon: json['icon'] as String? ?? '🗒️',
      createdAt: DateTime.parse(json['createdAt'] as String),
      modifiedAt: DateTime.parse(json['modifiedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      // ==> SIMPAN KE JSON <==
      'icon': icon,
      'createdAt': createdAt.toIso8601String(),
      'modifiedAt': modifiedAt.toIso8601String(),
    };
  }
}
