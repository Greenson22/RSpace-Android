// lib/features/progress/domain/models/progress_topic_model.dart

import 'progress_subject_model.dart';

class ProgressTopic {
  String topics;
  List<ProgressSubject> subjects;
  Map<String, dynamic> metadata;

  ProgressTopic({
    required this.topics,
    required this.subjects,
    this.metadata = const {},
  });

  factory ProgressTopic.fromJson(Map<String, dynamic> json) {
    var subjectsList = json['subjects'] as List;
    List<ProgressSubject> subjects = subjectsList
        .map((i) => ProgressSubject.fromJson(i))
        .toList();

    return ProgressTopic(
      topics: json['topics'] as String,
      subjects: subjects,
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'topics': topics,
      'subjects': subjects.map((e) => e.toJson()).toList(),
      'metadata': metadata,
    };
  }
}
