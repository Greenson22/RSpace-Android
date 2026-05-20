// lib/features/progress/domain/models/progress_topic_model.dart

import 'progress_subject_model.dart';

class ProgressTopic {
  String topics;
  List<ProgressSubject> subjects;
  Map<String, dynamic> metadata;
  int position;
  String icon;
  bool isHidden; // Properti untuk status sembunyi
  String section; // BARU: Properti untuk kategori bagian (section)

  ProgressTopic({
    required this.topics,
    required this.subjects,
    this.metadata = const {},
    this.position = -1,
    this.icon = '🎓',
    this.isHidden = false, // Default tidak tersembunyi
    this.section = 'Umum', // BARU: Default bagian
  });

  factory ProgressTopic.fromJson(Map<String, dynamic> json) {
    var subjectsList = json['subjects'] as List? ?? [];
    List<ProgressSubject> subjects = subjectsList
        .map((i) => ProgressSubject.fromJson(i))
        .toList();

    final metadata = json['metadata'] as Map<String, dynamic>? ?? {};

    return ProgressTopic(
      topics: json['topics'] as String,
      subjects: subjects,
      metadata: metadata,
      position: metadata['position'] as int? ?? -1,
      icon: metadata['icon'] as String? ?? '🎓',
      isHidden: metadata['isHidden'] as bool? ?? false,
      section:
          metadata['section'] as String? ?? 'Umum', // Baca bagian dari metadata
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> mutableMetadata = Map.from(metadata);
    mutableMetadata['position'] = position;
    mutableMetadata['icon'] = icon;
    mutableMetadata['isHidden'] = isHidden;
    mutableMetadata['section'] = section; // Simpan bagian ke metadata

    return {
      'topics': topics,
      'subjects': subjects.map((e) => e.toJson()).toList(),
      'metadata': mutableMetadata,
    };
  }
}
