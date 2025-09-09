// lib/features/progress/domain/models/progress_topic_model.dart

import 'progress_subject_model.dart';

class ProgressTopic {
  String topics;
  List<ProgressSubject> subjects;
  Map<String, dynamic> metadata;
  int position;
  String icon; // Properti baru untuk ikon

  ProgressTopic({
    required this.topics,
    required this.subjects,
    this.metadata = const {},
    this.position = -1,
    this.icon = '🎓', // Nilai default
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
      position: metadata['position'] as int? ?? -1,
      icon: metadata['icon'] as String? ?? '🎓', // Baca ikon dari metadata
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> mutableMetadata = Map.from(metadata);
    mutableMetadata['position'] = position;
    mutableMetadata['icon'] = icon; // Simpan ikon ke metadata

    return {
      'topics': topics,
      'subjects': subjects.map((e) => e.toJson()).toList(),
      'metadata': mutableMetadata,
    };
  }
}
