// lib/features/content_management/domain/models/subject_model.dart

import 'package:my_aplication/features/content_management/domain/models/discussion_model.dart';

class Subject {
  // Properti ini untuk identifikasi, tidak disimpan di file JSON subject
  String topicName;

  // Properti ini diambil dari metadata di file JSON
  String name;
  String icon;
  int position;
  bool isHidden;
  String? linkedPath;
  bool isFrozen; // ==> DITAMBAHKAN
  String? frozenDate; // ==> DITAMBAHKAN

  // Properti ini dihitung secara dinamis oleh service berdasarkan konten
  String? date;
  String? repetitionCode;
  int discussionCount;
  int finishedDiscussionCount;
  Map<String, int> repetitionCodeCounts;

  // Konten mentah dari file JSON
  List<Discussion> discussions;

  Subject({
    required this.topicName,
    required this.name,
    required this.icon,
    required this.position,
    this.date,
    this.repetitionCode,
    this.isHidden = false,
    this.linkedPath,
    this.isFrozen = false, // ==> DITAMBAHKAN
    this.frozenDate, // ==> DITAMBAHKAN
    this.discussionCount = 0,
    this.finishedDiscussionCount = 0,
    this.repetitionCodeCounts = const {},
    this.discussions = const [],
  });

  // Factory constructor untuk membuat objek Subject dari JSON
  factory Subject.fromJson(
    String topicName,
    String subjectName,
    Map<String, dynamic> json,
  ) {
    final metadata = json['metadata'] as Map<String, dynamic>? ?? {};
    final content = json['content'] as List<dynamic>? ?? [];
    final discussions = content
        .map((item) => Discussion.fromJson(item))
        .toList();

    return Subject(
      topicName: topicName,
      name: subjectName,
      icon: metadata['icon'] as String? ?? '📄',
      position: metadata['position'] as int? ?? -1,
      isHidden: metadata['isHidden'] as bool? ?? false,
      linkedPath: metadata['linkedPath'] as String?,
      isFrozen: metadata['isFrozen'] as bool? ?? false, // ==> DITAMBAHKAN
      frozenDate: metadata['frozenDate'] as String?, // ==> DITAMBAHKAN
      discussions: discussions,
      discussionCount: discussions.length,
      finishedDiscussionCount: discussions.where((d) => d.finished).length,
    );
  }

  // Method untuk mengubah objek Subject menjadi JSON
  Map<String, dynamic> toJson() {
    return {
      'metadata': {
        'icon': icon,
        'position': position,
        'isHidden': isHidden,
        'linkedPath': linkedPath,
        'isFrozen': isFrozen, // ==> DITAMBAHKAN
        'frozenDate': frozenDate, // ==> DITAMBAHKAN
      },
      'content': discussions.map((d) => d.toJson()).toList(),
    };
  }
}
