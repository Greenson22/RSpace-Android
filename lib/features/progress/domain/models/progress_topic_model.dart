// lib/features/progress/domain/models/progress_topic_model.dart

import 'progress_subject_model.dart';

class ProgressTopic {
  String topics;
  List<ProgressSubject> subjects;
  Map<String, dynamic> metadata;
  int position;

  ProgressTopic({
    required this.topics,
    required this.subjects,
    this.metadata = const {},
    this.position = -1,
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
    );
  }

  Map<String, dynamic> toJson() {
    // ==> PERBAIKAN DI SINI <==
    // 1. Buat salinan metadata yang dapat diubah.
    final Map<String, dynamic> mutableMetadata = Map.from(metadata);
    // 2. Ubah salinan tersebut.
    mutableMetadata['position'] = position;

    return {
      'topics': topics,
      'subjects': subjects.map((e) => e.toJson()).toList(),
      // 3. Gunakan salinan yang sudah diubah untuk disimpan.
      'metadata': mutableMetadata,
    };
  }
}
