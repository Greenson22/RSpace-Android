// lib/features/progress/domain/models/progress_topic_model.dart

import 'progress_subject_model.dart';

class ProgressTopic {
  String topics;
  List<ProgressSubject> subjects;
  Map<String, dynamic> metadata;
  int position; // Properti baru untuk urutan

  ProgressTopic({
    required this.topics,
    required this.subjects,
    this.metadata = const {},
    this.position = -1, // Nilai default
  });

  factory ProgressTopic.fromJson(Map<String, dynamic> json) {
    var subjectsList = json['subjects'] as List;
    List<ProgressSubject> subjects = subjectsList
        .map((i) => ProgressSubject.fromJson(i))
        .toList();

    final metadata = json['metadata'] as Map<String, dynamic>? ?? {};

    return ProgressTopic(
      topics: json['topics'] as String,
      subjects: subjects,
      metadata: metadata,
      position: metadata['position'] as int? ?? -1, // Baca posisi dari metadata
    );
  }

  Map<String, dynamic> toJson() {
    // Pastikan metadata diupdate dengan posisi terbaru
    metadata['position'] = position;

    return {
      'topics': topics,
      'subjects': subjects.map((e) => e.toJson()).toList(),
      'metadata': metadata,
    };
  }
}
